#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <xs>
#include <vector>

new gKeysMainMenu;
new gKeysBallMenu;
new gKeysBallSelectionMenu;

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
const Float:BallDamage = 45.0;
const Float:BallRadiusExplode =	100.0;

new const EntInfo[] = "env_sprite";
new const gBallClassname[] = "Entball";
new const fragementClassname[] = "Entfragement";

new akoMainMenu[256];
new akoBallMenu[256];
new akoBallSelectionMenu[256];

new SelectedBallType[33];

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
new const akoExplosionBulletSprites[] = "sprites/ref/explosion.spr"
new const bornModel[] = "models/ref/feather.mdl"
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
new bool:explosionbullet[33];
new bool:fragementexplode[33];
new bool:dodge[33];
new Float:SpeedBoostTimeOut[33];

new boom;
new kanata;
new expb;
new smoke;


public plugin_init()
{
	register_plugin("hax", "1.0", "Ako");

	register_clcmd("hax", "showMenu");
	register_clcmd("respawn", "respawn");

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_bullet");
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_bullet");
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1);
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", 1);
	RegisterHam(Ham_Touch, EntInfo, "ballTouch");
	RegisterHam(Ham_Touch, EntInfo, "fragementexplodeTouch");

	register_forward(FM_CmdStart, "fw_cmdstart");

	register_event("CurWeapon", "eventCurWeapon", "be");

	createMenu();

	register_menucmd(register_menuid("haxMainMenu"), gKeysMainMenu, "handleMainMenu");
	register_menucmd(register_menuid("haxBallMenu"), gKeysBallMenu, "handleBallMenu");
	register_menucmd(register_menuid("haxBallSelectionMenu"), gKeysBallSelectionMenu, "handleBallSelectionMenu");
}

public plugin_precache()
{
	akoBallSprites[BBALL] = akoBallSpritesBBall;
	akoBallSprites[SLBALL] = akoBallSpritesSLBall;
	akoBallSprites[TPBALL] = akoBallSpritesTPBall;
	precache_sound(dodgeSpeedBoost);
	smoke = precache_model("sprites/steam1.spr");
	precache_model(bornModel);

	for(new i = 0; i < BallMax; i++)
		precache_model(akoBallSprites[i]);

	for(new i = 0; i < sizeof BallSounds; i++)
		precache_sound(BallSounds[i]);

	boom = precache_model(akoBallBoomSprites);
	kanata = precache_model(akoBallKanataSprites);
	expb = precache_model(akoExplosionBulletSprites);
}

public plugin_natives()
{
	register_native("get_hax_menu", "native_hax", 1);
}

public native_hax(id)
	showMenu(id);

public respawn(id)
{
	ExecuteHam(Ham_CS_RoundRespawn, id);
	// if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	// 	fm_give_item(id, "weapon_knife");
	// 	fm_give_item(id, "weapon_usp");
	// }
}

public client_putinserver(id)
{
	g_stealth[id] = false;
	headshot[id] = false;
	dmg_reflection[id] = false;
	mahoujin[id] = false;
	explosionbullet[id] = false;
	fragementexplode[id] = false;
	dodge[id] = false;
}

createMenu()
{
	new size = sizeof(akoMainMenu);
	add(akoMainMenu, size, "\w低能兒 ^n^n");
	add(akoMainMenu, size, "\r1. \wAimbot(自動爆頭): %s ^n");
	add(akoMainMenu, size, "\r2. \w反射傷害: %s ^n");
	add(akoMainMenu, size, "\r3. \w隱身: %s ^n");
	add(akoMainMenu, size, "\r4. \w大跳(按 蹲+跳): %s ^n");
	add(akoMainMenu, size, "\r5. \w爆炸子彈: %s^n");
	add(akoMainMenu, size, "\r6. \w破片子彈(擊殺產生): %s^n");
	add(akoMainMenu, size, "\r7. \w迴避(機率發生): %s^n^n");
	add(akoMainMenu, size, "\r8. \w睪丸選單 ^n^n^n");
	add(akoMainMenu, size, "\r0. \w關閉");
	gKeysMainMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B0

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
}

