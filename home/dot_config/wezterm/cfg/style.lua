local wez = require('wezterm')
local gpu = require('utils.gpu')
local platform = require('utils.platform')
local mocha = {
  rosewater = "#f5e0dc",
  flamingo = "#f2cdcd",
  pink = "#f5c2e7",
  mauve = "#cba6f7",
  red = "#f38ba8",
  maroon = "#eba0ac",
  peach = "#fab387",
  yellow = "#f9e2af",
  green = "#a6e3a1",
  teal = "#94e2d5",
  sky = "#89dceb",
  sapphire = "#74c7ec",
  blue = "#89b4fa",
  lavender = "#b4befe",
  text = "#cdd6f4",
  subtext1 = "#bac2de",
  subtext0 = "#a6adc8",
  overlay2 = "#9399b2",
  overlay1 = "#7f849c",
  overlay0 = "#6c7086",
  surface2 = "#585b70",
  surface1 = "#45475a",
  surface0 = "#313244",
  base = "#1e1e2e",
  mantle = "#181825",
  crust = "#11111b",
}

local M = {}

M.apply_to_config = function(c)

   c.color_scheme = "Catppuccin Mocha"

   -- font
   c.font = wez.font("FantasqueSansM Nerd Font", { weight = "Medium" })
   c.font_rules = {
      {
         italic = true,
         font = wez.font("FantasqueSansM Nerd Font", { weight = "Medium", italic = true }),
      },
   }
   c.font_size = platform.is_mac and 16 or 14

   -- gfx
   c.front_end = 'WebGpu'
   c.webgpu_power_preference = 'HighPerformance'
   c.webgpu_preferred_adapter = gpu:pick_best()
   -- c.webgpu_preferred_adapter = platform.gpu_adapters:pick_manual('Dx12', 'IntegratedGpu')
   -- c.webgpu_preferred_adapter = platform.gpu_adapters:pick_manual('Gl', 'Other')

   -- Cursor
   c.animation_fps = 120
   c.cursor_blink_ease_in = 'EaseOut'
   c.cursor_blink_ease_out = 'EaseOut'
   c.default_cursor_style = 'BlinkingBlock'
   c.cursor_blink_rate = 650

   -- Window
   c.window_padding = {
      left = 5,
      right = 10,
      top = 12,
      bottom = 7,
   }
   c.adjust_window_size_when_changing_font_size = false
   c.window_close_confirmation = 'NeverPrompt'
   c.window_decorations = "RESIZE"
   c.tab_max_width = 25
   c.initial_cols = 100
   c.initial_rows = 32
   c.window_frame = {
    active_titlebar_bg = "#1e1e2e",
    inactive_titlebar_bg = "#1e1e2e",
    -- font = fonts.font,
    -- font_size = fonts.font_size,
  }
   c.inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 }
   c.visual_bell = {
      fade_in_function = 'EaseIn',
      fade_in_duration_ms = 250,
      fade_out_function = 'EaseOut',
      fade_out_duration_ms = 250,
      target = 'CursorColor',
   }

   -- tab bar
   c.enable_scroll_bar = false
   c.switch_to_last_active_tab_when_closing_tab = true
   c.enable_tab_bar = true
   c.hide_tab_bar_if_only_one_tab = false
   c.use_fancy_tab_bar = false
   c.show_tab_index_in_tab_bar = false
   c.colors = {
     tab_bar = {
       background = mocha.base
     }
   }
end

return M
