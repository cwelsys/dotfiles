local wez = require('wezterm')
local c = wez.config_builder()
wez.log_info("reloading")
require("utils.tabs")(c)

require('events.launch').setup()
-- require('events.lstatus').setup()
-- require('events.rstatus').setup({ date_format = '%a %I:%M:%p' })
-- require('events.tabs').setup({ hide_active_tab_unseen = false, unseen_icon = 'circle' })
-- require('events.launch').setup()

-- config
require('cfg.style').apply_to_config(c)
require('cfg.mouse').setup(c)
require('cfg.links').setup(c)
require('cfg.keys').apply_to_config(c)
require('cfg.remotes').apply_to_config(c)
require('cfg.shells').apply_to_config(c)
-- require('cfg.nvim').apply_to_config(c)
-- require('utils.launch').setup()
-- require("utils.status").set_status()
-- require('utils.bar').apply_to_config(c)

c.exit_behavior = "CloseOnCleanExit"
c.automatically_reload_config = true
c.default_workspace = "~"
c.selection_word_boundary = " \t\n{}[]()\"'`,;:│=&!%"
c.warn_about_missing_glyphs = false
c.scrollback_lines = 10000
-- c.prefer_egl = true

return c

