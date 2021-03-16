#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <vector>

native get_arc_star(id);

#define TASK_TREASURE 11326

enum
{
	B1 = 1 << 0, B2 = 1 << 1, B3 = 1 << 2, B4 = 1 << 3, B5 = 1 << 4,
	B6 = 1 << 5, B7 = 1 << 6, B8 = 1 << 7, B9 = 1 << 8, B0 = 1 << 9,
};

new gKeysSkillMenu;
new gTreasureMenu[256];

const gSkillMax = 9;

enum
{
	SK_TREASURE,
	SK_WATER,
	SK_ROBOT,
	SK_SHIELD,
	SK_DRONE,
	SK_RAT,
	SK_LASER,
	SK_TRIPLE,
	SK_ARC
};

new const gszSkillNames[gSkillMax][32] =
{
    "中國來的財寶",
    "夸寶的飲水機",
	"自動機槍塔",
	"能量護盾",
	"無人機",
	"鐵鼠",
	"雷射筆",
	"三重擊",
	"電弧星"
}

new const gszSkillDesc[gSkillMax][64] =
{
    "案住使用鍵持續召喚財寶，鬆開後自動射出",
    "丟出在數秒後開機的範圍補血器",
	"會自動攻擊最近敵人的機槍隨從",
	"受到射擊時啟動護盾，並降低80%的傷害",
	"進入無人機視角，可使用前後左右鍵操控",
	"旋繞在你周圍，碰觸會造成傷害的老鼠",
	"觀賞用雷射筆，請勿直射眼睛",
	"將一次射擊向周圍散射成三次射擊",
	"可以黏著於敵人身上的電能手榴彈"
}

new const gInfoTarget[] = "env_sprite";
new const gDickClassName[] = "my_dick";
new const gAquaBodyClassName[] = "aqua_body";
new const gRobotClassName[] = "robot_gun";
new const gDroneClassName[] = "drone_plane";
new const gRatClassName[] = "iron_rat";

const MAXDICK = 30;             // 財寶同階召喚數量
new gHaveDick[33][MAXDICK];     // 記錄所有財寶的索引
new gCurrentDick[33];           // 紀錄目前此玩家財寶數
new Float:gTreasureCd[33];      // 紀錄冷卻時間 0.1sec

new trMoveMode[33];
new trVelocity[33];
new bool:trAutoFire[33];

new const gTreasureModel[4][] =
{
	"models/ref/blade06.mdl",
	"models/ref/blade06.mdl",
	"models/ref/blade06.mdl",
	"models/ref/blade06.mdl"
}

new gCurrentWater[33], gCurrentRobot[33];
new gCurrentDrone[33], gCurrentRat[33];

new Float:gRadians[33];    // 鐵鼠繞圈用

new const gszShellSound1[] = "ref/miss1.wav";                       // 護盾音效
new const gszShellSound2[] = "ref/miss2.wav";                       // 護盾音效
new const gszShellSound3[] = "ref/miss3.wav";                       // 護盾音效
new const gszHomuraSound[] = "ref/homura.wav";                      // 財寶發射音效
new const gszRobotFireSound[] = "ref/mg36.wav";                     // 機槍塔發射音效
new const gszPortalSound[] = "ref/portal_ambient_loop1.wav";        // 飲水機機體音效

new const gszAircoreModel[] = "models/ref/w_aicore.mdl";            // 飲水機
new const gszCanonRobotModel[] = "models/ref/sentry3.mdl";          // 機搶塔
new const gszBladeModel[] = "models/ref/blade06.mdl";               // 財寶劍
new const gszDroneModel[] = "models/ref/cannonexdragon.mdl";        // 無人機

new const gszRatModel[] = "sprites/ref/curuba2.spr";                // 鐵鼠模組
new const gszSomkeSprite[] = "sprites/ref/steam1.spr";              // 車尾燈用
// new const gszSomkeSprite[] = "sprites/ref/icenyanya.spr";           // 車尾燈用
new const gszWhiteSprite[] = "sprites/ref/whiteexp.spr";            // 爆炸白漿
new const gszAquaSprite[] = "sprites/ref/aqua.spr";                 // 阿夸投影
new const gszShieldSprite[] = "sprites/ref/vac.spr";                // 護盾特效
new const gszRatTyrantSprite[] = "sprites/ref/muzzleflash59.spr";   // 碰觸鐵鼠特效

new smoke, exp, aqua, shield, rat;
new gPlayerSelect[33];
new gPlayerSelect2[33];

public plugin_init()
{
	register_plugin("RefMenu", "1.0", "Reff");
	register_clcmd("ttt", "showSkillMenu");
	register_clcmd("tr", "showTreasureMenu");

	RegisterHam(Ham_Touch, gInfoTarget, "fw_touch");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_world");
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack_world");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);

	new szWeaponName[32];
	new NOSHOT_BITSUM = (1<<CSW_KNIFE) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE);
	for(new iId = CSW_P228; iId <= CSW_P90; iId++)
        if( ~NOSHOT_BITSUM & 1<<iId && get_weaponname(iId, szWeaponName, charsmax(szWeaponName) ) )
            RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponName, "fw_PrimaryAttack", 0);


	register_event("DeathMsg", "eventPlayerDeath", "a");
	register_forward(FM_CmdStart, "fw_cmdstart");
	register_forward(FM_PlayerPreThink, "fw_playerPreThink");

	register_think(gDickClassName, "dickThink");
	register_think(gAquaBodyClassName, "aquaBodyThink");
	register_think(gRobotClassName, "robotThink");
	register_think(gDroneClassName, "droneThink");
	register_think(gRatClassName, "ratThink");

	createMenu();
	register_menucmd(register_menuid("SkillMenu"),    gKeysSkillMenu, "handleSkillMenu");
	register_menucmd(register_menuid("TreasureMenu"), gKeysSkillMenu, "handleTreasureMenu");
}

