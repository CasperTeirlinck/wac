-- Resolve the base branch this work was branched off, the way GitHub does:
-- prefer origin's default branch (origin/HEAD → e.g. "origin/main"), then
-- fall back to the usual names. Returns a remote ref like "origin/main".
local function default_base()
  local head = vim.fn.systemlist(
    "git symbolic-ref --quiet --short refs/remotes/origin/HEAD")[1]
  if head and head ~= "" and vim.v.shell_error == 0 then
    return head -- already "origin/main" form
  end
  for _, b in ipairs({ "origin/main", "origin/master", "main", "master" }) do
    vim.fn.system("git rev-parse --verify --quiet " .. b .. "^{commit}")
    if vim.v.shell_error == 0 then return b end
  end
  return "origin/main"
end

-- PR review: diff the whole branch against the merge-base with its base
-- branch (`base...HEAD`). Three-dot is deliberate — it shows only what this
-- branch introduces, not changes that landed on base afterwards, matching
-- what GitHub's "Files changed" tab shows. Left panel = file list, right =
-- editable worktree diffs.
local function review_pr()
  vim.cmd("DiffviewOpen " .. default_base() .. "...HEAD")
end

-- Same, but prompt for an arbitrary range so you can review someone else's
-- branch (e.g. "origin/main...origin/their-feature").
local function review_prompt()
  vim.ui.input(
    { prompt = "Review range: ", default = default_base() .. "...HEAD" },
    function(input)
      if input and input ~= "" then vim.cmd("DiffviewOpen " .. input) end
    end)
end

-- Commit-by-commit history of the PR range (the branch's own commits).
local function pr_history()
  vim.cmd("DiffviewFileHistory --range=" .. default_base() .. "...HEAD")
end

-- "Reviewed" markers ---------------------------------------------------------
-- GitHub-style "viewed" tracking for the file panel, kept as session-local
-- state (a set of absolute paths). No disk persistence — quitting nvim
-- clears it. Marked files get a green ✓ at end of line and a dimmed name.
local reviewed = {}
local reviewed_ns = vim.api.nvim_create_namespace("diffview_reviewed")

local function current_panel()
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then return end
  local view = lib.get_current_view()
  return view and view.panel or nil
end

-- FileEntry under the cursor (nil unless the cursor is on a file line).
local function file_at_cursor(panel)
  if not (panel and panel.winid and vim.api.nvim_win_is_valid(panel.winid)) then return end
  local comps = panel.components and panel.components.comp
  if not comps then return end
  local line = vim.api.nvim_win_get_cursor(panel.winid)[1]
  local comp = comps:get_comp_on_line(line)
  if comp and comp.name == "file" then return comp.context end
end

-- Re-stamp every reviewed file in the panel with its ✓ extmark. Cheap to run
-- on every cursor move: diffview wipes extmarks when it re-renders the panel,
-- so the `reviewed` set stays the source of truth and we just replay it.
local function apply_marks(panel)
  local buf = panel and panel.bufid
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then return end
  local comps = panel.components and panel.components.comp
  if not comps then return end
  vim.api.nvim_buf_clear_namespace(buf, reviewed_ns, 0, -1)
  local total = vim.api.nvim_buf_line_count(buf)
  local seen = {}
  for lnum = 1, total do
    local comp = comps:get_comp_on_line(lnum)
    if comp and comp.name == "file" and not seen[comp] then
      seen[comp] = true
      local ctx = comp.context
      local path = ctx and (ctx.absolute_path or ctx.path)
      if path and reviewed[path] then
        pcall(vim.api.nvim_buf_set_extmark, buf, reviewed_ns, lnum - 1, 0, {
          virt_text = { { " ✓", "DiffviewReviewedSign" } },
          virt_text_pos = "eol",
          line_hl_group = "DiffviewReviewed",
          priority = 200,
        })
      end
    end
  end
end

-- Toggle the reviewed mark on the file under the cursor, then jump to the
-- next entry so you can blow through a review file-by-file with one key.
local function toggle_reviewed()
  local panel = current_panel()
  local ctx = file_at_cursor(panel)
  local path = ctx and (ctx.absolute_path or ctx.path)
  if not path then return end
  reviewed[path] = not reviewed[path] or nil
  apply_marks(panel)
  pcall(function() require("diffview.actions").next_entry() end)
end

local function clear_reviewed()
  for k in pairs(reviewed) do reviewed[k] = nil end
  apply_marks(current_panel())
end

return {
  -- Inline conflict resolution: <leader>co/ct/cb/c0 to choose ours/theirs/
  -- both/none, ]x and [x to jump between conflicts.
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPre",
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      list_opener = "copen",
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
  },

  -- 3-way diff view for file-by-file merge resolution. :DiffviewOpen
  -- during a merge shows OURS | BASE | THEIRS panels.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
    keys = {
      -- PR review (this branch vs its base).
      { "<leader>gp", review_pr,                        desc = "Diffview: review PR (base...HEAD)" },
      { "<leader>gP", review_prompt,                    desc = "Diffview: review range (prompt)" },
      { "<leader>gl", pr_history,                       desc = "Diffview: PR commit history" },
      -- Working tree / history. NOTE: <leader>gd intentionally NOT bound
      -- here — it belongs to the git_tree sidebar (open file diff vs HEAD)
      -- in git-sidebar.lua. Use <leader>gw for a full working-tree diff.
      { "<leader>gw", "<cmd>DiffviewOpen<cr>",          desc = "Diffview: working tree changes" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>",   desc = "Diffview: repo history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>",         desc = "Diffview: close" },
    },
    -- Re-apply reviewed ✓ marks whenever we enter/move in the file panel.
    -- Diffview clears extmarks on every panel re-render, so we replay them
    -- from the `reviewed` set on cursor movement (cheap, panel is small).
    init = function()
      vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "CursorMoved" }, {
        group = vim.api.nvim_create_augroup("diffview_reviewed_marks", { clear = true }),
        callback = function(args)
          if vim.bo[args.buf].filetype ~= "DiffviewFiles" then return end
          local panel = current_panel()
          if panel and panel.bufid == args.buf then apply_marks(panel) end
        end,
      })
    end,
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed", -- 3-way layout for conflicts
          disable_diagnostics = true,
        },
      },
      keymaps = {
        file_panel = {
          -- m = toggle "reviewed" on the file under the cursor (and advance);
          -- M = clear all reviewed marks. Session-local, no disk persistence.
          { "n", "m", toggle_reviewed, { desc = "Diffview: toggle reviewed" } },
          { "n", "M", clear_reviewed,  { desc = "Diffview: clear reviewed marks" } },
        },
      },
    },
  },
}
