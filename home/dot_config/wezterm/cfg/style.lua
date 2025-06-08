local wez = require('wezterm')
local platform = require('utils.platform')

local M = {}

M.apply_to_config = function(c)
   -- Color scheme
   c.color_scheme = "Catppuccin Mocha"

   -- Fonts
   c.font = wez.font("FantasqueSansM Nerd Font", { weight = "Medium" })
   c.font_rules = {
      {
         italic = true,
         font = wez.font("FantasqueSansM Nerd Font", { weight = "Medium", italic = true }),
      },
   }
   c.font_size = platform.is_mac and 16 or 14

   -- Graphics
   c.front_end = 'WebGpu'
   c.webgpu_power_preference = 'HighPerformance'
   c.webgpu_preferred_adapter = platform.gpu_adapters:pick_best()
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
   c.inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 }

   -- Visual bell
   c.visual_bell = {
      fade_in_function = 'EaseIn',
      fade_in_duration_ms = 250,
      fade_out_function = 'EaseOut',
      fade_out_duration_ms = 250,
      target = 'CursorColor',
   }

   -- Tab bar appearance
   c.enable_scroll_bar = false
   c.enable_tab_bar = true
   c.hide_tab_bar_if_only_one_tab = false
   c.use_fancy_tab_bar = false
   c.show_tab_index_in_tab_bar = false
end

return M
