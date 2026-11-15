local M = {}

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
        mpd.set_song_sticker(t.file, "resumeMs", "0")
        mpd.set_song_sticker(t.file, "finishedAt", tostring(os.time()))
        log.info("resume: finished " .. t.file)
    else
        mpd.set_song_sticker(t.file, "resumeMs", tostring(math.floor(t.elapsed)))
    end
    t.saved = t.elapsed
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

    local resume = tonumber(mpd.get_song_sticker(t.file, "resumeMs") or "")
    if resume == nil then
        return
    end

    local target = math.floor((resume - self.rewind_ms) / 1000)
    if target * 1000 < self.min_resume_ms then
        return
    end

    local ok, err = mpd.seek_current(tostring(target))
    if not ok then
        log.error("resume: seek failed for " .. t.file .. ": " .. tostring(err))
        return
    end
    t.elapsed = target * 1000
    t.saved = t.elapsed
    log.info("resume: " .. t.file .. " at " .. target .. "s")
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
    self.prefixes = args.prefixes or { "podcast/" }
    self.rewind_ms = (args.rewind_s or 5) * 1000
    self.finished_within_ms = (args.finished_within_s or 300) * 1000
    self.save_every_ms = (args.save_every_s or 30) * 1000
    self.min_resume_ms = (args.min_resume_s or 30) * 1000
    self.fresh_start_ms = 3000
    self.poll_ms = (args.poll_s or 5) * 1000
end

M.start = function(self)
    if self.prefixes == nil then
        self:setup({})
    end

    local status = mpd.get_status()
    if status == nil then
        return
    end

    adopt(self, status.state == "stop")
    if self.track ~= nil and status.state ~= "stop" then
        self.track.elapsed = status.elapsed
        self.track.saved = status.elapsed
        self.track.duration = status.duration
    end
    arm_if_playing(self)
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
        try_resume(self)
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
