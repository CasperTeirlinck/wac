local awful     = require("awful")
local gears     = require("gears")
local wibox     = require("wibox")
local beautiful = require("beautiful")

local buttons   = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", {
                raise = true
            })
        end
    end), awful.button({}, 3, function()
        awful.menu.client_list({
            theme = {
                width = 250
            }
        })
    end), awful.button({}, 4, function()
        awful.client.focus.byidx(1)
    end), awful.button({}, 5, function()
        awful.client.focus.byidx(-1)
    end)
)

return function(s)
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        -- filter = awful.widget.tasklist.filter.currenttags,
        filter  = awful.widget.tasklist.filter.minimizedcurrenttags,
        buttons = buttons,
        layout  = {
            spacing = beautiful.useless_gap,
            -- spacing_widget = {
            --     {
            --         forced_width = 5,
            --         shape        = gears.shape.circle,
            --         widget       = wibox.widget.separator
            --     },
            --     valign = 'center',
            --     halign = 'center',
            --     widget = wibox.container.place,
            -- },
            layout  = wibox.layout.flex.horizontal
        },
    }
end
