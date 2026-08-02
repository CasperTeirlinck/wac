-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- Window/pane navigation, resize, and buffer cycling on the `<C-a>` prefix.
require("config.nav")

-- Non-vim-style insert-mode selection: Visual + letter motion, then <C-g>
-- toggles to Select mode so typing replaces the selection. Letter motions (not
-- arrows) because keymodel=stopsel cancels Select on unshifted special keys.
map("i", "<S-Left>", "<C-o>vh<C-g>", { desc = "Select character left" })
map("i", "<S-Right>", "<C-o>vl<C-g>", { desc = "Select character right" })
map("i", "<S-Up>", "<C-o>vk<C-g>", { desc = "Select line up" })
map("i", "<S-Down>", "<C-o>vj<C-g>", { desc = "Select line down" })
map("i", "<S-Home>", "<C-o>v0<C-g>", { desc = "Select to start of line" })
map("i", "<S-End>", "<C-o>v$<C-g>", { desc = "Select to end of line" })

-- Word motion. <C-Left>/<C-Right> on Linux/Windows; Ghostty maps Cmd+arrow to
-- the same CSI sequences on macOS. Uses a class-based motion (util/word-motion)
-- rather than `b`/`e`, which honour 'iskeyword' — the sql/python/etc. ftplugins
-- add `@ . - #` to it, so the built-ins skip over `user@host`, `a.b.c`,
-- `--flag`. The class motion stops at every symbol boundary. The Lua-callback
-- RHS (like <Cmd>) leaves the mode untouched — insert stays insert (no
-- completion re-trigger), visual extends the selection. Right in insert passes
-- `past=true` so the caret lands after the word; normal/visual land on the last
-- char, like `e`.
local wm = require("util.word-motion")
map("i", "<C-Left>", function() wm.left() end, { desc = "Move word left" })
map("i", "<C-Right>", function() wm.right(true) end, { desc = "Move word right" })
map({ "n", "x" }, "<C-Left>", function() wm.left() end, { desc = "Move word left" })
map({ "n", "x" }, "<C-Right>", function() wm.right(false) end, { desc = "Move word right" })
-- Word selection: <C-o>v enters Visual (a mode change, so the motion runs in
-- Visual), the class motion extends, <C-g> toggles to Select so typing
-- replaces. Right passes `past` to cover the whole word under exclusive select.
map("i", "<C-S-Left>", "<C-o>v<Cmd>lua require('util.word-motion').left()<CR><C-g>", { desc = "Select word left" })
map("i", "<C-S-Right>", "<C-o>v<Cmd>lua require('util.word-motion').right(true)<CR><C-g>", { desc = "Select word right" })

-- Ctrl/Cmd + Up/Down: scroll the viewport via Neovim's mouse-wheel path
-- (nvim_input_mouse), not <C-y>/<C-e>. The wheel path is what makes scrolling
-- glassy-smooth; count-scroll lurches at the scrolloff margin and reads as
-- jitter when held. Aimed at the cursor's screen position so it hits the
-- focused window; `mousescroll` (options.lua) sets lines per notch. Callback
-- form works in every mode, so insert scrolls without leaving insert. On macOS,
-- Ghostty forwards Cmd+Up/Down as these Ctrl+Up/Down CSI sequences.
local scroll_ticks = 3
local function wheel(dir)
  return function()
    local row = vim.fn.screenrow() - 1
    local col = vim.fn.screencol() - 1
    for _ = 1, scroll_ticks do
      vim.api.nvim_input_mouse("wheel", dir, "", 0, row, col)
    end
  end
end
map({ "n", "x", "i" }, "<C-Up>", wheel("up"), { desc = "Scroll up" })
map({ "n", "x", "i" }, "<C-Down>", wheel("down"), { desc = "Scroll down" })

-- `jk` exits insert mode (fast <Esc> without leaving the home row).
map("i", "jk", "<Esc>", { desc = "Escape insert mode" })

