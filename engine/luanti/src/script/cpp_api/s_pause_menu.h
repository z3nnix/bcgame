// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2025 grorp

#pragma once

#include "cpp_api/s_base.h"

class ScriptApiPauseMenu : virtual public ScriptApiBase
{
public:
	void open_settings();

	// Reference to the function registered via core.register_on_pause_menu().
	// Stored per script environment so it cannot dangle across sessions.
	void setPauseMenuCallbackRef(int ref) { m_pause_menu_callback_ref = ref; }
	int getPauseMenuCallbackRef() const { return m_pause_menu_callback_ref; }

private:
	int m_pause_menu_callback_ref = LUA_NOREF;
};
