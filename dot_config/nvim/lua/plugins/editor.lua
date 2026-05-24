local function git_file_history()
  Snacks.picker.git_log_file({
    confirm = function(picker, item)
      picker:close()
      if not (item and item.commit and item.file) then
        return
      end
      local git_root = vim.fn.system({ "git", "rev-parse", "--show-toplevel" }):gsub("\n", "")
      local rel_path = item.file:gsub("^" .. vim.pesc(git_root) .. "/", "")
      local content = vim.fn.systemlist({ "git", "show", item.commit .. ":" .. rel_path })
      vim.cmd("enew")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
      vim.bo.buftype = "nofile"
      vim.bo.modifiable = false
      vim.api.nvim_buf_set_name(0, item.file .. "@" .. item.commit:sub(1, 7))
      -- Resolve chezmoi naming (dot_bashrc → .bashrc, foo.toml.tmpl → foo.toml)
      local resolved = vim.fn.fnamemodify(item.file, ":t")
      resolved = resolved:gsub("%.tmpl$", "")
      resolved = resolved:gsub("^dot_", ".")
      resolved = resolved:gsub("^private_", "")
      resolved = resolved:gsub("^executable_", "")
      local ft = vim.filetype.match({ filename = resolved, buf = 0 })
      if ft then
        vim.bo.filetype = ft
      end
    end,
  })
end

vim.api.nvim_create_user_command("GitFileHistory", git_file_history, {})

return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewFileHistory", "DiffviewOpen" },
    keys = {
      { "<leader>gf", git_file_history, desc = "Git file history" },
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git diff view" },
    },
  },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    build = "./kitty/install-kittens.bash",
    keys = {
      -- Navigation
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to below split" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to above split" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
      -- Resizing
      { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize left" },
      { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize down" },
      { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize up" },
      { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize right" },
      -- Swapping
      { "<leader><leader>h", function() require("smart-splits").swap_buf_left() end, desc = "Swap buffer left" },
      { "<leader><leader>j", function() require("smart-splits").swap_buf_down() end, desc = "Swap buffer down" },
      { "<leader><leader>k", function() require("smart-splits").swap_buf_up() end, desc = "Swap buffer up" },
      { "<leader><leader>l", function() require("smart-splits").swap_buf_right() end, desc = "Swap buffer right" },
    },
  },
}
