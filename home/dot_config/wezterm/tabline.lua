-- i should have just forked tabline atp
local wez = require('wezterm')
local nf = wez.nerdfonts
local os = require('utils/os')

local M = {}

local function extract_process_name(title)
	if not title then return "" end

	-- Clean up admin prefixes
	title = title:gsub('^Administrator: ', '')
	title = title:gsub(' %(Admin%)', '')

	-- Extract filename from path (handles both / and \ separators)
	local filename = title:match('.*[/\\]([^/\\]+)$') or title

	-- Remove extensions
	filename = filename:gsub('%.exe$', ''):gsub('%.EXE$', ''):gsub('%.Exe$', '')
	filename = filename:gsub('%.bat$', ''):gsub('%.BAT$', '')
	filename = filename:gsub('%.cmd$', ''):gsub('%.CMD$', '')

	return filename
end

-- Distro icon mapping using basic, known-working icons
local function get_distro_icon(domain_name)
	if not domain_name then
		return nf.md_linux
	end

	local domain_lower = domain_name:lower()

	if domain_lower:find("ubuntu") then
		return nf.fa_ubuntu
	elseif domain_lower:find("debian") then
		return nf.dev_debian
	elseif domain_lower:find("fedora") then
		return nf.linux_fedora
	elseif domain_lower:find("centos") or domain_lower:find("rhel") or domain_lower:find("red hat") then
		return nf.linux_redhat
	elseif domain_lower:find("arch") then
		return nf.linux_archlinux
	elseif domain_lower:find("suse") or domain_lower:find("opensuse") then
		return nf.linux_opensuse
	elseif domain_lower:find("alpine") then
		return nf.linux_alpine
	elseif domain_lower:find("kali") then
		return nf.dev_kali
	elseif domain_lower:find("mint") then
		return nf.linux_mint
	elseif domain_lower:find("manjaro") then
		return nf.linux_manjaro
	else
		return nf.dev_linux
	end
end

local SHELLS = {
	ssh = { icon = nf.oct_globe, name = "Ssh" },
	pwsh = { icon = nf.cod_terminal_powershell, name = "Pwsh" },
	powershell = { icon = nf.cod_terminal_powershell, name = "PowerShell" },
	cmd = { icon = nf.cod_terminal_cmd, name = "Cmd" },
	bash = { icon = nf.cod_terminal_bash, name = "Bash" },
	zsh = { icon = nf.dev_terminal, name = "Zsh" },
	fish = { icon = nf.md_fish, name = "Fish" },
	nu = { icon = '🐚', name = "nu" },
	wslhost = {
		icon = function(domain_name)
			if domain_name and domain_name ~= "local" then
				return get_distro_icon(domain_name)
			end
			return nf.md_linux
		end,
		name = "WSL"
	},
}

local PROCESS_MAP = {
	nvim = { icon = nf.custom_neovim, name = "Neovim" },
	vim = { icon = nf.custom_neovim, name = "Neovim" },
	vi = { icon = nf.custom_neovim, name = "Neovim" },
	code = { icon = nf.custom_vscode, name = "VS Code" },
	lazygit = { icon = nf.dev_git, name = "Lazygit" },
	lg = { icon = nf.dev_git, name = "Lazygit" },
	lazydocker = { icon = nf.dev_docker, name = "Lazydocker" },
	ld = { icon = nf.dev_docker, name = "Lazydocker" },
	lazyjournal = { icon = nf.oct_log, name = "Lazyjournal" },
	lj = { icon = nf.oct_log, name = "Lazyjournal" },
	topgrade = { icon = nf.md_update, name = "Topgrade" },
	tg = { icon = nf.md_update, name = "Topgrade" },
	-- scoop = { icon = '🥣', name = "scoop" }, --scoop hook in pwsh profile is causing interference
	yazi = { icon = '🦆', name = "yazi" },
	y = { icon = '🦆', name = "yazi" },
	node = { icon = nf.dev_nodejs_small, name = "Node.js" },
	python = { icon = nf.dev_python, name = "Python" },
	cargo = { icon = '🦀', name = "cargo" },
	npm = { icon = nf.dev_npm, name = "npm" },
	yarn = { icon = nf.seti_yarn, name = "yarn" },
	htop = { icon = nf.md_monitor, name = "htop" },
	btop = { icon = nf.md_monitor, name = "btop" },
	ranger = { icon = nf.custom_folder_open, name = "Ranger" },
}

local tab_icons = {} -- Store icons per tab

