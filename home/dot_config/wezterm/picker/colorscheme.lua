local wezterm = require('wezterm')

local M = {}

local function prefers_dark_mode()
	local appearance = wezterm.gui.get_appearance()
	return appearance:find("Dark") ~= nil
end

function M.pick()
	if prefers_dark_mode() then
		return require("picker.dark").pick()
	else
		return require("picker.light").pick()
	end
end

return M
