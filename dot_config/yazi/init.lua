-- Linemode size_only
function Linemode:size_only()
	local size = self._file:size()
	return size and ya.readable_size(size) or ""
end

-- Plugins
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

require("linemode-plus"):setup({
	date_mode = "custom",
	custom = {
		order = { "month", "day", "year" },
		separator = "/",
		year_digits = 2,
	},
})

require("mime-ext.local"):setup({
	fallback_file1 = true,
})

require("zoxide"):setup({
	update_db = false,
})

require("session"):setup({
	sync_yanked = true,
})

require("yafg"):setup({
	editor = "nvim",
	file_arg_format = "+{row} {file}",
})

require("projects"):setup({
	save = { method = "yazi" },
	last = {
		update_after_save = true,
		update_after_load = true,
		update_before_quit = true,
		load_after_start = false,
	},
})
require("restore"):setup({})

require("augment-command"):setup({
	prompt = false,
	smart_enter = true,
	smart_paste = true,
	smart_tab_create = true,
	smart_tab_switch = true,
})

th.git = th.git or {}
th.git.modified_sign = "M"
th.git.added_sign = "A"
th.git.untracked_sign = "?"
th.git.ignored_sign = "!"
th.git.deleted_sign = "D"
th.git.updated_sign = "U"
require("git"):setup()

require("starship"):setup({
	hide_flags = true,
	show_right_prompt = true,
	hide_count = true,
})

Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end

	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	})
end, 500, Status.RIGHT)
