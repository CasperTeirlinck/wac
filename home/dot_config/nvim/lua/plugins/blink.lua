-- Prose-first filetypes: never auto-pop completion while typing (it's noise
-- when writing documentation). <C-Space> still forces the menu (blink's
-- `show` calls force_auto_show, which ignores this gate).
local prose_ft = {
  markdown = true,
  text = true,
  gitcommit = true,
  gitrebase = true,
  tex = true,
  plaintex = true,
  rst = true,
  asciidoc = true,
}

-- Suppress the auto-popup in prose buffers and inside code comments / strings
-- (docstrings) — like VSCode, which doesn't nag with suggestions on every
-- character of normal text. Completion still works on demand via <C-Space>.
local function should_auto_show()
  if prose_ft[vim.bo.filetype] then
    return false
  end
  local ok, node = pcall(vim.treesitter.get_node)
  if ok and node then
    local t = node:type()
    if t:find("comment") or t:find("string") then
      return false
    end
  end
  return true
end

return {
  {
    "saghen/blink.cmp",
    opts = {
      -- "super-tab": <Tab> accepts the selected completion; <CR> is left
      -- unbound so Enter is ALWAYS a newline, never an accept. Up/Down select.
      -- This is what stops markdown Enter from eating the popup instead of
      -- inserting a line.
      keymap = {
        preset = "super-tab",
      },
      -- <C-Space> = manual trigger. The auto-popup is gated by should_auto_show
      -- so it stays quiet in prose/comments/strings.
      completion = {
        menu = { auto_show = should_auto_show },
        -- Inline "ghost text" preview: the suggestion rendered directly in
        -- the text as you type. LazyVim enables it globally; we don't want
        -- it anywhere (distracting, breaks flow). The menu still shows on
        -- demand via <C-Space> / where should_auto_show allows.
        ghost_text = { enabled = false },
      },
      cmdline = {
        -- Same rule in the cmdline: <Tab> accepts, <CR> runs the command.
        keymap = {
          preset = "super-tab",
        },
        completion = { menu = { auto_show = true } },
      },
    },
  },
}
