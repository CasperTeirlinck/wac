local gears     = require("gears")
local beautiful = require("beautiful")

beautiful.init(gears.filesystem.get_configuration_dir() .. "theme/default/theme.lua")
beautiful.useless_gap = 10
beautiful.gap_single_client = true
