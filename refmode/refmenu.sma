#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <vector>

enum
{
	B1 = 1 << 0, B2 = 1 << 1, B3 = 1 << 2, B4 = 1 << 3, B5 = 1 << 4,
	B6 = 1 << 5, B7 = 1 << 6, B8 = 1 << 7, B9 = 1 << 8, B0 = 1 << 9,
};

new gKeysSkillMenu;
const gSkillMax = 3;

enum
{
	SK_TREASURE,
	MA_WATER,
	MA_ROBOT
};

new const gszSkillNames[gSkillMax][32] =
{
    "王之財寶",
    "夸寶的飲水機",
	"自動機槍塔"
}

new const gInfoTarget[] = "env_sprite";
new const gDickClassName[] = "my_dick";
new const gAquaBodyClassName[] = "aqua_body";
new const gRobotClassName[] = "robot_gun";

const MAXDICK = 30;             // 財寶同階召喚數量
new gHaveDick[33][MAXDICK];     // 記錄所有財寶的索引
new gCurrentDick[33];           // 紀錄目前此玩家財寶數
new Float:gTreasureCd[33];      // 紀錄冷卻時間 0.1sec

new const gTreasureModel[4][] =
{
	"models/w_ak47.mdl",
	"models/w_m4a1.mdl",
	"models/w_ump45.mdl",
	"models/w_scout.mdl"
}

new gCurrentWater[33], gCurrentRobot[33];

new const gszShellSound1[] = "ref/miss1.wav";
new const gszShellSound2[] = "ref/miss2.wav";
new const gszShellSound3[] = "ref/miss3.wav";                       // 護盾音效
new const gszHomuraSound[] = "ref/homura.wav";                      // 財寶發射音效
new const gszRobotFireSound[] = "ref/mg36.wav";                     // 機槍塔發射音效
new const gszPortalSound[] = "ref/portal_ambient_loop1.wav";        // 飲水機機體音效

new const gszAircoreModel[] = "models/ref/w_aicore.mdl";            // 飲水機
new const gszCanonRobotModel[] = "models/ref/sentry3.mdl";          // 機搶塔

new const gszSomkeSprite[] = "sprites/ref/steam1.spr";              // 車尾燈用
new const gszWhiteSprite[] = "sprites/ref/whiteexp.spr";            // 爆炸白漿
new const gszAquaSprite[] = "sprites/ref/aqua.spr";                 // 阿夸投影

new smoke, exp, aqua;
new gPlayerSelect[33];

public plugin_init()
{
	register_plugin("RefMenu", "1.0", "Reff");
	register_clcmd("ttt", "showSkillMenu");

	RegisterHam(Ham_Touch, gInfoTarget, "fw_touch");
	register_event("DeathMsg", "eventPlayerDeath", "a");
	register_forward(FM_CmdStart, "fw_cmdstart");

	register_think(gDickClassName, "dickThink");
	register_think(gAquaBodyClassName, "aquaBodyThink");
	register_think(gRobotClassName, "robotThink");

	createMenu();
	register_menucmd(register_menuid("SkillMenu"), gKeysSkillMenu, "handleSkillMenu");
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

	aqua = precache_model(gszAquaSprite);
	smoke = precache_model(gszSomkeSprite);
	exp = precache_model(gszWhiteSprite);
}

createMenu()
{
    arrayset(gPlayerSelect, -1, sizeof(gPlayerSelect));

    // Skills Class Menu
    gKeysSkillMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B0;
}

public showSkillMenu(id)
{
    new szMenu[256];
    new szTitle[32];
    new szEntry[32], szSelect[20];

    format(szTitle, sizeof(szTitle), "\ySkills Class Selection^n^n");
    add(szMenu, sizeof(szMenu), szTitle);

    for(new i = 0; i < gSkillMax; ++i)
    {
        szSelect = ( gPlayerSelect[id] == i ? "\y<==" : "");

        format(szEntry, sizeof(szEntry), "\r%d. \w%s %s^n", (i+1), gszSkillNames[i], szSelect);
        add(szMenu, sizeof(szMenu), szEntry);
    }

    add(szMenu, sizeof(szMenu), "^n\r0. \wBack^t\r9. \wMore");
	
    show_menu(id, gKeysSkillMenu, szMenu, -1, "SkillMenu");
}

public handleSkillMenu(id, num)
{
    switch(num) {
        case SK_TREASURE: gPlayerSelect[id] = num;
        case MA_WATER: doWater(id);
		case MA_ROBOT: createRobot(id);
    }
    
    showSkillMenu(id);
}

/*============================================= MachineRobot ===========================================*/
createRobot(id)
{
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
}

