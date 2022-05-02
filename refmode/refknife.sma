#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <xs>
#include <vector>
#include <orpheu>

new const v_model[] = "models/v_samuraisword.mdl"
new const p_model[] = "models/p_samuraisword.mdl"
new const weapon_sound[][] = 
{
	"weapons/samurai_deploy1.wav",
	"weapons/samurai_slash1.wav",
	"weapons/samurai_slash2.wav",
	"weapons/samurai_hit1.wav",
	"weapons/samurai_hit2.wav",
	"weapons/samurai_hit3.wav",
	"weapons/samurai_hit4.wav",
	"weapons/samurai_hitwall1.wav",
	"weapons/samurai_stab.wav"
}
enum
{
	SOUND_DRAW = 0,
	SOUND_SLASH1,
	SOUND_SLASH2,
	SOUND_HIT1,
	SOUND_HIT2,
	SOUND_HIT3,
	SOUND_HIT4,
    SOUND_HITWALL,
    SOUND_STAB
}
enum
{
	KNIFE_ANIM_IDLE = 0,
	KNIFE_ANIM_SLASH1,
	KNIFE_ANIM_SLASH2,
	KNIFE_ANIM_DRAW,
	KNIFE_ANIM_STAB_HIT,
	KNIFE_ANIM_STAB_MISS,
	KNIFE_ANIM_MIDSLASH1,
	KNIFE_ANIM_MIDSLASH2
}

new const skills_sound[][] = 
{
	"ref/vulcanus9_stab_miss.wav",
	"weapons/c4_explode1.wav",
	"ref/airplane2.wav",
	"ref/vulcanus9_draw.wav",
	"ref/moonbreak_summon.wav",
	"ref/moonbreak_hit.wav",
	"ref/freeze_hit.wav"
}
enum
{
	VULCANUS9_BLADE = 0,
	FIRESTAR_EXPLODE_SOUND,
	FIRESTAR_FLY_SOUND,
	CHANMOFIRE_ATTACK_SOUND,
	MOONBREAK_SUMMON,
	MOONBREAK_HIT,
	ICEWING_HIT
}

#define WEAPON_REF "weapon_knife"
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flNextIdle 48
#define m_flNextAttack 83

/*   CLASS NAME   */
#define VULCANUS9 "vulcanus9_magic"
#define VULCANUS9_PARTICLE "vulcanus9_particle"
#define MAGIC_CIRCLE_CLASS "magic_circle_ring"
#define FIREWAVE_CLASS "slash_firewave"
#define ELEMENT_CLASS "elements"
#define FIRESTAR_CLASS "firestars"
#define CHANMO_CLASS "chanmo_magic"
#define CHANMOFIRE_CLASS "chanmo_fire"
#define MOONBREAK_CLASS "moon_breker"
#define FADEOUT_CLASS "fadeout"
#define DELETE_CLASS "think_delete"
#define ICEWING_CLASS "icewing"
#define FLYKNIFE_CLASS "flyknife"

/* MODELS PATH */
new const vulcanus9[] = "models/ref/vulcanus9.mdl"
new const firewave_model[] = "models/ref/fireslash.mdl"
new const element_model[] = "models/ref/element.mdl"
new const firestar_model[] = "models/ref/firemagic.mdl"
new const moonbreak_model[] = "models/ref/moon_break.mdl"
new const icearrow_model[] = "models/ref/ice_arrow.mdl"
new const chanmomagic_model[] = "models/ref/mumei.mdl"
new const icewing_model[] = "models/ref/icewing.mdl"
new const flyknifedragon_model[] = "models/ref/flyknifedragon.mdl"

new const circles3[] = "models/circles3.mdl"  // test

new const muzzleflash63[] = "sprites/ref/muzzleflash63.spr"
new const holybombexp_model[] = "sprites/ref/holybomb_exp.spr"
new const yukiramy_model[] = "sprites/ref/yukiramy.spr"
new const moonkiller_model[] = "sprites/ref/moonkiller.spr"
new const moonwave_model[] = "sprites/ref/skills2.spr"

new g_had_refknife[33], g_had_element[33]
new g_moonBreakLightFlag = 0

public plugin_init()
{
	register_plugin("RefKnife", "1.0", "Reff")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")

	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_Think, "fw_Think")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_REF, "fw_Weapon_PrimaryAttack", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_REF, "fw_Weapon_SecondaryAttack", 1)
	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, WEAPON_REF, "fw_Weapon_SendAnim", 1)

	register_clcmd("getrk", "getRefKnife")
	register_clcmd("nskill", "new_skills")
}
public new_skills(id) { 
	flyknifeDragonAttack(id)
}

new firestar_explode, chanmo_explode, chanmo_follow, moonkiller_explode, moonwave
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, v_model)
	engfunc(EngFunc_PrecacheModel, p_model)
	engfunc(EngFunc_PrecacheModel, vulcanus9)
	engfunc(EngFunc_PrecacheModel, firewave_model)
	engfunc(EngFunc_PrecacheModel, element_model)
	engfunc(EngFunc_PrecacheModel, firestar_model)
	engfunc(EngFunc_PrecacheModel, chanmomagic_model)
	engfunc(EngFunc_PrecacheModel, icearrow_model)
	engfunc(EngFunc_PrecacheModel, moonbreak_model)
	engfunc(EngFunc_PrecacheModel, icewing_model)
	engfunc(EngFunc_PrecacheModel, flyknifedragon_model)

	firestar_explode = engfunc(EngFunc_PrecacheModel, muzzleflash63)
	chanmo_explode = engfunc(EngFunc_PrecacheModel, holybombexp_model)
	chanmo_follow = engfunc(EngFunc_PrecacheModel, yukiramy_model)
	moonkiller_explode = engfunc(EngFunc_PrecacheModel, moonkiller_model)
	moonwave = engfunc(EngFunc_PrecacheModel, moonwave_model)

	new i
	for(i = 0; i < sizeof(weapon_sound); i++)
		engfunc(EngFunc_PrecacheSound, weapon_sound[i])
	for(i = 0; i < sizeof(skills_sound); i++)
		engfunc(EngFunc_PrecacheSound, skills_sound[i])

	engfunc(EngFunc_PrecacheModel, circles3)
}

