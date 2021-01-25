#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <xs>
#include <vector>

new gKeysMainMenu;

new const gClassname[] = "func_haachama"

enum
{
	N1, N2, N3, N4, N5, N6, N7, N8, N9, N0
};

enum
{
	B1 = 1 << N1, B2 = 1 << N2, B3 = 1 << N3, B4 = 1 << N4, B5 = 1 << N5,
	B6 = 1 << N6, B7 = 1 << N7, B8 = 1 << N8, B9 = 1 << N9, B0 = 1 << N0,
};

new const gInfoTarget[] = "info_target"
new gszMainMenu[200];

new const gHaachamaModel[] = "models/haachama/haachama.mdl"

new bool:g_stealth[33];
new bool:headshot[33];
new bool:dmg_reflection[33];

new poop;
new wave;


public plugin_init()
{
	register_plugin("hax", "1.0", "Ako");

	register_clcmd("hax", "showMenu");

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");

	createMenu();

	register_menucmd(register_menuid("haxMainMenu"), gKeysMainMenu, "handleMainMenu");
}

public plugin_precache()
{
	precache_model(gHaachamaModel);
	poop = engfunc(EngFunc_PrecacheModel, "models/winebottle.mdl");
	wave = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr");
}

createMenu()
{
	new size = sizeof(gszMainMenu);
	add(gszMainMenu, size, "\w大便雞雞尿尿 ^n^n");
	add(gszMainMenu, size, "\r1. \waimbot: %s ^n");
	add(gszMainMenu, size, "\r2. \w反射傷害: %s ^n");
	add(gszMainMenu, size, "\r3. \w隱身: %s ^n^n");
	add(gszMainMenu, size, "\r4. \w召喚哈洽馬 ^n^n^n");
	add(gszMainMenu, size, "\r0. \wClose");
	gKeysMainMenu = B1 | B2 | B3 | B4 | B0

}

public showMenu(id){
	new menu[200];
	new Aimbot[6];
	new Dmgreflection[6];
	new Stealth[6];
	Aimbot = (headshot[id] ? "\yOn" : "\rOff");
	Dmgreflection = (dmg_reflection[id] ? "\yOn" : "\rOff");
	Stealth = (g_stealth[id] ? "\yOn" : "\rOff");

	format(menu, 200, gszMainMenu, Aimbot, Dmgreflection, Stealth);

	show_menu(id, gKeysMainMenu, menu, -1, "haxMainMenu");

	return PLUGIN_HANDLED;
}

public handleMainMenu(id, num){
	switch(num){
		case N1: { toggleAimbot(id); }
		case N2: { toggleDmgreflection(id); }
		case N3: { toggleStealth(id); }
		case N4: { summonHaachamaAiming(id); }
		case N0: { return; }
	}

	if(num != N5 && num != N6 && num != N7 && num != N8 && num != N9){
		showMenu(id);
	}
}

toggleAimbot(id){
	if(headshot[id]) headshot[id] = false;
	else headshot[id] = true;
}

toggleDmgreflection(id){
	if(dmg_reflection[id]) dmg_reflection[id] = false;
	else dmg_reflection[id] = true;
}

toggleStealth(id){
	if(g_stealth[id] && is_user_alive(id)){
		g_stealth[id] = false;
		Stealth_On(id);
	}
	else{
		g_stealth[id] = true;
		Stealth_Off(id);
	}
}

summonHaachamaAiming(id){
	new Origin[3];
	new Float:vOrigin[3];

	get_user_origin(id, Origin, 3);
	IVecFVec(Origin, vOrigin);
	vOrigin[2] += 36.0;

	summonHaachama(vOrigin);
}

summonHaachama(Float:vOrigin[3])
{
	new ent = create_entity(gInfoTarget);

	entity_set_string(ent, EV_SZ_classname, gClassname);
	entity_set_model(ent, gHaachamaModel);
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	entity_set_size(ent, Float:{-16.0, -16.0, -36.0}, Float:{16.0, 16.0, 36.0});
	entity_set_origin(ent, vOrigin);

	entity_set_float(ent,EV_FL_takedamage, 1.0);
	entity_set_float(ent,EV_FL_health, 100.0);

	entity_set_float(ent,EV_FL_animtime, 2.0);
	entity_set_float(ent,EV_FL_framerate, 1.0);
	entity_set_int(ent,EV_INT_sequence, 3);
}

Stealth_On(id)
	fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);

Stealth_Off(id)
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