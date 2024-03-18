local awful = require("awful")
local beautiful = require("beautiful")

client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
    Maximized_handler(c)
end)

client.connect_signal("property::maximized", Maximized_handler)

client.connect_signal("property::floating", Apply_borders)

client.connect_signal("focus", Apply_borders)

client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

client.connect_signal("request::titlebars", require("clients.titlebar"))
