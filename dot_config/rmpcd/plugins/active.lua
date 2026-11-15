local M = {}

local function touch(self)
    if self.path == nil then
        return
    end
    local ok, err = fs.write_str(self.path, tostring(os.time()))
    if not ok then
        log.error("active: failed to write " .. self.path .. ": " .. tostring(err))
    end
end

M.setup = function(self, args)
    args = args or {}
    local home = os.getenv("HOME")
    local dir = args.dir
    if dir == nil and home ~= nil then
        dir = home .. "/.local/state/mpd-active"
    end
    if dir == nil or args.name == nil then
        log.error("active: needs a name and a writable dir")
        return
    end
    fs.create_dir_all(dir)
    self.path = dir .. "/" .. args.name
end

M.start = function(self)
    touch(self)
end

M.state_change = function(self, _old, _new)
    touch(self)
end

M.song_change = function(self, _old, _new)
    touch(self)
end

return M
