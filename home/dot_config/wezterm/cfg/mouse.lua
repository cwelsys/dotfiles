local wez = require("wezterm")
local keys = require("cfg.keys")

local M = {}

function M.setup(c)
  c.alternate_buffer_wheel_scroll_speed = 1
  c.bypass_mouse_reporting_modifiers = keys.mod
  c.mouse_bindings = {
    -- Don't open links without modifier
    {
      event = { Up = { streak = 1, button = "Left" } },
      action = wez.action.CompleteSelection("ClipboardAndPrimarySelection"),
    },
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = keys.mod,
      action = wez.action.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
    },
  }

end

return M
