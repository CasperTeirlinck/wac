-- Git-tree model: the custom snacks finder that builds a tree of git-changed
-- files, the collapsed-folder state, and the file-open helpers.
local status = require("util.git-status")
local gitfmt = require("util.git-format")

local M = {}

-- Paths the user has collapsed in the tree (shared with the finder).
M.collapsed = {}

function M.find_main_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" then
      return win
    end
  end
  return nil
end

function M.open_file(picker, item)
  if not item then return end
  if item.dir then
    M.collapsed[item.file] = not M.collapsed[item.file]
    -- Preserve cursor position across the refresh-triggered re-find.
    if picker and picker.list and picker.list.set_target then
      pcall(picker.list.set_target, picker.list)
    end
    if picker and picker.find then pcall(picker.find, picker) end
    return
  end
  if not item.file then return end
  local target = M.find_main_window()
  if target then vim.api.nvim_set_current_win(target) end
  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
end

function M.open_with_diff(item)
  if not item or not item.file or item.dir then return end
  local target = M.find_main_window()
  if target then vim.api.nvim_set_current_win(target) end
  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
  -- Poll for gitsigns to attach before diffthis; a fixed defer raced when
  -- gitsigns took longer, silently no-op'ing the diff.
  local function try_diff(attempts)
    if attempts > 30 then return end
    if vim.b.gitsigns_status_dict then
      pcall(vim.cmd, "Gitsigns diffthis HEAD")
    else
      vim.defer_fn(function() try_diff(attempts + 1) end, 50)
    end
  end
  vim.defer_fn(function() try_diff(0) end, 30)
end

-- Custom finder: builds a tree of git-changed files with parent dirs, from the
-- cached status data so folder collapse/expand is instant.
function M.finder(opts, ctx)
  return function(cb)
    local cwd = (ctx and ctx.filter and ctx.filter.cwd) or vim.fn.getcwd()
    local files = status.read(cwd)

    local dirs = {}
    local items = {}

    local function ensure_dir(rel_dir)
      if rel_dir == "" or rel_dir == "." then return nil end
      if dirs[rel_dir] then return dirs[rel_dir] end
      local parent_rel = rel_dir:match("^(.+)/[^/]+$")
      local parent_item = parent_rel and ensure_dir(parent_rel) or nil
      local item = {
        file = cwd .. "/" .. rel_dir,
        text = cwd .. "/" .. rel_dir,
        dir = true,
        open = true,
        parent = parent_item,
        last = true,
      }
      dirs[rel_dir] = item
      table.insert(items, item)
      return item
    end

    -- Partial-staged files (index staged + fresh worktree change) render with
    -- the worktree status + a flag our formatter reads. See util/git-format.lua.
    local function display_status(xy)
      if gitfmt.is_partial_staged(xy) then
        return " " .. xy:sub(2, 2), true
      end
      return xy, false
    end

    local paths = vim.tbl_keys(files)
    table.sort(paths)
    for _, path in ipairs(paths) do
      local parent_rel = path:match("^(.+)/[^/]+$")
      local parent_item = parent_rel and ensure_dir(parent_rel) or nil
      local st, partial = display_status(files[path])
      table.insert(items, {
        file = cwd .. "/" .. path,
        text = cwd .. "/" .. path,
        dir = false,
        parent = parent_item,
        last = true,
        status = st,
        partial_staged = partial,
      })
    end

    -- Propagate file statuses up to ancestor dirs so a collapsed folder shows
    -- the aggregate status icon/color.
    local Git = require("snacks.picker.source.git")
    local function add_dir_status(dir_item, st)
      dir_item.dir_status = dir_item.dir_status
          and Git.merge_status(dir_item.dir_status, st)
          or st
    end
    for _, item in ipairs(items) do
      if not item.dir and item.status then
        local p = item.parent
        while p do
          add_dir_status(p, item.status)
          p = p.parent
        end
      end
    end

    -- Hide items under a collapsed ancestor; set `open` on dirs so the
    -- formatter shows open vs closed folder icons.
    local function is_hidden(item)
      local p = item.parent
      while p do
        if M.collapsed[p.file] then return true end
        p = p.parent
      end
      return false
    end
    local visible = {}
    for _, item in ipairs(items) do
      if not is_hidden(item) then
        if item.dir then
          item.open = not M.collapsed[item.file]
          -- Closed dir picks up the aggregate child status (matches explorer).
          item.status = (not item.open) and item.dir_status or nil
        end
        table.insert(visible, item)
      end
    end

    -- Fix `last` flags within the visible set.
    local last_per_parent = {}
    for _, item in ipairs(visible) do
      last_per_parent[item.parent or "__root__"] = item
    end
    for _, item in ipairs(visible) do
      item.last = (last_per_parent[item.parent or "__root__"] == item)
    end

    for _, item in ipairs(visible) do cb(item) end
  end
end

-- Renders normally, then for partial-staged files swaps the status icon to the
-- purple staged glyph. See util/git-format.lua.
function M.format(item, picker)
  local result = require("snacks.picker.format").file(item, picker)
  if item.partial_staged then
    gitfmt.mark_partial_staged(result, picker)
  end
  return result
end

return M
