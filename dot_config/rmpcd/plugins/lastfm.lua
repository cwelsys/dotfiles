---@type LastFmPlugin
---@diagnostic disable-next-line: missing-fields
local M = {}

---@return string|nil key_path
---@return string|nil key_dir
local function session_key_path()
    local data_dir = os.getenv("XDG_DATA_HOME")
    if data_dir == nil or data_dir == "" then
        local home = os.getenv("HOME")
        if home == nil then
            return nil, nil
        end
        data_dir = home .. "/.local/share"
    end
    local key_dir = data_dir .. "/rmpcd/lastfm"
    return key_dir .. "/session-key", key_dir
end

---@param self LastFmPlugin
---@param session_key string
local function persist_session(self, session_key)
    self.session_key = session_key

    local key_path, key_dir = session_key_path()
    if key_path == nil then
        log.warn("Could not resolve data dir; Last.fm session key will not be cached (re-auth required on next start)")
        return
    end

    local _, mkdir_err = fs.create_dir_all(key_dir)
    if mkdir_err ~= nil then
        log.error("Failed to create Last.fm data dir: " .. tostring(mkdir_err))
        return
    end

    local _, write_err = fs.write_str(key_path, session_key)
    if write_err ~= nil then
        log.error("Failed to write Last.fm session key: " .. tostring(write_err))
        return
    end
    process.spawn({ "chmod", "600", key_path })
end

---@param url string
---@return boolean
local function open_url(url)
    local opener = util.which("xdg-open") and "xdg-open" or util.which("open") and "open"
    if not opener then
        return false
    end
    local _, err = process.spawn({ opener, url })
    return err == nil
end

---@param title string
---@param body string
local function notify(title, body)
    if util.which("notify-send") then
        process.spawn({ "notify-send", title, body })
    elseif util.which("osascript") then
        process.spawn({
            "osascript",
            "-e",
            string.format('display notification %q with title %q', body, title),
        })
    end
end

local function lastfm_api_sig(params, shared_secret)
    local keys = {}
    for k, _ in pairs(params) do
        if k ~= "format" and k ~= "callback" then
            table.insert(keys, k)
        end
    end
    table.sort(keys)

    local base = ""
    for _, k in ipairs(keys) do
        base = base .. k .. params[k]
    end
    base = base .. shared_secret

    return util.md5(base)
end

---@return boolean
local function is_invalid_session(resp)
    return resp ~= nil and resp.code == 403
end

---@param api_key string
---@param shared_secret string
---@param session_key string
---@param song Song
---@param duration_seconds? number
---@return boolean invalid_session
local function lastfm_update_now_playing(api_key, shared_secret, session_key, song, duration_seconds)
    local params = {
        method = "track.updateNowPlaying",
        api_key = api_key,
        sk = session_key,
        format = "json",
    }

    if song.title ~= nil then
        params.track = song.title:first()
    end

    if song.artist ~= nil then
        params.artist = song.artist:first()
    end

    if song.album ~= nil then
        params.album = song.album:first()
    end

    if duration_seconds and duration_seconds > 0 then
        params.duration = tostring(duration_seconds)
    end

    if song.album_artist ~= nil then
        params.albumArtist = song.album_artist:first()
    end

    if song.musicbrainz_track_id ~= nil then
        params.mbid = song.musicbrainz_track_id:first()
    end

    params.api_sig = lastfm_api_sig(params, shared_secret)

    local resp = http.post("https://ws.audioscrobbler.com/2.0/", {
        headers = {},
        body = nil,
        params = params,
    })

    if resp.code ~= 200 then
        log.error("Last.fm updateNowPlaying failed: HTTP " .. tostring(resp.code))
        return is_invalid_session(resp)
    end
    return false
end

---@param api_key string
---@param shared_secret string
---@param token string
---@return string|nil session_key
local function get_session_key(api_key, shared_secret, token)
    local params = {
        api_key = api_key,
        method = "auth.getSession",
        token = token,
        format = "json",
    }

    params.api_sig = lastfm_api_sig(params, shared_secret)

    local session_response = http.get("https://ws.audioscrobbler.com/2.0/", { params = params })

    if session_response.code ~= 200 then
        return nil
    end

    local body = session_response:json()
    if body == nil or body.session == nil then
        return nil
    end

    return body.session.key
