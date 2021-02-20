#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
//#include <zombieplague>

new bool:round_end
new g_hamnpc, g_shokewaveSpr, g_explodeSpr, g_glassSpr, g_glassSpr2
new shoot_distance[33], shoot_1distance[33], shoot_2distance[33], shoot_3distance[33],
use_angles[33], space_mode[33], space_touch[33], space_ent[33], set_origin[33], space_takedamage[33],
size_type[33], owner_touch[33], team_attack[33], master[33], Float:health[33], Float:shoot_time[33]
public plugin_init()
{
	register_plugin("結界", "JOT", "LieVersion")
	register_clcmd("make_space" , "create_space", ADMIN_MENU)
	register_clcmd("make_space2" , "create_space2", ADMIN_MENU)
	register_clcmd("space_menu" , "cmd_menu", ADMIN_MENU)
	register_think("SpaceBox_Ent", "fw_Think")
	register_think("SpaceBox_Ent1", "fw_Think2")
	register_think("SpaceBox_Ent2", "fw_Think2")
	register_think("SpaceBox_Ent3", "fw_Think2")
	register_think("SpaceBox_Ent4", "fw_Think2")
	register_think("SpaceBox_Ent5", "fw_Think2")
	register_think("SpaceBox_Ent6", "fw_Think2")
	register_forward(FM_Touch, "fw_Touch")
	register_logevent("EventRoundEnd", 2, "1=Round_End")
	register_logevent("EventRoundStart", 2, "1=Round_Start")
}
public client_connect(id)
{
	shoot_distance[id] = 0
	shoot_1distance[id] = 120
	shoot_2distance[id] = 240
	shoot_3distance[id] = 360
	shoot_time[id] = 0.1
	set_origin[id] = 1
	use_angles[id] = 0
	space_ent[id] = 1
	size_type[id] = 1
	owner_touch[id] = 0
	space_mode[id] = 1
	space_touch[id] = 0
	space_takedamage[id] = 0
	team_attack[id] = 0
	master[id] = 1
	health[id] = 2000.0
}
public plugin_precache()
{
	precache_model("models/circles3.mdl")
	precache_model("models/circles3_small.mdl")
	precache_model("models/circles3_large.mdl")
	precache_model("models/circles3_super_large.mdl")
	precache_model("models/circles3_2.mdl")
	precache_model("models/circles3_small_2.mdl")
	precache_model("models/circles3_large_2.mdl")
	precache_model("models/circles3_super_large_2.mdl")
	precache_sound("lie_jump/Grenade_Sound.wav")
	g_explodeSpr = precache_model("sprites/zerogxplode.spr")
	g_shokewaveSpr = precache_model( "sprites/shockwave.spr")
	g_glassSpr2 = precache_model("models/shatter2.mdl")
	g_glassSpr = precache_model("models/circles_shatter.mdl")
}
public fw_Think(ent)
{
	if (!pev_valid(ent))
		return;

	if (pev(ent, pev_health) < 100)
	{
		Glass_shatter(ent)
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	new id = pev(ent, pev_iuser1)
	if (pev(ent, pev_health) < health[id])
		set_pev(ent, pev_health, pev(ent, pev_health) + health[id] / 100)

	new Float:maxs[3] = {40.0, 40.0, 40.0}
	new Float:mins[3] = {-40.0, -40.0, -40.0}
	if (pev(ent, pev_iuser4) == 0)
	{
		maxs[0] /= 2
		maxs[1] /= 2
		maxs[2] /= 2
		mins[0] /= 2
		mins[1] /= 2
		mins[2] /= 2
	}
	else if (pev(ent, pev_iuser4) == 2)
	{
		maxs[0] *= 2
		maxs[1] *= 2
		maxs[2] *= 2
		mins[0] *= 2
		mins[1] *= 2
		mins[2] *= 2
	}
	else if (pev(ent, pev_iuser4) == 3)
	{
		maxs[0] *= 4
		maxs[1] *= 4
		maxs[2] *= 4
		mins[0] *= 4
		mins[1] *= 4
		mins[2] *= 4
	}
	if (!space_touch[id])
	{
		if (pev(ent, pev_iuser3) || space_ent[id])
			engfunc(EngFunc_SetSize, ent, mins, maxs)
	}
	if (pev(ent, pev_iuser2) || pev(ent, pev_iuser3) || !pev(ent, pev_iuser3))
	{
		if ((pev(id, pev_button) & IN_ATTACK2 && get_user_weapon(id) == CSW_KNIFE) || (pev(id, pev_button) & IN_RELOAD && !is_user_alive(id)))
		{
			new Float:origin[3]
			pev(ent, pev_origin, origin)
			space_explosion(ent, id, origin)
			return;
		}
		if ((pev(id, pev_button) & IN_ATTACK && get_user_weapon(id) == CSW_KNIFE) || (pev(id, pev_button) & IN_USE && !is_user_alive(id)))
		{
			new Float:EntOrigin[3]
			pev(ent, pev_origin, EntOrigin)
			new Float:AimOrigin[3]
			pev(id, pev_origin, AimOrigin)
			if (get_distance_f(EntOrigin, AimOrigin) <= 60)
			{
				space_explosion(ent, id, EntOrigin)
				return;
			}
			fm_get_aim_origin(id, AimOrigin)
			if (get_distance_f(EntOrigin, AimOrigin) <= 80)
			{
				space_explosion(ent, id, EntOrigin)
				return;
			}
		}
	}
	new iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "c")
	if (iNum > 1)
	{
		new Float:the_range = 40.0, Float:Eorigin[3]
		pev(ent, pev_origin, Eorigin)
		if (pev(ent, pev_iuser4) == 0)
			the_range /= 2.0
		else if (pev(ent, pev_iuser4) == 2)
			the_range *= 2.0
		else if (pev(ent, pev_iuser4) == 3)
			the_range *= 4.0

		for (new i = 0;i < iNum;i++)
		{
			new Float:Porigin[3]
			iPlayer = iPlayers[i]
			pev(iPlayer, pev_origin, Porigin)
			if (is_user_alive(iPlayer) && iPlayer != id && space_touch[id] && is_user_connected(id) && cs_get_user_team(iPlayer) != CS_TEAM_SPECTATOR)
			{
				if ((Eorigin[0] - the_range <= Porigin[0] <= Eorigin[0] + the_range) &&
				(Eorigin[1] - the_range <= Porigin[1] <= Eorigin[1] + the_range) &&
				(Eorigin[2] - the_range <= Porigin[2] <= Eorigin[2] + the_range))
				{
					new Float:pos_ptr[3], Float:pos_ptd[3]
					pev(ent, pev_origin, pos_ptr)
					pev(iPlayer, pev_origin, pos_ptd)
					for(new t = 0;t < 3;t++)
					{
						pos_ptd[t] -= pos_ptr[t]
						pos_ptd[t] *= 8.0
					}
					set_pev(iPlayer, pev_velocity, pos_ptd)
					set_pev(iPlayer, pev_impulse, pos_ptd)
				}
			}
		}
	}
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	dllfunc(DLLFunc_Think, ent)
}
public fw_Think2(ent)
{
	new ent_group1[3], ent_group2[3]
	pev(ent, pev_vuser1, ent_group1)
	pev(ent, pev_vuser2, ent_group2)
	if (!pev_valid(ent_group1[0]) || !pev_valid(ent_group1[1]) || !pev_valid(ent_group1[2]) || !pev_valid(ent_group2[0]) || !pev_valid(ent_group2[1]) || !pev_valid(ent_group2[2]))
	{
		if (pev_valid(ent_group1[0]))
			engfunc(EngFunc_RemoveEntity, ent_group1[0])

		if (pev_valid(ent_group1[1]))
			engfunc(EngFunc_RemoveEntity, ent_group1[1])

		if (pev_valid(ent_group1[2]))
			engfunc(EngFunc_RemoveEntity, ent_group1[2])

		if (pev_valid(ent_group2[0]))
			engfunc(EngFunc_RemoveEntity, ent_group2[0])

		if (pev_valid(ent_group2[1]))
			engfunc(EngFunc_RemoveEntity, ent_group2[1])

		if (pev_valid(ent_group2[2]))
			engfunc(EngFunc_RemoveEntity, ent_group2[2])

		return;
	}
	if (pev(ent, pev_health) < 100)
	{
		Glass_shatter(ent)
		if (pev_valid(ent_group1[0]))
			engfunc(EngFunc_RemoveEntity, ent_group1[0])

		if (pev_valid(ent_group1[1]))
			engfunc(EngFunc_RemoveEntity, ent_group1[1])

		if (pev_valid(ent_group1[2]))
			engfunc(EngFunc_RemoveEntity, ent_group1[2])

		if (pev_valid(ent_group2[0]))
			engfunc(EngFunc_RemoveEntity, ent_group2[0])

		if (pev_valid(ent_group2[1]))
			engfunc(EngFunc_RemoveEntity, ent_group2[1])

		if (pev_valid(ent_group2[2]))
			engfunc(EngFunc_RemoveEntity, ent_group2[2])

		return;
	}
	new id = pev(ent, pev_iuser1)
	if (pev(ent, pev_health) < health[id])
		set_pev(ent, pev_health, pev(ent, pev_health) + health[id] / 100)

	new num, cache[3], origin_set = 20
	new Float:origin_center[3]
	new Float:maxs[3] = {40.0, 40.0, 40.0}
	new Float:mins[3] = {-40.0, -40.0, -40.0}
	pev(ent, pev_vuser4, cache)
	num = cache[0]
	pev(ent, pev_vuser3, origin_center)
	if (pev(ent, pev_iuser4) == 0)
	{
		maxs[0] /= 2
		maxs[1] /= 2
		maxs[2] /= 2
		mins[0] /= 2
		mins[1] /= 2
		mins[2] /= 2
		origin_set /= 2
	}
	else if (pev(ent, pev_iuser4) == 2)
	{
		maxs[0] *= 2
		maxs[1] *= 2
		maxs[2] *= 2
		mins[0] *= 2
		mins[1] *= 2
		mins[2] *= 2
		origin_set *= 2
	}
	else if (pev(ent, pev_iuser4) == 3)
	{
		maxs[0] *= 4
		maxs[1] *= 4
		maxs[2] *= 4
		mins[0] *= 4
		mins[1] *= 4
		mins[2] *= 4
		origin_set *= 4
	}
	if (num == 0 || num == 1)
	{
		maxs[1] = 1.0
		mins[1] = -1.0
	}
	else if (num == 2 || num == 3)
	{
		maxs[0] = 1.0
		mins[0] = -1.0
	}
	else if (num == 4 || num == 5)
	{
		maxs[2] = 1.0
		mins[2] = -1.0
	}
	if (num == 0)
	{
		set_pev(ent, pev_angles, Float:{0.0, 90.0, 0.0})
		origin_center[1] += float(origin_set) * 2.0
	}
	else if (num == 1)
	{
		set_pev(ent, pev_angles, Float:{0.0, 270.0, 0.0})
		origin_center[1] -= float(origin_set) * 2.0
	}
	else if (num == 2)
	{
		set_pev(ent, pev_angles, Float:{0.0, 0.0, 0.0})
		origin_center[0] += float(origin_set) * 2.0
	}
	else if (num == 3)
	{
		set_pev(ent, pev_angles, Float:{0.0, 180.0, 0.0})
		origin_center[0] -= float(origin_set) * 2.0
	}
	else if (num == 4)
	{
		set_pev(ent, pev_angles, Float:{270.0, 0.0, 0.0})
		origin_center[2] -= float(origin_set) * 2.0
	}
	else if (num == 5)
	{
		set_pev(ent, pev_angles, Float:{90.0, 0.0, 0.0})
		origin_center[2] += float(origin_set) * 2.0
	}
	if (set_origin[id])
		engfunc(EngFunc_SetOrigin, ent, origin_center)

	if (!space_touch[id])
	{
		if (pev(ent, pev_iuser3) || space_ent[id])
			engfunc(EngFunc_SetSize, ent, mins, maxs)
	}
	if (pev(ent, pev_iuser2) || pev(ent, pev_iuser3) || !pev(ent, pev_iuser3))
	{
		if ((pev(id, pev_button) & IN_ATTACK2 && get_user_weapon(id) == CSW_KNIFE) || (pev(id, pev_button) & IN_RELOAD && !is_user_alive(id)))
		{
			new Float:origin[3]
			pev(ent, pev_vuser3, origin)
			space_explosion(ent, id, origin)
			return;
		}
		if ((pev(id, pev_button) & IN_ATTACK && get_user_weapon(id) == CSW_KNIFE) || (pev(id, pev_button) & IN_USE && !is_user_alive(id)))
		{
			new Float:EntOrigin[3], Float:AimOrigin[3]
			pev(ent, pev_vuser3, EntOrigin)
			pev(id, pev_origin, AimOrigin)
			if (get_distance_f(EntOrigin, AimOrigin) <= 60)
			{
				space_explosion(ent, id, EntOrigin)
				return;
			}
			fm_get_aim_origin(id, AimOrigin)
			if (get_distance_f(EntOrigin, AimOrigin) <= 80)
			{
				space_explosion(ent, id, EntOrigin)
				return;
			}
		}
	}
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	dllfunc(DLLFunc_Think, ent)
}
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (!pev_valid(victim) || !pev_valid(attacker) || !attacker || !victim)
		return HAM_IGNORED;

	if (victim == attacker)
		return HAM_IGNORED;

	new classname[32]
	pev(victim, pev_classname, classname, 31)
	if (!equal(classname, "SpaceBox_Ent") && !equal(classname, "SpaceBox_Ent1") && !equal(classname, "SpaceBox_Ent2") && !equal(classname, "SpaceBox_Ent3") && !equal(classname, "SpaceBox_Ent4") && !equal(classname, "SpaceBox_Ent5") && !equal(classname, "SpaceBox_Ent6"))
		return HAM_IGNORED;

	if (!(damage_type & (1<<24)))
	{
		new Float:Fend[3],end[3]
		fm_get_aim_origin(attacker, Fend)
		end[0] = floatround(Fend[0])
		end[1] = floatround(Fend[1])
		end[2] = floatround(Fend[2])
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPARKS)
		write_coord(end[0])
		write_coord(end[1])
		write_coord(end[2])
		message_end()
	}
 	return HAM_IGNORED;
}
public cmd_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	show_space_menu(id)
	return PLUGIN_HANDLED;
}
public show_space_menu(id)
{
	new menu = menu_create("\y結界選單", "spacemenu")
	new itemname[64], data[2]
	if (shoot_distance[id] != 0)
		format(itemname, 63, "\w準心距離")
	else
		format(itemname, 63, "\y準心距離")

	data[0] = 1
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (shoot_distance[id] != 1)
		format(itemname, 63, "\w距離%d", shoot_1distance[id])
	else
		format(itemname, 63, "\y距離%d", shoot_1distance[id])

	data[0] = 2
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (shoot_distance[id] != 2)
		format(itemname, 63, "\w距離%d", shoot_2distance[id])
	else
		format(itemname, 63, "\y距離%d", shoot_2distance[id])

	data[0] = 3
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (shoot_distance[id] != 3)
		format(itemname, 63, "\w距離%d^n", shoot_3distance[id])
	else
		format(itemname, 63, "\y距離%d^n", shoot_3distance[id])

	data[0] = 4
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (!set_origin[id])
		format(itemname, 63, "\w六面結界:座標固定")
	else
		format(itemname, 63, "\y六面結界:座標固定")

	data[0] = 5
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (!space_takedamage[id])
		format(itemname, 63, "\w結界損壞")
	else
		format(itemname, 63, "\y結界損壞")

	data[0] = 6
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (!use_angles[id])
		format(itemname, 63, "\w套用角度")
	else
		format(itemname, 63, "\y套用角度")

	data[0] = 7
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	format(itemname, 63, "\r形成時間 %.1f 秒", shoot_time[id])
	data[0] = 8
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (size_type[id] == 0)
		format(itemname, 63, "\r大小: 小")
	else if (size_type[id] == 1)
		format(itemname, 63, "\r大小: 中")
	else if (size_type[id] == 2)
		format(itemname, 63, "\r大小: 大")
	else if (size_type[id] == 3)
		format(itemname, 63, "\r大小: 超大")

	data[0] = 9
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	format(itemname, 63, "\r耐久度: %.1f", health[id])
	data[0] = 10
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	format(itemname, 63, "%s自我冰凍", owner_touch[id] ? "\r" : "\w")
	data[0] = 11
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	format(itemname, 63, "%s隊友傷害", team_attack[id] ? "\r" : "\w")
	data[0] = 12
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (master[id] == 0)
		format(itemname, 63, "\r無主結界")
	else if (master[id] == 1)
		format(itemname, 63, "\r自主結界")

	data[0] = 13
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (space_mode[id] == 0)
		format(itemname, 63, "\r指定物件")
	else if (space_mode[id] == 1)
		format(itemname, 63, "\r指定座標")

	data[0] = 14
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	if (space_touch[id] == 0)
		format(itemname, 63, "\r實體規範")
	else if (space_touch[id] == 1)
		format(itemname, 63, "\r範圍規範")

	data[0] = 15
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	format(itemname, 63, "%s形成前固有", space_ent[id] ? "\r" : "\w")
	data[0] = 16
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_EXITNAME, "離開")
	menu_display(id, menu, 0)
}
public spacemenu(id, menu, item)
{
	if (item == MENU_EXIT || !(get_user_flags(id) & ADMIN_MENU))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	new data[6], itemname[64], access, callback, itemid
	menu_item_getinfo(menu, item, access, data,5, itemname, 63, callback)
	itemid = data[0]
	switch (itemid)
	{
		case 1: shoot_distance[id] = 0
		case 2:
		{
			if (shoot_distance[id] != 1)
				shoot_distance[id] = 1
			else if (shoot_1distance[id] >= 240)
				shoot_1distance[id] = 80
			else
				shoot_1distance[id] += 20
		}
		case 3:
		{
			if (shoot_distance[id] != 2)
				shoot_distance[id] = 2
			else if (shoot_2distance[id] >= 480)
				shoot_2distance[id] = 80
			else
				shoot_2distance[id] += 20
		}
		case 4:
		{
			if (shoot_distance[id] != 3)
				shoot_distance[id] = 3
			else if (shoot_3distance[id] >= 600)
				shoot_3distance[id] = 0
			else
				shoot_3distance[id] += 40
		}
		case 5: set_origin[id] = !set_origin[id]
		case 6: space_takedamage[id] = !space_takedamage[id]
		case 7: use_angles[id] = !use_angles[id]
		case 8:
		{
			if (shoot_time[id] >= 5.0)
				shoot_time[id] = 0.0
			else
				shoot_time[id] += 0.1
		}
		case 9:
		{
			if (size_type[id] >= 3)
				size_type[id] = 0
			else
				size_type[id]++
		}
		case 10:
		{
			if (health[id] >= 2000.0)
				health[id] = 400.0
			else
				health[id] += 400.0
		}
		case 11: owner_touch[id] = !owner_touch[id]
		case 12: team_attack[id] = !team_attack[id]
		case 13: master[id] = !master[id]
		case 14: space_mode[id] = !space_mode[id]
		case 15: space_touch[id] = !space_touch[id]
		case 16: space_ent[id] = !space_ent[id]
	}
	menu_destroy(menu)
	show_space_menu(id)
	return PLUGIN_HANDLED;
}
public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr) || !pev_valid(ptd))
		return FMRES_IGNORED;

	static classname[32]
	pev(ptr, pev_classname, classname, 31)
	if (!equal(classname, "SpaceBox_Ent") && !equal(classname, "SpaceBox_Ent1") && !equal(classname, "SpaceBox_Ent2") && !equal(classname, "SpaceBox_Ent3") && !equal(classname, "SpaceBox_Ent4") && !equal(classname, "SpaceBox_Ent5") && !equal(classname, "SpaceBox_Ent6"))
		return FMRES_IGNORED;

	if (pev(ptr, pev_iuser2) || pev(ptr, pev_iuser3))
		return FMRES_IGNORED;

	new id = pev(ptr, pev_iuser1)
	if (1 <= ptd <= get_maxplayers())
	{
		if ((id == ptd && owner_touch[id]) || id != ptd)
		{
			fm_set_rendering(ptr)
			engfunc(EngFunc_EmitSound, ptr, CHAN_VOICE, "lie_jump/Grenade_Sound.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			static Float:origin[3]
			pev(ptd, pev_origin, origin)
			set_pev(ptr, pev_origin, origin)
			set_pev(ptr, pev_vuser3, origin)
			set_pev(ptr, pev_iuser2, 1)
		}
	}
	return FMRES_IGNORED;
}
public create_space(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	new Float:aimorigin[3], Float:angles[3]
	fm_get_aim_origin(id, aimorigin)
	if (shoot_distance[id])
	{
		new Float:vector[3], Float:userorigin[3], Float:addorigin[3]
		pev(id, pev_origin, userorigin)
		pev(id, pev_origin, addorigin)
		if (shoot_distance[id] == 1)
			velocity_by_aim(id, shoot_1distance[id], vector)
		if (shoot_distance[id] == 2)
			velocity_by_aim(id, shoot_2distance[id], vector)
		if (shoot_distance[id] == 3)
			velocity_by_aim(id, shoot_3distance[id], vector)

		xs_vec_add(addorigin, vector, addorigin)
		if (get_distance_f(userorigin, aimorigin) > get_distance_f(userorigin, addorigin) || space_mode[id])
		{
			aimorigin[0] = addorigin[0]
			aimorigin[1] = addorigin[1]
			aimorigin[2] = addorigin[2]
		}
	}
	if (use_angles[id])
		pev(id, pev_angles, angles)

	new ent = create_entity_object("SpaceBox_Ent", angles, aimorigin, id)
	if (ent == -1)
		return PLUGIN_HANDLED;

	set_pev(ent, pev_iuser3, 0)
	set_pev(ent, pev_iuser2, 0)
	if (master[id])
		set_pev(ent, pev_iuser1, id)
	else
		set_pev(ent, pev_iuser1, 0)

	if (!g_hamnpc)
	{
		RegisterHamFromEntity(Ham_TraceAttack, ent, "fw_TraceAttack")
		g_hamnpc = 1
	}
	fm_set_rendering(ent, 1, 125, 255, 255, 19, 64)
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	dllfunc(DLLFunc_Think, ent)
	if (shoot_time[id])
	{
		set_task(shoot_time[id], "freeze_over_sound", ent)
		set_task(shoot_time[id], "space_freeze_over", ent)
	}
	return PLUGIN_HANDLED;
}
public create_space2(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	new Float:aimorigin[3]
	fm_get_aim_origin(id, aimorigin)
	if (shoot_distance[id])
	{
		new Float:vector[3], Float:userorigin[3], Float:addorigin[3]
		pev(id, pev_origin, userorigin)
		pev(id, pev_origin, addorigin)
		if (shoot_distance[id] == 1)
			velocity_by_aim(id, shoot_1distance[id], vector)
		if (shoot_distance[id] == 2)
			velocity_by_aim(id, shoot_2distance[id], vector)
		if (shoot_distance[id] == 3)
			velocity_by_aim(id, shoot_3distance[id], vector)

		xs_vec_add(addorigin, vector, addorigin)
		if (get_distance_f(userorigin, aimorigin) > get_distance_f(userorigin, addorigin) || space_mode[id])
		{
			aimorigin[0] = addorigin[0]
			aimorigin[1] = addorigin[1]
			aimorigin[2] = addorigin[2]
		}
	}
	create_entity_object2(aimorigin, id)
	return PLUGIN_HANDLED;
}
public space_freeze_over(ent)
{
	if (!pev_valid(ent))
		return;

	if (pev(ent, pev_iuser2))
		return;

	if (pev(ent, pev_iuser3))
		return;

	fm_set_rendering(ent)
	set_pev(ent, pev_iuser3, 1)
}
public freeze_over_sound(ent)
{
	if (!pev_valid(ent))
		return;

	if (pev(ent, pev_iuser2))
		return;

	if (pev(ent, pev_iuser3))
		return;

	engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, "lie_jump/Grenade_Sound.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
public space_explosion(ent, id, Float:origin[3])
{
	if (!round_end)
	{
		new damage, Float:range = 60.0
		new target = -1
		if (pev(ent, pev_iuser4) == 0)
			range /= 2
		else if (pev(ent, pev_iuser4) == 2)
			range *= 2
		else if (pev(ent, pev_iuser4) == 3)
			range *= 4

		create_blast_effect(origin, 0, 128, 255, 200, range)
		create_explosion_effect(origin)
		while ((target = engfunc(EngFunc_FindEntityInSphere, target, origin, range)) != 0)
		{
			if (!is_user_alive(target) || !is_user_connected(target) || target == id || (!team_attack[id]))
				continue;

			damage = 200
			if (pev(ent, pev_iuser4) == 0)
				damage /= 2
			else if (pev(ent, pev_iuser4) == 2)
				damage *= 2
			else if (pev(ent, pev_iuser4) == 3)
				damage *= 4

			if (is_ent_stuck(target))
			{
				if (pev(ent, pev_iuser4) == 0)
					damage += pev(target, pev_health) / 4
				else if (pev(ent, pev_iuser4) == 1)
					damage += pev(target, pev_health) / 2
				else if (pev(ent, pev_iuser4) == 2)
					damage += pev(target, pev_health)
				else if (pev(ent, pev_iuser4) == 3)
					damage += pev(target, pev_health) * 2
			}
			damage_human_user(target, id, damage)
		}
	}
	if (pev_valid(ent))
		engfunc(EngFunc_RemoveEntity, ent)
}
public EventRoundEnd()
	round_end = true

public EventRoundStart()
	round_end = false

public damage_human_user(victim, attacker, damage)
{
	if (cs_get_user_team(victim) == CS_TEAM_SPECTATOR)
		return 0;

	new Float:damage_armor_rate, damage_armor, armor
	damage_armor_rate = (1.0 / 2.0)
	damage_armor = floatround(float(damage) * damage_armor_rate)
	armor = pev(victim, pev_armorvalue)
	if (damage_armor > 0 && armor > 0)
	{
		if (armor > damage_armor)
		{
			damage -= damage_armor
			set_pev(victim, pev_armorvalue, (armor - damage_armor))
		}
		else
		{
			damage -= armor
			set_pev(victim, pev_armorvalue, 0)
		}
	}
	if (pev(victim, pev_health) > damage)
		set_user_takedamage(victim, damage, DMG_BLAST)
	else
		ExecuteHamB(Ham_Killed, victim, attacker, 0)

	return 1;
}
stock create_entity_object(const classname[], Float:angles[3], Float:origin[3], id)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!pev_valid(ent))
		return -1;

	set_pev(ent, pev_classname, classname)
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_sequence, 0)
	if (space_takedamage[id])
		set_pev(ent, pev_takedamage, 1.0)
	else
		set_pev(ent, pev_takedamage, 0.0)

	set_pev(ent, pev_health, health[id])
	set_pev(ent, pev_animtime, 2.0)
	set_pev(ent, pev_angles, angles)
	if (size_type[id] == 0)
		engfunc(EngFunc_SetModel, ent, "models/circles3_small.mdl")
	else if (size_type[id] == 1)
		engfunc(EngFunc_SetModel, ent, "models/circles3.mdl")
	else if (size_type[id] == 2)
		engfunc(EngFunc_SetModel, ent, "models/circles3_large.mdl")
	else if (size_type[id] == 3)
		engfunc(EngFunc_SetModel, ent, "models/circles3_super_large.mdl")

	engfunc(EngFunc_SetOrigin, ent, origin)
	new Float:maxs[3] = {40.0, 40.0, 40.0}
	new Float:mins[3] = {-40.0, -40.0, -40.0}
	set_pev(ent, pev_iuser4, 1)
	if (size_type[id] == 0)
	{
		maxs[0] /= 2
		maxs[1] /= 2
		maxs[2] /= 2
		mins[0] /= 2
		mins[1] /= 2
		mins[2] /= 2
		set_pev(ent, pev_iuser4, 0)
	}
	else if (size_type[id] == 2)
	{
		maxs[0] *= 2
		maxs[1] *= 2
		maxs[2] *= 2
		mins[0] *= 2
		mins[1] *= 2
		mins[2] *= 2
		set_pev(ent, pev_iuser4, 2)
	}
	else if (size_type[id] == 3)
	{
		maxs[0] *= 4
		maxs[1] *= 4
		maxs[2] *= 4
		mins[0] *= 4
		mins[1] *= 4
		mins[2] *= 4
		set_pev(ent, pev_iuser4, 3)
	}
	if (!space_touch[id])
	{
		if (pev(ent, pev_iuser3) || space_ent[id])
			engfunc(EngFunc_SetSize, ent, mins, maxs)
	}
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	dllfunc(DLLFunc_Think, ent)
	return ent;
}
stock create_entity_object2(Float:origin[3], id)
{
	new ent1 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	new ent2 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	new ent3 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	new ent4 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	new ent5 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	new ent6 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	new ent_group1[3], ent_group2[3], ent_group3[6], classname[32]
	ent_group1[0] = ent1
	ent_group1[1] = ent2
	ent_group1[2] = ent3
	ent_group2[0] = ent4
	ent_group2[1] = ent5
	ent_group2[2] = ent6
	ent_group3[0] = ent_group1[0]
	ent_group3[1] = ent_group1[1]
	ent_group3[2] = ent_group1[2]
	ent_group3[3] = ent_group2[0]
	ent_group3[4] = ent_group2[1]
	ent_group3[5] = ent_group2[2]
	for (new num = 0;num < sizeof(ent_group3);num++)
	{
		new cache[3]
		cache[0] = num
		formatex(classname, 31, "SpaceBox_Ent%d", num + 1)
		set_pev(ent_group3[num], pev_classname, classname)
		set_pev(ent_group3[num], pev_solid, SOLID_BBOX)
		set_pev(ent_group3[num], pev_movetype, MOVETYPE_NONE)
		set_pev(ent_group3[num], pev_sequence, 0)
		if (space_takedamage[id])
			set_pev(ent_group3[num], pev_takedamage, 1.0)
		else
			set_pev(ent_group3[num], pev_takedamage, 0.0)

		set_pev(ent_group3[num], pev_health, health[id])
		set_pev(ent_group3[num], pev_animtime, 2.0)
		set_pev(ent_group3[num], pev_iuser2, 0)
		set_pev(ent_group3[num], pev_iuser3, 0)
		set_pev(ent_group3[num], pev_vuser1, ent_group1)
		set_pev(ent_group3[num], pev_vuser2, ent_group2)
		set_pev(ent_group3[num], pev_vuser3, origin)
		set_pev(ent_group3[num], pev_vuser4, cache)
		if (master[id])
			set_pev(ent_group3[num], pev_iuser1, id)
		else
			set_pev(ent_group3[num], pev_iuser1, 0)

		if (size_type[id] == 0)
		{
			engfunc(EngFunc_SetModel, ent_group3[num], "models/circles3_small_2.mdl")
			set_pev(ent_group3[num], pev_iuser4, 0)
		}
		else if (size_type[id] == 1)
		{
			engfunc(EngFunc_SetModel, ent_group3[num], "models/circles3_2.mdl")
			set_pev(ent_group3[num], pev_iuser4, 1)
		}
		else if (size_type[id] == 2)
		{
			engfunc(EngFunc_SetModel, ent_group3[num], "models/circles3_large_2.mdl")
			set_pev(ent_group3[num], pev_iuser4, 2)
		}
		else if (size_type[id] == 3)
		{
			engfunc(EngFunc_SetModel, ent_group3[num], "models/circles3_super_large_2.mdl")
			set_pev(ent_group3[num], pev_iuser4, 3)
		}
		fm_set_rendering(ent_group3[num], 1, 125, 255, 255, 19, 64)
		set_pev(ent_group3[num], pev_nextthink, get_gametime() + 0.01)
		dllfunc(DLLFunc_Think, ent_group3[num])
		if (shoot_time[id])
		{
			if (num == 5)
				set_task(shoot_time[id], "freeze_over_sound", ent_group3[num])

			set_task(shoot_time[id], "space_freeze_over", ent_group3[num])
		}
	}
	if (pev_valid(ent1) && pev_valid(ent2) && pev_valid(ent3) && pev_valid(ent4) && pev_valid(ent5) && pev_valid(ent6))
		return true;

	if (pev_valid(ent1))
		engfunc(EngFunc_RemoveEntity, ent1)

	if (pev_valid(ent2))
		engfunc(EngFunc_RemoveEntity, ent2)

	if (pev_valid(ent3))
		engfunc(EngFunc_RemoveEntity, ent3)

	if (pev_valid(ent4))
		engfunc(EngFunc_RemoveEntity, ent4)

	if (pev_valid(ent5))
		engfunc(EngFunc_RemoveEntity, ent5)

	if (pev_valid(ent6))
		engfunc(EngFunc_RemoveEntity, ent6)

	return false;
}
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}
stock set_user_takedamage(index, damage, damage_type)
{
	new Float:origin[3], iOrigin[3]
	pev(index, pev_origin, origin)
	FVecIVec(origin, iOrigin)
	message_begin(MSG_ONE, get_user_msgid("Damage"), _, index)
	write_byte(21)
	write_byte(20)
	write_long(damage_type)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	message_end()
	set_pev(index, pev_health, max(pev(index, pev_health) - damage, 0))
}
stock is_ent_stuck(ent)
{
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	engfunc(EngFunc_TraceHull, originF, originF, 0, HULL_HEAD, ent, 0)
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;

	return false;
}
stock create_blast_effect(const Float:originF[3], red, green, blue, brightness, Float:radius)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2])
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2] + 100 + radius)
	write_short(g_shokewaveSpr)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(floatround(radius / 3))
	write_byte(0)
	write_byte(red)
	write_byte(green)
	write_byte(blue)
	write_byte(brightness)
	write_byte(0)
	message_end()
}
stock get_speed_vector_to_origin(ent1, origin2[3], speed, Float:new_velocity[3])
{
	if (!pev_valid(ent1))
		return 0;

	static Float:origin1[3], Float:num
	pev(ent1, pev_origin, origin1)
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	num = speed / vector_length(new_velocity)
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	return 1;
}
stock create_explosion_effect(const Float:originF[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2])
	write_short(g_explodeSpr)
	write_byte(32)
	write_byte(15)
	write_byte(0)
	message_end()
}
stock fm_get_aim_origin(index, Float:origin[3])
{
	new Float:start[3], Float:view_ofs[3], Float:dest[3]
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	pev(index, pev_v_angle, dest)
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	xs_vec_mul_scalar(dest, 9999.0, dest)
	xs_vec_add(start, dest, dest)
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0)
	get_tr2(0, TR_vecEndPos, origin)
	return 1;
}
stock Glass_shatter(ent)
{
	if (!pev_valid(ent))
		return 0;

	static Float:Forigin[3], origin[3], my_size
	pev(ent, pev_origin, Forigin)
	my_size = 128
	origin[0] = floatround(Forigin[0])
	origin[1] = floatround(Forigin[1])
	origin[2] = floatround(Forigin[2])
	if (pev(ent, pev_iuser4) == 0)
		my_size /= 2
	else if (pev(ent, pev_iuser4) == 2)
		my_size *= 2
	else if (pev(ent, pev_iuser4) == 3)
		my_size *= 2

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_BREAKMODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 32)
	write_coord(my_size)
	write_coord(my_size)
	write_coord(my_size)
	write_coord(random_num(-256, 256))
	write_coord(random_num(-256, 256))
	write_coord(25)
	write_byte(20)
	write_short(g_glassSpr)
	write_byte(6)
	write_byte(16)
	write_byte(0x01)
	message_end()
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_BREAKMODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 32)
	write_coord(my_size / 2)
	write_coord(my_size / 2)
	write_coord(my_size / 2)
	write_coord(random_num(-128, 128))
	write_coord(random_num(-128, 128))
	write_coord(25)
	write_byte(20)
	write_short(g_glassSpr2)
	write_byte(12)
	write_byte(25)
	write_byte(0x01)
	message_end()
	return 1;
}