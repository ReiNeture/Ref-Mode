#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <xs>
#include <vector>

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
#define ELEMENT_CLASS "element"


new const vulcanus9[] = "models/vulcanus9.mdl"
new const vulcanus9_steam[] = "sprites/ref/runeblade_ef02.spr"
new const firewave_model[] = "models/ref/fireslash.mdl"
new const magicircle[] = "models/ref/magic_circle.mdl"
new const element_model[] = "models/ref/element.mdl"
new const circles3[] = "models/circles3.mdl"  // test

new g_had_refknife[33], g_had_element[33]

public plugin_init()
{
	register_plugin("RefKnife", "1.0", "Reff")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")

	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_Think, "fw_Think")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")

	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, WEAPON_REF, "fw_Weapon_SendAnim", 1)
	register_clcmd("getrk", "getRefKnife")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, v_model)
	engfunc(EngFunc_PrecacheModel, p_model)
	engfunc(EngFunc_PrecacheModel, vulcanus9)
	engfunc(EngFunc_PrecacheModel, vulcanus9_steam)
	engfunc(EngFunc_PrecacheModel, magicircle)
	engfunc(EngFunc_PrecacheModel, firewave_model)
	engfunc(EngFunc_PrecacheModel, element_model)

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
	xs_vec_mul_scalar(v_forward, 130.0, v_forward) // 攻擊距離
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
	xs_vec_mul_scalar(v_forward, 130.0, v_forward) // 攻擊距離
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
			fadeOutEntity(ent, 2.0)
		else
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)

	}

	/* 附魔後元素球特效 */
	if( equal(classname, ELEMENT_CLASS) ) {
		set_pev(ent, pev_animtime, get_gametime())
		set_pev(ent, pev_nextthink, get_gametime() + 1.0)
	}

	return FMRES_IGNORED
}

public fw_Touch(ent, ptd)
{
	if(!pev_valid(ent) || !is_user_connected(ptd) ) return FMRES_IGNORED
	
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

	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)

	static Float:nextJumpTime[33];
	if( (CurButton & IN_JUMP) && (CurButton & IN_DUCK) ) {
		if( get_gametime() >= nextJumpTime[id] ) {
				
			new Float:velocity[3];
			velocity_by_aim(id, 910, velocity); // 大跳距離
			velocity[2] = 300.0;
			set_pev(id, pev_velocity, velocity);

			nextJumpTime[id] = get_gametime() + 0.1;
		}
	}

	if( (CurButton & IN_ATTACK) && (CurButton & IN_ATTACK2) ) {

		if(get_user_weapon(id) != CSW_KNIFE)
			return FMRES_IGNORED
		if(get_pdata_float(id, m_flNextAttack, 5) > 0.0 )
			return FMRES_IGNORED

		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
		set_pdata_float(id, m_flNextAttack, 1.0, 5) // 施放月光劍後的硬直時間
		set_weapon_anim(id, KNIFE_ANIM_DRAW)
		adurasMoonlightSword(id)
	}

	if( CurButton & IN_ATTACK ) {

		if(get_pdata_float(ent, m_flNextPrimaryAttack, 4) > 0.0 || get_pdata_float(ent, m_flNextSecondaryAttack, 4) > 0.0)
			return FMRES_IGNORED
		
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)

		if( g_had_element[id] ) {
			slashFireWave(id)
			RadiusAttack(id)
			set_pdata_float(ent, m_flNextPrimaryAttack, 0.25, 4)
			set_pdata_float(ent, m_flNextSecondaryAttack, 0.25, 4)
			set_pdata_float(ent, m_flNextIdle, 1.2, 4)
		}
	}

	if( (CurButton & IN_USE) && (CurButton & IN_RELOAD) ) {

		if(get_pdata_float(id, m_flNextAttack, 5) > 0.0 )
			return FMRES_IGNORED

		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_USE)
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_RELOAD)
		enChant(id)
	}

	return FMRES_IGNORED
}

