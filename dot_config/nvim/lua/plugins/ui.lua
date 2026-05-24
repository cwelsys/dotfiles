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
          icon = "",
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
        function(dashboard)
          local root = Snacks.git.get_root()
          if not root then
            return nil
          end
          local out = vim.fn.systemlist({ "git", "-C", root, "status", "--short", "--branch", "--renames" })
          if vim.tbl_isempty(out) then
            return nil
          end

          local indent = 3
          local maxw = (dashboard and dashboard.opts and dashboard.opts.width or 60) - indent

          local function branch_segs(line)
            local body = line:gsub("^## ", "")
            if body:match("^No commits yet") then
              return { { body, hl = "Title" } }
            end
            local name, upstream = body:match("^(.-)%.%.%.(%S+)")
            local rest
            if name then
              rest = body:match("%.%.%.%S+%s*(.*)$") or ""
            else
              name, rest = body:match("^(%S+)%s*(.*)$")
            end
            local segs = { { name or body, hl = "Title" } }
            local ahead = rest and rest:match("ahead (%d+)")
            local behind = rest and rest:match("behind (%d+)")
            if ahead then
              segs[#segs + 1] = { " ↑" .. ahead, hl = "Added" }
            end
            if behind then
              segs[#segs + 1] = { " ↓" .. behind, hl = "Changed" }
            end
            if rest and rest:match("gone") then
              segs[#segs + 1] = { " (upstream gone)", hl = "Removed" }
            end
            -- show the upstream ref only when its short name differs from the local branch
            if upstream and upstream:match("[^/]+$") ~= name then
              segs[#segs + 1] = { "  (" .. upstream .. ")", hl = "NonText" }
            end
            return segs
          end

          local function file_segs(line)
            local x, y = line:sub(1, 1), line:sub(2, 2)
            local field = (line:sub(1, 2):gsub("^%s+", "") .. "  "):sub(1, 2)
            local hl = (x == "?" or x == "!" or y ~= " ") and "Removed" or "Added"
            return {
              { field, hl = hl },
              { line:sub(3), hl = "SnacksDashboardFile" },
            }
          end

          -- shorten a line's segments to fit maxw, trimming the final (path) segment from the left
          -- with a leading ellipsis so the filename tail stays visible
          local function fit(segs)
            local total = 0
            for _, s in ipairs(segs) do
              total = total + vim.api.nvim_strwidth(s[1])
            end
            local over = total - maxw
            if over <= 0 then
              return
            end
            local last = segs[#segs]
            local cut = math.min(over + 1, vim.fn.strchars(last[1]) - 1)
            last[1] = "…" .. vim.fn.strcharpart(last[1], cut)
          end

          local height = dashboard and dashboard._size and dashboard._size.height or 40
          local reserve = 38
          local budget = math.max(height - reserve, 6)
          local rows = { branch_segs(out[1]) }
          local nfiles = #out - 1
          local shown = nfiles > budget and budget - 1 or nfiles
          for i = 2, 1 + shown do
            rows[#rows + 1] = file_segs(out[i])
          end
          if nfiles > shown then
            rows[#rows + 1] = { { "… " .. (nfiles - shown) .. " more", hl = "NonText" } }
          end

          local text = {}
          for i, segs in ipairs(rows) do
            fit(segs)
            if i < #rows then
              segs[#segs][1] = segs[#segs][1] .. "\n"
            end
            for _, s in ipairs(segs) do
              text[#text + 1] = s
            end
          end
          return { indent = indent, padding = 1, text = text }
        end,
        { section = "startup" },
      }

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
  {
    "nvim-mini/mini.animate",
    optional = true,
    opts = function(_, opts)
      opts.cursor = opts.cursor or {}
      opts.cursor.enable = false
    end,
  },
}
