-- Persistent right-side "Source Control" sidebar: a tree view of git changes,
-- built on a custom snacks picker source for tree rendering + fast git status.

local function find_main_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" then
      return win
    end
  end
  return nil
end

-- Keep in sync with the explorer layout width in snacks.lua.
local RIGHT_SIDEBAR_WIDTH = 35

-- Paths the user has collapsed in the git tree.
local collapsed = {}

local function open_file(picker, item)
  if not item then return end
  if item.dir then
    collapsed[item.file] = not collapsed[item.file]
    -- Preserve cursor position across the refresh-triggered re-find.
    if picker and picker.list and picker.list.set_target then
      pcall(picker.list.set_target, picker.list)
    end
    if picker and picker.find then pcall(picker.find, picker) end
    return
  end
  if not item.file then return end
  local target = find_main_window()
  if target then vim.api.nvim_set_current_win(target) end
  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
end

local function open_with_diff(item)
  if not item or not item.file or item.dir then return end
  local target = find_main_window()
  if target then vim.api.nvim_set_current_win(target) end
  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
  -- Poll for gitsigns to attach before diffthis; a fixed defer raced when
  -- gitsigns took longer, silently no-op'ing the diff.
  local function try_diff(attempts)
    if attempts > 30 then return end
    if vim.b.gitsigns_status_dict then
      pcall(vim.cmd, "Gitsigns diffthis HEAD")
    else
      vim.defer_fn(function() try_diff(attempts + 1) end, 50)
    end
  end
  vim.defer_fn(function() try_diff(0) end, 30)
end

-- Cache of `git status`, invalidated explicitly when git state may have changed
-- (save, focus gain, stage, manual refresh) so folder toggles re-render instantly.
local status_cache = { cwd = nil, files = nil }

local function invalidate_status_cache()
  status_cache.cwd = nil
  status_cache.files = nil
end

local function parse_git_status(output)
  local out = vim.split(output or "", "\n", { trimempty = true })
  local files = {}
  for _, line in ipairs(out) do
    if #line >= 3 then
      local status = line:sub(1, 2)
      local path = line:sub(4)
      local newpath = path:match("%-%> (.+)$")
      if newpath then path = newpath end
      path = path:gsub('^"', ""):gsub('"$', "")
      files[path] = status
    end
  end
  return files
end

local function read_git_status(cwd)
  if status_cache.cwd == cwd and status_cache.files then
    return status_cache.files
  end
  local quoted = "'" .. cwd:gsub("'", "'\\''") .. "'"
  local handle = io.popen("git -C " .. quoted .. " status --porcelain=v1 --untracked-files=all 2>/dev/null")
  if not handle then return {} end
  local output = handle:read("*a") or ""
  handle:close()
  local files = parse_git_status(output)
  status_cache.cwd = cwd
  status_cache.files = files
  return files
end

-- Async status fetch off the main loop, fills the cache, then cb(). Used by the
-- event-driven refresh so a slow `git status` (~1s in huge trees) can't freeze
-- the UI. read_git_status stays as the sync cache-miss path for user-initiated
-- finds (initial open, folder toggles), which read the warm cache this fills.
local function fetch_git_status_async(cwd, cb)
  local ok = pcall(vim.system,
    { "git", "-C", cwd, "status", "--porcelain=v1", "--untracked-files=all" },
    { text = true },
    vim.schedule_wrap(function(res)
      status_cache.cwd = cwd
      status_cache.files = parse_git_status(res and res.code == 0 and res.stdout or "")
      if cb then cb() end
    end))
  -- Fallback for older nvim without vim.system: block once (rare path).
  if not ok then
    read_git_status(cwd)
    if cb then cb() end
  end
end

