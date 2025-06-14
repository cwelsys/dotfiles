------------------------------------------------------------------------------------------
-- Inspired by https://github.com/wez/wezterm/discussions/628#discussioncomment-1874614 --
------------------------------------------------------------------------------------------

local wez = require('wezterm')
local cells = require('utils.cells')
local optv = require('utils.optv')
local platform = require('utils.platform')

-- Move the colors definition here, before process_icons
---@type table<string, cells.SegmentColors>
-- stylua: ignore
local colors = {
   text_default          = { bg = '#45475A', fg = '#1C1B19' },
   text_hover            = { bg = '#5D87A3', fg = '#1C1B19' },
   text_active           = { bg = '#74c7ec', fg = '#11111B' },

   unseen_output_default = { bg = '#45475A', fg = '#FFA066' },
   unseen_output_hover   = { bg = '#5D87A3', fg = '#FFA066' },
   unseen_output_active  = { bg = '#74c7ec', fg = '#FFA066' },

   scircle_default       = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#45475A' },
   scircle_hover         = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#5D87A3' },
   scircle_active        = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#74C7EC' },

   brights = {
      '#F28FAD', -- 1: Red
      '#ABE9B3', -- 2: Green
      '#FAE3B0', -- 3: Yellow
      '#96CDFB', -- 4: Blue
      '#F5C2E7', -- 5: Magenta
      '#89DCEB', -- 6: Cyan
      '#D9E0EE', -- 7: White
   },
   ansi = {
      '#F28FAD', -- 1: Red
      '#ABE9B3', -- 2: Green
      '#FAE3B0', -- 3: Yellow
      '#96CDFB', -- 4: Blue
      '#F5C2E7', -- 5: Magenta
      '#89DCEB', -- 6: Cyan
      '#D9E0EE', -- 7: White
   },
   cursor_bg = '#F5E0DC'
}

-- The rest of your initialization code
local M = {}
local nf = wez.nerdfonts

-- Now your GLYPH constants and other variables
local GLYPH_SCIRCLE_LEFT = nf.ple_left_half_circle_thick --[[  ]]
local GLYPH_SCIRCLE_RIGHT = nf.ple_right_half_circle_thick --[[  ]]
local GLYPH_CIRCLE = nf.fa_circle --[[  ]]
local GLYPH_ADMIN = nf.md_shield_half_full --[[ 󰞀 ]]
local GLYPH_LINUX = nf.cod_terminal_linux --[[  ]]
local GLYPH_DEBUG = nf.fa_bug --[[  ]]
-- local GLYPH_SEARCH = nf.fa_search --[[  ]]
local GLYPH_SEARCH = '🔭'

local GLYPH_WINDOWS = nf.custom_windows --[[  ]]
local GLYPH_MACOS = nf.fa_apple --[[  ]]
local GLYPH_UNKNOWN = nf.md_console --[[ 󰆍 ]]

local GLYPH_UNSEEN_NUMBERED_BOX = {
   [1] = nf.md_numeric_1_box_multiple, --[[ 󰼏 ]]
   [2] = nf.md_numeric_2_box_multiple, --[[ 󰼐 ]]
   [3] = nf.md_numeric_3_box_multiple, --[[ 󰼑 ]]
   [4] = nf.md_numeric_4_box_multiple, --[[ 󰼒 ]]
   [5] = nf.md_numeric_5_box_multiple, --[[ 󰼓 ]]
   [6] = nf.md_numeric_6_box_multiple, --[[ 󰼔 ]]
   [7] = nf.md_numeric_7_box_multiple, --[[ 󰼕 ]]
   [8] = nf.md_numeric_8_box_multiple, --[[ 󰼖 ]]
   [9] = nf.md_numeric_9_box_multiple, --[[ 󰼗 ]]
   [10] = nf.md_numeric_9_plus_box_multiple, --[[ 󰼘 ]]
}

