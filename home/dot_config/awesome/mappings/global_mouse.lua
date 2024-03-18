local gears = require("gears")
local awful = require("awful")

return gears.table.join(
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
-- awful.button({}, 3, function() mainmenu:toggle() end),
)
