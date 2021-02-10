#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <xs>
#include <vector>
#include <cstrike>

new gKeysMainMenu;
new gKeysBallMenu;
new gKeysBallSelectionMenu;
new gKeysMahoujinMenu;

enum
{
	N1, N2, N3, N4, N5, N6, N7, N8, N9, N0
};

enum
{
	B1 = 1 << N1, B2 = 1 << N2, B3 = 1 << N3, B4 = 1 << N4, B5 = 1 << N5,
	B6 = 1 << N6, B7 = 1 << N7, B8 = 1 << N8, B9 = 1 << N9, B0 = 1 << N0,
};

const BallMax = 3;
const BallSpeed = 2000;
const Float:BallDamage = 150.0;
const Float:BallRadiusExplode =	150.0;

new const gInfoTarget[] = "env_sprite"; // info_target
new const gClassname[] = "func_breakable"; //func_haachama
new const gBallEnt[] = "env_sprite";
new const gBallClassname[] = "Entball";

new akoMainMenu[256];
new akoBallMenu[256];
new akoBallSelectionMenu[256];
new akoMahoujinMenu[256];

new SelectedBallType[33];

new const gHaachamaModel[] = "models/haachama/haachama.mdl"
new const gszAquaSound[] = "ref/AkaihaatoRemixZ.wav";
new const dodgeSpeedBoost[] = "ref/speedboost.wav";
new const BallSounds[2][] = 
{
	"ref/ballshoot.wav",		
	"ref/ballexp.wav"		
}
new const akoBallSpritesBBall[] = "sprites/ref/gball.spr";
new const akoBallSpritesSLBall[] = "sprites/ref/slball.spr";
new const akoBallSpritesTPBall[] = "sprites/ref/tpball.spr";
new const akoBallBoomSprites[] = "sprites/ref/gbomb.spr";
new const akoBallKanataSprites[] = "sprites/ref/kanata.spr";

enum
{
	BBALL,
	SLBALL,
	TPBALL
}

new const akoBallNames[BallMax][20] =
{
	"爆炸球",
	"擊飛球",
	"傳送球"
}

new akoBallSprites[BallMax][256];

new bool:g_stealth[33];
new bool:headshot[33];
new bool:dmg_reflection[33];
new bool:mahoujin[33];
new Float:hachamaTimer[512];
new Float:SpeedBoostTimeOut[33];
new mahoujinSpeed[33];

new poop;
new wave;
new boom;
new kanata;


public plugin_init()
{
	register_plugin("hax", "1.0", "Ako");

	register_clcmd("hax", "showMenu");
	register_clcmd("respawn", "respawn");

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Touch, gBallEnt, "ballTouch");

	register_event("CurWeapon", "eventCurWeapon", "be");

	register_touch(gClassname, "player", "TouchHachama");
	register_think(gClassname, "hachamaThink");

	createMenu();

	register_menucmd(register_menuid("haxMainMenu"), gKeysMainMenu, "handleMainMenu");
	register_menucmd(register_menuid("haxBallMenu"), gKeysBallMenu, "handleBallMenu");
	register_menucmd(register_menuid("haxBallSelectionMenu"), gKeysBallSelectionMenu, "handleBallSelectionMenu");
	register_menucmd(register_menuid("haxMahoujinMenu"), gKeysMahoujinMenu, "handleMahoujinMenu");
}

public plugin_precache()
{
	akoBallSprites[BBALL] = akoBallSpritesBBall;
	akoBallSprites[SLBALL] = akoBallSpritesSLBall;
	akoBallSprites[TPBALL] = akoBallSpritesTPBall;
	precache_model(gHaachamaModel);
	precache_sound(gszAquaSound);
	precache_sound(dodgeSpeedBoost);
	poop = engfunc(EngFunc_PrecacheModel, "models/winebottle.mdl");
	wave = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr");

	for(new i = 0; i < BallMax; i++)
		precache_model(akoBallSprites[i]);

	for(new i = 0; i < sizeof BallSounds; i++)
		precache_sound(BallSounds[i]);

	boom = precache_model(akoBallBoomSprites);
	kanata = precache_model(akoBallKanataSprites);
}

