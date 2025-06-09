local wez = require('wezterm')
wez.log_info("reloading")

if wez.config_builder then
  c = wez.config_builder()
end

local c = {}

require('cfg.style').apply_to_config(c)
require('cfg.mouse').setup(c)
require('cfg.links').setup(c)
require('cfg.keys').apply_to_config(c)
require('cfg.remotes').apply_to_config(c)
require('cfg.shells').apply_to_config(c)
require('utils.nvim').apply_to_config(c)
require('utils.tabs').setup(c)
require('utils.launch').setup()
-- require('utils.bar').apply_to_config(c)

c.exit_behavior = "CloseOnCleanExit"
c.automatically_reload_config = true
c.default_workspace = "~"
c.selection_word_boundary = " \t\n{}[]()\"'`,;:│=&!%"
c.warn_about_missing_glyphs = false
c.scrollback_lines = 10000
-- c.prefer_egl = true

return c

