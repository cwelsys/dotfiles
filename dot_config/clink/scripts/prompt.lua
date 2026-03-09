local starship_enabled = true
local ohmyposh_enabled = false

if starship_enabled and ohmyposh_enabled then
	error("Only one of 'starship_enabled' or 'ohmyposh_enabled' can be set to true.")
	return
end

if starship_enabled then
	function starship_transient_prompt_func(prompt)
		return io.popen("starship module character"
			.. " --keymap=" .. rl.getvariable('keymap')
		):read("*a")
	end

	function starship_preprompt_user_func(prompt)
		local cwd = os.getcwd()
		local home_dir = os.getenv("USERPROFILE") or os.getenv("HOME")
		if home_dir and cwd:lower():find(home_dir:lower(), 1, true) == 1 then
			cwd = "~" .. cwd:sub(#home_dir + 1)
		end
		console.settitle(cwd)
	end

	local starship_init = io.popen("starship init cmd")
	if not starship_init then
		error("Failed to initialize Starship prompt.")
		return
	end
	load(starship_init:read("*a"))()
	starship_init:close()
elseif ohmyposh_enabled then
	local home_dir = os.getenv("USERPROFILE") or os.getenv("HOME")
	if not home_dir then
		error("Unable to determine home directory.")
		return
	end

	local ohmyposh_theme_file = home_dir .. "/.config/posh.toml"
	local ohmyposh_theme = string.gsub(ohmyposh_theme_file, "\\", "/")

	local ohmyposh_init = io.popen("oh-my-posh init cmd --config " .. ohmyposh_theme)
	if not ohmyposh_init then
		error("Failed to initialize Oh My Posh prompt.")
		return
	end
	load(ohmyposh_init:read("*a"))()
	ohmyposh_init:close()
else
	return
end
