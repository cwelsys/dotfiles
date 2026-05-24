return {
  { "LazyVim/LazyVim", version = false, opts = { colorscheme = "catppuccin-mocha" } },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      term_colors = true,
      float = {
        transparent = true,
        solid = false,
      },
      auto_integrations = true,
      custom_highlights = function(colors)
        local hl = {
          WinSeparator = { fg = colors.flamingo },
          ["@markup.strong"] = { fg = colors.teal, style = { "bold" } },
          ["@markup.italic"] = { fg = colors.teal, style = { "italic" } },
          ["@markup.quote"] = { fg = colors.mauve, style = { "italic" } },
          -- ["@markup.raw"]    = { fg = colors.flamingo },
        }
        local heading = { colors.blue, colors.peach, colors.green, colors.teal, colors.mauve, colors.pink }
        for i, fg in ipairs(heading) do
          hl["RenderMarkdownH" .. i] = { fg = fg, style = { "bold" } }
          hl["@markup.heading." .. i .. ".markdown"] = { fg = fg, style = { "bold" } }
        end
        return hl
      end,
    },
  },
  {
    "MaximilianLloyd/ascii.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
  },
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local ascii = require("ascii")

      opts.image = opts.image or {}
      opts.image.enabled = true
      opts.image.doc = vim.tbl_extend("force", opts.image.doc or {}, {
        max_width = 60,
        max_height = 20,
        conceal = true,
      })

      opts.dashboard = opts.dashboard or {}
      opts.dashboard.preset = opts.dashboard.preset or {}
      opts.dashboard.preset.header = table.concat(ascii.art.text.neovim.sharp, "\n")
      opts.dashboard.sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        {
          icon = " ",
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
          icon = " ",
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

      -- projects picker: snacks doesn't read $XDG_PROJECTS_DIR, so point its
      -- `dev` scan dir at it (falls back to ~/src if unset).
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.projects = vim.tbl_deep_extend("force", opts.picker.sources.projects or {}, {
        dev = { vim.env.XDG_PROJECTS_DIR or "~/src" },
      })

      return opts
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      -- dedupe dualing copilot glyphs
      local x = opts.sections.lualine_x
      for i = #x, 1, -1 do
        local render = type(x[i]) == "table" and x[i][1]
        if type(render) == "function" and debug.getinfo(render, "S").source:match("util/lualine%.lua$") then
          table.remove(x, i)
        end
      end
      -- chezmoi source-dir indicator.
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return ""
        end,
        cond = function()
          local file = vim.api.nvim_buf_get_name(0)
          local src = vim.g["chezmoi#source_dir_path"]
          return file ~= "" and src and file:find(src, 1, true) == 1
        end,
      })
    end,
  },
}
