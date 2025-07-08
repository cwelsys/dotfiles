local wez = require('wezterm')
local os = require('utils.os')
local nf = wez.nerdfonts
local act = wez.action

-- Configuration options
local menu_config = {
	-- Set to true to show SSHMUX domains (multiplexing SSH connections)
	-- Set to false to only show plain SSH domains
	show_ssh_mux_domains = false,

	-- Set to true to show SSH: and SSHMUX: prefixes in domain names
	-- Set to false to show clean hostnames
	show_ssh_prefixes = false,
}

local opts = {
	launch_menu = {},
}

if os.is_win then
	opts.launch_menu = {
		{ label = 'Pwsh',       args = { 'pwsh', '-NoLogo' } },
		{ label = 'Cmd',        args = { 'cmd' } },
		{ label = 'Nu',         args = { 'nu' } },
		{ label = 'Msys2',      args = { 'ucrt64.cmd' },                            icon = nf.md_pac_man, color = '#f9e2af' },
		{ label = 'PowerShell', args = { 'powershell.exe', '-NoLogo' } },
		{ label = 'Git Bash',   args = { 'C:\\Program Files\\git\\bin\\bash.exe' }, icon = nf.dev_git,    color = '#94e2d5' },
		{
			label = 'nvim',
			args = { "nvim" },
			icon = nf.custom_neovim,
			color = '#179299'
		},
	}
elseif os.is_mac then
	opts.launch_menu = {
		{ label = 'Zsh',  args = { 'zsh', '-l' } },
		{ label = 'Fish', args = { '/opt/homebrew/bin/fish', '-l' } },
		{ label = 'Bash', args = { '/opt/homebrew/bin/bash', '-l' } },
		{ label = 'Pwsh', args = { '/usr/local/bin/pwsh', '-NoLogo' } },
		{ label = 'Nu',   args = { '/opt/homebrew/bin/nu', '-l' } },
		{
			label = 'nvim',
			args = { "/opt/homebrew/bin/nvim" },
			icon = nf.custom_neovim,
			color = '#179299'
		},
	}
elseif os.is_linux then
	opts.launch_menu = {
		{ label = 'Zsh',  args = { 'zsh', '-l' } },
		{ label = 'Fish', args = { 'fish', '-l' } },
		{ label = 'Bash', args = { 'bash', '-l' } },
	}
end

-- Get current hostname for filtering
local function get_current_hostname()
	-- Try multiple methods to get hostname
	local hostname = wez.hostname()
	if hostname then
		return hostname
	end

	-- Fallback methods
	local success, result = pcall(function()
		return wez.run_child_process({ 'hostname' })
	end)

	if success and result.stdout then
		return result.stdout:gsub('%s+', '')
	end

	return nil
end

-- SSH hosts to filter out from the launcher menu
local SSH_HOSTS_TO_FILTER = {
	'github.com',
	'gitea',
	'gitlab.com',
	'bitbucket.org',
}

-- Add current hostname to filter list
local current_hostname = get_current_hostname()
if current_hostname then
	-- Strip .local suffix on macOS to match tabline.lua hostname normalization
	if os.is_mac then
		current_hostname = current_hostname:gsub("%.local$", "")
	end
	table.insert(SSH_HOSTS_TO_FILTER, current_hostname)
end

-- Function to check if an SSH host should be filtered
local function should_filter_ssh_host(hostname)
	for _, filtered_host in ipairs(SSH_HOSTS_TO_FILTER) do
		if hostname:find(filtered_host) then
			return true
		end
	end
	return false
end

-- Function to check if SSH domain should be included based on mux settings
local function should_include_ssh_domain(domain_name)
	local is_mux_domain = domain_name:match('^SSHMUX:')
	local is_plain_ssh = domain_name:match('^SSH:')

	if is_mux_domain and not menu_config.show_ssh_mux_domains then
		return false
	end

	-- Always include plain SSH domains and custom domains
	return true
end

