local catppuccin_palette = {
	rosewater = "#f5e0dc",
	flamingo = "#f2cdcd",
	pink = "#f5c2e7",
	mauve = "#cba6f7",
	red = "#f38ba8",
	maroon = "#eba0ac",
	peach = "#fab387",
	yellow = "#f9e2af",
	green = "#a6e3a1",
	teal = "#94e2d5",
	sky = "#89dceb",
	sapphire = "#74c7ec",
	blue = "#89b4fa",
	lavender = "#b4befe",
	text = "#cdd6f4",
	subtext1 = "#bac2de",
	subtext0 = "#a6adc8",
	overlay2 = "#9399b2",
	overlay1 = "#7f849c",
	overlay0 = "#6c7086",
	surface2 = "#585b70",
	surface1 = "#45475a",
	surface0 = "#313244",
	base = "#1e1e2e",
	mantle = "#181825",
	crust = "#11111b",
}

-- Linemode
function Linemode:size_only()
	local size = self._file:size()
	return string.format("%s", size and ya.readable_size(size) or "")
end

-- Plugins
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

require("zoxide"):setup({
	update_db = false,
})

require("session"):setup({
	sync_yanked = true,
})

require("searchjump"):setup({
	unmatch_fg = catppuccin_palette.overlay0,
	match_str_fg = catppuccin_palette.green,
	match_str_bg = catppuccin_palette.base,
	first_match_str_fg = catppuccin_palette.lavender,
	first_match_str_bg = catppuccin_palette.base,
	lable_fg = catppuccin_palette.lavender,
	lable_bg = catppuccin_palette.base,
	only_current = false, -- only search the current window
	show_search_in_statusbar = true,
	auto_exit_when_unmatch = false,
	enable_capital_lable = true,
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

require("recycle-bin"):setup()
