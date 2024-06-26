#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <messages>
#include <fun>
#include <xs>
#include <vector>

new gKeysMainMenu;

enum
{
	N1, N2, N3, N4, N5, N6, N7, N8, N9, N0
};

enum
{
	B1 = 1 << N1, B2 = 1 << N2, B3 = 1 << N3, B4 = 1 << N4, B5 = 1 << N5,
	B6 = 1 << N6, B7 = 1 << N7, B8 = 1 << N8, B9 = 1 << N9, B0 = 1 << N0,
};

const BallSpeed = 2000	
const Float:BallDamage = 250.0
const Float:BallRadiusExplode =	130.0

new const gInfoTarget[] = "env_sprite"; // info_target
new const gClassname[] = "func_haachama"; //func_haachama
new const gDickClassName[] = "my_dick";
new const gBallClassname[] = "Entball";

new gszMainMenu[200];

new const gCam[] = "models/ref/cam.mdl";
new const gAicore[] = "models/ref/w_aicore.mdl";
new const gHaachamaModel[] = "models/haachama/haachama.mdl";
new const gDickModel[] = "models/ref/dick.mdl";
new const gszAquaSound[] = "ref/AkaihaatoRemixZ.wav";
new const gszPortalSound[] = "ref/portal_ambient_loop1.wav"; // 4.665sec
new const gszAquaMahuo[] = "sprites/ref/aqua.spr";
new const gzHomura[] = "ref/homura.wav";
new const BallSprites[2][] =
{
	"sprites/gBall/gball.spr",		
	"sprites/gBall/gbomb.spr"		
}
new const gTreasureModel[4][] =
{
	"models/w_ak47.mdl",
	"models/w_m4a1.mdl",
	"models/w_ump45.mdl",
	"models/w_scout.mdl"
} 

const MAXDICK = 30;

new bool:g_stealth[33];
new bool:headshot[33];
new bool:dmg_reflection[33];
new Float:hachamaTimer[512];
new Float:fTreasureCd[33];

new gDisplayAqua[33];
new gHaveDick[33][MAXDICK];
new gCurrentDick[33];

new poop;
new wave;
new ball;
new smoke, exp;

public plugin_init()
{
	register_plugin("hax", "1.0", "Ako");

	register_clcmd("hax", "showMenu");
	register_clcmd("aqua", "throwAqua");

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Touch, gInfoTarget, "TouchDick");

	register_forward(FM_CmdStart, "fw_cmdstart");

	register_touch(gClassname, "player", "TouchHachama");

	register_think(gClassname, "hachamaThink");
	register_think(gDickClassName, "dickThink");
	register_think("AquaBody", "aquaBodyThink");

	createMenu();

	register_menucmd(register_menuid("haxMainMenu"), gKeysMainMenu, "handleMainMenu");
}

public plugin_precache()
{
	precache_model(gDickModel);
	precache_model(gHaachamaModel);
	precache_model(gszAquaMahuo);
	precache_model(gCam);
	precache_model(gAicore);
	precache_sound(gszAquaSound);
	precache_sound(gzHomura);
	precache_sound(gszPortalSound);
	smoke = precache_model("sprites/steam1.spr");
	exp = precache_model("sprites/ref/whiteexp.spr");
	poop = engfunc(EngFunc_PrecacheModel, "models/winebottle.mdl");
	wave = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr");
	ball = precache_model(BallSprites[1]);

	for(new i = 0; i < sizeof BallSprites; i++)
		precache_model(BallSprites[i]);
}

