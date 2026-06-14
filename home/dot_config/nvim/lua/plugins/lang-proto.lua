-- Protobuf language support — LSP via `protols` (lightweight, dedicated),
-- treesitter parser, and filetype hookup. If this project ever adopts the
-- Buf toolchain (buf.yaml), swap `protols` for `buf_ls` (`buf beta lsp`).
return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "protols" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        protols = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "proto" } },
  },
}
