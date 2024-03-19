local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")

function Maximized_handler(c)
    if c.maximized then
        -- awful.titlebar.hide(c)
        c.border_width = 0
    else
        -- awful.titlebar.show(c)
        c.border_width = beautiful.border_width
    end
end

function Double_click_handler(double_click_event)
    if Double_click_timer then
        Double_click_timer:stop()
        Double_click_timer = nil
        return true
    end
    Double_click_timer = gears.timer.start_new(0.20, function()
        Double_click_timer = nil
        return false
    end)
end

function Apply_borders(c)
    local s = awful.screen.focused()

    if not c.floating then
        if #s.tiled_clients > 1 then
            c.border_color = beautiful.border_focus
        else
            c.border_color = beautiful.border_normal
        end
    else
        c.border_color = "#828482"
    end
end
