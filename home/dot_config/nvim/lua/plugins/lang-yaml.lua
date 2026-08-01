-- Format YAML with prettier via conform, so per-project `.prettierrc` is
-- honored (keeps flow sequences inline where a repo sets a large printWidth).
-- Without this, conform has no YAML formatter and LazyVim falls back to
-- yaml-language-server, whose bundled formatter ignores project prettier config.
return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "prettier" } },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        yaml = { "prettier" },
      },
    },
  },
}
