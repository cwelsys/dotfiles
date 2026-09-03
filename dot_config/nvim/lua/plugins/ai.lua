return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      server = { type = "binary" },
      server_opts_overrides = {
        settings = { internal = { auth = { tokenEncryption = "false" } } },
      },
    },
  },
  {
    "folke/sidekick.nvim",
    keys = {
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Sidekick Toggle Claude",
      },
    },
  },
}