-- Custom finder: builds a tree of git-changed files with parent dirs, from the
-- cached status data so folder collapse/expand is instant.
local function git_tree_finder(opts, ctx)
  return function(cb)
    local cwd = (ctx and ctx.filter and ctx.filter.cwd) or vim.fn.getcwd()
    local files = read_git_status(cwd)

    local dirs = {}
    local items = {}

    local function ensure_dir(rel_dir)
      if rel_dir == "" or rel_dir == "." then return nil end
      if dirs[rel_dir] then return dirs[rel_dir] end
      local parent_rel = rel_dir:match("^(.+)/[^/]+$")
      local parent_item = parent_rel and ensure_dir(parent_rel) or nil
      local item = {
        file = cwd .. "/" .. rel_dir,
        text = cwd .. "/" .. rel_dir,
        dir = true,
        open = true,
        parent = parent_item,
        last = true,
      }
      dirs[rel_dir] = item
      table.insert(items, item)
      return item
    end

    -- Partial-staged files (index staged + fresh worktree change) render with
    -- the worktree status + a flag our formatter reads. See util/git-format.lua.
    local gitfmt = require("util.git-format")
    local function display_status(xy)
      if gitfmt.is_partial_staged(xy) then
        return " " .. xy:sub(2, 2), true
      end
      return xy, false
    end

    local paths = vim.tbl_keys(files)
    table.sort(paths)
    for _, path in ipairs(paths) do
      local parent_rel = path:match("^(.+)/[^/]+$")
      local parent_item = parent_rel and ensure_dir(parent_rel) or nil
      local status, partial = display_status(files[path])
      table.insert(items, {
        file = cwd .. "/" .. path,
        text = cwd .. "/" .. path,
        dir = false,
        parent = parent_item,
        last = true,
        status = status,
        partial_staged = partial,
      })
    end

    -- Propagate file statuses up to ancestor dirs so a collapsed folder shows
    -- the aggregate status icon/color.
    local Git = require("snacks.picker.source.git")
    local function add_dir_status(dir_item, status)
      dir_item.dir_status = dir_item.dir_status
          and Git.merge_status(dir_item.dir_status, status)
          or status
    end
    for _, item in ipairs(items) do
      if not item.dir and item.status then
        local p = item.parent
        while p do
          add_dir_status(p, item.status)
          p = p.parent
        end
      end
    end

    -- Hide items under a collapsed ancestor; set `open` on dirs so the
    -- formatter shows open vs closed folder icons.
    local function is_hidden(item)
      local p = item.parent
      while p do
        if collapsed[p.file] then return true end
        p = p.parent
      end
      return false
    end
    local visible = {}
    for _, item in ipairs(items) do
      if not is_hidden(item) then
        if item.dir then
          item.open = not collapsed[item.file]
          -- Closed dir picks up the aggregate child status (matches explorer).
          item.status = (not item.open) and item.dir_status or nil
        end
        table.insert(visible, item)
      end
    end

    -- Fix `last` flags within the visible set.
    local last_per_parent = {}
    for _, item in ipairs(visible) do
      last_per_parent[item.parent or "__root__"] = item
    end
    for _, item in ipairs(visible) do
      item.last = (last_per_parent[item.parent or "__root__"] == item)
    end

    for _, item in ipairs(visible) do cb(item) end
  end
end

-- Find the active git_tree picker and its highlighted item.
local function current_picker_item()
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then return nil, nil end
  local pickers = snacks.picker.get({ source = "git_tree" }) or {}
  local picker = pickers[1]
  if not picker or not picker.list or not picker.list.current then
    return picker, nil
  end
  return picker, picker.list:current()
end

local function leader_stage()
  local picker, item = current_picker_item()
  if not picker or not item then return end
  picker.list:set_target()
  require("snacks.picker.actions").git_stage(picker)
  vim.defer_fn(function()
    invalidate_status_cache()
    pcall(picker.find, picker)
  end, 200)
end

local function leader_refresh()
  local picker, _ = current_picker_item()
  if not picker then return end
  invalidate_status_cache()
  pcall(picker.find, picker)
end

local function leader_open_with_diff()
  local _, item = current_picker_item()
  open_with_diff(item)
end

local function leader_toggle()
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then return end
  local pickers = snacks.picker.get({ source = "git_tree" }) or {}
  if #pickers > 0 then
    for _, p in ipairs(pickers) do pcall(p.close, p) end
  else
    snacks.picker.git_tree()
  end
end