public fw_cmdstart(id, uc_handle, seed)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	static button;
	button = get_uc(uc_handle, UC_Buttons);

	if (button & IN_USE && (pev(id, pev_oldbuttons) & IN_USE))
	{
		createDick(id);
		return FMRES_HANDLED;

	} else if ( !(button & IN_USE) && (pev(id, pev_oldbuttons) & IN_USE)) {
		doDick(id);
		client_print(id, print_chat, "Relase");
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

createMenu()
{
	new size = sizeof(gszMainMenu);
	add(gszMainMenu, size, "\w大便雞雞尿尿 ^n^n");
	add(gszMainMenu, size, "\r1. \waimbot: %s ^n");
	add(gszMainMenu, size, "\r2. \w反射傷害: %s ^n");
	add(gszMainMenu, size, "\r3. \w隱身: %s ^n^n");
	add(gszMainMenu, size, "\r4. \w召喚哈洽馬 ^n");
	add(gszMainMenu, size, "\r5. \w色情球球 ^n");
	add(gszMainMenu, size, "\r6. \wDick ^n");
	add(gszMainMenu, size, "\r0. \wClose");
	gKeysMainMenu = B1 | B2 | B3 | B4 | B5 | B6 | B0;

}

public showMenu(id)
{
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

public handleMainMenu(id, num)
{
	switch(num){
		case N1: { toggleAimbot(id); }
		case N2: { toggleDmgreflection(id); }
		case N3: { toggleStealth(id); }
		case N4: { summonHaachamaAiming(id); }
		case N5: { createBall(id); }
		case N6: { createDick(id); }
		case N0: { return; }
	}

	if(num != N7 && num != N8 && num != N9)
		showMenu(id);
}

toggleAimbot(id)
{
	if(headshot[id]) headshot[id] = false;
	else headshot[id] = true;
}

toggleDmgreflection(id)
{
	if(dmg_reflection[id]) dmg_reflection[id] = false;
	else dmg_reflection[id] = true;
}

toggleStealth(id)
{
	if(g_stealth[id] && is_user_alive(id)){
		g_stealth[id] = false;
		Stealth_On(id);
	}
	else{
		g_stealth[id] = true;
		Stealth_Off(id);
	}
}

summonHaachamaAiming(id)
{
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
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX); //TRIGGER
	entity_set_size(ent, Float:{-16.0, -16.0, -25.0}, Float:{16.0, 16.0, 25.0});
	entity_set_origin(ent, vOrigin);

	entity_set_float(ent,EV_FL_takedamage, 1.0);
	entity_set_float(ent,EV_FL_health, 300.0);

	entity_set_float(ent,EV_FL_animtime, 0.5);
	entity_set_float(ent,EV_FL_framerate, 0.5);
	entity_set_int(ent,EV_INT_sequence, 4);
}
public throwAqua(id) // 本體
{
	new light = throwAquaLight(id);
	new ent = create_entity(gInfoTarget);
	// entity_set_edict(light, EV_ENT_aiment, ent);
	entity_set_int(light, EV_INT_iuser1, ent);

	entity_set_string(ent, EV_SZ_classname, "AquaBody");
	entity_set_model(ent, gAicore);
	entity_set_size(ent, Float:{-3.0, -3.0, 0.0}, Float:{3.0, 3.0, 50.0});
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);
	entity_set_edict(ent, EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_iuser1, light);

	new Float:velocity[3], Float:Origin[3];

	velocity_by_aim(id, 100, velocity);
	entity_get_vector(id, EV_VEC_origin, Origin);
	Origin[0] += velocity[0];
	Origin[1] += velocity[1];
	// Origin[2] += velocity[2];
	entity_set_origin(ent, Origin);
	
	entity_set_vector(ent, EV_VEC_velocity, velocity);

	set_task(2.0, "displayAquaLight", light);
}
public displayAquaLight(ent)
{
	new body = entity_get_int(ent, EV_INT_iuser1);
	entity_set_float(ent, EV_FL_renderamt, 135.0);

	new Float:Origin[3];
	entity_get_vector(body, EV_VEC_origin, Origin);
	Origin[2] += 75.0;
	entity_set_origin(ent, Origin);

	entity_set_float(body, EV_FL_nextthink, halflife_time() + 0.1);
}
throwAquaLight(id) // 燈光
{
	new ent = create_entity(gInfoTarget);

	entity_set_string(ent, EV_SZ_classname, "AquaLight");
	entity_set_model(ent, gszAquaMahuo);
	entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});
	entity_set_float(ent, EV_FL_scale, 0.3);
	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW); 

	entity_set_int(ent, EV_INT_renderfx, kRenderFxGlowShell);
	entity_set_int(ent, EV_INT_rendermode, kRenderTransAdd);
	entity_set_float(ent, EV_FL_renderamt, 0.0);

	new Float:Origin[3];
	entity_get_vector(id, EV_VEC_origin, Origin);
	entity_set_origin(ent, Origin);

	return ent;
}
public aquaBodyThink(ent)
{
	if (!is_valid_ent(ent)) return;
	emit_sound(ent, CHAN_STATIC, gszPortalSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 4.62);
}
createDick(id)
{
	if( halflife_time() >= fTreasureCd[id] && gCurrentDick[id] < MAXDICK) {

		new ent = create_entity(gInfoTarget);

		entity_set_string(ent, EV_SZ_classname, gDickClassName);
		entity_set_model(ent, gTreasureModel[random_num(0,3)] );
		entity_set_size(ent, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
		entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
		entity_set_edict(ent, EV_ENT_owner, id);
		entity_set_float(ent, EV_FL_fuser1, random_float(5.0, 100.0));  // 紀錄垂直軸隨機偏移量
		entity_set_float(ent, EV_FL_fuser2, random_float(-70.0, 70.0)); // 紀錄水平軸隨機偏移量

		dickThink(ent);
		
		fTreasureCd[id] = halflife_time() + 0.05;
		new count = gCurrentDick[id];
		gHaveDick[id][count] = ent;
		gCurrentDick[id]++;

		emit_sound(id, CHAN_WEAPON, "ref/miss2.wav", 0.3, ATTN_NORM, 0, PITCH_NORM);
	}
}
public dickThink(ent)
{
	if (!is_valid_ent(ent)) return;

	// 資料初始化
	new id = entity_get_edict(ent, EV_ENT_owner);
	static Float:vOrigin[3], Float:fAim[3], Float:fAngles[3];

	velocity_by_aim(id, 32, fAim);
	vector_to_angle(fAim, fAngles);

	// 物件角度設定
	fAngles[0]  = 0.0;           // 用於設定物件上下角度向量
	fAngles[1] -= 90.0;
	entity_set_vector(ent, EV_VEC_angles, fAngles);

	// X軸線偏移設定
	static Float:xOffsets[3];
	makeRandomOffsets(id, entity_get_float(ent, EV_FL_fuser2), xOffsets);
	
	// 物件座標設定
	entity_get_vector(id, EV_VEC_origin, vOrigin);
	vOrigin[0] = vOrigin[0] - fAim[0] + xOffsets[0];
	vOrigin[1] = vOrigin[1] - fAim[1] + xOffsets[1];
	vOrigin[2] = vOrigin[2] + entity_get_float(ent, EV_FL_fuser1);
	entity_set_origin(ent, vOrigin);

	// 物件思考設定
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.01);
}