local GLYPH_UNSEEN_NUMBERED_CIRCLE = {
   [1] = nf.md_numeric_1_circle, --[[ 󰲠 ]]
   [2] = nf.md_numeric_2_circle, --[[ 󰲢 ]]
   [3] = nf.md_numeric_3_circle, --[[ 󰲤 ]]
   [4] = nf.md_numeric_4_circle, --[[ 󰲦 ]]
   [5] = nf.md_numeric_5_circle, --[[ 󰲨 ]]
   [6] = nf.md_numeric_6_circle, --[[ 󰲪 ]]
   [7] = nf.md_numeric_7_circle, --[[ 󰲬 ]]
   [8] = nf.md_numeric_8_circle, --[[ 󰲮 ]]
   [9] = nf.md_numeric_9_circle, --[[ 󰲰 ]]
   [10] = nf.md_numeric_9_plus_circle, --[[ 󰲲 ]]
}

local process_icons = {
      ['air'] = { nf.md_language_go, color = { fg = colors.brights[5] } },
      ['apt'] = { nf.dev_debian, color = { fg = colors.ansi[2] } },
      ['bacon'] = { nf.dev_rust, color = { fg = colors.ansi[2] } },
      ['bash'] = { nf.cod_terminal_bash, color = { fg = colors.cursor_bg or nil } },
      ['bat'] = { nf.md_bat, color = { fg = colors.ansi[5] } },
      ['btm'] = { nf.md_chart_donut_variant, color = { fg = colors.ansi[2] } },
      ['btop'] = { nf.md_chart_areaspline, color = { fg = colors.ansi[2] } },
      ['btop4win++'] = { nf.md_chart_areaspline, color = { fg = colors.ansi[2] } },
      ['bun'] = { nf.md_hamburger, color = { fg = colors.cursor_bg or nil } },
      ['cargo'] = { nf.dev_rust, color = { fg = colors.ansi[2] } },
      ['chezmoi'] = { nf.md_home_plus_outline, color = { fg = colors.brights[5] } },
      ['cmd.exe'] = { nf.md_console_line, color = { fg = colors.cursor_bg or nil } },
      ['curl'] = nf.md_flattr,
      ['debug'] = { nf.cod_debug, color = { fg = colors.ansi[5] } },
      ['default'] = nf.md_application,
      ['docker'] = { nf.md_docker, color = { fg = colors.ansi[5] } },
      ['docker-compose'] = { nf.md_docker, color = { fg = colors.ansi[5] } },
      ['dpkg'] = { nf.dev_debian, color = { fg = colors.ansi[2] } },
      ['fish'] = { nf.md_fish, color = { fg = colors.cursor_bg or nil } },
      ['gh'] = { nf.dev_github_badge, color = { fg = colors.brights[4] or nil } },
      ['git'] = { nf.dev_git, color = { fg = colors.brights[4] or nil } },
      ['go'] = { nf.md_language_go, color = { fg = colors.brights[5] } },
      ['htop'] = { nf.md_chart_areaspline, color = { fg = colors.ansi[2] } },
      ['kubectl'] = { nf.md_docker, color = { fg = colors.ansi[5] } },
      ['kuberlr'] = { nf.md_docker, color = { fg = colors.ansi[5] } },
      ['lazydocker'] = { nf.md_docker, color = { fg = colors.ansi[5] } },
      ['lazygit'] = { nf.cod_github, color = { fg = colors.brights[4] or nil } },
      ['lua'] = { nf.seti_lua, color = { fg = colors.ansi[5] } },
      ['make'] = nf.seti_makefile,
      ['nix'] = { nf.linux_nixos, color = { fg = colors.ansi[5] } },
      ['node'] = { nf.md_nodejs, color = { fg = colors.brights[2] } },
      ['npm'] = { nf.md_npm, color = { fg = colors.brights[2] } },
      ['nvim'] = { nf.custom_neovim, color = { fg = colors.ansi[3] } },
      ['oh-my-posh'] = { nf.fae_hotdog, color = { fg = colors.ansi[5] } },
      ['pacman'] = { nf.md_pac_man, color = { fg = colors.ansi[4] } },
      ['paru'] = { nf.md_pac_man, color = { fg = colors.ansi[4] } },
      ['pnpm'] = { nf.md_npm, color = { fg = colors.brights[4] } },
      ['postgresql'] = { nf.dev_postgresql, color = { fg = colors.ansi[5] } },
      ['powershell.exe'] = { nf.md_console, color = { fg = colors.cursor_bg or nil } },
      ['powershell'] = { nf.md_console, color = { fg = colors.cursor_bg or nil } },
      ['psql'] = { nf.dev_postgresql, color = { fg = colors.ansi[5] } },
      ['pwsh.exe'] = { nf.md_console, color = { fg = colors.cursor_bg or nil } },
      ['pwsh'] = { nf.md_console, color = { fg = colors.cursor_bg or nil } },
      ['rpm'] = { nf.dev_redhat, color = { fg = colors.ansi[2] } },
      ['redis'] = { nf.dev_redis, color = { fg = colors.ansi[5] } },
      ['ruby'] = { nf.cod_ruby, color = { fg = colors.brights[2] } },
      ['rust'] = { nf.dev_rust, color = { fg = colors.ansi[2] } },
      ['serial'] = nf.md_serial_port,
      ['ssh'] = nf.md_ssh,
      ['sudo'] = nf.fa_hashtag,
      ['tls'] = nf.md_power_socket,
      ['topgrade'] = { nf.md_rocket_launch, color = { fg = colors.ansi[5] } },
      ['unix'] = nf.md_bash,
      ['valkey'] = { nf.dev_redis, color = { fg = colors.brights[5] } },
      ['vim'] = { nf.dev_vim, color = { fg = colors.ansi[3] } },
      ['wget'] = nf.md_arrow_down_box,
      ['yarn'] = { nf.seti_yarn, color = { fg = colors.ansi[5] } },
      ['yay'] = { nf.md_pac_man, color = { fg = colors.ansi[4] } },
      ['yazi'] = { nf.md_duck, color = { fg = colors.brights[4] or nil } },
      ['yum'] = { nf.dev_redhat, color = { fg = colors.ansi[2] } },
      ['zsh'] = { nf.dev_terminal, color = { fg = colors.cursor_bg or nil } },
}

