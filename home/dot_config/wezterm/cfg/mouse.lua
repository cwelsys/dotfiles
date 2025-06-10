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
    -- Right-click to copy selection or paste
    {
      event = { Down = { streak = 1, button = "Right" } },
      mods = "NONE",
      action = wez.action_callback(function(window, pane)
        local has_selection = window:get_selection_text_for_pane(pane) ~= ""
        if has_selection then
          window:perform_action(wez.action.CopyTo("ClipboardAndPrimarySelection"), pane)
          window:perform_action(wez.action.ClearSelection, pane)
        else
          window:perform_action(wez.action({ PasteFrom = "Clipboard" }), pane)
        end
      end),
    },
  }
end

return M
