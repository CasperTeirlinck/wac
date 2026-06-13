-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Non-vim-style selection: shifted special keys start Select mode where
-- typing a printable character replaces the selection.
vim.opt.keymodel = "startsel,stopsel"
vim.opt.selectmode = "key,mouse"
vim.opt.selection = "exclusive"
-- Lets the cursor sit one past end-of-line in normal/visual mode, matching
-- insert mode. Without this, Shift+Right at end of line selects the wrong char.
vim.opt.virtualedit = "onemore"

-- Mouse wheel scroll step: 1 line per tick instead of the default 3.
vim.opt.mousescroll = "ver:1,hor:1"

-- LazyVim already lowers `timeoutlen` to 300ms (for which-key / chord
-- mappings). But on top of that, terminal escape sequences fall back to
-- `timeoutlen` too — so pressing Esc to leave insert mode also waits up
-- to 300ms (sometimes feels longer when the terminal flushes Esc-led
-- byte sequences like our <S-CR>/<C-CR> tmux passthroughs). Decouple
-- the two: a small `ttimeoutlen` lets Esc fire ~immediately, while the
-- larger `timeoutlen` keeps chord mappings comfortable.
vim.opt.ttimeoutlen = 10
