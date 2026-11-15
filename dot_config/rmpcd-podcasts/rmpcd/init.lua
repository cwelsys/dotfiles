local home = os.getenv("HOME")

local config = {
	address = "127.0.0.1:6601",
	mpris_instance = "podcasts",
	mpris_identity = "Podcasts",
}

config.mpris = os.getenv("DBUS_SESSION_BUS_ADDRESS") ~= nil

rmpcd.install("#builtin.playcount")

rmpcd.install("plugins.resume"):setup({
	prefixes = { "podcast/" },
	finished_within_s = 300,
	min_resume_s = 30,
	rewind_s = 5,
	save_every_s = 30,
	poll_s = 5,
	pending_path = home .. "/.local/state/rmpcd-podcasts/resume-pending.json",
})

rmpcd.install("plugins.active"):setup({ name = "podcasts" })

return config
