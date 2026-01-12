-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.title = true

local function update_title()
  local buftype = vim.bo.buftype
  local bufname = vim.api.nvim_buf_get_name(0)

  -- Only update for real file buffers
  if buftype ~= "" and buftype ~= "acwrite" then
    return
  end

  -- Skip buffers with special names (like filetype-match-scratch)
  if bufname ~= "" and (bufname:match("filetype%-") or bufname:match("^[^/]*%-scratch")) then
    return
  end

  local filename = ""
  if bufname ~= "" then
    filename = vim.fn.fnamemodify(bufname, ":t")
  else
    filename = "nvim"
  end

  -- Try to find project root (git repository)
  local project_name = ""
  if bufname ~= "" then
    local file_dir = vim.fn.fnamemodify(bufname, ":p:h")
    -- Use git rev-parse to get the root directory (more reliable)
    local git_root_output =
      vim.fn.systemlist("cd " .. vim.fn.shellescape(file_dir) .. " && git rev-parse --show-toplevel 2>/dev/null")
    if git_root_output and #git_root_output > 0 and git_root_output[1] ~= "" then
      local root_dir = git_root_output[1]
      project_name = vim.fn.fnamemodify(root_dir, ":t")
    end
  end

  -- Build title: project name + filename, or just filename
  local title = filename
  if project_name ~= "" then
    title = project_name .. " - " .. filename
  end

  if filename ~= "" then
    vim.opt.titlestring = title
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "BufWritePost" }, {
  pattern = "*",
  callback = update_title,
})

vim.opt.clipboard = "unnamedplus"

if os.getenv("SSH_TTY") then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
  }
end

vim.opt.mousescroll = "ver:3,hor:1"