doDick(id)
{
	if( gCurrentDick[id] > 0 ) {
		for (new i = 0; i < MAXDICK; ++i)
		{
			new ent = gHaveDick[id][i];
			if ( !is_valid_ent(ent) || ent == 0 ) continue;

			gHaveDick[id][i] = 0;
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 99999.9);
			entity_set_int(ent, EV_INT_iuser1, 1);

			new Float:fAim[3], Float:xOffsets[3];
			velocity_by_aim(id, 1200, fAim);
			makeRandomOffsets(id, entity_get_float(ent, EV_FL_fuser2), xOffsets);

			// 減去偏移值使中心點瞄準
			fAim[0] -= xOffsets[0];
			fAim[1] -= xOffsets[1]; 
			fAim[2] -= entity_get_float(ent, EV_FL_fuser1);
			entity_set_vector(ent, EV_VEC_velocity, fAim);

			attachBeamFollow(ent, 10);
			emit_sound(ent, CHAN_WEAPON, "ref/homura.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		gCurrentDick[id] = 0;
	}
}
makeRandomOffsets(id, Float:random, Float:vec[3])
{
	new Float:xOffsets[3];
	entity_get_vector(id, EV_VEC_angles, xOffsets);
	xOffsets[1] += 90.0;
	angle_vector(xOffsets, ANGLEVECTOR_FORWARD, xOffsets);
	xs_vec_mul_scalar(xOffsets, random, xOffsets);
	vec = xOffsets;
}

public TouchDick(ent, ptr)
{
	if (!is_valid_ent(ent)) return;

	new szClassName[32], ptrClassName[32];
	entity_get_string(ent, EV_SZ_classname, szClassName, charsmax(szClassName));
	entity_get_string(ptr, EV_SZ_classname, ptrClassName, charsmax(ptrClassName));

	new Float:fOrigin[3];
	new id = entity_get_edict(ent, EV_ENT_owner);

	if(equal(szClassName, gDickClassName) && !equal(ptrClassName, gDickClassName) && id != ptr ) {
		if( entity_get_int(ent, EV_INT_iuser1) == 1 ) {
			entity_get_vector(ent, EV_VEC_origin, fOrigin);
			creat_exp_spr(fOrigin);
			ExecuteHam(Ham_TakeDamage, ptr, ptr, id, 5000.0, DMG_ENERGYBEAM);

			if( !equal(ptrClassName, "player") )
				remove_entity(ent);
		}
	}
}

createBall(id)
{
	for( new i=1; i<=3; ++i) {
		new Float:vOrigin[3];
		new ent = create_entity(gInfoTarget);

		// get_weapon_position(id, vOrigin, 40.0, 12.0, -5.0);
		// entity_get_vector(id, EV_VEC_origin, vOrigin);
		new Float:fAim[3], Float:fAnglesTemp[3];
		velocity_by_aim(id, 50, fAim);
		vector_to_angle(fAim, fAnglesTemp);
		entity_get_vector(id, EV_VEC_origin, vOrigin);

		vOrigin[0] += fAim[0];
		vOrigin[1] += fAim[1];
		vOrigin[2] += fAim[2];

		entity_set_origin(ent, vOrigin);

		entity_set_string(ent, EV_SZ_classname, gBallClassname);
		entity_set_int(ent, EV_INT_solid,   SOLID_TRIGGER);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);

		entity_set_model(ent, BallSprites[1]);
		entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});

		// entity_set_int(ent, EV_INT_renderfx, kRenderFxGlowShell);
		// entity_set_int(ent, EV_INT_rendermode, kRenderTransAdd);
		// entity_set_float(ent, EV_FL_renderamt, 255.0);
		entity_set_float(ent, EV_FL_scale, random_float(0.1, 0.4));
		entity_set_int(ent, EV_INT_iuser1, id);
		
		new Float:fVelocity[3];

		if(i==1)
			fAnglesTemp[1] += 30.0;
		else if(i==3)
			fAnglesTemp[1] -= 30.0;

		angle_vector(fAnglesTemp, ANGLEVECTOR_FORWARD, fVelocity);

		xs_vec_mul_scalar(fVelocity, 120.0, fVelocity);

		entity_set_vector(ent, EV_VEC_velocity, fVelocity);
	}
}

