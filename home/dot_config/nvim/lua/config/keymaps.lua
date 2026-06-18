-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Pane navigation by screen geometry. Handles real splits AND snacks
-- picker "floats" (sidebars rendered as relative='win' floating windows
-- that wincmd can't traverse). For each direction, find the
-- geometrically-closest window in that direction; if none, hand off to
-- smart-splits.mux which talks to whichever multiplexer is active
-- (tmux/zellij/wezterm/kitty).
local function mux_move(dir)
  pcall(function()
    require("smart-splits.mux").move_pane(dir, false, "stop")
  end)
end
-- Windows belonging to the same snacks picker as `cur_win` (input,
-- list, preview). Used to exclude same-picker sub-windows from nav so
-- "down" from a sidebar input doesn't land on the sibling list window.
local function picker_sibling_wins(cur_win)
  local set = {}
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then
    return set
  end
  for _, p in ipairs(snacks.picker.get() or {}) do
    local wins = {}
    if p.input and p.input.win then
      wins[#wins + 1] = p.input.win.win
    end
    if p.list and p.list.win then
      wins[#wins + 1] = p.list.win.win
    end
    if p.preview and p.preview.win then
      wins[#wins + 1] = p.preview.win.win
    end
    local owns = false
    for _, w in ipairs(wins) do
      if w == cur_win then
        owns = true
        break
      end
    end
    if owns then
      for _, w in ipairs(wins) do
        set[w] = true
      end
    end
  end
  return set
end

local function nav(dir)
  return function()
    local cur = vim.api.nvim_get_current_win()
    local siblings = picker_sibling_wins(cur)
    local cur_pos = vim.api.nvim_win_get_position(cur)
    local cur_w = vim.api.nvim_win_get_width(cur)
    local cur_h = vim.api.nvim_win_get_height(cur)

    local best, best_dist = nil, math.huge
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= cur and not siblings[w] and vim.api.nvim_win_is_valid(w) then
        local cfg = vim.api.nvim_win_get_config(w)
        -- Skip non-embedded floats (e.g. completion popups) but include
        -- snacks-style embedded floats (zindex < 50).
        local skip = cfg.relative ~= "" and (cfg.zindex or 50) >= 50
        if not skip then
          local p = vim.api.nvim_win_get_position(w)
          local pw = vim.api.nvim_win_get_width(w)
          local ph = vim.api.nvim_win_get_height(w)
          -- Direction check + overlap on the perpendicular axis so an
          -- "off to the side" window doesn't get picked as a vertical
          -- (or horizontal) neighbour.
          local h_overlap = (p[2] < cur_pos[2] + cur_w) and (p[2] + pw > cur_pos[2])
          local v_overlap = (p[1] < cur_pos[1] + cur_h) and (p[1] + ph > cur_pos[1])
          local valid, dist = false, 0
          if dir == "left" then
            valid = v_overlap and (p[2] + pw <= cur_pos[2])
            dist = cur_pos[2] - (p[2] + pw)
          elseif dir == "right" then
            valid = v_overlap and (p[2] >= cur_pos[2] + cur_w)
            dist = p[2] - (cur_pos[2] + cur_w)
          elseif dir == "up" then
            valid = h_overlap and (p[1] + ph <= cur_pos[1])
            dist = cur_pos[1] - (p[1] + ph)
          elseif dir == "down" then
            valid = h_overlap and (p[1] >= cur_pos[1] + cur_h)
            dist = p[1] - (cur_pos[1] + cur_h)
          end
          if valid and dist < best_dist then
            best, best_dist = w, dist
          end
        end
      end
    end

    if best then
      vim.api.nvim_set_current_win(best)
    else
      -- No nvim window in that direction → hand off to the multiplexer.
      mux_move(dir)
    end
  end
end
map({ "n", "i", "v" }, "<C-a><Left>", nav("left"), { desc = "Navigate left" })
map({ "n", "i", "v" }, "<C-a><Down>", nav("down"), { desc = "Navigate down" })
map({ "n", "i", "v" }, "<C-a><Up>", nav("up"), { desc = "Navigate up" })
map({ "n", "i", "v" }, "<C-a><Right>", nav("right"), { desc = "Navigate right" })

-- Pane resize: <C-a><S-Arrow> mirrors tmux's `prefix S-Arrow`. Uses
-- smart-splits so it resizes the nvim window when there's a neighbour
-- in that direction, and otherwise hands off to the multiplexer
-- (resizes the surrounding tmux pane). The outer tmux forwards the
-- chord here when the active pane runs vim — see the S-Arrow chain in
-- dot_tmux.conf.tmpl.
local function resize(dir)
  return function()
    pcall(function()
      require("smart-splits")["resize_" .. dir]()
    end)
  end
end
map({ "n", "i", "v" }, "<C-a><S-Left>", resize("left"), { desc = "Resize left" })
map({ "n", "i", "v" }, "<C-a><S-Down>", resize("down"), { desc = "Resize down" })
map({ "n", "i", "v" }, "<C-a><S-Up>", resize("up"), { desc = "Resize up" })
map({ "n", "i", "v" }, "<C-a><S-Right>", resize("right"), { desc = "Resize right" })

-- <C-a>[ / <C-a>]: cycle through bufferline buffers (mirrors tmux prefix
-- window navigation, since `<C-a>` is also the tmux prefix).
map({ "n", "i", "v" }, "<C-a>[", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
map({ "n", "i", "v" }, "<C-a>]", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })

-- <C-a>x: close the current buffer. Mirrors tmux's `prefix x` (close
-- pane); the outer tmux already forwards `C-a x` here when the active
-- pane runs vim (see the `bind-key x` chain in dot_tmux.conf.tmpl), so
-- we just need the matching keymap on this side. Snacks.bufdelete keeps
-- the window alive (unlike :bdelete, which closes the window if it was
-- the only buffer in it) — important so the sidebars stay put.
map({ "n", "i", "v" }, "<C-a>x", function()
  require("snacks").bufdelete()
end, { desc = "Close buffer" })

-- Non-vim-style insert-mode selection.
-- Enter Visual mode + letter motion, then <C-g> toggles to Select mode
-- so typing replaces the selection. Letter motions are used (not arrow
-- keys) because keymodel=stopsel cancels Select mode on unshifted special keys.
map("i", "<S-Left>", "<C-o>vh<C-g>", { desc = "Select character left" })
map("i", "<S-Right>", "<C-o>vl<C-g>", { desc = "Select character right" })
map("i", "<S-Up>", "<C-o>vk<C-g>", { desc = "Select line up" })
map("i", "<S-Down>", "<C-o>vj<C-g>", { desc = "Select line down" })
map("i", "<S-Home>", "<C-o>v0<C-g>", { desc = "Select to start of line" })
map("i", "<S-End>", "<C-o>v$<C-g>", { desc = "Select to end of line" })

-- Word motion in insert mode. <C-Left>/<C-Right> on Linux/Windows;
-- Ghostty translates Cmd+arrow into the same CSI sequences on macOS.
-- <Cmd>...<CR> stays in insert mode (no InsertLeave/Enter cycle), so
-- completion plugins don't re-trigger on the cursor move.
map("i", "<C-Left>", "<Cmd>normal! b<CR>", { desc = "Move word left" })
map("i", "<C-Right>", "<Cmd>normal! w<CR>", { desc = "Move word right" })
-- Same word motion in normal & visual modes.
map({ "n", "x" }, "<C-Left>", "b", { desc = "Move word left" })
map({ "n", "x" }, "<C-Right>", "w", { desc = "Move word right" })
-- Word selection: enter Visual, extend by word, then toggle to Select
-- mode so typing replaces the selection.
map("i", "<C-S-Left>", "<C-o>vb<C-g>", { desc = "Select word left" })
map("i", "<C-S-Right>", "<C-o>ve<C-g>", { desc = "Select word right" })

-- Cmd+C: copy to system clipboard. Ghostty forwards Cmd+C as Ctrl+C
-- (\x03), so we bind <C-c> here. Cmd+V already pastes natively via
-- ghostty's paste_from_clipboard action.
-- The "my ... `y" pattern marks the cursor before yank and restores
-- after, so the cursor stays put instead of jumping to the start of
-- the selection (Vim's default behavior).
map("n", "<C-c>", 'my"+yy`y', { desc = "Copy line to clipboard" })
map("x", "<C-c>", 'my"+y`y', { desc = "Copy selection to clipboard" })
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
map("i", "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })

-- Ctrl+V: paste from clipboard register. Bypasses ghostty/tmux text
-- input so multi-line pastes preserve their newlines. Loses the default
-- visual-block-mode binding in normal mode; use <C-q> instead if needed.
map("n", "<C-v>", '"+p', { desc = "Paste from clipboard" })
map("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("x", "<C-v>", '"+p', { desc = "Paste over selection" })
map("s", "<C-v>", '<C-g>"+p', { desc = "Paste over selection" })

-- Ctrl+X: cut to clipboard. With no selection, cuts the current line.
map("n", "<C-x>", '"+dd', { desc = "Cut line to clipboard" })
map("x", "<C-x>", '"+d', { desc = "Cut selection to clipboard" })
map("s", "<C-x>", '<C-g>"+d', { desc = "Cut selection to clipboard" })
map("i", "<C-x>", '<Cmd>normal! "+dd<CR>', { desc = "Cut line to clipboard" })

-- Ctrl+/ : toggle comment (VSCode-style). Karabiner swaps Cmd↔Ctrl so
-- the macOS muscle-memory Cmd+/ lands here too. Drives Neovim's built-in
-- `gc`/`gcc` operator (ts-comments.nvim wires commentstring via
-- treesitter for embedded languages like .tsx).
-- `<C-_>` (0x1F) is the legacy-terminal encoding of Ctrl+/; bind both
-- so it works regardless of whether the terminal speaks CSI-u or not.
--
-- Empty-line special case: gcc is a no-op on a blank line (nothing to
-- toggle). VSCode inserts the comment leader on blank lines and parks
-- the cursor ready to type. Match that.
local function insert_comment_leader_if_blank()
  local line = vim.api.nvim_get_current_line()
  if not line:match("^%s*$") then return false end
  local cs = vim.bo.commentstring
  if cs == "" then return false end
  -- commentstring is "<before>%s<after>" — e.g. "-- %s", "// %s",
  -- "{/* %s */}". Extract both halves; ensure a space after the prefix.
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

-- Shift+Tab: dedent (VSCode-style). Tab is left alone (snippet/completion
-- plugins may use it). blink.cmp is on the "enter" preset, so it does NOT
-- bind <S-Tab> in insert mode — safe to override here.
-- Select-mode dance: <C-g> flips to Visual so the `<` operator sees the
-- marks, `gv` reselects after dedent, final <C-g> flips back to Select.
map("n", "<S-Tab>", "<<",                  { desc = "Dedent line" })
map("x", "<S-Tab>", "<gv",                 { desc = "Dedent selection" })
map("s", "<S-Tab>", "<C-g><gv<C-g>",       { desc = "Dedent selection" })
map("i", "<S-Tab>", "<C-d>",               { desc = "Dedent line" })

-- F2: rename symbol under cursor via LSP (VSCode-style).
-- Works from normal, insert, visual, and select mode. In visual/select
-- we feedkeys <Esc> first and schedule the rename so the cursor settles
-- on a single position before the LSP `prepareRename` request fires.
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

-- Ctrl+Shift+F: global text search (grep across project).
-- F1: global file search (fuzzy find files in project).
-- F3: search open buffers.
-- F12: go to definition (LSP).
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
-- NOTE: do NOT add a fallback `<Esc>[13;5u` mapping here. The tmux
-- config sets `extended-keys on` + `terminal-features 'xterm*:extkeys'`,
-- so Neovim already resolves the CSI-u sequence to <C-CR> natively. A
-- raw `<Esc>[...` mapping makes every plain <Esc> wait `timeoutlen`
-- (~300ms) for the rest of the sequence — felt as a sluggish exit
-- from insert mode.
