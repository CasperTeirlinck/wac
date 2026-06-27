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
      -- codewindow's `highlight.lua` calls `config.get()` at module-load
      -- time and unconditionally `require`s `nvim-treesitter.ts_utils`
      -- when `use_treesitter` is truthy. That module was removed in
      -- nvim-treesitter's `main` branch (used by LazyVim), so simply
      -- passing `use_treesitter=false` to `setup()` is too late — the
      -- transitive require chain has already exploded.
      -- Pre-mutate the config BEFORE the main module is required.
      require("codewindow.config").setup({ use_treesitter = false })

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
        use_treesitter = false,
      })

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
    end,
  },
}
