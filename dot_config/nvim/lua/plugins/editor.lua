local function git_root_of(path)
  local root = vim.fn.systemlist({ "git", "-C", vim.fn.fnamemodify(path, ":h"), "rev-parse", "--show-toplevel" })
  return vim.v.shell_error == 0 and root[1] or nil
end

local function git_file_history()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No file in the current buffer", vim.log.levels.WARN)
    return
  end
  if not git_root_of(file) then
    vim.notify("Not a git repository: " .. vim.fn.fnamemodify(file, ":h"), vim.log.levels.WARN)
    return
  end

  Snacks.picker.git_log_file({
    confirm = function(picker, item)
      picker:close()
      if not (item and item.commit and item.file) then
        return
      end
      local root = item.cwd or git_root_of(item.file)
      local short = item.commit:sub(1, 7)
      local path
      for _, candidate in ipairs(item.files or { item.file }) do
        candidate = candidate:gsub("^" .. vim.pesc(root) .. "/", "")
        vim.fn.system({ "git", "-C", root, "cat-file", "-e", item.commit .. ":" .. candidate })
        if vim.v.shell_error == 0 then
          path = candidate
          break
        end
      end
      if not path then
        vim.notify(("%s does not exist in %s"):format(vim.fn.fnamemodify(item.file, ":t"), short), vim.log.levels.ERROR)
        return
      end

      local content = vim.fn.systemlist({ "git", "-C", root, "show", item.commit .. ":" .. path })
      if vim.v.shell_error ~= 0 then
        vim.notify(table.concat(content, "\n"), vim.log.levels.ERROR)
        return
      end

      vim.cmd("enew")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
      vim.bo.buftype = "nofile"
      vim.bo.modifiable = false
      pcall(vim.api.nvim_buf_set_name, 0, path .. "@" .. short)
      local resolved = vim.fn.fnamemodify(path, ":t")
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
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "Move to left split",
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "Move to below split",
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "Move to above split",
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "Move to right split",
      },
      -- Resizing
      {
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
        desc = "Resize left",
      },
      {
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
        desc = "Resize down",
      },
      {
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
        desc = "Resize up",
      },
      {
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
        desc = "Resize right",
      },
      -- Swapping
      {
        "<leader><leader>h",
        function()
          require("smart-splits").swap_buf_left()
        end,
        desc = "Swap buffer left",
      },
      {
        "<leader><leader>j",
        function()
          require("smart-splits").swap_buf_down()
        end,
        desc = "Swap buffer down",
      },
      {
        "<leader><leader>k",
        function()
          require("smart-splits").swap_buf_up()
        end,
        desc = "Swap buffer up",
      },
      {
        "<leader><leader>l",
        function()
          require("smart-splits").swap_buf_right()
        end,
        desc = "Swap buffer right",
      },
    },
  },
}