public TouchHachama(Ptd, Ptr)
{
	if (!is_valid_ent(Ptd))
		return;

	// new Float:origin[3];
	// entity_get_vector(Ptr, EV_VEC_origin, origin);
	// entity_set_vector(Ptd, EV_VEC_origin, origin);

	if( !entity_get_edict(Ptd, EV_ENT_owner) ) {
		
		hachamaTimer[Ptd] = halflife_time() + 70.0;

		entity_set_edict(Ptd, EV_ENT_owner, Ptr);
		entity_set_float(Ptd, EV_FL_nextthink, halflife_time() + 0.1);

		emit_sound(Ptd, CHAN_STATIC, gszAquaSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
}

public hachamaThink(ent)
{
	if (!is_valid_ent(ent))
		return;

	if( halflife_time() > hachamaTimer[ent])
	{
		remove_entity(ent);
		return;
	}

	new id = entity_get_edict(ent, EV_ENT_owner);
	if( (!is_user_connected(id) || !is_user_alive(id)) && id)
	{
		drop_to_floor(ent);
		entity_set_edict(ent, EV_ENT_owner, 0);
	}

	if( id ) {
		// new Float:origin[3];
		// entity_get_vector(id, EV_VEC_origin, origin);
		// // origin[2] += 10.0;
		// entity_set_vector(ent, EV_VEC_origin, origin);
		// drop_to_floor(ent);
		new Float:fAim[3], Float:vOrigin[3];
		velocity_by_aim(id, -50, fAim);
		entity_get_vector(id, EV_VEC_origin, vOrigin);

		vOrigin[0] += fAim[0];
		vOrigin[1] += fAim[1];
		// vOrigin[2] += fAim[2];

		entity_set_origin(ent, vOrigin);
	}

	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1);
}

public ballTouch(ent)
{
	if (!is_valid_ent(ent)) return;

	new Float:fOrigin[3];
	pev(ent, pev_origin, fOrigin);

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(ball);
	write_byte(5);
	write_byte(15);
	write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND);
	message_end();
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

	if( is_user_bot(id)) {
		fm_strip_user_weapons(id);
		fm_give_item(id, "weapon_knife");
	}

	if(g_stealth[id])
	{
		Stealth_On(id);
	}

	return PLUGIN_HANDLED;
}

