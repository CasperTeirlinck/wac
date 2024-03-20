local gears     = require("gears")
local awful     = require("awful")
local beautiful = require("beautiful")
local lain      = require("lain")

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    s.mypromptbox = awful.widget.prompt()
    require("layout.bar.layouts")(s)
    require("layout.bar.taglist")(s)
    require("layout.bar.tasklist")(s)
    require("layout.bar.bar")(s)

    s.quake = lain.util.quake({
        app = "alacritty",
        argname = "--title %s",
        extra = "--class QuakeDD -e tmux",
        visible = true,
        border = 0,
        height = 0.5,
        screen = s
    })
end)
