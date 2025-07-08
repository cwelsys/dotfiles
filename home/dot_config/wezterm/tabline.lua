local wez = require('wezterm')
local nf = wez.nerdfonts
local os = require('utils.os')

local M = {}

local process_name_cache = {}

local function extract_process_name(title)
	if not title then return "" end

	if process_name_cache[title] then
		return process_name_cache[title]
	end

	local clean_title = title:gsub('^Administrator: ', '')
	clean_title = clean_title:gsub(' %(Admin%)', '')

	local filename = clean_title:match('.*[/\\]([^/\\]+)$') or clean_title

	filename = filename:gsub('%.exe$', '', 1):gsub('%.EXE$', '', 1):gsub('%.Exe$', '', 1)
	filename = filename:gsub('%.bat$', '', 1):gsub('%.BAT$', '', 1)
	filename = filename:gsub('%.cmd$', '', 1):gsub('%.CMD$', '', 1)

	process_name_cache[title] = filename
	return filename
end

local WSL_DISTRO_ICONS = {
	['ubuntu'] = { icon = nf.linux_ubuntu, color = '#E95420' },
	['debian'] = { icon = nf.linux_debian, color = '#A81D33' },
	['arch'] = { icon = nf.linux_archlinux, color = '#1793D1' },
	['alpine'] = { icon = nf.linux_alpine, color = '#0D597F' },
	['fedora'] = { icon = nf.linux_fedora, color = '#b4befe' },
	['opensuse'] = { icon = nf.linux_opensuse, color = '#73BA25' },
	['suse'] = { icon = nf.linux_opensuse, color = '#73BA25' },
	['centos'] = { icon = nf.linux_centos, color = '#932279' },
	['redhat'] = { icon = nf.linux_redhat, color = '#EE0000' },
	['kali'] = { icon = nf.linux_kali_linux, color = '#557C94' },
	['manjaro'] = { icon = nf.linux_manjaro, color = '#35BF5C' },
	['nixos'] = { icon = nf.linux_nixos, color = '#5277C3' },
	['pengwin'] = { icon = nf.md_penguin, color = '#FF6B35' },
	['oracle'] = { icon = nf.dev_oracle, color = '#F80000' },
	['alma'] = { icon = nf.linux_almalinux, color = '#0F4266' },
}

local function calculate_fuzzy_score(target, candidate)
	if not target or not candidate then return 0 end

	local target_lower = target:lower()
	local candidate_lower = candidate:lower()

	if target_lower == candidate_lower then return 100 end

	if target_lower:find('^' .. candidate_lower) or candidate_lower:find('^' .. target_lower) then
		return 90
	end

	if target_lower:find(candidate_lower) or candidate_lower:find(target_lower) then
		return 70
	end

	local score = 0
	local target_len = #target_lower
	local candidate_len = #candidate_lower
	local i, j = 1, 1

	while i <= target_len and j <= candidate_len do
		if target_lower:sub(i, i) == candidate_lower:sub(j, j) then
			score = score + 1
			j = j + 1
		end
		i = i + 1
	end

	return math.floor((score / math.max(target_len, candidate_len)) * 50)
end

local normalize_cache = {}
local function normalize_distro_name(name)
	if not name then return nil end

	if normalize_cache[name] then
		return normalize_cache[name]
	end

	local normalized = name:lower()
	normalized = normalized:gsub('wsl:', '')
	normalized = normalized:gsub('linux', '')
	normalized = normalized:gsub('%-.*', '')          -- Remove version numbers like -20.04, -42
	normalized = normalized:gsub('%d+.*', '')         -- Remove version numbers at the end
	normalized = normalized:gsub('^%s*(.-)%s*$', '%1') -- Trim whitespace

	normalize_cache[name] = normalized
	return normalized
end

local distro_match_cache = {}
local function get_distro_info(distro_name)
	if not distro_name then return nil end

	if distro_match_cache[distro_name] then
		return distro_match_cache[distro_name]
	end

	local normalized = normalize_distro_name(distro_name)
	if not normalized or normalized == '' then return nil end

	local direct_match = WSL_DISTRO_ICONS[normalized]
	if direct_match then
		distro_match_cache[distro_name] = direct_match
		return direct_match
	end

	local best_match = nil
	local best_score = 0

	for key, info in pairs(WSL_DISTRO_ICONS) do
		local score = calculate_fuzzy_score(normalized, key)
		if score > best_score and score >= 50 then -- Minimum threshold
			best_score = score
			best_match = info
		end
	end

	distro_match_cache[distro_name] = best_match
	return best_match
end

local function get_distro_icon(domain_name)
	if not domain_name then
		return nf.md_linux
	end

	local distro_info = get_distro_info(domain_name)
	if distro_info and distro_info.icon then
		return distro_info.icon
	end

	return nf.dev_linux
