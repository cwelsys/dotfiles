return {
  {
    "MaximilianLloyd/ascii.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
  },

  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local ascii = require("ascii")

      opts.dashboard = opts.dashboard or {}
      opts.dashboard.preset = opts.dashboard.preset or {}
      opts.dashboard.preset.header = table.concat(ascii.art.text.neovim.sharp, "\n")
      opts.dashboard.sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          {
            pane = 2,
            icon = " ",
            desc = "Browse Repo",
            padding = 1,
            key = "b",
            enabled = function()
              return Snacks.git.get_root() ~= nil
            end,
            action = function()
              Snacks.gitbrowse()
            end,
          },
          {
            pane = 2,
            icon = " ",
            title = "Git Status",
            section = "terminal",
            enabled = function()
              return Snacks.git.get_root() ~= nil
            end,
            cmd = "git status --short --branch --renames",
            height = 10,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
          { section = "startup" },
      }

      return opts
    end,
  },
}
