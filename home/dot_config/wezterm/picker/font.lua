local wezterm = require('wezterm')

local M = {}

--todo install nerdfonts or check system fonts to generate list
local fonts = {
	{ id = "reset", label = "🔄 Reset to Default" },
	{ id = "JetBrains Mono", label = "✈️ JetBrains Mono" },
	{ id = "Fira Code", label = "🔥 Fira Code" },
	{ id = "Cascadia Code", label = "💧 Cascadia Code" },
	{ id = "CaskaydiaCove Nerd Font", label = "💧 CaskaydiaCove NF" },
	{ id = "FiraCode Nerd Font", label = "🔥 FiraCode NF" },
	{ id = "JetBrainsMono Nerd Font", label = "✈️ JetBrainsMono NF" },
	{ id = "Hack Nerd Font", label = "⚡ Hack NF" },
	{ id = "UbuntuMono Nerd Font", label = "🐧 UbuntuMono NF" },
	{ id = "DroidSansMono Nerd Font", label = "🤖 DroidSansMono NF" },
	{ id = "VictorMono Nerd Font", label = "👑 VictorMono NF" },
	{ id = "Monaspace Neon", label = "🌈 Monaspace Neon" },
	{ id = "Monaspace Argon", label = "🌈 Monaspace Argon" },
	{ id = "Monaspace Xenon", label = "🌈 Monaspace Xenon" },
	{ id = "Monaspace Radon", label = "🌈 Monaspace Radon" },
	{ id = "Monaspace Krypton", label = "🌈 Monaspace Krypton" },
	{ id = "ComicShannsMono Nerd Font", label = "📚 ComicShannsMono NF" },
	{ id = "FantasqueSansM Nerd Font", label = "🎭 FantasqueSansM NF" },
	{ id = "Maple Mono", label = "🍁 Maple Mono" },
}

function M.pick()
	local choices = {}
	for _, font in ipairs(fonts) do
		table.insert(choices, {
			id = font.id,
			label = font.label,
		})
	end

	return wezterm.action.InputSelector {
		title = "🔤 Select Font",
		choices = choices,
		fuzzy = true,
		action = wezterm.action_callback(function(window, pane, id, label)
			if not id then
				return
			end
			if id == "reset" then
				-- Clear font override to restore default
				local overrides = window:get_config_overrides() or {}
				overrides.font = nil
				window:set_config_overrides(overrides)
			else
				window:set_config_overrides({
					font = wezterm.font(id)
				})
			end
		end),
	}
end

return M
