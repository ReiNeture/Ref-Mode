#include <amxmodx>
#include <d2lod>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

new PLUGIN_NAME[] = "躍進"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

new Skill_Level = 73;

new const ChargeCast[] = "d2lod/charge.wav";

new const PalChDistance[MAX_P_SKILLS] = 
{
	195, 220, 250, 270, 300, 330, 360, 390, 400, 430, 440, 470, 490, 500, 520, 550, 580, 640, 670, 700
};
new const Float:PalChHeight[MAX_P_SKILLS] = 
{
	100.0, 100.0, 115.0, 125.0, 140.0, 
	155.0, 170.0, 185.0, 190.0, 205.0, 
	210.0, 225.0, 235.0, 240.0, 250.0, 
	265.0, 280.0, 310.0, 325.0, 345.0
};

#define CHARGE_DELAY 3.0

#define TASKID_CHARGE 140

new g_SkillId;

new g_iCurSkill[33];

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	register_forward(FM_CmdStart, "fw_cmdstart");

	g_SkillId = register_d2_skill(PLUGIN_NAME, "按下蹲跟跳向前快速移動", MAKO, Skill_Level, NOT_DISPLAY)

}

public plugin_precache()
{
	precache_sound( ChargeCast );
}

public fw_cmdstart(id)
{
	if( !is_user_connected(id) || !is_user_connected(id) ) return FMRES_IGNORED;
	if( get_p_hero(id) != MAKO || get_p_skill( id, g_SkillId ) <= 0 ) return FMRES_IGNORED;
	
	static button;
	static Float:last_time[33];
	button = pev(id, pev_button);

	if( halflife_time() - last_time[id] >= 0.3 ) {

		if((button & IN_JUMP) && (button & IN_DUCK)) {

			static Float:velocity[3];
			velocity_by_aim(id, PalChDistance[ get_p_skill(id, g_SkillId) - 1 ], velocity);
			velocity[2] = PalChHeight[ get_p_skill(id, g_SkillId) - 1 ];
			set_pev(id, pev_velocity, velocity);
			
			last_time[id] = halflife_time();
		}
	}
	return FMRES_HANDLED;
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

}