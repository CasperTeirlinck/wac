-- `git status` data layer for the git-tree sidebar: cached porcelain parsing,
-- with sync (cache-miss) and async (event-driven) fetch paths.
local M = {}

-- Invalidated explicitly when git state may have changed (save, focus gain,
-- stage, manual refresh) so folder toggles re-render instantly.
local cache = { cwd = nil, files = nil }

function M.invalidate()
  cache.cwd = nil
  cache.files = nil
end

local function parse(output)
  local out = vim.split(output or "", "\n", { trimempty = true })
  local files = {}
  for _, line in ipairs(out) do
    if #line >= 3 then
      local status = line:sub(1, 2)
      local path = line:sub(4)
      local newpath = path:match("%-%> (.+)$")
      if newpath then path = newpath end
      path = path:gsub('^"', ""):gsub('"$', "")
      files[path] = status
    end
  end
  return files
end

-- Sync read for user-initiated finds (initial open, folder toggles); reads the
-- warm cache the async path fills.
function M.read(cwd)
  if cache.cwd == cwd and cache.files then
    return cache.files
  end
  local quoted = "'" .. cwd:gsub("'", "'\\''") .. "'"
  local handle = io.popen("git -C " .. quoted .. " status --porcelain=v1 --untracked-files=all 2>/dev/null")
  if not handle then return {} end
  local output = handle:read("*a") or ""
  handle:close()
  cache.cwd = cwd
  cache.files = parse(output)
  return cache.files
end

-- Async fetch off the main loop, fills the cache, then cb(). Used by the
-- event-driven refresh so a slow `git status` (~1s in huge trees) can't freeze
-- the UI. Falls back to a single blocking read on older nvim without vim.system.
function M.fetch_async(cwd, cb)
  local ok = pcall(vim.system,
    { "git", "-C", cwd, "status", "--porcelain=v1", "--untracked-files=all" },
    { text = true },
    vim.schedule_wrap(function(res)
      cache.cwd = cwd
      cache.files = parse(res and res.code == 0 and res.stdout or "")
      if cb then cb() end
    end))
  if not ok then
    M.read(cwd)
    if cb then cb() end
  end
end

return M
