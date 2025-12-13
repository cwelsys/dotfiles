local disabled = {
  { "akinsho/bufferline.nvim" },
  { "nvim-neo-tree/neo-tree.nvim" },
  { "mfussenegger/nvim-dap-python" },
}

for i, plugin in ipairs(disabled) do
  plugin.enabled = false
end

return disabled
