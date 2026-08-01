-- Character-class word motion, independent of 'iskeyword'.
--
-- Vim's built-in word motions (`w`/`b`/`e`) treat a "word" as a run of
-- 'iskeyword' characters. That set is filetype-dependent: the sql, python
-- and other ftplugins add `@`, `.`, `#`, `-` and friends to 'iskeyword', so
-- <C-Left>/<C-Right> would sail straight over `user@host`, `a.b.c`, `--flag`
-- as if they were single words. That's rarely what you want while editing.
--
-- Instead we classify each byte by its actual character *type* and stop at
-- every class boundary:
--   0 = whitespace (space / tab)
--   1 = word       ([A-Za-z0-9_] or any byte >= 128, i.e. UTF-8 text)
--   2 = punctuation (everything else: @ . " - ( ) , ; ...)
-- So `user@host.com` breaks into user | @ | host | . | com, and the cursor
-- stops at each of those edges — matching the "stop at every symbol" feel of
-- a conventional editor, regardless of filetype.
--
-- Byte-based (not codepoint-based): runs of >=128 bytes group together, so a
-- multibyte glyph is treated as one word chunk. Landing positions are byte
-- columns, which is what nvim_win_set_cursor expects.

local M = {}

local function char_class(line, i)
  local c = line:byte(i)
  if not c then
    return -1
  end
  if c == 32 or c == 9 then
    return 0
  end
  if c >= 128 then
    return 1
  end
  if line:sub(i, i):match("[%w_]") then
    return 1
  end
  return 2
end

local function get_line(row)
  return vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
end

-- Forward to the end of the next word (like `e`). Returns row (1-based) and
-- the 0-based byte column of that word's last character.
local function fwd_end(row, col)
  local last = vim.api.nvim_buf_line_count(0)
  local line = get_line(row)
  local n = #line
  local i = col + 2 -- 1-based index of the char under the cursor, + one step

  while true do
    while i > n do
      if row >= last then
        return row, math.max(n - 1, 0)
      end
      row = row + 1
      line = get_line(row)
      n = #line
      i = 1
    end
    local cls = char_class(line, i)
    if cls == 0 then
      i = i + 1
    else
      while i < n and char_class(line, i + 1) == cls do
        i = i + 1
      end
      return row, i - 1
    end
  end
end

-- Backward to the start of the current/previous word (like `b`). Returns row
-- (1-based) and the 0-based byte column of that word's first character.
local function back_start(row, col)
  local line = get_line(row)
  local i = col -- 1-based index of the char under the cursor, - one step

  while true do
    while i < 1 do
      if row <= 1 then
        return row, 0
      end
      row = row - 1
      line = get_line(row)
      i = #line
    end
    local cls = char_class(line, i)
    if cls == 0 then
      i = i - 1
    else
      while i > 1 and char_class(line, i - 1) == cls do
        i = i - 1
      end
      return row, i - 1
    end
  end
end

-- Move the cursor left to the start of the previous word. In visual/select
-- mode this extends the selection (moving the cursor is all it takes).
function M.left()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = back_start(pos[1], pos[2])
  pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
end

-- Move the cursor right to a word end. `past` puts the caret just *after* the
-- last character (where you'd keep typing in insert mode, and the exclusive
-- end of a selection); without it the caret lands *on* the last character
-- (normal-mode `e` behaviour).
function M.right(past)
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = fwd_end(pos[1], pos[2])
  if past then
    col = col + 1
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
end

return M
