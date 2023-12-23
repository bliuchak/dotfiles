-- Inspiration
-- - https://ansidev.xyz/posts/2023-05-18-wezterm-cheatsheet

-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.color_scheme = "duskfox"
-- Hide title bar to get more space for the terminal window
config.window_decorations = "RESIZE"

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- and finally, return the configuration to wezterm
return config
