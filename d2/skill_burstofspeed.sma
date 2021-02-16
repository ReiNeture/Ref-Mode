#include <amxmodx>
#include <d2lod>
#include <fakemeta>
#include <hamsandwich>
#include <fun>

new PLUGIN_NAME[] = "速度激發"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

new Skill_Level = 33;
new Mana_Speed = 7;

new const Float:AssBrstDur[MAX_P_SKILLS] =  // 刺客速度激發持續時間.
{
	20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0, 	170.0, 200.0, 230.0, 240.0, 250.0, 300.0, 301.0, 400.0
};
new const Float:AssBrstSpeed[MAX_P_SKILLS] =  // 刺客速度激發的速度值.
{
	43.0, 49.0, 54.0, 59.0, 62.0, 65.0, 70.0, 73.0, 77.0, 80.0, 83.0, 86.0, 	89.0, 92.0, 95.0, 98.0, 100.0, 103.0, 105.0, 117.0
};
new const Float:AssBrstAtSpeed[MAX_P_SKILLS] =  // 刺客速度激發的攻擊冷卻時間.
{
	0.50, 
	0.49, 
	0.48, 
	0.47, 
	0.46, 
	0.45, 
	0.40, 
	0.39, 
	0.37, 
	0.35, 
	0.34, 
	0.33, 
	0.32, 	
	0.31, 
	0.30, 
	0.29, 
	0.28, 
	0.27, 
	0.26, 
	0.25
}

#define TASKID_BRST 15444

new g_SkillId;

const m_pPlayer	= 41;
const m_flPrimaryAttack = 46;

new Float:g_LastPressedSkill[33];
new g_iCurSkill[33];
new bool: g_IsBurstOfSpeed[33];
new g_iMaxPlayers;

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	// 87 112 注意
	g_SkillId = register_d2_skill(PLUGIN_NAME, "增加攻擊速度跟移動速度.", 99, Skill_Level, DISPLAY)

	register_forward(FM_PlayerPreThink, "fwd_PreThink")
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn", 1);
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

public fwd_PreThink(id)
{
	if ( !is_user_alive(id) || is_freezetime() )
		return;

	if ( g_IsBurstOfSpeed[id] && get_p_hero(id) == 99 && get_p_skill( id, g_SkillId ) > 0 )
	{
		set_user_maxspeed(id, get_current_speed(id) + ( ( get_current_speed(id) / 100 ) * AssBrstSpeed[ get_p_skill( id, g_SkillId ) - 1 ] ) );
	}
}
public fwd_PlayerSpawn(id)
{
	if ( !is_user_alive(id) )
		return;

	remove_task( id + TASKID_BRST );

	if ( g_IsBurstOfSpeed[id] )
	{
		g_IsBurstOfSpeed[id] = false;
	}
}
public fwd_AttackSpeed ( const Entity )
{
	if ( !pev_valid(Entity) ) return HAM_IGNORED;

	static id ; id = get_pdata_cbase(Entity, m_pPlayer, 4)
	
	if ( ( 1 <= id <= g_iMaxPlayers ) ) 
	{
		if ( get_p_skill( id, g_SkillId ) > 0 && g_IsBurstOfSpeed[id] && get_p_hero(id) == 99 ) 
		{ 
			set_pdata_float( Entity, m_flPrimaryAttack, AssBrstAtSpeed[ get_p_skill( id, g_SkillId ) - 1 ], 4 ); 
		} 
	}
	
	return HAM_IGNORED;
}

public d2_skill_fired(id)
{
	if ( g_iCurSkill[id] == g_SkillId )
	{
		static Float:cdown;
		cdown = 3.0;

		if (get_gametime() - g_LastPressedSkill[id] <= cdown) 
		{
			return PLUGIN_HANDLED;
		}
		else if ( get_gametime() - g_LastPressedSkill[id] >= cdown )
		{
			g_LastPressedSkill[id] = get_gametime()
		}

		if ( get_p_skill( id, g_SkillId ) > 0 && get_p_mana(id) >= Mana_Speed )
		{
			set_p_mana(id, get_p_mana(id) - Mana_Speed );

			remove_task(id + TASKID_BRST);

			g_IsBurstOfSpeed[id] = true;set_task(AssBrstDur[ get_p_skill( id, g_SkillId ) - 1 ], "Reset_Brst", id + TASKID_BRST);
		}
	}
	
	return PLUGIN_CONTINUE;
}
public Reset_Brst(id)
{
	id -= TASKID_BRST;

	if ( !( 1 <= id <= g_iMaxPlayers ) )
		return;

	g_IsBurstOfSpeed[id] = false;

	remove_task( id + TASKID_BRST );
}

public d2_logged(id, log_type)
{
	if ( log_type == UNLOGGED )
	{

	}
}