end

-- Simplified cache for remote OS detection (no TTL for now)
local remote_os_cache = {}

-- Enhanced remote OS detection with improved patterns
local function get_remote_os_icon(hostname, pane)
	if not hostname then
		return nf.dev_linux
	end

	if remote_os_cache[hostname] then
		return remote_os_cache[hostname]
	end

	-- Method 1: Try to get OS info from pane environment/metadata
	if pane then
		local pane_info = pane:get_metadata()
		if pane_info and pane_info.environment then
			local env = pane_info.environment
			-- Check for Windows environment variables
			if env.WINDIR or env.SYSTEMROOT or env.OS == "Windows_NT" then
				remote_os_cache[hostname] = nf.md_microsoft_windows
				return nf.md_microsoft_windows
			end
			-- Check for macOS
			if env.DARWIN_VERSION then
				local result = nf.dev_apple
				remote_os_cache[hostname] = result
				return result
			end
		end
	end

	-- Method 2: Try to detect via shell/process info
	if pane then
		local process_name = pane.foreground_process_name or ""
		if process_name:match("powershell") or process_name:match("pwsh") or process_name:match("cmd%.exe") then
			local result = nf.md_microsoft_windows
			remote_os_cache[hostname] = result
			return result
		end
	end

	-- Method 3: Fallback to hostname pattern matching (improved)
	local hostname_lower = hostname:lower()

	-- Windows patterns
	if hostname_lower:match('win') or
			hostname_lower:match('windows') or
			hostname_lower:match('w10') or
			hostname_lower:match('w11') or
			hostname_lower:match('srv') or
			hostname_lower:match('server') or
			hostname_lower:match('dc%d') or -- Domain controllers
			hostname_lower:match('ad%d') then -- Active Directory servers
		local result = nf.md_microsoft_windows
		remote_os_cache[hostname] = result
		return result
	end

	-- Mac patterns
	if hostname_lower:match('mac') or
			hostname_lower:match('osx') or
			hostname_lower:match('darwin') or
			hostname_lower:match('macos') or
			hostname_lower:match('imac') or
			hostname_lower:match('macbook') or
			hostname_lower:match('mba') or -- MacBook Air
			hostname_lower:match('mbp') then -- MacBook Pro
		local result = nf.dev_apple
		remote_os_cache[hostname] = result
		return result
	end

	-- Linux patterns (more specific distributions)
	if hostname_lower:match('ubuntu') or
			hostname_lower:match('debian') or
			hostname_lower:match('centos') or
			hostname_lower:match('rhel') or
			hostname_lower:match('fedora') or
			hostname_lower:match('arch') or
			hostname_lower:match('linux') or
			hostname_lower:match('pi') or -- Raspberry Pi
			hostname_lower:match('rpi') then
		local result = nf.dev_linux
		remote_os_cache[hostname] = result
		return result
	end

	-- Default to Linux for unknown Unix-like systems
	local result = nf.dev_linux
	remote_os_cache[hostname] = result
	return result
end

local SHELLS = {
	ssh = { icon = nf.oct_globe, name = "Ssh" },
	pwsh = { icon = nf.cod_terminal_powershell, name = "Pwsh" },
	powershell = { icon = nf.cod_terminal_powershell, name = "PowerShell" },
	cmd = { icon = nf.cod_terminal_cmd, name = "Cmd" },
	bash = { icon = nf.cod_terminal_bash, name = "Bash" },
	zsh = { icon = nf.dev_terminal, name = "Zsh" },
	fish = { icon = nf.md_fish, name = "Fish" },
	nu = { icon = nf.md_console, name = "Nu" }, -- Console icon for nu shell in tabs (🐚 is used in launch menu)
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
	-- Special case for Launch Menu to override nu shell detection
	["launch menu"] = { icon = '🐚', name = "Launch Menu" },
}

local tab_icon_cache = {}

local function get_icon_for_process(title, process_name, domain_name)
	local process_key = extract_process_name(title or process_name or ""):lower()
	if process_key ~= "" and tab_icon_cache[process_key] then
		return tab_icon_cache[process_key]
	end

	local result = nil

	local function resolve_icon(info, domain_name)
		if type(info.icon) == "function" then
			return info.icon(domain_name)
		end
		return info.icon
	end

	if title then
		local process = extract_process_name(title):lower()
		local shell_info = SHELLS[process]
		if shell_info then
			result = resolve_icon(shell_info, domain_name)
		else
			local process_info = PROCESS_MAP[process]
			if process_info then
				result = process_info.icon
			else
				local title_lower = title:lower()
				for proc_name, info in pairs(PROCESS_MAP) do
					if title_lower:find(proc_name) then
						result = info.icon
						break
					end
				end

				if not result then
					for shell_name, info in pairs(SHELLS) do
						if title_lower:find(shell_name) then
							result = resolve_icon(info, domain_name)
							break
						end
					end
				end
			end
		end
	end

	if not result and process_name then
		local process = extract_process_name(process_name):lower()
		local shell_info = SHELLS[process]
		if shell_info then
			result = resolve_icon(shell_info, domain_name)
		end
	end

	if process_key ~= "" and result then
		tab_icon_cache[process_key] = result
	end

	return result
