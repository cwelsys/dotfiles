local wez = require('wezterm')
local os = require('utils.os')

if wez.config_builder then
  c = wez.config_builder()
end

-- key/mouse bindings
require('binds').apply(c)

-- shells
if os.is_win then
  -- c.default_prog = { 'wsl' }
  c.default_prog = { 'pwsh', '-NoLogo' }
elseif os.is_mac then
  c.default_prog = { 'zsh' }
elseif os.is_linux then
  c.default_prog = { 'zsh' }
end

-- menus
local menu = require('utils.menu')
menu.setup()
require('utils.cmd_palette')

if menu.domains then
  c.ssh_domains = menu.domains.ssh_domains
  c.wsl_domains = menu.domains.wsl_domains
  c.unix_domains = menu.domains.unix_domains
end

-- plugins
local splits = wez.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
local tabline = require('tabline')

splits.apply_to_config(c)
tabline.setup()

-- opts
function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Catppuccin Mocha"
  else
    return "Catppuccin Mocha" -- not tryna get any more blind sorry
  end
end

c.color_scheme = scheme_for_appearance(wez.gui.get_appearance())
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
c.window_background_opacity = .8969
c.macos_window_background_blur = 60
-- c.win32_system_backdrop = "Tabbed"

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
c.skip_close_confirmation_for_processes_named = {
  'bash',
  'bash.exe',
  'sh',
  'zsh',
  'fish',
  'tmux',
  'nu',
  'nu.exe',
  'nvim',
  'ssh',
  'ssh.exe',
  'wsl.exe',
  'wslhost.exe',
  'conhost.exe',
  'cmd.exe',
  'pwsh.exe',
  'pwsh',
  'powershell.exe',
}
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

if os.is_mac then
  c.window_frame = {
    border_left_width = '2px',
    border_right_width = '2px',
    border_bottom_height = '2px',
    border_top_height = '2px',
    border_left_color = '#585b70',
    border_right_color = '#585b70',
    border_bottom_color = '#585b70',
    border_top_color = '#585b70',
  }
end

-- todo fix the new tab button why is just a block?
c.colors = {
  tab_bar = {
    new_tab = {
      bg_color = '#1e1e2e',
      fg_color = '#cdd6f4',
    },
    new_tab_hover = {
      bg_color = '#89b4fa',
      fg_color = '#1e1e2e',
      italic = true,
    },
  }
}

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

return c