public plugin_natives()
{
	register_native("get_refknife", "getRefKnife", 1)
	register_native("use_firestar", "fireStar", 1)
	register_native("use_moonsword", "adurasMoonlightSword", 1)
	register_native("use_enchant", "enChant", 1)
	register_native("use_moonbreak", "prepareMoonBreak", 1)
	register_native("use_chanmo", "ChanmoMagicImplement", 1)
	register_native("get_element_status", "get_element_status", 1)
	register_native("use_icewing", "iceWingAttack", 1)
	register_native("use_flyknife", "flyknifeDragonAttack", 1)
}

public getRefKnife(id)
{
    if( !is_user_alive(id) ) return

    g_had_refknife[id] = 1
    fm_give_item(id, WEAPON_REF)

    if (get_user_weapon(id) == CSW_KNIFE)
        Event_CurWeapon(id)
    else
        engclient_cmd(id, WEAPON_REF)
}

public adurasMoonlightSword(id)
{
	#define AFTER_ATTACKTIME 0.3
	new Float:origin[3], Float:angles[3]
	pev(id, pev_origin, origin)
	pev(id, pev_angles, angles)	

	/* 月光劍本體 */
	new moonlightSword = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(moonlightSword, pev_movetype, MOVETYPE_NONE)
	set_pev(moonlightSword, pev_owner, id)
	set_pev(moonlightSword, pev_classname, VULCANUS9)
	set_pev(moonlightSword, pev_solid, SOLID_NOT)
	set_pev(moonlightSword, pev_origin, origin)
	set_pev(moonlightSword, pev_impacttime, get_gametime() + 0.8) // 停止攻擊開始消失的時間
	set_pev(moonlightSword, pev_rendermode, kRenderTransAlpha)
	set_pev(moonlightSword, pev_renderamt, 255.0)

	engfunc(EngFunc_SetModel, moonlightSword, vulcanus9)
	angles[0] = 0.0
	angles[1] += 115.0 // 起始角度劍端指向左後方
	set_pev(moonlightSword, pev_angles, angles)
	set_pev(moonlightSword, pev_nextthink, get_gametime() + AFTER_ATTACKTIME) // 停留幾秒後開始揮刀
	set_task(0.4, "emitsound_vulcanus9_task", moonlightSword)

	/* 月光劍粒子 */
	for(new i = 2; i <= 7; i++) {
		new particle = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(particle, pev_classname, VULCANUS9_PARTICLE)
		set_pev(particle, pev_owner, id)
		set_pev(particle, pev_movetype, MOVETYPE_NOCLIP)
		set_pev(particle, pev_solid, SOLID_TRIGGER)
		set_pev(particle, pev_groupinfo, moonlightSword) // 紀錄此粒子所屬的月光劍
		set_pev(particle, pev_iuser1, i) // 紀錄此粒子索引值
		// engfunc(EngFunc_SetModel, particle, circles3)
		engfunc(EngFunc_SetSize, particle, Float:{-60.0, -60.0, -25.0}, Float:{60.0, 60.0, 25.0} ) // 粒子實體大小
		set_pev(particle, pev_nextthink, get_gametime() + AFTER_ATTACKTIME)
	}
}

public fireStar(id)
{
	/* 火流星 */
	new firestarEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(firestarEnt, pev_classname, FIRESTAR_CLASS)
	set_pev(firestarEnt, pev_movetype, MOVETYPE_NONE)
	set_pev(firestarEnt, pev_solid, SOLID_NOT)
	set_pev(firestarEnt, pev_owner, id)
	set_pev(firestarEnt, pev_animtime, get_gametime())
	set_pev(firestarEnt, pev_framerate, 1.0)

	new Float:aimOrigin[3]
	fm_get_aim_origin(id, aimOrigin)
	set_pev(firestarEnt, pev_origin, aimOrigin)

	engfunc(EngFunc_SetModel, firestarEnt, firestar_model)
	set_pev(firestarEnt, pev_nextthink, get_gametime() + 9.7) // 幾秒後爆炸(需綁模組動畫)
	client_cmd(0, "spk ^"sound/%s^"", skills_sound[FIRESTAR_FLY_SOUND])
}

