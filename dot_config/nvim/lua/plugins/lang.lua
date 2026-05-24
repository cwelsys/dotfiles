return {
  { "fladson/vim-kitty", ft = "kitty" },
  { "ron-rs/ron.vim" },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    config = function()
      require("render-markdown").setup({
        preset = "obsidian",
        file_types = { "markdown", "quarto" },
        anti_conceal = { disabled_modes = { "n", "v", "c" } },
        win_options = {
          concealcursor = {
            rendered = "nvc",
          },
        },
        heading = {
          render_modes = true,
          border_virtual = false,
          backgrounds = {},
        },
      })
    end,
  },
  {
    "xixiaofinland/sf.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "ibhagwan/fzf-lua", -- no need if you don't use listing metadata feature
    },
    config = function()
      require("sf").setup() -- Important to call setup() to initialize the plugin!
    end,
  },
}
