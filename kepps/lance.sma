#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <orpheu>

// just comment code below (by adding double slash at very front of each line) or delete any 'mdcsohud_' and 'metadrawer' code
#define LIBRARY_MD "metadrawer"
#include <md_csohud>

// No need to separate plugin for normal and ZP anymore! One for all!
#define LIBRARY_ZP "zp50_core"
#include <zombieplague>

#define PLUGIN "Demonic Scarlet Rose"
#define VERSION "2.0"
#define AUTHOR "Asdian DX"

#define CSW_LANCE CSW_KNIFE
#define weapon_lance "weapon_knife"

#define v_model "models/v_lance.mdl"
#define p_model "models/p_lance.mdl"
#define spr_wpn	"knife_lance"

new const weapon_sound[][] =
{
	"weapons/lance_slash1.wav",				// 0
	"weapons/lance_slash2.wav",				// 1
	"weapons/lance_slash3.wav",				// 2
	"weapons/lance_slash3_exp.wav",				// 3
	
	"weapons/lance_slash_hit1.wav",				// 4
	"weapons/lance_slash_hit2.wav",				// 5
	"weapons/lance_slash_hit3.wav",				// 6
	
	"weapons/lance_snd_attack.wav",				// 7
	"weapons/lance_draw.wav",				// 8
	
	"weapons/lance_field_attack_actuation.wav",		// 9
	"weapons/lance_field_attack_charge.wav",		// 10
	"weapons/lance_field_attack_charge2.wav",		// 11
	"weapons/lance_field_attack_end.wav",			// 12
	"weapons/lance_field_attack_inoperation.wav",		// 13
	"weapons/lance_field_attack_inoperation_spark.wav",	// 14
	"weapons/lance_field_attack_start.wav",			// 15
	
	"weapons/lance_special_attack.wav",			// 16
	"weapons/lance_special_attack_end.wav",			// 17
	"weapons/lance_special_attack_inoperation.wav",		// 18
	
	"weapons/lance_wall_metal1.wav",			// 19
	"weapons/lance_wall_metal2.wav",			// 20
	"weapons/lance_wall_stone1.wav",			// 21
	"weapons/lance_wall_stone2.wav"				// 22
}

new const weapon_skillmdls[][] = 
{
	"models/ef_lance_fieldattack.mdl",			// 0
	"models/ef_lance_specialattack1.mdl",			// 1
	"models/ef_lance_specialattack2.mdl",			// 2
	"models/ef_lance_specialattack3.mdl"			// 3
}

// SLASH
#define	SLASH_ANGLE			120.0
#define SLASH_DAMAGE			random_float(300.0,350.0)
#define SLASH_RANGE			130.0
#define SLASH_KNOCKBACK 		1.0		

// FIELD
#define SKLFIELD_DAMAGE			random_float(190.0,250.0)	
#define	SKLFIELD_RANGE			179.0			

// CHAIN
#define SKLCHAIN_DAMAGE			random_float(170.0,190.0)	
#define	SKLCHAIN_RANGE			179.0			

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_METAL			2
#define	RESULT_HIT_GENERIC			3

new g_had_lance[33], g_rb, g_attacking[33], Float:g_SoundTimer[33], Float:g_SoundTimer2[33], Float:g_Fix[33]
new g_GoingReset[33], Float:g_GoingReset_Timer[33], g_ComboCount[33], Float:g_ComboTimer[33], Float:g_StockSpeed[33]
new spr_blood_spray, spr_blood_drop, g_freezetime, spr1//, spr2

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("HLTV","Event_HLTV","a","1=0","2=0")
	register_logevent("LogEvent_Round_Start",2, "1=Round_Start")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	RegisterHam(Ham_Item_PostFrame, weapon_lance, "fw_Item_PostFrame")
	RegisterHam(Ham_Item_Holster, weapon_lance, "fw_Item_Holster")
	register_think("lance_ent", "Fw_LanceEnt_Think")
	
	if (LibraryExists(LIBRARY_ZP, LibType_Library))
		g_rb = zp_register_extra_item(PLUGIN, 30, ZP_TEAM_HUMAN)
	else
		register_clcmd("lance", "get_lance");
	
	register_clcmd(spr_wpn, "hook_rb")
}