public emitsound_vulcanus9_task(id)
{
	emit_sound(id, CHAN_WEAPON, skills_sound[VULCANUS9_BLADE], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE)
		return PLUGIN_HANDLED
	if(!g_had_refknife[id])
		return PLUGIN_HANDLED
		
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, p_model)
	return PLUGIN_CONTINUE
}

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED

	static classname[32], id
	pev(ent, pev_classname, classname, sizeof(classname))
	id = pev(ent, pev_owner)
	
	/* Fade out */
	if( equal(classname, FADEOUT_CLASS) )
	{
		static Float:fadeSpeed, Float:renderamt
		pev(ent, pev_fuser1, fadeSpeed) // 此欄位紀錄淡出的速度
		pev(ent, pev_renderamt, renderamt)

		if( renderamt > 0.0 ) {
			if( fadeSpeed > renderamt )  
				set_pev(ent, pev_renderamt, 0.0)
			else
				set_pev(ent, pev_renderamt, renderamt - fadeSpeed) // 漸層淡出的速度
			set_pev(ent, pev_nextthink, get_gametime() + 0.01)

		} else engfunc(EngFunc_RemoveEntity, ent)
	}

	/* 思考移除 */
	if( equal(classname, DELETE_CLASS) ) {
		engfunc(EngFunc_RemoveEntity, ent)
	}

	static Float:impacttime // 給擁有有效期限物件的計時器
	/* 月光劍 */
	if( equal(classname, VULCANUS9) )
	{
		pev(ent, pev_impacttime, impacttime)
		if( get_gametime() < impacttime ) {
			static Float:angles[3]
			pev(ent, pev_angles, angles)
			angles[1] -= 4.5 // 角度轉的速度
			set_pev(ent, pev_angles, angles)
			set_pev(ent, pev_nextthink, get_gametime() + 0.01)

		} else {
			toFadeOutEntity(ent)
		}
	}

	/* 魔法陣 */
	if( equal(classname, MAGIC_CIRCLE_CLASS) ) {
		engfunc(EngFunc_RemoveEntity, ent)
	}
	
	/* 月光劍粒子 */
	if( equal(classname, VULCANUS9_PARTICLE) ) {

		static parent; parent = pev(ent, pev_groupinfo)

		if( pev_valid(parent) ) {
			static Float:angles[3], Float:origin[3]
			static indexs; indexs = pev(ent, pev_iuser1)
			pev(parent, pev_angles, angles)
			pev(parent, pev_origin, origin)

			origin[0] += floatcos(angles[1], degrees) * (90.0 * indexs) // 半徑*index
			origin[1] += floatsin(angles[1], degrees) * (90.0 * indexs)
			set_pev(ent, pev_origin, origin)
			set_pev(ent, pev_nextthink, get_gametime() + 0.01)

		} else {
			engfunc(EngFunc_RemoveEntity, ent)
		}
	}

	/* 附魔後揮刀的劍氣 */
	if( equal(classname, FIREWAVE_CLASS) ) {
		toFadeOutEntity(ent, 4.0)
	}

	/* 附魔後元素球特效 */
	if( equal(classname, ELEMENT_CLASS) ) {
		set_pev(ent, pev_animtime, get_gametime())
		set_pev(ent, pev_nextthink, get_gametime() + 1.0)
	}

	/* 火流星 */
	if( equal(classname, FIRESTAR_CLASS) ) {

		new Float:fOrigin[3]
		pev(ent, pev_origin, fOrigin)

		new victim = FM_NULLENT
		while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, 1500.0) ) != 0 ) { // 火流星爆炸範圍
			if(!is_user_alive(victim) )
				continue
			ExecuteHamB(Ham_TakeDamage, victim, ent, id, 10000.0, DMG_BURN)
		}

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fOrigin, 0)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2])
		write_short(firestar_explode)
		write_byte(210)
		write_byte(10)
		write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
		message_end()

		for(new i = 1; i <= 2; ++i)
			client_cmd(0, "spk ^"sound/%s^"", skills_sound[FIRESTAR_EXPLODE_SOUND])
		client_cmd(0, "room_type 6")

		engfunc(EngFunc_RemoveEntity, ent)
	}

	/* 破月者 */
	if( equal(classname, MOONBREAK_CLASS) ) {

		new Float:fOrigin[3]
		pev(ent, pev_origin, fOrigin)

		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
		write_byte(TE_BEAMCYLINDER)
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2])
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2] + 1200.0)
		write_short(moonwave) // sprite
		write_byte(0) // startframe
		write_byte(0) // framerate
		write_byte(10) // life (時間長度)
		write_byte(30) // width
		write_byte(0) // noise
		write_byte(255) // red (顏色 R)
		write_byte(255) // green (顏色 G)
		write_byte(255) // blue (顏色 B)
		write_byte(180) // brightness
		write_byte(0) // speed
		message_end()

		client_cmd(0, "spk ^"sound/%s^"", skills_sound[MOONBREAK_HIT])

		new Float:timers = 0.0, taskparm[2]
		taskparm[0] = id

		new victim = FM_NULLENT
		while( (victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, 1200.0) ) != 0 ) { // 月亮破壞抓取範圍
			if(!is_user_alive(victim) || id == victim )
				continue

			timers += 0.1
			set_task(timers, "moonbreakAttackTask", victim, taskparm, sizeof taskparm)
		}

		set_task(timers + 0.1, "moonbreakSetDefaultLighTask")
		toFadeOutEntity(ent, 3.0)
	}

	/* 常魔紋連射魔法陣 */
	if( equal(classname, CHANMO_CLASS) ) {
		pev(ent, pev_impacttime, impacttime)

		if( get_gametime() < impacttime ) {
			ChanmoMagicAttack(ent)
			set_pev(ent, pev_nextthink, get_gametime() + 0.15)

		} else
			engfunc(EngFunc_RemoveEntity, ent)
	}

	/* 冰風暴 */
	if( equal(classname, ICEWING_CLASS) ) {

		#define ICEWING_DAMAGE 475.0
		WeaponDamage_Config(id, ent, 0, 0, 350.0, 0.0, ICEWING_DAMAGE, 50.0)

		new Float:fOrigin[3]
		pev(ent, pev_origin, fOrigin)

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fOrigin, 0)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2])
		write_short(chanmo_explode)
		write_byte(45)
		write_byte(30)
		write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
		message_end()

		emit_sound(ent, CHAN_WEAPON, skills_sound[ICEWING_HIT], 1.0, ATTN_NORM, 0, PITCH_NORM)
		engfunc(EngFunc_RemoveEntity, ent)
	}

	/* 龍牙刃 */
	if( equal(classname, FLYKNIFE_CLASS) ) {

		pev(ent, pev_fuser1, impacttime)

		if( get_gametime() < impacttime ) {

			static Float:velocity[3]

			pev(ent, pev_velocity, velocity)
			xs_vec_neg(velocity, velocity)
			set_pev(ent, pev_velocity, velocity)
			set_pev(ent, pev_nextthink, get_gametime() + 0.5)

		} else
			engfunc(EngFunc_RemoveEntity, ent)
	}

	return FMRES_IGNORED
}

public moonbreakSetDefaultLighTask() {
	// 代表目前總發動次數
	if( --g_moonBreakLightFlag <= 0 ) {
		engfunc(EngFunc_LightStyle, 0, "") // Default value
	}
}

