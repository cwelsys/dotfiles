local wez = require('wezterm')
local nf = wez.nerdfonts
local os = require('utils.os')

if wez.config_builder then
  c = wez.config_builder()
end

-- key/mouse bindings
require('binds').apply(c)

-- shells
if os.is_win then
  c.default_prog = { 'pwsh', '-NoLogo' }
elseif os.is_mac then
  c.default_prog = { 'zsh' }
elseif os.is_linux then
  c.default_prog = { 'zsh' }
end

-- menu
local menu = require('utils.menu')
menu.setup()

if menu.domains then
  c.ssh_domains = menu.domains.ssh_domains
  c.wsl_domains = menu.domains.wsl_domains
  c.unix_domains = menu.domains.unix_domains
end

-- plugins
local splits = wez.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
-- local resurrect = wez.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
local switcher = wez.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local tabline = wez.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

switcher.get_choices = function(opts)
  return switcher.choices.get_workspace_elements({})
end

switcher.apply_to_config(c)
splits.apply_to_config(c)

-- opts
c.color_scheme = "Catppuccin Mocha"
c.exit_behavior = "CloseOnCleanExit"
c.automatically_reload_config = true
c.default_workspace = "~"
c.default_domain = "local"
c.selection_word_boundary = " \t\n{}[]()\"'`,;:│=&!%"
c.warn_about_missing_glyphs = false
c.scrollback_lines = 10000
c.prefer_egl = true
c.enable_scroll_bar = false
c.switch_to_last_active_tab_when_closing_tab = true
c.hide_tab_bar_if_only_one_tab = false
c.use_fancy_tab_bar = false

c.harfbuzz_features = { "zero", "cv01", "cv02", "ss03", "ss05", "ss07", "ss08", "calt=0", "clig=0", "liga=0" }
c.font_size = os.is_mac and 16 or 14
c.font = wez.font_with_fallback({
  { family = "FantasqueSansM Nerd Font", weight = "Medium" },
  { family = "CaskaydiaCove NF",         weight = "DemiBold" },
  { family = "FiraCode Nerd Font",       weight = "Regular" },
})
c.font_rules = {
  {
    italic = true,
    font = wez.font("FantasqueSansM Nerd Font", { weight = "Medium", italic = true }),
  },
  {
    intensity = "Bold",
    font = wez.font("FantasqueSansM Nerd Font", { weight = "Bold" }),
  },
  {
    intensity = "Bold",
    italic = true,
    font = wez.font("FantasqueSansM Nerd Font", { weight = "Bold", italic = true }),
  },
  {
    italic = true,
    font = wez.font("CaskaydiaCove NF", { weight = "DemiBold", italic = true }),
  },
  {
    intensity = "Bold",
    font = wez.font("CaskaydiaCove NF", { weight = "Bold" }),
  },
  {
    intensity = "Bold",
    italic = true,
    font = wez.font("CaskaydiaCove NF", { weight = "Bold", italic = true }),
  },
  {
    italic = true,
    font = wez.font("FiraCode Nerd Font", { weight = "Regular", italic = true }),
  },
  {
    intensity = "Bold",
    font = wez.font("FiraCode Nerd Font", { weight = "Bold" }),
  },
  {
    intensity = "Bold",
    italic = true,
    font = wez.font("FiraCode Nerd Font", { weight = "Bold", italic = true }),
  },
}

c.front_end = 'OpenGL'
if os.is_win then
  -- c.win32_system_backdrop = "Tabbed"
  c.window_background_opacity = .8969
elseif os.is_mac then
  c.macos_window_background_blur = 60
  c.window_background_opacity = 1.0
end

c.animation_fps = 120
c.cursor_blink_ease_in = 'EaseOut'
c.cursor_blink_ease_out = 'EaseOut'
c.default_cursor_style = 'BlinkingBlock'
c.cursor_blink_rate = 690