public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	
	new i
	for(i = 0; i < sizeof(weapon_sound); i++)
		precache_sound(weapon_sound[i])
	for(i = 0; i < sizeof(weapon_skillmdls); i++)
		precache_model(weapon_skillmdls[i])
		
	spr1 = precache_model("sprites/ef_lance_cockpung.spr")
	//spr2 = precache_model("sprites/ef_lance_hit.spr") // unused
	
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	spr_blood_drop = precache_model("sprites/blood.spr")
	
	new Txt[32]
	format(Txt, 31, "sprites/%s.txt", spr_wpn)
	engfunc(EngFunc_PrecacheGeneric, Txt)
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZP) || equal(module, LIBRARY_MD))
		return PLUGIN_HANDLED;
    
	return PLUGIN_CONTINUE;
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
    
	return PLUGIN_CONTINUE;
}

public hook_rb(id)
{
	engclient_cmd(id, weapon_lance)
	return PLUGIN_HANDLED
}

public Event_HLTV() g_freezetime = 1
public LogEvent_Round_Start() g_freezetime = 0

public zp_extra_item_selected(id, itemid) if(itemid == g_rb) get_lance(id)
public zp_user_infected_post(id) remove_crow9(id)

public get_lance(id)
{
	if (!is_user_alive(id))
		return

	g_had_lance[id] = 1
	remove_attrib(id)
	
	if (get_user_weapon(id) == CSW_LANCE) Event_CurWeapon(id)
	else engclient_cmd(id,weapon_lance)
	
	if(LibraryExists(LIBRARY_MD, LibType_Library)) 
		mdcsohud_regwpnhud(id, CSW_LANCE, spr_wpn)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_had_lance[id] == 1 ? spr_wpn : weapon_lance)
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(2)
	write_byte(1)
	write_byte(CSW_LANCE)
	write_byte(0)
	message_end()
}

public remove_crow9(id)
{
	g_had_lance[id] = 0
	
	if(LibraryExists(LIBRARY_MD, LibType_Library)) 
		mdcsohud_resetwpnhud(id, CSW_LANCE)
	
	remove_attrib(id)
}

public remove_attrib(id)
{
	g_attacking[id] = 0
	g_GoingReset[id] = 0
	g_ComboCount[id] = 0
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(get_user_weapon(id) != CSW_LANCE)
		return 1
	if(!g_had_lance[id])
		return 1
		
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, p_model)
	
	Set_WeaponAnim(id, 1)
	
	static iEnt; iEnt = fm_get_user_weapon_entity(id, CSW_LANCE)
	if(!pev_valid(iEnt)) return 1
	
	set_pdata_float(id, 83, 1.0, 5)
	set_pdata_float(iEnt, 46, 0.16, 4);
	set_pdata_float(iEnt, 47, 0.16, 4);
	set_pdata_float(iEnt, 48, 1.03, 4);
	
	set_pev(iEnt, pev_iuser1, 0)
	set_pev(iEnt, pev_iuser2, 0)
	set_pev(iEnt, pev_iuser3, 0)

	remove_attrib(id)
	return 0
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "knife"))
		return PLUGIN_CONTINUE

	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_LANCE || !g_had_lance[id])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "lance")
	return PLUGIN_CONTINUE
}

public fw_Item_Holster(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id)|| !g_had_lance[id])
		return HAM_IGNORED
		
	SendSound(id, CHAN_WEAPON, "common/null.wav")
	SendSound(id, CHAN_VOICE, "common/null.wav")
	
	return HAM_IGNORED
}

public fw_Item_PostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_LANCE || !g_had_lance[id])
		return HAM_IGNORED
		
	new iButton = pev(id,pev_button)
	
	if(!Stock_Can_Attack())
	{
		set_pev(id, pev_button, (iButton & ~IN_ATTACK) & ~IN_ATTACK2)
		Set_WeaponAnim(id, 0)
		return HAM_SUPERCEDE
	}
	
	new a, b, c
	a = pev(ent, pev_iuser1)
	b = pev(ent, pev_iuser2)
	c = pev(ent, pev_iuser3)
	
	if(!a && !b && !c && !g_ComboCount[id] && get_pdata_float(ent, 48, 4) <= 0.0) 
	{
		g_StockSpeed[id] = fm_get_user_maxspeed(id)
		Set_WeaponAnim(id, 0)
		set_pdata_float(ent, 48, 4.0, 4)
	}
	
	return WeaponEffect_Lance(id, ent, iButton)
}

