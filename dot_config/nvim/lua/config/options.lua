vim.opt.title = true
vim.opt.cmdheight = 0
vim.opt.backup = true
vim.opt.backupdir = vim.fn.stdpath("state") .. "/backup"

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

  -- Project root (git repository)
  local project_name = ""
  if bufname ~= "" then
    local root = vim.fs.root(bufname, ".git")
    if root then
      project_name = vim.fn.fnamemodify(root, ":t")
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
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }

  -- web URL over SSH
  local original_open = vim.ui.open
  vim.ui.open = function(path, opts)
    local browser = os.getenv("BROWSER")
    if browser then
      return vim.system({ browser, path }, { text = true, detach = true })
    end
    return original_open(path, opts)
  end
end

vim.opt.mousescroll = "ver:3,hor:1"
