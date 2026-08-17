// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2025 grorp

#include "l_pause_menu.h"
#include "client/keycode.h"
#include "cpp_api/s_pause_menu.h"
#include "gui/mainmenumanager.h"
#include "lua_api/l_internal.h"
#include "client/client.h"


int ModApiPauseMenu::l_show_touchscreen_layout(lua_State *L)
{
	g_gamecallback->touchscreenLayout();
	return 0;
}


int ModApiPauseMenu::l_is_internal_server(lua_State *L)
{
	lua_pushboolean(L, getClient(L)->m_internal_server);
	return 1;
}


int ModApiPauseMenu::l_register_on_pause_menu(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TFUNCTION);
	auto *script = getScriptApi<ScriptApiPauseMenu>(L);
	if (script->getPauseMenuCallbackRef() != LUA_NOREF)
		luaL_unref(L, LUA_REGISTRYINDEX, script->getPauseMenuCallbackRef());
	script->setPauseMenuCallbackRef(luaL_ref(L, LUA_REGISTRYINDEX));
	return 0;
}

std::string ModApiPauseMenu::getPauseMenuFormspec(lua_State *L)
{
	auto *script = getScriptApi<ScriptApiPauseMenu>(L);
	int ref = script->getPauseMenuCallbackRef();
	if (ref == LUA_NOREF)
		return std::string();

	lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		return std::string();
	}

	if (lua_pcall(L, 0, 1, 0) != 0) {
		const char *err = lua_tostring(L, -1);
		warningstream << "Error in pause menu callback: "
				<< (err ? err : "(unknown error)") << std::endl;
		lua_pop(L, 1);
		return std::string();
	}

	std::string formspec;
	if (lua_isstring(L, -1)) {
		size_t len = 0;
		const char *s = lua_tolstring(L, -1, &len);
		formspec.assign(s, len);
	}
	lua_pop(L, 1);
	return formspec;
}


void ModApiPauseMenu::Initialize(lua_State *L, int top)
{
	API_FCT(show_touchscreen_layout);
	API_FCT(is_internal_server);
	API_FCT(register_on_pause_menu);
}
