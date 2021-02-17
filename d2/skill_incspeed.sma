#include <amxmodx>
#include <d2lod>
#include <fakemeta>
#include <fun>

new PLUGIN_NAME[] = "疾風行走"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

new Skill_Level = 45;

new const Float:BarSpeed[MAX_P_SKILLS] =  // 野蠻人加速的百分比.
{
	15.0, 17.0, 19.0, 23.0, 25.0, 27.0, 29.0, 31.0, 33.0, 35.0, 37.0, 39.0, 41.0, 43.0, 44.0, 55.0, 66.0, 77.0, 98.0, 120.0
};


new g_SkillId;

new g_iCurSkill[33];

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	g_SkillId = register_d2_skill(PLUGIN_NAME, "增加移動速度.", COMBAT, Skill_Level, NOT_DISPLAY)

	register_forward(FM_PlayerPreThink, "fwd_PreThink")
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
	if ( !is_user_alive(id) || is_freezetime() ) return;
	
	if( get_p_hero(id) == COMBAT || get_p_hero(id) == HAYATO || get_p_hero(id) == MAKO ) {

		if ( get_p_skill( id, g_SkillId ) > 0 )
			set_user_maxspeed(id, get_current_speed(id) + ( ( get_current_speed(id) / 100 ) * BarSpeed[ get_p_skill( id, g_SkillId ) - 1 ] ) );
	}
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