public WeaponEffect_Lance(id, iEnt, iButton)
{
	new iStatePrim = pev(iEnt, pev_iuser2)
	new iStateSec = pev(iEnt, pev_iuser3)
	new bStab = (iStatePrim == 4)
	
	new Float:fSecAtk, Float:fFieldAtk, Float:fSklAtk;
	pev(iEnt, pev_fuser1, fSklAtk)
	pev(iEnt, pev_fuser2, fFieldAtk)
	pev(iEnt, pev_fuser3, fSecAtk)
	
	if(!(iButton & IN_ATTACK) && g_attacking[id] && iStatePrim <= 2 && g_ComboCount[id] < 5)
	{
		g_attacking[id] = 0
		g_GoingReset[id] = 1
		
		switch(iStatePrim)
		{
			case 0, 1:
			{
				set_pdata_float(iEnt, 46, 0.85, 4)
				set_pdata_float(iEnt, 47, 0.86, 4)
				set_pdata_float(iEnt, 48, 0.89, 4)
				
				g_GoingReset_Timer[id] = get_gametime() + 0.84
			}
			case 2:
			{
				set_pdata_float(iEnt, 46, 0.75, 4)
				set_pdata_float(iEnt, 47, 0.76, 4)
				set_pdata_float(iEnt, 48, 0.79, 4)
				
				g_GoingReset_Timer[id] = get_gametime() + 0.74
			}
		}
	}
	
	if(!(iButton & IN_ATTACK2))
	{
		if(iStateSec > 0 && iStateSec <= 3)
		{
			if(g_ComboCount[id] == 1) g_ComboCount[id] = 2
			else if(g_ComboCount[id] == 2) g_ComboCount[id] = 3
			else g_ComboCount[id] = 0				
			
			Set_WeaponAnim(id, 5)
			SendSound(id, CHAN_WEAPON, weapon_sound[7])
			SendSound(id, CHAN_VOICE, "common/null.wav")
			
			set_pdata_float(iEnt, 46, 1.0, 4)
			set_pdata_float(iEnt, 47, 1.1, 4)
			set_pdata_float(iEnt, 48, 1.93, 4)
			
			set_pdata_float(id, 83, 0.3, 5)
			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_iuser2, 4)
			set_pev(iEnt, pev_iuser3, 0)
			set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
		}
		
		if(iStateSec == 4)
		{
			SendSound(id, CHAN_WEAPON, "common/null.wav")
			Set_WeaponAnim(id, 9)
			
			set_pdata_float(iEnt, 46, 1.43, 4);
			set_pdata_float(iEnt, 47, 1.44, 4);
			set_pdata_float(iEnt, 48, 0.53, 4)	
			
			set_pev(iEnt, pev_iuser3, 5)
			set_pev(iEnt, pev_fuser2, get_gametime() + 0.53)
		}
	}
	
	if(g_GoingReset[id] && g_GoingReset_Timer[id] < get_gametime())
	{
		g_GoingReset[id] = 0
		set_pev(iEnt, pev_iuser2, 0)
	}
	
	/// prim atk
	if(iStatePrim == 3 && g_attacking[id] && fSecAtk && fSecAtk < get_gametime())
	{
		WeaponDamage_Config(id, 0, 1, 0, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE, SLASH_KNOCKBACK)
		SendSound(id, CHAN_WEAPON, weapon_sound[3])
		
		new Float:vOr[3]; Stock_Get_Postion(id, 10.0, 0.0, -11.0, vOr)
		Make_EffSprite(vOr,spr1,1,40)
		
		// user knockback here
		UserKnockback(id)
		
		set_pev(iEnt, pev_iuser2, 0)
		set_pev(iEnt, pev_fuser3, 0.0)
	}
	
	// skill, IGNITION !!1!
	if(g_ComboCount[id] == 5 && g_ComboTimer[id] < get_gametime())
	{
		// put entity skill here
		LanceAtk_Special(id)
		fm_set_user_maxspeed(id, 0.1)
		
		Set_WeaponAnim(id, 13)
		set_pdata_float(iEnt, 48, 0.7, 4)	
		
		g_ComboCount[id] = 6
		g_ComboTimer[id] = get_gametime() + 0.66
		g_Fix[id] = get_gametime() + 0.5
	}
	
	if(g_ComboCount[id] == 6 && g_ComboTimer[id] < get_gametime())
	{
		Set_WeaponAnim(id, 14)
		SendSound(id, CHAN_WEAPON, weapon_sound[17])
		set_pdata_float(iEnt, 48, 0.96, 4)	
		
		g_attacking[id] = 0
		g_ComboCount[id] = 0
		g_GoingReset[id] = 1
		
		g_GoingReset_Timer[id] = get_gametime() + 0.85
		g_ComboTimer[id] = 0.0
	}
	
	// field atk
	if(iStateSec == 5 && fFieldAtk && fFieldAtk < get_gametime())
	{
		//// field atk here
		Set_WeaponAnim(id, 10)
		client_cmd(id, "spk %s", weapon_sound[13])
		set_pdata_float(iEnt, 48, 0.35, 4)	
		
		LanceAtk_Field(id)
		fm_set_user_maxspeed(id, 0.1)
		
		set_pev(iEnt, pev_iuser3, 6)
		set_pev(iEnt, pev_fuser2, get_gametime() + 0.33)
	}
	
	if(iStateSec == 6 && fFieldAtk && fFieldAtk < get_gametime())
	{
		Set_WeaponAnim(id, 11)
		set_pdata_float(iEnt, 48, 0.68, 4)	
		
		set_pev(iEnt, pev_iuser3, 0)
		set_pev(iEnt, pev_fuser2, 0.0)
		
		g_Fix[id] = get_gametime() + 0.5
	}
	
	if(g_Fix[id] && g_Fix[id] < get_gametime())
	{
		fm_set_user_maxspeed(id, g_StockSpeed[id])
		g_Fix[id] = 0.0
	}
	
	if (get_pdata_float(id, 83, 5) <= 0.0 && pev(iEnt, pev_iuser1))
	{
		new iHitResult = WeaponDamage_Config(id, 0, 1, bStab, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE, SLASH_KNOCKBACK)
		
		if(!bStab)
		{
			switch (iHitResult)
			{
				case RESULT_HIT_PLAYER : 
				{
					if(g_ComboCount[id] == 5) SendSound(id, CHAN_VOICE, weapon_sound[4])
					else SendSound(id, CHAN_VOICE, weapon_sound[3 + iStatePrim])
				}
				case RESULT_HIT_METAL : SendSound(id, CHAN_VOICE, weapon_sound[random_num(19, 20)])
				case RESULT_HIT_GENERIC : SendSound(id, CHAN_VOICE, weapon_sound[random_num(21, 22)])
			}
		}
		
		set_pev(iEnt, pev_iuser1, 0)
		if(bStab) set_pev(iEnt, pev_iuser2, 0)
	}
	
	if(get_pdata_float(iEnt, 46, 4) > 0.0)
		return HAM_IGNORED
				
	if(iButton & IN_ATTACK)
	{
		g_attacking[id] = 1
		
		switch(iStatePrim)
		{
			case 0:
			{	
				if(g_ComboCount[id] <= 1) g_ComboCount[id] = 1
				else if(g_ComboCount[id] == 3) g_ComboCount[id] = 4
				else g_ComboCount[id] = 0
				
				if(g_ComboCount[id] == 4)
				{
					g_ComboCount[id] = 5
					
					Set_WeaponAnim(id, 12)
					SendSound(id, CHAN_WEAPON, weapon_sound[16])
					
					set_pdata_float(iEnt, 46, 2.7, 4)
					set_pdata_float(iEnt, 47, 2.71, 4)
					set_pdata_float(iEnt, 48, 1.17, 4)
					
					set_pdata_float(id, 83, 0.1, 5)
					set_pev(iEnt, pev_iuser1, 1)
					set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
					
					// skill, IGNITION !!!11!1!
					g_ComboTimer[id] = get_gametime() + 1.16
				} else {
					Set_WeaponAnim(id, 2)
					SendSound(id, CHAN_WEAPON, weapon_sound[0])
					
					set_pdata_float(iEnt, 46, 0.3, 4)
					set_pdata_float(iEnt, 47, 0.35, 4)
					set_pdata_float(iEnt, 48, 1.1, 4)
					
					set_pev(iEnt, pev_iuser2, 1)
					
					set_pdata_float(id, 83, 0.2, 5)
					set_pev(iEnt, pev_iuser1, 1)
					set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
				}
			}
			case 1:
			{
				g_ComboCount[id] = 0
				
				Set_WeaponAnim(id, 3)
				SendSound(id, CHAN_WEAPON, weapon_sound[1])
				
				set_pdata_float(iEnt, 46, 0.5, 4)
				set_pdata_float(iEnt, 47, 0.55, 4)
				set_pdata_float(iEnt, 48, 1.5, 4)
					
				set_pev(iEnt, pev_iuser2, 2)
				
				set_pdata_float(id, 83, 0.3, 5)
				set_pev(iEnt, pev_iuser1, 1)
				set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
			}
			case 2:
			{
				// frame 13
				Set_WeaponAnim(id, 4)
				SendSound(id, CHAN_WEAPON, weapon_sound[2])
				
				set_pdata_float(iEnt, 46, 1.68, 4)
				set_pdata_float(iEnt, 47, 1.73, 4)
				set_pdata_float(iEnt, 48, 2.1, 4)
				
				set_pev(iEnt, pev_iuser2, 3)
				
				// 1st atk
				set_pdata_float(id, 83, 0.43, 5)
				set_pev(iEnt, pev_iuser1, 1)
				set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
				
				// 2nd atk
				set_pev(iEnt, pev_fuser3, get_gametime() + 1.16)
			}
		}
	}

	if(iButton & IN_ATTACK2)
	{
		switch(iStateSec)
		{
			case 0:
			{
				Set_WeaponAnim(id, 6)
				
				set_pdata_float(iEnt, 46, 0.13, 4)
				set_pdata_float(iEnt, 47, 0.13, 4)
				set_pdata_float(iEnt, 48, 0.13, 4)
				
				set_pev(iEnt, pev_iuser3, 1)
			}
			case 1:
			{
				g_ComboCount[id] = 0
				
				// start
				Set_WeaponAnim(id, 7)
				SendSound(id, CHAN_WEAPON, weapon_sound[15])
				
				set_pdata_float(iEnt, 46, 0.6, 4);
				set_pdata_float(iEnt, 47, 0.6, 4);
				set_pdata_float(iEnt, 48, 0.6, 4);

				set_pev(iEnt, pev_iuser3, 2)
			}
			case 2:
			{
				Set_WeaponAnim(id, 8)
				SendSound(id, CHAN_WEAPON, weapon_sound[10])
				
				set_pdata_float(iEnt, 46, 1.88, 4);
				set_pdata_float(iEnt, 47, 1.88, 4);
				set_pdata_float(iEnt, 48, 0.94, 4);

				set_pev(iEnt, pev_iuser3, 3)
			}
			case 3, 4:
			{
				Set_WeaponAnim(id, 8)
				
				if((iStateSec == 3 || iStateSec == 4) && g_SoundTimer[id] < get_gametime())
				{
					SendSound(id, CHAN_WEAPON, weapon_sound[10])
					g_SoundTimer[id] = get_gametime() + 3.8
				}
				
				if(iStateSec == 4 && g_SoundTimer2[id] < get_gametime())
				{
					SendSound(id, CHAN_VOICE, weapon_sound[11])
					g_SoundTimer2[id] = get_gametime() + 1.8
				}
				
				set_pdata_float(iEnt, 46, 0.94, 4);
				set_pdata_float(iEnt, 47, 0.94, 4);
				set_pdata_float(iEnt, 48, 0.94, 4);
				
				set_pev(iEnt, pev_iuser3, 4)
			}
		}
	}
	
	iButton &= ~IN_ATTACK;
	iButton &= ~IN_ATTACK2;
	set_pev(id, pev_button, iButton);
	return HAM_IGNORED
}

