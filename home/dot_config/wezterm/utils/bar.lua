local wez = require('wezterm')
local bar = wez.plugin.require('https://github.com/adriankarlen/bar.wezterm')

local M = {}

local bar_config = {
  position = "top",
  max_width = 32,
  padding = {
    left = 1,
    right = 1,
    tabs = {
      left = 0,
      right = 2,
    },
  },
  modules = {
    clock = {
      enabled = true,
      icon = wez.nerdfonts.md_calendar_clock,
      format = "%I:%M%p",
      color = 5,
    },
    username = {
      icon = "",
      color = 6,
    },
    tabs = {
      active_tab_fg = 4,
      inactive_tab_fg = 6,
      new_tab_fg = 2,
    },
    workspace = {
      enabled = true,
      icon = wez.nerdfonts.cod_window,
      color = 8,
    },
    leader = {
      enabled = true,
      icon = wez.nerdfonts.oct_rocket,
      color = 2,
    },
    zoom = {
      enabled = false,
      icon = wez.nerdfonts.md_fullscreen,
      color = 4,
    },
    pane = {
      enabled = true,
      icon = wez.nerdfonts.cod_multiple_windows,
      color = 7,
    },
    hostname = {
      enabled = true,
      icon = wez.nerdfonts.cod_server,
      color = 8,
    },
    cwd = {
      enabled = true,
      icon = wez.nerdfonts.oct_file_directory,
      color = 7,
    },
    spotify = {
      enabled = false,
      icon = wez.nerdfonts.fa_spotify,
      color = 3,
      max_width = 64,
      throttle = 15,
    },
  },
  separator = {
    space = 1,
    left_icon = "",
    right_icon = "",
    field_icon = wez.nerdfonts.indent_line,
  }
}

M.apply_to_config = function(c, options)
  local opts = options or bar_config
  bar.apply_to_config(c, opts)
end

return M