public fw_Touch(ent, ptd)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED
	
	static classname[32], id
	pev(ent, pev_classname, classname, sizeof(classname))
	id = pev(ent, pev_owner)

	if( equal(classname, VULCANUS9_PARTICLE) ) {

		if( id == ptd )
			return FMRES_IGNORED

		static Float:nextValidAttackTime[33]
		new Float:gameTime = get_gametime()

		if( gameTime >= nextValidAttackTime[ptd] ) {
			nextValidAttackTime[ptd] = gameTime + 0.1
			#define VULCANUS9_DAMAGE 700.0
			fake_traceattack(ent, ptd, VULCANUS9_DAMAGE, DMG_SLASH)
		}
	}

	if( equal(classname, CHANMOFIRE_CLASS) ) {

		new Float:fOrigin[3]
		pev(ent, pev_origin, fOrigin)

		if( id == ptd ) return FMRES_IGNORED
		#define CHANMOFIRE_DAMAGE 275.0
		WeaponDamage_Config(id, ent, 0, 0, 150.0, 0.0, CHANMOFIRE_DAMAGE, 0.01)

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fOrigin, 0)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2])
		write_short(chanmo_explode)
		write_byte(15)
		write_byte(40)
		write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
		message_end()

		engfunc(EngFunc_RemoveEntity, ent)
	}

	if( equal(classname, FLYKNIFE_CLASS) ) {

		if( id == ptd ) return FMRES_IGNORED
		fake_traceattack(ent, ptd, 175.0, DMG_SONIC)
	}

	return FMRES_IGNORED
}


public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) ) 
		return FMRES_IGNORED
	if (!g_had_refknife[id])
		return FMRES_IGNORED
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(ent) )
		return FMRES_IGNORED
	
	new Float:game_time = get_gametime()
	static CurButton, OldButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	OldButton = pev(id, pev_oldbuttons)

	static Float:nextJumpTime[33]
	if( (CurButton & IN_JUMP) && (CurButton & IN_DUCK) ) {
		if( game_time >= nextJumpTime[id] ) {
				
			new Float:velocity[3];
			velocity_by_aim(id, 910, velocity); // 大跳距離
			velocity[2] = 300.0;
			set_pev(id, pev_velocity, velocity);

			nextJumpTime[id] = game_time + 0.1;
		}
	}

	if( (CurButton & IN_USE) && (CurButton & IN_RELOAD) ) {
		if(get_user_weapon(id) != CSW_KNIFE)
			return FMRES_IGNORED
		if(get_pdata_float(id, m_flNextAttack, 5) > 0.0 )
			return FMRES_IGNORED

		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_USE)
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_RELOAD)
		enChant(id)
	}

	if( CurButton & IN_ATTACK && g_had_element[id] ) {

		if(get_user_weapon(id) != CSW_KNIFE)
			return FMRES_IGNORED
		if(get_pdata_float(id, m_flNextAttack, 5) > 0.0 ||  
		get_pdata_float(ent, m_flNextPrimaryAttack, 4) > 0.0 || get_pdata_float(ent, m_flNextSecondaryAttack, 4) > 0.0 )
			return FMRES_IGNORED

		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)

		slashFireWave(id)
		RadiusAttack(id)
		set_next_attacktime(id, ent, 0.2) // 附魔後攻速
		set_pdata_float(ent, m_flNextIdle, 1.2, 4)
	}

	return FMRES_IGNORED
}

public flyknifeDragonAttack(id)
{
	new const Float:angles_offset[] = {-18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0};
	new Float:angels[3], Flaot:origin[3]
	pev(id, pev_v_angle, angels)
	pev(id, pev_origin, origin)

	new Float:offset_angle[3], Float:velocity[3]

	for(new i = 0; i < sizeof angles_offset; i++) {

		new flyknife = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target") )
		set_pev(flyknife, pev_classname, FLYKNIFE_CLASS)
		set_pev(flyknife, pev_movetype, MOVETYPE_NOCLIP)
		set_pev(flyknife, pev_solid, SOLID_TRIGGER)
		set_pev(flyknife, pev_owner, id)
		set_pev(flyknife, pev_origin, origin)
		set_pev(flyknife, pev_fuser1, get_gametime() + 10.0) // 消失時間

		engfunc(EngFunc_SetModel, flyknife, flyknifedragon_model)
		engfunc(EngFunc_SetSize, flyknife, Float:{-10.0, -20.0, -5.0}, Float:{10.0, 20.0, 5.0});
		fm_set_rendering(flyknife, kRenderFxGlowShell, 224, 102, 255, kRenderNormal, 16)

		offset_angle[0] = 0.0
		offset_angle[1] = angels[1] + angles_offset[i]
		offset_angle[2] = angels[2]
		set_pev(flyknife, pev_angles, offset_angle)

		angle_vector(offset_angle, ANGLEVECTOR_FORWARD, velocity)
		xs_vec_mul_scalar(velocity, 2000.0, velocity)

		set_pev(flyknife, pev_velocity, velocity)
		set_pev(flyknife, pev_nextthink, get_gametime() + 0.5)

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0)
		write_byte(TE_BEAMFOLLOW)
		write_short(flyknife)
		write_short(chanmo_follow)
		write_byte(5); // life
		write_byte(2); // widtd
		write_byte(255); // r
		write_byte(231); // g
		write_byte(139); // b
		write_byte(225); // brightness
		message_end()
	}

}

