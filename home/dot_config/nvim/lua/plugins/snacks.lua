-- The explorer `format` fn runs once per row per render. Computing the
-- most-recently-active file there meant an N× buffer enumeration on every
-- cursor move — the per-move redraw a slow terminal (Windows Terminal) can't
-- keep up with, so the sidebar felt laggy. The active file only changes on
-- buffer switch, so compute once, cache the normalized path, invalidate on
-- BufEnter.
local af_valid, af_value = false, nil
local function active_file()
  if not af_valid then
    af_valid = true
    af_value = nil
    local buffers = vim.fn.getbufinfo({ buflisted = 1 })
    table.sort(buffers, function(a, b) return a.lastused > b.lastused end)
    for _, b in ipairs(buffers) do
      if vim.bo[b.bufnr].buftype == "" then
        local name = vim.api.nvim_buf_get_name(b.bufnr)
        if name ~= "" then
          af_value = vim.fs.normalize(name)
          break
        end
      end
    end
  end
  return af_value
end
vim.api.nvim_create_autocmd("BufEnter", { callback = function() af_valid = false end })

return {
  "folke/snacks.nvim",
  -- LazyVim's snacks-picker extra binds <leader>gd to git_diff. We want it to
  -- be diffview's DiffviewOpen (plugins/merge.lua); the two live on different
  -- plugins so load order picked the winner nondeterministically. Disabling
  -- the snacks one here (same plugin, so lazy merges it away) makes diffview's
  -- the only <leader>gd.
  keys = {
    { "<leader>gd", false },
  },
  opts = function(_, opts)
    opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, { enabled = false })
    -- Inline image previews via the Kitty graphics protocol (Ghostty supports
    -- it natively). PNG/JPG/GIF need no deps; SVG/PDF/AVIF need `imagemagick`
    -- on PATH. `svg` isn't in snacks's default allowlist, so add it — the
    -- vector→PNG recipe (convert.magick) is already wired, only the extension
    -- was missing. Quirk: switching between two open images under tmux blanks
    -- the previous one; `:e!` re-renders.
    opts.image = vim.tbl_deep_extend("force", opts.image or {}, {
      enabled = true,
      formats = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "tiff",
        "heic", "avif", "mp4", "mov", "avi", "mkv", "webm", "pdf", "icns", "svg" },
    })
    -- Suppress `/` search highlighting in picker windows (esp. the explorer):
    -- without this, hlsearch lights up matching filenames in the tree. Use a
    -- per-window highlight namespace with empty Search/CurSearch/IncSearch,
    -- attached via nvim_win_set_hl_ns — bypasses `winhighlight` (which snacks
    -- keeps rewriting) and works for pre-existing windows.
    local ns = vim.api.nvim_create_namespace("snacks_picker_no_hlsearch")
    -- Attaching a window-local namespace bypasses `winhighlight`, so snacks's
    -- `CursorLine:SnacksPickerListCursorLine` remap never applies (cursorline
    -- draws as plain CursorLine, near-invisible against Normal). And link
    -- targets resolve within the namespace, not global ns 0. Fix: inline the
    -- Visual bg onto CursorLine here, refreshed on ColorScheme.
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

    -- Snacks's image placement leaves `modified` set on image buffers (it
    -- writes blank lines during render passes), showing a phantom `[+]`.
    -- Re-assert modified=false whenever it flips.
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

    -- <C-Up>/<C-Down>: scroll a picker's list a few lines at a time, matching
    -- the viewport-scroll keymap in normal buffers (keymaps.lua). The global
    -- normal-mode mapping doesn't reach picker list windows, so bind it on the
    -- picker's own keymap layer. `list:scroll(±n)` shifts the view and drags
    -- the selection along; snacks's built-in list_scroll jumps by half a page,
    -- we want the same small steady step as the editor. List window only —
    -- the input window binds <C-Up>/<C-Down> to search-history nav.
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
        -- Don't list git-ignored files. In big repos they're the bulk of the
        -- tree (283k ignored / 6.1G in ov-dp3-data-projects), and listing them
        -- makes every refresh's tree walk + git-status enumeration run over all
        -- of them — the dominant save/movement lag. hidden=true still shows
        -- non-ignored dotfiles. Toggle with `I` at runtime.
        ignored = false,
        -- Custom layout: list first (tree starts at the top of the sidebar),
        -- input pinned to the bottom as one borderless row. snacks's auto_hide
        -- / layout-hidden can't drop the input — they close its scratch win,
        -- then explorer actions crash on the next input:set(). Keeping it alive
        -- at the bottom dodges that. Width in sync with git-sidebar.lua.
        layout = {
          preset = "sidebar",
          preview = false,
          layout = {
            box = "vertical",
            -- Must set position explicitly: snacks's preset resolver
            -- short-circuits the preset merge once we supply our own layout[1],
            -- so position="left" from the sidebar preset never reaches us —
            -- without this the explorer opens as a centred float.
            position = "left",
            width = 35,
            { win = "list",  border = "none" },
            { win = "input", height = 1, border = "none" },
          },
        },
        -- Named actions go through snacks's resolver, which captures the picker
        -- via closure. Function-form key handlers receive `self = the
        -- snacks.win` (no picker), so a raw inline function crashes inside
        -- toggle_focus.
        actions = {
          exit_search = function(picker)
            if vim.fn.mode():sub(1, 1) == "i" then vim.cmd.stopinsert() end
            -- Clear the filter so the list snaps back to the full tree.
            if picker.input and picker.input.set then
              pcall(picker.input.set, picker.input, "", "")
            end
            require("snacks.picker.actions").toggle_focus(picker)
          end,
          -- <C-S-f> from inside the explorer greps scoped to the tree item
          -- under the cursor (global keymaps don't reach the picker's list
          -- window; the global <C-S-f> still greps the whole cwd elsewhere).
          -- `picker:dir()` = the item's path if a dir, else its containing dir.
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
              -- <Esc> exits search (stopinsert + toggle_focus back to the
              -- list); never cancel/close — the sidebar is pinned.
              ["<Esc>"] = { "exit_search", mode = { "i", "n" } },
              ["<C-S-f>"] = { "explorer_grep", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              -- <Esc> defaults to `cancel` (closes the picker); make it inert
              -- in the list. Not exit_search — that flips focus to the input.
              ["<Esc>"] = { function() end, mode = { "n" } },
              -- Snacks explorer defaults, pinned so they survive our overrides.
              ["I"] = "toggle_ignored",
              ["H"] = "toggle_hidden",
              ["<C-S-f>"] = "explorer_grep",
            },
          },
        },
        -- Render the most-recently-active file in bold (via `lastused`, so diff
        -- scratch buffers don't steal it). Also mark partial-staged files
        -- (staged + fresh worktree edit): filename in modified color, staged
        -- glyph as the icon — see util/git-format.lua.
        format = function(item, picker)
          local Format = require("snacks.picker.format")
          local gitfmt = require("util.git-format")
          local raw, partial = item.status, false
          if gitfmt.is_partial_staged(item.status) then
            partial = true
            item.status = " " .. raw:sub(2, 2)
          end
          local result = Format.file(item, picker)
          if partial then
            item.status = raw
            gitfmt.mark_partial_staged(result, picker)
          end
          -- active_file() is cached and pre-normalized, so this is cheap.
          local current = active_file()
          if item.file and current
              and vim.fs.normalize(item.file) == current then
            for _, hl in ipairs(result) do
              -- The filename hl is SnacksPickerFile OR a SnacksPickerGitStatus*
              -- if changed. Swap to a lazily-defined Bold variant either way so
              -- it inherits whatever color snacks set at runtime.
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