public UserKnockback(id)
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vFor[3], Float:pVelocity[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_v_angle, vAngle)
	pev(id, pev_velocity, pVelocity)
	vAngle[0] = 0.0
	
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vFor);
	xs_vec_mul_scalar(vFor, -350.0, vFor); 
	xs_vec_add(vFor, pVelocity, pVelocity)
	set_pev(id, pev_velocity, pVelocity)
}

public LanceAtk_Field(id)
{
	new Float:VecOrig[3]
	pev(id, pev_origin, VecOrig)
	
	VecOrig[2] -= 27.0
	
	new iEfx = Stock_CreateEntityBase(id, "info_target", weapon_skillmdls[0], "lance_ent", SOLID_NOT, 0.01)
	set_pev(iEfx, pev_origin, VecOrig)
	
	Stock_SetEntityAnim(iEfx, 0)
	
	engfunc(EngFunc_SetSize, iEfx, {-0.07, -0.07, -0.07}, {0.07, 0.07, 0.07})
	dllfunc(DLLFunc_Spawn, iEfx)
	set_pev(iEfx, pev_velocity, Float:{0.01,0.01,0.01});
	
	set_pev(iEfx, pev_iuser1, 0)
	set_pev(iEfx, pev_fuser1, get_gametime() + 3.0)
	set_pev(iEfx, pev_fuser2, get_gametime() + 0.01)
}