public client_PreThink(id)
{
	if(!is_user_connected(id))
		return;

	if(mahoujin[id]) {
		static button1, button2;
		button1 = pev(id, pev_button);
		button2 = pev(id, pev_button);
		if((button1 & IN_JUMP) && (button2 & IN_DUCK)) {
			static Float:velocity[3];
			velocity_by_aim(id, mahoujinSpeed[id], velocity);
			velocity[2] = 500.0;
			set_pev(id, pev_velocity, velocity);
		}
		entity_set_int(id,  EV_INT_watertype, CONTENTS_WATER);
	}
}

public respawn(id)
{
	ExecuteHam(Ham_CS_RoundRespawn, id);
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
		fm_give_item(id, "weapon_knife");
		fm_give_item(id, "weapon_usp");
	}
}

createMenu()
{
	new size = sizeof(akoMainMenu);
	add(akoMainMenu, size, "\w大便雞雞尿尿 ^n^n");
	add(akoMainMenu, size, "\r1. \waimbot: %s ^n");
	add(akoMainMenu, size, "\r2. \w反射傷害: %s ^n");
	add(akoMainMenu, size, "\r3. \w隱身: %s ^n^n");
	add(akoMainMenu, size, "\r4. \w色情睪丸 ^n");
	add(akoMainMenu, size, "\r5. \w魔法陣選單^n");
	add(akoMainMenu, size, "\r6. \w召喚哈洽馬 ^n^n^n");
	add(akoMainMenu, size, "\r0. \w關閉");
	gKeysMainMenu = B1 | B2 | B3 | B4 | B5 | B6 | B0

	size = sizeof(akoBallMenu);
	add(akoBallMenu, size, "\w睪丸選單 ^n^n");
	add(akoBallMenu, size, "\r1. \w睪丸類型: \y%s ^n");
	add(akoBallMenu, size, "\r2. \w發射球球 ^n^n");
	add(akoBallMenu, size, "\r0. \w返回");
	gKeysBallMenu = B1 | B2 | B0

	size = sizeof(akoBallSelectionMenu);
	add(akoBallSelectionMenu, size, "\w睪丸選擇^n^n");
	add(akoBallSelectionMenu, size, "\r1. \w爆炸球^n");
	add(akoBallSelectionMenu, size, "\r2. \w擊飛球^n");
	add(akoBallSelectionMenu, size, "\r3. \w傳送球^n^n");
	add(akoBallSelectionMenu, size, "\r0. \w返回");
	gKeysBallSelectionMenu = B1 | B2 | B3 | B0

	size = sizeof(akoMahoujinMenu);
	add(akoMahoujinMenu, size, "\w魔法陣選單^n^n");
	add(akoMahoujinMenu, size, "\r1. \w魔法陣: %s^n");
	add(akoMahoujinMenu, size, "\r2. \w速度: \y%d/3000^n");
	add(akoMahoujinMenu, size, "\r3. \w速度歸零^n^n");
	add(akoMahoujinMenu, size, "\r0. \w返回");
	gKeysMahoujinMenu = B1 | B2 | B3 | B0

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

	format(menu, 200, akoMainMenu, Aimbot, Dmgreflection, Stealth);

	show_menu(id, gKeysMainMenu, menu, -1, "haxMainMenu");

	return PLUGIN_HANDLED;
}

showBallMenu(id)
{
	new menu[200];

	format(menu, 200, akoBallMenu, akoBallNames[SelectedBallType[id]]);

	show_menu(id, gKeysBallMenu, menu, -1, "haxBallMenu");

	return PLUGIN_HANDLED;
}

showBallSelectionMenu(id)
{
	new menu[200];

	format(menu, 200, akoBallSelectionMenu);

	show_menu(id, gKeysBallSelectionMenu, menu, -1, "haxBallSelectionMenu");
}

showMahoujinMenu(id)
{
	new menu[200];
	new Mahoujin[6];
	Mahoujin = (mahoujin[id] ? "\yOn" : "\yOff");

	format(menu, 200, akoMahoujinMenu, Mahoujin, mahoujinSpeed[id]);

	show_menu(id, gKeysMahoujinMenu, menu, -1, "haxMahoujinMenu");
}

public handleMainMenu(id, num)
{
	switch(num) {
		case N1: { toggleAimbot(id); }
		case N2: { toggleDmgreflection(id); }
		case N3: { toggleStealth(id); }
		case N4: { showBallMenu(id); }
		case N5: { showMahoujinMenu(id); }
		case N6: { summonHaachamaAiming(id); }
		case N0: { return; }
	}

	if(num != N4 && num != N5)
		showMenu(id);
}

