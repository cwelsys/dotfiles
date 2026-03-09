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
  "sindrets/diffview.nvim",
  cmd = { "DiffviewFileHistory", "DiffviewOpen" },
  keys = {
    { "<leader>gf", git_file_history, desc = "Git file history" },
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git diff view" },
  },
}
