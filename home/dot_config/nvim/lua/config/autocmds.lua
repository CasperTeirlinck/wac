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
  vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#2c313a" })
  vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#4b5263" })
  vim.api.nvim_set_hl(0, "SnacksIndentChunk", { fg = "#4b5263" })
end
set_indent_hls()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_indent_hls })

-- Color untracked git files green so they aren't confused with ignored
-- (which also defaults to grey). Bold variants for the "current file"
-- highlight are created lazily inside the format function (autocmds
-- here run before snacks defines its SnacksPickerGitStatus* groups, so
-- defining bold variants now picks up empty/default attrs).
local function set_explorer_hls()
  vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { fg = "#98c379" })
  vim.api.nvim_set_hl(0, "SnacksPickerDirectory", { link = "SnacksPickerFile" })
end
set_explorer_hls()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_explorer_hls })

-- Refresh the explorer picker on buffer change so the bold tracks focus.
-- Skip when entering a snacks picker (would reset its cursor to top).
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.filetype:match("^snacks_picker") then
      return
    end
    vim.schedule(function()
      local ok, snacks = pcall(require, "snacks")
      if not ok or not snacks.picker then
        return
      end
      for _, p in ipairs(snacks.picker.get({ source = "explorer" }) or {}) do
        pcall(p.find, p, { refresh = true })
      end
    end)
  end,
})
