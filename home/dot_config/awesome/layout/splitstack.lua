local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

-- | 1 | 2 | --
local nr_of_columns = 2
local default_column = 2
local class_to_default_column = {
    ["Brave-browser"] = 1
}

local tabbar_height = 30

local layout = {}

layout.name = "splitstack"

local function update_tabbar(clients, tag, area)
    local s = tag.screen

    if not s.tabbar then
        s.tabbar = wibox({
            ontop = false,
            shape = function(cr, width, height)
                local border_radius = 3
                gears.shape.rounded_rect(cr, width, height, border_radius)
            end,
            bg = beautiful.bg_normal,
            visible = true,
        })
    end

    s.tabbar.x = area.x + tag.gap
    s.tabbar.y = area.y + tag.gap
    s.tabbar.width = area.width - 2 * tag.gap
    s.tabbar.height = tabbar_height
end

function layout.arrange(p)
    local area = p.workarea
    local clients = p.clients
    local tag = p.tag or screen[p.screen].selected_tag

    if #clients <= 1 then
        return awful.layout.suit.tile.right.arrange(p)
    end

    for idx = 1, #clients do
        local c = clients[idx]
        local class = c.class
        local column = class_to_default_column[class] or default_column

        p.geometries[c] = {
            x = area.x + ((column - 1) * area.width / nr_of_columns),
            y = area.y + tabbar_height,
            width = area.width / nr_of_columns,
            height = area.height - tabbar_height,
        }
    end

    update_tabbar(clients, tag, area)
end

return layout
