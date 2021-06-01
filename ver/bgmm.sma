public boss_skill_switch_menu(id)
{
	if ( !g_isBoss[id] )
		return PLUGIN_HANDLED

	new menu = menu_create("\y癡漢魔王專用技能", "boss_skill_use")
	menu_additem(menu, "\w[\r55\w] 吸收傷害", "1", 0)
	menu_additem(menu, "\w[\r55\w] 普通的跳", "2", 0)
	menu_additem(menu, "\w[\r60\w] 牽引繩", "3", 0)
	menu_additem(menu, "\d[被動] 野性激發(擊殺人類回復15點魔力)", "4", 0)
	menu_additem(menu, "\d[被動] 魔法少女伊莉亞(每秒回復2點魔力)", "5", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}
public boss_skill_use(id,  menu, item)
{
	if ( item == MENU_EXIT || !g_isBoss[id] )
	{
		menu_destroy(menu)
    	}
	if ( cannon_mode_temp[id] || cannon_mode[id] )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)

	set_dhudmessage(120, 67, 133, -1.0, 0.2, 0, 6.0, 4.5, 0.5, 0.5)
	switch(key)
	{
		case 1:
		{
			if ( !skill_ed[id] && boss_mana[id] >= 55)
			{
				boss_mana[id] -= 55
				skill_ed[id] = true
				set_task(5.0,"skill_ed_off",id)
				set_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 90)
				show_dhudmessage(0, "花豹使用了吸收傷害")
			}
			else
				boss_skill_switch_menu(id)
		}
		case 2:
		{
			if ( boss_mana[id] >= 55 )
			{
				boss_mana[id] -= 55
				normal_jump(id)
				show_dhudmessage(0, "花豹使用了普通的跳躍")
			}
			else
				boss_skill_switch_menu(id)
		}
		case 3:
		{
			if ( !skill_cn[id] && boss_mana[id] >= 60 )
			{
				boss_mana[id] -= 60
				skill_cn[id] = true
				skill_cn_public = true
				connect_rope(id+1333)
				set_task(10.0,"skill_cn_off",id)
				show_dhudmessage(0, "花豹使用了牽引繩")
			}
			else
				boss_skill_switch_menu(id)
		}
	}
	return PLUGIN_HANDLED
}
public normal_jump(id)
{
	static Float:velocity[3]
	velocity_by_aim(id, 1350, velocity);
	velocity[2] = 720.0;
	set_pev(id, pev_velocity, velocity);
}
public connect_rope(id)
{
	id -= 1333
	for (new i=0 ; i < 32 ; i++){
		if ( is_user_connected(i) && is_user_alive(i) && id != i)
		{
			new Origin[3]
			get_user_origin(i, Origin)

			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMENTPOINT)
			write_short(id)
			write_coord(Origin[0])
			write_coord(Origin[1]) 
			write_coord(Origin[2]) 
			write_short(beam)
			write_byte(3) // framerate
			write_byte(3) // framerate
			write_byte(1) // life
			write_byte(6)  // width
			write_byte(0)// noise
			write_byte(random_num(1, 255))// r, g, b
			write_byte(random_num(1, 255))// r, g, b
			write_byte(random_num(1, 255))// r, g, b
			write_byte(255)	// brightness
			write_byte(20)	// speed	200
			message_end()
		}
	}
	set_task(0.1,"connect_rope",id+1333)
}
public skill_ed_off(id)
{
	skill_ed[id] = false
	set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 90)

	if ( skill_ed_get[id] >= 25000 )
		finish_achievement(id, ED_DAMAGE_25000)
	if ( skill_ed_get[id] == 0 )
		finish_achievement(id, ED_DAMAGE_0000)
	if ( skill_ed_get[id] == 444 )
		finish_achievement(id, ED_DAMAGE_444)

	skill_ed_get[id] = 0
}
public skill_cn_off(id)
{
	skill_cn[id] = false
	skill_cn_public = false
	remove_task(id+1333)
}