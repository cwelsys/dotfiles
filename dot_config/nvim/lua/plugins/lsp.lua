return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        taplo = {
          flags = {
            exit_timeout = 50,
          },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        toml = { "taplo" },
      },
    },
  },
}
