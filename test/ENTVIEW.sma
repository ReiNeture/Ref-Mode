#include <amxmodx>
#include <fakemeta>
#include <engine>

#define PLUGIN_NAME "Ent view"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Re"

new ef;

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_clcmd("xxx", "testOnGround");
	// register_think("TestOnGround", "ratThink");
}

public plugin_precache()
{
	ef = precache_model("sprites/ref/ef_explosion.spr");
}

public fw_PlayerPreThink(id)
{
        if (!is_user_alive(id))
		return;

	static target, body
	get_user_aiming(id, target, body)

	if (pev_valid(target))
	{
		new szName[32]
		entity_get_string(target, EV_SZ_classname, szName, 31)
		//native entity_get_string(iIndex, iKey, szReturn[], iRetLen)

		client_print(id, print_center, "%s", szName)
		
		if ( equal(szName ,"grenade") )
			remove_entity(target)
	}
}
public testOnGround(id)
{
	new Float:origin[3];
	pev(id, pev_origin, origin);

	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, 0, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(ef)
	write_byte(5)
	write_byte(250)
	message_end()
}
// public testOnGround(id)
// {
// 	static entity;
// 	entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"));
// 	if (!pev_valid(entity) ) return FMRES_IGNORED;

// 	new Float:vOrigin[3];
// 	pev(id, pev_origin, vOrigin);
// 	vOrigin[2] += 10.0;

// 	new Float:ddss[3];
// 	velocity_by_aim(id, 150, ddss);

// 	set_pev(entity, pev_classname, "TestOnGround");
// 	set_pev(entity, pev_owner, id);
// 	set_pev(entity, pev_movetype, MOVETYPE_NONE);
// 	set_pev(entity, pev_solid, SOLID_NOT);
// 	set_pev(entity, pev_velocity, ddss);
	

// 	engfunc(EngFunc_SetSize, entity, Float:{-1.1, -1.1, -1.1}, Float:{1.1, 1.1, 1.1} );
// 	engfunc(EngFunc_SetModel, entity, "models/ref/w_aicore.mdl");
// 	engfunc(EngFunc_SetOrigin, entity, vOrigin);
// 	set_pev(entity, pev_nextthink, halflife_time() + 0.01);

// 	return FMRES_HANDLED;
// }

// public ratThink(ent)
// {
// 	const FL_ONGROUND2 = (FL_CONVEYOR|FL_ONGROUND|FL_PARTIALGROUND|FL_INWATER|FL_FLOAT);

// 	// if ( pev( iEnt, pev_flags ) & FL_ONGROUND2 ) {
// 	// 	static 		
// 	// }
// }