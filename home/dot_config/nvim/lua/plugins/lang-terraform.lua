-- Terraform tweaks on top of LazyVim's lang.terraform extra.
--
-- nvim-lint's terraform_validate runs `terraform -chdir=<file dir> validate`.
-- Two problems with the upstream behaviour:
--   1. -chdir uses :.:h (relative to nvim's cwd) which can resolve oddly.
--   2. When editing files in `modules/` — consumed by an env elsewhere in
--      the tree — there's no .terraform/ at or above the file, so validate
--      flags every `module "x"` block as "not installed" even though the
--      envs that use the module have been init'd.
--
-- Strategy: walk upward looking for a .terraform/. If found, chdir there
-- (absolute path, so cwd doesn't matter). If not found, return a no-op
-- linter so the buffer stays diagnostic-clean; terraform-ls still handles
-- syntax and references for module files.
return {
  {
    -- lspconfig's shipped terraformls on_attach calls vim.lsp.codelens.enable,
    -- which only exists on nvim 0.12+. On 0.11 it's nil and errors on every
    -- file open. Override on_attach with a version-guarded codelens call.
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = {
          on_attach = function(_, bufnr)
            if vim.lsp.codelens.enable then
              vim.lsp.codelens.enable(true, { bufnr = bufnr })
            else
              vim.lsp.codelens.refresh({ bufnr = bufnr })
            end
          end,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        terraform_validate = function()
          local buf = vim.api.nvim_buf_get_name(0)
          local marker = vim.fs.find(".terraform", { path = buf, upward = true })[1]
          if not marker then
            return {
              cmd = "true",
              args = {},
              stdin = false,
              stream = "stdout",
              ignore_exitcode = true,
              parser = function() return {} end,
            }
          end
          local cfg = require("lint.linters.terraform_validate")()
          cfg.args = { "-chdir=" .. vim.fn.fnamemodify(marker, ":h"), "validate", "-json" }
          return cfg
        end,
      },
    },
  },
}
