local awful     = require("awful")
local beautiful = require("beautiful")
require("awful.autofocus")

awful.rules.rules = {
    -- All clients
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = require("mappings.client_keys"),
            buttons = require("mappings.client_mouse").client,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    },
    -- Floating clients
    {
        rule_any = {
            instance = {
                "DTA",   -- Firefox addon DownThemAll.
                "copyq", -- Includes session name in class.
                "pinentry"
            },
            class = {
                "Arandr",
                "Blueman-manager",
                "Gpick",
                "Kruler",
                "MessageWin",  -- kalarm.
                "Sxiv",
                "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
                "Wpa_gui",
                "veromix",
                "xtightvncviewer",
                "eyedropper",
                "Pavucontrol"
            },
            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
                "Event Tester", -- xev.
                "Pick"          -- color picker
            },
            role = {
                "AlarmWindow",   -- Thunderbird's calendar.
                "ConfigManager", -- Thunderbird's about:config.
                "pop-up"         -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    },
    {
        rule_any = {
            class = { "QuakeDD" }
        },
        properties = {
            -- border_width = 0,
            -- border_color = "#ffffff00"
        }
    },
    -- {
    --     rule_any = { type = { "normal", "dialog" } },
    --     properties = { titlebars_enabled = true }
    -- }
}