end

---@class Deque<T>
---@field first integer
---@field last integer
---@field [integer] T
local Deque = {}
Deque.__index = Deque

---@generic T
---@return Deque<T>
function Deque.new()
    return setmetatable({ first = 0, last = -1 }, Deque)
end

---@generic T
---@param value T
function Deque:push_right(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end

---@generic T
---@return T
function Deque:pop_left()
    local first = self.first
    if first > self.last then
        return nil
    end
    local value = self[first]
    self[first] = nil
    self.first = first + 1
    return value
end

---@generic T
---@return T
function Deque:peek_right()
    local last = self.last
    if self.first > last then
        return nil
    end
    return self[last]
end

---@generic T
---@return T
function Deque:peek_left()
    local first = self.first
    if first > self.last then
        return nil
    end
    return self[first]
end

---@param api_key string
---@param session_key string
---@param shared_secret string
---@param old_song Song
---@param song_start integer
---@return "ok" | "failed" | "invalid_session"
local function scrobble(api_key, session_key, shared_secret, old_song, song_start)
    local params = {
        method = "track.scrobble",
        api_key = api_key,
        sk = session_key,
        timestamp = tostring(song_start),
        format = "json",
    }

    if old_song.artist ~= nil then
        params.artist = old_song.artist:first()
    end

    if old_song.album ~= nil then
        params.album = old_song.album:first()
    end

    if old_song.title ~= nil then
        params.track = old_song.title:first()
    end

    if old_song.album_artist ~= nil then
        params.albumArtist = old_song.album_artist:first()
    end

    if old_song.musicbrainz_track_id ~= nil then
        params.mbid = old_song.musicbrainz_track_id:first()
    end

    params.api_sig = lastfm_api_sig(params, shared_secret)
    local resp = http.post("https://ws.audioscrobbler.com/2.0/", {
        params = params,
    })

    if resp.code ~= 200 then
        log.error("Last.fm scrobble failed: HTTP " .. tostring(resp.code))
        if is_invalid_session(resp) then
            return "invalid_session"
        end
        return "failed"
    end

    log.info("Scrobbled: " .. old_song.file)
    return "ok"
end

---@param api_key string
---@param session_key string
---@param shared_secret string
---@param scrobble_queue Deque<{ song: Song, timestamp: integer }>
---@return "invalid_session" | nil
local function process_scrobble_queue(api_key, session_key, shared_secret, scrobble_queue)
    log.info("Processing scrobble queue with " .. (scrobble_queue.last - scrobble_queue.first + 1) .. " items")
    while true do
        local item = scrobble_queue:peek_left()
        if item == nil then
            break
        end

        local status = scrobble(api_key, session_key, shared_secret, item.song, item.timestamp)
        if status == "ok" then
            scrobble_queue:pop_left()
        elseif status == "invalid_session" then
            log.info("Finished processing scrobble queue")
            return "invalid_session"
        else
            log.error("Failed to scrobble, stopping processing of scrobble queue for now")
            break
        end
    end
    log.info("Finished processing scrobble queue")
    return nil
end

---@param song_start integer
---@param current_time integer
---@param song Song
---@return boolean
local function should_scrobble(song_start, current_time, song)
    local min_scrobble_duration = 30
    local min_scrobble_time_secs = 4 * 60 -- 4 minutes as specified by last.fm

    if song_start == nil then
        return false
    end

    local song_duration_secs = math.floor(song.duration / 1000)

    if song_duration_secs < min_scrobble_duration then
        return false
    end

    local elapsed_secs = current_time - song_start

    if elapsed_secs >= min_scrobble_time_secs then
        return true
    end

    if elapsed_secs >= song_duration_secs / 2 then
        return true
    end

    return false
end

---@param self LastFmPlugin
local function handle_revoked_session(self)
    self.session_key = nil
    self.enabled = false

    local key_path = session_key_path()
    if key_path ~= nil then
        fs.delete(key_path)
    end

    log.warn("Last.fm session key was rejected; cleared it and disabled scrobbling. Restart rmpcd to re-authorize.")
    notify("Last.fm", "Session key was rejected. Restart rmpcd to re-authorize.")
end

M.setup = function(self, args)
    self.api_key = args.api_key
    self.shared_secret = args.shared_secret
    self.update_now_playing = args.update_now_playing == true
    self.enabled = args.enabled == nil or args.enabled

    self.scrobble_queue = Deque.new()

    local key_path = session_key_path()
    if key_path ~= nil then
        local cached_session_key, err = fs.read_str(key_path)
        if cached_session_key ~= nil and err == nil then
            log.info("Using cached Last.fm session key")
            self.session_key = cached_session_key
            return
        end
    end
    log.info("No cached Last.fm session key found, starting auth flow")

    local response = http.get("https://ws.audioscrobbler.com/2.0", {
        params = {
            method = "auth.getToken",
            api_key = args.api_key,
            format = "json",
        },
    })

    if response.code ~= 200 then
        log.error("Failed to get Last.fm auth token: HTTP " .. tostring(response.code))
        return
    end

    local token = response:json().token

    local auth_url = "https://www.last.fm/api/auth/?api_key=" .. args.api_key .. "&token=" .. token
    if open_url(auth_url) then
        log.warn("Opening your browser to authorize Last.fm. If it didn't open, visit: " .. auth_url)
    else
        log.warn("Couldn't open a browser. To authorize Last.fm, visit: " .. auth_url)
    end

    log.info("Waiting for Last.fm authorization (up to 5 minutes); authorize at: " .. auth_url)

    local poll_interval_ms = 5000
    local max_attempts = math.floor((5 * 60 * 1000) / poll_interval_ms)
    local attempts = 0
    sync.set_interval(poll_interval_ms, function(handle)
        attempts = attempts + 1
        local sk = get_session_key(args.api_key, args.shared_secret, token)
        if sk ~= nil then
            handle.cancel()
            persist_session(self, sk)
            log.info("Last.fm authorized")
        elseif attempts >= max_attempts then
            handle.cancel()
            self.enabled = false
            log.warn("Last.fm authorization timed out after 5 minutes; plugin disabled. To authorize, visit: " .. auth_url .. " then restart rmpcd.")
        end
    end)
end

M.song_change = function(self, old, new)
    if not self.enabled or self.session_key == nil then
        return
    end

    if new ~= nil and (self.update_now_playing or false) then
        if lastfm_update_now_playing(self.api_key, self.shared_secret, self.session_key, new, math.floor(new.duration / 1000)) then
            handle_revoked_session(self)
            return
        end
    end

    local current_time = os.time()

    if old ~= nil and self.song_start ~= nil and should_scrobble(self.song_start, current_time, old) then
        local last = self.scrobble_queue:peek_right()
        if last == nil or (last ~= nil and last.timestamp < self.song_start) then
            self.scrobble_queue:push_right({ song = old, timestamp = self.song_start })
        end
    end

    self.song_start = current_time
    self.current_song = new

    if process_scrobble_queue(self.api_key, self.session_key, self.shared_secret, self.scrobble_queue) == "invalid_session" then
        handle_revoked_session(self)
    end
end

M.state_change = function(self, old, new)
    if not self.enabled or self.session_key == nil then
        return
    end

    if new ~= "play" and old == "play" then
        local current_time = os.time()

        if
            self.current_song ~= nil
            and self.song_start ~= nil
            and should_scrobble(self.song_start, current_time, self.current_song)
        then
            local last = self.scrobble_queue:peek_right()
            if last == nil or (last ~= nil and last.timestamp < self.song_start) then
                self.scrobble_queue:push_right({ song = self.current_song, timestamp = self.song_start })
            end
        end

        self.song_start = nil
        self.current_song = nil
    end

    if process_scrobble_queue(self.api_key, self.session_key, self.shared_secret, self.scrobble_queue) == "invalid_session" then
        handle_revoked_session(self)
    end
end

M.subscribed_channels = { "rmpcd.lastfm" }
M.message = function(self, _channel, message)
    if message == "enable" then
        log.info("Enabling lastfm plugin")
        self.enabled = true
    elseif message == "disable" then
        log.info("Disabling lastfm plugin")
        self.enabled = false
    elseif message == "toggle" then
        log.info("Toggling lastfm plugin to: " .. tostring(not self.enabled))
        self.enabled = not self.enabled
    end

    if not self.enabled then
        self.current_song = nil
        self.song_start = nil
        return
    end
end

return M