public handleBallMenu(id, num)
{
	switch(num) {
		case N1: { showBallSelectionMenu(id); }
		case N2: { createBall(id, SelectedBallType[id]); }
		case N0: { showMenu(id); }
	}

	if(num != N0 && num != N1)
		showBallMenu(id);
}

public handleBallSelectionMenu(id, num)
{
	switch(num) {
		case N1:
		{
			SelectedBallType[id] = num;
			showBallMenu(id);
		}
		case N2:
		{
			SelectedBallType[id] = num;
			showBallMenu(id);
		}
		case N3:
		{
			SelectedBallType[id] = num;
			showBallMenu(id);
		}
		case N0: { showBallMenu(id); }
	}
}

public handleMahoujinMenu(id, num)
{
	switch(num) {
		case N1: { toggleMahoujin(id); }
		case N2:
		{
			if(mahoujinSpeed[id] < 3000) mahoujinSpeed[id] += 100;
			else showMahoujinMenu(id);
		}
		case N3: { mahoujinSpeed[id] = 0; }
		case N0: { showMenu(id); }
	}
	if(num != N0) {
		showMahoujinMenu(id);
	}
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

toggleMahoujin(id)
{
	if(mahoujin[id]) mahoujin[id] = false;
	else mahoujin[id] = true;
}

Stealth_On(id)
	fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);

Stealth_Off(id)
	fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);

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
	entity_set_float(ent,EV_FL_health, 100.0);

	entity_set_float(ent,EV_FL_animtime, 0.5);
	entity_set_float(ent,EV_FL_framerate, 0.5);
	entity_set_int(ent,EV_INT_sequence, 4);
}

createBall(id, const ballType)
{
	new Float:vOrigin[3], Float:vVelocity[3];
	new ent = create_entity(gBallEnt);
	new BallSpr[256];

	get_weapon_position(id, vOrigin, 40.0, 12.0, -5.0)

	entity_set_string(ent, EV_SZ_classname, gBallClassname);
	entity_set_int(ent, EV_INT_solid,   SOLID_SLIDEBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);

	BallSpr = akoBallSprites[ballType];

	if(ballType >= 0 && ballType < BallMax) {
		entity_set_model(ent, BallSpr);
	}
	entity_set_origin(ent, vOrigin);
	entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});
	entity_set_int(ent, EV_INT_iuser2, ballType);

	entity_set_int(ent, EV_INT_rendermode, kRenderTransAdd);
	entity_set_float(ent, EV_FL_renderamt, 255.0);
	entity_set_float(ent, EV_FL_scale, random_float(0.1, 0.4));
	entity_set_int(ent, EV_INT_iuser1, id);

	velocity_by_aim(id, BallSpeed, vVelocity);

	entity_set_vector(ent, EV_VEC_velocity, vVelocity);
	emit_sound(id, CHAN_WEAPON, BallSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public TouchHachama(Ptd, Ptr)
{
	if (!is_valid_ent(Ptd))
		return;

	// new Float:origin[3];
	// entity_get_vector(Ptr, EV_VEC_origin, origin);
	// entity_set_vector(Ptd, EV_VEC_origin, origin);

	if( !entity_get_edict(Ptd, EV_ENT_owner) ) {
		
		hachamaTimer[Ptd] = halflife_time()+70.0;

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
		new Float:origin[3];
		entity_get_vector(id, EV_VEC_origin, origin);
		// origin[2] += 10.0;
		entity_set_vector(ent, EV_VEC_origin, origin);
		drop_to_floor(ent);
	}

	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1);
}

