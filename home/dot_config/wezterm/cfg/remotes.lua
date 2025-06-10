local platform = require('utils.platform')
local M = {}

-- Domain configuration
M.ssh_domains = {
   {
      name = 'pbox',
      remote_address = 'pbox',
      multiplexing = 'None'
   },
   {
      name = 'mba',
      remote_address = 'mba',
      multiplexing = 'None'
   },
   {
      name = 'wini',
      remote_address = 'wini',
      multiplexing = 'None'
   }
}

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

return M
