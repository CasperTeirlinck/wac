-- ref: https://awesomewm.org/doc/api/documentation/05-awesomerc.md.html
pcall(require, "luarocks.loader")

local gears      = require("gears")
local awful      = require("awful")
local wibox      = require("wibox")
local beautiful  = require("beautiful")
local naughty    = require("naughty")
local menubar    = require("menubar")
local xresources = require("beautiful.xresources")
local dpi        = xresources.apply_dpi

-- Error handling
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then
            return
        end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end

-- Variable definitions
-- beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/default/theme.lua")

-- Bling utilities: https://github.com/BlingCorp/bling
-- local bling = require("bling")

-- This is used later as the default terminal and editor to run.
-- terminal = "x-terminal-emulator"
terminal = "wezterm"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"

awful.layout.layouts = {
    -- bling.layout.mstab,
    awful.layout.suit.floating
    -- awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}

-- Menu
awesomemenu = {
    { "restart", awesome.restart },
    { "quit",    function() awesome.quit() end }
}
mainmenu = awful.menu({ items = { { "awesome", awesomemenu, beautiful.awesome_icon } } })
launcher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mainmenu
})

menubar.utils.terminal = terminal

mykeyboardlayout = awful.widget.keyboardlayout()

-- Wibar
local taglist_buttons = gears.table.join(awful.button({}, 1, function(t)
    t:view_only()
end), awful.button({ modkey }, 1, function(t)
    if client.focus then
        client.focus:move_to_tag(t)
    end
end), awful.button({}, 3, awful.tag.viewtoggle), awful.button({ modkey }, 3, function(t)
    if client.focus then
        client.focus:toggle_tag(t)
    end
end), awful.button({}, 4, function(t)
    awful.tag.viewnext(t.screen)
end), awful.button({}, 5, function(t)
    awful.tag.viewprev(t.screen)
end))

local tasklist_buttons = gears.table.join(awful.button({}, 1, function(c)
    if c == client.focus then
        c.minimized = true
    else
        c:emit_signal("request::activate", "tasklist", {
            raise = true
        })
    end
end), awful.button({}, 3, function()
    awful.menu.client_list({
        theme = {
            width = 250
        }
    })
end), awful.button({}, 4, function()
    awful.client.focus.byidx(1)
end), awful.button({}, 5, function()
    awful.client.focus.byidx(-1)
end))

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

beautiful.useless_gap = 10
beautiful.gap_single_client = true

screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(awful.button({}, 1, function()
        awful.layout.inc(1)
    end), awful.button({}, 3, function()
        awful.layout.inc(-1)
    end), awful.button({}, 4, function()
        awful.layout.inc(1)
    end), awful.button({}, 5, function()
        awful.layout.inc(-1)
    end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s
    })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            launcher,
            s.mytaglist,
            s.mypromptbox
        },
        s.mytasklist, -- Middle widget
        {
            -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            s.mylayoutbox
        }
    }
end)

-- Mouse bindings
root.buttons(gears.table.join(
    awful.button({}, 3, function() mainmenu:toggle() end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))

-- Key bindings
require("mappings.global_keys")

clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- Rules to apply to new clients
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
            buttons = clientbuttons,
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
    -- Add titlebars to normal clients and dialogs
    {
        rule_any = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = true }
    }
}

function maximized_handler(c)
    if c.maximized then
        -- Hide titlebar
        awful.titlebar.hide(c)
        -- Hide border
        c.border_width = 0
    else
        awful.titlebar.show(c)
        c.border_width = beautiful.border_width
    end
end

-- Signals
client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end

    maximized_handler(c)

    -- Rounded corners
    -- c.shape = function(cr, w, h)
    --     gears.shape.rounded_rect(cr, w, h, 10)
    -- end
end)

client.connect_signal("property::maximized", function(c)
    maximized_handler(c)
end)

-- Double click handler
function double_click_handler(double_click_event)
    if double_click_timer then
        double_click_timer:stop()
        double_click_timer = nil
        return true
    end
    double_click_timer = gears.timer.start_new(0.20, function()
        double_click_timer = nil
        return false
    end)
end

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(awful.button({}, 1, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        -- Maximize on double click
        if double_click_handler() then
            c.maximized = not c.maximized
            c:raise()
            -- Else just move
        else
            awful.mouse.client.move(c)
        end
    end), awful.button({}, 2, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        -- Minimize on middle click
        c.minimized = true
        c:raise()
    end), awful.button({}, 3, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        awful.mouse.client.resize(c)
    end))

    awful.titlebar(c, {
        size = 25
    }):setup {
        {
            -- Left
            -- awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal
        },
        {
            -- Middle
            -- {
            -- Title
            -- align  = "center",
            -- widget = awful.titlebar.widget.titlewidget(c)
            -- },
            buttons = buttons,
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
end)

local function apply_borders(c)
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

client.connect_signal("property::floating", apply_borders)
client.connect_signal("focus", apply_borders)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)

-- Autostart Applications
-- awful.spawn.with_shell("picom")