public ChanmoMagicAttack(ent)
{
	static Float:fStart[3], Float:velocity[3], Float:angles[3], id
	id = pev(ent, pev_owner)

	new chanmoFire = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(chanmoFire, pev_movetype, MOVETYPE_FLY)
	set_pev(chanmoFire, pev_owner, id)
	set_pev(chanmoFire, pev_classname, CHANMOFIRE_CLASS)
	set_pev(chanmoFire, pev_solid, SOLID_TRIGGER)
	engfunc(EngFunc_SetModel, chanmoFire, icearrow_model)
	engfunc(EngFunc_SetSize, chanmoFire, Float:{-3.0, -3.0, -3.0}, Float:{3.0, 3.0, 3.0} )

	pev(ent, pev_angles, angles)
	pev(ent, pev_origin, fStart)
	set_pev(chanmoFire, pev_origin, fStart)

	angles[0] += random_float(-10.0, 10.0)
	angles[1] += random_float(-10.0, 10.0)
	angles[2] += random_float(-10.0, 10.0)
	set_pev(chanmoFire, pev_angles, angles)
	angles[0] *= -1.0

	new Float:dest[3]
	engfunc(EngFunc_MakeVectors, angles)
	global_get(glb_v_forward, dest)
	xs_vec_mul_scalar(dest, 9999.0, dest)
	xs_vec_add(fStart, dest, dest)

	engfunc(EngFunc_TraceLine, fStart, dest, 0, id, 0)
	get_tr2(0, TR_vecEndPos, dest)

	get_speed_vector(fStart, dest, 2400.0, velocity)
	set_pev(chanmoFire, pev_velocity, velocity)
	
	emit_sound(ent, CHAN_WEAPON, skills_sound[CHANMOFIRE_ATTACK_SOUND], 1.0, ATTN_NORM, 0, PITCH_NORM)

	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_BEAMFOLLOW);
	write_short(chanmoFire);
	write_short(chanmo_follow);
	write_byte(5); // life
	write_byte(10); // width
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(215); // brightness
	message_end();
}

public ChanmoMagicImplement(id)
{
	new chanmoBody = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(chanmoBody, pev_movetype, MOVETYPE_FLY)
	set_pev(chanmoBody, pev_owner, id)
	set_pev(chanmoBody, pev_classname, CHANMO_CLASS)
	set_pev(chanmoBody, pev_solid, SOLID_NOT)
	engfunc(EngFunc_SetModel, chanmoBody, chanmomagic_model)

	new Float:angles[3]
	pev(id, pev_v_angle, angles)
	angles[0] *= -1.0
	set_pev(chanmoBody, pev_angles, angles)

	new Float:fStart[3]
	get_position(id, 50.0, 0.0, 0.0, fStart)
	set_pev(chanmoBody, pev_origin, fStart)

	set_pev(chanmoBody, pev_impacttime, get_gametime() + 7.0)
	set_pev(chanmoBody, pev_nextthink, get_gametime() + 1.0)
}

public prepareMoonBreak(id)
{
	new moon = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target") )
	set_pev(moon, pev_movetype, MOVETYPE_NONE)
	set_pev(moon, pev_owner, id)
	set_pev(moon, pev_classname, MOONBREAK_CLASS)
	set_pev(moon, pev_solid, SOLID_NOT)
	set_pev(moon, pev_animtime, get_gametime() )
	set_pev(moon, pev_framerate, 1.0)
	set_pev(moon, pev_rendermode, kRenderTransAlpha);
	set_pev(moon, pev_renderamt, 255.0)

	new Float:origin[3], Float:angles[3]
	pev(id, pev_origin, origin)
	set_pev(moon, pev_origin, origin)

	pev(id, pev_v_angle, angles)
	angles[2] = 0.0
	set_pev(moon, pev_angles, angles)

	engfunc(EngFunc_SetModel, moon, moonbreak_model)
	set_pev(moon, pev_nextthink, get_gametime() + 2.0)
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_byte(130) // radius in 10's
	write_byte(100) // rgb
	write_byte(100)
	write_byte(100)
	write_byte(60) // life in 10's
	write_byte(20) // decay rate in 10's
	message_end()
	
	client_cmd(0, "spk ^"sound/%s^"", skills_sound[MOONBREAK_SUMMON])
	engfunc(EngFunc_LightStyle, 0, "a")
	g_moonBreakLightFlag++
}

public moonbreakAttackTask(const param_menu[], id)
{
	if( !is_user_alive(id) )
		return PLUGIN_CONTINUE

	static Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)

	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(moonkiller_explode)
	write_byte(10)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()

	#define PARMS_ID 0
	#define MOON_DAMAG 1450.0
	ExecuteHamB(Ham_TakeDamage, id, param_menu[PARMS_ID], param_menu[PARMS_ID], MOON_DAMAG, DMG_SLASH)

	return PLUGIN_CONTINUE
}

public iceWingAttack(id)
{
	new icewing, Float:fOrigin[3], Float:radOrigin[3], Float:angles[3]
	pev(id, pev_origin, fOrigin)

	for(new i = 1; i <= 10; i++) {	

		icewing = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target") )
		set_pev(icewing, pev_movetype, MOVETYPE_FLY)
		set_pev(icewing, pev_owner, id)
		set_pev(icewing, pev_classname, ICEWING_CLASS)
		set_pev(icewing, pev_solid, SOLID_NOT)
		set_pev(icewing, pev_animtime, get_gametime())
		set_pev(icewing, pev_framerate, 1.0)

		radOrigin[0] = fOrigin[0] + random_float(-500.0, 500.0)
		radOrigin[1] = fOrigin[1] + random_float(-500.0, 500.0)
		radOrigin[2] = fOrigin[2] - 18.0
		set_pev(icewing, pev_origin, radOrigin)

		pev(id, pev_v_angle, angles)
		angles[1] = 0.0
		set_pev(icewing, pev_angles, angles)

		engfunc(EngFunc_SetModel, icewing, icewing_model)
		set_pev(icewing, pev_nextthink, get_gametime() + 1.95)
	}
}

public enChant(id)
{
	new ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if( !g_had_element[id] ) {

		g_had_element[id] = 1
		client_print(id, print_chat, "附魔啟動")
		set_next_attacktime(id, ent, 1.5) // 施放附魔後的硬直時間
		set_weapon_anim(id, KNIFE_ANIM_DRAW)

		new elements = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(elements, pev_movetype, MOVETYPE_FOLLOW)
		set_pev(elements, pev_owner, id)
		set_pev(elements, pev_classname, ELEMENT_CLASS)
		set_pev(elements, pev_solid, SOLID_NOT)
		set_pev(elements, pev_aiment, id)
		set_pev(elements, pev_animtime, get_gametime())
		set_pev(elements, pev_framerate, 1.0)

		new Float:origin[3]
		pev(id, pev_origin, origin)
		set_pev(elements, pev_origin, origin)
		
		engfunc(EngFunc_SetModel, elements, element_model)
		set_pev(elements, pev_nextthink, get_gametime() + 1.0)

	} else {

		g_had_element[id] = 0
		client_print(id, print_chat, "附魔關閉")
		set_next_attacktime(id, ent, 0.7) // 解除附魔後的硬直時間
		set_weapon_anim(id, KNIFE_ANIM_DRAW)

		new element = fm_find_ent_by_owner(0, ELEMENT_CLASS, id)
		engfunc(EngFunc_RemoveEntity, element)
	}

}

