-- codewindow.nvim: compact overview of the current buffer, docked at the
-- right edge of the focused editor window (NOT the screen — so it sits
-- naturally to the left of the snacks git_tree sidebar float without any
-- nvim_win_set_config repositioning).
--
-- Toggle:  <leader>m   (sticky — stays hidden across window switches)
-- Focus:   <leader>mf
--
-- Sticky-disable: codewindow's `auto_enable = true` registers a
-- BufEnter/WinEnter autocmd that blindly reopens the minimap, with no
-- notion of "the user turned it off" — so closing it via <leader>m only
-- lasts until the next window switch (e.g. returning from the git
-- sidebar). We replace that behavior: `auto_enable = false` makes the
-- plugin's autocmd inert, and we run our own auto-open autocmd gated on
-- `vim.g.minimap_disabled`. The toggle flips that flag, so a disable
-- sticks until you explicitly re-enable.
return {
  {
    "gorbit99/codewindow.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>m",
        function()
          vim.g.minimap_disabled = not vim.g.minimap_disabled
          if vim.g.minimap_disabled then
            require("codewindow").close_minimap()
          else
            require("codewindow").open_minimap()
          end
        end,
        desc = "Minimap: toggle (sticky)",
      },
      { "<leader>mf", function() require("codewindow").toggle_focus() end, desc = "Minimap: focus" },
    },
    config = function()
      -- codewindow's `highlight.lua` `require`s `nvim-treesitter.ts_utils`
      -- when `use_treesitter` is truthy. That module was removed in
      -- nvim-treesitter's `main` branch (used by LazyVim), so the transitive
      -- require chain explodes before `setup()` can do anything. But the
      -- only thing codewindow uses from it is `get_vim_range`, so we shim
      -- exactly that (a verbatim copy of nvim-treesitter's old impl: convert
      -- a 0-indexed, end-exclusive TS node range to a 1-indexed Vim range)
      -- and inject it into package.loaded BEFORE codewindow is required.
      -- The pcall first lets a real ts_utils win if the master branch is
      -- ever used again; the shim only fills in when it's genuinely absent.
      if not pcall(require, "nvim-treesitter.ts_utils") then
        package.loaded["nvim-treesitter.ts_utils"] = {
          get_vim_range = function(range, buf)
            local srow, scol, erow, ecol = range[1], range[2], range[3], range[4]
            srow = srow + 1
            scol = scol + 1
            erow = erow + 1
            if ecol == 0 then
              erow = erow - 1
              if not buf or buf == 0 then
                ecol = vim.fn.col({ erow, "$" }) - 1
              else
                local l = vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
                ecol = l and #l or 0
              end
              ecol = math.max(ecol, 1)
            end
            return srow, scol, erow, ecol
          end,
        }
      end

      -- Pre-mutate the config BEFORE the main module is required so
      -- highlight.lua sees use_treesitter=true at its module-load gate.
      require("codewindow.config").setup({ use_treesitter = true })

      require("codewindow").setup({
        -- Our own autocmd below drives auto-open (gated on the sticky
        -- flag); the plugin's built-in one would ignore it. See header.
        auto_enable = false,
        exclude_filetypes = {
          "help",
          "snacks_dashboard",
          "snacks_picker_list",
          "snacks_picker_input",
          "snacks_picker_preview",
          "neo-tree",
          "NvimTree",
          "alpha",
          "starter",
        },
        minimap_width = 10,
        screen_bounds = "lines",
        window_border = "none",
        relative = "win",
        use_treesitter = true,
      })

      -- Drive the minimap's git column from gitsigns' hunks instead of
      -- codewindow's built-in `git diff -U0 <file>`. That shell-out only
      -- reports *unstaged, tracked* changes, so untracked files (no diff
      -- output) and staged changes showed nothing in the minimap even
      -- though gitsigns painted them in the editor gutter — the exact
      -- "shows in the editor but not the minimap, for some files only"
      -- mismatch. Sourcing from gitsigns guarantees the minimap matches
      -- the gutter (gitsigns marks untracked files as all-adds, etc.).
      -- parse_git_diff only receives `lines`, but the minimap follows the
      -- focused window, so the current buffer is the one being rendered.
      -- We rebuild the same per-line add/remove bitmask aggregation the
      -- original used, so the downstream rendering is unchanged.
      local cw_git = require("codewindow.git")
      local cw_utils = require("codewindow.utils")
      cw_git.parse_git_diff = function(lines)
        local nlines = #lines
        local git_lines = {}
        local ok, gs = pcall(require, "gitsigns")
        if not ok or type(gs.get_hunks) ~= "function" then
          return git_lines
        end
        local hunks = gs.get_hunks(vim.api.nvim_get_current_buf())
        if not hunks then
          return git_lines
        end

        local adds, removes = {}, {}
        for _, h in ipairs(hunks) do
          local a = h.added or {}
          local astart, acount = a.start or 0, a.count or 0
          for i = astart, astart + acount - 1 do
            if i >= 1 and i <= nlines then
              adds[i] = true
            end
          end
          local rcount = (h.removed or {}).count or 0
          -- Deletion marker for pure deletes (no added lines) or a hunk
          -- that net-removes lines — mirrors a gitsigns delete sign.
          if acount == 0 or rcount > acount then
            local mark = math.max(astart, 1)
            if mark <= nlines then
              removes[mark] = true
            end
          end
        end

        -- Aggregate per-line changes into the minimap's 4:1 braille glyphs
        -- exactly as codewindow's built-in renderer did, so the indicators
        -- look identical to the default — we've only swapped the data source
        -- (gitsigns hunks instead of `git diff`).
        local minimap_height = math.ceil(nlines / 4)
        for y = 1, minimap_height do
          local a_flag, d_flag = 0, 0
          for dy = 1, 4 do
            local line_y = (y - 1) * 4 + dy
            if adds[line_y] then
              a_flag = a_flag + math.pow(2, dy - 1)
            end
            if removes[line_y] then
              d_flag = d_flag + math.pow(2, dy - 1)
            end
          end
          git_lines[y] = cw_utils.flag_to_char(a_flag) .. cw_utils.flag_to_char(d_flag)
        end
        return git_lines
      end

      -- Replacement auto-open: reopen the minimap on buffer/window enter
      -- (so it follows the focused editor window, like auto_enable did),
      -- but bail out when the user has stickily disabled it. open_minimap
      -- is a safe no-op on sidebars / special buffers (codewindow's
      -- should_ignore checks exclude_filetypes + buftype), so no filtering
      -- is needed here.
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = vim.api.nvim_create_augroup("minimap_sticky_autoopen", { clear = true }),
        callback = function()
          if vim.g.minimap_disabled then
            return
          end
          vim.schedule(function()
            require("codewindow").open_minimap()
          end)
        end,
      })

      -- Repaint when gitsigns' hunks become available. gitsigns computes
      -- hunks asynchronously, but codewindow renders the minimap
      -- synchronously on BufEnter — so on a freshly opened file the git
      -- column drew empty (hunks didn't exist yet) and stayed empty until
      -- the next unrelated minimap update (a cursor move, a text change).
      -- gitsigns fires `User GitSignsUpdate` once its signs are ready;
      -- re-rendering then (open_minimap is the idempotent refresh path the
      -- auto-open autocmd above already uses) populates the git column
      -- immediately. Gated on the sticky-disable flag like the rest.
      vim.api.nvim_create_autocmd("User", {
        pattern = "GitSignsUpdate",
        group = vim.api.nvim_create_augroup("minimap_gitsigns_refresh", { clear = true }),
        callback = function()
          if vim.g.minimap_disabled then
            return
          end
          vim.schedule(function()
            pcall(function()
              require("codewindow").open_minimap()
            end)
          end)
        end,
      })
    end,
  },
}
