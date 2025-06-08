local wez = require('wezterm')
local style = require('cfg.style')
local remotes = require('cfg.remotes')
local keys = require('cfg.keys')
local shells = require('cfg.shells')
local session = require('utils.session')
local nvim = require('utils.nvim')
local bar = wez.plugin.require('https://github.com/adriankarlen/bar.wezterm')
local launch = require('utils.launch').setup()

local c = {}

if wez.config_builder then
  c = wez.config_builder()
end

c.automatically_reload_config = true
c.switch_to_last_active_tab_when_closing_tab = true

remotes.apply_to_config(c)
keys.apply_to_config(c)
shells.apply_to_config(c)
session.apply_to_config(c)
nvim.apply_to_config(c)
style.apply_to_config(c)

-- bar
c.enable_scroll_bar = false
c.enable_tab_bar = true
c.hide_tab_bar_if_only_one_tab = false
c.use_fancy_tab_bar = false
c.show_tab_index_in_tab_bar = false
bar.apply_to_config(c, {
  position = "top",
  modules = {
    clock = {
      enabled = true,
    },
    username = {
      icon = "",
    }
  },
})

return c
