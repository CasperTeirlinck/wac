local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")

function Maximized_handler(c)
    if c.maximized then
        -- awful.titlebar.hide(c)

        local area = awful.screen.focused().workarea
        local tabbar_height = 30
        c:geometry({
            x = area.x + beautiful.useless_gap * 2,
            y = area.y + tabbar_height + beautiful.useless_gap * 2,
            width = area.width - 4 * beautiful.useless_gap,
            height = area.height - tabbar_height - beautiful.useless_gap * 3,
        })
    else
        -- awful.titlebar.show(c)
        -- if c.class == "QuakeDD" then
        --     return
        -- end
        -- c.border_width = beautiful.border_width
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

    if #s.tiled_clients > 1 then
        c.border_color = beautiful.border_focus
    else
        c.border_color = beautiful.border_normal
    end

    -- if not c.floating then
    --     if #s.tiled_clients > 1 then
    --         c.border_color = beautiful.border_focus
    --     else
    --         c.border_color = beautiful.border_normal
    --     end
    -- else
    --     c.border_color = "#828482"
    -- end
end