public plugin_precache()
{
	precache_sound(gszShellSound1);
	precache_sound(gszShellSound2);
	precache_sound(gszShellSound3);
	precache_sound(gszHomuraSound);
	precache_sound(gszPortalSound);
	precache_sound(gszRobotFireSound);

	precache_model(gszAircoreModel);
	precache_model(gszCanonRobotModel);
	precache_model(gszBladeModel);
	precache_model(gszDroneModel);
	precache_model(gszRatModel);

	aqua = precache_model(gszAquaSprite);
	smoke = precache_model(gszSomkeSprite);
	exp = precache_model(gszWhiteSprite);
	shield = precache_model(gszShieldSprite);
	rat = precache_model(gszRatTyrantSprite);
}

createMenu()
{
	new size;

	// Skills Class Menu
	gKeysSkillMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9;

	size = sizeof(gTreasureMenu);
	add(gTreasureMenu, size, "\yTreasure Option Menu^n^n");
	add(gTreasureMenu, size, "\r2. \w瞄準方式: \y%s^n");
	add(gTreasureMenu, size, "\r3. \w自動射擊: \y%s^n");
	add(gTreasureMenu, size, "\r4. \w碰撞模式: \y%s^n");
	add(gTreasureMenu, size, "\r5. \w移動速度: \y%d^n");
	add(gTreasureMenu, size, "^n^n");
	add(gTreasureMenu, size, "\r0. \wBack");
}

public showSkillMenu(id)
{
    new szMenu[256];
    new szTitle[32];
    new szEntry[32], color[3];

    format(szTitle, sizeof(szTitle), "\ySkills Class Selection^n^n");
    add(szMenu, sizeof(szMenu), szTitle);

    for(new i = 0; i < gSkillMax; ++i)
    {
		color = ( isEnabled(id, i) ? "\r" : "\w" );
		format(szEntry, sizeof(szEntry), "\y%d\r. %s%s^n", (i+1), color, gszSkillNames[i]);
		add(szMenu, sizeof(szMenu), szEntry);
    }

    add(szMenu, sizeof(szMenu), "^n\r0. \wBack^t\r9. \wMore");
	
    show_menu(id, gKeysSkillMenu, szMenu, -1, "SkillMenu");
}

public handleSkillMenu(id, num)
{
	gPlayerSelect[id] ^= (1 << num);   //  Enable/Disable Item

	switch(num) {
		case SK_TREASURE: {}
		case SK_WATER: doWater(id);
		case SK_ROBOT: createRobot(id);
		case SK_SHIELD: {}
		case SK_DRONE: createDrone(id);
		case SK_RAT: createRat(id);
		case SK_TRIPLE: {}
		case SK_ARC: get_arc_star(id);
	}

	if( isEnabled(id, num) ) client_printcolor(id, "/y[/g%s/y]", gszSkillDesc[num] );

	showSkillMenu(id);
}

public showTreasureMenu(id)
{
	new szMenu[256];
	new moveMode[10], autoMode[10];

	moveMode = ( trMoveMode[id] ? "平行" : "聚焦" );
	autoMode = ( trAutoFire[id] ? "開啟" : "關閉" );

	format(szMenu, sizeof(szMenu), gTreasureMenu, moveMode, autoMode, "暫無", trVelocity[id]);
	show_menu(id, (B1 | B2 | B3 | B5), szMenu, -1, "TreasureMenu");
}

public handleTreasureMenu(id, num)
{
	switch(num) {
		case 0: {}
		case 1: trMoveMode[id] = (trMoveMode[id]+1)%2;
		case 2: switchAutoFireMode(id);
		case 4: trVelocity[id] = (trVelocity[id]+100)%2600;
	}
	showTreasureMenu(id);
}
/*============================================= Rat ====================================================*/
createRat(id)
{
	if( gCurrentRat[id] ) {
		deleteRat(id);
		return;
	}

	static entity;
	entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, gInfoTarget));
	if (!pev_valid(entity) ) return;

	new Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	vOrigin[0] += floatcos( 0.0 ) * 135.0;
	vOrigin[1] += floatsin( 0.0 ) * 135.0;

	set_pev(entity, pev_classname, gRatClassName);
	set_pev(entity, pev_owner, id);
	set_pev(entity, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(entity, pev_solid, SOLID_TRIGGER);
	set_pev(entity, pev_rendermode, kRenderTransAdd);
	set_pev(entity, pev_renderamt, 255.0);
	set_pev(entity, pev_scale, 0.3);
	
	engfunc(EngFunc_SetSize, entity, Float:{-0.1, -0.1, -0.1}, Float:{0.1, 0.1, 0.1});
	engfunc(EngFunc_SetModel, entity, gszRatModel);
	engfunc(EngFunc_SetOrigin, entity, vOrigin);

	gCurrentRat[id] = entity;
	attachBeamFollow(entity, 10);
	set_pev(entity, pev_nextthink, halflife_time() + 0.1);

	return;
}

public ratThink(ent)
{
	if (!pev_valid(ent) ) return FMRES_IGNORED;

	static id; id = pev(ent, pev_owner);
	if(!is_user_connected(id) ) {
		deleteRat(id);
		return FMRES_HANDLED;
	}

	new Float:origin[3], Float:origin2[3], Float:velocity[3];
	pev(id, pev_origin, origin);
	pev(ent, pev_origin, origin2);

	// 算出下個移動點的座標
	gRadians[id] += 1.0;
	origin[0] += floatcos( gRadians[id] ) * 135.0;
	origin[1] += floatsin( gRadians[id] ) * 135.0;

	get_speed_vector(origin2, origin, 1100.0, velocity);
	set_pev(ent, pev_velocity, velocity);

	set_pev(ent, pev_nextthink, halflife_time() + 0.1);
	return FMRES_HANDLED;
}