-- Function to clean up SSH domain display name
local function clean_ssh_domain_name(domain_name)
	if not menu_config.show_ssh_prefixes then
		-- Remove SSH: and SSHMUX: prefixes
		return domain_name:gsub('^SSH:', ''):gsub('^SSHMUX:', 'MUX')
	end
	return domain_name
end

-- Function to extract hostname from SSH args
local function extract_ssh_hostname(args)
	if args and args[1] == 'ssh' and args[2] then
		return args[2]
	end
	return nil
end

-- Custom SSH domains configuration (optional - for hosts not in SSH config)
local custom_ssh_domains = {
	-- Add your SSH hosts here manually if needed
	-- {
	--   name = 'example-server',
	--   remote_address = 'example.com',
	--   username = 'myuser',
	--   ssh_option = {
	--     identityfile = '~/.ssh/id_rsa',
	--   },
	-- },
}

-- Function to build SSH domains from launch menu entries
local function build_ssh_domains_from_launch_menu()
	local ssh_domains = {}

	for _, entry in ipairs(opts.launch_menu) do
		local hostname = extract_ssh_hostname(entry.args)
		if hostname and not should_filter_ssh_host(hostname) then
			table.insert(ssh_domains, {
				name = hostname,
				remote_address = hostname,
				username = nil, -- Will use current user or config
			})
		end
	end

	return ssh_domains
end

-- Merge all SSH domains
local function get_all_ssh_domains()
	local all_ssh_domains = {}

	-- Add default SSH domains (from ~/.ssh/config)
	for _, domain in ipairs(wez.default_ssh_domains()) do
		table.insert(all_ssh_domains, domain)
	end

	-- Add custom SSH domains (if any)
	for _, domain in ipairs(custom_ssh_domains) do
		table.insert(all_ssh_domains, domain)
	end

	return all_ssh_domains
end

local unix_domains = {}

-- Configure SSH domains with better shell integration
local function configure_ssh_domains()
	local ssh_domains = get_all_ssh_domains()

	-- Enhance SSH domains with better configuration for tab titles
	for _, domain in ipairs(ssh_domains) do
		-- Set assume_shell based on hostname
		if not domain.assume_shell then
			local hostname = domain.name:gsub('^SSH:', ''):gsub('^SSHMUX:', '')

			-- Set assume_shell based on known host types
			if hostname:match('wini') then
				-- Windows host
				domain.assume_shell = 'Unknown'
			else
				domain.assume_shell = 'Posix'
			end
		end

		-- Disable multiplexing for better integration unless explicitly set
		if domain.multiplexing == nil then
			domain.multiplexing = 'None'
		end
	end

	return ssh_domains
end

local domains = {
	ssh_domains = configure_ssh_domains(),
	unix_domains = unix_domains,
	wsl_domains = wez.default_wsl_domains(),
}

local M = {}
M.domains = domains

--[[ FormatItems: Begin ]]
---@class FormatItem.Text
---@field Text string

---@class FormatItem.Attribute.Intensity
---@field Intensity 'Bold'|'Half'|'Normal'

---@class FormatItem.Attribute.Italic
---@field Italic boolean

---@class FormatItem.Attribute.Underline
---@field Underline 'None'|'Single'|'Double'|'Curly'

---@class FormatItem.Attribute
---@field Attribute FormatItem.Attribute.Intensity|FormatItem.Attribute.Italic|FormatItem.Attribute.Underline

---@class FormatItem.Foreground
---@field Background {Color: string}

---@class FormatItem.Background
---@field Foreground {Color: string}

---@alias FormatItem.Reset 'ResetAttributes'

---@alias FormatItem FormatItem.Text|FormatItem.Attribute|FormatItem.Foreground|FormatItem.Background|FormatItem.Reset
--[[ FormatItems: End ]]

local attr_module = {}

---@param type 'Bold'|'Half'|'Normal'
---@return {Attribute: FormatItem.Attribute.Intensity}
attr_module.intensity = function(type)
	return { Attribute = { Intensity = type } }
end

