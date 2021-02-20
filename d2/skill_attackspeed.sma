#include <amxmodx>
#include <d2lod>
#include <fakemeta>
#include <hamsandwich>
#include <fun>

new PLUGIN_NAME[] = "速度激發"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

new Skill_Level = 82;

new const Float:AssBrstAtSpeed[MAX_P_SKILLS] =  // 刺客速度激發的攻擊冷卻時間.
{
	0.75, 
	0.72, 
	0.68, 
	0.65, 
	0.64, 
	0.60, 
	0.57, 
	0.55, 
	0.54, 
	0.52, 
	0.50, 
	0.46, 
	0.45, 	
	0.40, 
	0.38, 
	0.36, 
	0.33, 
	0.30, 
	0.25, 
	0.19
}

#define TASKID_BRST 15444

new g_SkillId;

const m_pPlayer	= 41;
const m_flPrimaryAttack = 46;

new g_iCurSkill[33];
new g_iMaxPlayers;

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	g_SkillId = register_d2_skill(PLUGIN_NAME, "永久增加攻擊速度", MAKO, Skill_Level, NOT_DISPLAY)

	RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_knife", "fwd_AttackSpeed" , 1 );
	RegisterHam( Ham_Item_Deploy , "weapon_knife", "fwd_AttackSpeed", 1);

	g_iMaxPlayers = get_maxplayers();
}

public client_disconnect(id)
{
	
}

public d2_skill_selected(id, skill_id)
{
	g_iCurSkill[id] = skill_id
}

public fwd_AttackSpeed ( const Entity )
{
	if ( !pev_valid(Entity) ) return HAM_IGNORED;

	static id ; id = get_pdata_cbase(Entity, m_pPlayer, 4)
	
	if ( ( 1 <= id <= g_iMaxPlayers ) ) 
	{
		if ( get_p_skill( id, g_SkillId ) > 0 && get_p_hero(id) == MAKO ) 
			set_pdata_float( Entity, m_flPrimaryAttack, AssBrstAtSpeed[ get_p_skill( id, g_SkillId ) - 1 ], 4 ); 
	}
	
	return HAM_IGNORED;
}

public d2_skill_fired(id)
{
}

public d2_logged(id, log_type)
{
	if ( log_type == UNLOGGED )
	{

	}
}