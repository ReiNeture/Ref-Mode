#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

native get_refknife(id);
native use_firestar(id);
native use_moonsword(id);
native use_enchant(id);
native use_moonbreak(id);
native use_chanmo(id);
native get_element_status(id);
native use_icewing(id);

new bossid = 0
new g_targetid = 0
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flNextIdle 48
#define m_flNextAttack 83
public plugin_init()
{
	register_plugin("Ref knife bot", "1.0", "Reff")
	register_forward(FM_PlayerPreThink, "fw_playerPreThink");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage");
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Weapon_PrimaryAttack", 1)
	register_clcmd("iamboss", "summon_entity")
}

public summon_entity(id)
{
	bossid = id
	g_targetid = 0
}

#define pDataKey_iOwner 41
#define pData_Item 4
public fw_Weapon_PrimaryAttack(ent)
{
	static id
	id = get_pdata_cbase(ent, pDataKey_iOwner, pData_Item)

	if( !is_user_alive(id) || id != bossid || !g_targetid )
		return HAM_IGNORED

	set_next_attacktime(id, ent, 0.05) // 附魔後攻速

	return HAM_IGNORED
}

public fw_PlayerTakeDamage(this, idinflictor, idattacker, Float:damage, damagebits) {
	if ( g_targetid || this != bossid || idattacker == this || !is_user_alive(idattacker))
		return PLUGIN_CONTINUE

	g_targetid = idattacker
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
    if( !is_user_bot(id) )
		return PLUGIN_CONTINUE

	if( !bossid )
		bossid = id

	return PLUGIN_CONTINUE
}
public fw_playerPreThink(id)
{
	if( !is_user_alive(id) ) 
		return FMRES_IGNORED
	if( id != bossid ) 
		return FMRES_IGNORED

	static Float:nextthink, Float:nextskill, Float:nextlong
	static Float:gamtime; gamtime = get_gametime()
	if( nextthink > gamtime )
		return FMRES_IGNORED

	// nextthink = gamtime + 0.25
	nextthink = gamtime + 0.1

	static healths
	healths = pev(id, pev_health)

	// new Float:skill_times = healths >= 1500 ? 6.0 : 1.0;
	// new Float:long_times = healths >= 1500 ? 1.5 : 0.5;
	new Float:skill_times = healths >= 1500 ? 0.25 : 0.25;
	new Float:long_times = healths >= 1500 ? 0.0 : 0.0;

	// new target
	// if( g_targetid )
	// 	target = g_targetid
	// else
	// 	target = isPlayerNearby(id, 1200.0)

	static Float:idVec[3], Float:tarVec[3]

	new target = g_targetid

	if( target )
	{
		pev(id, pev_origin, idVec)
		pev(target, pev_origin, tarVec)

		if( get_distance_f(idVec, tarVec) <= 1000.0 )
		{
			if( gamtime >= nextskill ) {
				nextskill = gamtime + skill_times
				new i = random_num(0, 100)
				switch(i) {
					case 0: use_firestar(id)
					case 1..26: use_moonbreak(id)
					case 27..52: use_moonsword(id)
					case 53..65: use_chanmo(id)
					case 66..100: use_icewing(id)
				}
			}
		}

		if( gamtime >= nextlong ) {
			nextlong = gamtime + long_times
			this_longjump(id, target)
		}

	}

	return FMRES_IGNORED;
}

public fw_PlayerSpawn_Post(id)
{
	if (is_user_bot(id) && id == bossid ) {
		set_pev(id, pev_health, 10000.0)
		get_refknife(id)
		if(!get_element_status(id))
			use_enchant(id)
	}
	
	if( is_user_connected(id) && !is_user_bot(id) ) {
		set_pev(id, pev_health, 300000.0)
	}

	if( id == bossid ) {
		if( g_targetid ) 
			g_targetid = 0
	}
	return HAM_IGNORED;
}

stock isPlayerNearby(id, Float:diss=700.0)
{
	new flags = 0
	static Flaot:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	new victim = FM_NULLENT
	while( (victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, diss) ) != 0 ) {

		if(!is_user_alive(victim) || id == victim || is_user_bot(victim) )
			continue

		flags = victim
		break
	}
	return flags
}

stock set_next_attacktime(id, weaponEnt, Float:time)
{
	set_pdata_float(weaponEnt, m_flNextPrimaryAttack, time, 4)
	set_pdata_float(weaponEnt, m_flNextSecondaryAttack, time, 4)
	set_pdata_float(id, m_flNextAttack, time, 5) 
}

stock this_longjump(id, target) {

	new Float:targetOrigin[3], Float:botOrigin[3]
	new Float:velocity[3];

	pev(id, pev_origin, botOrigin)
	pev(target, pev_origin, targetOrigin)

	get_speed_vector(botOrigin, targetOrigin, 2500.0, velocity)
	// velocity[2] = 20.0;
	set_pev(id, pev_velocity, velocity);
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) ) 
		return FMRES_IGNORED
	
	new Float:game_time = get_gametime()
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)

	static Float:nextJumpTime[33]
	if( (CurButton & IN_JUMP) && (CurButton & IN_DUCK) ) {

		if( game_time >= nextJumpTime[id] ) {

			fm_set_user_godmode(id, 1)

			engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
			write_short(1<<10); // Duration --> Note: Duration and HoldTime is in special units. 1 second is equal to (1<<12) i.e. 4096 units.
			write_short(1<<11); // Holdtime
			write_short(0x0000); // 0x0001 Fade in
			write_byte(0);
			write_byte(255);
			write_byte(0);
			write_byte(20);  // Alpha
			message_end();

			set_task(0.7, "disableGodmode", id)
			nextJumpTime[id] = game_time + 1.0;
		}
	}
	return FMRES_IGNORED
}

public disableGodmode(id)
{
	fm_set_user_godmode(id, 0)
}

stock fm_set_user_godmode(index, godmode = 0) {
	set_pev(index, pev_takedamage, godmode == 1 ? DAMAGE_NO : DAMAGE_AIM);
	return 1;
}

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	return 1
}