#define pDataKey_iOwner 41
#define pData_Item 4
new g_firestarCounter[33], Float:g_skillsNexttime[33]
public fw_Weapon_PrimaryAttack(ent)
{
	static Float:game_time, id
	game_time = get_gametime()
	id = get_pdata_cbase(ent, pDataKey_iOwner, pData_Item)

	if( !is_user_alive(id) )
		return HAM_IGNORED
	if(!g_had_refknife[id] )
		return HAM_IGNORED

	if( game_time > g_skillsNexttime[id] )
		g_firestarCounter[id] = 0
			
	g_skillsNexttime[id] = game_time + 1.0
	g_firestarCounter[id]++

	new skill_name[16], t_count = g_firestarCounter[id] / 2
	switch( t_count ) {
		case 1: skill_name = "月光劍"
		case 2: skill_name = "常魔紋"
		case 3: skill_name = "破月"
		case 4: skill_name = "冰風暴"
		case 5: skill_name = "穿透匕首"
		case 10..9999: skill_name = "火流星"
		default: skill_name = "無"
	}

	client_print(id, print_center, "攻擊計數器: %d [%s]", g_firestarCounter[id], skill_name)

	return HAM_IGNORED
}

public fw_Weapon_SecondaryAttack(ent)
{
	new Float:game_time = get_gametime()
	new id = get_pdata_cbase(ent, pDataKey_iOwner, pData_Item)

	if( !is_user_alive(id) )
		return HAM_IGNORED
	if( !g_had_refknife[id] )
		return HAM_IGNORED

	if( g_firestarCounter[id] >= 2 && game_time <= g_skillsNexttime[id] ) {

		switch( g_firestarCounter[id]/2 ) {
			case 1: adurasMoonlightSword(id)
			case 2: ChanmoMagicImplement(id)
			case 3: prepareMoonBreak(id)
			case 4: iceWingAttack(id)
			case 5: flyknifeDragonAttack(id)
			case 10: fireStar(id)
		}
		g_firestarCounter[id] = 0
	}

	return HAM_IGNORED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_KNIFE || !g_had_refknife[id])
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i') {

        // slash
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') {
			emit_sound(id, channel, weapon_sound[random_num(SOUND_SLASH1, SOUND_SLASH2)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		}

        // hit
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') {

			if (sample[17] == 'w') { // wall
                emit_sound(id, channel, weapon_sound[SOUND_HITWALL], volume, attn, flags, pitch)
                return FMRES_SUPERCEDE
			} else {
				emit_sound(id, channel, weapon_sound[random_num(SOUND_HIT1, SOUND_HIT4)], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE
			}
		}

        // stab  
		if(sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') {
			emit_sound(id, channel, weapon_sound[random_num(SOUND_HIT1, SOUND_HIT4)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public fw_Weapon_SendAnim(ent, anim, skip_local)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new id; id = get_pdata_cbase(ent, 41 , 4)
	if(!g_had_refknife[id])
        return HAM_IGNORED
	
	if(anim == KNIFE_ANIM_MIDSLASH2) {
        set_weapon_anim(id, KNIFE_ANIM_MIDSLASH1)
	}
	return HAM_IGNORED
}

slashFireWave(id)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.2)
	set_pev(ent, pev_classname, FIREWAVE_CLASS)
	engfunc(EngFunc_SetModel, ent, firewave_model)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_rendermode, kRenderTransAdd);
	set_pev(ent, pev_renderamt, 130.0)

	static Float:origin[3], Float:angles[3], Float:velocity[3]

	pev(id, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	
	pev(id, pev_angles, angles)
	angles[0] = random_float(-7.0, 7.0) //上下翻轉
	angles[2] = random_float(-18.0, 18.0) //左右翻轉
	set_pev(ent, pev_angles, angles)

	velocity_by_aim(id, 5, velocity)
	set_pev(ent, pev_velocity, velocity)
}

public get_element_status(id)
{
	return g_had_element[id]
}

stock toFadeOutEntity(ent, Float:fadeSpeed=5.0)
{
	set_pev(ent, pev_classname, FADEOUT_CLASS)
	set_pev(ent, pev_fuser1, fadeSpeed)
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
}

stock set_next_attacktime(id, weaponEnt, Float:time)
{
	set_pdata_float(weaponEnt, m_flNextPrimaryAttack, time, 4)
	set_pdata_float(weaponEnt, m_flNextSecondaryAttack, time, 4)
	set_pdata_float(id, m_flNextAttack, time, 5) 
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id)) return
	set_pev(id, pev_weaponanim, anim)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
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
	return 1
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

/* ----------------------------------------- 範圍攻擊區域 -------------------------------------------------- */

#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_METAL			2
#define	RESULT_HIT_GENERIC			3

