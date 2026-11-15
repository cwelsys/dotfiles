local M = {}

local function quote(s)
    local escaped = s:gsub("\\", "\\\\"):gsub('"', '\\"')
    return '"' .. escaped .. '"'
end

local function matches(self, song)
    if song == nil or song.file == nil then
        return false
    end
    for _, prefix in ipairs(self.prefixes) do
        if song.file:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function remote(self, commands, done)
    if not self.remote_socket then
        done(nil, "disabled")
        return
    end

    local chunks = {}
    local finished = false
    local sock = nil
    local timer = nil

    local function finish(err, from_close)
        if finished then
            return
        end
        finished = true
        if timer ~= nil then
            timer.cancel()
        end
        if sock ~= nil and not from_close then
            sock:close()
        end
        local data = table.concat(chunks)
        if err == nil and data:sub(1, 7) ~= "OK MPD " then
            err = "no response"
        end
        if err ~= nil then
            done(nil, err)
        else
            done(data, nil)
        end
    end

    local s, cerr = socket.connect_unix(self.remote_socket, {
        on_data = function(data)
            chunks[#chunks + 1] = data
        end,
        on_close = function(_reason)
            finish(nil, true)
        end,
        write_timeout_ms = self.remote_timeout_ms,
    })
    if s == nil then
        finish(cerr or "connect failed", true)
        return
    end
    sock = s

    timer = sync.set_timeout(self.remote_timeout_ms, function()
        finish("timeout", false)
    end)

    local ok, werr = sock:write(table.concat(commands, "\n") .. "\nclose\n")
    if not ok then
        finish(werr or "write failed", false)
    end
end

local function remote_get(self, file, done)
    remote(self, { "sticker list song " .. quote(file) }, function(data, err)
        if data == nil then
            done(nil, err)
            return
        end
        local values = {}
        for name, value in data:gmatch("sticker: ([^=\n]+)=([^\n]*)") do
            values[name] = value
        end
        done(values, nil)
    end)
end

local function save_pending(self)
    if self.pending_path == nil then
        return
    end
    local encoded = util.json_encode(self.pending)
    if encoded ~= nil then
        fs.write_str(self.pending_path, encoded)
    end
end

local function load_pending(self)
    self.pending = {}
    if self.pending_path == nil or not fs.exists(self.pending_path) then
        return
    end
    local text = fs.read_str(self.pending_path)
    if text == nil or text == "" then
        return
    end
    local decoded = util.json_decode(text)
    if type(decoded) == "table" then
        for file, rec in pairs(decoded) do
            if type(file) == "string" and type(rec) == "table" then
                self.pending[file] = rec
            end
        end
    end
end

local drain

local function push(self, file, rec, done)
    local cmds = {
        "command_list_begin",
        "sticker set song " .. quote(file) .. " elapsed " .. rec.elapsed,
        "sticker set song " .. quote(file) .. " elapsedAt " .. rec.at,
    }
    if rec.finished_at ~= nil then
        cmds[#cmds + 1] = "sticker set song " .. quote(file) .. " finishedAt " .. rec.finished_at
    end
    cmds[#cmds + 1] = "command_list_end"

    remote(self, cmds, function(data, err)
        if data ~= nil and data:find("\nACK ", 1, true) then
            err = data:match("\n(ACK [^\n]*)")
        end
        if err ~= nil then
            local existing = self.pending[file]
            if existing == nil or existing.at <= rec.at then
                self.pending[file] = rec
                save_pending(self)
            end
            if not self.remote_down then
                self.remote_down = true
                log.warn("resume: pbox unavailable (" .. tostring(err) .. "), queueing writes")
            end
        else
            if self.remote_down then
                self.remote_down = false
                log.info("resume: pbox reachable again")
            end
            local existing = self.pending[file]
            if existing ~= nil and existing.at <= rec.at then
                self.pending[file] = nil
                save_pending(self)
            end
            drain(self)
        end
        if done ~= nil then
            done(err)
        end
    end)
end

drain = function(self)
    if self.draining then
        return
    end
    local file, rec = next(self.pending)
    if file == nil then
        return
    end
    self.draining = true

    remote_get(self, file, function(values, err)
        if values == nil then
            self.draining = false
            if not self.remote_down then
                self.remote_down = true
                log.warn("resume: pbox unavailable (" .. tostring(err) .. "), keeping queued writes")
            end
            return
        end
        local remote_at = tonumber(values.elapsedAt or "")
        if remote_at ~= nil and remote_at > rec.at then
            self.pending[file] = nil
            save_pending(self)
            self.draining = false
            drain(self)
            return
        end
        push(self, file, rec, function(perr)
            self.draining = false
            if perr == nil then
                log.info("resume: synced queued " .. file)
                drain(self)
            end
        end)
    end)
end

local function record(self, file, elapsed_s, finished_at)
    local rec = { elapsed = elapsed_s, at = os.time(), finished_at = finished_at }
    mpd.set_song_sticker(file, "elapsed", tostring(rec.elapsed))
    mpd.set_song_sticker(file, "elapsedAt", tostring(rec.at))
    if finished_at ~= nil then
        mpd.set_song_sticker(file, "finishedAt", tostring(finished_at))
    end
    push(self, file, rec)
end

local function flush(self)
    local t = self.track
    if t == nil or t.elapsed == nil then
        return
    end

    if t.duration ~= nil and t.duration > 0 and t.elapsed >= t.duration - self.finished_within_ms then
        t.saved = t.elapsed
        if t.finished then
            return
        end
        t.finished = true
        record(self, t.file, 0, os.time())
        log.info("resume: finished " .. t.file)
        return
    end

    record(self, t.file, math.floor(t.elapsed / 1000), nil)
    t.saved = t.elapsed
end

local function seek_to(self, file, elapsed_s)
    local t = self.track
    if t == nil or t.file ~= file or elapsed_s == nil then
        return
    end

    local status = mpd.get_status()
    if status == nil or status.state == "stop" then
        t.pending = true
        return
    end
    if status.elapsed > self.late_seek_ms then
        return
    end

    local target = math.floor(elapsed_s - self.rewind_ms / 1000)
    if target * 1000 < self.min_resume_ms then
        return
    end

    local ok, err = mpd.seek_current(tostring(target))
    if not ok then
        log.error("resume: seek failed for " .. file .. ": " .. tostring(err))
        return
    end
    t.elapsed = target * 1000
    t.saved = t.elapsed
    log.info("resume: " .. file .. " at " .. target .. "s")
end

local function try_resume(self)
    local t = self.track
    if t == nil or not t.pending then
        return
    end

    local status = mpd.get_status()
    if status == nil or status.state == "stop" then
        return
    end
    t.pending = false

    if status.elapsed > self.fresh_start_ms then
        return
    end

    local file = t.file
    local local_elapsed = tonumber(mpd.get_song_sticker(file, "elapsed") or "")
    local local_at = tonumber(mpd.get_song_sticker(file, "elapsedAt") or "") or 0

    remote_get(self, file, function(values, _err)
        local elapsed_s = local_elapsed
        if values ~= nil then
            local remote_at = tonumber(values.elapsedAt or "")
            local remote_elapsed = tonumber(values.elapsed or "")
            if remote_at ~= nil and remote_elapsed ~= nil and remote_at > local_at then
                elapsed_s = remote_elapsed
                mpd.set_song_sticker(file, "elapsed", tostring(remote_elapsed))
                mpd.set_song_sticker(file, "elapsedAt", tostring(remote_at))
                if values.finishedAt ~= nil then
                    mpd.set_song_sticker(file, "finishedAt", values.finishedAt)
                end
            end
        end
        seek_to(self, file, elapsed_s)
    end)
end

local function reconcile(self)
    local t = self.track
    if t == nil then
        return
    end

    local file = t.file
    local local_at = tonumber(mpd.get_song_sticker(file, "elapsedAt") or "") or 0

    remote_get(self, file, function(values, _err)
        if values == nil then
            return
        end
        local remote_at = tonumber(values.elapsedAt or "")
        local remote_elapsed = tonumber(values.elapsed or "")
        if remote_at == nil or remote_elapsed == nil or remote_at <= local_at then
            return
        end

        mpd.set_song_sticker(file, "elapsed", tostring(remote_elapsed))
        mpd.set_song_sticker(file, "elapsedAt", tostring(remote_at))
        if values.finishedAt ~= nil then
            mpd.set_song_sticker(file, "finishedAt", values.finishedAt)
        end

        local cur = self.track
        if cur == nil or cur.file ~= file or remote_elapsed == 0 then
            return
        end

        local status = mpd.get_status()
        if status == nil or status.state == "stop" or status.elapsed == nil then
            return
        end

        local target = math.floor(remote_elapsed - self.rewind_ms / 1000)
        if target * 1000 < self.min_resume_ms then
            return
        end
        if math.abs(remote_elapsed * 1000 - status.elapsed) < self.min_jump_ms then
            return
        end

        local ok, err = mpd.seek_current(tostring(target))
        if not ok then
            log.error("resume: seek failed for " .. file .. ": " .. tostring(err))
            return
        end
        cur.elapsed = target * 1000
        cur.saved = cur.elapsed
        log.info("resume: " .. file .. " moved to " .. target .. "s (newer position on pbox)")
    end)
end

local function poll(self)
    local t = self.track
    if t == nil then
        return
    end

    local status = mpd.get_status()
    if status == nil or status.state ~= "play" then
        return
    end

    local song = mpd.get_current_song()
    if song == nil or song.file ~= t.file then
        return
    end

    t.elapsed = status.elapsed
    t.duration = status.duration

    if math.abs(t.elapsed - t.saved) >= self.save_every_ms then
        flush(self)
    end
end

local function arm(self)
    if self.timer ~= nil then
        return
    end
    self.timer = sync.set_interval(self.poll_ms, function()
        poll(self)
    end)
end

local function disarm(self)
    if self.timer == nil then
        return
    end
    self.timer.cancel()
    self.timer = nil
end

local function adopt(self, pending)
    local song = mpd.get_current_song()
    if not matches(self, song) then
        self.track = nil
        return
    end
    if self.track == nil or self.track.file ~= song.file then
        self.track = { file = song.file, elapsed = 0, saved = 0, duration = song.duration, pending = pending }
    end
end

local function arm_if_playing(self)
    local status = mpd.get_status()
    if self.track ~= nil and status ~= nil and status.state == "play" then
        arm(self)
    else
        disarm(self)
    end
end

M.setup = function(self, args)
    args = args or {}
    local home = os.getenv("HOME")
    self.prefixes = args.prefixes or { "podcast/" }
    self.rewind_ms = (args.rewind_s or 5) * 1000
    self.finished_within_ms = (args.finished_within_s or 300) * 1000
    self.save_every_ms = (args.save_every_s or 30) * 1000
    self.min_resume_ms = (args.min_resume_s or 30) * 1000
    self.poll_ms = (args.poll_s or 5) * 1000
    self.remote_timeout_ms = (args.remote_timeout_s or 5) * 1000
    self.min_jump_ms = (args.min_jump_s or 10) * 1000
    self.fresh_start_ms = 3000
    self.late_seek_ms = self.fresh_start_ms + self.remote_timeout_ms + 2000

    if args.remote_socket == false then
        self.remote_socket = nil
    elseif args.remote_socket ~= nil then
        self.remote_socket = args.remote_socket
    elseif home ~= nil then
        self.remote_socket = home .. "/.local/state/mpd-pbox.sock"
    end

    if args.pending_path ~= nil then
        self.pending_path = args.pending_path
    elseif home ~= nil then
        self.pending_path = home .. "/.local/state/rmpcd/resume-pending.json"
    end
    if self.pending_path ~= nil then
        fs.create_dir_all(self.pending_path:match("^(.*)/[^/]*$"))
    end
    load_pending(self)
end

M.start = function(self)
    if self.prefixes == nil then
        self:setup({})
    end

    local status = mpd.get_status()
    if status ~= nil then
        adopt(self, status.state == "stop")
        if self.track ~= nil and status.state ~= "stop" then
            self.track.elapsed = status.elapsed
            self.track.saved = status.elapsed
            self.track.duration = status.duration
            reconcile(self)
        end
        arm_if_playing(self)
    end

    drain(self)
end

M.song_change = function(self, old, new)
    if matches(self, old) and self.track ~= nil and self.track.file == old.file then
        flush(self)
    end
    self.track = nil

    if matches(self, new) then
        self.track = { file = new.file, elapsed = 0, saved = 0, duration = new.duration, pending = true }
        try_resume(self)
    end
    arm_if_playing(self)
end

M.state_change = function(self, _old, new)
    if new == "play" then
        if self.track == nil then
            adopt(self, true)
        end
        if self.track ~= nil and self.track.pending then
            try_resume(self)
        elseif self.track ~= nil and _old == "pause" then
            reconcile(self)
        end
        arm_if_playing(self)
        return
    end

    disarm(self)
    if self.track == nil then
        return
    end

    if new == "pause" then
        local status = mpd.get_status()
        if status ~= nil and status.state == "pause" and status.elapsed ~= nil then
            self.track.elapsed = status.elapsed
            self.track.duration = status.duration
        end
        flush(self)
    elseif new == "stop" then
        flush(self)
        self.track.pending = true
    end
end

M.shutdown = function(self)
    disarm(self)
    flush(self)
end

return M
