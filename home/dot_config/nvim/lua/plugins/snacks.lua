return {
  "folke/snacks.nvim",
  -- LazyVim's snacks-picker extra binds <leader>gd to Snacks.picker.git_diff
  -- ("Git Diff (hunks)"). We want <leader>gd to be diffview's DiffviewOpen
  -- (plugins/merge.lua) instead. Because the two mappings live on different
  -- plugins, lazy.nvim's load order picked the winner nondeterministically
  -- (inconsistent between nvim starts). Disabling the snacks one here — same
  -- plugin, so lazy merges and drops it — leaves diffview's as the only
  -- <leader>gd, deterministically.
  keys = {
    { "<leader>gd", false },
  },
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
    -- Add `svg` to the formats allowlist — it's not in snacks's default
    -- list, so without this `nvim foo.svg` and inline `![](foo.svg)` in
    -- markdown both fall back to text rendering. The vector → PNG
    -- conversion recipe is already wired up in snacks's `convert.magick`
    -- (rasterised at -density 192), so allowing the extension is all
    -- that's needed.
    opts.image = vim.tbl_deep_extend("force", opts.image or {}, {
      enabled = true,
      formats = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "tiff",
        "heic", "avif", "mp4", "mov", "avi", "mkv", "webm", "pdf", "icns", "svg" },
    })
    -- Suppress `/` search highlighting in snacks picker windows (esp. the
    -- explorer sidebar). Without this, hlsearch lights up matching
    -- filenames in the tree whenever you `/` search inside a file buffer.
    --
    -- Approach: create a per-window highlight namespace where Search /
    -- CurSearch / IncSearch are empty, and attach it via
    -- `nvim_win_set_hl_ns` to any window with a snacks picker buffer.
    -- This bypasses `winhighlight` (which snacks keeps rewriting) and
    -- works even for windows that already exist when this code runs.
    local ns = vim.api.nvim_create_namespace("snacks_picker_no_hlsearch")
    -- Attaching a window-local namespace has two side effects that bite the
    -- picker's selection highlight:
    --   1. `winhighlight` is bypassed for that window — so snacks's
    --      `CursorLine:SnacksPickerListCursorLine` remap never applies, and
    --      the cursorline is drawn using plain `CursorLine` (whose bg
    --      `#21262b` is nearly identical to our Normal `#21252b` → invisible).
    --   2. Link targets are resolved *within* the namespace, not falling
    --      back to global ns 0. So `link = "Visual"` here would resolve to
    --      an empty entry, not the global Visual.
    -- Workaround: inline the Visual bg (`#3b3f4c`) directly onto CursorLine
    -- in this namespace, and refresh on ColorScheme to follow theme changes.
    local function refresh()
      vim.api.nvim_set_hl(ns, "Search",    {})
      vim.api.nvim_set_hl(ns, "CurSearch", {})
      vim.api.nvim_set_hl(ns, "IncSearch", {})
      local visual = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
      vim.api.nvim_set_hl(ns, "CursorLine", { bg = visual.bg and string.format("#%06x", visual.bg) or "#3b3f4c" })
    end
    refresh()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("snacks_picker_no_hlsearch_refresh", { clear = true }),
      callback = refresh,
    })
    local function attach_ns(win)
      if not vim.api.nvim_win_is_valid(win) then return end
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[buf].filetype
      if ft == "snacks_picker_list" or ft == "snacks_picker_preview" then
        pcall(vim.api.nvim_win_set_hl_ns, win, ns)
      end
    end
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType" }, {
      group = vim.api.nvim_create_augroup("snacks_picker_no_hlsearch", { clear = true }),
      callback = function()
        local win = vim.api.nvim_get_current_win()
        vim.schedule(function() attach_ns(win) end)
      end,
    })
    -- Catch windows already open at setup time (session restore, etc.).
    vim.schedule(function()
      for _, w in ipairs(vim.api.nvim_list_wins()) do attach_ns(w) end
    end)

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

    -- Ctrl/Cmd + Up/Down: scroll a picker's list a few lines at a time,
    -- mirroring the viewport-scroll keymap used in normal buffers (see
    -- config/keymaps.lua). This is what makes the chord scroll the left
    -- explorer and right git_tree sidebars — they're snacks pickers, so
    -- the global <C-Up>/<C-Down> normal-mode mapping doesn't reach their
    -- list windows; the picker's own keymap layer does.
    --
    -- `list:scroll(±n)` shifts the view n lines and drags the selection
    -- along (clamped into view) — the list analogue of <C-y>/<C-e>.
    -- Snacks's built-in list_scroll_up/down jump by the window's `scroll`
    -- option (~half the list height); we want the same small, steady step
    -- as the editor, so we scroll a fixed few lines instead.
    --
    -- Bound on the LIST window only: focus lands on the list when you nav
    -- into either sidebar (git-sidebar.lua bounces input → list), and the
    -- INPUT window already binds <C-Up>/<C-Down> to search-history nav,
    -- which we leave intact. Set at the global picker level so every
    -- picker gets it, not just the two sidebars.
    local picker_scroll_lines = 3
    opts.picker.actions = vim.tbl_deep_extend("force", opts.picker.actions or {}, {
      list_scroll_up_lines = function(picker) picker.list:scroll(-picker_scroll_lines) end,
      list_scroll_down_lines = function(picker) picker.list:scroll(picker_scroll_lines) end,
    })
    opts.picker.win = opts.picker.win or {}
    opts.picker.win.list = opts.picker.win.list or {}
    opts.picker.win.list.keys = vim.tbl_deep_extend("force", opts.picker.win.list.keys or {}, {
      ["<C-Up>"] = "list_scroll_up_lines",
      ["<C-Down>"] = "list_scroll_down_lines",
    })

    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.notifications = vim.tbl_deep_extend("force",
      opts.picker.sources.notifications or {},
      { win = { preview = { wo = { wrap = true } } } }
    )
    opts.picker.sources.explorer = vim.tbl_deep_extend("force",
      opts.picker.sources.explorer or {},
      {
        hidden = true,
        -- Don't list git-ignored files. In big repos these are the bulk
        -- of the working tree (Python .venv, __pycache__, build output —
        -- e.g. ov-dp3-data-projects has 283k ignored files / 6.1G), and
        -- listing them makes the explorer's tree walk + git-status
        -- enumeration re-run over all of them on every refresh, which is
        -- the dominant source of save/movement lag. hidden=true still
        -- shows non-ignored dotfiles (.github, .gitignore, etc.).
        ignored = false,
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
          -- <C-S-f> from inside the explorer greps *scoped to the tree
          -- item under the cursor* instead of the whole project. Global
          -- keymaps don't reach the picker's list window (see the C-Up/Down
          -- note above), so the scoped variant lives here on the picker's
          -- own keymap layer; the global <C-S-f> (config/keymaps.lua) still
          -- greps the whole cwd from anywhere else.
          --
          -- `picker:dir()` = the item's own path when it's a directory, else
          -- the directory containing it — so it works whether you land on a
          -- folder or a file. `dirs = { dir }` makes the grep search that
          -- path only.
          explorer_grep = function(picker)
            local dir = picker:dir()
            require("snacks").picker.grep({
              dirs = { dir },
              title = "Grep in " .. vim.fn.fnamemodify(dir, ":~:."),
            })
          end,
        },
        win = {
          input = {
            keys = {
              -- <Esc> = exit search: stopinsert + toggle_focus back to
              -- the list. We explicitly do NOT call cancel/close — the
              -- sidebar is pinned and <Esc> must never destroy it.
              ["<Esc>"] = { "exit_search", mode = { "i", "n" } },
              -- Grep scoped to the item under the cursor (see explorer_grep).
              ["<C-S-f>"] = { "explorer_grep", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              -- <Esc> defaults to `cancel` which closes the picker;
              -- we want it to be inert in the list (just stay in
              -- normal mode here). Don't reuse exit_search — that one
              -- calls toggle_focus, which would flip you to the input.
              ["<Esc>"] = { function() end, mode = { "n" } },
              -- Toggle git-ignored / hidden files on demand. These are
              -- snacks explorer defaults, pinned here explicitly so they
              -- survive our custom key overrides. `ignored` defaults off
              -- (fast in huge repos); press I to reveal .env / build
              -- artifacts / .venv when you need them, I again to hide.
              ["I"] = "toggle_ignored",
              ["H"] = "toggle_hidden",
              -- Grep scoped to the tree item under the cursor: select a
              -- folder (or file) and <C-S-f> searches just that subtree,
              -- instead of the whole project.
              ["<C-S-f>"] = "explorer_grep",
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