local TITLE_INSET = {
   DEFAULT = 6,
   ICON = 8,
}

local RENDER_VARIANTS = {
   { 'scircle_left', 'title', 'padding', 'scircle_right' },
   { 'scircle_left', 'title', 'unseen_output', 'padding', 'scircle_right' },
   { 'scircle_left', 'admin', 'title', 'padding', 'scircle_right' },
   { 'scircle_left', 'admin', 'title', 'unseen_output', 'padding', 'scircle_right' },
   { 'scircle_left', 'wsl', 'title', 'padding', 'scircle_right' },
   { 'scircle_left', 'wsl', 'title', 'unseen_output', 'padding', 'scircle_right' },
}

---
-- ================
-- Helper functions
-- ================

---@param proc string
local function clean_process_name(proc)
   local a = string.gsub(proc, '(.*[/\\])(.*)', '%2')
   return a:gsub('%.exe$', '')
end

---@param process_name string
---@param base_title string
---@param max_width number
---@param inset number
local function create_title(process_name, base_title, max_width, inset)
   local title
   local os_icon
   local proc_icon = ""

   -- Get process icon if available
   if process_name and process_name:len() > 0 then
      local icon_config = process_icons[process_name]
      if icon_config then
         if type(icon_config) == "table" then
            proc_icon = icon_config[1] .. " "  -- Use first element if it's a table
         else
            proc_icon = icon_config .. " "     -- Use directly if it's a string/icon
         end
         -- Add extra space for the icon
         inset = inset + 2
      end
   end

   if process_name:match('^wsl') then
      os_icon = ''
   elseif platform.is_win then
      os_icon = GLYPH_WINDOWS
   elseif platform.is_mac then
      os_icon = GLYPH_MACOS
   elseif platform.is_linux then
      os_icon = GLYPH_LINUX
   else
      os_icon = GLYPH_UNKNOWN
   end

   if process_name:len() > 0 then
      title = os_icon .. ' ' .. base_title
   else
      title = base_title
   end

   if base_title == 'Debug' then
      title = GLYPH_DEBUG .. ' DEBUG'
      inset = inset - 2
   end

   if base_title:match('^InputSelector:') ~= nil then
      title = base_title:gsub('InputSelector:', GLYPH_SEARCH)
      inset = inset - 2
   end

   if title:len() > max_width - inset then
      local diff = title:len() - max_width + inset
      title = title:sub(1, title:len() - diff)
   else
      local padding = max_width - title:len() - inset
      title = title .. string.rep(' ', padding)
   end

   return title .. proc_icon