end

local display_name_cache = {}

local function get_display_name(title)
	if not title then return "" end

	if display_name_cache[title] then
		return display_name_cache[title]
	end

	local process = extract_process_name(title):lower()
	local result = ""

	local shell_info = SHELLS[process]
	if shell_info then
		result = ""
	else
		local process_info = PROCESS_MAP[process]
		if process_info then
			result = process_info.name
		else
			local title_lower = title:lower()
			for proc_name, info in pairs(PROCESS_MAP) do
				if title_lower:find("%f[%w]" .. proc_name .. "%f[%W]") then
					result = info.name
					break
				end
			end

			if result == "" then
				result = extract_process_name(title)
			end
		end
	end

	display_name_cache[title] = result
	return result
end

local tab_icons = {}

local function get_tab_info(tab)
	local tab_id = tab.tab_id
	local pane_title = tab.active_pane.title or ""
	local process_name = tab.active_pane.foreground_process_name or ""

	local domain_name = tab.active_pane.domain_name
	if not domain_name and tab.active_pane.get_domain and type(tab.active_pane.get_domain) == "function" then
		local success, domain = pcall(function() return tab.active_pane:get_domain().name end)
		if success then domain_name = domain end
	end

	local final_icon, final_name

	if tab.tab_title and #tab.tab_title > 0 then
		final_icon = get_icon_for_process(pane_title, process_name, domain_name) or
				get_icon_for_process(process_name, process_name, domain_name)
		final_name = tab.tab_title
	else
		final_icon = get_icon_for_process(pane_title, process_name, domain_name)

		if pane_title:match("^[A-Za-z]:[/\\].*%.exe$") or pane_title:match("^[A-Za-z]:[/\\].*%.EXE$") then
			local exec_name = extract_process_name(pane_title):lower()
			local shell_info = SHELLS[exec_name]
			if shell_info then
				final_name = shell_info.name
				if type(shell_info.icon) == "function" then
					final_icon = shell_info.icon(domain_name)
				else
					final_icon = shell_info.icon
				end
			else
				final_name = extract_process_name(pane_title)
			end
		else
			final_name = get_display_name(pane_title)
			if final_name == "" then
				final_name = pane_title
			end
		end
	end

	final_icon = final_icon or tab_icons[tab_id] or nf.cod_terminal

	tab_icons[tab_id] = final_icon

	return final_icon, final_name
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



function M.setup()
	tabline_instance = wez.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

	-- Get the global config
	local config = wez.config_builder and wez.config_builder() or {}
	local current_scheme = config.color_scheme or "Catppuccin Mocha"

	local initial_theme_overrides = get_dynamic_theme_overrides(current_scheme)
	tabline_instance.setup({
		options = {
			icons_enabled = true,
			theme = current_scheme,
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
							-- Check if it's a WSL domain (starts with WSL:)
							if domain_name:match("^WSL:") then
								-- WSL domains - show distro icon + name
								local icon = get_distro_icon(domain_name)
								return icon .. " " .. domain_name
							else
								-- SSH domains - show target OS icon + hostname
								local hostname = domain_name
								-- Clean up SSH domain name (remove SSH: prefix if present)
								hostname = hostname:gsub("^SSH:", "")
								local pane = window:active_pane()
								local remote_os_icon = get_remote_os_icon(hostname, pane)
								return remote_os_icon .. " " .. hostname
							end
						else
							-- Local domain - show OS-specific icon + hostname
							local hostname = wez.hostname() or "local"
							-- Remove .local suffix on macOS
							hostname = hostname:gsub("%.local$", "")
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

	wez.on('update-status', function(window, _)
		local overrides = window:get_config_overrides() or {}
		local scheme = overrides.color_scheme or current_scheme
		if not _G._last_tabline_theme then
			_G._last_tabline_theme = scheme
		elseif _G._last_tabline_theme ~= scheme then
			local new_theme_overrides = get_dynamic_theme_overrides(scheme)
			tabline_instance.set_theme(scheme, new_theme_overrides)
			_G._last_tabline_theme = scheme
		end
	end)
end

return M
