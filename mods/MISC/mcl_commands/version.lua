local S = core.get_translator(core.get_current_modname())

local function read_file(path)
	local file = io.open(path, "r")
	if not file then return nil end
	local contents = file:read("*a")
	file:close()
	return contents
end

local function get_git_str(git_dir)
	local head = read_file(git_dir .. DIR_DELIM .. "HEAD")
	if not head then return end
	head = string.trim(head)

	local ref = head:match("^ref:%s*(.+)$")
	if not ref then
		return head -- detached
	end

	-- <https://git-scm.com/docs/git-symbolic-ref>
	local ref_path = git_dir .. DIR_DELIM .. ref
	local hash = read_file(ref_path)
	if hash then
		return string.trim(hash)
	end

	-- <https://git-scm.com/docs/git-pack-refs>
	local packed = read_file(git_dir .. DIR_DELIM .. "packed-refs")
	if packed then
		for line in packed:gmatch("[^\r\n]+") do
			if not line:match("^#") then
				local hash_match, ref_match = line:match("^(%w+)%s+(.+)$")
				if ref_match == ref then
					return hash_match
				end
			end
		end
	end
end

local version_str = "(unknown)"
do
	local game_root = core.get_game_info().path
	local readme_path = game_root .. DIR_DELIM .. "README.md"
	local contents = read_file(readme_path)
	local version = contents:match("Version:%s*([%d%.]+)")
	if version then
		version_str = version
	end

	-- <https://git-scm.com/docs/gitrepository-layout>
	-- while a different Git layout *is* possible, it's very uncommon to be stored differently
	-- ... at least not for a Mineclonia repo
	local git_dir = game_root .. DIR_DELIM .. ".git"
	if core.path_exists(git_dir) then
		local git_str = get_git_str(git_dir)
		if git_str then
			version_str = version_str .. " (git " .. git_str:sub(1, 10) .. ")"
		end
	end
end

core.register_chatcommand("version", {
	description = S("Displays the Mineclonia version"),
	params = "",
	privs = {},
	func = function(name)
		core.chat_send_player(name, "Mineclonia version: " .. version_str)
	end
})
