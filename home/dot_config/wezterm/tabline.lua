local wezterm = require('wezterm')
local nf = wezterm.nerdfonts

local M = {}

local function extract_process_name(title)
	if not title then return "" end
	title = title:gsub('^Administrator: ', '')
	title = title:gsub(' %(Admin%)', '')
	local filename = title:match('.*[/\\]([^/\\]+)$') or title
	filename = filename:gsub('%.exe$', '')
	filename = filename:gsub('%.EXE$', '')
	return filename
end

local ICON_MAP = {
	nvim = nf.custom_neovim,
	lazygit = nf.dev_git,
	lazydocker = nf.dev_docker,
	pwsh = nf.seti_powershell,
	powershell = nf.seti_powershell,
	cmd = nf.md_console,
	bash = nf.cod_terminal_bash,
	zsh = nf.dev_terminal,
	git = nf.dev_git_branch,
	node = nf.dev_nodejs_small,
	python = nf.dev_python,
	cargo = '🦀',
	npm = nf.dev_npm,
}

local APP_PATTERNS = {
	{ pattern = "lazygit",    icon = nf.dev_git,       name = "Lazygit" },
	{ pattern = "lazydocker", icon = nf.dev_docker,    name = "Lazydocker" },
	{ pattern = "nvim",       icon = nf.custom_neovim, name = "Neovim" },
}

local function get_icon_for_process(title)
	if not title then return nf.oct_terminal end

	local title_lower = title:lower()
	for _, app in ipairs(APP_PATTERNS) do
		if title_lower:find(app.pattern) then
			return app.icon
		end
	end
	local process = extract_process_name(title):lower()
	return ICON_MAP[process] or nf.oct_terminal
end

local function get_display_name(title)
	if not title then return "" end
	local title_lower = title:lower()
	for _, app in ipairs(APP_PATTERNS) do
		if title_lower:find(app.pattern) then
			return app.name
		end
	end
	return extract_process_name(title)
end

local function get_tab_info(tab)
	if tab.tab_title and #tab.tab_title > 0 then
		return tab.tab_title, tab.tab_title
	end

	local pane_title = tab.active_pane.title or ""

	if pane_title:match("^~") then
		return nf.cod_home, pane_title
	end

	if pane_title:match("^%.%.") then
		local dir_name = pane_title:match("([^/\\]+)[/\\]?$") or ""
		return nf.custom_folder_open, "../" .. dir_name
	end

	local process_name = get_display_name(pane_title)
	local icon = get_icon_for_process(pane_title)

	return icon, process_name
end

local function tab_title(tab)
	local icon, _ = get_tab_info(tab)
	return icon
end

local function process_name(tab)
	local _, name = get_tab_info(tab)
	return name
end

local tabline_instance = nil

local function get_dynamic_theme_overrides(colorscheme_name)
	local schemes = wezterm.color.get_builtin_schemes()
	local scheme = schemes[colorscheme_name]

	if not scheme then
		return {}
	end
end

-- todo fix dynamic mode color generation
-- 	local bg = scheme.background or '#000000'
-- 	local fg = scheme.foreground or '#ffffff'

-- 	local bg_hex = bg:gsub('#', '')
-- 	local bg_num = tonumber(bg_hex, 16) or 0
-- 	local is_dark = bg_num < 0x808080

-- 	local pick_bg, font_bg, mid_bg

-- 	if is_dark then
-- 		pick_bg = '#4c7fd9'
-- 		font_bg = '#5cb85c'
-- 		mid_bg = '#404040'
-- 	else
-- 		pick_bg = '#2563eb'
-- 		font_bg = '#16a34a'
-- 		mid_bg = '#d1d5db'
-- 	end

-- 	return {
-- 		pick_mode = {
-- 			a = { fg = fg, bg = pick_bg },
-- 			b = { fg = pick_bg, bg = mid_bg },
-- 			c = { fg = fg, bg = bg },
-- 		},
-- 		font_mode = {
-- 			a = { fg = fg, bg = font_bg },
-- 			b = { fg = font_bg, bg = mid_bg },
-- 			c = { fg = fg, bg = bg },
-- 		},
-- 	}
-- end

function M.setup()
	tabline_instance = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

	local initial_theme_overrides = get_dynamic_theme_overrides(c.color_scheme)
	tabline_instance.setup({
		options = {
			icons_enabled = true,
			theme = c.color_scheme,
			section_separators = {
				left = nf.ple_right_half_circle_thick,
				right = nf.ple_left_half_circle_thick,
			},
			component_separators = {
				left = '',
				right = '',
			},
			tab_separators = {
				left = nf.ple_right_half_circle_thick .. ' ',
				right = nf.ple_left_half_circle_thick,
			},
			theme_overrides = initial_theme_overrides,
		},
		sections = {
			tabline_a = { {
				"mode",
				padding = 0,
				fmt = function(mode, window)
					if window:leader_is_active() then
						return " 🦀 "
					elseif mode == "NORMAL" then
						return " 🌴 "
					elseif mode == "PICK" then
						return " 🍺 "
					elseif mode == "FONT" then
						return " 📝 "
					elseif mode == "COPY" then
						return " ✂️ "
					elseif mode == "SEARCH" then
						return " 🔍 "
					end
					return mode
				end,
			} },
			tabline_b = {
				function(window)
					local active_mode = window:active_key_table()
					if active_mode == "pick_mode" then
						return " <c> color <f> font <s> size <l> height <esc> close"
					elseif active_mode == "font_mode" then
						return " <+> increase <-> decrease <0> reset <esc> close"
					end
					return ''
				end
			},
			tabline_c = { " " },
			tab_active = { tab_title, '  ', process_name },
			tab_inactive = { tab_title, '  ', process_name },
			tabline_x = (function()
				local components = {}
				local has_battery = wezterm.battery_info()[1] ~= nil

				if has_battery then
					table.insert(components, { "battery" })
				end
				-- table.insert(components, { "ram", icon = nf.fa_memory })
				-- table.insert(components, { "cpu", icon = nf.oct_cpu })

				table.insert(components, function(window)
					local metadata = window:active_pane():get_metadata()
					if not metadata then
						return ""
					end

					local latency = metadata.since_last_response_ms
					if not latency then
						return ""
					end

					local color
					local icon
					local red = "\27[31m"
					local yellow = "\27[33m"
					local green = "\27[32m"
					if metadata.is_tardy then
						if latency > 10000 then
							color = red
							icon = "󰢼"
							latency = ">999"
						else
							color = yellow
							icon = "󰢽"
						end
					else
						color = green
						icon = "󰢾"
						latency = "<1"
					end
					return string.format(color .. icon .. " %sms ", latency)
				end)

				return components
			end)(),
			tabline_y = {
				{
					"datetime",
					style = "%b %d / %I:%M %p",
					icon = ' ',
					hour_to_icon = false,
					padding = { left = 0, right = 1 },
				},
			},
			tabline_z = { { "domain", padding = 0, icons_only = true }, "hostname" },
		},
		extensions = {}
	})

	wezterm.on('update-status', function(window, pane)
		local overrides = window:get_config_overrides() or {}
		local current_scheme = overrides.color_scheme or c.color_scheme
		if not _G._last_tabline_theme then
			_G._last_tabline_theme = current_scheme
		elseif _G._last_tabline_theme ~= current_scheme then
			local new_theme_overrides = get_dynamic_theme_overrides(current_scheme)
			tabline_instance.set_theme(current_scheme, new_theme_overrides)
			_G._last_tabline_theme = current_scheme
		end
	end)
end

return M
