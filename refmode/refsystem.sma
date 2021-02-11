#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

new const SoundFiles[6][] =
{
	"ref/hit1.wav",
	"ref/miss1.wav",
	"ref/miss2.wav",
	"ref/miss3.wav",
	"ref/helmet_hit.wav",
	"ref/knife_slash1.wav"
}


public plugin_init()
{
	register_plugin("RefMainSystem", "1.0", "Reff");

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");

	register_event("DeathMsg", "eventPlayerDeath", "a");
	register_event("DeathMsg", "eventPlayerDeath", "bg");
}

public plugin_precache()
{
	for (new i=0; i < sizeof(SoundFiles); i++) {
		engfunc(EngFunc_PrecacheSound, SoundFiles[i]);
	}
}

public fw_PlayerKilled(this, attack, shouldgib)
{
	if ( !is_user_alive(attack) || !is_user_connected(attack) ) return PLUGIN_HANDLED;

	static Float:thisOrigin[3], Float:attOrigin[3], distance;
	pev(this,   pev_origin, thisOrigin);
	pev(attack, pev_origin, attOrigin );

	distance = floatround(get_distance_f(thisOrigin, attOrigin));

	new Float:volume;
	switch (distance/100) {
		case 0: volume = 1.0;
		case 1..3: volume = 0.8;
		case 4..5: volume = 0.7;
		case 6..7: volume = 0.6;
		default:   volume = 0.4;
	}
	emit_sound(attack, CHAN_STATIC, SoundFiles[0], volume, ATTN_NORM, 0, PITCH_NORM);

	new Float:heal = float(pev(attack, pev_health));
	if( heal < 1000.0 ) {
		set_pev(attack, pev_health, heal+20.0);

		engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, attack);
		write_short(1<<10); // Duration --> Note: Duration and HoldTime is in special units. 1 second is equal to (1<<12) i.e. 4096 units.
		write_short(1<<9); // Holdtime
		write_short(0x0000); // 0x0001 Fade in
		write_byte(0);
		write_byte(255);
		write_byte(0);
		write_byte(20);  // Alpha
		message_end();
	}

	return PLUGIN_HANDLED;
}

public fw_PlayerSpawn_Post(id)
{
    if (!is_user_alive(id) && !is_user_connected(id))
        return PLUGIN_HANDLED;

    fm_strip_user_weapons(id);
    fm_give_item(id, "weapon_knife");

    return PLUGIN_CONTINUE;
}
public client_putinserver(id)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	set_task(1.0, "checkIsAlivePost", id);
	return PLUGIN_HANDLED;
}
public checkIsAlivePost(id)
{
	if(!is_user_connected(id)) return;
	if(!is_user_alive(id)) DeathPost(id);
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