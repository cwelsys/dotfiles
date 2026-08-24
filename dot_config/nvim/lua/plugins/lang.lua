return {
  { "fladson/vim-kitty", ft = "kitty" },
  { "ron-rs/ron.vim", ft = "ron" },
  {
    "MeanderingProgrammer/render-markdown.nvim",
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
    cmd = "SF",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "ibhagwan/fzf-lua", -- no need if you don't use listing metadata feature
    },
    config = function()
      require("sf").setup() -- Important to call setup() to initialize the plugin!
    end,
  },
}