end

---@param panes any[] WezTerm https://wezfurlong.org/wezterm/config/lua/pane/index.html
local function check_unseen_output(panes)
   local unseen_output = false
   local unseen_output_count = 0

   for i = 1, #panes, 1 do
      if panes[i].has_unseen_output then
         unseen_output = true
         if unseen_output_count >= 10 then
            unseen_output_count = 10
            break
         end
         unseen_output_count = unseen_output_count + 1
      end
   end

   return unseen_output, unseen_output_count
end

---
-- =================
-- Tab class and API
-- =================

---@class Tab
---@field title string
---@field cells cells
---@field title_locked boolean
---@field locked_title string
---@field is_wsl boolean
---@field is_admin boolean
---@field unseen_output boolean
---@field unseen_output_count number
---@field is_active boolean
local Tab = {}
Tab.__index = Tab

function Tab:new()
   local tab = {
      title = '',
      cells = cells:new(),
      title_locked = false,
      locked_title = '',
      is_wsl = false,
      is_admin = false,
      unseen_output = false,
      unseen_output_count = 0,
   }
   return setmetatable(tab, self)
end

---@param event_opts Event.TabTitleOptions
---@param tab any WezTerm https://wezfurlong.org/wezterm/config/lua/MuxTab/index.html
---@param max_width number
function Tab:set_info(event_opts, tab, max_width)
   local process_name = clean_process_name(tab.active_pane.foreground_process_name)

   self.is_wsl = process_name:match('^wsl') ~= nil
   self.is_admin = (
      tab.active_pane.title:match('^Administrator: ') or tab.active_pane.title:match('(Admin)')
   ) ~= nil
   self.unseen_output = false
   self.unseen_output_count = 0

   if not event_opts.hide_active_tab_unseen or not tab.is_active then
      self.unseen_output, self.unseen_output_count = check_unseen_output(tab.panes)
   end

   local inset = (self.is_admin or self.is_wsl) and TITLE_INSET.ICON or TITLE_INSET.DEFAULT
   if self.unseen_output then
      inset = inset + 2
   end

   if self.title_locked then
      self.title = create_title('', self.locked_title, max_width, inset)
      return
   end
   self.title = create_title(process_name, tab.active_pane.title, max_width, inset)
end

function Tab:create_cells()
   local attr = self.cells.attr
   self.cells
      :add_segment('scircle_left', GLYPH_SCIRCLE_LEFT)
      :add_segment('admin', ' ' .. GLYPH_ADMIN)
      :add_segment('wsl', ' ' .. GLYPH_LINUX)
      :add_segment('title', ' ', nil, attr(attr.intensity('Bold')))
      :add_segment('unseen_output', ' ' .. GLYPH_CIRCLE)
      :add_segment('padding', ' ')
      :add_segment('scircle_right', GLYPH_SCIRCLE_RIGHT)
end

---@param title string
function Tab:update_and_lock_title(title)
   self.locked_title = title
   self.title_locked = true
end

---@param event_opts Event.TabTitleOptions
---@param is_active boolean
---@param hover boolean
function Tab:update_cells(event_opts, is_active, hover)
   local tab_state = 'default'
   if is_active then
      tab_state = 'active'
   elseif hover then
      tab_state = 'hover'
   end

   self.cells:update_segment_text('title', ' ' .. self.title)

   if event_opts.unseen_icon == 'numbered_box' and self.unseen_output then
      self.cells:update_segment_text(
         'unseen_output',
         ' ' .. GLYPH_UNSEEN_NUMBERED_BOX[self.unseen_output_count]
      )
   end
   if event_opts.unseen_icon == 'numbered_circle' and self.unseen_output then
      self.cells:update_segment_text(
         'unseen_output',
         ' ' .. GLYPH_UNSEEN_NUMBERED_CIRCLE[self.unseen_output_count]
      )
   end

   self.cells
      :update_segment_colors('scircle_left', colors['scircle_' .. tab_state])
      :update_segment_colors('admin', colors['text_' .. tab_state])
      :update_segment_colors('wsl', colors['text_' .. tab_state])
      :update_segment_colors('title', colors['text_' .. tab_state])
      :update_segment_colors('unseen_output', colors['unseen_output_' .. tab_state])
      :update_segment_colors('padding', colors['text_' .. tab_state])
      :update_segment_colors('scircle_right', colors['scircle_' .. tab_state])
