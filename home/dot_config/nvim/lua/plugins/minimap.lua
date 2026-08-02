-- codewindow.nvim: compact buffer overview docked at the right edge of the
-- focused editor window (relative='win', so it sits left of the git_tree
-- sidebar without repositioning).
--   <leader>m   toggle (sticky — survives window switches)
--   <leader>mf  focus
--
-- Sticky-disable: codewindow's `auto_enable` blindly reopens on BufEnter/
-- WinEnter with no "user turned it off" notion, so <leader>m only lasts until
-- the next window switch. We set auto_enable=false and drive our own auto-open
-- autocmd gated on vim.g.minimap_disabled, which the toggle flips.
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
      -- codewindow's highlight.lua requires `nvim-treesitter.ts_utils` when
      -- use_treesitter is truthy, but that module was removed in
      -- nvim-treesitter's main branch (LazyVim uses it), so the require chain
      -- explodes before setup() runs. It only needs `get_vim_range`, so shim
      -- exactly that (verbatim from the old impl: 0-indexed end-exclusive TS
      -- range → 1-indexed Vim range) into package.loaded first. The pcall lets
      -- a real ts_utils win if master is ever used again.
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

      -- Mutate the config before the main module loads so highlight.lua sees
      -- use_treesitter=true at its module-load gate.
      require("codewindow.config").setup({ use_treesitter = true })

      require("codewindow").setup({
        -- Our autocmd below drives auto-open (gated on the sticky flag).
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
      -- codewindow's built-in `git diff -U0`, which only reports unstaged
      -- tracked changes — so untracked and staged files showed nothing even
      -- though gitsigns painted them in the gutter. gitsigns marks untracked
      -- files as all-adds, so the minimap matches the gutter. parse_git_diff
      -- only gets `lines`, but the minimap follows the focused window so the
      -- current buffer is the one rendered; we rebuild the same per-line
      -- add/remove bitmask the original used, leaving downstream rendering
      -- unchanged.
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
          -- Deletion marker for pure deletes or a net-removing hunk.
          if acount == 0 or rcount > acount then
            local mark = math.max(astart, 1)
            if mark <= nlines then
              removes[mark] = true
            end
          end
        end

        -- Aggregate per-line changes into the minimap's 4:1 braille glyphs
        -- exactly as codewindow's renderer did — only the data source changed.
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

      -- Replacement auto-open: reopen on buffer/window enter (so it follows the
      -- focused window, like auto_enable did) unless stickily disabled.
      -- open_minimap is a safe no-op on sidebars / special buffers.
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

      -- Repaint when gitsigns' hunks arrive. gitsigns computes hunks async but
      -- codewindow renders synchronously on BufEnter, so a freshly opened file's
      -- git column drew empty until the next unrelated update. gitsigns fires
      -- User GitSignsUpdate when its signs are ready; re-rendering then (via the
      -- idempotent open_minimap) populates the column immediately.
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
