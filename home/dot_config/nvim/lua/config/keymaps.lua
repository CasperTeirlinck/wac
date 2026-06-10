-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

--- Tmux Navigator keymaps                                                                                                                                 
-- map({ "n", "i", "v" }, "<C-a><Left>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Tmux Navigate Left" })                                                       
-- map({ "n", "i", "v" }, "<C-a><Down>", "<cmd>TmuxNavigateDown<cr>", { desc = "Tmux Navigate Down" })                                                       
-- map({ "n", "i", "v" }, "<C-a><Up>", "<cmd>TmuxNavigateUp<cr>", { desc = "Tmux Navigate Up" })                                                             
-- map({ "n", "i", "v" }, "<C-a><Right>", "<cmd>TmuxNavigateRight<cr>", { desc = "Tmux Navigate Right" })  

-- Pane navigation via smart-splits. Moves between vim windows; at the
-- edge of the layout, falls through to the multiplexer (tmux or zellij,
-- auto-detected). See ~/.config/zellij/config.kdl for the zellij side
-- (autolock keeps `<C-a>` passing through to nvim).
local function nav(dir)
  return function() require("smart-splits")["move_cursor_" .. dir]() end
end
map({ "n", "i", "v" }, "<C-a><Left>",  nav("left"),  { desc = "Navigate left (vim/mux)" })
map({ "n", "i", "v" }, "<C-a><Down>",  nav("down"),  { desc = "Navigate down (vim/mux)" })
map({ "n", "i", "v" }, "<C-a><Up>",    nav("up"),    { desc = "Navigate up (vim/mux)" })
map({ "n", "i", "v" }, "<C-a><Right>", nav("right"), { desc = "Navigate right (vim/mux)" })

-- Non-vim-style insert-mode selection.
-- Enter Visual mode + letter motion, then <C-g> toggles to Select mode
-- so typing replaces the selection. Letter motions are used (not arrow
-- keys) because keymodel=stopsel cancels Select mode on unshifted special keys.
map("i", "<S-Left>",  "<C-o>vh<C-g>", { desc = "Select character left" })
map("i", "<S-Right>", "<C-o>vl<C-g>", { desc = "Select character right" })
map("i", "<S-Up>",    "<C-o>vk<C-g>", { desc = "Select line up" })
map("i", "<S-Down>",  "<C-o>vj<C-g>", { desc = "Select line down" })
map("i", "<S-Home>",  "<C-o>v0<C-g>", { desc = "Select to start of line" })
map("i", "<S-End>",   "<C-o>v$<C-g>", { desc = "Select to end of line" })

-- Word motion in insert mode. <C-Left>/<C-Right> on Linux/Windows;
-- Ghostty translates Cmd+arrow into the same CSI sequences on macOS.
-- <Cmd>...<CR> stays in insert mode (no InsertLeave/Enter cycle), so
-- completion plugins don't re-trigger on the cursor move.
map("i", "<C-Left>",    "<Cmd>normal! b<CR>", { desc = "Move word left" })
map("i", "<C-Right>",   "<Cmd>normal! w<CR>", { desc = "Move word right" })
-- Word selection: enter Visual, extend by word, then toggle to Select
-- mode so typing replaces the selection.
map("i", "<C-S-Left>",  "<C-o>vb<C-g>", { desc = "Select word left" })
map("i", "<C-S-Right>", "<C-o>ve<C-g>", { desc = "Select word right" })

-- Cmd+C: copy to system clipboard. Ghostty forwards Cmd+C as Ctrl+C
-- (\x03), so we bind <C-c> here. Cmd+V already pastes natively via
-- ghostty's paste_from_clipboard action.
-- The "my ... `y" pattern marks the cursor before yank and restores
-- after, so the cursor stays put instead of jumping to the start of
-- the selection (Vim's default behavior).
map("n", "<C-c>", 'my"+yy`y',  { desc = "Copy line to clipboard" })
map("x", "<C-c>", 'my"+y`y',   { desc = "Copy selection to clipboard" })
-- In Select mode every printable character would *replace* the
-- selection, so toggle to Visual first via <C-g>, then yank.
map("s", "<C-c>", '<C-g>my"+y`y', { desc = "Copy selection to clipboard" })
map("i", "<C-c>", '<Cmd>normal! my"+yy`y<CR>', { desc = "Copy line to clipboard" })

-- Enter in normal mode starts insert (VSCode-style "press Enter to edit").
-- Buffer-local <CR> mappings (quickfix, explorer, picker, etc.) take
-- precedence, so this only fires in normal file buffers.
map("n", "<CR>", "i", { desc = "Enter insert mode" })

-- Ctrl+Z: undo (overrides nvim's default suspend behavior).
map({ "n", "x", "s" }, "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })
map("i",                "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })

-- Ctrl+V: paste from clipboard register. Bypasses ghostty/tmux text
-- input so multi-line pastes preserve their newlines. Loses the default
-- visual-block-mode binding in normal mode; use <C-q> instead if needed.
map("n", "<C-v>", '"+p',       { desc = "Paste from clipboard" })
map("i", "<C-v>", "<C-r>+",    { desc = "Paste from clipboard" })
map("x", "<C-v>", '"+p',       { desc = "Paste over selection" })
map("s", "<C-v>", '<C-g>"+p',  { desc = "Paste over selection" })

-- Ctrl+X: cut to clipboard. With no selection, cuts the current line.
map("n", "<C-x>", '"+dd',                       { desc = "Cut line to clipboard" })
map("x", "<C-x>", '"+d',                        { desc = "Cut selection to clipboard" })
map("s", "<C-x>", '<C-g>"+d',                   { desc = "Cut selection to clipboard" })
map("i", "<C-x>", '<Cmd>normal! "+dd<CR>',      { desc = "Cut line to clipboard" })

-- Ctrl+Shift+F: global text search (grep across project).
-- F1: global file search (fuzzy find files in project).
local function grep()  require("snacks").picker.grep()  end
local function files() require("snacks").picker.files() end
map({ "n", "i", "v", "s" }, "<C-S-f>", grep,  { desc = "Search across files (grep)" })
map({ "n", "i", "v", "s" }, "<F1>",    files, { desc = "Find files in project" })
