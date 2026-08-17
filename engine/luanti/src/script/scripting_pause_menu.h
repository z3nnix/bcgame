// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2025 grorp

#pragma once

#include "cpp_api/s_base.h"
#include "cpp_api/s_client_common.h"
#include "cpp_api/s_pause_menu.h"
#include "cpp_api/s_security.h"

class PauseMenuScripting:
		virtual public ScriptApiBase,
		public ScriptApiPauseMenu,
		public ScriptApiClientCommon,
		public ScriptApiSecurity
{
public:
	PauseMenuScripting(Client *client, const std::string &game_path);
	void loadBuiltin();
	std::string getPauseMenuFormspec();

protected:
	bool checkPathInternal(const std::string &abs_path, bool write_required,
			bool *write_allowed) override;

private:
	Client *m_client;
	std::string m_game_path;
	void initializeModApi(lua_State *L, int top);
};