enChant(id)
{
	if( !g_had_element[id] ) {

		g_had_element[id] = 1
		client_print(id, print_chat, "附魔啟動")
		set_pdata_float(id, m_flNextAttack, 2.0, 5) // 施放附魔後的硬直時間
		set_weapon_anim(id, KNIFE_ANIM_DRAW)

		new element = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
		set_pev(element, pev_movetype, MOVETYPE_NONE)
		set_pev(element, pev_owner, id)
		set_pev(element, pev_classname, ELEMENT_CLASS)
		set_pev(element, pev_solid, SOLID_NOT)
		set_pev(element, pev_aiment, id)
		set_pev(element, pev_animtime, get_gametime())
		set_pev(element, pev_framerate, 1.0)
		engfunc(EngFunc_SetModel, element, element_model)
		set_pev(element, pev_nextthink, get_gametime() + 1.0)

	} else {

		g_had_element[id] = 0
		client_print(id, print_chat, "附魔關閉")
		set_pdata_float(id, m_flNextAttack, 0.7, 5) // 關閉附魔後的硬直時間

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
	set_pev(ent, pev_fuser1, get_gametime() + 0.3) // remove time
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	set_pev(ent, pev_classname, FIREWAVE_CLASS)
	engfunc(EngFunc_SetModel, ent, firewave_model)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_rendermode, kRenderTransAdd);
	set_pev(ent, pev_renderamt, 100.0)

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

RadiusAttack(id)
{
	static Float:Max_Distance, Float:Point[4][3], Float:TB_Distance, Float:Point_Dis
	Point_Dis = 90.0
	Max_Distance = 120.0
	TB_Distance = Max_Distance / 4.0
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < 4; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
	
	static ent; ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent) ) return
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		if(fm_entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue
			
		if(get_distance_f(VicOrigin, Point[0]) <= Point_Dis
			|| get_distance_f(VicOrigin, Point[1]) <= Point_Dis
			|| get_distance_f(VicOrigin, Point[2]) <= Point_Dis
			|| get_distance_f(VicOrigin, Point[3]) <= Point_Dis)
		{
			emit_sound(id, CHAN_WEAPON, weapon_sound[random_num(SOUND_HIT1, SOUND_HIT4)], 1.0, ATTN_NORM, 0, PITCH_NORM)
			doAttack(id, i, ent, 15.0)
		}
	}
}	

doAttack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage*1.0, Inflictor)
}

stock fadeOutEntity(ent, Float:fadeSpeed=5.0)
{
	static Float:renderamt
	static id
	pev(ent, pev_renderamt, renderamt)
	id = pev(ent, pev_owner)

 	if( renderamt > 0.0 ) {
		set_pev(ent, pev_renderamt, renderamt - fadeSpeed) // 漸層淡出的速度
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)

	} else {
		client_print(id, print_chat, "FadeOut %d removed;", ent)
		engfunc(EngFunc_RemoveEntity, ent)
	}
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

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 

stock fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	// get fDirection
	new Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	// get fStart
	new Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	// get aimOrigin
	new iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	// TraceLine from fStart to AimOrigin
	new ptr = create_tr2() 
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	new pHit = get_tr2(ptr, TR_pHit)
	new iHitgroup = get_tr2(ptr, TR_iHitgroup)
	new Float:fEndPos[3]
	get_tr2(ptr, TR_vecEndPos, fEndPos)

	// get target & body at aiming
	new iTarget, iBody
	get_user_aiming(iAttacker, iTarget, iBody)
	
	// if aiming find target is iVictim then update iHitgroup
	if (iTarget == iVictim)
	{
		iHitgroup = iBody
	}
	
	// if ptr find target not is iVictim
	else if (pHit != iVictim)
	{
		// get AimOrigin in iVictim
		new Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		// check aim in size of iVictim
		new iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		new Float:fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		new Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		if ( fDis <= fVicSize[0] * 0.5 )
		{
			// TraceLine from fStart to aimOrigin in iVictim
			new ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			new pHit2 = get_tr2(ptr2, TR_pHit)
			new iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			// if ptr2 find target is iVictim
			if ( pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25) )
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			
			free_tr2(ptr2)
		}
		
		// if pHit still not is iVictim then set default HitGroup
		if (pHit != iVictim)
		{
			// set default iHitgroup
			iHitgroup = HIT_GENERIC
			
			new ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			// free ptr3
			free_tr2(ptr3)
		}
	}
	
	// set new Hit & Hitgroup & EndPos
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)
	
	// hitgroup multi fDamage
	new Float:fMultifDamage 
	switch(iHitgroup)
	{
		case HIT_HEAD: fMultifDamage  = 4.0
		case HIT_STOMACH: fMultifDamage  = 1.25
		case HIT_LEFTLEG: fMultifDamage  = 0.75
		case HIT_RIGHTLEG: fMultifDamage  = 0.75
		default: fMultifDamage  = 1.0
	}
	
	fDamage *= fMultifDamage
	
	// ExecuteHam
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	
	// free ptr
	free_tr2(ptr)
}

stock fake_trake_attack(iAttacker, iVictim, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDamageBit)
}
stock fake_take_damage(iAttacker, iVictim, Float:fDamage, iInflictor = 0, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	iInflictor = (!iInflictor) ? iAttacker : iInflictor
	ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDamageBit)
}
stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	new Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	new Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	new iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		new Float:fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		new fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	new Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	new iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}