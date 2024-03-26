local awful = require("awful")
local beautiful = require("beautiful")

client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
    Maximized_handler(c)
end)

client.connect_signal("property::maximized", function(c)
    Maximized_handler(c)

    if c.maximized then
        c.border_color = beautiful.border_normal
    else
        c.border_color = beautiful.border_focus
    end
end)

-- client.connect_signal("property::floating", Apply_borders)
-- client.connect_signal("focus", Apply_borders)

client.connect_signal("focus", function(c)
    if c.maximized then
        c.opacity = 1
        c.below = false

        c.border_color = beautiful.border_normal
    else
        c.border_color = beautiful.border_focus
    end
end)

client.connect_signal("unfocus", function(c)
    if c.maximized then
        -- Don't hide maximised windows when the focus switches to the quake window
        -- TODO: not robust yet: when switching focus and/or maximising the quake or other windows while the quake window is open
        if awful.screen.focused().quake.visible then return end
        c.opacity = 0
        c.below = true
    end

    c.border_color = beautiful.border_normal
end)

-- client.connect_signal("request::titlebars", require("clients.titlebar"))