-- Cmd+C: copy to system clipboard. Ghostty forwards Cmd+C as Ctrl+C, so bind
-- <C-c>. The `my ... `y` pattern marks the cursor before yank and restores
-- after, so it stays put instead of jumping to the selection start.
map("n", "<C-c>", 'my"+yy`y', { desc = "Copy line to clipboard" })
map("x", "<C-c>", 'my"+y`y', { desc = "Copy selection to clipboard" })
-- In Select mode a printable char replaces the selection, so <C-g> to Visual
-- first, then yank.
map("s", "<C-c>", '<C-g>my"+y`y', { desc = "Copy selection to clipboard" })
map("i", "<C-c>", '<Cmd>normal! my"+yy`y<CR>', { desc = "Copy line to clipboard" })

-- Enter in normal mode starts insert (VSCode-style). Buffer-local <CR> maps
-- (quickfix, explorer, picker) take precedence, so this only fires in files.
map("n", "<CR>", "i", { desc = "Enter insert mode" })

-- Ctrl+Z: undo (overrides nvim's default suspend).
map({ "n", "x", "s" }, "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })
map("i", "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })

-- Ctrl+V: paste from clipboard. Bypasses ghostty/tmux text input so multi-line
-- pastes keep their newlines. Loses visual-block in normal mode; use <C-q>.
map("n", "<C-v>", '"+p', { desc = "Paste from clipboard" })
map("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("x", "<C-v>", '"+p', { desc = "Paste over selection" })
map("s", "<C-v>", '<C-g>"+p', { desc = "Paste over selection" })

-- Ctrl+X: cut to clipboard. With no selection, cuts the current line.
map("n", "<C-x>", '"+dd', { desc = "Cut line to clipboard" })
map("x", "<C-x>", '"+d', { desc = "Cut selection to clipboard" })
map("s", "<C-x>", '<C-g>"+d', { desc = "Cut selection to clipboard" })
map("i", "<C-x>", '<Cmd>normal! "+dd<CR>', { desc = "Cut line to clipboard" })

-- Ctrl+S: save. LazyVim's default `<cmd>w<cr><esc>` kicks you out of insert on
-- every save; `<Cmd>w<CR>` writes without changing mode (VSCode style). Ghostty
-- forwards Cmd+S as Ctrl+S.
map({ "n", "i", "x", "s" }, "<C-s>", "<Cmd>w<CR>", { desc = "Save file" })

-- Ctrl+/ : toggle comment (VSCode-style). Karabiner swaps Cmd↔Ctrl so Cmd+/
-- lands here too. Drives `gc`/`gcc` (ts-comments wires commentstring via
-- treesitter for embedded languages). `<C-_>` (0x1F) is the legacy-terminal
-- encoding of Ctrl+/; bind both. Empty-line special case: gcc is a no-op on a
-- blank line, so insert the comment leader and park the cursor, like VSCode.
local function insert_comment_leader_if_blank()
  local line = vim.api.nvim_get_current_line()
  if not line:match("^%s*$") then return false end
  local cs = vim.bo.commentstring
  if cs == "" then return false end
  -- commentstring is "<before>%s<after>"; extract both halves, ensure a space
  -- after the prefix.
  local before, after = cs:match("(.-)%%s(.*)")
  if not before then return false end
  if not before:match("%s$") then before = before .. " " end
  local indent = line:match("^%s*") or ""
  vim.api.nvim_set_current_line(indent .. before .. after)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  -- Park cursor between prefix and suffix (or at EOL for line comments).
  vim.api.nvim_win_set_cursor(0, { row, #indent + #before })
  return true
end
local function comment_normal()
  if insert_comment_leader_if_blank() then
    vim.cmd("startinsert")
    return
  end
  vim.api.nvim_feedkeys("gcc", "m", false)
end
local function comment_insert()
  if insert_comment_leader_if_blank() then return end
  vim.cmd("normal gcc")
end
for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
  map("n", lhs, comment_normal,        { desc = "Toggle comment / insert leader" })
  map("x", lhs, "gc",                  { remap = true, desc = "Toggle comment" })
  -- Select mode: <C-g> flips to Visual so `gc` can operate on the marks.
  map("s", lhs, "<C-g>gc",             { remap = true, desc = "Toggle comment" })
  map("i", lhs, comment_insert,        { desc = "Toggle comment / insert leader" })
end

-- Shift+Tab: dedent (VSCode-style). Tab is left alone (snippet/completion may
-- use it); blink.cmp is on the "enter" preset so it doesn't bind <S-Tab> in
-- insert. Select-mode dance: <C-g> to Visual so `<` sees the marks, `gv`
-- reselects, final <C-g> back to Select.
map("n", "<S-Tab>", "<<",                  { desc = "Dedent line" })
map("x", "<S-Tab>", "<gv",                 { desc = "Dedent selection" })
map("s", "<S-Tab>", "<C-g><gv<C-g>",       { desc = "Dedent selection" })
map("i", "<S-Tab>", "<C-d>",               { desc = "Dedent line" })

-- <leader>cp : copy absolute file path to the clipboard. If the current window
-- is a snacks picker (explorer / git_tree / buffers), yank the highlighted
-- item's path; otherwise the current buffer's path.
local function yank_path()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker then
    local cur_win = vim.api.nvim_get_current_win()
    for _, p in ipairs(snacks.picker.get() or {}) do
      local owns = (p.list and p.list.win and p.list.win.win == cur_win)
                or (p.input and p.input.win and p.input.win.win == cur_win)
      if owns and p.list and p.list.current then
        local item = p.list:current()
        if item and item.file then
          vim.fn.setreg("+", item.file)
          vim.notify("Yanked: " .. item.file)
          return
        end
      end
    end
  end
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("Current buffer has no file path", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", path)
  vim.notify("Yanked: " .. path)
end
map("n", "<leader>cp", yank_path, { desc = "Copy file path (buffer or picker item)" })

-- F2: LSP rename (VSCode-style). From visual/select, feedkeys <Esc> first and
-- schedule the rename so the cursor settles before prepareRename fires.
local function lsp_rename()
  local mode = vim.fn.mode()
  if mode == "n" or mode == "i" then
    vim.lsp.buf.rename()
    return
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  vim.schedule(function() vim.lsp.buf.rename() end)
end
map({ "n", "i", "v", "s" }, "<F2>", lsp_rename, { desc = "Rename symbol (LSP)" })

-- Search/nav: <C-S-f> grep, F1 files, F3 buffers, F12 / <C-CR> go-to-definition.
local function grep()
  require("snacks").picker.grep()
end
local function files()
  require("snacks").picker.files()
end
local function buffers()
  require("snacks").picker.buffers()
end
local function definition()
  require("snacks").picker.lsp_definitions()
end
map({ "n", "i", "v", "s" }, "<C-S-f>", grep, { desc = "Search across files (grep)" })
map({ "n", "i", "v", "s" }, "<F1>", files, { desc = "Find files in project" })
map({ "n", "i", "v", "s" }, "<F3>", buffers, { desc = "Search open buffers" })
map({ "n", "i", "v", "s" }, "<F12>", definition, { desc = "Go to definition" })
map({ "n", "i", "v", "s" }, "<C-CR>", definition, { desc = "Go to definition" })

-- Ctrl+Shift+Enter: LSP hover for the symbol under the cursor. Preferred over
-- LazyVim's `gK` (signature_help, only resolves inside a call paren). Press
-- again to focus the float; `q` closes it. From visual/select, <Esc> + schedule
-- like lsp_rename.
local function hover()
  local mode = vim.fn.mode()
  if mode == "n" or mode == "i" then
    vim.lsp.buf.hover()
    return
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  vim.schedule(function() vim.lsp.buf.hover() end)
end
map({ "n", "i", "v", "s" }, "<C-S-CR>", hover, { desc = "Hover (LSP docs)" })
-- NB: do NOT add a fallback `<Esc>[13;5u` map. tmux's `extended-keys on` +
-- xterm extkeys means nvim already resolves the CSI-u sequence to <C-CR>
-- natively; a raw `<Esc>[...` map would make every plain <Esc> wait timeoutlen.
