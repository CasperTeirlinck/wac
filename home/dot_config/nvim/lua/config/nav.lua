-- Window/pane navigation, resize, and buffer cycling — all on the `<C-a>`
-- prefix (mirroring tmux, whose prefix is also `<C-a>`). Required from
-- config/keymaps.lua. Handles real splits AND snacks picker "floats", falling
-- through to the multiplexer at a true edge.

local map = vim.keymap.set

local function mux_move(dir)
  -- Inside tmux, if the focused pane is at the server's edge in this direction
  -- and we're nested (nvim inside an inner tmux), smart-splits' select-pane on
  -- the inner socket would just stop — so hop to the outer server (`TMUX=`
  -- targets the default/outer socket). Harmless no-op in a single tmux.
  if vim.env.TMUX then
    local at_edge = { left = "pane_at_left", right = "pane_at_right", up = "pane_at_top", down = "pane_at_bottom" }
    local flag = { left = "-L", right = "-R", up = "-U", down = "-D" }
    local edge = vim.fn.system({ "tmux", "display-message", "-p", "#{" .. at_edge[dir] .. "}" }):gsub("%s+", "")
    if edge == "1" then
      vim.fn.system("TMUX= tmux select-pane " .. flag[dir])
      return
    end
  end
  pcall(function()
    require("smart-splits.mux").move_pane(dir, false, "stop")
  end)
end

-- Windows of the same snacks picker as `cur_win` (input, list, preview). Used to
-- exclude same-picker sub-windows from nav so "down" from a sidebar input
-- doesn't land on its sibling list window.
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

-- Neovim's mode is global, not per-window. Switching windows with a
-- Visual/Select selection live drags it into the target window, where it
-- re-anchors and highlights garbage. So before a switch we drop to normal mode
-- (recording the selection in '< / '> marks) and remember the window we left;
-- the WinEnter autocmd below reselects it with `gv` on return — preserved, not
-- lost.
local pending_reselect = nil

local function preserve_visual_select()
  local m = vim.fn.mode()
  -- v / V / <C-v> / s / S / <C-s>
  if m == "v" or m == "V" or m == "\22" or m == "s" or m == "S" or m == "\19" then
    pending_reselect = vim.api.nvim_get_current_win()
    vim.cmd("normal! \27")
  end
end

vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    if not pending_reselect then return end
    local win = vim.api.nvim_get_current_win()
    if win ~= pending_reselect then return end
    pending_reselect = nil
    -- Schedule so the switch settles before `gv` reselects; pcall guards
    -- invalidated marks (buffer changed under us).
    vim.schedule(function()
      if vim.api.nvim_get_current_win() == win then
        pcall(vim.cmd, "normal! gv")
      end
    end)
  end,
})

local function nav(dir)
  return function()
    preserve_visual_select()
    local cur = vim.api.nvim_get_current_win()
    local siblings = picker_sibling_wins(cur)
    local cur_pos = vim.api.nvim_win_get_position(cur)
    local cur_w = vim.api.nvim_win_get_width(cur)
    local cur_h = vim.api.nvim_win_get_height(cur)

    local best, best_dist = nil, math.huge
    -- Current tabpage only. nvim_list_wins() spans every tab, so navigating
    -- toward an edge in a separate-tab layout (diffview) could jump to another
    -- tab. tabpage_list_wins(0) keeps nav in-tab; at a real edge it falls
    -- through to the multiplexer.
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if w ~= cur and not siblings[w] and vim.api.nvim_win_is_valid(w) then
        local cfg = vim.api.nvim_win_get_config(w)
        -- Skip non-embedded floats (completion popups); include snacks-style
        -- embedded floats (zindex < 50).
        local skip = cfg.relative ~= "" and (cfg.zindex or 50) >= 50
        if not skip then
          local p = vim.api.nvim_win_get_position(w)
          local pw = vim.api.nvim_win_get_width(w)
          local ph = vim.api.nvim_win_get_height(w)
          -- Direction check + overlap on the perpendicular axis so an
          -- off-to-the-side window isn't picked as a neighbour.
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
      -- No nvim window that way → hand off to the multiplexer.
      mux_move(dir)
    end
  end
end
map({ "n", "i", "v" }, "<C-a><Left>", nav("left"), { desc = "Navigate left" })
map({ "n", "i", "v" }, "<C-a><Down>", nav("down"), { desc = "Navigate down" })
map({ "n", "i", "v" }, "<C-a><Up>", nav("up"), { desc = "Navigate up" })
map({ "n", "i", "v" }, "<C-a><Right>", nav("right"), { desc = "Navigate right" })

-- Pane resize: <C-a><S-Arrow> mirrors tmux's `prefix S-Arrow`. smart-splits
-- resizes the nvim window when there's a neighbour that way, else hands off to
-- the multiplexer. The outer tmux forwards the chord here when the active pane
-- runs vim (see dot_tmux.conf.tmpl).
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

-- <C-a>[ / <C-a>]: cycle bufferline buffers (mirrors tmux prefix window nav,
-- since `<C-a>` is also the tmux prefix).
map({ "n", "i", "v" }, "<C-a>[", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
map({ "n", "i", "v" }, "<C-a>]", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })

-- <C-a>x: close the current buffer (mirrors tmux's `prefix x`, which the outer
-- tmux forwards here when the pane runs vim). Snacks.bufdelete keeps the window
-- alive (unlike :bdelete) so the sidebars stay put.
map({ "n", "i", "v" }, "<C-a>x", function()
  require("snacks").bufdelete()
end, { desc = "Close buffer" })
