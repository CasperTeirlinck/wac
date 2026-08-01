-- dbt syntax highlighting.
--
-- dbt models/macros are `.sql` files that are mostly Jinja (`{% macro %}`,
-- `{{ ref() }}`) interleaved with often-fragmentary SQL. Treesitter's `sql`
-- parser (via LazyVim's lang.sql extra) mangles the Jinja, and a jinja+sql
-- treesitter injection can't cope with the incomplete SQL fragments between
-- control-flow tags. `chrismaher/vim-dbt` sidesteps this with regex syntax:
-- it pulls in `syntax/sql.vim` for real SQL keywords and layers Jinja regions
-- on top, degrading gracefully on fragments.
--
-- Detection: any `.sql` file inside a dbt project (a `dbt_project.yml` exists
-- at or above it) gets `filetype=dbt`; plain `.sql` elsewhere stays `sql` so
-- LazyVim's SQL LSP/treesitter still applies there. filetype=dbt has no
-- treesitter parser, so Vim's regex syntax (syntax/dbt.vim) takes over.
--
-- Note: filetype=dbt means the SQL LSP won't attach to dbt files — that's
-- intentional; sql language servers choke on Jinja anyway.
return {
  {
    "chrismaher/vim-dbt",
    ft = "dbt",
    init = function()
      -- Runs during startup (before the startup buffer is read), so the
      -- first `.sql` opened is detected correctly.
      vim.filetype.add({
        extension = {
          sql = function(path)
            if vim.fs.root(path, "dbt_project.yml") then
              return "dbt"
            end
            return "sql"
          end,
        },
      })
    end,
    config = function()
      -- The plugin's bundled ftdetect walks upward to $HOME and infinite-loops
      -- on any `.sql` outside $HOME. We do detection ourselves (init above), so
      -- neutralise its detection function — the autocmd still fires, but no-ops.
      --
      -- Deferred: on the buffer that triggers the plugin load, DetectDBT() is
      -- what set filetype=dbt and is still on the call stack, so redefining it
      -- now throws E127 ("Cannot redefine function ... It is in use").
      -- vim.schedule runs after that call unwinds.
      vim.schedule(function()
        vim.cmd([[
          function! DetectDBT() abort
          endfunction
        ]])
      end)
    end,
  },
}
