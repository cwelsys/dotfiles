local wez = require('wezterm')
local os = require('utils.os')
local nf = wez.nerdfonts
local act = wez.action

local opts = {
	launch_menu = {},
}

if os.is_win then
	opts.launch_menu = {
		{ label = 'Powershell',     args = { 'pwsh', '-NoLogo' } },
		-- { label = 'PowerShell Desktop', args = { 'powershell' } },
		{ label = 'Command Prompt', args = { 'cmd' } },
		{ label = 'Nushell',        args = { 'nu' } },
		{ label = 'Msys2',          args = { 'ucrt64.cmd' } },
		{
			label = 'Git Bash',
			args = { 'C:\\Program Files\\git\\bin\\bash.exe' },
		},
	}
elseif os.is_mac then
	opts.launch_menu = {
		{ label = 'Bash',    args = { 'bash', '-l' } },
		{ label = 'Fish',    args = { '/opt/homebrew/bin/fish', '-l' } },
		{ label = 'Nushell', args = { '/opt/homebrew/bin/nu', '-l' } },
		{ label = 'Zsh',     args = { 'zsh', '-l' } },
	}
elseif os.is_linux then
	opts.default_prog = { 'zsh' }
	opts.launch_menu = {
		{ label = 'Bash', args = { 'bash', '-l' } },
		{ label = 'Fish', args = { 'fish', '-l' } },
		{ label = 'Zsh',  args = { 'zsh', '-l' } },
	}
end

local ssh_domains = {}
local unix_domains = {}
local wsl_domains = {}

if os.is_win then
	ssh_domains = {
		{
			name = 'pbox',
			remote_address = 'pbox',
			multiplexing = 'None',
			assume_shell = "Posix"
		},
		{
			name = 'mba',
			remote_address = 'mba',
			multiplexing = 'None',
			assume_shell = "Posix"
		},
	}
	wsl_domains = {
		{
			name = 'Fedora',
			distribution = 'FedoraLinux-42',
			username = 'cwel',
			default_cwd = '~',
		},
		{
			name = 'Arch',
			distribution = 'archlinux',
			username = 'cwel',
			default_cwd = '~',
		}
	}
elseif os.is_mac then
	ssh_domains = {
		{
			name = 'pbox',
			remote_address = 'pbox',
			multiplexing = 'None',
			assume_shell = "Posix"
		},
		{
			name = 'wini',
			remote_address = 'wini',
			multiplexing = 'None'
		},
	}
elseif os.is_linux then
	ssh_domains = {
		{
			name = 'mba',
			remote_address = 'mba',
			multiplexing = 'None',
			assume_shell = "Posix"
		},
		{
			name = 'wini',
			remote_address = 'wini',
			multiplexing = 'None'
		},
	}
end

local domains = {
	ssh_domains = ssh_domains,
	unix_domains = unix_domains,
	wsl_domains = wsl_domains,
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

local attr_module = {} -- Renamed from attr to avoid conflict with Cells.attr

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
Cells.attr = setmetatable(attr_module, { -- Use the renamed attr_module
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
	local cells_render = {} -- Renamed from cells to avoid conflict

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
---
---@return FormatItem[]
function Cells:render_all()
	local cells_render_all = {} -- Renamed from cells to avoid conflict
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
	icon_ssh     = { fg = '#F38BA8' },
	icon_unix    = { fg = '#CBA6F7' },
}

local cells_instance = Cells:new() -- Renamed from 'cells' to 'cells_instance'
		:add_segment('icon_default', ' ' .. nf.oct_terminal .. ' ', colors.icon_default)
		:add_segment('icon_wsl', ' ' .. nf.md_linux .. ' ', colors.icon_wsl)
		:add_segment('icon_ssh', ' ' .. nf.cod_remote_explorer .. ' ', colors.icon_ssh)
		:add_segment('icon_unix', ' ' .. nf.dev_gnu .. ' ', colors.icon_unix)
		:add_segment('label_text', '', colors.label_text, attr(attr.intensity('Bold')))

local function build_choices()
	local choices = {}
	local choices_data = {}
	local idx = 1

	-- Add launch menu items (DefaultDomain)
	for _, v in ipairs(opts.launch_menu) do
		cells_instance:update_segment_text('label_text', v.label) -- Use cells_instance

		table.insert(choices, {
			id = tostring(idx),
			label = wez.format(cells_instance:render({ 'icon_default', 'label_text' })), -- Use cells_instance
		})
		table.insert(choices_data, {
			args = v.args,
			domain = 'DefaultDomain',
		})
		idx = idx + 1
	end

	-- Add WSL domains
	for _, v in ipairs(domains.wsl_domains) do
		cells_instance:update_segment_text('label_text', v.name) -- Use cells_instance

		table.insert(choices, {
			id = tostring(idx),
			label = wez.format(cells_instance:render({ 'icon_wsl', 'label_text' })), -- Use cells_instance
		})
		table.insert(choices_data, {
			domain = { DomainName = v.name },
		})
		idx = idx + 1
	end

	-- Add SSH domains
	for _, v in ipairs(domains.ssh_domains) do
		cells_instance:update_segment_text('label_text', v.name) -- Use cells_instance
		table.insert(choices, {
			id = tostring(idx),
			label = wez.format(cells_instance:render({ 'icon_ssh', 'label_text' })), -- Use cells_instance
		})
		table.insert(choices_data, {
			domain = { DomainName = v.name },
		})
		idx = idx + 1
	end

	-- Add Unix domains
	for _, v in ipairs(domains.unix_domains) do
		cells_instance:update_segment_text('label_text', v.name) -- Use cells_instance
		table.insert(choices, {
			id = tostring(idx),
			label = wez.format(cells_instance:render({ 'icon_unix', 'label_text' })), -- Use cells_instance
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
					title = 'Launch Menu',
					choices = choices,
					fuzzy = true,
					fuzzy_description = nf.md_rocket .. ' Select a lauch item: ',
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
