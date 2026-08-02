-- Shared "partial-staged" rendering for snacks pickers (explorer + git_tree).
local M = {}

-- XY porcelain status where the index is staged (X in MADRC) AND the worktree
-- has a fresh change on top (Y in MD) — e.g. "MM", "AM". snacks renders these
-- as fully staged; we want the modified-color filename with the staged glyph.
function M.is_partial_staged(xy)
  return xy ~= nil and #xy == 2
    and xy:sub(1, 1):match("[MADRC]") ~= nil
    and xy:sub(2, 2):match("[MD]") ~= nil
end

-- Overwrite the right-aligned status icon in a Format.file result with the
-- purple staged glyph, leaving the filename color the format already applied.
function M.mark_partial_staged(result, picker)
  local icon = (picker.opts.icons.git or {}).staged or "●"
  for _, chunk in ipairs(result) do
    if chunk.virt_text_pos == "right_align" and chunk.virt_text then
      chunk.virt_text[1] = { icon, "SnacksPickerGitStatusStaged" }
    end
  end
end

return M
