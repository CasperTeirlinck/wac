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
      keymap = {
        preset = "enter",
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
      },
      -- <C-Space> = manual trigger (from the "enter" preset). The auto-popup
      -- is gated by should_auto_show so it stays quiet in prose/comments/strings.
      completion = {
        menu = { auto_show = should_auto_show },
      },
      cmdline = {
        keymap = {
          preset = "enter",
          ["<Up>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
        },
        completion = { menu = { auto_show = true } },
      },
    },
  },
}
