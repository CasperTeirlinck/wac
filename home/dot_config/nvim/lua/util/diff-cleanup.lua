-- Cleanup autocmds for the diff workflow: unlist gitsigns' scratch buffers and
-- resolve orphaned diff windows when their partner goes away.
local M = {}

-- One window left in diff mode means its partner went away. If the orphan holds
-- a scratch (nofile) buffer like gitsigns' HEAD view, close it; if a normal
-- file, just turn diff mode off so the file stays visible.
local function cleanup_orphan_diff()
  local diff_wins = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(w) and vim.wo[w].diff then
      table.insert(diff_wins, w)
    end
  end
  if #diff_wins ~= 1 then return false end
  local orphan = diff_wins[1]
  local buf = vim.api.nvim_win_get_buf(orphan)
  if vim.bo[buf].buftype == "nofile" then
    pcall(vim.api.nvim_win_close, orphan, true)
  else
    pcall(function() vim.wo[orphan].diff = false end)
  end
  return true
end

function M.setup()
  -- Unlist `nofile` buffers (e.g. gitsigns' diff scratch) so they don't appear
  -- as `[No Name]` tabs in the bufferline.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      if vim.bo[args.buf].buftype == "nofile" then
        vim.bo[args.buf].buflisted = false
      end
    end,
  })

  -- Wipe orphaned listed buffers so :q closes both window and tab, and clean up
  -- orphaned diff windows when their partner goes away.
  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      local closed_win = tonumber(args.match)
      local closed_buf = closed_win and vim.api.nvim_win_get_buf(closed_win)
      vim.schedule(function()
        if vim.v.exiting ~= vim.NIL and vim.v.exiting ~= nil then return end
        if #vim.api.nvim_list_wins() == 0 then return end

        local cleaning_diff = cleanup_orphan_diff()

        if not cleaning_diff
            and closed_buf
            and vim.api.nvim_buf_is_valid(closed_buf)
            and vim.bo[closed_buf].buftype == ""
            and vim.bo[closed_buf].buflisted then
          local still_shown = false
          for _, w in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(w) == closed_buf then
              still_shown = true
              break
            end
          end
          if not still_shown then
            pcall(vim.api.nvim_buf_delete, closed_buf, {})
          end
        end
      end)
    end,
  })

  -- <leader>bd (Snacks.bufdelete) keeps the window but pulls the file out — no
  -- WinClosed fires, so re-check for orphaned diffs on buffer removal.
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    callback = function()
      vim.schedule(function()
        cleanup_orphan_diff()
      end)
    end,
  })
end

return M
