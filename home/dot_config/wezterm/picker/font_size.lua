local wezterm = require('wezterm')

local M = {}

local font_sizes = {
	{ id = "reset", label = "🔄 Reset to Default" },
	{ id = "8", label = "🔍 Tiny (8px)" },
	{ id = "9", label = "🔍 Very Small (9px)" },
	{ id = "10", label = "📖 Small (10px)" },
	{ id = "11", label = "📖 Small+ (11px)" },
	{ id = "12", label = "📚 Medium- (12px)" },
	{ id = "13", label = "📚 Medium (13px)" },
	{ id = "14", label = "📚 Medium+ (14px)" },
	{ id = "15", label = "📖 Large- (15px)" },
	{ id = "16", label = "📖 Large (16px)" },
	{ id = "17", label = "📖 Large+ (17px)" },
	{ id = "18", label = "📕 Extra Large (18px)" },
	{ id = "19", label = "📕 Extra Large+ (19px)" },
	{ id = "20", label = "📙 Huge (20px)" },
	{ id = "21", label = "📙 Huge+ (21px)" },
	{ id = "22", label = "📗 Giant (22px)" },
	{ id = "23", label = "📗 Giant+ (23px)" },
	{ id = "24", label = "📘 Massive (24px)" },
}

function M.pick()
	local choices = {}
	for _, size in ipairs(font_sizes) do
		table.insert(choices, {
			id = size.id,
			label = size.label,
		})
	end

	return wezterm.action.InputSelector {
		title = "📏 Select Font Size",
		choices = choices,
		fuzzy = true,
		action = wezterm.action_callback(function(window, pane, id, label)
			if not id then
				return
			end

			if id == "reset" then
				local overrides = window:get_config_overrides() or {}
				overrides.font_size = nil
				window:set_config_overrides(overrides)
			else
				window:set_config_overrides({
					font_size = tonumber(id)
				})
			end
		end),
	}
end

return M
