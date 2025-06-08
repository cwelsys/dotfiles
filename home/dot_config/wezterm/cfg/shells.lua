local platform = require('utils.platform')

local M = {}

-- Create the launch menu based on platform
local create_launch_menu = function()
   if platform.is_win then
      return {
         { label = 'Powershell', args = { 'pwsh', '-NoLogo' } },
         -- { label = 'PowerShell Desktop', args = { 'powershell' } },
         { label = 'Command Prompt', args = { 'cmd' } },
         { label = 'Nushell', args = { 'nu' } },
         { label = 'Msys2', args = { 'ucrt64.cmd' } },
         {
            label = 'Git Bash',
            args = { 'C:\\Users\\cwel\\scoop\\apps\\git\\current\\bin\\bash.exe' },
         },
      }
   elseif platform.is_mac then
      return {
         { label = 'Bash', args = { 'bash', '-l' } },
         { label = 'Fish', args = { '/opt/homebrew/bin/fish', '-l' } },
         { label = 'Nushell', args = { '/opt/homebrew/bin/nu', '-l' } },
         { label = 'Zsh', args = { 'zsh', '-l' } },
      }
   elseif platform.is_linux then
      return {
         { label = 'Bash', args = { 'bash', '-l' } },
         { label = 'Fish', args = { 'fish', '-l' } },
         { label = 'Zsh', args = { 'zsh', '-l' } },
      }
   end
   return {}
end

M.launch_menu = create_launch_menu()

M.apply_to_config = function(c)
   if platform.is_win then
      c.default_prog = { 'pwsh', '-NoLogo' }
   elseif platform.is_mac then
      c.default_prog = { 'zsh', '-l' }
   elseif platform.is_linux then
      c.default_prog = { 'zsh', '-l' }
   end

   c.launch_menu = M.launch_menu
end

return M
