-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = function()
--     -- require("snacks.explorer").open({ focus = false })
--     vim.api.nvim_create_timer(1, false, function()
--       local ok, snacks = pcall(require, "snacks")
--       if ok and snacks.picker and snacks.picker.explorer then
--         snacks.picker.explorer()
--       end
--     end)
--   end,
-- })

-- Tone down indent guides: very dim by default, slightly brighter for
-- the focused scope. Overrides snacks's defaults (which inherit from
-- the colorscheme and end up red on onedark).
local function set_indent_hls()
  vim.api.nvim_set_hl(0, "SnacksIndent",      { fg = "#2c313a" })
  vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#4b5263" })
  vim.api.nvim_set_hl(0, "SnacksIndentChunk", { fg = "#4b5263" })
end
set_indent_hls()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_indent_hls })
