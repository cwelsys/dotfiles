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
  },
  {
    "Wansmer/treesj",
    keys = { { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" } },
    opts = { use_default_keymaps = false, max_join_length = 150 },
  },
  {
    "nvim-mini/mini.align",
    opts = {},
    keys = { { "ga", mode = { "n", "v" } }, { "gA", mode = { "n", "v" } } },
  },
}