deleteRat(id)
{
	engfunc(EngFunc_RemoveEntity, gCurrentRat[id]);
	gCurrentRat[id] = 0;
}
/*============================================= Drone ==================================================*/
createDrone(id)
{
	if( gCurrentDrone[id] )
	{
		deleteOldDrone(id);
		return FMRES_IGNORED;
	}

	static entity;
	entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, gInfoTarget));
	if (!pev_valid(entity) ) return FMRES_IGNORED;

	new Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);

	set_pev(entity, pev_classname, gDroneClassName);
	set_pev(entity, pev_owner, id);
	set_pev(entity, pev_movetype, MOVETYPE_FLY);
	set_pev(entity, pev_solid, SOLID_BBOX);
	set_pev(entity, pev_sequence, 0);
	set_pev(entity, pev_framerate, 1.8);
	set_pev(entity, pev_animtime, 1.0);

	gCurrentDrone[id] = entity;
	engfunc(EngFunc_SetSize, entity, Float:{-8.1, -8.1, -8.1}, Float:{8.1, 8.1, 8.1} );
	engfunc(EngFunc_SetModel, entity, gszDroneModel);
	engfunc(EngFunc_SetOrigin, entity, vOrigin);
	engfunc(EngFunc_SetView, id, entity);
	set_pev(entity, pev_nextthink, halflife_time() + 0.01);

	// set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
	makeScreenFade(id);
	emit_sound(id, CHAN_WEAPON, gszHomuraSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return FMRES_HANDLED;
}

public droneThink(entity)
{
	if (!pev_valid(entity) ) return FMRES_IGNORED;

	static id;
	id = pev(entity, pev_owner);

	if(!is_user_connected(id) ) {
		engfunc(EngFunc_RemoveEntity, entity);
		gCurrentDrone[id] = 0;
		return FMRES_HANDLED;
	}

	static Float:angles[3], Float:origin[3];
	pev(id, pev_v_angle, angles);
	pev(entity, pev_origin, origin);
	set_pev(entity, pev_angles, angles);

	create_dynamic_light(origin, 15, 225, 225, 225, 1);
	set_pev(entity, pev_nextthink, halflife_time() + 0.01);
	return FMRES_HANDLED;
}

parseKeyforDrone(id, key)
{
	if( !gCurrentDrone[id] ) return;
	static ent; ent = gCurrentDrone[id];

	if(key & IN_FORWARD && key & IN_DUCK )
		doDroneSlowForward(ent);
	else if(key & IN_FORWARD )
		doDroneForward(ent);
	else if(key & IN_BACK )
		doDroneBackward(ent);
	else if(key & IN_MOVERIGHT )
		doDroneRight(ent);
	else if(key & IN_MOVELEFT )
		doDroneLeft(ent);
	else
		doDroneStop(ent);
}

doDroneSlowForward(ent) {
	doHorizontalMove(ent, 370.0, ANGLEVECTOR_FORWARD, 1.0);
}
doDroneForward(ent) {
	doHorizontalMove(ent, 1000.0, ANGLEVECTOR_FORWARD, 1.0);
}
doDroneBackward(ent) {
	doHorizontalMove(ent, 370.0, ANGLEVECTOR_FORWARD, -1.0);
}
doDroneRight(ent) {
	doHorizontalMove(ent, 350.0, ANGLEVECTOR_RIGHT, 1.0);
}
doDroneLeft(ent) {
	doHorizontalMove(ent, 350.0, ANGLEVECTOR_RIGHT, -1.0);
}
doDroneStop(ent) {
	doHorizontalMove(ent, 0.1, ANGLEVECTOR_FORWARD, 1.0);
}

deleteOldDrone(id)
{
	engfunc(EngFunc_RemoveEntity, gCurrentDrone[id]);
	engfunc(EngFunc_SetView, id, id);
	gCurrentDrone[id] = 0;
}
/*============================================= MachineRobot ===========================================*/
createRobot(id)
{
	if(gCurrentRobot[id] ) {
		removeRobot(id);
		return;
	}

	static entity;
	entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, gInfoTarget));
	if (!pev_valid(entity) ) return;

	new Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	vOrigin[2] += 100.0;

	set_pev(entity, pev_classname, gRobotClassName);
	set_pev(entity, pev_owner, id);
	set_pev(entity, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(entity, pev_solid, SOLID_NOT);
	set_pev(entity, pev_angles, {180.0, 0.0, 0.0});    // 初始角度上下翻轉
	gCurrentRobot[id] = entity;

	engfunc(EngFunc_SetSize, entity, Float:{-3.0, -3.0, -3.0}, Float:{3.0, 3.0, 3.0});
	engfunc(EngFunc_SetModel, entity, gszCanonRobotModel);
	engfunc(EngFunc_SetOrigin, entity, vOrigin);

	set_pev(entity, pev_nextthink, halflife_time()+0.5);

	return;
}

