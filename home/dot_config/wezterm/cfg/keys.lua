local wez = require("wezterm")
local platform = require('utils.platform')
local act = wez.action
local callback = wez.action_callback

local mod = {
	c = "CTRL",
	s = "SHIFT",
	a = "ALT",
	l = "LEADER",
}

if platform.is_mac then
   mod.SUPER = 'SUPER'
elseif platform.is_win or platform.is_linux then
   mod.SUPER = 'ALT'
end

local keybind = function(mods, key, action)
	return { mods = table.concat(mods, "|"), key = key, action = action }
end

local M = {}

local leader = { mods = mod.SUPER, key = ";", timeout_miliseconds = 1000 }

local keys = function()
	local keys = {
		-- pane and tabs
		keybind({ mod.l }, "s", act.SplitVertical({ domain = "CurrentPaneDomain" })),
		keybind({ mod.l }, "v", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
		keybind({ mod.l }, "z", act.TogglePaneZoomState),
		keybind({ mod.l }, "x", act.CloseCurrentPane({ confirm = true })),
		keybind({ mod.l }, "c", act.SpawnTab("CurrentPaneDomain")),
		--- move between panes
		keybind({ mod.l }, "h", act.ActivatePaneDirection("Left")),
		keybind({ mod.l }, "j", act.ActivatePaneDirection("Down")),
		keybind({ mod.l }, "k", act.ActivatePaneDirection("Up")),
		keybind({ mod.l }, "l", act.ActivatePaneDirection("Right")),
		-- search
		keybind({ mod.SUPER }, "f", act.Search({ CaseInSensitiveString = '' })),
		-- cursor movement --
		keybind({ mod.SUPER }, "LeftArrow", act.SendString '\u{1b}OH'),
		keybind({ mod.SUPER }, "RightArrow", act.SendString '\u{1b}OF'),
		keybind({ mod.SUPER }, "Backspace", act.SendString '\u{15}'),
		-- spawn new tab
		keybind({ mod.SUPER }, "t", act.SpawnTab('CurrentPaneDomain')),
		--- rename tab
		keybind(
			{ mod.l },
			"e",
			act.PromptInputLine({
				description = wez.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { AnsiColor = "Fuchsia" } },
					{ Text = "Renaming Tab title....:" },
				}),
				action = callback(function(win, _, line)
					if line == "" then
						return
					end
					win:active_tab():set_title(line)
				end),
			})
		),

		-- workspaces
		keybind({ mod.l }, "w", act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" })),

		-- copy and paste
		keybind({ mod.c, mod.s }, "c", act.CopyTo("Clipboard")),
		keybind({ mod.c, mod.s }, "v", act.PasteFrom("Clipboard")),

		-- update all plugins
		keybind(
			{ mod.l },
			"u",
			callback(function(win)
				wez.plugin.update_all()
				win:toast_notification("wezterm", "plugins updated!", nil, 4000)
			end)
		),

		-- show the debug overlay
		keybind({ mod.l }, "d", wez.action.ShowDebugOverlay),
	}

	-- leader number navigates to the tab
	for i = 1, 9 do
		table.insert(keys, keybind({ mod.l }, tostring(i), act.ActivateTab(i - 1)))
	end

	return keys
end

M.apply_to_config = function(config)
	config.treat_left_ctrlalt_as_altgr = true
	config.leader = leader
	config.keys = keys()
end

return M
