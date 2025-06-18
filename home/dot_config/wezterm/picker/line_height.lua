local wezterm = require('wezterm')

local M = {}

local line_heights = {
	{ id = "reset", label = "🔄 Reset to Default" },
	{ id = "0.8", label = "📏 Compressed (0.8)" },
	{ id = "0.9", label = "📏 Tight (0.9)" },
	{ id = "1.0", label = "📏 Normal (1.0)" },
	{ id = "1.1", label = "📏 Comfortable (1.1)" },
	{ id = "1.2", label = "📏 Relaxed (1.2)" },
	{ id = "1.3", label = "📏 Spacious (1.3)" },
	{ id = "1.4", label = "📏 Airy (1.4)" },
	{ id = "1.5", label = "📏 Very Spacious (1.5)" },
	{ id = "1.6", label = "📏 Extra Spacious (1.6)" },
	{ id = "1.7", label = "📏 Loose (1.7)" },
	{ id = "1.8", label = "📏 Very Loose (1.8)" },
	{ id = "1.9", label = "📏 Maximum (1.9)" },
	{ id = "2.0", label = "📏 Double Spaced (2.0)" },
}

function M.pick()
	local choices = {}
	for _, height in ipairs(line_heights) do
		table.insert(choices, {
			id = height.id,
			label = height.label,
		})
	end

	return wezterm.action.InputSelector {
		title = "📐 Select Line Height",
		choices = choices,
		fuzzy = true,
		action = wezterm.action_callback(function(window, pane, id, label)
			if not id then
				return
			end
			if id == "reset" then
				local overrides = window:get_config_overrides() or {}
				overrides.line_height = nil
				window:set_config_overrides(overrides)
			else
				window:set_config_overrides({
					line_height = tonumber(id)
				})
			end
		end),
	}
end

return M
