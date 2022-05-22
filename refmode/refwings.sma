#include <amxmodx>
#include <fakemeta>
#include <vector>

new const wings_model[] = "models/ref/krilo2.mdl"
new const yukiramy_model[] = "sprites/ref/yukiramy.spr"
new const WING_CLASS[] = "ref_wing"

new wing_status[33], had_wing[33]
new yukiramy

public plugin_init()
{
	register_plugin("進階翅膀", "1.0", "Reff")
	register_forward(FM_PlayerPreThink, "fw_playerPreThink")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_clcmd("rw", "get_ref_wing")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, wings_model)
	yukiramy = engfunc(EngFunc_PrecacheModel, yukiramy_model)
}

public client_connect(id) {
	remove_wing(id)
}
public client_disconnected(id) {
	remove_wing(id)
}
public get_ref_wing(id)
{
	if( !had_wing[id] ) {
		had_wing[id] = 1
		new wing = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target") )
		set_pev(wing, pev_classname, WING_CLASS)
		set_pev(wing, pev_movetype, MOVETYPE_FOLLOW)
		set_pev(wing, pev_solid, SOLID_NOT)
		set_pev(wing, pev_owner, id)
		set_pev(wing, pev_aiment, id)
		engfunc(EngFunc_SetModel, wing, wings_model)

	} else remove_wing(id)
}

public remove_wing(id)
{
	had_wing[id] = 0
	new wing = fm_find_ent_by_owner(0, WING_CLASS, id)
	if( pev_valid(wing) ) {
		engfunc(EngFunc_RemoveEntity, wing)
	}
}

public fw_playerPreThink(id)
{
	if( !is_user_alive(id) ) 
		return FMRES_IGNORED

	if( wing_status[id] ) {

		static Float:velocity[3]
		pev(id, pev_velocity, velocity)

		if( velocity[2] < 0.0 ) // 下降時
		{
			velocity[2] = (velocity[2] + 15.0 < -50.0) ? velocity[2] + 15.0 : -50.0
			set_pev(id, pev_velocity, velocity)
		}

	}

	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) ) 
		return FMRES_IGNORED
	if( !had_wing[id] )
		return FMRES_IGNORED

	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	static Float:nextJumpCheckTime[33], Float:game_time
	game_time = get_gametime()

	if( CurButton & IN_JUMP && !(CurButton & IN_DUCK) ) {

		if( game_time < nextJumpCheckTime[id] )
			return FMRES_IGNORED

		nextJumpCheckTime[id] = game_time + 0.2

		if( !(pev(id, pev_flags) & FL_ONGROUND) )
			set_wing_float(id)
    }

	if( CurButton & IN_USE ) {
		static Float:velocity[3]
		velocity_by_aim(id, 1200, velocity)
		velocity[2] = 300.0
		set_pev(id, pev_velocity, velocity)
	}

	return FMRES_IGNORED
}

public set_wing_float(id)
{
	if( !wing_status[id] ) {
		wing_status[id] = 1 // 啟動懸空
		client_print(id, print_center, "[翅膀] 啟動懸空")

	} else {
		wing_status[id] = 0 // 關閉懸空
		client_print(id, print_center, "[翅膀] 關閉懸空")
	}
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {

	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}