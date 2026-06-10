-- Justfile language support (https://github.com/casey/just).
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "just" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        just = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        just = { "just" },
      },
      formatters = {
        just = {
          command = "just",
          args = { "--fmt", "--unstable", "--justfile", "$FILENAME" },
          stdin = false,
        },
      },
    },
  },
}