public robotThink(entity)
{
	if (!pev_valid(entity) ) return;

	static id;
	static Float:vOrigin[3], Float:tOrigin[3], Float:fVelocity[3], Float:vAngle[3];
	id = pev(entity, pev_owner);

	if(!is_user_connected(id)) {
		remove_entity(entity);
		return;
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
}
doFire(entity)
{
	static id; id = pev(entity, pev_owner);
	if( !is_user_alive(id)) return;

	static near; near = findNearPlayers(id);

	if( near ) {
		static Float:vOrigin[3], Float:eOrigin[3];

		ExecuteHamB(Ham_TakeDamage, near, id, id, 375.0, DMG_SONIC);
		
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
}

findNearPlayers(id)
{
	new near = 0;
	new Float:vOrigin[3], Float:eOrigin[3];
	new Float:distance = -1.0;
	pev(id, pev_origin, vOrigin);

	for(new i = 1; i <= 32; ++i) {

		if( !is_user_connected(i) || !is_user_alive(i) || 
		i==id || get_user_team(id) == get_user_team(i) ) continue;	

		pev(i, pev_origin, eOrigin);
		new Float:temp = get_distance_f(vOrigin, eOrigin);
		if( temp <= 450.0 && temp > distance) {   //攻擊距離設定
			if( nonBlockedByWorld(id, vOrigin, eOrigin) ) {
				distance = temp;
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
	new ent = gCurrentRobot[id];
	remove_entity(ent);
}
/*============================================= Treasure ===============================================*/
createDick(id)
{
	if( halflife_time() >= gTreasureCd[id] && gCurrentDick[id] < MAXDICK) {

		new ent = create_entity(gInfoTarget);

		entity_set_string(ent, EV_SZ_classname, gDickClassName);
		entity_set_model(ent, gTreasureModel[random_num(0,3)] );
		entity_set_size(ent, Float:{-7.0, -7.0, -7.0}, Float:{7.0, 7.0, 7.0});
		entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
		entity_set_edict(ent, EV_ENT_owner, id);
		entity_set_float(ent, EV_FL_fuser1, random_float(5.0, 90.0));  // 紀錄垂直軸隨機偏移量
		entity_set_float(ent, EV_FL_fuser2, random_float(-50.0, 50.0)); // 紀錄水平軸隨機偏移量

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
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.05);
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

			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 99999.9);
			entity_set_int(ent, EV_INT_iuser1, 1);

			new Float:fAim[3], Float:xOffsets[3];
			velocity_by_aim(id, 1300, fAim);
			makeRandomOffsets(id, entity_get_float(ent, EV_FL_fuser2), xOffsets);

			// 減去偏移值使中心點瞄準
			fAim[0] -= xOffsets[0];
			fAim[1] -= xOffsets[1]; 
			fAim[2] -= entity_get_float(ent, EV_FL_fuser1);
			fAim[2] += 10.0;
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
removeAllDick(id)
{
	if( gCurrentDick[id] <= 0 ) return;

	for (new i = 0; i < MAXDICK; ++i)
	{
		new ent = gHaveDick[id][i];
		gHaveDick[id][i] = 0;

		if ( !is_valid_ent(ent) || ent == 0 ) continue;
		remove_entity(ent);
		gCurrentDick[id] = 0;
	}
}
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

    velocity_by_aim(id, 625, velocity);
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
	if (!is_valid_ent(ent)) return;

	doWaterHeal(ent);
	emit_sound(ent, CHAN_STATIC, gszPortalSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 4.62);
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
		if( health < 2000.0) {
			set_pev(healer, pev_health, 2000.0);

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
/*========================================== COMMON FUNCTION =============================================*/
/*========================================== FUNCTION END ================================================*/
public fw_touch(ent, ptr)
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

public fw_cmdstart(id, uc_handle, seed)
{
    if (!is_user_alive(id)) return FMRES_IGNORED;
    static button;
    button = get_uc(uc_handle, UC_Buttons);
    
    if (button & IN_USE) {
        switch(gPlayerSelect[id]){
            
        }
    }
    
    if (button & IN_USE && (pev(id, pev_oldbuttons) & IN_USE))
    {
        if(gPlayerSelect[id] ==  SK_TREASURE)
            createDick(id);
        return FMRES_HANDLED;

	} else if ( !(button & IN_USE) && (pev(id, pev_oldbuttons) & IN_USE)) {
		doDick(id);
		return FMRES_HANDLED;
	}
    return FMRES_IGNORED;
}
public eventPlayerDeath()
{
	new index = read_data(2);
	doDick(index);
}
public client_putinserver(id)
{
}

public client_disconnect(id)
{
	gPlayerSelect[id] = -1;
	doDick(id);
	deleteOldWater(id);
	removeRobot(id);
}
public plugin_natives()
{
	register_native("test_tr", "native_test_tr", 1);
}
public native_test_tr(id)
{
	createDick(id);
	doDick(id);
}
/*============================================== STOCK =======================================*/
stock attachBeamCylinder(Float:position[3])
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_BEAMTORUS);
	write_coord(floatround(position[0]));
	write_coord(floatround(position[1]));
	write_coord(floatround(position[2]));
	write_coord(floatround(position[0]));
	write_coord(floatround(position[1]));
	write_coord(floatround(position[2])+450);
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