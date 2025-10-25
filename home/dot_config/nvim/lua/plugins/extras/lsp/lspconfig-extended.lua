local nvim_0_10 = vim.fn.has("nvim-0.10")
local prefix = "<leader>cl"

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
      },
      inlay_hints = {
        enabled = nvim_0_10,
      },
      codelens = {
        enabled = false,
      },
      servers = {
        ["*"] = {
          keys = {
            { prefix, false },
            { "<leader>cil", "<cmd>LspInfo<cr>", desc = "Lsp" },
            { prefix .. "r", "<cmd>LspRestart<cr>", desc = "Restart Lsp" },
            { prefix .. "s", "<cmd>LspStart<cr>", desc = "Start Lsp" },
            { prefix .. "S", "<cmd>LspStop<cr>", desc = "Stop Lsp" },
            { "E", vim.diagnostic.open_float, desc = "Line Diagnostics" },
            { prefix .. "W", function() vim.lsp.buf.remove_workspace_folder() end, desc = "Remove workspace" },
            { prefix .. "w", function() vim.lsp.buf.add_workspace_folder() end, desc = "Add workspace" },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              hint = {
                enable = nvim_0_10,
                setType = nvim_0_10,
              },
            },
          },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>cl", group = "lsp", icon = " " },
      },
    },
  },
}
