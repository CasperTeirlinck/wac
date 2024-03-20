local awful   = require("awful")
local gears   = require("gears")

local winkey  = "Mod4"

local buttons = gears.table.join(
    awful.button({}, 1, function(t)
        t:view_only()
    end),
    awful.button({ winkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle), awful.button({ winkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t)
        awful.tag.viewnext(t.screen)
    end),
    awful.button({}, 5, function(t)
        awful.tag.viewprev(t.screen)
    end)
)

return function(s)
    awful.tag({ "1", "2", "3" }, s, awful.layout.layouts[1])
    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = buttons
    }
end
