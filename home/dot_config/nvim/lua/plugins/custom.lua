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

  { "christoomey/vim-tmux-navigator" },
}
