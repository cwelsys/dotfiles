return {
  { "LazyVim/LazyVim", version = false, opts = { colorscheme = "catppuccin-mocha" } },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      float = {
        transparent = true,
      },
      auto_integrations = true,
      default_integrations = true,
      custom_highlights = function(colors)
        return {
          WinSeparator = { fg = colors.flamingo },
        }
      end,
    },
  },
}
