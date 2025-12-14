-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local ac = vim.api.nvim_create_autocmd
local ag = vim.api.nvim_create_augroup

-- Terminal cleanup (no numbers, no spell)
ac("TermOpen", {
  group = ag("custom_term_settings", { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.spell = false
    vim.opt_local.listchars = ""
  end,
})

-- Disable automatic comment continuation on new lines
ac("BufEnter", {
  group = ag("custom_formatoptions", { clear = true }),
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- Smart relative/absolute line number toggle
local numbertoggle = ag("custom_numbertoggle", { clear = true })

ac({ "BufEnter", "FocusGained", "InsertLeave", "CmdlineLeave", "WinEnter" }, {
  group = numbertoggle,
  callback = function()
    if vim.o.number and vim.api.nvim_get_mode().mode ~= "i" then
      vim.opt.relativenumber = true
    end
  end,
})

ac({ "BufLeave", "FocusLost", "InsertEnter", "CmdlineEnter", "WinLeave" }, {
  group = numbertoggle,
  callback = function()
    if vim.o.number then
      vim.opt.relativenumber = false
    end
  end,
})
