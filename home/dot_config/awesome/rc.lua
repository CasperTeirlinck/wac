-- ref: https://awesomewm.org/doc/api/documentation/05-awesomerc.md.html
pcall(require, "luarocks.loader")
require("utils.error_handler")

require("awful").util.shell = "/home/casper/.nix-profile/bin/zsh"

require("theme")
require("layout")
require("clients")

root.buttons(require("mappings.global_mouse"))
root.keys(require("mappings.global_keys"))
