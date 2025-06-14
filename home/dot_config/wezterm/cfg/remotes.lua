local wez = require('wezterm')
local platform = require('utils.platform')
local M = {}

-- Domain configuration
if platform.is_win then
   M.ssh_domains = {
      {
         name = 'pbox',
         remote_address = 'pbox',
         multiplexing = 'None',
         assume_shell = "Posix"
      },
      {
         name = 'mba',
         remote_address = 'mba',
         multiplexing = 'None',
         assume_shell = "Posix"
      },
   }
elseif platform.is_mac then
   M.ssh_domains = {
      {
         name = 'pbox',
         remote_address = 'pbox',
         multiplexing = 'None',
         assume_shell = "Posix"
      },
      {
         name = 'wini',
         remote_address = 'wini',
         multiplexing = 'None'
      }
   }
elseif platform.is_linux then
   M.ssh_domains = {
      {
         name = 'mba',
         remote_address = 'mba',
         multiplexing = 'None',
         assume_shell = "Posix"
      },
      {
         name = 'wini',
         remote_address = 'wini',
         multiplexing = 'None'
      }
   }
end
-- M.ssh_domains = wez.default_ssh_domains()

M.unix_domains = {}

M.wsl_domains = {
   {
      name = 'WSL:Fedora',
      distribution = 'FedoraLinux-42',
      username = 'cwel',
      default_cwd = '~',
   },
   {
      name = 'WSL:Arch',
      distribution = 'archlinux',
      username = 'cwel',
      default_cwd = '~',
   }
}

M.apply_to_config = function(c)
   c.ssh_domains = M.ssh_domains
   c.unix_domains = M.unix_domains
   if platform.is_win then
   c.wsl_domains = M.wsl_domains
   else
   c.wsl_domains = {}
   end
end

return M
