return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- taplo defaults explode arrays past column_width and strip bracket padding
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