public showMenu(id)
{
	new menu[256];
	new Aimbot[6];
	new Dmgreflection[6];
	new Stealth[6];
	new Mahoujin[6];
	new Explosionbullet[6];
	new Fragementexplode[6];
	new Dodge[6];
	Aimbot = (headshot[id] ? "\yOn" : "\rOff");
	Dmgreflection = (dmg_reflection[id] ? "\yOn" : "\rOff");
	Stealth = (g_stealth[id] ? "\yOn" : "\rOff");
	Mahoujin = (mahoujin[id] ? "\yOn" : "\rOff");
	Explosionbullet = (explosionbullet[id] ? "\yOn" : "\rOff");
	Fragementexplode = (fragementexplode[id] ? "\yOn" : "\rOff");
	Dodge = (dodge[id] ? "\yOn" : "\rOff");

	format(menu, 256, akoMainMenu, Aimbot, Dmgreflection, Stealth, Mahoujin, Explosionbullet, Fragementexplode, Dodge);

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

public handleMainMenu(id, num)
{
	switch(num) {
		case N1: { toggleAimbot(id); }
		case N2: { toggleDmgreflection(id); }
		case N3: { toggleStealth(id); }
		case N4: { toggleMahoujin(id); }
		case N5: { toggleExplosionbullet(id); }
		case N6: { toggleFragementexplode(id); }
		case N7: { toggleDodge(id); }
		case N8: { showBallMenu(id); }
		case N0: { return; }
	}

	if(num != N8)
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
		fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
	}
	else{
		g_stealth[id] = true;
		fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
	}
}

toggleMahoujin(id)
{
	if(mahoujin[id]) mahoujin[id] = false;
	else mahoujin[id] = true;
}

toggleExplosionbullet(id)
{
	if(explosionbullet[id]) explosionbullet[id] = false;
	else explosionbullet[id] = true;
}

toggleFragementexplode(id)
{
	if(fragementexplode[id]) fragementexplode[id] = false;
	else fragementexplode[id] = true;
}

toggleDodge(id)
{
	if(dodge[id]) dodge[id] = false;
	else dodge[id] = true;
}

createBall(id, const ballType)
{
	new Float:vOrigin[3], Float:vVelocity[3];
	new ent = create_entity(EntInfo);
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

public ballTouch(ent)
{
	if (!is_valid_ent(ent)) return HAM_HANDLED;

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
				if(!is_user_alive(victim) || id == victim)
					continue;

				ExecuteHamB(Ham_TakeDamage, victim, id, id, BallDamage, DMG_ENERGYBEAM);
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
	return HAM_HANDLED;
}

createFragement(id, Float:vOrigin[3])
{
	static const Float:xpis[] = {300.0, -300.0, -300.0}
	static const Float:ypis[] = {0.0, -300.0, 300.0}

	static const Float:xsta[] = {20.0, -20.0, -20.0}
	static const Float:ysta[] = {0.0, -20.0, 20.0}
	static ent

	for(new i = 0; i <= 2; i++) {
		ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, EntInfo));
		set_pev(ent, pev_classname, fragementClassname);
		engfunc(EngFunc_SetModel, ent, bornModel);
		engfunc(EngFunc_SetSize, ent, Float:{-0.7, -0.7, -0.7}, Float:{0.7, 0.7, 0.7});
		set_pev(ent, pev_movetype, MOVETYPE_FLY);
		set_pev(ent, pev_solid, SOLID_TRIGGER);
		set_pev(ent, pev_owner, id);

		static Float:vVelocity[3];
		vOrigin[0] += xsta[i];
		vOrigin[1] += ysta[i];
		set_pev(ent, pev_origin, vOrigin);

		vVelocity[0] = xpis[i];
		vVelocity[1] = ypis[i];
		vVelocity[2] = 0.0;

		vVelocity[0] *= 400.0;
		vVelocity[1] *= 400.0;
		
		set_pev(ent, pev_velocity, vVelocity);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(ent)
		write_short(smoke)
		write_byte(3)
		write_byte(1)
		write_byte(0)
		write_byte(255)
		write_byte(255)
		write_byte(70)
		message_end()
	}
}