public LanceAtk_Special(id)
{
	static Float:vOrigin[3], Float:vAngle[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_v_angle, vAngle)
	vAngle[0] = 0.0
	vOrigin[2] -= 27.0
	
	static Ent; Ent = Stock_CreateEntityBase(id, "info_target", weapon_skillmdls[1], "lance_ent", SOLID_NOT, 0.0)
	set_pev(Ent, pev_origin, vOrigin);
	set_pev(Ent, pev_angles, vAngle);
	fm_set_rendering(Ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	set_pev(Ent, pev_iuser1, 1)
	
	Stock_SetEntityAnim(Ent, 0, 0.75)
	
	engfunc(EngFunc_SetSize, Ent, {-0.07, -0.07, -0.07}, {0.07, 0.07, 0.07})
	dllfunc(DLLFunc_Spawn, Ent)
	
	set_pev(Ent, pev_iuser4, 5) 
	set_pev(Ent, pev_fuser1, 40.0) 
	set_pev(Ent, pev_fuser3, get_gametime()) // trigger next efx
}

public Fw_LanceEnt_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	new iOwner, iMode, Float:vecOri[3]
	iOwner = pev(iEnt, pev_owner)
	iMode = pev(iEnt, pev_iuser1)
	pev(iEnt, pev_origin, vecOri)
	
	if(!IsAlive(iOwner) || !is_user_connected(iOwner) || zp_get_user_zombie(iOwner))
	{
		remove_entity(iEnt)
		return
	}
	
	if(!iMode)
	{
		if(pev(iEnt, pev_fuser1) < get_gametime())
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return
		}
		
		new Float:fDmgTimer;
		pev(iEnt, pev_fuser2, fDmgTimer)
		
		if(fDmgTimer && fDmgTimer < get_gametime())
		{
			WeaponDamage_Config(iOwner, iEnt, 0, 0, SKLFIELD_RANGE, 0.0, SKLFIELD_DAMAGE, 0.01, -1, 0, DMG_CLUB, true, true)
			set_pev(iEnt, pev_fuser2, get_gametime() + 0.15)
		}
		set_pev(iEnt, pev_nextthink, get_gametime())
	} 
	
	if(iMode == 1)
	{
		static iBlowId, Float:fDelay2
		iBlowId = pev(iEnt, pev_iuser4);
		pev(iEnt, pev_fuser3, fDelay2)
		
		if(iBlowId <= 0)
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return;
		}
		
		static Float:vOrigin[3], Float:vAngle[3];
		pev(iEnt, pev_origin, vOrigin);
		pev(iEnt, pev_angles, vAngle);
		
		static Float:vFor[3], Float:fDist, Float:vNew[3];
		engfunc(EngFunc_MakeVectors, vAngle);
		global_get(glb_v_forward, vFor);
		
		pev(iEnt, pev_fuser1, fDist);
		
		xs_vec_mul_scalar(vFor, fDist, vFor);
		xs_vec_add(vFor, vOrigin, vNew);
		
		fDist -= 100.0;
		
		if(fDelay2 && fDelay2 < get_gametime())
		{
			SendSound(iOwner, CHAN_VOICE, weapon_sound[18])
			
			new szModel[64]
			if(iBlowId >= 4) format(szModel, 63, weapon_skillmdls[1])
			else if(iBlowId >= 2 && iBlowId < 4) format(szModel, 63, weapon_skillmdls[2])
			else if(iBlowId < 2) format(szModel, 63, weapon_skillmdls[3])
			
			new iNextEnt = Stock_CreateEntityBase(iOwner, "info_target", szModel, "lance_ent", SOLID_NOT, 0.0)
			set_pev(iNextEnt, pev_origin, vNew);
			set_pev(iNextEnt, pev_angles, vAngle);
			set_pev(iNextEnt, pev_iuser1, 2)
			
			Stock_SetEntityAnim(iNextEnt, 0, 1.0)
			
			engfunc(EngFunc_SetSize, iNextEnt, {-0.07, -0.07, -0.07}, {0.07, 0.07, 0.07})
			dllfunc(DLLFunc_Spawn, iNextEnt)
			set_pev(iNextEnt, pev_fuser2, get_gametime() + 1.0) // next remove
			
			set_pev(iEnt, pev_iuser4, iBlowId - 1)
			set_pev(iEnt, pev_origin, vNew);
			set_pev(iEnt, pev_fuser1, floatmax(100.0, fDist))
			set_pev(iEnt, pev_fuser3, get_gametime() + 0.25) // next seq
			
			// do damage
			WeaponDamage_Config(iOwner, iEnt, 0, 0, SKLCHAIN_RANGE, 0.0, SKLCHAIN_DAMAGE, 0.01, -1, 0, DMG_CLUB, true, true)
		}
		
		set_pev(iEnt, pev_nextthink, get_gametime())
	}
	
	if(iMode == 2)
	{
		static Float:fDelay
		pev(iEnt, pev_fuser2, fDelay)
		
		if(fDelay < get_gametime())
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return;
		}
		set_pev(iEnt, pev_nextthink, get_gametime())
	}
}

