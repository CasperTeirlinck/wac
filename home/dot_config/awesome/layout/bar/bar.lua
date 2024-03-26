local awful             = require("awful")
local gears             = require("gears")
local beautiful         = require("beautiful")
local wibox             = require("wibox")
local brightness_widget = require("turtlewidgets.brightness-widget.brightness")

return function(s)
    local brightnesscontrol = brightness_widget {
        type = 'arc',
        program = 'brightnessctl',
        step = '2'
    }
    brightnesscontrol:buttons(
        awful.util.table.join(
            awful.button({}, 1, function() brightness_widget:inc() end),
            awful.button({}, 3, function() brightness_widget:dec() end)
        )
    )

    local textclock = wibox.widget.textclock(" %d/%m/%Y %R ")
    local calendar = awful.widget.calendar_popup.month()
    calendar:attach(textclock, "br", { on_hover = false })

    local widgets_right = wibox.widget({
        {
            layout = wibox.layout.fixed.horizontal,
            awful.widget.keyboardlayout(),
            brightnesscontrol,
            wibox.widget.systray(),
            s.mylayoutbox,
            textclock,
        },
        bg = beautiful.bg_normal,
        shape = gears.shape.rounded_rect,
        shape_border_radius = 10,
        widget = wibox.container.background(),
    })

    s.mywibox = awful.wibar({
        position = "bottom",
        screen = s,
        bg = gears.color.transparent,
        border_width = beautiful.useless_gap,
    })
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        -- Left widgets
        {
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            s.mypromptbox
        },
        -- Middle widget
        s.mytasklist,
        -- Right widgets
        widgets_right
    }
end
