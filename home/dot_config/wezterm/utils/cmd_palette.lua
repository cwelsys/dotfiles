local wezterm = require('wezterm')
local act = wezterm.action

wezterm.on("augment-command-palette", function(window, pane)
	-- wezterm.log_info("Calling custom command palette event handler")

	return {
		{
			brief = "Rename tab",
			icon = "md_rename_box",
			action = act.PromptInputLine {
				description = "Enter new name for tab",
				action = wezterm.action_callback(function(inner_window, inner_pane, line)
					if line then
						inner_window:active_tab():set_title(line)
					end
				end),
			},
		}, {
		brief = "🎨 Colorscheme picker",
		icon = "md_palette",
		action = require("picker.colorscheme").pick(),
	},
		{
			brief = "🔤 Font picker",
			icon = "md_format_font",
			action = require("picker.font").pick(),
		},
		{
			brief = "📏 Font size picker",
			icon = "md_format_font_size_decrease",
			action = require("picker.font_size").pick(),
		},
		{
			brief = "📐 Line height picker",
			icon = "fa_text_height",
			action = require("picker.line_height").pick(),
		},
		{
			brief = "🔄 Reset all font settings",
			icon = "md_restore",
			action = wezterm.action_callback(function(win, pane)
				local overrides = win:get_config_overrides() or {}
				overrides.font = nil
				overrides.font_size = nil
				overrides.line_height = nil
				win:set_config_overrides(overrides)
			end),
		},
		{
			brief = "🔄 Reset colorscheme",
			icon = "md_palette_outline",
			action = wezterm.action_callback(function(win, pane)
				local overrides = win:get_config_overrides() or {}
				overrides.color_scheme = nil
				win:set_config_overrides(overrides)
			end),
		},
		{
			brief = "🔄 Reset all appearance settings",
			icon = "md_auto_fix",
			action = wezterm.action_callback(function(win, pane)
				local overrides = win:get_config_overrides() or {}
				overrides.color_scheme = nil
				overrides.font = nil
				overrides.font_size = nil
				overrides.line_height = nil
				win:set_config_overrides(overrides)
			end),
		},
	}
end)
