local gears = require("gears")
local awful = require("awful")
local winkey = "Mod4"
local altkey = "Mod1"

return gears.table.join(
    awful.key({ winkey, }, "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        { description = "toggle fullscreen", group = "client" }
    ),
    awful.key({ winkey, }, "Up",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        { description = "(un)maximize", group = "client" }
    ),
    awful.key({ winkey, }, "Down", function(c) c.minimized = true end,
        { description = "minimize", group = "client" }),
    awful.key({ altkey, }, "f", awful.client.floating.toggle,
        { description = "toggle floating", group = "client" }),
    awful.key({ winkey, }, "o", function(c) c:move_to_screen() end,
        { description = "move to screen", group = "client" })
)
