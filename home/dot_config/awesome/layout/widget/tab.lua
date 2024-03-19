local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local bg_normal = beautiful.bg_normal or "#ffffff"
local fg_normal = beautiful.fg_normal or "#000000"
local bg_focus = beautiful.bg_focus or "#000000"
local fg_focus = beautiful.fg_focus or "#ffffff"

local function get_client_title(c)
    local title = c.name or c.class or "-"
    return gears.string.xml_escape(title)
end

local function get_client_text(c, fg)
    return "<span foreground='" .. fg .. "'>" .. get_client_title(c) .. "</span>"
end

local function get_client_mousebuttons(c)
    return gears.table.join(
        awful.button({}, 1, function()
            c:raise()
            client.focus = c
        end),
        awful.button({}, 2, function()
            c:kill()
        end),
        awful.button({}, 3, function()
            c.minimized = true
        end)
    )
end

local function create(c, focused)
    local fg = focused and fg_focus or fg_normal
    local bg = focused and bg_focus or bg_normal

    local text = wibox.widget.textbox()
    text.align = "center"
    text.valign = "center"
    text.markup = get_client_text(c, fg)

    c:connect_signal("property::name", function(_)
        text.markup = get_client_text(c, fg)
    end)

    return wibox.widget({
        text,
        buttons = get_client_mousebuttons(c),
        bg = bg,
        widget = wibox.container.background(),
    })
end

return {
    create = create
}