public fragementexplodeTouch(ent, ptr)
{
	if(!is_valid_ent(ent)) return HAM_HANDLED;

	new id = pev(ent, pev_owner);
	static entClassName[32], ptrClassName[32];

	pev(ent, pev_classname, entClassName, charsmax(entClassName));
	pev(ptr, pev_classname, ptrClassName, charsmax(ptrClassName));

	if(equal(entClassName, fragementClassname) && !equal(ptrClassName, fragementClassname) && id != ptr) {
		ExecuteHamB(Ham_TakeDamage, ptr, ptr, id, 169.0, DMG_ENERGYBEAM);

		engfunc(EngFunc_RemoveEntity, ent)
	}

	return HAM_HANDLED;
}

public eventCurWeapon(id)
{
	// new Float:fTime = halflife_time();
	// new Float:fTimeLeft = SpeedBoostTimeOut[id] - fTime;
	// if(fTimeLeft > 0.0)
	// 	set_user_maxspeed(id, 700.0);
	return;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (headshot[attacker])
		if (get_tr2(tracehandle, TR_iHitgroup) != HIT_HEAD)
			set_tr2(tracehandle, TR_iHitgroup, HIT_HEAD);

	if(dodge[victim] && is_user_alive(victim) && is_user_connected(victim) && get_user_team(victim) == 1) {
		if(random_num(1, 5) == 1) {
			new Float:fTime = halflife_time();

			// set_task(4.0, "speedboostRemove", victim);
			// set_user_maxspeed(victim, 700.0);

			emit_sound(victim, CHAN_WEAPON, dodgeSpeedBoost, 1.0, ATTN_NORM, 0, PITCH_NORM);
			static Float:last_time;
			if(fTime - last_time >= 0.2) {
				new Float:vOrigin[3];
				get_tr2(tracehandle, TR_vecEndPos, vOrigin);

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
				last_time = fTime;
			}

			SpeedBoostTimeOut[victim] = fTime + 4.0;
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}

public fw_TraceAttack_bullet(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if(!is_user_connected(attacker) ) return HAM_IGNORED;

	// 爆炸子彈
	if(explosionbullet[attacker] && get_user_weapon(attacker) != CSW_KNIFE) {
		if(random_num(1, 2) == 1) {
			victim  = FM_NULLENT;
			new fOrigin[3];
			get_tr2(tracehandle, TR_vecEndPos, fOrigin);

			while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, 100.0)) != 0) {
				if(!is_user_alive(victim) || attacker == victim)
					continue;

				ExecuteHamB(Ham_TakeDamage, victim, attacker, attacker, 105.0, DMG_ENERGYBEAM);
			}

			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fOrigin, 0);
			write_byte(TE_EXPLOSION);
			engfunc(EngFunc_WriteCoord, fOrigin[0]);
			engfunc(EngFunc_WriteCoord, fOrigin[1]);
			engfunc(EngFunc_WriteCoord, fOrigin[2]);
			write_short(expb);
			write_byte(5);
			write_byte(15);
			write_byte(TE_EXPLFLAG_NOPARTICLES);
			message_end();

		}
	}
	return HAM_IGNORED;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if( !is_user_alive(attacker) || attacker == victim ) return HAM_IGNORED;

	static Float:vOrigin[3];
	if(fragementexplode[attacker] ) {
		pev(victim, pev_origin, vOrigin);
		createFragement(attacker, vOrigin);
	}
	
	return HAM_IGNORED;
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	if(g_stealth[id])
		fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);

	return PLUGIN_HANDLED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(victim) )
		return HAM_IGNORED;
	if(attacker == victim || !is_user_connected(attacker))
		return HAM_IGNORED;

	if(dmg_reflection[victim])
		ExecuteHam(Ham_TakeDamage, attacker, victim, victim, (damage*0.1), DMG_RADIATION);

	// client_print(attacker, print_chat, ": %f", damage)
	return HAM_IGNORED;
}

public speedboostRemove(victim)
{
	// if(is_user_alive(victim))
	// 	set_user_maxspeed(victim, 250.0);
	return 0;
}

public fw_cmdstart(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	if(mahoujin[id]) {
		static button;
		static Float:last_time[33];
		button = pev(id, pev_button);

		if(halflife_time() - last_time[id] >= 0.1) {
			if((button & IN_JUMP) && (button & IN_DUCK)) {
				static Float:velocity[3];
				velocity_by_aim(id, 850, velocity);  // 大跳距離
				velocity[2] = 270.0;
				set_pev(id, pev_velocity, velocity);
				
				last_time[id] = halflife_time();
			}
		}
	}

	return PLUGIN_HANDLED;
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