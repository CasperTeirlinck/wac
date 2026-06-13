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
        -- onedark defaults WinSeparator to bg3 (#3b3f4c) which is barely
        -- distinguishable from our Normal bg (#21252b) — the vertical
        -- bar between splits effectively disappears, e.g. on the left
        -- edge of the right git sidebar. Bump it to a clearly visible
        -- mid-grey. The autocmd below also force-sets SnacksWinSeparator
        -- (snacks's per-window remap of WinSeparator) — onedark's
        -- highlights table runs before snacks's plugin-load hook, so the
        -- link `SnacksWinSeparator -> WinSeparator` from snacks can get
        -- masked by an empty entry depending on load order. Setting both
        -- explicitly on every ColorScheme dodges that race.
        WinSeparator = { fg = "#5c6370" },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("CustomWinSeparator", { clear = true }),
        callback = function()
          vim.api.nvim_set_hl(0, "WinSeparator",      { fg = "#5c6370" })
          vim.api.nvim_set_hl(0, "SnacksWinSeparator", { fg = "#5c6370" })
        end,
      })
    end,
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
