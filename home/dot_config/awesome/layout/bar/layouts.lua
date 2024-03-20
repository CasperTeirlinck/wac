local awful = require("awful")
local gears = require("gears")

local buttons
gears.table.join(
    awful.button({}, 1, function()
        awful.layout.inc(1)
    end),
    awful.button({}, 3, function()
        awful.layout.inc(-1)
    end),
    awful.button({}, 4, function()
        awful.layout.inc(1)
    end),
    awful.button({}, 5, function()
        awful.layout.inc(-1)
    end)
)

return function(s)
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(buttons)
end
