-- return {
--     "folke/snacks.nvim",
--     opts = {
--         -- This table configures the dashboard
--         dashboard = {
--             -- We override the default command that runs.
--             -- Instead of showing the dashboard, we'll show the explorer.
--             cmd = function()
--                 -- Only run this if nvim was opened without a file
--                 -- if vim.fn.argc() == 0 and vim.fn.bufname() == "" then
--                 -- We use vim.defer_fn to wait "one tick"
--                 -- This ensures snacks is fully loaded before we call it
--                 -- vim.defer_fn(function()
--                 -- pcall (protected call) safely tries to run this
--                 local ok, snacks = pcall(require, "snacks")
--                 if ok and snacks.picker and snacks.picker.explorer then
--                     snacks.picker.explorer()
--                 end
--                 -- end, 1)     -- 1ms delay
--                 -- end
--             end,
--         },
--     },
-- }

return {
  "folke/snacks.nvim",
  opts = {
    dashboard = { enabled = false },
    picker = {
      sources = {
        notifications = { win = { preview = { wo = { wrap = true } } } },
        explorer = { hidden = true },
      },
    },
  },
}
