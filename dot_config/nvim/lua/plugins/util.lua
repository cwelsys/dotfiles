return {
  {
    "alker0/chezmoi.vim",
    init = function()
      vim.g["chezmoi#source_dir_path"] = vim.env.HOME .. "/.local/share/dots"
      vim.g["chezmoi#use_tmp_buffer"] = 1
    end,
  },
  {
    "xvzc/chezmoi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      events = {
        on_open = { notification = { enable = false } },
        on_watch = { notification = { enable = false } },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { vim.env.HOME .. "/.local/share/dots/*" },
        callback = function(ev)
          local name = vim.fn.fnamemodify(ev.file, ":t")
          local ignored = require("chezmoi").config.edit.ignore_patterns
          if require("chezmoi.util").str_matches_any_of(name, ignored) then
            return
          end
          vim.schedule(function()
            require("chezmoi.commands.__edit").watch(ev.buf)
          end)
        end,
      })
    end,
  },
  {
    "willothy/flatten.nvim",
    lazy = false,
    priority = 1001,
    opts = {
      window = {
        open = "alternate",
      },
    },
  },
}