RadiusAttack(id)
{
	#define ATTACK_RANGE 185.0
	#define ATTACK_ANGLE 0.0
	#define ATTACK_DAMAGE 70.0
	#define ATTACK_KNOCK 2.0

	new iHitResult = KnifeAttack_Main(id, 1, ATTACK_RANGE, ATTACK_ANGLE, ATTACK_DAMAGE, ATTACK_KNOCK)
	switch (iHitResult)
	{
		case RESULT_HIT_PLAYER : emit_sound(id, CHAN_WEAPON, weapon_sound[random_num(SOUND_HIT1, SOUND_HIT4)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		// case RESULT_HIT_METAL : ...
		// case RESULT_HIT_GENERIC : ...
	}
}

stock KnifeAttack_Main(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
{
	new iHitResult
	if(fAngle > 0.0) iHitResult = KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
	else iHitResult = KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack)

	return iHitResult
}

stock KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
{
	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
	
	get_tr2(tr, TR_flFraction, flFraction);

	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new iHitResult = RESULT_HIT_NONE;
	
	if (flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit);
		
		new iTtextureType, pTextureName[64];
		engfunc(EngFunc_TraceTexture, 0, vecSrc, vecEnd, pTextureName, charsmax(pTextureName));
		iTtextureType = dllfunc(DLLFunc_PM_FindTextureType, pTextureName);
		
		if (iTtextureType == 'M') iHitResult = RESULT_HIT_METAL
		else iHitResult = RESULT_HIT_GENERIC;
		
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 3.0;

			iHitResult = RESULT_HIT_PLAYER;
		}

		if (pev_valid(pEntity))
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			Stock_Fake_KnockBack(id, pEntity, flKnockBack)

			ClearMultiDamage();
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
			ApplyMultiDamage(id, id);
			
			if (IsAlive(pEntity))
			{
				free_tr2(tr);
				return iHitResult;
			}
		}
	}
	free_tr2(tr);
	return iHitResult;
}

stock KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bNoTraceCheck = 0, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
{
	new Float:vecOrigin[3], Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	pev(id, pev_origin, vecOrigin);

	new iHitResult = RESULT_HIT_NONE;
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
	
	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction < 1.0) 
	{
		new iTtextureType, pTextureName[64];
		engfunc(EngFunc_TraceTexture, 0, vecSrc, vecEnd, pTextureName, charsmax(pTextureName));
		iTtextureType = dllfunc(DLLFunc_PM_FindTextureType, pTextureName);
		
		if (iTtextureType == 'M') iHitResult = RESULT_HIT_METAL
		else iHitResult = RESULT_HIT_GENERIC
	}
	
	new Float:vecEndZ = vecEnd[2];
	
	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0)
	{
		if (!pev_valid(pEntity))
			continue;
		if (id == pEntity)
			continue;
		if (!IsAlive(pEntity))
			continue;
		if (!CheckAngle(id, pEntity, fAngle))
			continue;

		GetGunPosition(id, vecSrc);
		Stock_Get_Origin(pEntity, vecEnd);
		
		vecEnd[2] = vecSrc[2] + (vecEndZ - vecSrc[2]) * (get_distance_f(vecSrc, vecEnd) / flRange);

		xs_vec_sub(vecEnd, vecSrc, vecForward);
		xs_vec_normalize(vecForward, vecForward);
		xs_vec_mul_scalar(vecForward, flRange, vecForward);
		xs_vec_add(vecSrc, vecForward, vecEnd);

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);

		get_tr2(tr, TR_flFraction, flFraction);
		
		if (flFraction < 1.0)
		{
			if (IsPlayer(pEntity) || IsHostage(pEntity))
			{
				iHitResult = RESULT_HIT_PLAYER;
				
				if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
					flDamage *= 3.0;
			}

			if (get_tr2(tr, TR_pHit) == pEntity || bNoTraceCheck)
			{
				engfunc(EngFunc_MakeVectors, v_angle);
				global_get(glb_v_forward, vecForward);

				if (iHitgroup != -1) set_tr2(tr, TR_iHitgroup, iHitgroup);

				Stock_Fake_KnockBack(id, pEntity, flKnockBack)

				ClearMultiDamage();
				ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
				ApplyMultiDamage(id, id);
			}
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock fake_traceattack(ent, victim, Float:damages, dmgBit)
{
	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3]
	new id = pev(ent, pev_owner)
	pev(ent, pev_origin, vecSrc)
	pev(victim, pev_origin, vecEnd)
	xs_vec_sub(vecEnd, vecSrc, v_angle)
	angle_vector(v_angle, ANGLEVECTOR_FORWARD, v_angle)
	new tr = create_tr2()
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
	ClearMultiDamage()
	ExecuteHamB(Ham_TraceAttack, victim, id, damages, vecForward, tr, dmgBit)
	ApplyMultiDamage(id, id)
	free_tr2(tr)
}

