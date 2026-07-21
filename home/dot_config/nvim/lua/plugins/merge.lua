return {
  -- Inline conflict resolution: <leader>co/ct/cb/c0 to choose ours/theirs/
  -- both/none, ]x and [x to jump between conflicts.
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPre",
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      list_opener = "copen",
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
  },

  -- 3-way diff view for file-by-file merge resolution. :DiffviewOpen
  -- during a merge shows OURS | BASE | THEIRS panels.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>",         desc = "Diffview: open" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>",  desc = "Diffview: repo history" },
      -- Review the current branch as a PR: diff against a base ref using
      -- `base...HEAD` (triple-dot = merge-base range, i.e. exactly what
      -- this branch changed, ignoring commits that landed on the base
      -- since it forked). The prompt is pre-filled with the remote's
      -- default branch (origin/HEAD → origin/main or origin/master), so
      -- <CR> reviews vs the default branch; edit it to diff against any
      -- other branch, tag, or commit.
      {
        "<leader>gm",
        function()
          local base = vim.fn.systemlist({ "git", "rev-parse", "--abbrev-ref", "origin/HEAD" })
          base = (vim.v.shell_error == 0 and base[1] and base[1] ~= "") and base[1] or "origin/main"
          vim.ui.input({ prompt = "Diffview — review vs base: ", default = base }, function(ref)
            if ref and ref ~= "" then
              vim.cmd("DiffviewOpen " .. ref .. "...HEAD")
            end
          end)
        end,
        desc = "Diffview: review branch vs base (PR)",
      },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed", -- 3-way layout for conflicts
          disable_diagnostics = true,
        },
      },
    },
  },
}
