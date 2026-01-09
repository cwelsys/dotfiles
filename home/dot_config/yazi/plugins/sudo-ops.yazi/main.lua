--- @since 25.12.29
--- sudo-ops.yazi - Sudo mirrors of rename and create

local get_hovered = ya.sync(function()
	local h = cx.active.current.hovered
	if h then
		return {
			url = tostring(h.url),
			name = h.name,
		}
	end
end)

local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

local function fail(s, ...)
	ya.notify {
		title = "sudo-ops",
		content = string.format(s, ...),
		level = "error",
		timeout = 5,
	}
end

local function sudo_rename()
	local hovered = get_hovered()
	if not hovered then
		return ya.notify { title = "sudo-ops", content = "No file hovered", level = "warn", timeout = 3 }
	end

	local name = hovered.name
	local cursor_pos = #name
	local dot = name:match(".*()%.")
	if dot then
		cursor_pos = dot - 1
	end

	local new_name, event = ya.input {
		title = " Rename:",
		value = name,
		cursor = cursor_pos,
		pos = { "hovered", y = 1, w = 50 },
	}

	if event ~= 1 or not new_name or new_name == "" or new_name == name then
		return
	end

	local cwd = get_cwd()
	local new_path = cwd .. "/" .. new_name

	local output, err = Command("sudo"):arg("mv"):arg(hovered.url):arg(new_path):stderr(Command.PIPED):output()
	if not output then
		fail("Failed to run sudo mv: %s", err)
	elseif not output.status.success then
		fail("Rename failed:\n%s", output.stderr)
	else
		ya.notify { title = "sudo-ops", content = "Renamed to " .. new_name, level = "info", timeout = 3 }
	end
end

local function sudo_create()
	local cwd = get_cwd()

	local name, event = ya.input {
		title = " Create:",
		pos = { "hovered", y = 1, w = 50 },
	}

	if event ~= 1 or not name or name == "" then
		return
	end

	local path = cwd .. "/" .. name
	local is_dir = name:sub(-1) == "/"

	local output, err
	if is_dir then
		output, err = Command("sudo"):arg("mkdir"):arg("-p"):arg(path):stderr(Command.PIPED):output()
	else
		-- Ensure parent directory exists
		local parent = name:match("(.*/)")
		if parent then
			Command("sudo"):arg("mkdir"):arg("-p"):arg(cwd .. "/" .. parent):output()
		end
		output, err = Command("sudo"):arg("touch"):arg(path):stderr(Command.PIPED):output()
	end

	if not output then
		fail("Failed to run sudo: %s", err)
	elseif not output.status.success then
		fail("Create failed:\n%s", output.stderr)
	else
		ya.notify { title = "sudo-ops", content = "Created " .. name, level = "info", timeout = 3 }
	end
end

return {
	entry = function(_, job)
		local action = job.args[1]

		if action == "rename" then
			sudo_rename()
		elseif action == "create" then
			sudo_create()
		else
			fail("Unknown action: %s. Use 'rename' or 'create'", action or "nil")
		end
	end,
}