stock WeaponDamage_Config(id, iEnt, isKnife, bStab, Float:flRadius, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bNoTraceCheck = 0, bitsDamageType = DMG_NEVERGIB | DMG_CLUB, bool:bSkipAttacker=true, bool:bCheckTeam=false)
{
	if(!id) id = iEnt
	
	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	
	if(isKnife) GetGunPosition(id, vecSrc);
	else pev(iEnt, pev_origin, vecSrc)
	
	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);
	
	new Float:flAdjustedDamage, Float:falloff
	falloff = flDamage / flRadius
	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER)
	if (!isKnife) vecSrc[2] += 1.0
	
	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRadius, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (isKnife && !bStab && flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
	
	get_tr2(tr, TR_flFraction, flFraction);

	new iHitResult = RESULT_HIT_NONE;
	
	if (isKnife && flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit);
		
		new iTtextureType, pTextureName[64];
		engfunc(EngFunc_TraceTexture, 0, vecSrc, vecEnd, pTextureName, charsmax(pTextureName));
		iTtextureType = dllfunc(DLLFunc_PM_FindTextureType, pTextureName);
		
		if (iTtextureType == 'M') iHitResult = RESULT_HIT_METAL
		else iHitResult = RESULT_HIT_GENERIC;
		
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 3.0;

			iHitResult = RESULT_HIT_PLAYER;
		}

		if (!bStab && pev_valid(pEntity))
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			Stock_Fake_KnockBack(id, pEntity, flKnockBack)

			ClearMultiDamage();
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
			ApplyMultiDamage(id, id);
			
			if (IsAlive(pEntity))
			{
				free_tr2(tr);
				return iHitResult;
			}
		}
		free_tr2(tr);
	}
	
	new Float:vecEndZ = vecEnd[2];
		
	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if(isKnife)
		{
			if (!pev_valid(pEntity))
				continue;
			if (id == pEntity)
				continue;
			if (!IsAlive(pEntity))
				continue;
			if (!CheckAngle(id, pEntity, fAngle))
				continue;
			if (!can_damage(id, pEntity))
				continue;
		}
		
		if(!isKnife)
		{
			if (pev(pEntity, pev_takedamage) == DAMAGE_NO)
				continue;
			if (bInWater && !pev(pEntity, pev_waterlevel))
				continue;
			if (!bInWater && pev(pEntity, pev_waterlevel) == 3)
				continue;
				
			if(bCheckTeam && pEntity != id)
				if(!can_damage(pEntity, id))
					continue
			
			if(bSkipAttacker && pEntity == id)
				continue
		} 
		
		Stock_Get_Origin(pEntity, vecEnd);
		
		if(isKnife)
		{
			GetGunPosition(id, vecSrc);
			vecEnd[2] = vecSrc[2] + (vecEndZ - vecSrc[2]) * (get_distance_f(vecSrc, vecEnd) / flRadius);
	
			xs_vec_sub(vecEnd, vecSrc, vecForward);
			xs_vec_normalize(vecForward, vecForward);
			xs_vec_mul_scalar(vecForward, flRadius, vecForward);
			xs_vec_add(vecSrc, vecForward, vecEnd);
		
			engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
			get_tr2(tr, TR_flFraction, flFraction);
	
			if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);

			if (isKnife && flFraction < 1.0)
			{
				if (IsPlayer(pEntity) || IsHostage(pEntity))
				{
					iHitResult = RESULT_HIT_PLAYER;
					
					if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
						flDamage *= 3.0;
				}
	
				if (get_tr2(tr, TR_pHit) == pEntity || bNoTraceCheck)
				{
					engfunc(EngFunc_MakeVectors, v_angle);
					global_get(glb_v_forward, vecForward);
	
					if (iHitgroup != -1) set_tr2(tr, TR_iHitgroup, iHitgroup);
	
					Stock_Fake_KnockBack(id, pEntity, flKnockBack)
	
					ClearMultiDamage();
					ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
					ApplyMultiDamage(id, id);
				}
			}
		}
		
		if(!isKnife && pev_valid(pEntity))
		{
			engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, 0, tr)

			new Float:flFraction
			get_tr2(tr, TR_flFraction, flFraction)
	
			if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, 0, tr)
			
			pev(pEntity, pev_origin, vecEnd)
			xs_vec_sub(vecEnd, vecSrc, vecEnd)

			new Float:fDistance = xs_vec_len(vecEnd)
			if(fDistance < 1.0) fDistance = 0.0

			flAdjustedDamage = fDistance * falloff
			
			if(get_tr2(tr, TR_pHit) != pEntity) flAdjustedDamage *= 0.3

			if(flAdjustedDamage <= 0)
				continue

			ClearMultiDamage();
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flAdjustedDamage, vecEnd, tr, bitsDamageType);
			ApplyMultiDamage(id, id);
			
			static Float:Velocity[3]
			Velocity[0] = Velocity[1] *= flKnockBack
			set_pev(pEntity, pev_velocity, Velocity)
			
			iHitResult = RESULT_HIT_PLAYER;
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock CheckAngle(iAttacker, iVictim, Float:fAngle)  return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))
stock IsPlayer(pEntity) return is_user_connected(pEntity)
stock ClearMultiDamage() OrpheuCall(OrpheuGetFunction("ClearMultiDamage"));
stock ApplyMultiDamage(inflictor, iAttacker) OrpheuCall(OrpheuGetFunction("ApplyMultiDamage"), inflictor, iAttacker);
stock GetGunPosition(id, Float:vecScr[3])
{
	new Float:vecViewOfs[3]
	pev(id, pev_origin, vecScr)
	pev(id, pev_view_ofs, vecViewOfs)
	xs_vec_add(vecScr, vecViewOfs, vecScr)
}
stock CheckBack(iEnemy,id)
{
	new Float:anglea[3], Float:anglev[3]
	pev(iEnemy, pev_v_angle, anglea)
	pev(id, pev_v_angle, anglev)
	new Float:angle = anglea[1] - anglev[1] 
	if (angle < -180.0) angle += 360.0
	if (angle <= 45.0 && angle >= -45.0) return 1
	return 0
}
public Stock_Fake_KnockBack(id, iVic, Float:iKb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}
stock IsAlive(pEntity)
{
	if (pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}
stock Stock_Get_Origin(id, Float:origin[3])
{
	new Float:maxs[3],Float:mins[3]
	if (pev(id, pev_solid) == SOLID_BSP)
	{
		pev(id,pev_maxs,maxs)
		pev(id,pev_mins,mins)
		origin[0] = (maxs[0] - mins[0]) / 2 + mins[0]
		origin[1] = (maxs[1] - mins[1]) / 2 + mins[1]
		origin[2] = (maxs[2] - mins[2]) / 2 + mins[2]
	} else pev(id, pev_origin, origin)
}
stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}
stock Float:Stock_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]
	Stock_Get_Origin(id, vId_ori)
	Stock_Get_Origin(iTarget, vTar_ori)
	
	pev(id,pev_angles,vId_ang)
	for(new i=0;i<2;i++) vOricross[i] = vTar_ori[i] - vId_ori[i]
	
	fLength = floatsqroot(vOricross[0]*vOricross[0] + vOricross[1]*vOricross[1])
	
	if (fLength<=0.0)
	{
		vOricross[0]=0.0
		vOricross[1]=0.0
	} else {
		vOricross[0]=vOricross[0]*(1.0/fLength)
		vOricross[1]=vOricross[1]*(1.0/fLength)
	}
	
	engfunc(EngFunc_MakeVectors,vId_ang)
	global_get(glb_v_forward,vForward)
	
	fRad = vOricross[0]*vForward[0]+vOricross[1]*vForward[1]
	
	return fRad   //->   RAD 90' = 0.5rad
}

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}