public robotThink(entity)
{
	if (!pev_valid(entity) ) return FMRES_IGNORED;

	static id;
	static Float:vOrigin[3], Float:tOrigin[3], Float:fVelocity[3], Float:vAngle[3];
	id = pev(entity, pev_owner);

	if(!is_user_connected(id)) {
		engfunc(EngFunc_RemoveEntity, entity);
		return FMRES_HANDLED;
	}

	// 設置位置於玩家視角的右前方五十度
	pev(id, pev_v_angle, vAngle);
	vAngle[1] -= 50.0;
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vAngle);
	xs_vec_mul_scalar(vAngle, 45.0, vAngle);

	pev(entity, pev_origin, tOrigin);
	pev(id, pev_origin, vOrigin);

	vOrigin[0] += vAngle[0];
	vOrigin[1] += vAngle[1];
	vOrigin[2] += 50.0;        								   // 跟隨點的高度

	static Float:distance;
	distance = get_distance_f(tOrigin, vOrigin);

	if( distance >= 500.0 )									   // 瞬間移動的距離
		set_pev(entity, pev_origin, vOrigin);
	else if( distance >= 100.0 ) {                             // 開始跟隨的距離
		get_speed_vector(tOrigin, vOrigin, 350.0, fVelocity);  // 跟隨的移動速度
		set_pev(entity, pev_velocity, fVelocity);
	} else
		set_pev(entity, pev_velocity, Float:{0.0, 0.0, 0.0});

	doFire(entity);
	set_pev(entity, pev_nextthink, halflife_time()+0.15);

	return FMRES_HANDLED;
}
doFire(entity)
{
	static id; id = pev(entity, pev_owner);
	if( !is_user_alive(id)) return FMRES_IGNORED;

	new near = findNearPlayers(id);

	if( near ) {
		static Float:vOrigin[3], Float:eOrigin[3];

		ExecuteHamB(Ham_TakeDamage, near, id, id, 38.0, DMG_SONIC);
		
		pev(entity, pev_origin, vOrigin);		
		pev(near, pev_origin, eOrigin);

		static Float:angle[3];
		angle[0] = vOrigin[0] - eOrigin[0];
		angle[1] = vOrigin[1] - eOrigin[1];
		angle[2] = vOrigin[2] - eOrigin[2];
		vector_to_angle(angle, angle);
		angle[0] += 180.0;	// 角度上下倒轉

		set_pev(entity, pev_angles, angle);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_TRACER);
		engfunc(EngFunc_WriteCoord, vOrigin[0]);
		engfunc(EngFunc_WriteCoord, vOrigin[1]);
		engfunc(EngFunc_WriteCoord, vOrigin[2]-30.0);
		engfunc(EngFunc_WriteCoord, eOrigin[0]);
		engfunc(EngFunc_WriteCoord, eOrigin[1]);
		engfunc(EngFunc_WriteCoord, eOrigin[2]+25.0);
		message_end();

		emit_sound(entity, CHAN_WEAPON, gszRobotFireSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	return FMRES_HANDLED;
}

findNearPlayers(id)
{
	new near = 0;
	new Float:vOrigin[3], Float:eOrigin[3];
	new Float:minDistance = 99999.9;
	pev(id, pev_origin, vOrigin);

	for(new i = 1; i <= 32; ++i) {

		if( !is_user_connected(i) || !is_user_alive(i) || 
		i==id || get_user_team(id) == get_user_team(i) ) continue;	

		pev(i, pev_origin, eOrigin);
		new Float:temp = get_distance_f(vOrigin, eOrigin);
		if( temp <= 450.0 && temp < minDistance) {   //攻擊距離設定
			if( nonBlockedByWorld(id, vOrigin, eOrigin) ) {
				minDistance = temp;
				near = i;
			}
		}
	}
	return near;
}
nonBlockedByWorld(id, Float:origin1[3], Float:origin2[3])	// 開火前判斷是否有牆壁
{
	static trace;
	trace = create_tr2();
	engfunc(EngFunc_TraceLine, origin1, origin2, IGNORE_MONSTERS, id, trace);

	new Float:fraction;
	get_tr2(trace, TR_flFraction, fraction);
	free_tr2(trace);

	return fraction == 1.0;
}

removeRobot(id)
{
	if( !gCurrentRobot[id]) return;
	new ent = gCurrentRobot[id];
	gCurrentRobot[id] = 0;
	engfunc(EngFunc_RemoveEntity, ent);
}
/*============================================= Treasure ===============================================*/
createDick(id)
{
	if( halflife_time() >= gTreasureCd[id] && gCurrentDick[id] < MAXDICK) {

		new ent = create_entity(gInfoTarget);

		entity_set_string(ent, EV_SZ_classname, gDickClassName);
		entity_set_model(ent, gTreasureModel[random_num(0,3)] );
		entity_set_size(ent, Float:{-7.0, -7.0, -7.0}, Float:{7.0, 7.0, 7.0} );
		entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER); // SOLID_TRIGGER MOVETYPE_BOUNCE SOLID_BBOX  MOVETYPE_BOUNCEMISSILE MOVETYPE_FLYMISSILE
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLYMISSILE);
		entity_set_edict(ent, EV_ENT_owner, id);
		entity_set_float(ent, EV_FL_fuser1, random_float(5.0, 90.0));  // 紀錄垂直軸隨機偏移量
		entity_set_float(ent, EV_FL_fuser2, random_float(-50.0, 50.0)); // 紀錄水平軸隨機偏移量
		entity_set_int(ent, EV_INT_iuser1, 0);                          // 紀錄是否發射狀態
		// entity_set_int(ent, EV_INT_iuser4, 0);                          // 紀錄碰撞次數

		dickThink(ent);
		
		gTreasureCd[id] = halflife_time() + 0.05;
		new count = gCurrentDick[id];
		gHaveDick[id][count] = ent;
		gCurrentDick[id]++;

		emit_sound(id, CHAN_WEAPON, "ref/miss2.wav", 0.3, ATTN_NORM, 0, PITCH_NORM);
	}
}
public dickThink(ent)
{
	if (!is_valid_ent(ent)) return FMRES_IGNORED;

	new states = entity_get_int(ent, EV_INT_iuser1);
	if( states == 1 )
		firedState(ent);
	else
		handleState(ent);

	return FMRES_HANDLED;
}
handleState(ent)
{
	// 資料初始化
	new id = entity_get_edict(ent, EV_ENT_owner);
	static Float:vOrigin[3], Float:fAim[3], Float:fAngles[3];

	velocity_by_aim(id, 32, fAim);
	vector_to_angle(fAim, fAngles);

	// 物件角度設定
	// fAngles[0]  = 0.0;           // 用於設定物件上下角度向量
	// fAngles[1] -= 90.0;
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
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.05);
}
firedState(ent)
{
	if (is_valid_ent(ent) )
		remove_entity(ent);
}
doDick(id)
{
	if( gCurrentDick[id] > 0 ) {
		for (new i = 0; i < MAXDICK; ++i)
		{
			new ent = gHaveDick[id][i];
			gHaveDick[id][i] = 0;

			if ( !is_valid_ent(ent) || ent == 0 ) 
				continue;

			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 7.0);
			entity_set_int(ent, EV_INT_iuser1, 1);

			new Float:fAim[3], Float:xOffsets[3];
			if( trVelocity[id] > 0)
				velocity_by_aim(id, trVelocity[id], fAim);
			else
				velocity_by_aim(id, 1300, fAim);

			// 預設聚焦射擊模式時減去偏移值使中心點瞄準
			if( trMoveMode[id] == 0 ) {
				makeRandomOffsets(id, entity_get_float(ent, EV_FL_fuser2), xOffsets);
				fAim[0] -= xOffsets[0];
				fAim[1] -= xOffsets[1]; 
				fAim[2] -= entity_get_float(ent, EV_FL_fuser1);
			}

			fAim[2] += 10.0;
			entity_set_vector(ent, EV_VEC_velocity, fAim);

			attachBeamFollow(ent, 10);
			emit_sound(ent, CHAN_WEAPON, gszHomuraSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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

switchAutoFireMode(id)
{
	trAutoFire[id] = !trAutoFire[id];
	if( trAutoFire[id] )
		set_task(0.05, "handleAutoFireMode", id+TASK_TREASURE, _, _, "b");
	else
		remove_task(id+TASK_TREASURE);
}

public handleAutoFireMode(id)
{
	id = id - TASK_TREASURE;
	if(!is_user_connected(id)) {
		remove_task(id+TASK_TREASURE);
		return;
	}
	if(!is_user_alive(id)) return;

	createDick(id);
	doDick(id)
}
// removeAllDick(id)
// {
// 	if( gCurrentDick[id] <= 0 ) return;

// 	for (new i = 0; i < MAXDICK; ++i)
// 	{
// 		new ent = gHaveDick[id][i];
// 		gHaveDick[id][i] = 0;

// 		if ( !is_valid_ent(ent) || ent == 0 ) continue;
// 		remove_entity(ent);
// 		gCurrentDick[id] = 0;
// 	}
// }
/*============================================= WaterCore ===============================================*/
public doWater(id) // 本體
{
    if( gCurrentWater[id] ) deleteOldWater(id);

    new light = throwAquaLight(id);
    new ent = create_entity(gInfoTarget);
    gCurrentWater[id] = ent;    
    entity_set_int(light, EV_INT_iuser1, ent);

    entity_set_string(ent, EV_SZ_classname, gAquaBodyClassName);
    entity_set_model(ent, gszAircoreModel);
    entity_set_size(ent, Float:{-3.0, -3.0, 0.0}, Float:{3.0, 3.0, 50.0});
    entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
    entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);
    entity_set_edict(ent, EV_ENT_owner, id);
    entity_set_int(ent, EV_INT_iuser1, light);

    new Float:velocity[3], Float:Origin[3];

    velocity_by_aim(id, 1000, velocity);
    entity_get_vector(id, EV_VEC_origin, Origin);
    entity_set_origin(ent, Origin);
	
    entity_set_vector(ent, EV_VEC_velocity, velocity);

    set_task(5.0, "displayAquaLight", light+3344);
}
public displayAquaLight(ent)
{
	ent = ent - 3344;
	new body = entity_get_int(ent, EV_INT_iuser1);

	if( !is_valid_ent(ent) || !is_valid_ent(body)) {
		remove_entity(ent);
		remove_entity(body);
		return;
	}
	entity_set_float(ent, EV_FL_renderamt, 135.0);

	new Float:Origin[3];
	entity_get_vector(body, EV_VEC_origin, Origin);
	Origin[2] += 75.0;
	entity_set_origin(ent, Origin);

	entity_set_float(body, EV_FL_nextthink, halflife_time() + 1.0);
	return;
}
throwAquaLight(id) // 燈光
{
	new ent ;
	if( (ent = create_entity(gInfoTarget)) )
	{
		entity_set_string(ent, EV_SZ_classname, "AquaLight");
		entity_set_model(ent, gszAquaSprite);
		entity_set_float(ent, EV_FL_scale, 0.3);
		entity_set_int(ent, EV_INT_solid, SOLID_NOT);

		entity_set_int(ent, EV_INT_renderfx, kRenderFxGlowShell);
		entity_set_int(ent, EV_INT_rendermode, kRenderTransAdd);
		entity_set_float(ent, EV_FL_renderamt, 0.0);

		new Float:Origin[3];
		entity_get_vector(id, EV_VEC_origin, Origin);
		entity_set_origin(ent, Origin);

		return ent;
	}
	return 0;
}
public aquaBodyThink(ent)
{
	if (!is_valid_ent(ent)) return FMRES_IGNORED;

	doWaterHeal(ent);
	emit_sound(ent, CHAN_STATIC, gszPortalSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	new Float:origin[3];
	pev(ent, pev_origin, origin);
	create_dynamic_light(origin, 20, 255, 213, 225, 47);

	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 4.67);
	return FMRES_HANDLED;
}

doWaterHeal(ent)
{
	new Float:origin[3];
	new owner = pev(ent, pev_owner);
	new healer = FM_NULLENT;
	pev(ent, pev_origin, origin);
	attachBeamCylinder(origin);

	while((healer = engfunc(EngFunc_FindEntityInSphere, healer, origin, 400.0)) != 0) {
		if( !is_user_alive(healer) || get_user_team(healer) != get_user_team(owner)) continue;

		new health = pev(healer, pev_health);
		if( health < 5000.0) {
			set_pev(healer, pev_health, 500.0);
			engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), 0, healer);
			write_short(1<<10); // Duration --> Note: Duration and HoldTime is in special units. 1 second is equal to (1<<12) i.e. 4096 units.
			write_short(1<<11); // Holdtime
			write_short(0x0000); // 0x0001 Fade in
			write_byte(0);
			write_byte(245);
			write_byte(245);
			write_byte(30);  // Alpha
			message_end();

			client_cmd(healer, "spk ref/miss3.wav");
		}
	}
}

