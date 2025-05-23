return {
  "nvim-neo-tree/neo-tree.nvim",
  enabled = false,
  dependencies = {
    {
      'ten3roberts/window-picker.nvim',
      name = 'window-picker',
      config = function()
        local picker = require('window-picker')
        picker.setup()
        picker.pick_window = function()
          return picker.select(
            { hl = 'WindowPicker', prompt = 'Pick window: ' },
            function(winid) return winid or nil end
          )
        end
      end,
    },
  },
  opts = {
    enable_git_status = true,
    git_status_async = true,
    close_if_last_window = true,
    window = {
      mappings = {
        ["e"] = "open",
        ["E"] = function()
          vim.api.nvim_exec("Neotree focus filesystem left", true)
        end,
        ["b"] = function()
          vim.api.nvim_exec("Neotree focus buffers left", true)
        end,
        ["g"] = function()
          vim.api.nvim_exec("Neotree focus git_status left", true)
        end,
        ["<c-/>"] = "fuzzy_finder_directory",
        ["D"] = function(state)
          local node = state.tree:get_node()
          local log = require("neo-tree.log")
          state.clipboard = state.clipboard or {}
          if diff_Node and diff_Node ~= tostring(node.id) then
            local current_Diff = node.id
            require("neo-tree.utils").open_file(state, diff_Node, open)
            vim.cmd("vert diffs " .. current_Diff)
            log.info("Diffing " .. diff_Name .. " against " .. node.name)
            diff_Node = nil
            current_Diff = nil
            state.clipboard = {}
            require("neo-tree.ui.renderer").redraw(state)
          else
            local existing = state.clipboard[node.id]
            if existing and existing.action == "diff" then
              state.clipboard[node.id] = nil
              diff_Node = nil
              require("neo-tree.ui.renderer").redraw(state)
            else
              state.clipboard[node.id] = { action = "diff", node = node }
              diff_Name = state.clipboard[node.id].node.name
              diff_Node = tostring(state.clipboard[node.id].node.id)
              log.info("Diff source file " .. diff_Name)
              require("neo-tree.ui.renderer").redraw(state)
            end
          end
        end,
      },
    },
    filesystem = {
      hijack_netrw_behavior = "open_default",
      use_libuv_file_watcher = true,
      follow_current_file = { enabled = true, leave_dirs_open = true },
      group_empty_dirs = false,
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
        never_show = { '.DS_Store' },
      }
    },
  },
}
