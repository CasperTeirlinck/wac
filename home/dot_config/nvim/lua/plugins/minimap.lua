-- mini.map: compact right-side overview of the current buffer with
-- coloured markers for git changes (via gitsigns), search hits, and
-- diagnostics.
--
-- Toggle:  <leader>m
-- Focus:   <leader>mf   (jump cursor into the map window for keyboard nav)
-- Refresh: auto on common edit / git events.

return {
  {
    "nvim-mini/mini.map",
    version = false,
    event = "VeryLazy",
    keys = {
      { "<leader>m",  function() require("mini.map").toggle()             end, desc = "Minimap: toggle" },
      { "<leader>mf", function() require("mini.map").toggle_focus(false) end, desc = "Minimap: focus" },
    },
    config = function()
      local map = require("mini.map")

      map.setup({
        integrations = {
          map.gen_integration.builtin_search(),
          map.gen_integration.gitsigns(),
          map.gen_integration.diagnostic(),
        },
        symbols = {
          encode = map.gen_encode_symbols.dot("4x2"),
        },
        window = {
          side         = "right",
          width        = 10,
          winblend     = 0,
          show_integration_count = false,
          -- Snacks pickers (git_tree) default to zindex 50. Keep mini.map
          -- at the same layer; the repositioning below makes overlap
          -- a non-issue when both are visible.
          zindex       = 50,
        },
      })

      -- mini.map opens with `anchor = "NE", col = vim.o.columns`, so it
      -- sits at the screen's right edge. When the snacks git_tree picker
      -- is also visible (a width=35 float at the same right edge), we
      -- want the minimap to dock at the left edge of THAT float instead
      -- so they sit side-by-side. Achieved by tweaking the float's `col`
      -- after open/refresh via nvim_win_set_config.
      -- Returns the screen column where the git_tree picker's sidebar
      -- starts. snacks layouts store their resolved screen position in
      -- `layout.screenpos` (col is 1-indexed). Root window's opts.col is
      -- layout-relative (always 0 here) — `screenpos.col` is what we want.
      -- nil when the picker isn't open.
      local function git_sidebar_left_col()
        local ok, snacks = pcall(require, "snacks")
        if not ok or not snacks.picker then return nil end
        local pickers = snacks.picker.get({ source = "git_tree" }) or {}
        for _, p in ipairs(pickers) do
          local sp = p.layout and p.layout.screenpos
          if sp and sp.col and sp.col > 1 then
            -- screenpos is 1-indexed; nvim_win_set_config col is 0-indexed.
            return sp.col - 1
          end
        end
        return nil
      end

      local function get_minimap_win()
        local cur = map.current
        if not cur or not cur.win_data then return nil end
        return cur.win_data[vim.api.nvim_get_current_tabpage()]
      end

      -- Number of rows the tabline occupies (bufferline forces showtabline=2).
      -- mini.map opens with row=0 which sits on top of that tabline; we shift
      -- the float down by this many rows so it docks under the buffer tabs.
      local function tabline_height()
        local s = vim.o.showtabline
        if s == 2 then return 1 end
        if s == 1 and vim.fn.tabpagenr("$") > 1 then return 1 end
        return 0
      end

      local function reposition()
        local win = get_minimap_win()
        if not win or not vim.api.nvim_win_is_valid(win) then return end
        local target_col = git_sidebar_left_col() or vim.o.columns
        local th = tabline_height()
        local cfg = vim.api.nvim_win_get_config(win)
        -- mini.map opens with anchor=NE and col=vim.o.columns (right edge
        -- of the screen). Force these explicitly each call so we keep
        -- the right-edge-anchored behavior even when `get_config` returns
        -- a partial table or after some other code repositions the float.
        cfg.relative  = "editor"
        cfg.anchor    = "NE"
        cfg.col       = target_col
        -- Push the float below the tabline and shrink height to match, so
        -- it stops at the global statusline instead of overflowing it. At
        -- VeryLazy / startup time mini.map's own height computation runs
        -- before the tabline is drawn, which is the root cause of the
        -- "overlaps the buffer tab bar" symptom on first paint.
        cfg.row       = th
        cfg.height    = math.max(1, vim.o.lines - th - 1 - vim.o.cmdheight)
        pcall(vim.api.nvim_win_set_config, win, cfg)
      end

      -- Wrap MiniMap.refresh so EVERY refresh (including mini.map's own
      -- internal CursorMoved / WinScrolled / ModeChanged handlers) triggers
      -- our reposition. Without this the col gets reset to vim.o.columns
      -- by H.update_window_opts on every scroll and the dock is lost.
      local orig_refresh = map.refresh
      map.refresh = function(...)
        orig_refresh(...)
        reposition()
      end

      -- Wrap MiniMap.open so reposition runs on every open (incl. the
      -- `<leader>m` toggle), not just the initial deferred open below.
      local orig_open = map.open
      map.open = function(...)
        orig_open(...)
        reposition()
      end

      local group = vim.api.nvim_create_augroup("MinimapAutoRefresh", { clear = true })
      -- Re-dock on window-tree changes too (git sidebar toggle, resize,
      -- close) — those don't always coincide with a refresh event.
      -- WinResized catches manual float resizes of the snacks sidebar.
      vim.api.nvim_create_autocmd(
        { "WinNew", "WinClosed", "WinResized", "VimResized", "TabEnter" },
        { group = group, callback = reposition }
      )

      -- Don't let the minimap follow the cursor into sidebar buffers.
      -- mini.map's BufEnter handler retargets `buf_data.source` to the
      -- new buffer if it passes `is_proper_buftype`; setting the buffer-
      -- local `minimap_disable` flag makes mini.map's early-return skip
      -- those refreshes so the map keeps pointing at the last real file.
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "snacks_picker_*", "snacks_dashboard", "neo-tree", "NvimTree" },
        callback = function(args)
          vim.b[args.buf].minimap_disable = true
        end,
      })

      -- Deferred auto-open. Calling `map.open()` eagerly inside `config`
      -- (on VeryLazy) fires while the dashboard / neo-tree is the current
      -- window, so mini.map locks its source onto that buffer and you
      -- get a "random" map of dashboard ASCII art on first paint. Wait
      -- for the first proper file buffer to be entered, open then, and
      -- self-disable. The fallback opens after a beat in case the user
      -- launched straight into a real file with no intervening event.
      local function is_proper_source()
        local buftype = vim.bo.buftype
        local ft      = vim.bo.filetype
        if buftype ~= "" then return false end
        local skip = {
          snacks_dashboard = true, alpha = true, starter = true,
          ["neo-tree"]     = true, NvimTree = true,
        }
        if skip[ft] or ft:match("^snacks_picker") then return false end
        return true
      end

      local opened = false
      local function try_open()
        if opened then return end
        if not is_proper_source() then return end
        opened = true
        map.open()  -- our wrap above calls reposition()
      end

      vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter" }, {
        group = group, callback = try_open,
      })
      -- Fallback: if Neovim was launched straight into a real file
      -- (e.g. `nvim foo.lua`) the BufEnter for it may already have
      -- fired before this plugin's config runs, so schedule one shot.
      vim.schedule(try_open)
    end,
  },
}
