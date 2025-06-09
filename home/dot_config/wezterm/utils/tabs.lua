local wez = require("wezterm")

-- Create a module table
local M = {}

-- Add this to define colors before using them
local function get_colors(c)
  -- Get colors from the active color scheme
  local active_colors = wez.color.get_default_colors()
  return active_colors
end

local function leader(window)
  if window:leader_is_active() then
    return "   "
  end
  return ""
end

M.setup = function(c)
  local tabline = wez.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
  local colors = get_colors(c)

  tabline.setup({
    options = {
      icons_enabled = true,
      theme = 'Catppuccin Mocha',
      tabs_enabled = true,
      component_separators = {
        left = "",
        right = "",
      },
      section_separators = {
        left = "",
        right = "",
      },
      tab_separators = {
        left = "",
        right = "",
      },
      color_overrides = {
        normal_mode = {
          a = { fg = colors.background, bg = colors.ansi[5] },
          b = { fg = colors.indexed[59], bg = colors.background },
          c = { fg = colors.indexed[59], bg = colors.background },
        },
        copy_mode = {
          a = { fg = colors.background, bg = colors.ansi[4] },
          b = { fg = colors.ansi[4], bg = colors.background },
          c = { fg = colors.foreground, bg = colors.background },
        },
        search_mode = {
          a = { fg = colors.background, bg = colors.ansi[3] },
          b = { fg = colors.ansi[3], bg = colors.background },
          c = { fg = colors.foreground, bg = colors.background },
        },
        window_mode = {
          a = { fg = colors.background, bg = colors.ansi[6] },
          b = { fg = colors.ansi[6], bg = colors.background },
          c = { fg = colors.foreground, bg = colors.background },
        },
        tab = {
          active = { fg = colors.ansi[6], bg = colors.background },
          inactive = { fg = colors.indexed[59], bg = colors.background },
          inactive_hover = { fg = colors.ansi[6], bg = colors.background },
        },
      },
    },
    sections = {
      tabline_a = { leader },
      tabline_b = {},
      tabline_c = {},
      tab_active = { { "process", padding = { left = 0, right = 1 } } },
      tab_inactive = { "index", { "process", padding = { left = 0, right = 1 } } },
      tabline_x = { "battery", "ram", "cpu", "datetime" },
      tabline_y = {},
      tabline_z = {},
    },
    extensions = {
      "resurrect",
    },
  })
end

-- Return the module table
return M
