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

const BallMax = 2;
const BallSpeed = 2000;
const Float:BallDamage = 150.0;
const Float:BallRadiusExplode =	130.0;

new const gInfoTarget[] = "env_sprite"; // info_target
new const gClassname[] = "func_breakable"; //func_haachama
new const gBallEnt[] = "env_sprite";
new const gBallClassname[] = "Entball";

new akoMainMenu[256];
new akoBallMenu[256];

new BallMenuPages[20];
new BallMenuPagesMax
new SelectedBallType[BallMax];

new const gHaachamaModel[] = "models/haachama/haachama.mdl"
new const gszAquaSound[] = "ref/AkaihaatoRemixZ.wav";
new const BallSounds[2][] = 
{
	"ref/ballshoot.wav",		
	"ref/ballexp.wav"		
}
new const akoBallSpritesBBall[] = "sprites/ref/gball.spr";
new const akoBallSpritesTpBall[] = "sprites/ref/tpball.spr";
new const akoBallBoomSprites[] = "sprites/ref/gbomb.spr";

enum
{
	BBAL,
	TPBALL
}

new const akoBallNames[BallMax][20] =
{
	"爆炸球",
	"傳送球"
}

new akoBallSprites[BallMax][256];

new bool:g_stealth[33];
new bool:headshot[33];
new bool:dmg_reflection[33];
new Float:hachamaTimer[512];

new poop;
new wave;
new boom;


public plugin_init()
{
	register_plugin("hax", "1.0", "Ako");

	register_clcmd("hax", "showMenu");

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Touch, gBallEnt, "ballTouch");

	register_touch(gClassname, "player", "TouchHachama");
	register_think(gClassname, "hachamaThink");

	createMenu();

	register_menucmd(register_menuid("haxMainMenu"), gKeysMainMenu, "handleMainMenu");
	register_menucmd(register_menuid("haxBallMenu"), gKeysBallMenu, "handleBallMenu");
	register_menucmd(register_menuid("haxBallSelectionMenu"), gKeysBallSelectionMenu, "handleBallSelectionMenu");
}

public plugin_precache()
{
	akoBallSprites[BBAL] = akoBallSpritesBBall;
	akoBallSprites[TPBALL] = akoBallSpritesTpBall;
	precache_model(gHaachamaModel);
	precache_sound(gszAquaSound);
	poop = engfunc(EngFunc_PrecacheModel, "models/winebottle.mdl");
	wave = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr");

	for(new i = 0; i < BallMax; i++)
		precache_model(akoBallSprites[i]);

	for(new i = 0; i < sizeof BallSounds; i++)
		precache_sound(BallSounds[i]);

	boom = precache_model(akoBallBoomSprites);
}

createMenu()
{
	BallMenuPagesMax = floatround((float(BallMax) / 8.0), floatround_ceil);

	new size = sizeof(akoMainMenu);
	add(akoMainMenu, size, "\w大便雞雞尿尿 ^n^n");
	add(akoMainMenu, size, "\r1. \waimbot: %s ^n");
	add(akoMainMenu, size, "\r2. \w反射傷害: %s ^n");
	add(akoMainMenu, size, "\r3. \w隱身: %s ^n^n");
	add(akoMainMenu, size, "\r4. \w色情球球 ^n");
	add(akoMainMenu, size, "\r5. \w召喚哈洽馬 ^n^n^n");
	add(akoMainMenu, size, "\r0. \w關閉");
	gKeysMainMenu = B1 | B2 | B3 | B4 | B5 | B0

	size = sizeof(akoBallMenu);
	add(akoBallMenu, size, "\w球球選單>< ^n^n");
	add(akoBallMenu, size, "\r1. \w睪丸類型: \y%s ^n");
	add(akoBallMenu, size, "\r2. \w發射球球 ^n^n");
	add(akoBallMenu, size, "\r0, \w返回");
	gKeysBallMenu = B1 | B2 | B0
	gKeysBallSelectionMenu = B1 | B2 | B0

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
	new BallMenu[200];
	new title[32];
	new entry[32];
	new num;
	new starBall;

	format(title, sizeof(title), "\y睪丸選擇 %d^n^n", BallMenuPages[id]);

	add(BallMenu, sizeof(BallMenu), title);

	starBall = (BallMenuPages[id] - 1) * 8;

	for(new i = starBall; i < starBall; ++i) {
		if(i < BallMax) {
			num = (i - starBall) + 1;
			format(entry, sizeof(entry), "\r%d. \w%s^n", num, akoBallNames[i]);
		}
		else
		{
			format(entry, sizeof(entry), "^n");
		}

		add(BallMenu, sizeof(BallMenu), entry);
	}

	if(BallMenuPages[id] < BallMenuPagesMax)
		add(BallMenu, sizeof(BallMenu), "^n\r9. \wMore");
	else
		add(BallMenu, sizeof(BallMenu), "^n");

	add(BallMenu, sizeof(BallMenu), "^n\r0. \w返回");

	show_menu(id, gKeysBallSelectionMenu, BallMenu, -1, "haxBallSelectionMenu");
}

public handleMainMenu(id, num)
{
	switch(num) {
		case N1: { toggleAimbot(id); }
		case N2: { toggleDmgreflection(id); }
		case N3: { toggleStealth(id); }
		case N4: { showBallMenu(id); }
		case N5: { summonHaachamaAiming(id); }
		case N0: { return; }
	}

	if(num != N4)
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
		case N9:
		{
			++BallMenuPages[id];

			if(BallMenuPages[id] > BallMenuPagesMax)
				BallMenuPages[id] = BallMenuPagesMax;

			showBallSelectionMenu(id);
		}

		case N0:
		{
			--BallMenuPages[id];

			if(BallMenuPages[id] < 1) {
				showBallMenu(id);
				BallMenuPages[id] = 1;
			}
			else
			{
				showBallSelectionMenu(id);
			}
		}

		default:
		{
			num += (BallMenuPages[id] - 1) * 8;

			if(num < BallMax) {
				SelectedBallType[id] = num;
				showBallMenu(id);
			}
			else
			{
				showBallSelectionMenu(id);
			}
		}
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

createBall(id, const blockType)
{
	new Float:vOrigin[3], Float:vVelocity[3];
	new ent = create_entity(gBallEnt);
	new BallSpr[256];

	get_weapon_position(id, vOrigin, 40.0, 12.0, -5.0)

	entity_set_string(ent, EV_SZ_classname, gBallClassname);
	entity_set_int(ent, EV_INT_solid,   SOLID_SLIDEBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);

	BallSpr = akoBallSprites[blockType];

	if(blockType >= 0 && blockType < BallMax) {
		entity_set_model(ent, BallSpr);
	}
	entity_set_origin(ent, vOrigin);
	entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});

	entity_set_int(ent, EV_INT_renderfx, kRenderFxGlowShell);
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
	pev(ent, pev_classname, bClassName, charsmax(bClassName))

	if(equal(bClassName, gBallClassname)) {
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

		new victim  = FM_NULLENT;
		new attacker = pev(ent, pev_iuser1);

		while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, BallRadiusExplode)) != 0) {
			if(!is_user_alive(victim))
				continue;

			ExecuteHamB(Ham_TakeDamage, victim, attacker, attacker, BallDamage, DMG_SONIC);
		}
		engfunc(EngFunc_RemoveEntity, ent);
	}
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