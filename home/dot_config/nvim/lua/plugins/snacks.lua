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
        format = function(item, picker)
          local result = require("snacks.picker.format").file(item, picker)
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
