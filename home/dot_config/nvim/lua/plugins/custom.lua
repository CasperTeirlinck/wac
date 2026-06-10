return {
  {
    "navarasu/onedark.nvim",
    opts = {
      style = "dark",
      colors = {
        black = "#21252b",
        bg0 = "#21252b",
        bg1 = "#21252b",
      },
      highlights = {
        Normal = { bg = "#21252b" },
        NormalFloat = { bg = "#21252b" },
        SignColumn = { bg = "#21252b" },
        EndOfBuffer = { bg = "#21252b" },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },
  -- smart-splits: multiplexer-agnostic pane navigation, used by the
  -- nav() keymaps in config/keymaps.lua as the fall-through when no
  -- nvim window is found in the requested direction. Auto-detects
  -- tmux/zellij/wezterm/kitty from environment.
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = {},
  },
}