end

---@return FormatItem[] (ref: https://wezfurlong.org/wezterm/config/lua/wezterm/format.html)
function Tab:render()
   local variant_idx = self.is_admin and 3 or 1
   if self.is_wsl then
      variant_idx = 5
   end

   if self.unseen_output then
      variant_idx = variant_idx + 1
   end
   return self.cells:render(RENDER_VARIANTS[variant_idx])
end

---@type Tab[]
local tab_list = {}

-- Define the missing EVENT_OPTS validator
local EVENT_OPTS = {
  validator = {
    validate = function(opts)
      -- Simple validation that returns the opts with defaults
      local valid_opts = opts or {}
      valid_opts.hide_active_tab_unseen = valid_opts.hide_active_tab_unseen ~= nil
        and valid_opts.hide_active_tab_unseen
        or true
      valid_opts.unseen_icon = valid_opts.unseen_icon or 'circle'

      -- Ensure unseen_icon is valid
      if valid_opts.unseen_icon ~= 'circle' and
         valid_opts.unseen_icon ~= 'numbered_box' and
         valid_opts.unseen_icon ~= 'numbered_circle' then
        valid_opts.unseen_icon = 'circle'
      end

      return valid_opts, nil
    end
  }
}

---@param opts? Event.TabTitleOptions Default: {unseen_icon = 'circle', hide_active_tab_unseen = true}
M.setup = function(opts)
   local valid_opts, err = EVENT_OPTS.validator:validate(opts or {})

   if err then
      wez.log_error(err)
   end

   -- CUSTOM EVENT
   -- Event listener to manually update the tab name
   -- Tab name will remain locked until the `reset-tab-title` is triggered
   wez.on('tabs.manual-update-tab-title', function(window, pane)
      window:perform_action(
         wez.action.PromptInputLine({
            description = wez.format({
               { Foreground = { Color = '#FFFFFF' } },
               { Attribute = { Intensity = 'Bold' } },
               { Text = 'Enter new name for tab' },
            }),
            action = wez.action_callback(function(_window, _pane, line)
               if line ~= nil then
                  local tab = window:active_tab()
                  local id = tab:tab_id()
                  tab_list[id]:update_and_lock_title(line)
               end
            end),
         }),
         pane
      )
   end)

   -- CUSTOM EVENT
   -- Event listener to unlock manually set tab name
   wez.on('tabs.reset-tab-title', function(window, _pane)
      local tab = window:active_tab()
      local id = tab:tab_id()
      tab_list[id].title_locked = false
   end)

   -- CUSTOM EVENT
   -- Event listener to manually update the tab name
   wez.on('tabs.toggle-tab-bar', function(window, _pane)
      local effective_config = window:effective_config()
      window:set_config_overrides({
         enable_tab_bar = not effective_config.enable_tab_bar,
         background = effective_config.background,
      })
   end)

   -- BUILTIN EVENT
   wez.on('format-tab-title', function(tab, _tabs, _panes, _config, hover, max_width)
      if not tab_list[tab.tab_id] then
         tab_list[tab.tab_id] = Tab:new()
         tab_list[tab.tab_id]:set_info(valid_opts, tab, max_width)
         tab_list[tab.tab_id]:create_cells()
         return tab_list[tab.tab_id]:render()
      end

      tab_list[tab.tab_id]:set_info(valid_opts, tab, max_width)
      tab_list[tab.tab_id]:update_cells(valid_opts, tab.is_active, hover)
      return tab_list[tab.tab_id]:render()
   end)
end

return M