c.window_padding = {
  left = 5,
  right = 10,
  top = 12,
  bottom = 7,
}
c.adjust_window_size_when_changing_font_size = false
c.tab_and_split_indices_are_zero_based = true
c.window_close_confirmation = "NeverPrompt"
c.window_decorations = "RESIZE"
c.tab_max_width = 42
c.initial_cols = 120
c.initial_rows = 32
c.inactive_pane_hsb = { saturation = 0.9, brightness = 0.7 }
c.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 250,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 250,
  target = 'CursorColor',
}
c.colors = {
  tab_bar = {
    -- background = "#1e1e2e",
    new_tab = {
      bg_color = '#1e1e2e',
      fg_color = '#cdd6f4',
    },
    new_tab_hover = {
      bg_color = '#89b4fa',
      fg_color = '#1e1e2e',
      italic = true,
    }
  }
}
-- c.tab_bar_style = {
--   new_tab = wez.format({
--     { Background = { Color = 'rgba(0, 0, 0, 0)' } },
--     { Foreground = { Color = '#cdd6f4' } },
--     { Text = ' +' },
--   }),
--   new_tab_hover = wez.format({
--     { Background = { Color = 'rgba(0, 0, 0, 0)' } },
--     { Foreground = { Color = '#89b4fa' } },
--     { Text = ' +' },
--   }),
-- }

-- links
c.hyperlink_rules = {
  {
    regex = "\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b",
    format = "$0",
  },
  {
    regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
    format = "mailto:$0",
  },
  {
    regex = [[\bfile://\S*\b]],
    format = "$0",
  },
  {
    regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
    format = "$0",
  },
  {
    regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
    format = "https://www.github.com/$1/$3",
  },
}

-- tabline
local function clean_title(title)
  if not title then return "" end
  title = title:gsub('^Administrator: ', '')
  title = title:gsub(' %(Admin%)', '')
  title = title:gsub('.*[/\\]([^/\\]+)$', '%1')
  title = title:gsub('%.exe$', '')
  title = title:gsub('%.EXE$', '')
  return title
end

tabline.setup({
  options = {
    icons_enabled = true,
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
  },
  sections = {
    tabline_a = { {
      "mode",
      padding = 0,
      fmt = function(mode, window)
        if window:leader_is_active() then
          return " 🦀"
        elseif mode == "NORMAL" then
          return " 🌴"
        elseif mode == "COPY" then
          return "  "
        elseif mode == "SEARCH" then
          return "  "
        end
        return mode
      end,
    } },
    tabline_b = {},
    tabline_c = { " " },
    tabline_x = (function()
      local components = {}
      -- local has_battery = wez.battery_info()[1] ~= nil

      -- if has_battery then
      --   table.insert(components, { "battery" })
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
        style = "%b %d / %I:%M %p",
        icon = ' ',
        hour_to_icon = false,
        padding = { left = 0, right = 1 },
      },
    },
    tabline_z = { { "domain", padding = 0, icons_only = true }, "hostname" },
    tab_active = {
      { "process", icons_only = true, padding = { left = 1, right = 0 } },
      { "parent",  max_length = 10,   padding = 0,                      fmt = function(text) return text:lower() end },
      "/",
      { "cwd", max_length = 15, padding = { left = 0, right = 1 } },
    },
    tab_inactive = {
      { "process", icons_only = true, padding = { left = 1, right = 0 } },
      { "parent",  max_length = 10,   padding = 0,                      fmt = function(text) return text:lower() end },
      "/",
      { "cwd", max_length = 15, padding = { left = 0, right = 1 } },
      -- {
      --   "process",
      --   icons_only = true
      -- },
      -- function(tab)
      --   local pane = tab.active_pane
      --   if pane and pane.title then
      --     return clean_title(pane.title)
      --   end
      --   return tab.tab_title or "   "
      -- end
    },
  },
  extensions = {
    "resurrect",
    "smart_workspace_switcher",
    "quick_domains",
    "presentation",
  }
})

return c
