-- VSCode-style multi-cursor. <C-d> selects the word under cursor (or extends
-- the visual selection) and adds a new cursor at the next match — repeat to
-- pile on more cursors. <C-S-d> goes the other direction; q skips the current
-- match; <Esc> drops back to a single cursor.
--
-- This overrides nvim's default <C-d> (scroll half-page down) — intentional
-- to keep VSCode muscle memory.
return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  keys = {
    { "<C-d>",   mode = { "n", "x", "s" }, desc = "MC: add cursor at next match" },
    { "<C-S-d>", mode = { "n", "x", "s" }, desc = "MC: add cursor at prev match" },
  },
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    -- options.lua sets `selectmode=key,mouse`, so a Shift+motion or
    -- mouse-drag selection lands in Select mode (`s`), not Visual (`x`).
    -- Multicursor's match logic expects Visual mode; if invoked from
    -- Select mode it dumps its internal cursor payload into the buffer
    -- as literal text. <C-g> flips Select → Visual in-place; we send it
    -- first when the mapping fires from `s` mode.
    local function from_visual(fn)
      return function()
        if vim.fn.mode():sub(1, 1) == "s" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-g>", true, false, true), "nx", false)
        end
        fn()
      end
    end

    local map = function(lhs, fn, desc)
      vim.keymap.set({ "n", "x", "s" }, lhs, from_visual(fn), { desc = desc })
    end
    map("<C-d>",   function() mc.matchAddCursor(1)  end, "MC: add cursor at next match")
    map("<C-S-d>", function() mc.matchAddCursor(-1) end, "MC: add cursor at prev match")
    map("<C-q>",   function() mc.toggleCursor()    end, "MC: toggle cursor here")

    -- While cursors are active, q skips the current match and N goes back.
    -- These only fire when the multi-cursor layer is engaged.
    mc.addKeymapLayer(function(layerSet)
      layerSet({ "n", "x" }, "q", function() mc.matchSkipCursor(1)  end, { desc = "MC: skip match" })
      layerSet({ "n", "x" }, "N", function() mc.matchSkipCursor(-1) end, { desc = "MC: skip back" })
      layerSet({ "n", "x" }, "<Esc>", function()
        if not mc.cursorsEnabled() then mc.enableCursors() else mc.clearCursors() end
      end, { desc = "MC: clear cursors" })
    end)
  end,
}
