local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local tab = require("layout.widget.tab")

-- | - | - | --
-- | 1 | 2 | --
local max_nr_of_columns = 2 -- max 2 supported
local default_column = 2
local class_to_default_column = {
    ["Brave-browser"] = 1
}

local tabbar_height = 30

local layout = {}
layout.name = "splitstack"

local function update_tabbar(clients, tag, area)
    local s = tag.screen

    local tabbar = wibox.widget {
        spacing = tag.gap,
        layout  = wibox.layout.flex.horizontal
    }
    for _, c in ipairs(clients) do
        -- print(c.name or c.class)
        -- for k, v in pairs(awful.client.idx(c)) do
        --     print(k, v)
        -- end

        tabbar:add(tab.create(c))
    end
    -- maximused clients are normally not included in the layout's client list
    for _, c in pairs(tag:clients()) do
        if c.maximized then
            tabbar:add(tab.create(c))
        end
    end

    if not s["tabbar"] then
        s["tabbar"] = wibox({
            ontop = false,
            -- shape = function(cr, width, height)
            --     local border_radius = 3
            --     gears.shape.rounded_rect(cr, width, height, border_radius)
            -- end,
            -- bg = beautiful.bg_normal,
            -- bg = "#ffffff00",
            -- bg = nil,
            type = "dock",
            bg = gears.color.transparent,
            visible = true,
        })
    end

    s["tabbar"].x = area.x + tag.gap
    s["tabbar"].y = area.y
    s["tabbar"].width = area.width - 2 * tag.gap
    s["tabbar"].height = tabbar_height

    s["tabbar"]:setup({ layout = wibox.layout.flex.horizontal, tabbar })

    -- for i = 1, nr_of_clumns do
    --     if not s["tabbar" .. i] then
    --         s["tabbar" .. i] = wibox({
    --             ontop = false,
    --             shape = function(cr, width, height)
    --                 local border_radius = 3
    --                 gears.shape.rounded_rect(cr, width, height, border_radius)
    --             end,
    --             bg = beautiful.bg_normal,
    --             visible = true,
    --         })
    --     end

    --     -- s["tabbar" .. i].x = area.x + tag.gap * i + (i - 1) *
    --     -- s["tabbar" .. i].y = area.y + tag.gap
    --     -- s["tabbar" .. i].width = area.width - 2 * tag.gap
    --     -- s["tabbar" .. i].height = tabbar_height
    -- end
end

function layout.mouse_resize_handler(c, _, _, _)
    local tag         = c.screen.selected_tag
    local area        = c.screen.workarea
    local cursor      = "sb_h_double_arrow"

    local prev_coords = {}
    mousegrabber.run(function(m)
        if not c.valid then return false end

        for _, v in ipairs(m.buttons) do
            if v then
                prev_coords = { x = m.x, y = m.y }
                local master_width_factor = (m.x - area.x) / area.width
                tag.master_width_factor = math.min(math.max(master_width_factor, 0.01), 0.99)
                return true
            end
        end
        return prev_coords.x == m.x and prev_coords.y == m.y
    end, cursor)
end

function layout.arrange(p)
    local tag = p.tag or screen[p.screen].selected_tag
    local area = p.workarea
    local clients = p.clients

    local width_factor = tag.master_width_factor
    if #clients == 1 then width_factor = 1 end

    local nr_of_clumns = math.min(max_nr_of_columns, #clients)

    for idx = 1, #clients do
        local c = clients[idx]

        local column = class_to_default_column[c.class] or default_column
        column = math.min(column, nr_of_clumns)

        local width = area.width * width_factor
        if column == 2 then width = area.width - width end

        p.geometries[c] = {
            x = area.x + ((column - 1) * area.width * width_factor),
            y = area.y + tabbar_height,
            width = width,
            height = area.height - tabbar_height + tag.gap * 2,
        }
    end

    update_tabbar(clients, tag, area)
end

return layout