---@return {Attribute: FormatItem.Attribute.Italic}
attr_module.italic = function()
	return { Attribute = { Italic = true } }
end

---@param type 'None'|'Single'|'Double'|'Curly'
---@return {Attribute: FormatItem.Attribute.Underline}
attr_module.underline = function(type)
	return { Attribute = { Underline = type } }
end

---@alias Cells.SegmentColors {bg?: string|'UNSET', fg?: string|'UNSET'}

---@class Cells.Segment
---@field items FormatItem[]
---@field has_bg boolean
---@field has_fg boolean

---Format item generator for `wezterm.format` (ref: <https://wezfurlong.org/wezterm/config/lua/wezterm/format.html>)
---@class Cells
---@field segments table<string|number, Cells.Segment>
local Cells = {}
Cells.__index = Cells

---Attribute generator for `wezterm.format` (ref: <https://wezfurlong.org/wezterm/config/lua/wezterm/format.html>)
---@class Cells.Attributes
---@field intensity fun(type: 'Bold'|'Half'|'Normal'): {Attribute: FormatItem.Attribute.Intensity}
---@field underline fun(type: 'None'|'Single'|'Double'|'Curly'): {Attribute: FormatItem.Attribute.Underline}
---@field italic fun(): {Attribute: FormatItem.Attribute.Italic}
---@overload fun(...: FormatItem.Attribute): FormatItem.Attribute[]
Cells.attr = setmetatable(attr_module, {
	__call = function(_, ...)
		return { ... }
	end,
})

function Cells:new()
	return setmetatable({
		segments = {},
	}, self)
end

---Add a new segment with unique `segment_id` to the cells
---@param segment_id string|number the segment id
---@param text string the text to push
---@param color? Cells.SegmentColors the bg and fg colors for text
---@param attributes? FormatItem.Attribute[] use bold text
function Cells:add_segment(segment_id, text, color, attributes)
	color = color or {}

	---@type FormatItem[]
	local items = {}

	if color.bg then
		assert(color.bg ~= 'UNSET', 'Cannot use UNSET when adding new segment')
		table.insert(items, { Background = { Color = color.bg } })
	end
	if color.fg then
		assert(color.fg ~= 'UNSET', 'Cannot use UNSET when adding new segment') -- Corrected: was color.bg
		table.insert(items, { Foreground = { Color = color.fg } })
	end
	if attributes and #attributes > 0 then
		for _, attr_item in ipairs(attributes) do -- Renamed attr_ to attr_item
			table.insert(items, attr_item)
		end
	end
	table.insert(items, { Text = text })
	table.insert(items, 'ResetAttributes')

	---@type Cells.Segment
	self.segments[segment_id] = {
		items = items,
		has_bg = color.bg ~= nil,
		has_fg = color.fg ~= nil,
	}

	return self
end

---Check if the segment exists
---@private
---@param segment_id string|number the segment id
function Cells:_check_segment(segment_id)
	if not self.segments[segment_id] then
		error('Segment "' .. segment_id .. '" not found')
	end
end

---Update the text of a segment
---@param segment_id string|number the segment id
---@param text string the text to push
function Cells:update_segment_text(segment_id, text)
	self:_check_segment(segment_id)
	local idx = #self.segments[segment_id].items - 1
	self.segments[segment_id].items[idx] = { Text = text }
	return self
end

---Update the colors of a segment
---@param segment_id string|number the segment id
---@param color Cells.SegmentColors the bg and fg colors for text
function Cells:update_segment_colors(segment_id, color)
	assert(type(color) == 'table', 'Color must be a table')

	self:_check_segment(segment_id)

	local has_bg = self.segments[segment_id].has_bg
	local has_fg = self.segments[segment_id].has_fg

	if color.bg then
		if has_bg and color.bg == 'UNSET' then
			table.remove(self.segments[segment_id].items, 1)
			has_bg = false
			goto bg_end
		end

		if has_bg then
			self.segments[segment_id].items[1] = { Background = { Color = color.bg } }
		else
			table.insert(self.segments[segment_id].items, 1, { Background = { Color = color.bg } })
			has_bg = true
		end
	end
	::bg_end::

	if color.fg then
		local fg_idx = has_bg and 2 or 1
		if has_fg and color.fg == 'UNSET' then
			table.remove(self.segments[segment_id].items, fg_idx)
			has_fg = false
			goto fg_end
		end

		if has_fg then
			self.segments[segment_id].items[fg_idx] = { Foreground = { Color = color.fg } }
		else
			table.insert(
				self.segments[segment_id].items,
				fg_idx,
				{ Foreground = { Color = color.fg } }
			)
			has_fg = true
		end
	end
	::fg_end::

	self.segments[segment_id].has_bg = has_bg
	self.segments[segment_id].has_fg = has_fg
	return self
end

---Convert specific segments into a format that `wezterm.format` can use
---Segments will rendered in the order of the `ids` table
---@param ids table<string|number> the segment ids
---@return FormatItem[]
function Cells:render(ids)
	local cells_render = {}

	for _, id in ipairs(ids) do
		self:_check_segment(id)

		for _, item in pairs(self.segments[id].items) do
			table.insert(cells_render, item)
		end
	end
	return cells_render
end

---Convert all segments into a format that `wezterm.format` can use
--- WARNING: Segments may not be in the same order as they were added if the `segment_id` is a string

---@return FormatItem[]
function Cells:render_all()
	local cells_render_all = {}
	for _, segment in pairs(self.segments) do
		for _, item in pairs(segment.items) do
			table.insert(cells_render_all, item)
		end
	end
	return cells_render_all
end

---Reset all segments
function Cells:reset()
	self.segments = {}
end

local attr = Cells.attr

---@type table<string, Cells.SegmentColors>
-- stylua: ignore
local colors = {
	label_text   = { fg = '#CDD6F4' },
	icon_default = { fg = '#89B4FA' },
	icon_wsl     = { fg = '#FAB387' },
	icon_ssh     = { fg = '#a6e3a1' },
	icon_unix    = { fg = '#CBA6F7' },
}

-- WSL distribution icons mapping (base distros only)
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

-- Function to normalize distro name for matching
local function normalize_distro_name(name)
	if not name then return nil end

	-- Convert to lowercase and remove common prefixes/suffixes
	local normalized = name:lower()
	normalized = normalized:gsub('wsl:', '')
	normalized = normalized:gsub('linux', '')
	normalized = normalized:gsub('%-.*', '')          -- Remove version numbers like -20.04, -42
	normalized = normalized:gsub('%d+.*', '')         -- Remove version numbers at the end
	normalized = normalized:gsub('^%s*(.-)%s*$', '%1') -- Trim whitespace

	return normalized
end

-- Function to find distro info with proper fuzzy matching
local function get_distro_info(distro_name)
	if not distro_name then return nil end

	local normalized = normalize_distro_name(distro_name)
	if not normalized or normalized == '' then return nil end

	-- Direct match on normalized name
	local direct_match = WSL_DISTRO_ICONS[normalized]
	if direct_match then return direct_match end

	-- Fuzzy matching - check if normalized name contains any distro key
	for key, info in pairs(WSL_DISTRO_ICONS) do
		if normalized:find(key) or key:find(normalized) then
			return info
		end
	end

	return nil
end

-- Shell icons mapping
local SHELL_ICONS = {
	['pwsh'] = { icon = nf.dev_powershell, color = '#89b4fa' },
	['powershell'] = { icon = nf.dev_powershell, color = '#89b4fa' },
	['cmd'] = { icon = nf.cod_terminal_cmd, color = '#fab387' },
	['bash'] = { icon = nf.cod_terminal_bash, color = '#4E9A06' },
	['fish'] = { icon = nf.md_fish, color = '#89dceb' },
	['nu'] = { icon = nf.md_console, color = '#50C878' },
	['elvish'] = { icon = nf.md_console, color = '#FF6B35' },
	['xonsh'] = { icon = nf.dev_python, color = '#306998' },
	['dash'] = { icon = nf.md_console, color = '#757575' },
	['sh'] = { icon = nf.md_console, color = '#4EAA25' },
	['zsh'] = { icon = nf.md_console, color = '#89dceb' },
	['tcsh'] = { icon = nf.md_console, color = '#326CE5' },
	['csh'] = { icon = nf.md_console, color = '#326CE5' },
	['ksh'] = { icon = nf.md_console, color = '#FF6B6B' },
}

-- Helper function to detect shell from args
local function get_shell_from_args(args)
	if not args or #args == 0 then
		return nil
	end

	-- Helper function to extract shell name from path
	local function extract_shell_name(arg)
		if not arg then return nil end
		local normalized = arg:lower()
		local shell_name = normalized:match('.*[/\\]([^/\\]+)$') or normalized
		shell_name = shell_name:gsub('%.exe$', '')
		return shell_name
	end

	for i = 1, #args do
		local arg = args[i]
		if arg == '-e' and i < #args then
			local shell_candidate = extract_shell_name(args[i + 1])
			if shell_candidate and SHELL_ICONS[shell_candidate] then
				return shell_candidate
			end
		end

		local shell_candidate = extract_shell_name(arg)
		if shell_candidate and SHELL_ICONS[shell_candidate] then
			-- Skip common wrappers/launchers that aren't actual shells
			if shell_candidate ~= 'wsl' and shell_candidate ~= 'ssh' and
					shell_candidate ~= 'sudo' and shell_candidate ~= 'su' and
					not shell_candidate:match('%.cmd$') then
				return shell_candidate
			end
		end
	end

	-- If no shell found in the arguments, try the first argument as fallback
	local first_shell = extract_shell_name(args[1])
	if first_shell and SHELL_ICONS[first_shell] then
		return first_shell
	end

	return nil
end

local cells_instance = nil

local function initialize_cells()
	if not cells_instance then
		cells_instance = Cells:new()
				:add_segment('icon_default', ' ' .. nf.oct_terminal .. ' ', colors.icon_default)
				:add_segment('icon_wsl', ' ' .. nf.md_linux .. ' ', colors.icon_wsl)
				:add_segment('icon_ssh', ' ' .. nf.cod_remote .. ' ', colors.icon_ssh)
				:add_segment('icon_unix', ' ' .. nf.dev_gnu .. ' ', colors.icon_unix)
				:add_segment('label_text', '', colors.label_text, attr(attr.intensity('Bold')))
	end
end

local function build_choices()
	initialize_cells()

	if not cells_instance then
		error("Failed to initialize cells_instance")
	end

	local choices = {}
	local choices_data = {}
	local idx = 1

	for _, v in ipairs(opts.launch_menu) do
		cells_instance:update_segment_text('label_text', v.label)

		local icon_segment = 'icon_default'
		local cleanup_segment = nil

		if v.icon or v.color then
			local custom_icon_id = 'custom_icon_' .. idx
			local custom_color = v.color and { fg = v.color } or colors.icon_default
			local custom_icon = v.icon or nf.oct_terminal

			if custom_icon then
				cells_instance:add_segment(custom_icon_id, ' ' .. custom_icon .. ' ', custom_color)
				icon_segment = custom_icon_id
				cleanup_segment = custom_icon_id
			end
		else
			local shell_name = get_shell_from_args(v.args)
			if shell_name and SHELL_ICONS[shell_name] then
				local shell_info = SHELL_ICONS[shell_name]

				if shell_info and shell_info.icon and shell_info.color then
					local shell_icon_id = 'shell_icon_' .. idx
					local shell_color = { fg = shell_info.color }
					local shell_icon = shell_info.icon

					cells_instance:add_segment(shell_icon_id, ' ' .. shell_icon .. ' ', shell_color)
					icon_segment = shell_icon_id
					cleanup_segment = shell_icon_id
				end
			end
		end

		table.insert(choices, {
			id = tostring(idx),
			label = wez.format(cells_instance:render({ icon_segment, 'label_text' })),
		})
		table.insert(choices_data, {
			args = v.args,
			domain = 'DefaultDomain',
		})

		-- Clean up temporary segments
		if cleanup_segment then
			cells_instance.segments[cleanup_segment] = nil
		end

		idx = idx + 1
	end

	-- WSL domains
	for _, v in ipairs(domains.wsl_domains) do
		local distro_info = get_distro_info(v.distribution) or get_distro_info(v.name)

		-- Use just the distro name (without "WSL: " prefix)
		local display_name = v.distribution or v.name

		cells_instance:update_segment_text('label_text', display_name)

		local icon_segment = 'icon_wsl'

		if distro_info and distro_info.icon and distro_info.color then
			local custom_icon_id = 'custom_wsl_icon_' .. idx
			local custom_color = { fg = distro_info.color }
			local custom_icon = distro_info.icon

			cells_instance:add_segment(custom_icon_id, ' ' .. custom_icon .. ' ', custom_color)
			icon_segment = custom_icon_id
		end

		table.insert(choices, {
			id = tostring(idx),
			label = wez.format(cells_instance:render({ icon_segment, 'label_text' })),
		})
		table.insert(choices_data, {
			domain = { DomainName = v.name },
		})

		-- Clean up temporary segment
		if distro_info then
			cells_instance.segments['custom_wsl_icon_' .. idx] = nil
		end

		idx = idx + 1
	end

	-- SSH domains
	for _, v in ipairs(domains.ssh_domains) do
		-- Filter based on hostname and mux settings
		local clean_hostname = clean_ssh_domain_name(v.name)
		if should_include_ssh_domain(v.name) and not should_filter_ssh_host(clean_hostname) then
			-- Create display name - use clean name
			local display_name = clean_hostname
			if v.remote_address and v.remote_address ~= clean_hostname then
				display_name = clean_hostname .. ' (' .. v.remote_address .. ')'
			end

			cells_instance:update_segment_text('label_text', display_name)

			-- Create custom SSH icon with enhanced styling
			local custom_icon_id = 'custom_ssh_icon_' .. idx
			local ssh_color = colors.icon_ssh -- Use consistent SSH color
			local ssh_icon = nf.cod_remote

			cells_instance:add_segment(custom_icon_id, ' ' .. ssh_icon .. ' ', ssh_color)

			table.insert(choices, {
				id = tostring(idx),
				label = wez.format(cells_instance:render({ custom_icon_id, 'label_text' })),
			})
			table.insert(choices_data, {
				domain = { DomainName = v.name }, -- Keep original name for WezTerm
			})

			-- Clean up temporary segment
			cells_instance.segments[custom_icon_id] = nil

			idx = idx + 1
		end
	end

	-- Unix domains
	for _, v in ipairs(domains.unix_domains) do
		cells_instance:update_segment_text('label_text', v.name)

		table.insert(choices, {
			id = tostring(idx),
			label = wez.format(cells_instance:render({ 'icon_unix', 'label_text' })),
		})
		table.insert(choices_data, {
			domain = { DomainName = v.name },
		})
		idx = idx + 1
	end

	return choices, choices_data
end

local choices, choices_data = build_choices()

M.setup = function()
	wez.on('new-tab-button-click', function(window, pane, button, default_action)
		if default_action and button == 'Left' then
			window:perform_action(default_action, pane)
		end

		if default_action and button == 'Right' then
			window:perform_action(
				act.InputSelector({
					title = '🐚 Launch Menu',
					choices = choices,
					fuzzy = true,
					fuzzy_description = nf.md_rocket .. '  : ',
					action = wez.action_callback(function(_window, _pane, id, label)
						if not id and not label then
							return
						else
							wez.log_info('you selected ', id, label)
							wez.log_info(choices_data[tonumber(id)])
							window:perform_action(
								act.SpawnCommandInNewTab(choices_data[tonumber(id)]),
								pane
							)
						end
					end),
				}),
				pane
			)
		end
		return false
	end)
end

return M