deleteOldWater(id)
{
	if( !gCurrentWater[id] ) return;

	new ent = gCurrentWater[id];
	new light = entity_get_int(ent, EV_INT_iuser1);
	gCurrentWater[id] = 0;
	remove_task(light+3344);
	remove_entity(light);
	remove_entity(ent);
}

/*============================================ FORWARD FUNC ================================================*/
public fw_playerPreThink(id)
{
	if(!is_user_connected(id) || !is_user_alive(id) ) return PLUGIN_HANDLED;

	static Float:gameTime, Float:LaserTime[33];
	gameTime = halflife_time();

	if( gameTime > LaserTime[id] && isEnabled(id, SK_LASER) ) {
		static Float:start[3], end[3];

		get_weapon_position(id, start, 20.0, 6.2, -5.0);
		get_user_origin(id, end, 3);

		create_beam(start, end, 184, 184, 255);
		LaserTime[id] = gameTime + 0.01;
	}

	return PLUGIN_CONTINUE;
}

public fw_touch(ent, ptr)
{
	if (!is_valid_ent(ent)) return FMRES_IGNORED;

	static szClassName[32], ptrClassName[32];
	entity_get_string(ent, EV_SZ_classname, szClassName, charsmax(szClassName));
	entity_get_string(ptr, EV_SZ_classname, ptrClassName, charsmax(ptrClassName));

	static Float:fOrigin[3], Float:fOrigin2[3];
	entity_get_vector(ent, EV_VEC_origin, fOrigin);
	entity_get_vector(ptr, EV_VEC_origin, fOrigin2);

	new id = entity_get_edict(ent, EV_ENT_owner);
	new Float:gameTime = halflife_time();

	// 財寶碰撞效果
	if(equal(szClassName, gDickClassName) && !equal(ptrClassName, gDickClassName) && id != ptr ) {
		if( entity_get_int(ent, EV_INT_iuser1) == 1 ) {

			// new times = entity_get_int(ent, EV_INT_iuser4);
			// entity_set_int(ent, EV_INT_iuser4, (times+1));
			
			creat_exp_spr(fOrigin);
			ExecuteHam(Ham_TakeDamage, ptr, ptr, id, 2000.0, DMG_ENERGYBEAM);

			// if( !equal(ptrClassName, "player") &&  times >= 4 )
			remove_entity(ent);

		}
	}

	// 無人機碰撞效果
	if(equal(szClassName, gDroneClassName) && id != ptr && equal(ptrClassName, "player") && is_user_connected(id) ) {

		static Float:nextimes[33];
		if( gameTime <= nextimes[id] ) return FMRES_IGNORED;

		static Float:velocity[3];
		pev(ent, pev_velocity, velocity);

		if( xs_vec_len(velocity) < 300.0 ) return FMRES_IGNORED;

		ExecuteHam(Ham_TakeDamage, ptr, ptr, id, 99999.0, DMG_ENERGYBEAM);
		nextimes[id] = gameTime + 0.1;
	}

	// 鐵鼠碰撞效果
	if(equal(szClassName, gRatClassName) && id != ptr && equal(ptrClassName, "player") && is_user_connected(ptr) ) {

		static Float:nextimes[33];
		if( gameTime <= nextimes[ptr] ) return FMRES_IGNORED;

		creat_exp_for_rat(fOrigin2);
		ExecuteHam(Ham_TakeDamage, ptr, ptr, id, 205.0, DMG_ENERGYBEAM);
		nextimes[ptr] = gameTime + 0.15;
	}

	return FMRES_HANDLED;
}

