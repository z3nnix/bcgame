// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2025 grorp

#include "scripting_pause_menu.h"
#include "client/client.h"
#include "cpp_api/s_internal.h"
#include "filesys.h"
#include "lua_api/l_client_common.h"
#include "lua_api/l_menu_common.h"
#include "lua_api/l_pause_menu.h"
#include "lua_api/l_settings.h"
#include "lua_api/l_util.h"

PauseMenuScripting::PauseMenuScripting(Client *client, const std::string &game_path):
		ScriptApiBase(ScriptingType::PauseMenu),
		m_client(client),
		m_game_path(game_path)
{
	setGameDef(client);

	SCRIPTAPI_PRECHECKHEADER

	initializeSecurity();

	lua_getglobal(L, "core");
	int top = lua_gettop(L);

	// Initialize our lua_api modules
	initializeModApi(L, top);
	lua_pop(L, 1);

	// Push builtin initialization type
	lua_pushstring(L, "pause_menu");
	lua_setglobal(L, "INIT");

	infostream << "SCRIPTAPI: Initialized pause menu modules" << std::endl;
}

void PauseMenuScripting::initializeModApi(lua_State *L, int top)
{
	// Register reference classes (userdata)
	LuaSettings::Register(L);

	// Initialize mod API modules
	ModApiPauseMenu::Initialize(L, top);
	ModApiMenuCommon::Initialize(L, top);
	ModApiClientCommon::Initialize(L, top);
	ModApiUtil::Initialize(L, top);
}

void PauseMenuScripting::loadBuiltin()
{
	loadScript(Client::getBuiltinLuaPath() + DIR_DELIM "init.lua");
	checkSetByBuiltin();

	// Allow the game to override the pause menu formspec
	if (!m_game_path.empty()) {
		std::string game_pause_menu =
				m_game_path + DIR_DELIM + "menu" + DIR_DELIM + "pause_menu.lua";
		if (fs::PathExists(game_pause_menu))
			loadScript(game_pause_menu);
	}
}

std::string PauseMenuScripting::getPauseMenuFormspec()
{
	SCRIPTAPI_PRECHECKHEADER

	return ModApiPauseMenu::getPauseMenuFormspec(L);
}

bool PauseMenuScripting::checkPathInternal(const std::string &abs_path, bool write_required,
		bool *write_allowed)
{
	// NOTE: The pause menu env is on the same level of trust as the mainmenu env.
	// However, since it doesn't need anything else at the moment, there's no
	// reason to give it access to anything else.
	// See also: `MainMenuScripting::mayModifyPath` for similar, but less restricted checks.

	if (write_required)
		return false;

	std::string path_builtin = fs::AbsolutePath(Client::getBuiltinLuaPath());
	if (!path_builtin.empty() && fs::PathStartsWith(abs_path, path_builtin))
		return true;

	// Allow the game to ship a pause menu definition (read-only)
	if (!m_game_path.empty()) {
		std::string path_game_menu = fs::AbsolutePath(
				m_game_path + DIR_DELIM + "menu");
		if (!path_game_menu.empty() && fs::PathStartsWith(abs_path, path_game_menu))
			return true;
	}

	return false;
}
