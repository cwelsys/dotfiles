local wezterm = require('wezterm')

local M = {}

local function hex_to_rgb(hex)
	if not hex then return nil end
	hex = hex:gsub("#", "")
	if #hex == 3 then
		hex = hex:gsub("(%x)(%x)(%x)", "%1%1%2%2%3%3")
	end
	if #hex ~= 6 then return nil end

	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	return r, g, b
end

local function get_luminance(r, g, b)
	if not r or not g or not b then return nil end
	r, g, b = r / 255, g / 255, b / 255
	r = r <= 0.03928 and r / 12.92 or ((r + 0.055) / 1.055) ^ 2.4
	g = g <= 0.03928 and g / 12.92 or ((g + 0.055) / 1.055) ^ 2.4
	b = b <= 0.03928 and b / 12.92 or ((b + 0.055) / 1.055) ^ 2.4
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

local function is_light_scheme(scheme_data)
	local bg_color = scheme_data.background
	if not bg_color then return false end

	local r, g, b = hex_to_rgb(bg_color)
	if not r then return false end

	local luminance = get_luminance(r, g, b)
	if not luminance then return false end

	return luminance >= 0.4
end

function M.pick()
	local builtin_schemes = wezterm.color.get_builtin_schemes()
	local choices = {}

	table.insert(choices, {
		id = "reset",
		label = "🔄 Reset to Default",
	})

	local light_schemes = {}
	for name, scheme_data in pairs(builtin_schemes) do
		if is_light_scheme(scheme_data) then
			table.insert(light_schemes, name)
		end
	end

	table.sort(light_schemes)

	for _, name in ipairs(light_schemes) do
		table.insert(choices, {
			id = name,
			label = "☀️ " .. name,
		})
	end

	return wezterm.action.InputSelector {
		title = "☀️ Select Light Colorschemes",
		choices = choices,
		fuzzy = true,
		fuzzy_description = "☀️ Type to search light colorschemes...",
		action = wezterm.action_callback(function(window, pane, id, label)
			if not id then
				return
			end
			if id == "reset" then
				local overrides = window:get_config_overrides() or {}
				overrides.color_scheme = nil
				window:set_config_overrides(overrides)
			else
				window:set_config_overrides({
					color_scheme = id
				})
			end
		end),
	}
end

return M