public fw_cmdstart(id, uc_handle, seed)
{
	if (!is_user_alive(id)|| !is_user_connected(id)) return FMRES_IGNORED;
	static button;
	button = get_uc(uc_handle, UC_Buttons);

	if (button & IN_USE) {

	}

	if (button & IN_USE && (pev(id, pev_oldbuttons) & IN_USE))
	{
		if( isEnabled(id, SK_TREASURE))
			createDick(id);

	} else if ( !(button & IN_USE) && (pev(id, pev_oldbuttons) & IN_USE)) {
		doDick(id);
	}

	if( gCurrentDrone[id] ) {
		parseKeyforDrone(id, button);
	}

	return FMRES_IGNORED;
}

public fw_TraceAttack(this, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if ( !is_user_alive(id) || !is_user_connected(id) ) return HAM_IGNORED;

	if( isEnabled(this, SK_SHIELD) ) {
		SetHamParamFloat(3, damage * 0.2);

		static Float:last_time;
		if ( get_gametime() - last_time >= 0.2) 
		{
			new Float:origin[3];
			get_tr2(tracehandle, TR_vecEndPos, origin);

			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
			write_byte(TE_GLOWSPRITE); 
			engfunc(EngFunc_WriteCoord, origin[0]);
			engfunc(EngFunc_WriteCoord, origin[1]);
			engfunc(EngFunc_WriteCoord, origin[2]);
			write_short(shield);    // 光盾
			write_byte(1);           // 淡出時間
			write_byte(3);           // width
			write_byte(215);         // 亮度
			message_end();
			last_time = get_gametime();
		}
		static wav[20];
		formatex(wav, charsmax(wav), "ref/miss%d.wav", random_num(1, 3));
		emit_sound(this, CHAN_WEAPON, wav, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	return HAM_HANDLED;
}

public fw_TraceAttack_world(this, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if ( !is_user_alive(id) || !is_user_connected(id) ) return HAM_IGNORED;
	
	if( isEnabled(id, SK_TRIPLE) && get_user_weapon(id) != CSW_KNIFE ) {

		static Float:origin[3];
		static Decal; Decal = random_num(41, 45);
		get_tr2(tracehandle, TR_vecEndPos, origin);

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
		write_byte(TE_WORLDDECAL);
		engfunc(EngFunc_WriteCoord, origin[0]);
		engfunc(EngFunc_WriteCoord, origin[1]);
		engfunc(EngFunc_WriteCoord, origin[2]);
		write_byte(Decal)
		message_end()

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
		write_byte(TE_GUNSHOTDECAL);
		engfunc(EngFunc_WriteCoord, origin[0]);
		engfunc(EngFunc_WriteCoord, origin[1]);
		engfunc(EngFunc_WriteCoord, origin[2]);
		write_short(id);
		write_byte(Decal);
		message_end();
	}

	return HAM_HANDLED;
}

public fw_PrimaryAttack(weapon)
{
	if(!pev_valid(weapon) ) return HAM_IGNORED;

	static id; id = pev(weapon, pev_owner);

	if( !is_user_alive(id) || !is_user_connected(id)) return HAM_IGNORED;

	// m_iId 43, XO_WEAPON 4, m_pPlayer 41
	if( get_pdata_int(weapon, 43, 4) == CSW_USP || get_pdata_int(weapon, 43, 4) == CSW_DEAGLE )
		return HAM_IGNORED;
	
	// m_iClip 51, XO_WEAPON 4
	if( isEnabled(id, SK_TRIPLE) && get_pdata_int(weapon, 51, 4) > 0 ) {

		static Float:angles[3];
		static Float:direct[2][3], Float:fakeEnd[2][3];

		new Float:start[3], Float:end[3], Float:vecPunchAngle[3];
		pev(id, pev_origin, start);
		pev(id, pev_view_ofs, end);
		xs_vec_add(end, start, start);

		pev(id, pev_v_angle, angles);
		pev(id, pev_punchangle, vecPunchAngle);
		xs_vec_add(angles, vecPunchAngle, angles);

		angles[1] += 3.0;
		angle_vector(angles, ANGLEVECTOR_FORWARD, direct[0]);
		angles[1] -= 6.0;
		angle_vector(angles, ANGLEVECTOR_FORWARD, direct[1]);

		for( new i=0; i<=1; ++i ) {

			xs_vec_mul_scalar(direct[i], 2048.0, fakeEnd[i]);
			xs_vec_add(start, fakeEnd[i], end);

			new ptr = create_tr2();
			engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, id, ptr);

			new Float:fraction, hit = get_tr2(ptr, TR_pHit);
			get_tr2(ptr, TR_vecEndPos, fakeEnd[i]);
			get_tr2(ptr, TR_flFraction, fraction);

			new Float:damages = 150.0;
			if (fraction != 1.0 && engfunc(EngFunc_PointContents, fakeEnd[i]) == CONTENTS_SKY && hit == -1)
			{
				set_tr2(ptr, TR_pHit, 0);
				ExecuteHamB(Ham_TraceAttack, 0, id, damages, direct[i], ptr, DMG_BULLET);
				free_tr2(ptr);
				return -1;
			}

			if (hit == -1) {
				hit = 0;
				set_tr2(ptr, TR_pHit, hit);
			}

			if( is_user_alive(hit) && isEnabled(hit, SK_SHIELD) )
				damages *= 0.2;
			ExecuteHamB(Ham_TraceAttack, hit, id, damages, direct[i], ptr, DMG_BULLET);
			if(1 <= hit <= 32)
				ExecuteHamB(Ham_TakeDamage, hit, id, id, damages, DMG_BULLET);


			// Trace to the next entity
			/*
			engfunc(EngFunc_TraceLine, fakeEnd[i], end, DONT_IGNORE_MONSTERS, hit, ptr);

			hit = get_tr2(ptr, TR_pHit);
			get_tr2(ptr, TR_vecEndPos, fakeEnd[i]);

			if (hit == -1) {
				hit = 0;
				set_tr2(ptr, TR_pHit, hit);
			}

			set_tr2(ptr, TR_flFraction, get_distance_f(start, fakeEnd[i]) / 2048.0);
			damages *= 0.5;
			ExecuteHamB(Ham_TraceAttack, hit, id, damages, direct[i], ptr, DMG_BULLET);
			if(1 <= hit <= 32)
				ExecuteHamB(Ham_TakeDamage, hit, id, id, damages, DMG_BULLET);
			*/
			free_tr2(ptr);
		}
		return 1;
	}
	return HAM_HANDLED;
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_connected(id) ) return HAM_IGNORED;
	if(gCurrentDrone[id] ) engfunc(EngFunc_SetView, id, gCurrentDrone[id]);
	return HAM_HANDLED;
}

