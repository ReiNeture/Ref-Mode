/*================================================================================
 * Please don't change plugin register information.
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

#define SUPPORT_BOT_TO_USE	//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)

#define PLUGIN_NAME	"[ZP] Class : Frank"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"Jim"

#define TASK_ID_1	param[0]+3344
#define TASK_ID_2	ent+4455
#define ENTITY_ID_2	taskid-4455

// Zombie Atributes
new const zclass_name[] = { "法蘭克喪屍" } // 喪屍名字
new const zclass_info[] = { "能夠使用放黑霧技能" } // 喪屍說明
new const zclass_model[] = { "zombie_source" } // 喪屍模型
new const zclass_clawmodel[] = { "v_knife_zombie.mdl" } // 爪的模型
const zclass_health = 2000 // 血量
const zclass_speed = 230 // 速度
const Float:zclass_gravity = 1.0 // 重力
const Float:zclass_knockback = 1.80 // 擊退

// Settings
new const Float:Effect_Human_Delay = 1.5 	//人類碰觸到黑霧時,受到影響的延遲間格時間(單位:秒)
new const Float:Play_Cough_Sound_Delay = 2.5	//人類碰觸到黑霧時,播放咳嗽聲音的延遲間格時間(單位:秒)

// Sounds
new const Smoke_Effect_Sound[] = { "items/airtank1.wav" } //施放黑霧時的效果聲音
new const Humans_Cough_Sound[][] = { "zombie_plague/cough1.wav", "zombie_plague/cough2.wav", "zombie_plague/cough3.wav",
	 "zombie_plague/cough4.wav", "zombie_plague/cough5.wav", "zombie_plague/cough6.wav" } //人類被煙霧嗆到時所發出的咳嗽聲音

// Class IDs
new g_zclass_frank

// Cvars
new g_UseSmokeTimes, g_SmokeTimelimit, g_SmokeSkillCooldown
new g_smokeSpr
new maxplayers
new bool:round_end
new g_msgScreenFade, g_msgScreenShake

new UseSmokeTimes[33]
new bool:UseSmokeStarted[33]
new bool:CooldownStarted[33]
new bool:EffectStarted[33], Float:EffectOverTime[33], Float:NextEffectTime[33]
new EffectSoundIndex[33], Float:NextPlaySoundTime[33]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	
	g_UseSmokeTimes = register_cvar("zp_zclass_frank_times", "12")			//一回合可施放黑霧的次數(設定為 0 代表不限制次數)
	g_SmokeTimelimit = register_cvar("zp_zclass_frank_timelimit", "15.0")		//施放後的黑霧,存在時間長度(單位:秒)
	g_SmokeSkillCooldown = register_cvar("zp_zclass_frank_cooldown", "30.0")	//使用放黑霧技能需要的冷卻時間(單位:秒)
	
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink", 1)
	
	register_event("ResetHUD","event_NewRound","be")
	register_event("DeathMsg", "event_Death", "a")
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
	
	maxplayers = get_maxplayers()
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
}

public plugin_precache()
{
	precache_sound(Smoke_Effect_Sound)
	
	for (new i = 0; i < sizeof Humans_Cough_Sound; i++)
		precache_sound(Humans_Cough_Sound[i])
	
	g_smokeSpr = precache_model("sprites/black_smoke1.spr")
	
	g_zclass_frank = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

// User Infected forward
public zp_user_infected_post(id, infector)
{
	if (zp_get_user_zombie_class(id) == g_zclass_frank)
	{
		UseSmokeTimes[id] = get_pcvar_num(g_UseSmokeTimes)
		
		client_print(id, print_chat, "[喪屍:提示] 你可以按'R'使用放黑霧技能,黑霧效用時間%d秒,技能冷卻時間%d秒!", floatround(get_pcvar_float(g_SmokeTimelimit)), floatround(get_pcvar_float(g_SmokeSkillCooldown)))
	}
}

public zp_user_humanized_post(id)
{
	if (task_exists(id)) remove_task(id)
	
	client_print(id, print_center, "")
	
	UseSmokeStarted[id] = false
	CooldownStarted[id] = false
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr))
		return FMRES_IGNORED;
	
	static classname[32]
	pev(ptr, pev_classname, classname, 31)
	
	if (!equal(classname, "FAKE_SMOKE_ENT"))
		return FMRES_IGNORED;
	
	if ((1 <= ptd <= 32) && is_user_alive(ptd) && !zp_get_user_zombie(ptd))
	{
		if (!EffectStarted[ptd])
		{
			EffectSoundIndex[ptd] = random_num(0, sizeof Humans_Cough_Sound -1)
			EffectStarted[ptd] = true
		}
		
		//設定每人類玩家每次碰觸到煙霧時,受到影響的結束時間(預設影響時間長度為3.0秒).
		//必需離開煙霧的影響範圍,才會停止設定影響的結束時間,即影響的結束時間以最後一次碰觸時間開始計算.
		EffectOverTime[ptd] = get_gametime() + 3.0 
	}
	
	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id))
		return FMRES_IGNORED;
	
	if ((zp_get_user_zombie_class(id) != g_zclass_frank) || zp_get_user_nemesis(id))
		return FMRES_IGNORED;
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		if (CooldownStarted[id])
			return FMRES_IGNORED;
		
		new enemy, body
		get_user_aiming(id, enemy, body) //檢查是否正在瞄準某個目標
		
		if ((1 <= enemy <= 32) && is_user_alive(enemy) &&!zp_get_user_zombie(enemy)) //檢查是否是有效的目標
		{
			if (fm_entity_range(id, enemy) <= 100.0)
			{
				if (!UseSmokeStarted[id])
					Use_SmokeSkill(id)
			}
		}
		
		return FMRES_IGNORED;
	}
	#endif
	
	static button, oldbutton
	button = get_uc(uc_handle, UC_Buttons)
	oldbutton = pev(id, pev_oldbuttons)
	
	if ((button & IN_RELOAD) && !(oldbutton & IN_RELOAD))
	{
		if (!UseSmokeStarted[id])
			Use_SmokeSkill(id)
	}
	
	return FMRES_HANDLED;
}

public fw_PlayerPostThink(id)
{
	if (!is_user_alive(id) || zp_get_user_zombie(id))
		return FMRES_IGNORED;
	
	if (!EffectStarted[id])
		return FMRES_IGNORED;
	
	new Float:gametime = get_gametime()
	if (gametime >= NextEffectTime[id])
	{
		screen_fade(id, 1.0)
		NextEffectTime[id] = gametime + Effect_Human_Delay
	}
	
	if (gametime >= NextPlaySoundTime[id])
	{
		screen_shake(id, 5, 1, 5)
		engfunc(EngFunc_EmitSound, id, CHAN_VOICE, Humans_Cough_Sound[EffectSoundIndex[id]], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		NextPlaySoundTime[id] = gametime + Play_Cough_Sound_Delay
	}
	
	if (gametime >= EffectOverTime[id])
		EffectStarted[id] = false
	
	return FMRES_IGNORED;
}

public Use_SmokeSkill(id)
{
	if (!is_user_alive(id))
		return;
	
	if (!zp_get_user_zombie(id) || (zp_get_user_zombie_class(id) != g_zclass_frank))
		return;
	
	if (zp_get_user_nemesis(id))
		return;
	
	if (get_pcvar_num(g_UseSmokeTimes) && UseSmokeTimes[id] <= 0)
		return;
	
	if (UseSmokeStarted[id])
		return;
	
	if (CooldownStarted[id])
	{
		client_print(id, print_center, "冷卻時間還未結束! 你還不可以使用放黑霧技能.")
		return;
	}
	
	UseSmokeStarted[id] = true
	
	client_print(id, print_center, "")
	
	// Create smoke entity
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (pev_valid(ent))
	{
		new Float:origin[3]
		pev(id, pev_origin, origin)
		
		new flags = pev(id, pev_flags)
		if (!((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
			origin[2] -= 36.0
		
		Create_Smoke_Group(origin)
		
		new iOrigin[3]
		FVecIVec(origin, iOrigin)
		
		new param[6]
		param[0] = ent	//記錄煙霧物件的ID
		param[1] = iOrigin[0] //記錄施放煙霧中心點的 X座標
		param[2] = iOrigin[1] //記錄施放煙霧中心點的 Y座標
		param[3] = iOrigin[2] //記錄施放煙霧中心點的 Z座標
		param[4] = floatround(get_pcvar_float(g_SmokeTimelimit) / 0.1) //設定製造煙霧的時間長度(單位:0.1秒)
		param[5] = 10	//設定每隔多久時間製造一次煙霧(單位:0.1秒)
		
		set_task(0.1, "Do_Smoke_Effect", TASK_ID_1, param, 6)
		
		// Set smoke entity status
		set_pev(ent, pev_classname, "FAKE_SMOKE_ENT")
		set_pev(ent, pev_solid, SOLID_TRIGGER)
		set_pev(ent, pev_movetype, MOVETYPE_NOCLIP)
		set_pev(ent, pev_sequence, 1)
		
		// Set smoke entity size
		new Float:mins[3], Float:maxs[3]
		if (!((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
		{
			mins = Float:{ -130.0, -130.0, -20.0 }
			maxs = Float:{ 130.0, 130.0, 130.0 }
		}
		else
		{
			mins = Float:{ -130.0, -130.0, -56.0 }
			maxs = Float:{ 130.0, 130.0, 130.0 }
		}
		
		engfunc(EngFunc_SetSize, ent, mins, maxs)
		
		// Set smoke entity origin
		set_pev(ent, pev_origin, origin)
		
		engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, Smoke_Effect_Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		CooldownStarted[id] = true
		set_task(get_pcvar_float(g_SmokeSkillCooldown), "SmokeSkill_Cooldown_Over", id)
		
		if (get_pcvar_num(g_UseSmokeTimes))
		{
			UseSmokeTimes[id]--
			
			if (UseSmokeTimes[id] > 0)
				client_print(id, print_chat, "[ZP] 你還可以施放 %d 次黑霧.", UseSmokeTimes[id])
			else
				client_print(id, print_chat, "[ZP] 你已經用完可施放黑霧的次數了.")
		}
	}
	
	UseSmokeStarted[id] = false
}

public Do_Smoke_Effect(param[6])
{
	new ent = param[0]
	new iOrigin[3]
	iOrigin[0] = param[1]
	iOrigin[1] = param[2]
	iOrigin[2] = param[3]
	
	if (!pev_valid(ent))
		return;
	
	if (param[4] <= 0 || round_end)
	{
		if (pev_valid(ent))
			set_task(0.8, "Remove_Smoke_Entity", TASK_ID_2)
		
		return;
	}
	
	if (param[5] <= 0)
	{
		new Float:fOrigin[3]
		IVecFVec(iOrigin, fOrigin)
		Create_Smoke_Group(fOrigin)
		
		param[5] = 10
	}
	
	param[5]--
	param[4]--
	
	set_task(0.1, "Do_Smoke_Effect", TASK_ID_1, param, 6)
}

public Create_Smoke_Group(Float:position[3])
{
	new Float:origin[12][3]
	get_spherical_coord(position, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(position, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(position, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(position, 40.0, 270.0, 0.0, origin[3])
	get_spherical_coord(position, 100.0, 0.0, 0.0, origin[4])
	get_spherical_coord(position, 100.0, 45.0, 0.0, origin[5])
	get_spherical_coord(position, 100.0, 90.0, 0.0, origin[6])
	get_spherical_coord(position, 100.0, 135.0, 0.0, origin[7])
	get_spherical_coord(position, 100.0, 180.0, 0.0, origin[8])
	get_spherical_coord(position, 100.0, 225.0, 0.0, origin[9])
	get_spherical_coord(position, 100.0, 270.0, 0.0, origin[10])
	get_spherical_coord(position, 100.0, 315.0, 0.0, origin[11])
	
	for (new i = 0; i < 12; i++)
		create_Smoke(origin[i], g_smokeSpr, 100, 0)
}

public Remove_Smoke_Entity(taskid)
{
	new ent = ENTITY_ID_2
	
	if (pev_valid(ent))
		engfunc(EngFunc_RemoveEntity, ent)
}

public SmokeSkill_Cooldown_Over(id)
{
	if (CooldownStarted[id] && zp_get_user_zombie(id) && (zp_get_user_zombie_class(id) == g_zclass_frank))
	{
		CooldownStarted[id] = false
		
		if (!get_pcvar_num(g_UseSmokeTimes) || UseSmokeTimes[id] > 0)
			client_print(id, print_center, "冷卻時間%d秒己過,你已經可以再使用放黑霧技能了!", floatround(get_pcvar_float(g_SmokeSkillCooldown)))
	}
}

public Remove_All_FakeSmokeEnt()
{
	new ent = fm_find_ent_by_class(-1, "FAKE_SMOKE_ENT")
	while(ent)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		ent = fm_find_ent_by_class(ent, "FAKE_SMOKE_ENT")
	}
}

public client_connect(id)
{
	UseSmokeStarted[id] = false
	CooldownStarted[id] = false
}

public client_disconnect(id)
{
	UseSmokeStarted[id] = false
	CooldownStarted[id] = false
}

public event_NewRound(id)
{
	client_print(id, print_center, "")
	
	UseSmokeStarted[id] = false
	CooldownStarted[id] = false
}

public event_Death()
{
	new player = read_data(2)
	if (!(1 <= player <= maxplayers))
		return;
	
	if (task_exists(player)) remove_task(player)
	
	client_print(player, print_center, "")
	
	UseSmokeStarted[player] = false
	CooldownStarted[player] = false
}

public event_RoundStart()
{
	round_end = false
	Remove_All_FakeSmokeEnt()
}

public zp_round_ended(winteam)
{
	round_end = true
}

stock get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}

stock create_Smoke(const Float:position[3], sprite_index, life, framerate)
{
	// Alphablend sprite, move vertically 30 pps
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE) // TE_SMOKE (5)
	engfunc(EngFunc_WriteCoord, position[0]) // position.x
	engfunc(EngFunc_WriteCoord, position[1]) // position.y
	engfunc(EngFunc_WriteCoord, position[2]) // position.z
	write_short(sprite_index) // sprite index
	write_byte(life) // scale in 0.1's
	write_byte(framerate) // framerate
	message_end()
}

stock screen_fade(id, Float:time)
{
	// Add a blue tint to their screen
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
	write_short((1<<12)*1) // duration
	write_short(floatround((1<<12)*time)) // hold time
	write_short(0x0000) // fade type
	write_byte(0) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(255) // alpha
	message_end()
}

stock screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) // 振幅
	write_short((1<<12)*duration) // 時間
	write_short((1<<12)*frequency) // 頻率
	message_end()
}

stock fm_find_ent_by_class(index, const classname[])
{
	return engfunc(EngFunc_FindEntityByString, index, "classname", classname) 
}

#if defined SUPPORT_BOT_TO_USE
stock Float:fm_entity_range(ent1, ent2)
{
	new Float:origin1[3], Float:origin2[3];
	pev(ent1, pev_origin, origin1);
	pev(ent2, pev_origin, origin2);
	
	return get_distance_f(origin1, origin2);
}
#endif

