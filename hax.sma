#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <xs>
#include <vector>


new bool:g_stealth[33];
new bool:headshot[33];
new bool:dmg_reflection[33];

new poop, wave;

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

public plugin_init()
{
	register_plugin("dafuq", "1.0", "Ako");

	register_clcmd("bored", "forfun");

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");

	register_menu("FUNMENU", KEYSMENU, "Funn_menu");
}

public plugin_precache()
{
	poop = engfunc(EngFunc_PrecacheModel, "models/winebottle.mdl");
	wave = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr");
}

public forfun(id)
{
	new menu[200], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w大便雞雞尿尿 ^n^n");
	if(!headshot[id])
		len += formatex(menu[len], charsmax(menu) - len, "\w1.aimbot ^n");
	else if(headshot[id])
		len += formatex(menu[len], charsmax(menu) - len, "\r1.aimbot ^n");
	if(!dmg_reflection[id])
		len += formatex(menu[len], charsmax(menu) - len, "\w2.反射傷害 ^n");
	else if(dmg_reflection[id])
		len += formatex(menu[len], charsmax(menu) - len, "\r2.反射傷害 ^n");
	if(!g_stealth[id])
		len += formatex(menu[len], charsmax(menu) - len, "\w3.隱身 ^n");
	else if(g_stealth[id])
		len += formatex(menu[len], charsmax(menu) - len, "\r3.隱身 ^n");

	show_menu(id, KEYSMENU, menu, -1, "FUNMENU");
	return PLUGIN_HANDLED;
}

public Funn_menu(id, key)
{
	switch(key)
	{
		case 0:
		{
			if(!headshot[id])
			{
				headshot[id] = true;
				forfun(id);
			}
			else if(headshot[id])
			{
				headshot[id] = false;
				forfun(id);
			}
		}
		case 1:
		{
			if(!dmg_reflection[id]){
				dmg_reflection[id] = true;
				forfun(id);
			}
			else if(dmg_reflection[id]){
				dmg_reflection[id] = false;
				forfun(id);
			}
		}
		case 2:
		{
			if(!g_stealth[id] && is_user_alive(id)){
				g_stealth[id] = true;
				Stealth_Off(id);
				forfun(id);
			}
			else if(g_stealth[id] && is_user_alive(id)){
				g_stealth[id] = false;
				Stealth_On(id);
				forfun(id);
			}
		}
	}
}

public Stealth_On(id)
	fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);

public Stealth_Off(id)
	fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);


public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (headshot[attacker] == true)
	{
		if (get_tr2(tracehandle, TR_iHitgroup) != HIT_HEAD) set_tr2(tracehandle, TR_iHitgroup, HIT_HEAD);
	}
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) && !is_user_connected(id))
		return PLUGIN_HANDLED;

	if(g_stealth[id])
	{
		Stealth_On(id);
	}

	return PLUGIN_HANDLED;
}

public fw_TakeDamage(victim, inflictor, attacker, damage, damagebits){
	if(attacker == victim || !is_user_connected(attacker))
		return HAM_IGNORED;

	new victim_origin[3];
	get_user_origin(victim, victim_origin, 0);
	new Float:victim_aim[3], Float:originF[3], Float:scalar = -1.0, Float:attacker_origin[3];
	velocity_by_aim(victim, 50, victim_aim);
	xs_vec_mul_scalar(victim_aim, scalar, originF);
	pev(attacker, pev_origin, attacker_origin);

	if(dmg_reflection[victim]){
		ExecuteHam(Ham_TakeDamage, attacker, victim, victim, damage,  DMG_TIMEBASED);

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
		write_byte(TE_MODEL);
		write_coord(victim_origin[0]); //x
		write_coord(victim_origin[1]); //y
		write_coord(victim_origin[2]); //z
		engfunc(EngFunc_WriteCoord, originF[0]); //velocity x
		engfunc(EngFunc_WriteCoord, originF[1]); //velocity y
		engfunc(EngFunc_WriteCoord, originF[2]); //velocity z
		write_angle(0);
		write_short(poop);
		write_byte(2); //bounceSound 0 : No Sound 1 : Bullet casing 2 : Shotgun shell
		write_byte(10); //life sec*0.1
		message_end();

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, attacker_origin, 0);
		write_byte(TE_BEAMCYLINDER);
		engfunc(EngFunc_WriteCoord, attacker_origin[0]); // x 
		engfunc(EngFunc_WriteCoord, attacker_origin[1]); // y 
		engfunc(EngFunc_WriteCoord, attacker_origin[2]); // z 
		engfunc(EngFunc_WriteCoord, attacker_origin[0]); // x axis (X 軸)
		engfunc(EngFunc_WriteCoord, attacker_origin[1]); // y axis (Y 軸)
		engfunc(EngFunc_WriteCoord, attacker_origin[2]+400.0); // z axis (Z 軸)
		write_short(wave)
		write_byte(0); // startframe (幀幅開始)
		write_byte(0); // framerate (幀幅頻率)
		write_byte(3); // life 
		write_byte(30); // width 
		write_byte(0); // noise 
		write_byte(235); // r
		write_byte(0); // g
		write_byte(0); // b 
		write_byte(50); // brightness 
		write_byte(0); // speed 
		message_end()

	}
	return HAM_IGNORED;
}

stock fm_set_rendering(id, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3];
	color[0] = float(r);
	color[1] = float(g);
	color[2] = float(b);
	
	set_pev(id, pev_renderfx, fx);
	set_pev(id, pev_rendercolor, color);
	set_pev(id, pev_rendermode, render);
	set_pev(id, pev_renderamt, float(amount));
}