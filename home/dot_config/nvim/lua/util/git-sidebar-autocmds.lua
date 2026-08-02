-- Autocmds that keep the git-tree sidebar in sync: focus bounce, follow-file,
-- and a debounced refresh on events that may have changed git state.
local status = require("util.git-status")

local M = {}

function M.setup()
  -- When you nav into the sidebar via window motion, vim picks the window your
  -- cursor row lines up with — often the bottom input. Bounce focus input →
  -- list, unless you came from the list itself (via `/`) or a search term is
  -- active (don't disrupt it).
  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      if vim.bo.filetype ~= "snacks_picker_input" then return end
      local current_win = vim.api.nvim_get_current_win()
      local prev_win = vim.fn.win_getid(vim.fn.winnr("#"))
      local ok, snacks = pcall(require, "snacks")
      if not ok or not snacks.picker then return end
      for _, p in ipairs(snacks.picker.get({ source = "git_tree" }) or {}) do
        if p.input and p.input.win and p.input.win.win == current_win then
          if p.list and p.list.win and p.list.win.win == prev_win then
            return -- came via `/` (toggle_focus from list)
          end
          local buf = p.input.win.buf
          if buf and vim.api.nvim_buf_is_valid(buf) then
            local content = (vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] or "")
            if content ~= "" then return end -- preserve active search
          end
          if p.list and p.list.win and p.list.win.win
              and vim.api.nvim_win_is_valid(p.list.win.win) then
            vim.schedule(function()
              pcall(vim.api.nvim_set_current_win, p.list.win.win)
            end)
          end
          return
        end
      end
    end,
  })

  -- Follow the current file in the git tree: on opening a file, move the list
  -- cursor to its item (mirrors explorer's follow_file). Only changed files are
  -- in the tree, so a clean file leaves the highlight put. Skips when the picker
  -- is focused or a search is active.
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    callback = function(args)
      if vim.bo[args.buf].buftype ~= "" then return end
      vim.schedule(function()
        if args.buf ~= vim.api.nvim_get_current_buf() then return end
        local win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_config(win).relative ~= "" then return end
        local ok, snacks = pcall(require, "snacks")
        if not ok or not snacks.picker then return end
        local file = vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf))
        if file == "" then return end
        for _, p in ipairs(snacks.picker.get({ source = "git_tree" }) or {}) do
          if not p.closed and not p:is_focused() and p.list then
            local cur = p.list:current()
            if not (cur and cur.file and vim.fs.normalize(cur.file) == file) then
              for i = 1, p.list:count() do
                local it = p.list:get(i)
                if it and not it.dir and it.file
                    and vim.fs.normalize(it.file) == file then
                  pcall(p.list.view, p.list, i, nil, true)
                  break
                end
              end
            end
          end
        end
      end)
    end,
  })

  -- Debounced refresh on events that may have changed git state.
  local refresh_timer
  local function refresh_git_picker()
    if refresh_timer then
      refresh_timer:stop()
      refresh_timer:close()
    end
    refresh_timer = vim.defer_fn(function()
      refresh_timer = nil
      -- Fetch status async, then re-find from the warm cache. Doing it sync
      -- (invalidate + find, which runs a blocking io.popen) froze the UI ~1s
      -- per save in large repos.
      status.fetch_async(vim.fn.getcwd(), function()
        local ok, snacks = pcall(require, "snacks")
        if not ok or not snacks.picker then return end
        for _, p in ipairs(snacks.picker.get({ source = "git_tree" }) or {}) do
          -- Preserve cursor/top so the tree doesn't jump to the top on every
          -- save / focus-gain.
          if p.list and p.list.set_target then
            pcall(p.list.set_target, p.list)
          end
          pcall(p.find, p)
        end

        -- Force the LEFT explorer to re-read git status too. snacks caches
        -- explorer git status for 15 min, invalidated only by a `.git`
        -- fs-watcher (unreliable on macOS) — so in-editor git ops never showed
        -- up until reopen. Marking the cache stale (the watcher's own call) +
        -- re-find picks them up; explorer's finder re-runs `git status` on
        -- find, so this stays non-blocking.
        local EGit = require("snacks.explorer.git")
        for _, p in ipairs(snacks.picker.get({ source = "explorer" }) or {}) do
          if not p.closed then
            local root = snacks.git.get_root(p:cwd())
            if root then EGit.refresh(root) end
            if p.list and p.list.set_target then
              pcall(p.list.set_target, p.list)
            end
            pcall(p.find, p)
          end
        end
      end)
    end, 250)
  end
  vim.api.nvim_create_autocmd(
    -- ShellCmdPost/TermClose catch `:!git ...` and terminal git; FocusGained
    -- catches an external terminal you tab back from.
    { "BufWritePost", "FocusGained", "DirChanged", "ShellCmdPost", "TermClose" },
    { callback = refresh_git_picker }
  )
  -- The two in-editor git paths that touch the index without a save or focus
  -- change: fugitive fires User FugitiveChanged, gitsigns hunk-staging fires
  -- User GitSignsUpdate. Debounced, so the GitSignsUpdate storm during editing
  -- collapses into one refresh.
  vim.api.nvim_create_autocmd("User", {
    pattern = { "FugitiveChanged", "GitSignsUpdate" },
    callback = refresh_git_picker,
  })
end

return M
