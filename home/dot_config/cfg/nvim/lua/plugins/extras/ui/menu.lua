return {
	{ "nvzone/volt", lazy = true },
	{
		"nvzone/menu",
		lazy = true,
		keys = {
			{
				"<RightMouse>",
				function()
					require('menu.utils').delete_old_menus()
					vim.cmd.exec '"normal! \\<RightMouse>"'

					-- Get clicked buffer and window
					local mousepos = vim.fn.getmousepos()
					local buf = vim.api.nvim_win_get_buf(mousepos.winid)
					local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

					require("menu").open(options, { mouse = true })
				end,
				mode = { "n", "v" },
				desc = "Open context menu"
			},
			{
				"<C-t>",
				function()
					require("menu").open("default")
				end,
				mode = "n",
				desc = "Open menu (keyboard)"
			}
		}
	}
}
