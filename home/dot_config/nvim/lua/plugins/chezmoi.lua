return {
  {
    "alker0/chezmoi.vim",
    init = function()
      vim.g["chezmoi#use_tmp_buffer"] = true
    end,
  },
  {
    "xvzc/chezmoi.nvim",
    dependencies = { "alker0/chezmoi.vim" },
    opts = {
      edit = {
        watch = true,
      },
      notification = {
        on_watch = true,
      },
    },
    keys = {
      { "<leader>cz", "<cmd>ChezmoiList<cr>", desc = "Chezmoi managed files" },
    },
    cmd = { "ChezmoiEdit", "ChezmoiList" },
  },
}
