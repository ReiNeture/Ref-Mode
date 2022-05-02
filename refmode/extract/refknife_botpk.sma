#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

native get_refknife(id);
native use_firestar(id);
native use_moonsword(id);
native use_enchant(id);
native use_moonbreak(id);
native use_chanmo(id);
native get_element_status(id);
native use_icewing(id);
native use_flyknife(id);

new boss_ct = 0, boss_t = 0
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flNextIdle 48
#define m_flNextAttack 83
public plugin_init()
{
	register_plugin("Ref knife bot", "1.0", "Reff")
	register_forward(FM_PlayerPreThink, "fw_playerPreThink");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Weapon_PrimaryAttack", 1)
}

#define pDataKey_iOwner 41
#define pData_Item 4
public fw_Weapon_PrimaryAttack(ent)
{
	static id
	id = get_pdata_cbase(ent, pDataKey_iOwner, pData_Item)

	if( !is_user_alive(id) || id != boss_ct || id != boss_t )
		return HAM_IGNORED

	set_next_attacktime(id, ent, 0.05) // 附魔後攻速

	return HAM_IGNORED
}

public client_putinserver(id)
{
    if( !is_user_bot(id) )
		return PLUGIN_CONTINUE

	return PLUGIN_CONTINUE
}
public client_disconnected(id)
{
	if(id == boss_ct)
		boss_ct = 0
	if(id == boss_t)	
		boss_t = 0
}

public fw_playerPreThink(id)
{
	if( !is_user_alive(id) || !is_user_bot(id) ) 
		return FMRES_IGNORED
	if( id != boss_ct && id != boss_t ) 
		return FMRES_IGNORED

	static Float:nextthink[33], Float:nextskill[33], Float:nextlong[33]
	static Float:gamtime; gamtime = get_gametime()
	if( nextthink[id] > gamtime )
		return FMRES_IGNORED

	nextthink[id] = gamtime + 0.2
	new Float:skill_times = 1.0;
	new Float:long_times = 0.2;

	static Float:idVec[3], Float:tarVec[3]
	new target = (id == boss_ct ? boss_t : boss_ct )

	if( target )
	{
		pev(id, pev_origin, idVec)
		pev(target, pev_origin, tarVec)

		if( get_distance_f(idVec, tarVec) <= 1000.0 )
		{
			if( gamtime >= nextskill[id] ) {
				nextskill[id] = gamtime + skill_times
				new i = random_num(0, 100)
				switch(i) {
					case 0: use_firestar(id)
					case 1..26: use_moonbreak(id)
					case 27..52: use_moonsword(id)
					case 53..65: use_chanmo(id)
					case 66..85: use_icewing(id)
					case 86..100: use_flyknife(id)
				}
			}
		}

		if( gamtime >= nextlong[id] ) {
			nextlong[id] = gamtime + long_times
			this_longjump(id, target)
		}

	}

	return FMRES_IGNORED;
}

public fw_PlayerSpawn_Post(id)
{
	if ( !is_user_bot(id) ) {
		set_pev(id, pev_health, 300000.0)
		return HAM_IGNORED;
	}

	if( !boss_ct && cs_get_user_team(id) == CS_TEAM_CT )
		boss_ct = id
	if( !boss_t && cs_get_user_team(id) == CS_TEAM_T )
		boss_t = id

	if( id == boss_ct || id == boss_t ) {
		set_pev(id, pev_health, 300000.0)
		get_refknife(id)
		if(!get_element_status(id))
			use_enchant(id)
	}
	return HAM_IGNORED;
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