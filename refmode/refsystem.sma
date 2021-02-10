#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

public plugin_init()
{
    register_plugin("RefMainSystem", "1.0", "Reff");

    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
    
    register_event("DeathMsg", "eventPlayerDeath", "a");
    register_event("DeathMsg", "eventPlayerDeath", "bg");
}

public fw_PlayerSpawn_Post(id)
{
    if (!is_user_alive(id) && !is_user_connected(id))
        return PLUGIN_HANDLED;

    fm_strip_user_weapons(id);
    fm_give_item(id, "weapon_knife");

    return PLUGIN_CONTINUE;
}

public eventPlayerDeath()
{
	new index = read_data(2);
	set_task(0.16, "DeathPost", index);
}
public DeathPost(index)
{
	set_pev(index, pev_deadflag, DEAD_RESPAWNABLE);
	dllfunc(DLLFunc_Spawn, index);
	set_pev(index, pev_iuser1, 0);
}

stock fm_strip_user_weapons(index) {
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent))
		return 0;

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return;

	static Float:originF[3], save
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;

	engfunc(EngFunc_RemoveEntity, ent)
}
stock fm_create_entity(const classname[])
{
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
}