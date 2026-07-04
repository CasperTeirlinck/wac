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
-- the colorscheme and end up red on onedark). Values track the active
-- theme (vim.g.theme_mode, set by plugins/custom.lua): the dark greys
-- would be harsh dark lines on the light background, so light mode uses
-- light greys. Re-runs on ColorScheme, so <leader>ut refreshes these too.
local function set_indent_hls()
  local indent, scope
  if vim.g.theme_mode == "light" then
    indent, scope = "#e1e2e6", "#c6c8cc"
  else
    indent, scope = "#2c313a", "#4b5263"
  end
  vim.api.nvim_set_hl(0, "SnacksIndent", { fg = indent })
  vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = scope })
  vim.api.nvim_set_hl(0, "SnacksIndentChunk", { fg = scope })
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

-- Diffview's file-panel tree colors folder names with `Directory` (blue),
-- which clashes with the explorer where we flattened folders to the normal
-- text color (SnacksPickerDirectory -> SnacksPickerFile above). Match that:
-- link DiffviewFolderName to Normal so the file tree reads as plain text.
-- Diffview applies its own links with `default = true`, so an explicit set
-- here wins regardless of load/ColorScheme ordering.
local function set_diffview_hls()
  vim.api.nvim_set_hl(0, "DiffviewFolderName", { link = "Normal" })
  -- Folder icon defaults to `PreProc` (purple); the explorer uses the blue
  -- `Directory` color for folder icons. Match it.
  vim.api.nvim_set_hl(0, "DiffviewFolderSign", { link = "Directory" })
  -- The open/selected file defaults to `Type` (yellow text). Match the
  -- explorer's active-file style instead: bold text on the grey selection
  -- bg. Pull the grey from Visual so it tracks the theme — the same source
  -- snacks.lua uses for its picker CursorLine.
  local visual = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
  local bg = visual.bg and string.format("#%06x", visual.bg) or "#3b3f4c"
  vim.api.nvim_set_hl(0, "DiffviewFilePanelSelected", { bold = true, bg = bg })
  -- Reviewed-file markers (see merge.lua): green ✓ glyph + a dimmed filename
  -- so reviewed entries recede, GitHub-"viewed" style.
  vim.api.nvim_set_hl(0, "DiffviewReviewedSign", { link = "DiffviewFilePanelInsertions" })
  vim.api.nvim_set_hl(0, "DiffviewReviewed", { link = "Comment" })
end
set_diffview_hls()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_diffview_hls })

-- Refresh the explorer picker on buffer change so the bold tracks focus.
-- Skip when entering a snacks picker (would reset its cursor to top).
--
-- This used to fire `picker:find({ refresh = true })` synchronously on
-- every BufEnter — which re-runs the finder (tree walk + matcher) every
-- time. In huge repos (~100k files) that's the dominant cause of laggy
-- window navigation and the occasional double-render.
--
-- Two guards now:
--   1. Debounce: coalesce bursts of BufEnter (cycling tabs, jumping
--      between windows) into a single refresh ~100 ms after motion stops.
--   2. Dedupe: track the last "interesting" buffer file; skip the
--      refresh entirely if it hasn't changed (entering a help/term/
--      scratch buffer doesn't need a tree re-render).
local refresh_timer = nil
local last_refreshed_file = nil
local function schedule_explorer_refresh()
  if vim.bo.filetype:match("^snacks_picker") then return end
  local file = vim.api.nvim_buf_get_name(0)
  -- Empty path = `[No Name]` / scratch; nothing to track.
  if file == "" or file == last_refreshed_file then return end
  if refresh_timer then refresh_timer:stop(); refresh_timer:close() end
  refresh_timer = vim.uv.new_timer()
  refresh_timer:start(100, 0, vim.schedule_wrap(function()
    refresh_timer:close(); refresh_timer = nil
    last_refreshed_file = file
    local ok, snacks = pcall(require, "snacks")
    if not ok or not snacks.picker then return end
    -- Use the explorer's own update action rather than a bare
    -- `find({ refresh = true })`: the latter re-runs the finder (which
    -- recomputes our bold "current file" highlight) but leaves the
    -- cursor at the top. `Actions.update` re-runs the finder AND reveals
    -- `target` when done, so the tree stays parked on the open file.
    -- This also makes us order-independent vs snacks's own scheduled
    -- `follow_file` reveal (the debounce here used to lose that race).
    local uok, Actions = pcall(require, "snacks.explorer.actions")
    for _, p in ipairs(snacks.picker.get({ source = "explorer" }) or {}) do
      if uok then
        pcall(Actions.update, p, { target = file, refresh = true })
      else
        pcall(p.find, p, { refresh = true })
      end
    end
  end))
end
vim.api.nvim_create_autocmd("BufEnter", { callback = schedule_explorer_refresh })
