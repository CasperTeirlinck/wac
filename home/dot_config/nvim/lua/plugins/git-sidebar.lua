-- Persistent right-side "Source Control" sidebar with a TREE view of git
-- changes. Built on a custom snacks picker source so we get tree
-- rendering + fast `git status` data, without committing snacks source
-- code into our repo.

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

-- Set of paths the user has collapsed in the git tree sidebar.
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
  -- Poll for gitsigns to attach to the new buffer before calling
  -- diffthis. The defer-by-100ms approach raced when gitsigns took
  -- longer to attach, causing the diff to silently no-op.
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

-- Cache of `git status` output. Invalidated explicitly when git state
-- may have changed (file save, focus gain, stage action, manual refresh)
-- so that folder toggles re-render instantly without re-running git.
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

-- Async status fetch: runs `git status` off the main loop, fills the
-- cache, then invokes `cb`. The event-driven refresh (save / focus-gain)
-- uses this instead of the blocking io.popen so a slow `git status`
-- (huge working trees — e.g. ~1s in ov-dp3-data-projects) can't freeze
-- the UI. read_git_status stays as the synchronous cache-miss fallback
-- for user-initiated finds (initial open, folder toggles), which read
-- the warm cache this fills.
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

-- Custom finder: builds a tree of git-changed files with parent dirs.
-- Uses cached status data so folder collapse/expand is instant.
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

    -- When the index (X) is staged AND the worktree (Y) has a fresh
    -- change on top (e.g. "MM", "AM"), snacks's git_status treats the
    -- file as fully staged because the first char matches the staged
    -- pattern — purple S icon, no hint that there are uncommitted
    -- edits. Force the display status to the worktree side AND tag the
    -- item so our custom formatter can render the staged icon (purple
    -- ●) alongside the modified filename color (orange).
    local function display_status(xy)
      local x, y = xy:sub(1, 1), xy:sub(2, 2)
      if x:match("[MADRC]") and y:match("[MD]") then
        return " " .. y, true
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

    -- Propagate file statuses up to ancestor directories so a collapsed
    -- folder can display the aggregate status icon/color.
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

    -- Hide items whose ancestor is collapsed; set `open` flag on dirs
    -- so the formatter shows open vs closed folder icons correctly.
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
          -- Show git status on collapsed dirs (matches snacks.explorer
          -- behavior: closed folder picks up the aggregate child status).
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