local function get_icon_for_process(title, process_name, domain_name)
	if not title then
		if process_name then
			local process = extract_process_name(process_name):lower()
			local shell_info = SHELLS[process]
			if shell_info then
				-- Handle function icons (like wslhost)
				if type(shell_info.icon) == "function" then
					return shell_info.icon(domain_name)
				end
				return shell_info.icon
			end
		end
		return nil
	end

	local process = extract_process_name(title):lower()

	local shell_info = SHELLS[process]
	if shell_info then
		-- Handle function icons (like wslhost)
		if type(shell_info.icon) == "function" then
			return shell_info.icon(domain_name)
		end
		return shell_info.icon
	end

	local process_info = PROCESS_MAP[process]
	if process_info then
		return process_info.icon
	end

	local title_lower = title:lower()
	for proc_name, info in pairs(PROCESS_MAP) do
		if title_lower:find(proc_name) then
			return info.icon
		end
	end

	for shell_name, info in pairs(SHELLS) do
		if title_lower:find(shell_name) then
			-- Handle function icons (like wslhost)
			if type(info.icon) == "function" then
				return info.icon(domain_name)
			end
			return info.icon
		end
	end

	if process_name then
		local process = extract_process_name(process_name):lower()
		local shell_info = SHELLS[process]
		if shell_info then
			-- Handle function icons (like wslhost)
			if type(shell_info.icon) == "function" then
				return shell_info.icon(domain_name)
			end
			return shell_info.icon
		end
	end

	return nil
end

local function get_display_name(title, process_name)
	if not title then return "" end

	local process = extract_process_name(title):lower()

	local shell_info = SHELLS[process]
	if shell_info then
		return ""
	end

	local process_info = PROCESS_MAP[process]
	if process_info then
		return process_info.name
	end

	local title_lower = title:lower()
	for proc_name, info in pairs(PROCESS_MAP) do
		if title_lower:find("%f[%w]" .. proc_name .. "%f[%W]") then
			return info.name
		end
	end

	local fallback = extract_process_name(title)
	return fallback
end

local function get_tab_info(tab)
	local pane_title = tab.active_pane.title or ""
	local process_name = tab.active_pane.foreground_process_name or ""
	local tab_id = tab.tab_id

	-- Try to get domain name - check multiple possible ways
	local domain_name = nil
	if tab.active_pane.domain_name then
		domain_name = tab.active_pane.domain_name
	elseif tab.active_pane.get_domain and type(tab.active_pane.get_domain) == "function" then
		pcall(function() domain_name = tab.active_pane:get_domain().name end)
	end

	-- Handle explicit tab titles
	if tab.tab_title and #tab.tab_title > 0 then
		local icon = get_icon_for_process(pane_title, process_name, domain_name)
		if not icon then
			icon = get_icon_for_process(process_name, process_name, domain_name)
		end
		-- Store the icon if we found one, otherwise keep the previous one
		if icon then
			tab_icons[tab_id] = icon
		end
		return tab_icons[tab_id], tab.tab_title
	end

	local pane_display = get_display_name(pane_title, process_name)

	-- Try to get icon from pane title first, then process name
	local final_icon = get_icon_for_process(pane_title, process_name, domain_name)
	if not final_icon then
		final_icon = get_icon_for_process(process_name, process_name, domain_name)
	end

	local final_name = pane_title

	if pane_title:match("^[A-Za-z]:[/\\].*%.exe$") or pane_title:match("^[A-Za-z]:[/\\].*%.EXE$") then
		local exec_name = extract_process_name(pane_title):lower()
		local shell_info = SHELLS[exec_name]
		if shell_info then
			final_name = shell_info.name
			-- Update icon if we found a shell match - handle function icons
			if type(shell_info.icon) == "function" then
				final_icon = shell_info.icon(domain_name)
			else
				final_icon = shell_info.icon
			end
		else
			final_name = extract_process_name(pane_title)
		end
	else
		if pane_display ~= "" then
			local title_lower = pane_title:lower()
			for proc_name, info in pairs(PROCESS_MAP) do
				if title_lower:find("%f[%w]" .. proc_name .. "%f[%W]") then
					final_name = info.name
					-- Update icon if we found a process match
					final_icon = info.icon
					break
				end
			end
		end
	end

	-- Only update the stored icon if we found a new one
	if final_icon then
		tab_icons[tab_id] = final_icon
	end

	-- Return the stored icon (preserves last known icon) or fallback
	return tab_icons[tab_id] or nf.cod_terminal, final_name
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
	local schemes = wez.color.get_builtin_schemes()
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
	tabline_instance = wez.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

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
			-- tab_active = { process_name },
			-- tab_inactive = { process_name },
			tabline_x = (function()
				local components = {}
				-- local has_battery = wez.battery_info()[1] ~= nil

				-- if has_battery then
				-- 	table.insert(components, { "battery" })
				-- end
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
					style = " %b %d / %I:%M %p",
					icon = nf.cod_calendar,
					hour_to_icon = false,
					padding = { left = 0, right = 1 },
				},
			},
			tabline_z = {
				{
					"domain",
					padding = 0,
					icons_enabled = false, -- Disable plugin's automatic icons
					fmt = function(domain_name, window)
						if domain_name and domain_name ~= "local" then
							-- WSL domains - show distro icon + name
							local icon = get_distro_icon(domain_name)
							return icon .. " " .. domain_name
						else
							-- Local domain - show OS-specific icon + hostname
							local hostname = wez.hostname() or "local"
							if os.is_win then
								return nf.md_microsoft_windows .. " " .. hostname
							elseif os.is_mac then
								return nf.dev_apple .. " " .. hostname
							else
								return nf.dev_linux .. " " .. hostname
							end
						end
					end
				}
			},
		},
		extensions = {}
	})

	wez.on('update-status', function(window, pane)
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