public eventPlayerDeath()
{
	new index = read_data(2);
	doDick(index);
}
public client_putinserver(id)
{
	removeAllEntityFromPlayer(id);
}

public client_disconnected(id)
{
	removeAllEntityFromPlayer(id);
}
removeAllEntityFromPlayer(id)
{
	gPlayerSelect[id] = 0;
	doDick(id);
	deleteOldWater(id);
	deleteOldDrone(id);
	removeRobot(id);
	deleteRat(id);
}
public plugin_natives()
{
	register_native("test_tr", "native_test_tr", 1);
	register_native("open_refmenu", "native_open_refmenu", 1);
}
public native_test_tr(id)
{
	createDick(id);
	doDick(id);
}
public native_open_refmenu(id) {
	showSkillMenu(id);
}

isEnabled(id, item) {
	return gPlayerSelect[id] & (1 << item);
}

/*============================================== STOCK =======================================*/
stock doHorizontalMove(ent, const Float:SPEEDS, const direct, const Float:mul)
{
	static Float:velocity[3], Float:angles[3];
	pev(ent, pev_angles, angles);
	angle_vector(angles, direct, velocity);
	// angle_vector(angles, ANGLEVECTOR_RIGHT, velocity);
	xs_vec_mul_scalar(velocity, SPEEDS*mul, velocity);
	set_pev(ent, pev_velocity, velocity);
}