-- Helpers used by the leader-key shortcuts below: find the active
-- git_tree picker and its currently-highlighted item.
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
      os.execute("git -C " .. quoted .. " clean -f -- " .. file_q .. " 2>/dev/null")
      -- For untracked files: `restore` doesn't handle them; clean -f removes.
      invalidate_status_cache()
      -- Reload the affected buffer if it's open
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
      -- Format wrapper: renders normally via the built-in file format,
      -- but for files whose XY status combines a staged change AND a
      -- fresh worktree change (item.partial_staged), it replaces the
      -- right-aligned status icon with the staged glyph (●) colored
      -- purple, while leaving the filename in the modified (orange)
      -- color the underlying format already applied. This makes
      -- partial-staged files visually distinct from both fully-staged
      -- and fully-unstaged files.
      local function git_tree_format(item, picker)
        local Format = require("snacks.picker.format")
        local result = Format.file(item, picker)
        if not item.partial_staged then return result end
        local staged_icon = (picker.opts.icons.git or {}).staged or "●"
        for _, chunk in ipairs(result) do
          if chunk.virt_text_pos == "right_align" and chunk.virt_text then
            chunk.virt_text[1] = { staged_icon, "SnacksPickerGitStatusStaged" }
          end
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
          -- Custom layout: list on top (so the git tree starts at row 0
          -- of the sidebar), input pinned at the bottom as a single
          -- borderless row. We can't use auto_hide / layout-hidden to
          -- drop the input — they close its scratch window, and the
          -- explorer-derived picker actions crash the next time
          -- input:set() runs. Keeping the input alive at the bottom is
          -- the simplest workaround that also gives us list at row 0.
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
          -- Picker-local actions and keybinds:
          --   r = refresh (manual cache-invalidating reload)
          --   s = stage/unstage current file then refresh
          actions = {
            -- A named action goes through snacks's action resolver, which
            -- captures the picker via closure. Function-form key handlers
            -- receive `self = the snacks.win`, so a plain inline function
            -- crashes inside toggle_focus because the win has no .input.
            exit_search = function(picker)
              if vim.fn.mode():sub(1, 1) == "i" then vim.cmd.stopinsert() end
              -- Clear the search term so the list goes back to showing
              -- everything. Without this, the filter stays active and
              -- the list keeps showing only matched items even though
              -- the input row at the bottom is visually empty.
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
              -- Capture cursor/top NOW: snacks's internal refresh (fired
              -- by git_stage) consumes-and-clears the target before our
              -- deferred find runs, so we have to re-force them after.
              local saved_cursor = picker.list and picker.list.cursor or nil
              local saved_top = picker.list and picker.list.top or nil
              Actions.git_stage(picker)
              -- snacks's git_stage runs git asynchronously and calls
              -- picker:refresh() when done. Invalidate our cache shortly
              -- after so the next refresh fetches fresh status.
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
                -- <Esc> defaults to `cancel` which closes the picker;
                -- we want it inert in the list (stay in normal mode).
                -- Don't reuse exit_search — that calls toggle_focus
                -- which would flip you to the input.
                ["<Esc>"] = { function() end, mode = { "n" } },
              },
            },
            input = {
              keys = {
                ["s"] = { "git_tree_stage", mode = { "n" } },
                ["r"] = { "git_tree_refresh", mode = { "n" } },
                -- See exit_search above for the stopinsert dance and
                -- why we route through a named action instead of an
                -- inline function.
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
      -- <leader>gD (capital), not gd: gd is diffview's open (plugins/merge.lua).
      -- They previously both bound gd and clobbered each other nondeterministically
      -- depending on lazy load order — which is why gd "sometimes" opened the
      -- wrong thing and went missing from which-key.
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

      -- Unlist any `nofile` buffers (e.g. gitsigns' diff scratch buffer)
      -- so they don't appear as `[No Name]` tabs in the bufferline.
      vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function(args)
          if vim.bo[args.buf].buftype == "nofile" then
            vim.bo[args.buf].buflisted = false
          end
        end,
      })

      -- The input row sits at the bottom of the sidebar; when you nav
      -- into the sidebar with <C-l>/smart-splits from the main editor,
      -- vim picks the window your cursor row lines up with — which is
      -- often the input. Bounce focus from input -> list whenever the
      -- previous window was NOT this picker's own list (i.e. you came
      -- from outside via window nav, not from `/`). When the input
      -- already has a search term, leave focus alone so an active
      -- search isn't disrupted.
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


      -- Debounced refresh of the git_tree picker on events that may
      -- have changed git state.
      local refresh_timer
      local function refresh_git_picker()
        if refresh_timer then
          refresh_timer:stop()
          refresh_timer:close()
        end
        refresh_timer = vim.defer_fn(function()
          refresh_timer = nil
          -- Fetch git status ASYNC, then re-find from the now-warm cache.
          -- The old path invalidated the cache and called find(), which
          -- ran a blocking io.popen `git status` on the UI thread —
          -- ~1s freeze on save in large repos. Now the git call is off
          -- the main loop and find() just reads the cache it filled.
          fetch_git_status_async(vim.fn.getcwd(), function()
            local ok, snacks = pcall(require, "snacks")
            if not ok or not snacks.picker then return end
            for _, p in ipairs(snacks.picker.get({ source = "git_tree" }) or {}) do
              -- Preserve cursor/top across the re-find, else the tree
              -- jumps back to the top on every save / focus-gain. Same
              -- pattern as open_file's folder-toggle and git_tree_stage.
              if p.list and p.list.set_target then
                pcall(p.list.set_target, p.list)
              end
              pcall(p.find, p)
            end
          end)
        end, 250)
      end
      vim.api.nvim_create_autocmd(
        { "BufWritePost", "FocusGained", "DirChanged" },
        { callback = refresh_git_picker }
      )

      -- Resolve an orphaned diff window: one window left in diff mode
      -- means its partner just went away. If the orphan holds a scratch
      -- (nofile) buffer like gitsigns' HEAD view, close that window. If
      -- it holds a normal file buffer, just turn off diff mode so the
      -- file stays visible without the diff highlighting.
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

      -- Wipe orphaned listed buffers so :q closes both window and tab,
      -- and clean up orphaned diff windows when their partner goes away.
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

      -- <leader>bd (Snacks.bufdelete) keeps the window alive but pulls
      -- the file out from under us — no WinClosed fires, but a buffer
      -- has gone away. Re-check for orphaned diffs after such events.
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
