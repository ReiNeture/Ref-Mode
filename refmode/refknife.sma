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
#define m_flNextAttack 83

/*   CLASS NAME   */
#define VULCANUS9 "vulcanus9_magic"
#define VULCANUS9_PARTICLE "vulcanus9_particle"
#define MAGIC_CIRCLE_CLASS "magic_circle_ring"
#define FIREWAVE_CLASS "slash_firewave"


new const vulcanus9[] = "models/vulcanus9.mdl"
new const vulcanus9_steam[] = "sprites/ref/runeblade_ef02.spr"
new const firewave_model[] = "models/ref/fireslash.mdl"
new const magicircle[] = "models/ref/magic_circle.mdl"
new const circles3[] = "models/circles3.mdl"  // test

new g_had_refknife[33]

public plugin_init()
{
	register_plugin("RefKnife", "1.0", "Reff")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")

	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_Think, "fw_Think")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")

	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_REF, "fw_Weapon_PrimaryAttack")
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

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED

	static classname[32], id
	pev(ent, pev_classname, classname, sizeof(classname))
	id = pev(ent, pev_owner)
	
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

	if( equal(classname, MAGIC_CIRCLE_CLASS) ) {
		engfunc(EngFunc_RemoveEntity, ent)
	}
	
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

	if( equal(classname, FIREWAVE_CLASS) ) {

		static Float:fTimeRemove
		pev(ent, pev_fuser1, fTimeRemove)
		if (get_gametime() >= fTimeRemove)
			fadeOutEntity(ent, 2.0)
		else
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)

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

	if( equal(classname, FIREWAVE_CLASS) ) {
	}

	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE) 
		return FMRES_IGNORED
	if(!g_had_refknife[id])
		return FMRES_IGNORED
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(ent) )
		return FMRES_IGNORED

	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	if( (CurButton & IN_ATTACK) && (CurButton & IN_ATTACK2) ) {

		if(get_pdata_float(id, m_flNextAttack, 5) > 0.0 )
			return FMRES_IGNORED

		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
		ExecuteHamB(Ham_Weapon_SecondaryAttack, ent)
		set_pdata_float(id, m_flNextAttack, 1.0, 5) // 施放月光劍後的硬直時間
		set_weapon_anim(id, KNIFE_ANIM_DRAW)
		adurasMoonlightSword(id)
	}
	return FMRES_IGNORED
}

public fw_Weapon_PrimaryAttack(item) {

	if(!pev_valid(item) )
		return HAM_IGNORED;

	static id; id = get_pdata_cbase(item, 41, 4);
	if( !g_had_refknife[id] )
		return HAM_IGNORED;

	slashFireWave(id)
	set_pdata_float(item, m_flNextPrimaryAttack, 0.1, 4)

	return HAM_IGNORED;
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