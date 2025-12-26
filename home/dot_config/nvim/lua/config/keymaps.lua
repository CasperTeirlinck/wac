-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Tmux Navigator keymaps
map({ "n", "i", "v" }, "<C-a><Left>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Tmux Navigate Left" })
map({ "n", "i", "v" }, "<C-a><Down>", "<cmd>TmuxNavigateDown<cr>", { desc = "Tmux Navigate Down" })
map({ "n", "i", "v" }, "<C-a><Up>", "<cmd>TmuxNavigateUp<cr>", { desc = "Tmux Navigate Up" })
map({ "n", "i", "v" }, "<C-a><Right>", "<cmd>TmuxNavigateRight<cr>", { desc = "Tmux Navigate Right" })

-- map({ "n", "i", "v" }, "<C-a>h", "<cmd>TmuxNavigateLeft<cr>", { desc = "Tmux Navigate Left" })
-- map({ "n", "i", "v" }, "<C-a>j", "<cmd>TmuxNavigateDown<cr>", { desc = "Tmux Navigate Down" })
-- map({ "n", "i", "v" }, "<C-a>k", "<cmd>TmuxNavigateUp<cr>", { desc = "Tmux Navigate Up" })
-- map({ "n", "i", "v" }, "<C-a>l", "<cmd>TmuxNavigateRight<cr>", { desc = "Tmux Navigate Right" })
