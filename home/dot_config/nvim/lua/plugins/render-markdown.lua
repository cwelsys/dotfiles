return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-mini/mini.nvim",
  }, -- if you use the mini.nvim suite
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
  config = function()
    require("render-markdown").setup({
      preset = "obsidian",
      file_types = { "markdown", "quarto" },
      anti_conceal = { enabled = true },
      win_options = {
        concealcursor = {
          rendered = "ci",
        },
      },
      heading = {
        render_modes = true,
        border_virtual = false,
      },
    })
  end,
}