local function leader_discard()
  local picker, item = current_picker_item()
  if not picker or not item or not item.file or item.dir then return end
  local rel = vim.fn.fnamemodify(item.file, ":~:.")
  vim.ui.select({ "Yes, discard", "Cancel" },
    { prompt = "Discard changes to " .. rel .. "?" },
    function(choice)
      if choice ~= "Yes, discard" then return end
      local cwd = vim.fn.getcwd()
      local quoted = "'" .. cwd:gsub("'", "'\\''") .. "'"
      local file_q = "'" .. item.file:gsub("'", "'\\''") .. "'"
      os.execute("git -C " .. quoted .. " restore -- " .. file_q .. " 2>/dev/null")
      -- restore doesn't touch untracked files; clean -f removes them.
      os.execute("git -C " .. quoted .. " clean -f -- " .. file_q .. " 2>/dev/null")
      invalidate_status_cache()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == item.file then
          vim.api.nvim_buf_call(buf, function() vim.cmd("checktime") end)
        end
      end
      pcall(picker.find, picker)
    end
  )
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      -- Renders normally, then for partial-staged files (item.partial_staged)
      -- swaps the status icon to the purple staged glyph. See util/git-format.
      local function git_tree_format(item, picker)
        local result = require("snacks.picker.format").file(item, picker)
        if item.partial_staged then
          require("util.git-format").mark_partial_staged(result, picker)
        end
        return result
      end

      opts.picker.sources.git_tree = vim.tbl_deep_extend("force",
        opts.picker.sources.git_tree or {}, {
          finder = git_tree_finder,
          format = git_tree_format,
          tree = true,
          formatters = { file = { filename_only = true } },
          matcher = { sort_empty = false, fuzzy = false },
          auto_close = false,
          preview = false,
          focus = false,
          show_empty = true,
          -- List on top (tree at row 0), input pinned at the bottom as one
          -- borderless row. auto_hide / layout-hidden can't drop the input —
          -- they close its scratch window and the explorer-derived actions
          -- crash on the next input:set(). Keeping it alive is the workaround.
          layout = {
            preset = "sidebar",
            preview = false,
            layout = {
              box = "vertical",
              position = "right",
              width = RIGHT_SIDEBAR_WIDTH,
              { win = "list",  border = "none" },
              { win = "input", height = 1, border = "none" },
            },
          },
          confirm = open_file,
          -- Named actions go through snacks's resolver (captures the picker via
          -- closure). Function-form key handlers get `self = the snacks.win`,
          -- so a plain inline function crashes inside toggle_focus.
          actions = {
            exit_search = function(picker)
              if vim.fn.mode():sub(1, 1) == "i" then vim.cmd.stopinsert() end
              -- Clear the search term so the list shows everything again.
              if picker.input and picker.input.set then
                pcall(picker.input.set, picker.input, "", "")
              end
              require("snacks.picker.actions").toggle_focus(picker)
            end,
            git_tree_refresh = function(picker)
              invalidate_status_cache()
              picker:find()
            end,
            git_tree_stage = function(picker)
              local Actions = require("snacks.picker.actions")
              -- Capture cursor/top NOW: snacks's internal refresh (fired by
              -- git_stage) clears the target before our deferred find runs, so
              -- re-force them after.
              local saved_cursor = picker.list and picker.list.cursor or nil
              local saved_top = picker.list and picker.list.top or nil
              Actions.git_stage(picker)
              -- git_stage runs git async and calls picker:refresh() when done;
              -- invalidate the cache shortly after so the next find is fresh.
              vim.defer_fn(function()
                invalidate_status_cache()
                if picker.list and picker.list.set_target and saved_cursor then
                  pcall(picker.list.set_target, picker.list,
                        saved_cursor, saved_top, { force = true })
                end
                pcall(picker.find, picker)
              end, 200)
            end,
          },
          win = {
            list = {
              keys = {
                ["s"] = "git_tree_stage",
                ["r"] = "git_tree_refresh",
                -- <Esc> inert in the list (default `cancel` would close the
                -- picker; exit_search would flip focus to the input).
                ["<Esc>"] = { function() end, mode = { "n" } },
              },
            },
            input = {
              keys = {
                ["s"] = { "git_tree_stage", mode = { "n" } },
                ["r"] = { "git_tree_refresh", mode = { "n" } },
                ["<Esc>"] = { "exit_search", mode = { "i", "n" } },
              },
            },
          },
        })
    end,
    keys = {
      { "<leader>gt", leader_toggle,         desc = "Git: toggle tree sidebar" },
      { "<leader>gs", leader_stage,          desc = "Git: stage/unstage current file" },
      { "<leader>gr", leader_refresh,        desc = "Git: refresh tree sidebar" },
      -- <leader>gD (capital), not gd: gd is diffview's open (merge.lua). Both
      -- bound gd once and clobbered each other by lazy load order.
      { "<leader>gD", leader_open_with_diff, desc = "Git: open file with diff vs HEAD" },
      { "<leader>gx", leader_discard,        desc = "Git: discard changes (restore)" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          vim.schedule(function() require("snacks").picker.git_tree() end)
        end,
      })

      -- Unlist `nofile` buffers (e.g. gitsigns' diff scratch) so they don't
      -- appear as `[No Name]` tabs in the bufferline.
      vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function(args)
          if vim.bo[args.buf].buftype == "nofile" then
            vim.bo[args.buf].buflisted = false
          end
        end,
      })

      -- When you nav into the sidebar via window motion, vim picks the window
      -- your cursor row lines up with — often the bottom input. Bounce focus
      -- input → list, unless you came from the list itself (via `/`) or a
      -- search term is active (don't disrupt it).
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


      -- Follow the current file in the git tree: on opening a file, move the
      -- list cursor to its item (mirrors explorer's follow_file). Only changed
      -- files are in the tree, so a clean file leaves the highlight put. Skips
      -- when the picker is focused or a search is active.
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
          -- Fetch status async, then re-find from the warm cache. Doing it
          -- sync (invalidate + find, which runs a blocking io.popen) froze the
          -- UI ~1s per save in large repos.
          fetch_git_status_async(vim.fn.getcwd(), function()
            local ok, snacks = pcall(require, "snacks")
            if not ok or not snacks.picker then return end
            for _, p in ipairs(snacks.picker.get({ source = "git_tree" }) or {}) do
              -- Preserve cursor/top so the tree doesn't jump to the top on
              -- every save / focus-gain.
              if p.list and p.list.set_target then
                pcall(p.list.set_target, p.list)
              end
              pcall(p.find, p)
            end

            -- Force the LEFT explorer to re-read git status too. snacks caches
            -- explorer git status for 15 min, invalidated only by a `.git`
            -- fs-watcher (unreliable on macOS) — so in-editor git ops never
            -- showed up until reopen. Marking the cache stale (the watcher's
            -- own call) + re-find picks them up; explorer's finder re-runs
            -- `git status` on find, so this stays non-blocking.
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
        -- ShellCmdPost/TermClose catch `:!git ...` and terminal git;
        -- FocusGained catches an external terminal you tab back from.
        { "BufWritePost", "FocusGained", "DirChanged", "ShellCmdPost", "TermClose" },
        { callback = refresh_git_picker }
      )
      -- The two in-editor git paths that touch the index without a save or
      -- focus change: fugitive fires User FugitiveChanged, gitsigns hunk-staging
      -- fires User GitSignsUpdate. Debounced, so the GitSignsUpdate storm during
      -- editing collapses into one refresh.
      vim.api.nvim_create_autocmd("User", {
        pattern = { "FugitiveChanged", "GitSignsUpdate" },
        callback = refresh_git_picker,
      })

      -- One window left in diff mode means its partner went away. If the orphan
      -- holds a scratch (nofile) buffer like gitsigns' HEAD view, close it; if a
      -- normal file, just turn diff mode off so the file stays visible.
      local function cleanup_orphan_diff()
        local diff_wins = {}
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(w) and vim.wo[w].diff then
            table.insert(diff_wins, w)
          end
        end
        if #diff_wins ~= 1 then return false end
        local orphan = diff_wins[1]
        local buf = vim.api.nvim_win_get_buf(orphan)
        if vim.bo[buf].buftype == "nofile" then
          pcall(vim.api.nvim_win_close, orphan, true)
        else
          pcall(function() vim.wo[orphan].diff = false end)
        end
        return true
      end

      -- Wipe orphaned listed buffers so :q closes both window and tab, and clean
      -- up orphaned diff windows when their partner goes away.
      vim.api.nvim_create_autocmd("WinClosed", {
        callback = function(args)
          local closed_win = tonumber(args.match)
          local closed_buf = closed_win and vim.api.nvim_win_get_buf(closed_win)
          vim.schedule(function()
            if vim.v.exiting ~= vim.NIL and vim.v.exiting ~= nil then return end
            if #vim.api.nvim_list_wins() == 0 then return end

            local cleaning_diff = cleanup_orphan_diff()

            if not cleaning_diff
                and closed_buf
                and vim.api.nvim_buf_is_valid(closed_buf)
                and vim.bo[closed_buf].buftype == ""
                and vim.bo[closed_buf].buflisted then
              local still_shown = false
              for _, w in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_get_buf(w) == closed_buf then
                  still_shown = true
                  break
                end
              end
              if not still_shown then
                pcall(vim.api.nvim_buf_delete, closed_buf, {})
              end
            end
          end)
        end,
      })

      -- <leader>bd (Snacks.bufdelete) keeps the window but pulls the file out —
      -- no WinClosed fires, so re-check for orphaned diffs on buffer removal.
      vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        callback = function()
          vim.schedule(function()
            cleanup_orphan_diff()
          end)
        end,
      })
    end,
  },
}
