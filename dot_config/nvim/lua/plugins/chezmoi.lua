return {
  {
    "alker0/chezmoi.vim",
    lazy = false,
    init = function()
      vim.g["chezmoi#use_tmp_buffer"] = true
      vim.g["chezmoi#use_external"] = 1
    end,
  },
  {
    "xvzc/chezmoi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("chezmoi").setup({
        edit = {
          watch = false,
          force = false,
        },
        events = {
          on_open = {
            notification = {
              enable = false,
              opts = {},
            },
          },
          on_watch = {
            enable = true,
            msg = "This file will be automatically applied",
            opts = {},
          },
          on_apply = {
            notification = {
              enable = true,
              msg = "Successfully applied",
            },
          },
        },
      })
    end,
    keys = {
      {
        "<leader>cz",
        function()
          require("chezmoi.pick").snacks()
        end,
        desc = "Chezmoi managed files",
      },
    },
    init = function()
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { os.getenv("HOME") .. "/.local/share/dots/*" },
        callback = function(ev)
          local bufnr = ev.buf
          vim.schedule(function()
            require("chezmoi.commands.__edit").watch(bufnr)
          end)
        end,
      })
    end,
  },
}
