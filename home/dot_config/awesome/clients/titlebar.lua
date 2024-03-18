local awful      = require("awful")
local wibox      = require("wibox")
local xresources = require("beautiful.xresources")
local dpi        = xresources.apply_dpi

return function(c)
    local mousebuttons = require("mappings.client_mouse").titlebar(c)

    awful.titlebar(c, { size = 25 }):setup {
        {
            -- Left
            -- awful.titlebar.widget.iconwidget(c),
            buttons = mousebuttons,
            layout = wibox.layout.fixed.horizontal
        },
        {
            -- Middle
            -- {
            -- Title
            -- align  = "center",
            -- widget = awful.titlebar.widget.titlewidget(c)
            -- },
            buttons = mousebuttons,
            layout = wibox.layout.flex.horizontal
        },
        {
            -- Right
            {
                -- awful.titlebar.widget.floatingbutton (c),
                -- awful.titlebar.widget.maximizedbutton(c),
                -- awful.titlebar.widget.stickybutton   (c),
                -- awful.titlebar.widget.ontopbutton    (c),
                -- awful.titlebar.widget.minimizebutton    (c),
                awful.titlebar.widget.closebutton(c),
                layout = wibox.layout.fixed.horizontal()
            },
            widget = wibox.container.margin,
            right = dpi(5)
        },
        layout = wibox.layout.align.horizontal
    }
end
