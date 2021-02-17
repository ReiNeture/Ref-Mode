#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <d2lod>

new PLUGIN_NAME[] = "魔力激發"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

new Skill_Level = 31;

new const AmazonEvade[MAX_P_SKILLS] =  // 每0.5秒回復輛
{
	1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 8, 10
};

new g_SkillId;

new g_iCurSkill[33];
new Float:g_manatime[33];

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_forward(FM_PlayerPreThink, "fwd_PreThink")
	g_SkillId = register_d2_skill(PLUGIN_NAME, "移動時快速回復魔力.", SPELLS, Skill_Level, NOT_DISPLAY)
}

public d2_skill_selected(id, skill_id)
{
	g_iCurSkill[id] = skill_id
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

public fwd_PreThink(id)
{
	if ( !is_user_alive(id) ) return FMRES_IGNORED;

	if( halflife_time() >= g_manatime[id] ) {
		if ( IsPlayerMoving(id) && (get_p_hero(id) == SPELLS ||get_p_hero(id) == ELEMENT||get_p_hero(id) == MAGIC)  && get_p_skill( id, g_SkillId ) > 0 && get_p_mana(id) < get_p_maxmana(id))
		{
			new add = get_p_mana(id) + AmazonEvade[ get_p_skill(id, g_SkillId ) - 1 ]
			set_p_mana(id, add);
			g_manatime[id] = halflife_time() + 0.5
		}
	}

	return FMRES_HANDLED;
}

// public d2_takedamage(victim, attacker, Float:iDamage[1])
// {
// 	if ( is_user_alive(victim) && get_p_hero(victim) == AMAZON && get_p_skill( victim, g_SkillId ) > 0 && random_num( 0, 100 ) < AmazonEvade[ get_p_skill( victim, g_SkillId ) - 1 ] && IsPlayerMoving(victim) )
// 	{
// 		iDamage[0] = 0.0;
// 	}
// }
// public d2_ranged_takedamage(victim, attacker, Float:iDamage[1])
// {
// 	if ( is_user_alive(victim) && get_p_hero(victim) == AMAZON && get_p_skill( victim, g_SkillId ) > 0 && random_num( 0, 100 ) < AmazonEvade[ get_p_skill( victim, g_SkillId ) - 1 ] && IsPlayerMoving(victim) )
// 	{
// 		iDamage[0] = 0.0;
// 	}
// }
public bool:IsPlayerMoving( id )
{
	new Float:Velo[3];
	get_user_velocity( id, Velo);

	if ( Velo[0] > 0.0 || Velo[1] > 0.0 || Velo[2] > 0.0 )
		return true;

	return false;
}