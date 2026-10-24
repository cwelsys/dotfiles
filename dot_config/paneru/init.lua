---@diagnostic disable: undefined-global

paneru.setup({
	options = {
		focus_follows_mouse = true,
		mouse_follows_focus = true,
		preset_column_widths = { 0.33, 0.5, 0.75, 1.0 },
		animation_speed = 420.0,
		auto_center = true,
		window_hidden_ratio = 0.0,
		window_resize_cycle = true,
		reap_empty_workspaces = false,
		virtual_workspace_animations = true,
		mouse_resize_modifier = "alt",
		horizontal_mouse_warp = -1,
	},
	padding = {
		top = 0,
		bottom = 0,
		left = 0,
		right = 0,
	},
	swipe = {
		sensitivity = 0.35,
		deceleration = 4.0,
		continuous = false,
		gesture = {
			fingers_count = 3,
			direction = "Reversed",
			vertical = false,
		},
		scroll = {
			modifier = "alt",
			vertical_modifier = "shift",
		},
	},
	decorations = {
		workspace_menu_status = true,
		workspace_popup_status = false,
		active = {
			border = {
				enabled = true,
				color = "#89b4fa",
				width = 1.6,
				opacity = 1.0,
				radius = "auto",
			},
		},
	},
	restore = {
		enabled = true,
		startup_grace_ms = 2000,
		missing_windows = "ignore",
	},
	bindings = {
		["window virtualnum 1"] = "ctrl + alt + shift + cmd - 1",
		["window virtualnum 2"] = "ctrl + alt + shift + cmd - 2",
		["window virtualnum 3"] = "ctrl + alt + shift + cmd - 3",
		["window virtualnum 4"] = "ctrl + alt + shift + cmd - 4",
		["window virtualnum 5"] = "ctrl + alt + shift + cmd - 5",
		["window virtual south"] = "ctrl + alt + shift + cmd - j",
		["window virtual north"] = "ctrl + alt + shift + cmd - k",
		["window virtualmove south"] = "ctrl + alt + shift + cmd - u",
		["window virtualmove north"] = "ctrl + alt + shift + cmd - i",
		["window focus west"] = "ctrl + alt + shift + cmd - h",
		["window focus east"] = "ctrl + alt + shift + cmd - l",
		["window focus north"] = "ctrl + alt + shift + cmd - uparrow",
		["window focus south"] = "ctrl + alt + shift + cmd - downarrow",
		["window focus first"] = "ctrl + alt + shift + cmd - home",
		["window focus last"] = "ctrl + alt + shift + cmd - end",
		["window swap west"] = "ctrl + alt + shift + cmd - a",
		["window swap east"] = "ctrl + alt + shift + cmd - d",
		["window swap north"] = "ctrl + alt + shift + cmd - w",
		["window swap south"] = "ctrl + alt + shift + cmd - s",
		["window stack"] = "ctrl + alt + shift + cmd - leftbracket",
		["window unstack"] = "ctrl + alt + shift + cmd - rightbracket",
		["window center"] = "ctrl + alt + shift + cmd - space",
		["window shrink"] = "ctrl + alt + shift + cmd - minus",
		["window balance"] = "ctrl + alt + shift + cmd - b",
		["window equalize"] = "ctrl + alt + shift + cmd - x",
		["window manage"] = "ctrl + alt + shift + cmd - t",
		["window snap"] = "ctrl + alt + shift + cmd - n",
		["window raise floating"] = "ctrl + alt + shift + cmd - g",
		["mouse nextdisplay"] = "ctrl + cmd - tab",
		["window nextdisplay"] = "ctrl + cmd + shift - tab",
	},
	windows = {
		gaps = {
			title = ".*",
			horizontal_padding = 4,
			vertical_padding = 2,
		},
		pip = {
			title = "Picture.*(in)?.*[Pp]icture",
			floating = true,
		},
		finder = {
			title = ".*",
			bundle_id = "com.apple.finder",
			floating = true,
		},
		messages = {
			title = ".*",
			bundle_id = "com.apple.MobileSMS",
			floating = true,
		},
		kitty = {
			title = ".*",
			bundle_id = "net.kovidgoyal.kitty",
			index = 1,
		},
		zen = {
			title = ".*",
			bundle_id = "app.zen-browser.zen",
			index = 2,
		},
		systemsettings = {
			title = ".*",
			bundle_id = "com.apple.systempreferences",
			floating = true,
		},
	},
})

for _, chord in ipairs({ "ctrl + alt + shift + cmd - return", "ctrl + alt + shift + cmd - f" }) do
	paneru.bind(chord, "window fullwidth")
end
for _, chord in ipairs({ "ctrl + alt + shift + cmd - r", "ctrl + alt + shift + cmd - equal" }) do
	paneru.bind(chord, "window resize")
end

local home_workspaces = {
	["^app%.zen%-browser%.zen$"] = 1,
	["^net%.kovidgoyal%.kitty$"] = 2,
}

paneru.on("window_spawned", function(event, ws)
	if event.floating or not event.managed then
		return
	end
	for pattern, workspace in pairs(home_workspaces) do
		if event.bundle_id and event.bundle_id:match(pattern) then
			if ws:workspace_of(event.window_id) == workspace then
				return
			end
			return ws:shift(event.window_id, workspace, true)
		end
	end
end)
