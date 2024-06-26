#include <amxmodx>
#include <d2lod>
#include <fakemeta>
#include <engine>

new PLUGIN_NAME[] = "跳躍攻擊"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

new Skill_Level = 61;
new Mana_Leap = 5;

new const Float:BarLeapDmg[MAX_P_SKILLS] =  // 野蠻人跳躍攻擊的傷害.
{
	30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0, 140.0, 	150.0, 160.0, 170.0, 180.0, 190.0, 200.0, 210.0, 220.0
};

new const BarbarianWarCry[] = "d2lod/leapattack.wav";
new const g_SpriteWarCry[] = "sprites/shockwave.spr";

new g_SkillId;

new Float:g_LastPressedSkill[33];
new bool:Not_Landed[33];
new g_iCurSkill[33];
new g_spriteShockwave;
new g_iMaxPlayers;

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	g_SkillId = register_d2_skill(PLUGIN_NAME, "跳躍後著地並對敵人造成傷害.", COMBAT, Skill_Level, DISPLAY)

	register_forward(FM_PlayerPreThink, "fwd_PreThink")
	register_event("DeathMsg", "ev_DeathMsg", "a")

	g_iMaxPlayers = get_maxplayers();
}

public ev_DeathMsg()
{
	Not_Landed[ read_data(2) ] = false;
}

public plugin_precache()
{
	g_spriteShockwave = precache_model( g_SpriteWarCry );
	precache_sound( BarbarianWarCry );
}

public client_disconnect(id)
{
	Not_Landed[id] = false;
}

public d2_skill_selected(id, skill_id)
{
	g_iCurSkill[id] = skill_id
}

public fwd_PreThink(id)
{
	if ( !is_user_alive(id) || is_freezetime() )
		return;

	if ( Not_Landed[id] && (get_entity_flags(id) & FL_ONGROUND) )
	{
		Not_Landed[id] = false;

		new Float: Porigin[3], Float: Torigin[3], Float: Distance, iOrigin[3];

		entity_get_vector( id, EV_VEC_origin, Porigin);
					
		iOrigin[0] = floatround(Porigin[0]);
		iOrigin[1] = floatround(Porigin[1]);
		iOrigin[2] = floatround(Porigin[2]);

		message_begin( MSG_PAS, SVC_TEMPENTITY, iOrigin );
		write_byte( TE_BEAMCYLINDER );
		engfunc( EngFunc_WriteCoord, Porigin[0]);
		engfunc( EngFunc_WriteCoord, Porigin[1]);
		engfunc( EngFunc_WriteCoord, Porigin[2] - 16.0);
		engfunc( EngFunc_WriteCoord, Porigin[0]);
		engfunc( EngFunc_WriteCoord, Porigin[1]);
		engfunc( EngFunc_WriteCoord, Porigin[2] - 16.0 + 150.0);
		write_short( g_spriteShockwave );
		write_byte( 0 );	// 幀幅開始.
		write_byte( 0 );	// 幀幅頻率.
		write_byte( 3 );	// 時間長度.
		write_byte( 12 );	// 寬度.
		write_byte( 0 );	// 響聲.
		write_byte( 255 );  // 顏色 R.
		write_byte( 90 );  // 顏色 G.
		write_byte( 0 );  // 顏色 B.
		write_byte( 255 );	// 顏色亮度.
		write_byte( 8 );	// 速度.
		message_end();

		for(new enemy = 1; enemy <= g_iMaxPlayers; enemy++) 
		{
			if ( is_user_alive(enemy) && id != enemy )
			{
				entity_get_vector( enemy, EV_VEC_origin, Torigin);

				Distance = get_distance_f(Porigin, Torigin);

				if ( Distance <= 135.0 && !IsPlayerNearByMonster(enemy) && !is_p_protected(enemy) )
				{
					dmg_kill_player(enemy, id, BarLeapDmg[ get_p_skill( id, g_SkillId ) - 1 ], "leapattack");
				}
			}
		}
	}
}

public d2_skill_fired(id)
{
	if ( g_iCurSkill[id] == g_SkillId )
	{
		static Float:cdown;
		cdown = 5.0;

		if (get_gametime() - g_LastPressedSkill[id] <= cdown) 
		{
			return PLUGIN_HANDLED;
		}
		else if ( get_gametime() - g_LastPressedSkill[id] >= cdown )
		{
			g_LastPressedSkill[id] = get_gametime()
		}

		if ( get_p_skill( id, g_SkillId ) > 0 && get_p_mana(id) >= Mana_Leap && get_entity_flags(id) & FL_ONGROUND && !Not_Landed[id] )
		{
			emit_sound(id, CHAN_ITEM, BarbarianWarCry, 1.0, ATTN_NORM, 0, PITCH_NORM);

			set_p_mana(id, get_p_mana(id) - Mana_Leap );

			static Float: velocity[3];

			velocity_by_aim(id, 400, velocity);
			velocity[2] = 500.0;
			set_pev(id, pev_velocity, velocity);

			set_task( 0.1, "Task_Leap", id);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public d2_logged(id, log_type)
{
	if ( log_type == UNLOGGED )
	{
		Not_Landed[id] = false;
	}
}
public Task_Leap(id)
{
	if ( !is_user_alive(id) )
		return;

	Not_Landed[id] = true;
}