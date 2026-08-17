local BUTTON_STYLE = "border=false;bgimg=gui_buttons.png;bgimg_hovered=gui_buttons.png;bgimg_pressed=gui_buttons.png"

core.register_on_pause_menu(function()
	return "formspec_version[1]" ..
		"size[11,5.5,false]" ..
		"no_prepend[]" ..
		"bgcolor[#0000007f;true]" ..
		"style[btn_continue;" .. BUTTON_STYLE .. "]" ..
		"style[btn_settings;" .. BUTTON_STYLE .. "]" ..
		"style[btn_exit_os;" .. BUTTON_STYLE .. "]" ..
		"button_exit[1.5,1.35;8,0.8;btn_continue;Back to game]" ..
		"button[1.5,2.35;8,0.8;btn_settings;Options...]" ..
		"button[1.5,3.35;8,0.8;btn_exit_os;Save and quit to launcher]"
end)