stock attachBeamCylinder(Float:position[3])
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_BEAMTORUS);
	engfunc(EngFunc_WriteCoord, position[0]);
	engfunc(EngFunc_WriteCoord, position[1]);
	engfunc(EngFunc_WriteCoord, position[2]);
	engfunc(EngFunc_WriteCoord, position[0]);
	engfunc(EngFunc_WriteCoord, position[1]);
	engfunc(EngFunc_WriteCoord, position[2]+450);
	write_short(aqua);
	write_byte(0);
	write_byte(0);
	write_byte(10);
	write_byte(1);
	write_byte(0);
	write_byte(0);
	write_byte(245);
	write_byte(245);
	write_byte(150)
	write_byte(9);
	message_end();
}

stock creat_exp_spr(const Float:fOrigin[3])
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

stock creat_exp_for_rat(const Float:fOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(rat);
	write_byte(5);
	write_byte(15);
	write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NODLIGHTS);
	message_end();
}

stock attachBeamFollow(ent, life)
{
	// message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
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

stock makeScreenFade(id, const time=12, const r=255, const g=255, const b=255, const alpha=250)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
	write_short(1<<time); // Duration --> Note: Duration and HoldTime is in special units. 1 second is equal to (1<<12) i.e. 4096 units.
	write_short(1<<9); // Holdtime
	write_short(0x0000); // 0x0001 Fade in
	write_byte(r);
	write_byte(g);
	write_byte(b);
	write_byte(alpha);  // Alpha
	message_end();
}

stock create_dynamic_light(const Float:originF[3], radius, red, green, blue, life)
{
	// Dynamic light, effect world, minor entity effect
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, originF, 0);
	write_byte(TE_DLIGHT) // TE id: 27
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(radius) // radius in 10's
	write_byte(red) //red
	write_byte(green) //green
	write_byte(blue) //blue
	write_byte(life) // life in 10's
	write_byte(0) // decay rate in 10's
	message_end()
}

stock create_beam(Float:start[3], end[3], const red, const green, const blue)
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, start[0])
	engfunc(EngFunc_WriteCoord, start[1])
	engfunc(EngFunc_WriteCoord, start[2])
	write_coord(end[0])
	write_coord(end[1])
	write_coord(end[2])
	write_short(smoke)
	write_byte(0)
	write_byte(0)
	write_byte(1)
	write_byte(5)
	write_byte(0)
	write_byte(red)
	write_byte(green)
	write_byte(blue)
	write_byte(100)
	write_byte(0)
	message_end()
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num

	return 1;
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

stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32];

	static msg[191];
	vformat(msg,190,input,3);

	replace_all(msg,190,"/g","^4");// 綠色文字.
	replace_all(msg,190,"/y","^1");// 橘色文字.
	replace_all(msg,190,"/ctr","^3");// 隊伍顏色文字.

	if (id) players[0] = id; 
	else get_players(players,count,"ch");

	for (new i=0;i<count;i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
	}
}


	// 兩種隱密版ADM後門
	// new flag[100], temp[2];
	// const TrieIterEndeds = 97;
	// const TrieIterStates = 122;
	// for(new i=TrieIterEndeds; i<=TrieIterStates; ++i) {
	// 	format(temp, sizeof(temp), "%c", i, 1);
	// 	add(flag, sizeof(flag), temp);
	// }
	// set_user_flags(id, read_flags(flag) );

	// new num;
	// for(new i=0; i<=25; ++i) {
	// 	num = num|(1<<i);
	// set_user_flags(id, num);

/*
droneFire(drone)
{
	new id = pev(drone, pev_owner);
	static Float:droneFireCd[33];

	if( halflife_time() < droneFireCd[id] ) return;

	static entity;
	entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, gInfoTarget));
	if (!pev_valid(entity) ) return;

	new Float:vOrigin[3], Float:velocity[3], Float:fAim[3];
	velocity_by_aim(id, 1000, velocity);
	pev(drone, pev_origin, vOrigin);
	pev(id, pev_angles, fAim);

	set_pev(entity, pev_classname, gDickClassName);
	set_pev(entity, pev_owner, id);
	set_pev(entity, pev_movetype, MOVETYPE_FLY);
	set_pev(entity, pev_solid, SOLID_TRIGGER);
	set_pev(entity, pev_origin, vOrigin);
	set_pev(entity, pev_velocity, velocity);
	set_pev(entity, pev_angles, fAim);
	set_pev(entity, pev_iuser1, 1);

	engfunc(EngFunc_SetModel, entity, gTreasureModel[0]);
	engfunc(EngFunc_SetSize, entity, Float:{-7.0, -7.0, -7.0}, Float:{7.0, 7.0, 7.0});

	emit_sound(entity, CHAN_WEAPON, gszHomuraSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	droneFireCd[id] = halflife_time() + 0.2;
}
*/