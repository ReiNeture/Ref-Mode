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
	"ref/vulcanus9_stab_miss.wav"
}
enum
{
	VULCANUS9_BLADE = 0
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

/* MODELS PATH */
new const vulcanus9[] = "models/vulcanus9.mdl"
new const firewave_model[] = "models/ref/fireslash.mdl"
new const magicircle[] = "models/ref/magic_circle.mdl"
new const element_model[] = "models/ref/element.mdl"
new const muzzleflash63[] = "sprites/ref/muzzleflash63.spr"
new const firestar[] = "models/ref/firemagic.mdl"
new const firestarExplosion[] = "weapons/c4_explode1.wav"
new const firestarFly[] = "ref/airplane2.wav"

new const circles3[] = "models/circles3.mdl"  // test

new g_had_refknife[33], g_had_element[33]
new firestar_explode

public plugin_init()
{
	register_plugin("RefKnife", "1.0", "Reff")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")

	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_Think, "fw_Think")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	// register_forward(FM_TraceLine, "fw_TraceLine")
	// register_forward(FM_TraceHull, "fw_TraceHull")

	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, WEAPON_REF, "fw_Weapon_SendAnim", 1)
	register_clcmd("getrk", "getRefKnife")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, v_model)
	engfunc(EngFunc_PrecacheModel, p_model)
	engfunc(EngFunc_PrecacheModel, vulcanus9)
	engfunc(EngFunc_PrecacheModel, magicircle)
	engfunc(EngFunc_PrecacheModel, firewave_model)
	engfunc(EngFunc_PrecacheModel, element_model)
	engfunc(EngFunc_PrecacheModel, firestar)
	firestar_explode = engfunc(EngFunc_PrecacheModel, muzzleflash63)
	precache_sound(firestarExplosion)
	precache_sound(firestarFly)

	new i;
	for(i = 0; i < sizeof(weapon_sound); i++)
		engfunc(EngFunc_PrecacheSound, weapon_sound[i])
	for(i = 0; i < sizeof(skills_sound); i++)
		engfunc(EngFunc_PrecacheSound, skills_sound[i])

	engfunc(EngFunc_PrecacheModel, circles3)
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

adurasMoonlightSword(id)
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
	set_pev(moonlightSword, pev_rendermode, kRenderTransAlpha);
	set_pev(moonlightSword, pev_renderamt, 255.0);

	engfunc(EngFunc_SetModel, moonlightSword, vulcanus9)
	angles[0] = 0.0
	angles[1] += 115.0 // 起始角度劍端指向左後方
	set_pev(moonlightSword, pev_angles, angles)
	set_pev(moonlightSword, pev_nextthink, get_gametime() + AFTER_ATTACKTIME) // 停留幾秒後開始揮刀
	set_task(0.4, "emitsound_vulcanus9_task", moonlightSword);

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

	/* 魔法陣 */
	new Float:circle_origin[3]
	new circle = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(circle, pev_movetype, MOVETYPE_NONE)
	set_pev(circle, pev_owner, id)
	set_pev(circle, pev_classname, MAGIC_CIRCLE_CLASS)
	set_pev(circle, pev_solid, SOLID_NOT)
	xs_vec_copy(origin, circle_origin)
	circle_origin[2] -= 36.0
	set_pev(circle, pev_origin, circle_origin)

	engfunc(EngFunc_SetModel, circle, magicircle)
	set_pev(circle, pev_nextthink, get_gametime() + 1.0) // 幾秒後移除魔法陣
}

fireStar(id)
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

	engfunc(EngFunc_SetModel, firestarEnt, firestar)
	set_pev(firestarEnt, pev_nextthink, get_gametime() + 9.7) // 幾秒後爆炸(需綁模組動畫)
	emit_sound(0, CHAN_STATIC, firestarFly, 1.0, ATTN_NORM, 0, PITCH_NORM)
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

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id) )
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_KNIFE || !g_had_refknife[id] )
		return FMRES_IGNORED

	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], 
		Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	angle_vector(v_angle, ANGLEVECTOR_FORWARD, v_forward)
	xs_vec_mul_scalar(v_forward, 80.0, v_forward) // 攻擊距離
	xs_vec_add(vecStart, v_forward, vecEnd)
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)

	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id) )
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_KNIFE || !g_had_refknife[id] )
		return FMRES_IGNORED

	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], 
		Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	angle_vector(v_angle, ANGLEVECTOR_FORWARD, v_forward)
	xs_vec_mul_scalar(v_forward, 80.0, v_forward) // 攻擊距離
	xs_vec_add(vecStart, v_forward, vecEnd)
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)

	return FMRES_SUPERCEDE
}

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED

	static classname[32], id
	pev(ent, pev_classname, classname, sizeof(classname))
	id = pev(ent, pev_owner)
	
	/* 月光劍 */
	if( equal(classname, VULCANUS9) )
	{
		static Float:impacttime
		pev(ent, pev_impacttime, impacttime)

		if( get_gametime() < impacttime ) {
			static Float:angles[3]
			pev(ent, pev_angles, angles)
			angles[1] -= 4.5 // 角度轉的速度
			set_pev(ent, pev_angles, angles)
			set_pev(ent, pev_nextthink, get_gametime() + 0.01)

		} else {
			fadeOutEntity(ent)
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

		static Float:fTimeRemove
		pev(ent, pev_fuser1, fTimeRemove)
		if (get_gametime() >= fTimeRemove)
			fadeOutEntity(ent, 3.0)
		else
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)

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
		new id = pev(ent, pev_owner)

		new victim = FM_NULLENT
		while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, 1500.0) ) != 0 ) { // 火流星爆炸範圍
			if(!is_user_alive(victim) )
				continue
			ExecuteHamB(Ham_TakeDamage, victim, ent, id, 5000.0, DMG_BURN)
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
			emit_sound(0, CHAN_STATIC, firestarExplosion, 1.0, ATTN_NORM, 0, PITCH_NORM)

		engfunc(EngFunc_RemoveEntity, ent)
	}

	return FMRES_IGNORED
}

