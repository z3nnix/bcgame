-- Betacraft Discord Rich Presence launcher.
--
-- The actual presence is handled by a small companion binary
-- (tools/discord_rpc). This mod starts it as soon as the game session begins
-- (singleplayer, locally hosted or remote) and stops it again on shutdown.
-- The binary connects to the locally running Discord client over its IPC
-- interface and shows a static "Playing Betacraft" activity.
--
-- For the mod to be allowed to start the binary it must be listed in the
-- secure.trusted_mods setting of the main configuration file
-- (~/.minetest/minetest.conf). Secure settings cannot be provided by games.

local modpath = core.get_modpath("mcl_discord_rpc")
local sep = (package.config and package.config:sub(1, 1)) or "/"
local is_windows = sep == "\\"
local bin_name = is_windows and "discord_rpc.exe" or "discord_rpc"
local bin_path = modpath .. sep .. "bin" .. sep .. bin_name
local pidfile = core.get_worldpath() .. sep .. "betacraft_discord_rpc.pid"
local logfile = core.get_worldpath() .. sep .. "discord_rpc.log"

-- The insecure environment (with os.execute) must be requested from the mod's
-- top-level scope: the engine only grants it when the call originates there.
local insecure = core.request_insecure_environment()

local function read_pid()
	local f = io.open(pidfile, "r")
	if not f then
		return nil
	end
	local pid = f:read("*n")
	f:close()
	return pid
end

local function stop_rpc()
	local env = insecure
	if not env then
		return
	end
	local pid = read_pid()
	if pid then
		if is_windows then
			env.os.execute("taskkill /F /PID " .. pid)
		else
			env.os.execute("kill " .. pid)
		end
	end
	env.os.remove(pidfile)
end

local function start_rpc()
	local f = io.open(bin_path, "r")
	if not f then
		core.log("warning", "[mcl_discord_rpc] companion binary not found at " ..
			bin_path .. " (build it with tools/discord_rpc/build.sh)")
		return
	end
	f:close()

	local env = insecure
	if not env then
		core.log("warning", "[mcl_discord_rpc] mod is not trusted; add mcl_discord_rpc " ..
			"to secure.trusted_mods in the main minetest.conf")
		return
	end

	stop_rpc()

	-- Pass the game's PID so the companion can stop itself when the game
	-- dies. The game's PID is found via the shell that os.execute spawns:
	-- that shell is a direct child of the game process, so its $PPID is the
	-- game's PID. (Mod security blocks reading /proc/self directly, and on
	-- Windows there is no portable way, so there on_shutdown handles it.)
	local parent_pid = ""
	if not is_windows then
		local game_pid_file = core.get_worldpath() .. sep .. "betacraft_game_pid.tmp"
		env.os.execute('echo $PPID > "' .. game_pid_file .. '"')
		local f = io.open(game_pid_file, "r")
		if f then
			local pid = f:read("*n")
			f:close()
			env.os.remove(game_pid_file)
			if pid and pid > 0 then
				parent_pid = " -parent-pid " .. math.floor(pid)
			end
		end
	end

	local cmd
	if is_windows then
		cmd = 'start "" /b "' .. bin_path .. '" -pidfile "' .. pidfile .. '" -log "' ..
			logfile .. '" -verbose'
	else
		cmd = 'nohup "' .. bin_path .. '" -pidfile "' .. pidfile .. '" -log "' ..
			logfile .. '"' .. parent_pid .. ' >/dev/null 2>&1 &'
	end
	env.os.execute(cmd)
	core.log("action", "[mcl_discord_rpc] started companion: " .. bin_path)
end

if core.settings:get_bool("mcl_discord_rpc_enabled", true) then
	start_rpc()
end

core.register_on_shutdown(stop_rpc)