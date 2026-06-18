-- codewindow.nvim: compact overview of the current buffer, docked at the
-- right edge of the focused editor window (NOT the screen — so it sits
-- naturally to the left of the snacks git_tree sidebar float without any
-- nvim_win_set_config repositioning).
--
-- Toggle:  <leader>m
-- Focus:   <leader>mf
return {
  {
    "gorbit99/codewindow.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>m",  function() require("codewindow").toggle_minimap() end, desc = "Minimap: toggle" },
      { "<leader>mf", function() require("codewindow").toggle_focus()   end, desc = "Minimap: focus" },
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
        auto_enable = true,
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
    end,
  },
}
