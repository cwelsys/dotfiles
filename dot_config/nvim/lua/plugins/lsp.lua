return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        copilot = { enabled = false },
        taplo = {
          settings = {
            evenBetterToml = {
              formatter = {
                arrayAutoExpand = false,
                arrayAutoCollapse = false,
                compactArrays = false,
                alignEntries = true,
              },
            },
          },
        },
      },
    },
  },
}
