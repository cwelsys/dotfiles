local wez = require("wezterm")
local nf = wez.nerdfonts
local tabline = wez.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

local process_custom_icons = {
	["brew"] = " ",
	["curl"] = nf.md_arrow_down_box,
	["gitui"] = nf.dev_github_badge,
	["kubectl"] = nf.md_kubernetes,
	["kuberlr"] = nf.md_kubernetes,
	["python"] = { nf.md_language_python },
	["taskwarrior"] = { " " },
	["tmux"] = nf.cod_terminal_tmux,
}

local function tabs(c)
  tabline.setup({
    options = {
      theme_overrides = {
        normal_mode = {
          a = { fg = '#181825', bg = '#89b4fa' },
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
          b = { fg = '#cba6f7', bg = '#313244' },
          c = { fg = '#cdd6f4', bg = '#1e1e2e' },
        },
        tab = {
          active = { fg = '#89b4fa', bg = '#313244' },
          inactive = { fg = '#cdd6f4', bg = '#181825' },
          inactive_hover = { fg = '#f5c2e7', bg = '#1e1e2e' },
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
      tabline_a = 	{ {
        "mode",
        padding = { left = 1, right = 1 },
        fmt = function(mode, window)
          local pane = window:active_pane()
          local process = pane:get_foreground_process_name()
          local process_name = process:match("([^/\\]+)$") or process
          process_name = process_name:gsub("%.exe$", "")
          if window:leader_is_active() then
            return nf.oct_rocket .. " " .. process_name
          elseif mode == "COPY" then
            return nf.md_scissors_cutting .. " " .. process_name
          elseif mode == "SEARCH" then
            return nf.oct_search .. " " .. process_name
          else
            return process_name
          end
        end,
      } },
      tabline_b = {},
      tabline_c = {},
      tab_active = {           local process = pane:get_foreground_process_name()
          local process_name = process:match("([^/\\]+)$") or process
          process_name = process_name:gsub("%.exe$", "")
      ' ',
      { 'zoomed',  padding = 0 },
      -- { 'index',   padding = 0 },
      { 'process', padding = 0 },
      '|',
      { 'cwd', padding = 0 },
      ' '
    },
      tab_inactive = { "TEST INACTIVE" },
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
end

return tabs