public ballTouch(ent)
{
	if (!is_valid_ent(ent))
		return;

	new bClassName[32];
	new victim  = FM_NULLENT;
	new id = pev(ent, pev_iuser1);
	new ballType = entity_get_int(ent, EV_INT_iuser2);
	pev(ent, pev_classname, bClassName, charsmax(bClassName))

	if(equal(bClassName, gBallClassname)) {
		if(ballType == BBALL) {
			new Float:fOrigin[3];
			pev(ent, pev_origin, fOrigin);

			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
			write_byte(TE_EXPLOSION);
			engfunc(EngFunc_WriteCoord, fOrigin[0]);
			engfunc(EngFunc_WriteCoord, fOrigin[1]);
			engfunc(EngFunc_WriteCoord, fOrigin[2]);
			write_short(boom);
			write_byte(5);
			write_byte(15);
			write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND);
			message_end();

			emit_sound(ent, CHAN_WEAPON, BallSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, BallRadiusExplode)) != 0) {
				if(!is_user_alive(victim))
					continue;

				ExecuteHamB(Ham_TakeDamage, victim, id, id, BallDamage, DMG_TIMEBASED);
			}
			engfunc(EngFunc_RemoveEntity, ent);
		}

		if(ballType == SLBALL) {
			new Float:fOrigin[3], Float:fOrigin2[3];
			pev(ent, pev_origin, fOrigin);

			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
			write_byte(TE_EXPLOSION);
			engfunc(EngFunc_WriteCoord, fOrigin[0]);
			engfunc(EngFunc_WriteCoord, fOrigin[1]);
			engfunc(EngFunc_WriteCoord, fOrigin[2]);
			write_short(kanata);
			write_byte(5);
			write_byte(1);
			write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND);
			message_end();

			emit_sound(ent, CHAN_WEAPON, BallSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, BallRadiusExplode)) != 0) {
				if(!is_user_alive(victim))
					continue;

				pev(victim, pev_origin, fOrigin2);
				new Float:velocity[3];
				get_speed_vector_to_entity(ent, victim, 700.0, velocity);
				velocity[2] += 400.0
				set_pev(victim, pev_velocity, velocity);
			}

			engfunc(EngFunc_RemoveEntity, ent);
		}

		if(ballType == TPBALL) {
			new Float:entAngle[3], Float:eee[3];
			pev(ent, pev_velocity, entAngle);
			xs_vec_normalize(entAngle, eee);
			xs_vec_mul_scalar(eee, -64.0, eee);
			new Float:vOrigin[3];
			pev(ent, pev_origin, vOrigin);
			vOrigin[0] += eee[0];
			vOrigin[1] += eee[1];
			vOrigin[2] = vOrigin[2] + 36;
			set_pev(id, pev_origin, vOrigin);
			engfunc(EngFunc_RemoveEntity, ent);
		}
		
	}
}

public eventCurWeapon(id)
{
	new Float:fTime = halflife_time();
	new Float:fTimeLeft = SpeedBoostTimeOut[id] - fTime;
	if(fTimeLeft > 0.0)
		set_user_maxspeed(id, 700.0);
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (headshot[attacker] == true)
	{
		if (get_tr2(tracehandle, TR_iHitgroup) != HIT_HEAD) set_tr2(tracehandle, TR_iHitgroup, HIT_HEAD);
	}

	if(is_user_alive(victim) && is_user_connected(victim)) {
		if(random_num(1, 10) != 0) {
			new vOrigin[3];
			new Float:fTime = halflife_time();
			get_tr2(tracehandle, TR_vecEndPos, vOrigin);

			set_task(8.0, "speedboostRemove", victim);

			set_user_maxspeed(victim, 700.0);

			emit_sound(victim, CHAN_WEAPON, dodgeSpeedBoost, 1.0, ATTN_NORM, 0, PITCH_NORM);

			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
			write_byte(TE_GLOWSPRITE);
			engfunc(EngFunc_WriteCoord, vOrigin[0]);
			engfunc(EngFunc_WriteCoord, vOrigin[1]);
			engfunc(EngFunc_WriteCoord, vOrigin[2]);
			write_short(kanata);
			write_byte(1);
			write_byte(3);
			write_byte(175);
			message_end();

			SpeedBoostTimeOut[victim] = fTime + 8.0;
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED
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

public speedboostRemove(victim)
{
	if(is_user_alive(victim)) {
		set_user_maxspeed(victim, 250.0);
	}
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

stock get_speed_vector_to_entity(ent1, ent2, Float:speed, Float:new_velocity[3])
{
	if(!pev_valid(ent1) || !pev_valid(ent2))
		return 0;
	
	static Float:origin1[3]
	pev(ent1,pev_origin,origin1)
	static Float:origin2[3]
	pev(ent2,pev_origin,origin2)
	
	new_velocity[0] = origin2[0] - origin1[0];
	new_velocity[1] = origin2[1] - origin1[1];
	new_velocity[2] = origin2[2] - origin1[2];
	
	static Float:num
	num = speed / vector_length(new_velocity);
				
	new_velocity[0] *= num;
	new_velocity[1] *= num;
	new_velocity[2] *= num;
	
	return 1;
}

stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;
	#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
	new ent = fm_create_entity(item);
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}