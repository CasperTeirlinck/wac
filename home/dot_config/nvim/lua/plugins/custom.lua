-- Light/dark theme toggle. onedark.nvim ships a `light` style; `<leader>ut`
-- swaps between it and our tuned dark — live and persisted across restarts
-- (for presentations / light-background screenshots, then straight back).
--
-- Two things make this fiddly:
--   1. Our dark bg is pinned via `colors`/`highlights` overrides. Those must
--      NOT carry into light mode, or the "light" theme keeps a dark editor bg.
--   2. onedark's setup() *merges* opts into the existing config
--      (tbl_deep_extend 'force'), so a later light setup() that simply omits
--      the dark overrides leaves them in place. apply() therefore clears
--      vim.g.onedark_config first, so every setup starts from a clean slate.
local dark_bg = "#21252b"
local sep_fg = { dark = "#5c6370", light = "#a0a1a7" }
local mode_file = vim.fn.stdpath("state") .. "/theme_mode"

local function read_mode()
  local f = io.open(mode_file, "r")
  if not f then
    return "dark"
  end
  local m = f:read("*l")
  f:close()
  return m == "light" and "light" or "dark"
end

local function write_mode(mode)
  local f = io.open(mode_file, "w")
  if f then
    f:write(mode)
    f:close()
  end
end

local function onedark_opts(mode)
  if mode == "light" then
    -- Pin floats/sidebars to the editor's white Normal bg (onedark light
    -- bg0), symmetric to the dark branch pinning everything to dark_bg.
    -- The snacks explorer / git-tree sidebars chain their bg off
    -- NormalFloat; without this override they render onedark-light's grey
    -- float bg, standing out against the white editor.
    local light_bg = "#fafafa"
    return {
      style = "light",
      highlights = {
        Normal = { bg = light_bg },
        NormalFloat = { bg = light_bg },
        SignColumn = { bg = light_bg },
        EndOfBuffer = { bg = light_bg },
        WinSeparator = { fg = sep_fg.light },
      },
    }
  end
  return {
    style = "dark",
    colors = { black = dark_bg, bg0 = dark_bg, bg1 = dark_bg },
    highlights = {
      Normal = { bg = dark_bg },
      NormalFloat = { bg = dark_bg },
      SignColumn = { bg = dark_bg },
      EndOfBuffer = { bg = dark_bg },
      WinSeparator = { fg = sep_fg.dark },
    },
  }
end

-- Reconfigure + reapply onedark for `mode`. Sets vim.g.theme_mode BEFORE
-- loading so the ColorScheme autocmds below (and the indent-guide ones in
-- config/autocmds.lua) pick the right palette. Clearing onedark_config
-- avoids the previous mode's overrides bleeding through the merge in setup().
local function apply(mode)
  vim.g.theme_mode = mode
  vim.g.onedark_config = nil
  require("onedark").setup(onedark_opts(mode))
  require("onedark").load() -- runs `colorscheme onedark`, fires ColorScheme
end

return {
  {
    "navarasu/onedark.nvim",
    -- opts as a function so startup honours the persisted mode. lazy calls
    -- setup() with this; LazyVim then applies `colorscheme onedark`.
    opts = function()
      vim.g.theme_mode = read_mode()
      return onedark_opts(vim.g.theme_mode)
    end,
    init = function()
      -- onedark defaults WinSeparator to bg3, barely distinguishable from our
      -- Normal bg — the split divider effectively disappears. Force a clearly
      -- visible, mode-appropriate separator. SnacksWinSeparator (snacks's
      -- per-window remap) is force-set too: onedark's highlights table runs
      -- before snacks's load hook, so the link can get masked by load order.
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("CustomWinSeparator", { clear = true }),
        callback = function()
          local fg = sep_fg[vim.g.theme_mode or "dark"]
          vim.api.nvim_set_hl(0, "WinSeparator", { fg = fg })
          vim.api.nvim_set_hl(0, "SnacksWinSeparator", { fg = fg })
        end,
      })

      vim.keymap.set("n", "<leader>ut", function()
        local next_mode = vim.g.theme_mode == "light" and "dark" or "light"
        apply(next_mode)
        write_mode(next_mode)
        vim.notify("Theme → " .. next_mode, vim.log.levels.INFO, { title = "onedark" })
      end, { desc = "Toggle light/dark theme" })
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
