require("hs.ipc")
hs.autoLaunch(true)

local PANERU = os.getenv("HOME") .. "/.local/bin/paneru"
local TRACKPAD_THRESHOLD = 80
local TRACKPAD_COOLDOWN = 0.25
local GESTURE_TIMEOUT = 0.3
local TRACKPAD_INVERT = false
local MOUSE_INVERT = false
local SWALLOW = true

local props = hs.eventtap.event.properties
local accum, cooldownUntil = 0, 0

-- The menubar is the strip that fullFrame() includes and frame() excludes.
local function inMenubar()
	local screen = hs.mouse.getCurrentScreen()
	if not screen then
		return false
	end
	local top, usable = screen:fullFrame().y, screen:frame().y
	if top == usable then
		return false
	end
	local y = hs.mouse.absolutePosition().y
	return y >= top and y < usable
end

local function switchWorkspace(direction)
	hs.task.new(PANERU, nil, { "send-cmd", "window", "virtual", direction }):start()
end

--
-- Logging
--

local LOG_SIZE = 24
local gestures, events = {}, {}
local gesture = nil

local function push(list, line)
	list[#list + 1] = line
	if #list > LOG_SIZE then
		table.remove(list, 1)
	end
end

local function flushGesture()
	if not gesture or gesture.flushed then
		return
	end
	gesture.flushed = true
	push(
		gestures,
		string.format(
			"flick %4.0fpx / %3dms -> %d switch(es)   [inertia %4.0fpx over %2d events, dropped]",
			gesture.px,
			(gesture.last - gesture.start) * 1000,
			gesture.switches,
			gesture.momPx,
			gesture.momEvents
		)
	)
end

local function startGesture(now)
	flushGesture()
	gesture = { start = now, last = now, px = 0, switches = 0, momPx = 0, momEvents = 0 }
end

function gestureLog()
	flushGesture() -- include the one just finished
	if #gestures == 0 then
		return "no trackpad gestures recorded yet"
	end
	return table.concat(gestures, "\n")
end

function scrollLog()
	if #events == 0 then
		return "no menubar scroll events seen yet"
	end
	return table.concat(events, "\n")
end

menubarScroll = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, function(e)
	if not inMenubar() then
		return false
	end
	local mods = e:getFlags()
	if mods.alt or mods.cmd or mods.ctrl or mods.shift or mods.fn then
		return false
	end

	local continuous = e:getProperty(props.scrollWheelEventIsContinuous) == 1
	local momentum = e:getProperty(props.scrollWheelEventMomentumPhase)
	local phase = e:getProperty(props.scrollWheelEventScrollPhase)
	local px = e:getProperty(props.scrollWheelEventPointDeltaAxis1)
	local lines = e:getProperty(props.scrollWheelEventDeltaAxis1)

	local function fire(dy, invert)
		if invert then
			dy = -dy
		end
		local dir = dy > 0 and "north" or "south"
		switchWorkspace(dir)
		return dir
	end

	if not continuous then
		-- Mouse wheel. Each notch is already a discrete intent, so fire 1:1
		if lines == 0 then -- horizontal
			push(events, string.format("mouse line=0 -> passthrough (horizontal)"))
			return false
		end
		push(events, string.format("mouse line=%d -> SWITCH %s", lines, fire(lines, MOUSE_INVERT)))
		return SWALLOW
	end

	--
	-- Trackpad
	--

	local now = hs.timer.secondsSinceEpoch()

	if not gesture or now - gesture.last > GESTURE_TIMEOUT or (momentum == 0 and phase == 1) then
		startGesture(now)
		accum = 0
	end
	gesture.last = now

	if momentum ~= 0 then
		gesture.momPx = gesture.momPx + math.abs(px)
		gesture.momEvents = gesture.momEvents + 1
		if momentum == 3 then
			flushGesture()
		end -- kCGMomentumScrollPhaseEnd
		return SWALLOW
	end

	gesture.px = gesture.px + math.abs(px)

	if now < cooldownUntil then
		accum = 0
		return SWALLOW
	end

	accum = accum + px
	if math.abs(accum) < TRACKPAD_THRESHOLD then
		push(events, string.format("trackpad px=%3.0f -> accum %3.0f/%d", px, accum, TRACKPAD_THRESHOLD))
		return SWALLOW
	end

	local dy = accum
	accum, cooldownUntil = 0, now + TRACKPAD_COOLDOWN
	gesture.switches = gesture.switches + 1
	push(events, string.format("trackpad px=%3.0f -> SWITCH %s", px, fire(dy, TRACKPAD_INVERT)))

	return SWALLOW
end)

menubarScroll:start()

function reloadConfig(files)
	for _, file in pairs(files) do
		if file:sub(-4) == ".lua" then
			hs.reload()
		end
	end
end

configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/hammerspoon/", reloadConfig)
configWatcher:start()

hs.notify.show("Hammerspoon", "", "Menubar scroll -> paneru workspaces")
