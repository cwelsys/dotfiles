local wez = require('wezterm')
local nf = wez.nerdfonts

-- utils
local gpu = require('utils.gpu')
local os = require('utils.os')

-- start config buildering
if wez.config_builder then
  c = wez.config_builder()
end
wez.log_info("reloading")

-- key/mouse bindings
require('binds').apply(c)

-- default shells
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

-- color
c.color_scheme = "Catppuccin Mocha"
c.colors = {
  tab_bar = {
    background = "#1e1e2e"
  }
}

-- font
c.font = wez.font("FantasqueSansM Nerd Font", { weight = "Medium" })
c.font_rules = {
  {
    italic = true,
    font = wez.font("FantasqueSansM Nerd Font", { weight = "Medium", italic = true }),
  },
}
c.font_size = os.is_mac and 16 or 14

-- gfx
c.front_end = 'WebGpu'
c.webgpu_power_preference = 'HighPerformance'
c.webgpu_preferred_adapter = gpu:pick_best()
-- c.webgpu_preferred_adapter = os.gpu_adapters:pick_manual('Dx12', 'IntegratedGpu')
-- c.webgpu_preferred_adapter = os.gpu_adapters:pick_manual('Gl', 'Other')

-- cursor
c.animation_fps = 120
c.cursor_blink_ease_in = 'EaseOut'
c.cursor_blink_ease_out = 'EaseOut'
c.default_cursor_style = 'BlinkingBlock'
c.cursor_blink_rate = 690

-- window
c.window_padding = {
  left = 5,
  right = 10,
  top = 12,
  bottom = 7,
}
c.adjust_window_size_when_changing_font_size = false
c.window_close_confirmation = "NeverPrompt"
c.window_decorations = "RESIZE"
c.tab_max_width = 42
c.initial_cols = 120
c.initial_rows = 32
-- c.window_frame = {
--   active_titlebar_bg = "#1e1e2e",
--   inactive_titlebar_bg = "#1e1e2e",
-- }
c.inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 }
c.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 250,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 250,
  target = 'CursorColor',
}

c.enable_scroll_bar = false
c.switch_to_last_active_tab_when_closing_tab = true
c.enable_tab_bar = true
c.hide_tab_bar_if_only_one_tab = false
c.use_fancy_tab_bar = false
c.show_tab_index_in_tab_bar = false

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
tabline.setup({
  options = {
    theme_overrides = {
      normal_mode = {
        a = { fg = '#89b4fa', bg = '#1e1e2e' },
        b = { fg = '#89b4fa', bg = '#313244' },
        c = { fg = '#cdd6f4', bg = '#1e1e2e' },
      },
      copy_mode = {
        a = { fg = '#181825', bg = '#f9e2af' },
        b = { fg = '#f9e2af', bg = '#313244' },
        c = { fg = '#cdd6f4', bg = '#1e1e2e' },
      },
      search_mode = {
        a = { fg = '#181825', bg = '#a6e3a1' },
        b = { fg = '#a6e3a1', bg = '#313244' },
        c = { fg = '#cdd6f4', bg = '#1e1e2e' },
      },
      window_mode = {
        a = { fg = '#181825', bg = '#cba6f7' },
        c = { fg = '#cdd6f4', bg = '#1e1e2e' },
      }
    },
    icons_enabled = true,
    theme = c.color_scheme,
    tabs_enabled = true,
    component_separators = {
      left = '',
      right = '',
    },
    section_separators = {
      right = nf.ple_left_half_circle_thick,
      left = nf.ple_right_half_circle_thick,
    },
    tab_separators = {
      left = nf.ple_right_half_circle_thick,
      right = nf.ple_left_half_circle_thick,
    }
  },
  sections = {
    tabline_a = { {
      "mode",
      padding = { left = 1, right = 1 },
      fmt = function(mode, window)
        if window:leader_is_active() then
          return wez.format({
            { Foreground = { Color = "#fab387" } },
            { Text = nf.oct_rocket },
          })
        elseif mode == "NORMAL" then
          return wez.format({
            { Foreground = { Color = "#cdd6f4" } },
            { Text = nf.oct_terminal },
          })
        elseif mode == "COPY" then
          return nf.md_scissors_cutting
        elseif mode == "SEARCH" then
          return nf.oct_search
        end
        return mode
      end,
    } },
    tabline_b = {},
    tabline_c = {},
    tab_active = {
      ' ',
      { 'zoomed', padding = 0 },
      { 'cwd',    padding = 0 },
      ' '
    },
    tabline_x = { "battery", "datetime" },
    tabline_y = { "ram", "cpu" },
    tabline_z = { { "domain", padding = 0, icons_only = true }, "hostname" },
  },
  extensions = {
    "resurrect",
    "smart_workspace_switcher",
    "quick_domains",
    "presentation",
  }
})

c.exit_behavior = "CloseOnCleanExit"
c.automatically_reload_config = true
c.default_workspace = "~"
c.selection_word_boundary = " \t\n{}[]()\"'`,;:│=&!%"
c.warn_about_missing_glyphs = false
c.scrollback_lines = 10000
c.prefer_egl = true

return c
