local wez = require("wezterm")
local os = require('utils.os')
local act = wez.action
local callback = wez.action_callback

local mod = {
   c = "CTRL",
   s = "SHIFT",
   a = "ALT",
   l = "LEADER",
}

if os.is_mac then
   mod.SUPER = 'SUPER'
elseif os.is_win or os.is_linux then
   mod.SUPER = 'ALT'
end

local keybind = function(mods, key, action)
   return { mods = table.concat(mods, "|"), key = key, action = action }
end

local M = {}

local leader = { mods = mod.SUPER, key = ";", timeout_miliseconds = 1000 }

local keys = function()
   local keys = {
      -- pane and tabs
      keybind({ mod.l }, "s", act.SplitVertical({ domain = "CurrentPaneDomain" })),
      keybind({ mod.l }, "v", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
      keybind({ mod.l }, "z", act.TogglePaneZoomState),
      keybind({ mod.l }, "x", act.CloseCurrentPane({ confirm = false })),
      keybind({ mod.l }, "X", act.CloseCurrentTab({ confirm = false })),
      keybind({ mod.l }, "c", act.SpawnTab("CurrentPaneDomain")),
      --- move between panes
      keybind({ mod.l }, "h", act.ActivatePaneDirection("Left")),
      keybind({ mod.l }, "j", act.ActivatePaneDirection("Down")),
      keybind({ mod.l }, "k", act.ActivatePaneDirection("Up")),
      keybind({ mod.l }, "l", act.ActivatePaneDirection("Right")),
      -- search
      keybind({ mod.SUPER }, "f", act.Search({ CaseInSensitiveString = '' })),
      -- cursor movement --
      keybind({ mod.SUPER }, "LeftArrow", act.SendString '\u{1b}OH'),
      keybind({ mod.SUPER }, "RightArrow", act.SendString '\u{1b}OF'),
      keybind({ mod.SUPER }, "Backspace", act.SendString '\u{15}'),
      -- spawn new tab
      keybind({ mod.SUPER }, "t", act.SpawnTab('CurrentPaneDomain')),
      -- close tab without confirmation
      keybind({ mod.SUPER }, "w", act.CloseCurrentTab({ confirm = false })),
      --- rename tab
      keybind(
         { mod.l },
         "e",
         act.PromptInputLine({
            description = wez.format({
               { Attribute = { Intensity = "Bold" } },
               { Foreground = { AnsiColor = "Fuchsia" } },
               { Text = "Renaming Tab title....:" },
            }),
            action = callback(function(win, _, line)
               if line == "" then
                  return
               end
               win:active_tab():set_title(line)
            end),
         })
      ),

      -- cmd palette
      keybind({ mod.c }, "p", act.ActivateCommandPalette),
      keybind({ mod.l }, "w", act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" })),

      -- copy and paste
      keybind({ mod.c, mod.s }, "c", act.CopyTo("Clipboard")),
      keybind({ mod.c }, "v", act.PasteFrom("Clipboard")),

      -- update all plugins
      keybind({ mod.l }, "u", callback(function(win)
         wez.plugin.update_all()
      end)),

      -- show the debug overlay
      keybind({ mod.l }, "d", wez.action.ShowDebugOverlay),

      -- picker mode
      keybind({ mod.l }, "p", callback(function(win)
         win:perform_action(act.ActivateKeyTable { name = "pick_mode" }, win:active_pane())
      end)),

      -- font mode for quick font size adjustments
      keybind({ mod.l }, "f", callback(function(win)
         win:perform_action(act.ActivateKeyTable { name = "font_mode" }, win:active_pane())
      end)),
   }

   -- leader number navigates to the tab
   for i = 1, 9 do
      table.insert(keys, keybind({ mod.l }, tostring(i), act.ActivateTab(i - 1)))
   end

   return keys
end

-- Mouse functionality
local setup_mouse = function(c)
   c.alternate_buffer_wheel_scroll_speed = 1
   c.bypass_mouse_reporting_modifiers = mod.SUPER
   c.mouse_bindings = {
      -- Don't open links without modifier
      {
         event = { Up = { streak = 1, button = "Left" } },
         action = wez.action.CompleteSelection("ClipboardAndPrimarySelection"),
      },
      {
         event = { Up = { streak = 1, button = "Left" } },
         mods = mod.SUPER,
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

-- setup key tables
local setup_key_tables = function(c)
   c.key_tables = {
      pick_mode = {
         {
            key = "Escape",
            action = callback(function(win)
               win:perform_action("PopKeyTable", win:active_pane())
            end)
         },
         {
            key = "c",
            action = callback(function(win)
               win:perform_action(require("picker.colorscheme").pick(), win:active_pane())
            end)
         },
         {
            key = "f",
            action = callback(function(win)
               win:perform_action(require("picker.font").pick(), win:active_pane())
            end)
         },
         {
            key = "s",
            action = callback(function(win)
               win:perform_action(require("picker.font_size").pick(), win:active_pane())
            end)
         },
         {
            key = "l",
            action = callback(function(win)
               win:perform_action(require("picker.line_height").pick(), win:active_pane())
            end)
         },
      },
      font_mode = {
         {
            key = "Escape",
            action = act.PopKeyTable,
         },
         {
            key = "+",
            action = act.IncreaseFontSize,
         },
         {
            key = "-",
            action = act.DecreaseFontSize,
         },
         {
            key = "0",
            action = act.ResetFontSize,
         },
      }
   }
end

M.apply = function(c)
   c.treat_left_ctrlalt_as_altgr = true
   c.leader = leader
   c.keys = keys()
   setup_mouse(c)
   setup_key_tables(c)
end

return M
