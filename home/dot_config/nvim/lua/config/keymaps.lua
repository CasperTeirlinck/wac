-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Tmux Navigator keymaps
map({ "n", "i", "v" }, "<C-a><Left>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Tmux Navigate Left" })
map({ "n", "i", "v" }, "<C-a><Down>", "<cmd>TmuxNavigateDown<cr>", { desc = "Tmux Navigate Down" })
map({ "n", "i", "v" }, "<C-a><Up>", "<cmd>TmuxNavigateUp<cr>", { desc = "Tmux Navigate Up" })
map({ "n", "i", "v" }, "<C-a><Right>", "<cmd>TmuxNavigateRight<cr>", { desc = "Tmux Navigate Right" })

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
