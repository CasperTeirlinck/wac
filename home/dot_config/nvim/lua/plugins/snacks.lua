return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, { enabled = false })
    -- Inline image previews via Kitty graphics protocol (Ghostty supports it
    -- natively). PNG/JPG/GIF render with no extra deps; SVG/PDF/AVIF need
    -- `imagemagick` on PATH (installed via Homebrew on Darwin, nixpkgs on
    -- Linux). Opens image files full-pane and also drives snacks.picker
    -- previews + inline markdown image rendering.
    --
    -- Known quirk: on buffer-switch between two open images under tmux, the
    -- previously-shown image vanishes and "Identify loading…" reappears.
    -- Workaround: `:e!` to re-render. Tried 3rd/image.nvim as an
    -- alternative; its hijack mode interacts badly with the snacks.explorer
    -- sidebar layout, so we're back here.
    opts.image = vim.tbl_deep_extend("force", opts.image or {}, { enabled = true })
    -- Snacks's image placement writes empty lines into the buffer during
    -- progress/render passes and never resets `modified` — so the buffer
    -- shows a phantom `[+]` flag after opening an image. Re-assert
    -- `modified = false` whenever it gets set on an image-filetype buffer.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "image",
      group = vim.api.nvim_create_augroup("snacks_image_unmodified", { clear = true }),
      callback = function(ev)
        vim.api.nvim_create_autocmd("BufModifiedSet", {
          buffer = ev.buf,
          callback = function() vim.bo[ev.buf].modified = false end,
        })
      end,
    })
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
        -- Custom layout: list first (so the file tree starts at the
        -- very top of the sidebar), input pinned to the bottom as a
        -- single borderless row. We can't use snacks's `auto_hide` /
        -- layout-`hidden` to remove the input — they call win:close()
        -- on it, which nils its scratch buf, and then explorer/actions
        -- crashes the next time it calls input:set() (e.g. on
        -- confirm). Keeping the input alive at the bottom dodges that
        -- entirely, and the list still gets row 0.
        -- Keep width in sync with git-sidebar.lua's LEFT_SIDEBAR_WIDTH.
        layout = {
          preset = "sidebar",
          preview = false,
          layout = {
            box = "vertical",
            -- Must set position explicitly: snacks's preset resolver
            -- (config/init.lua:225) short-circuits the preset merge as
            -- soon as we supply our own `layout[1]`, so position="left"
            -- from the sidebar preset never reaches us — without this
            -- the explorer opens as a centred float instead of a left
            -- split, and the editor + buffer tabs shuffle around it.
            position = "left",
            width = 35,
            { win = "list",  border = "none" },
            { win = "input", height = 1, border = "none" },
          },
        },
        -- A named action goes through snacks's action resolver, which
        -- captures the picker via closure. Function-form key handlers
        -- receive `self = the snacks.win` (no picker reference), so a
        -- raw inline function crashes inside toggle_focus.
        actions = {
          exit_search = function(picker)
            if vim.fn.mode():sub(1, 1) == "i" then vim.cmd.stopinsert() end
            -- Clear the filter so the list snaps back to the full tree
            -- instead of staying narrowed to the previous search term.
            if picker.input and picker.input.set then
              pcall(picker.input.set, picker.input, "", "")
            end
            require("snacks.picker.actions").toggle_focus(picker)
          end,
        },
        win = {
          input = {
            keys = {
              -- <Esc> = exit search: stopinsert + toggle_focus back to
              -- the list. We explicitly do NOT call cancel/close — the
              -- sidebar is pinned and <Esc> must never destroy it.
              ["<Esc>"] = { "exit_search", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              -- <Esc> defaults to `cancel` which closes the picker;
              -- we want it to be inert in the list (just stay in
              -- normal mode here). Don't reuse exit_search — that one
              -- calls toggle_focus, which would flip you to the input.
              ["<Esc>"] = { function() end, mode = { "n" } },
            },
          },
        },
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
