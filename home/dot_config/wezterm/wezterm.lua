local wez = require('wezterm')
local nf = wez.nerdfonts
local os = require('utils.os')

if wez.config_builder then
  c = wez.config_builder()
end

-- key/mouse bindings
require('binds').apply(c)

-- shells
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

-- opts
c.color_scheme = "Catppuccin Mocha"
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
c.colors = {
  tab_bar = {
    -- background = "#1e1e2e",
    new_tab = {
      bg_color = '#1e1e2e',
      fg_color = '#cdd6f4',
    },
    new_tab_hover = {
      bg_color = '#89b4fa',
      fg_color = '#1e1e2e',
      italic = true,
    }
  }
}
-- c.tab_bar_style = {
--   new_tab = wez.format({
--     { Background = { Color = 'rgba(0, 0, 0, 0)' } },
--     { Foreground = { Color = '#cdd6f4' } },
--     { Text = ' +' },
--   }),
--   new_tab_hover = wez.format({
--     { Background = { Color = 'rgba(0, 0, 0, 0)' } },
--     { Foreground = { Color = '#89b4fa' } },
--     { Text = ' +' },
--   }),
-- }

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
local function extract_process_name(title)
  if not title then return "" end

  -- Remove common prefixes
  title = title:gsub('^Administrator: ', '')
  title = title:gsub(' %(Admin%)', '')

  -- Extract just the filename from full path
  local filename = title:match('.*[/\\]([^/\\]+)$') or title

  -- Remove .exe extension (case insensitive)
  filename = filename:gsub('%.exe$', '')
  filename = filename:gsub('%.EXE$', '')

  return filename
end

-- Icon mapping for different applications with patterns
local ICON_MAP = {
  nvim = nf.custom_neovim,
  vim = nf.custom_neovim,
  lazygit = nf.dev_git,
  lazydocker = nf.dev_docker,
  atac = nf.md_api,
  apis = nf.md_api,
  pwsh = nf.seti_powershell,
  powershell = nf.seti_powershell,
  cmd = nf.md_console,
  bash = nf.cod_terminal_bash,
  zsh = nf.dev_terminal,
  git = nf.dev_git_branch,
  node = nf.dev_nodejs_small,
  python = nf.dev_python,
  cargo = nf.dev_rust,
  npm = nf.dev_npm,
}

-- Pattern-based application detection
local APP_PATTERNS = {
  { pattern = "lazygit",    icon = nf.dev_git,       name = "Lazygit" },
  { pattern = "lazydocker", icon = nf.dev_docker,    name = "Lazydocker" },
  { pattern = "neovim",     icon = nf.custom_neovim, name = "Neovim" },
  { pattern = "nvim",       icon = nf.custom_neovim, name = "Neovim" },
  { pattern = "atac",       icon = nf.md_api,        name = "ATAC" },
}

local function get_icon_for_process(title)
  if not title then return nf.oct_terminal end

  local title_lower = title:lower()

  -- First check for pattern matches (for complex titles like "repo - Lazygit")
  for _, app in ipairs(APP_PATTERNS) do
    if title_lower:find(app.pattern) then
      return app.icon
    end
  end

  -- Fall back to exact process name matching
  local process = extract_process_name(title):lower()
  return ICON_MAP[process] or nf.oct_terminal
end

local function get_display_name(title)
  if not title then return "" end

  local title_lower = title:lower()

  -- Check for pattern matches first
  for _, app in ipairs(APP_PATTERNS) do
    if title_lower:find(app.pattern) then
      return app.name
    end
  end

  -- Fall back to extracted process name
  return extract_process_name(title)
end

local function get_tab_info(tab)
  -- Use explicit tab title if set
  if tab.tab_title and #tab.tab_title > 0 then
    return tab.tab_title, tab.tab_title
  end

  local pane_title = tab.active_pane.title or ""

  -- Handle special directory patterns first
  if pane_title:match("^~") then
    return nf.cod_home, pane_title
  end

  if pane_title:match("^%.%.") then
    local dir_name = pane_title:match("([^/\\]+)[/\\]?$") or ""
    return nf.custom_folder_open, "../" .. dir_name
  end

  -- For process titles, show just the process name, not the full path
  local process_name = get_display_name(pane_title)
  local icon = get_icon_for_process(pane_title)

  return icon, process_name
end

local function tab_title(tab)
  local icon, _ = get_tab_info(tab)
  return icon
end

local function process_name(tab)
  local _, name = get_tab_info(tab)
  return name
end

tabline.setup({
  options = {
    icons_enabled = true,
    section_separators = {
      left = nf.ple_right_half_circle_thick,
      right = nf.ple_left_half_circle_thick,
    },
    component_separators = {
      left = '',
      right = '',
    },
    tab_separators = {
      left = nf.ple_right_half_circle_thick .. ' ',
      right = nf.ple_left_half_circle_thick,
    },
  },
  sections = {
    tabline_a = { {
      "mode",
      padding = 0,
      fmt = function(mode, window)
        if window:leader_is_active() then
          return " 🦀"
        elseif mode == "NORMAL" then
          return " 🌴"
        elseif mode == "COPY" then
          return "  "
        elseif mode == "SEARCH" then
          return "  "
        end
        return mode
      end,
    } },
    tabline_b = {},
    tabline_c = { " " },
    tab_active = { tab_title, " ", process_name },
    tab_inactive = { tab_title },
    tabline_x = (function()
      local components = {}
      -- local has_battery = wez.battery_info()[1] ~= nil

      -- if has_battery then
      --   table.insert(components, { "battery" })
      -- end
      -- table.insert(components, { "ram", icon = nf.fa_memory })
      -- table.insert(components, { "cpu", icon = nf.oct_cpu })

      table.insert(components, function(window)
        local metadata = window:active_pane():get_metadata()
        if not metadata then
          return ""
        end

        local latency = metadata.since_last_response_ms
        if not latency then
          return ""
        end

        local color
        local icon
        local red = "\27[31m"
        local yellow = "\27[33m"
        local green = "\27[32m"
        if metadata.is_tardy then
          if latency > 10000 then
            color = red
            icon = "󰢼"
            latency = ">999"
          else
            color = yellow
            icon = "󰢽"
          end
        else
          color = green
          icon = "󰢾"
          latency = "<1"
        end
        return string.format(color .. icon .. " %sms ", latency)
      end)

      return components
    end)(),
    tabline_y = {
      {
        "datetime",
        style = "%b %d / %I:%M %p",
        icon = ' ',
        hour_to_icon = false,
        padding = { left = 0, right = 1 },
      },
    },
    tabline_z = { { "domain", padding = 0, icons_only = true }, "hostname" },
  },
  extensions = {
    "resurrect",
    "smart_workspace_switcher",
    "quick_domains",
    "presentation",
  }
})

return c
