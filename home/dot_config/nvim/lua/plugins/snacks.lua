return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, { enabled = false })
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.notifications = vim.tbl_deep_extend("force",
      opts.picker.sources.notifications or {},
      { win = { preview = { wo = { wrap = true } } } }
    )
    opts.picker.sources.explorer = vim.tbl_deep_extend("force",
      opts.picker.sources.explorer or {},
      {
        hidden = true,
        -- Render the most-recently-active file in bold.
        -- Uses the buffer-info `lastused` timestamp so diff scratch
        -- buffers (which aren't `buflisted`) don't override the bold.
        --
        -- Also distinguishes partial-staged files (XY = staged + fresh
        -- worktree edit, e.g. "MM", "AM"). Snacks's default treats
        -- these as fully staged. We render the filename as
        -- modified-unstaged (orange) but keep the staged glyph (purple
        -- ●) as the icon so it's visually distinct from both
        -- fully-staged and fully-unstaged.
        format = function(item, picker)
          local Format = require("snacks.picker.format")
          local original_status, partial = item.status, false
          if original_status and #original_status == 2 then
            local x = original_status:sub(1, 1)
            local y = original_status:sub(2, 2)
            if x:match("[MADRC]") and y:match("[MD]") then
              partial = true
              item.status = " " .. y
            end
          end
          local result = Format.file(item, picker)
          if partial then
            item.status = original_status
            local staged_icon = (picker.opts.icons.git or {}).staged or "●"
            for _, chunk in ipairs(result) do
              if chunk.virt_text_pos == "right_align" and chunk.virt_text then
                chunk.virt_text[1] = { staged_icon, "SnacksPickerGitStatusStaged" }
              end
            end
          end
          local function active_file()
            local buffers = vim.fn.getbufinfo({ buflisted = 1 })
            table.sort(buffers, function(a, b) return a.lastused > b.lastused end)
            for _, b in ipairs(buffers) do
              if vim.bo[b.bufnr].buftype == "" then
                local name = vim.api.nvim_buf_get_name(b.bufnr)
                if name ~= "" then return name end
              end
            end
          end
          local current = active_file()
          if item.file and current
              and vim.fs.normalize(item.file) == vim.fs.normalize(current) then
            for _, hl in ipairs(result) do
              -- The filename's highlight could be SnacksPickerFile OR a
              -- SnacksPickerGitStatus* if the file has git changes. Swap
              -- to a Bold variant either way, defining it lazily so it
              -- inherits whatever color snacks set up at runtime.
              if hl.field == "file" and type(hl[2]) == "string"
                  and hl[2]:match("^SnacksPicker") then
                local bold = hl[2] .. "Bold"
                if vim.fn.hlexists(bold) == 0 then
                  local base = vim.api.nvim_get_hl(0, { name = hl[2], link = false })
                  base.bold = true
                  vim.api.nvim_set_hl(0, bold, base)
                end
                hl[2] = bold
              end
            end
          end
          return result
        end,
      }
    )
  end,
}
