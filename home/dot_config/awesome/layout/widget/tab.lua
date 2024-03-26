local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local bg_normal = beautiful.bg_normal or "#ffffff"
local fg_normal = beautiful.fg_normal or "#000000"
local bg_focus = beautiful.bg_focus or "#000000"
local fg_focus = beautiful.fg_focus or "#ffffff"

local function get_client_title(c)
    local title = c.name or c.class or "-"
    return gears.string.xml_escape(title)
end

local function get_client_text(c, fg)
    local maximized_indicator = c.maximized and "+" or ""
    return "<span foreground='" .. fg .. "'>" .. maximized_indicator .. get_client_title(c) .. "</span>"
end

local function get_mousebuttons(c)
    return gears.table.join(
        awful.button({}, 1, function()
            c:raise()
            client.focus = c
        end),
        -- awful.button({}, 2, function()
        --     c:kill()
        -- end),
        awful.button({}, 3, function()
            c.minimized = true
        end)
    )
end

local function create(c)
    local text = wibox.widget({
        markup = get_client_text(c, fg_normal),
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    })

    local icon = wibox.widget({
        awful.widget.clienticon(c),
        top = dpi(3),
        right = dpi(3),
        bottom = dpi(3),
        widget = wibox.container.margin,
    })

    local content = wibox.widget({
        {
            icon,
            text,
            layout = wibox.layout.align.horizontal,
        },
        -- top = dpi(3),
        left = dpi(5),
        right = dpi(5),
        -- bottom = dpi(3),
        widget = wibox.container.margin,
    })

    local tab = wibox.widget({
        content,
        buttons = get_mousebuttons(c),
        bg = (client.focus == c) and bg_focus or bg_normal,
        shape = gears.shape.rounded_rect,
        shape_border_radius = 10,
        widget = wibox.container.background(),
    })

    c:connect_signal("property::name", function(_) text.markup = get_client_text(c, fg_normal) end)
    c:connect_signal("focus", function(_) tab.bg = bg_focus end)
    c:connect_signal("unfocus", function(_) tab.bg = bg_normal end)

    return tab
end

return {
    create = create
}
