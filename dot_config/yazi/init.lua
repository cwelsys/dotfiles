-- Linemodes
function ya.readable_size(size)
	local units = { "B", "K", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q" }
	local i = 1
	while size > 1024 and i < #units do
		size = size / 1024
		i = i + 1
	end
	local s = string.format("%.1f %s", size, units[i]):gsub("[.,]0", "", 1)
	return s
end

local function short_date(t)
	if not t then
		return ""
	end
	local now = ya.time()
	if t.year == now.year and t.month == now.month and t.day == now.day then
		return t:format({ hour24 = "2-digit", minute = "2-digit" })
	end
	return t:format({ year = "2-digit", month = "2-digit", day = "2-digit" })
end

function Linemode:size_only()
	local size = self._file:size()
	return size and ya.readable_size(size) or ""
end

function Linemode:mtime()
	return short_date(self._file.stat.mtime)
end

function Linemode:btime()
	return short_date(self._file.stat.btime)
end

function Linemode:size_mtime()
	return string.format("%7s  %8s", self:size(), self:mtime())
end

-- Plugins
require("full-border"):setup({
	set = "rounded",
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

require("git"):setup({
	order = 1500,
})

require("no-header"):setup()

require("term-cwd"):setup()

Status:children_add(function()
	local h = cx.tab.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end

	return ui.Line({
		ui.Span(ya.user_name(h.stat.uid) or tostring(h.stat.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.stat.gid) or tostring(h.stat.gid)):fg("magenta"),
		" ",
	})
end, 500, Status.RIGHT)
