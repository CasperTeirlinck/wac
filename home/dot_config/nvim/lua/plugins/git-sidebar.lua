-- Persistent right-side "Source Control" sidebar: a tree view of git changes,
-- built on a custom snacks picker source (util/git-tree). The finder, status
-- cache, and sync/cleanup autocmds live in util/git-{status,tree,sidebar-
-- autocmds} and util/diff-cleanup; this file is the plugin spec + leader keys.
local status = require("util.git-status")
local tree = require("util.git-tree")

-- Keep in sync with the explorer layout width in snacks.lua.
local RIGHT_SIDEBAR_WIDTH = 35

-- Find the active git_tree picker and its highlighted item.
local function current_picker_item()
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then return nil, nil end
  local pickers = snacks.picker.get({ source = "git_tree" }) or {}
  local picker = pickers[1]
  if not picker or not picker.list or not picker.list.current then
    return picker, nil
  end
  return picker, picker.list:current()
end

local function leader_stage()
  local picker, item = current_picker_item()
  if not picker or not item then return end
  picker.list:set_target()
  require("snacks.picker.actions").git_stage(picker)
  vim.defer_fn(function()
    status.invalidate()
    pcall(picker.find, picker)
  end, 200)
end

local function leader_refresh()
  local picker, _ = current_picker_item()
  if not picker then return end
  status.invalidate()
  pcall(picker.find, picker)
end

local function leader_open_with_diff()
  local _, item = current_picker_item()
  tree.open_with_diff(item)
end

local function leader_toggle()
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then return end
  local pickers = snacks.picker.get({ source = "git_tree" }) or {}
  if #pickers > 0 then
    for _, p in ipairs(pickers) do pcall(p.close, p) end
  else
    snacks.picker.git_tree()
  end
end

local function leader_discard()
  local picker, item = current_picker_item()
  if not picker or not item or not item.file or item.dir then return end
  local rel = vim.fn.fnamemodify(item.file, ":~:.")
  vim.ui.select({ "Yes, discard", "Cancel" },
    { prompt = "Discard changes to " .. rel .. "?" },
    function(choice)
      if choice ~= "Yes, discard" then return end
      local cwd = vim.fn.getcwd()
      local quoted = "'" .. cwd:gsub("'", "'\\''") .. "'"
      local file_q = "'" .. item.file:gsub("'", "'\\''") .. "'"
      os.execute("git -C " .. quoted .. " restore -- " .. file_q .. " 2>/dev/null")
      -- restore doesn't touch untracked files; clean -f removes them.
      os.execute("git -C " .. quoted .. " clean -f -- " .. file_q .. " 2>/dev/null")
      status.invalidate()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == item.file then
          vim.api.nvim_buf_call(buf, function() vim.cmd("checktime") end)
        end
      end
      pcall(picker.find, picker)
    end
  )
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.git_tree = vim.tbl_deep_extend("force",
        opts.picker.sources.git_tree or {}, {
          finder = tree.finder,
          format = tree.format,
          tree = true,
          formatters = { file = { filename_only = true } },
          matcher = { sort_empty = false, fuzzy = false },
          auto_close = false,
          preview = false,
          focus = false,
          show_empty = true,
          -- List on top (tree at row 0), input pinned at the bottom as one
          -- borderless row. auto_hide / layout-hidden can't drop the input —
          -- they close its scratch window and the explorer-derived actions
          -- crash on the next input:set(). Keeping it alive is the workaround.
          layout = {
            preset = "sidebar",
            preview = false,
            layout = {
              box = "vertical",
              position = "right",
              width = RIGHT_SIDEBAR_WIDTH,
              { win = "list",  border = "none" },
              { win = "input", height = 1, border = "none" },
            },
          },
          confirm = tree.open_file,
          -- Named actions go through snacks's resolver (captures the picker via
          -- closure). Function-form key handlers get `self = the snacks.win`,
          -- so a plain inline function crashes inside toggle_focus.
          actions = {
            exit_search = function(picker)
              if vim.fn.mode():sub(1, 1) == "i" then vim.cmd.stopinsert() end
              -- Clear the search term so the list shows everything again.
              if picker.input and picker.input.set then
                pcall(picker.input.set, picker.input, "", "")
              end
              require("snacks.picker.actions").toggle_focus(picker)
            end,
            git_tree_refresh = function(picker)
              status.invalidate()
              picker:find()
            end,
            git_tree_stage = function(picker)
              local Actions = require("snacks.picker.actions")
              -- Capture cursor/top NOW: snacks's internal refresh (fired by
              -- git_stage) clears the target before our deferred find runs, so
              -- re-force them after.
              local saved_cursor = picker.list and picker.list.cursor or nil
              local saved_top = picker.list and picker.list.top or nil
              Actions.git_stage(picker)
              -- git_stage runs git async and calls picker:refresh() when done;
              -- invalidate the cache shortly after so the next find is fresh.
              vim.defer_fn(function()
                status.invalidate()
                if picker.list and picker.list.set_target and saved_cursor then
                  pcall(picker.list.set_target, picker.list,
                        saved_cursor, saved_top, { force = true })
                end
                pcall(picker.find, picker)
              end, 200)
            end,
          },
          win = {
            list = {
              keys = {
                ["s"] = "git_tree_stage",
                ["r"] = "git_tree_refresh",
                -- <Esc> inert in the list (default `cancel` would close the
                -- picker; exit_search would flip focus to the input).
                ["<Esc>"] = { function() end, mode = { "n" } },
              },
            },
            input = {
              keys = {
                ["s"] = { "git_tree_stage", mode = { "n" } },
                ["r"] = { "git_tree_refresh", mode = { "n" } },
                ["<Esc>"] = { "exit_search", mode = { "i", "n" } },
              },
            },
          },
        })
    end,
    keys = {
      { "<leader>gt", leader_toggle,         desc = "Git: toggle tree sidebar" },
      { "<leader>gs", leader_stage,          desc = "Git: stage/unstage current file" },
      { "<leader>gr", leader_refresh,        desc = "Git: refresh tree sidebar" },
      -- <leader>gD (capital), not gd: gd is diffview's open (merge.lua). Both
      -- bound gd once and clobbered each other by lazy load order.
      { "<leader>gD", leader_open_with_diff, desc = "Git: open file with diff vs HEAD" },
      { "<leader>gx", leader_discard,        desc = "Git: discard changes (restore)" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          vim.schedule(function() require("snacks").picker.git_tree() end)
        end,
      })
      require("util.git-sidebar-autocmds").setup()
      require("util.diff-cleanup").setup()
    end,
  },
}
