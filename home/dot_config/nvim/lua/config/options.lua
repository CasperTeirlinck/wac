-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Non-vim-style selection: shifted special keys start Select mode where
-- typing a printable character replaces the selection.
vim.opt.keymodel = "startsel,stopsel"
vim.opt.selectmode = "key,mouse"
vim.opt.selection = "exclusive"
-- Lets the cursor sit one past end-of-line in normal/visual mode, matching
-- insert mode. Without this, Shift+Right at end of line selects the wrong char.
vim.opt.virtualedit = "onemore"

-- Mouse wheel scroll step: 1 line per tick instead of the default 3.
vim.opt.mousescroll = "ver:1,hor:1"

-- LazyVim already lowers `timeoutlen` to 300ms (for which-key / chord
-- mappings). But on top of that, terminal escape sequences fall back to
-- `timeoutlen` too — so pressing Esc to leave insert mode also waits up
-- to 300ms (sometimes feels longer when the terminal flushes Esc-led
-- byte sequences like our <S-CR>/<C-CR> tmux passthroughs). Decouple
-- the two: a small `ttimeoutlen` lets Esc fire ~immediately, while the
-- larger `timeoutlen` keeps chord mappings comfortable.
--
-- Not *too* small, though: terminal query/resize responses (e.g. the
-- cursor-position report tmux relays on a `prefix-z` zoom) arrive as
-- `\e[…`-led sequences, and at 10ms the `\e` was being parsed alone — its
-- lone Esc dropped Select mode and the printable tail (`122H49`-style junk)
-- leaked into the buffer, replacing the selection. 50ms lets these
-- multi-byte responses reassemble into one (discarded) terminal code while
-- still feeling instant on a real Esc press. Pairs with `escape-time 10`
-- on the tmux side (~/.tmux.conf), which fixes the same split one layer up.
vim.opt.ttimeoutlen = 50

-- Snappy clipboard. nvim's default macOS provider shells out to `pbcopy`
-- on every yank/cut to the + register — a ~20ms process fork that makes
-- C-x/C-c (which route through "+) feel laggy vs VSCode. Copy via OSC52
-- instead: it just emits an escape sequence (no fork, instant), and reaches
-- the system clipboard through tmux's `set-clipboard on` passthrough — the
-- same path tmux's own mouse-drag copy uses. Paste still shells out (rare,
-- and OSC52 read is unreliable). macOS-only so the Linux/WSL default
-- provider (xclip/wl-clipboard) is left untouched.
if vim.fn.has("mac") == 1 then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function pbpaste()
    return vim.fn.systemlist("pbpaste")
  end
  vim.g.clipboard = {
    name = "osc52-copy/pbpaste",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = pbpaste, ["*"] = pbpaste },
  }
end

-- Work around a tmux bug (3.5a) when running under tmux with `extended-keys
-- on`: tmux re-encodes the newlines *inside* a bracketed paste as extended-key
-- sequences (ESC[27;<mod>;106~ = Ctrl+J, or …;13~ = Ctrl+M) instead of passing
-- them through raw. nvim requests extended keys (for <C-CR>/<C-Space>/…), so a
-- multi-line paste arrives as a single line with those literal escape
-- sequences where the line breaks should be — verified by capturing the raw
-- bytes nvim receives. A plain shell that doesn't request extended keys gets
-- raw \n, which is why only nvim was affected. Ghostty alone (no tmux) also
-- sends raw \n, so this decode is a no-op outside tmux.
--
-- Fix it in the paste handler: turn those sequences back into real newlines
-- and re-split before nvim's default `vim.paste` lays the text into the
-- buffer. Wrapping `vim.paste` is the documented hook for bracketed-paste
-- content.
do
  local orig_paste = vim.paste
  vim.paste = function(lines, phase)
    local fixed = {}
    for _, line in ipairs(lines) do
      -- ESC[27;<mod>;13~ (CR) and ESC[27;<mod>;106~ (LF) → newline.
      line = line:gsub("\27%[27;%d+;13~", "\n"):gsub("\27%[27;%d+;106~", "\n")
      for _, part in ipairs(vim.split(line, "\n", { plain = true })) do
        fixed[#fixed + 1] = part
      end
    end
    return orig_paste(fixed, phase)
  end
end