public fw_TakeDamage(victim, inflictor, attacker, damage, damagebits)
{
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

stock creat_exp_spr(const Float:fOrigin[3])  //位置整數陣列X,Y,Z
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(exp);
	write_byte(5);
	write_byte(15);
	write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND);
	message_end();
}
stock attachBeamFollow(ent, life)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	// engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_BEAMFOLLOW); // 車尾燈
	write_short(ent);
	write_short(smoke);
	write_byte(life); // life
	write_byte(1); // width
	write_byte(random_num(1,255)); // r
	write_byte(random_num(1,255)); // g
	write_byte(random_num(1,255)); // b
	write_byte(127); // brightness
	message_end();
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

stock get_weapon_position(id, Float:fOrigin[], Float:add_forward = 0.0, Float:add_right = 0.0, Float:add_up = 0.0)
{
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3]
	static Float:Forward[3], Float:Right[3], Float:Up[3]
	
	pev(id, pev_v_angle, vAngles)
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, ViewOfs)
	xs_vec_add(fOrigin, ViewOfs, fOrigin)
	
	pev(id, pev_angles, Angles)
	
	Angles[0] = vAngles[0]
	
	engfunc(EngFunc_MakeVectors, Angles)
	
	global_get(glb_v_forward, Forward)
	global_get(glb_v_right, Right)
	global_get(glb_v_up, Up)
	
	xs_vec_mul_scalar(Forward, add_forward, Forward)
	xs_vec_mul_scalar(Right, add_right, Right)
	xs_vec_mul_scalar(Up, add_up, Up)
	
	fOrigin[0] = fOrigin[0] + Forward[0] + Right[0] + Up[0]
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1]
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2]
}
stock fm_strip_user_weapons(index) {
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent))
		return 0;

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return;

	static Float:originF[3], save
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;

	engfunc(EngFunc_RemoveEntity, ent)
}
stock fm_create_entity(const classname[])
{
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
}