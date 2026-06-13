return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    -- Load after startup so the WebSocket server is ready for any
    -- `claude` CLI process started in a tmux pane to discover.
    event = "VeryLazy",
    config = function(_, opts)
      require("claudecode").setup(opts)

      -- Patch the selection tracker so Select mode is treated like
      -- Visual mode. options.lua sets `selectmode = "key,mouse"`, so
      -- drag selections / shifted-key selections from insert mode land
      -- in Select mode (`s`/`S`/`<C-s>`). The plugin's internal mode
      -- checks (selection.lua:16, 258, 438, 458, …) hardcode v/V/<C-v>
      -- and therefore silently skip those selections.
      --
      -- The fix temporarily masks `vim.api.nvim_get_mode()` for the
      -- duration of update_selection() so every nested local helper
      -- (validate_visual_mode, get_effective_visual_mode, …) sees the
      -- Select mode as its Visual equivalent. The selection itself is
      -- read from the `'<` / `'>` marks, which Neovim sets in Select
      -- mode too — so no other plumbing needs to change.
      local sel = require("claudecode.selection")
      local select_to_visual = { s = "v", S = "V", ["\19"] = "\22" }
      local orig_update = sel.update_selection
      sel.update_selection = function(...)
        local m = (vim.api.nvim_get_mode() or {}).mode
        if not select_to_visual[m] then return orig_update(...) end
        local orig_get_mode = vim.api.nvim_get_mode
        vim.api.nvim_get_mode = function(...)
          local info = orig_get_mode(...)
          info.mode = select_to_visual[info.mode] or info.mode
          return info
        end
        local ok, err = pcall(orig_update, ...)
        vim.api.nvim_get_mode = orig_get_mode
        if not ok then error(err) end
      end
    end,
    keys = {
      { "<leader>a",  nil,                              desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer to context" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v", desc = "Send selection to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Deny diff" },
    },
  },
}
