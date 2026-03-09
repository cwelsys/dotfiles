-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Fix right-click context menu in insert mode
vim.keymap.set("v", "<RightMouse>", "<C-\\><C-g>gv<cmd>popup! PopUp<cr>", { noremap = true })
-- Other configurations...

-- Right-click fix
vim.keymap.set("v", "<RightMouse>", "<C-\\><C-g>gv<cmd>popup! PopUp<cr>", { noremap = true })
-- Define a simple context menu (optional)
vim.api.nvim_create_user_command("PopUp", function()
  vim.ui.select({ "Copy", "Paste", "Cut" }, { prompt = "Context Menu:" }, function(choice)
    if choice == "Copy" then
      vim.cmd("normal! y")
    end
    if choice == "Paste" then
      vim.cmd("normal! p")
    end
    if choice == "Cut" then
      vim.cmd("normal! d")
    end
  end)
end, {})
