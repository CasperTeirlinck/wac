local awful = require("awful")
local wibox = require("wibox")

return function(s)
    s.mywibox = awful.wibar({
        position = "bottom",
        screen = s
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
        {
            layout = wibox.layout.fixed.horizontal,
            awful.widget.keyboardlayout(),
            wibox.widget.systray(),
            s.mylayoutbox
        }
    }
end