public fw_Touch(ent, ptd)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED
	
	static classname[32]
	pev(ent, pev_classname, classname, sizeof(classname))

	if( equal(classname, VULCANUS9_PARTICLE) ) {
		static owner; owner = pev(ent, pev_owner)
		if( owner == ptd ) return FMRES_IGNORED
		ExecuteHamB(Ham_TakeDamage, ptd, ent, owner, 3000.0, DMG_SLASH);
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
	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)

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

	if( (CurButton & IN_ATTACK) && (CurButton & IN_ATTACK2) ) {

		if(get_user_weapon(id) != CSW_KNIFE)
			return FMRES_IGNORED
		if(get_pdata_float(id, m_flNextAttack, 5) > 0.0 )
			return FMRES_IGNORED

		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
		set_next_attacktime(id, ent, 1.0) // 施放月光劍後的硬直時間
		set_weapon_anim(id, KNIFE_ANIM_DRAW)
		adurasMoonlightSword(id)
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
	
	static g_firestarCounter[33], Float:g_firestarNexttime[33]
	if( CurButton & IN_ATTACK ) {

		if(get_user_weapon(id) != CSW_KNIFE)
			return FMRES_IGNORED
		if(get_pdata_float(id, m_flNextAttack, 5) > 0.0 )
			return FMRES_IGNORED

		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)

		if( g_had_element[id] ) {
			slashFireWave(id)
			RadiusAttack(id)
			set_next_attacktime(id, ent, 0.2) // 附魔後攻速
			set_pdata_float(ent, m_flNextIdle, 1.2, 4)

		} else {
			set_next_attacktime(id, ent, 0.4) // 刀子預設攻擊速度
		}

		/* 火流星計數 */
		if( game_time > g_firestarNexttime[id] )
			g_firestarCounter[id] = 0
			
		g_firestarNexttime[id] = game_time + 1.0
		g_firestarCounter[id]++
		client_print(id, print_chat, "%d", g_firestarCounter[id])
	}

	if( (CurButton & IN_ATTACK2) && g_firestarCounter[id] >= 7 && game_time <= g_firestarNexttime[id] ) {
		g_firestarCounter[id] = 0
		fireStar(id)
	}

	return FMRES_IGNORED
}

enChant(id)
{
	new ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if( !g_had_element[id] ) {

		g_had_element[id] = 1
		client_print(id, print_chat, "附魔啟動")
		set_next_attacktime(id, ent, 1.5) // 施放附魔後的硬直時間
		set_weapon_anim(id, KNIFE_ANIM_DRAW)

		new elements = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(elements, pev_movetype, MOVETYPE_NONE)
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
	set_pev(ent, pev_fuser1, get_gametime() + 0.2) // remove time
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

stock fadeOutEntity(ent, Float:fadeSpeed=5.0)
{
	static Float:renderamt
	pev(ent, pev_renderamt, renderamt)

 	if( renderamt > 0.0 ) {
		if( fadeSpeed > renderamt )  
			set_pev(ent, pev_renderamt, 0.0)
		else
			set_pev(ent, pev_renderamt, renderamt - fadeSpeed) // 漸層淡出的速度
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)

	} else engfunc(EngFunc_RemoveEntity, ent)
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

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3],Float:speed, Float:new_velocity[3])
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

/* ----------------------------------------- 範圍攻擊天才區域 -------------------------------------------------- */

#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_METAL			2
#define	RESULT_HIT_GENERIC			3

RadiusAttack(id)
{
	#define ATTACK_RANGE 185.0
	#define ATTACK_ANGLE 30.0
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