stock SendSound(id, chan, sample[]) emit_sound(id, chan, sample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

stock Stock_CreateEntityBase(id, classtype[], mdl[], class[], solid, Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}

stock Stock_SetEntityAnim(iEnt, iSeq, Float:fRate = 1.0)
{
	set_pev(iEnt, pev_frame, 0.0)
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, fRate)
	set_pev(iEnt, pev_sequence, iSeq)
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

stock ClearMultiDamage() OrpheuCall(OrpheuGetFunction("ClearMultiDamage"));
stock ApplyMultiDamage(inflictor, iAttacker) OrpheuCall(OrpheuGetFunction("ApplyMultiDamage"), inflictor, iAttacker);

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Make_EffSprite(Float:fOrigin[3],spr,scale,fr)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(spr) 
	write_byte(scale)
	write_byte(fr)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
}

stock Stock_Get_Postion(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock IsPlayer(pEntity) return is_user_connected(pEntity)

stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}

stock IsAlive(pEntity)
{
	if (pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}

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

stock CheckAngle(iAttacker, iVictim, Float:fAngle)  return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))

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

stock SpawnBlood(const Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount == 0)
		return
	if (!iColor)
		return

	iAmount *= 2
	if(iAmount > 255) iAmount = 255
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(iColor)
	write_byte(min(max(3, iAmount / 10), 16))
	message_end()
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

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}

stock Stock_Can_Attack()
{
	if(g_freezetime) return 0
	return 1
}
