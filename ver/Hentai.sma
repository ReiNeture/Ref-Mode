#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <nvault>
#include <xs>
#include <amxconst>
#include <dhudmessage>

#define MAX_MONSTERS 15

native get_t7(id);
native give_cv4760r(id);//戰力
native get_blockar(id);//樂高
native give_user_CompoundBow(id); //倉瓊
native give_weapon_psg1(id)
native give_plasma(id); //普拉斯瑪槓
native freehaha(id)
native freeitem(id)
native greeitem(id)

#include "PluginVar.sma"
#include "aa10413.sma"
#include "bgmm.sma"
#include "Ach.sma"

////////////////////////////////////////////////////////////////////New////////////////////////////////////////////////////////////////////
public plugin_init()
{
	register_plugin("Hentai", "1.0", "KuroNeko Ako")
	
	g_FirstRound = true
	register_clcmd("/menu", "majaja")
	register_clcmd("say /menu", "majaja")
	register_clcmd("/weapon_for_nor","weapon_switch_menu")
	register_clcmd("drop", "boss_skill_switch_menu")
	register_clcmd("say Pneumonoultramicroscopicsilicovolcanoconiosis", "pneum")

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_SetModel, "fw_SetModel")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1") //--------------0725
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	//RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	register_concmd("rest_data", "set_boobs", ADMIN_FAP)
	register_concmd("set_exp", "set_expp", ADMIN_FAP)
	register_concmd("set_mil", "set_mill", ADMIN_FAP)
	register_concmd("give_fgun", "get_fgun", ADMIN_FAP)
	register_forward(FM_Touch, "fw_Touch")
	register_touch( "LowBouns", "player", "LowBouns_Pickup")
	register_touch( "HighBouns", "player", "HighBouns_Pickup")
	register_touch( "NoBouns", "player", "NoBouns_Pickup")
	register_touch( "CannonDick", "*", "exp_big_dick")

	register_message(get_user_msgid("TextMsg"), "message_textmsg")
	register_message(get_user_msgid("SendAudio"), "message_sendaudio")
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
	register_logevent("EventRoundEnd", 2, "1=Round_End")
	register_event("DeathMsg", "event_Death", "a")
	unregister_forward(FM_PrecacheSound, g_fwPrecacheSound)

	register_menu("Skill Menu", KEYSMENU, "skill_menu")
	register_menu("Adm Cmd Menu", KEYSMENU, "adm_cmd_menu")
	register_menu("Ray Menu", KEYSMENU, "ray_menu")
	register_menu("Sweet", KEYSMENU, "sweet_menu")
	register_menu("Adm chinchin Menu", KEYSMENU, "adm_chinchin_menu")
	register_menu("Main Menu", KEYSMENU, "main_menu")
	register_menu("ICraft", KEYSMENU, "IForge")
	register_menu("ABCD", KEYSMENU, "mkmenu0")
	register_menu("REIN", KEYSMENU, "rein_menu")
    	register_menu("FORVER_MENU", KEYSMENU, "forver_use_menu")
	register_menu("Item Buy Menu", KEYSMENU, "item_buy_menu")
	register_menu("NORMAL_KNIFE", KEYSMENU, "normal_knife")  //-----------------0725
	register_menu("SWITCH_KNIFE", KEYSMENU, "switch_knife")  //-----------------0725
	register_menu("WEAPON_SWITCH", KEYSMENU, "switch_for_nor") //----------------0729
	register_menu("ACH_MENU", KEYSMENU, "ach_menu_switch") //-----------------0804
	register_menu("ACH_SHOP_MENU", KEYSMENU, "ach_shop_menu_switch")
	//register_menu("REG_MENU", KEYSMENU, "register_menu") //--------------0805

	set_task(20.0, "check_boss",_,_,_,"b");

	register_cvar("Ako_exp", "1")
	register_cvar("boss_add_atk", "0")
	//register_cvar("boss_hp", "200000")

	g_vault = nvault_open("Ako_monster")
	g_vault2 = nvault_open("Ako_monster2")
	g_vault3 = nvault_open("KuroNeko_achievement")

}
public plugin_precache()
{
	for (new i = 0;i < MAX_COUNT;i++)
	{
		g_UPNum++
	}
	spacespr = precache_model("sprites/shockwave.spr")
	precache_model("models/head.mdl");
	/*precache_model("models/Ako/p_Karambit.mdl")
	precache_model("models/Ako/v_Karambit.mdl")
	precache_model("models/Ako/p_blueaxe.mdl")
	precache_model("models/Ako/p_byknife.mdl")
	precache_model("models/Ako/v_blueaxe.mdl")
	precache_model("models/Ako/v_byknife.mdl")
	precache_model("models/Ako/p_warhammer.mdl")
	precache_model("models/Ako/v_warhammer.mdl")*/
	precache_model("models/player/posrte/posrte.mdl")
	g_beacon = precache_model("sprites/beacon.spr")
	beam = precache_model("sprites/plasma_beam.spr") //bgmm
	precache_sound("Ako/bg1.mp3");
	precache_sound("Ako/bg2.mp3")
	precache_sound("Ako/bg3.mp3")

	precache_sound("Ako/boss_death.wav")
	precache_sound("Ako/Human_Win1.wav")
	precache_sound("Ako/Zombie_Win1.wav")

	precache_model("models/shell_firecracker.mdl")
	smoke = precache_model("sprites/steam1.spr");
	exp = precache_model("sprites/fexplo.spr");
	precache_sound("weapons/bomb.wav");
	precache_sound("weapons/star.wav");

	g_fwPrecacheSound = register_forward(FM_PrecacheSound, "fw_PrecacheSound")
}
public fw_PrecacheSound(const sound[])
{
	if (equal(sound, "hostage", 7))
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}
public set_boobs(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	new i
	new Target[64], Target_Name[64]
	read_argv(1, Target, 63)

	if (!cmd_target(id, Target))
	return PLUGIN_HANDLED;
	get_user_name(cmd_target(id, Target), Target_Name, 63)
	porn[cmd_target(id, Target)][0] = 0
	porn[cmd_target(id, Target)][1] = 0
	porn[cmd_target(id, Target)][2] = 0
	porn[cmd_target(id, Target)][4] = 0
	semen[cmd_target(id, Target)][0] = 0
	semen[cmd_target(id, Target)][1] = 0
	for(i = 0 ; i<=23 ; i++)
	{
		material[cmd_target(id, Target)][i] = 0
	}
	for(i = 1 ; i<=6 ; i++)
	{
		combin_material[cmd_target(id, Target)][i] = 0
	}
	rein[cmd_target(id, Target)] = 0
	client_printcolor(0, "/g管理員將/ctr%s/g的資料重置了", Target_Name)
	return PLUGIN_HANDLED
}
public set_expp(id, level, cid)
{
	if (!cmd_access(id, level, cid, 4))
		return PLUGIN_HANDLED;

	new Target[64], Target_Name[64], Type[64], value[64], Say[64]
	read_argv(1, Target, 63)
	read_argv(2, Type, 63)
	read_argv(3, value, 63)

	if (!cmd_target(id, Target))
	return PLUGIN_HANDLED;

	get_user_name(cmd_target(id, Target), Target_Name, 63)
	if (Type[0] == '+')
		semen[cmd_target(id, Target)][1] += str_to_num(value)
	else if (Type[0] == '=')
		semen[cmd_target(id, Target)][1] = str_to_num(value)

	if (str_to_num(Say))
		client_printcolor(0, "/g管理員將/ctr%s/g的經驗增加/ctr%d", Target_Name, str_to_num(value))
	else
		client_printcolor(id, "/g你將/ctr%s/g的經驗增加/ctr%d", Target_Name, str_to_num(value))

	return PLUGIN_HANDLED
}
public set_mill(id, level, cid)
{
	if (!cmd_access(id, level, cid, 4))
		return PLUGIN_HANDLED;

	new Target[64], Target_Name[64], Type[64], value[64], Say[64]
	read_argv(1, Target, 63)
	read_argv(2, Type, 63)
	read_argv(3, value, 63)

	if (!cmd_target(id, Target))
	return PLUGIN_HANDLED;

	get_user_name(cmd_target(id, Target), Target_Name, 63)
	if (Type[0] == '+')
		g_mileage[cmd_target(id, Target)] += str_to_num(value)
	else if (Type[0] == '=')
		g_mileage[cmd_target(id, Target)] = str_to_num(value)

	if (str_to_num(Say))
		client_printcolor(id, "/g管理員將/ctr%s/g的經驗增加/ctr%d", Target_Name, str_to_num(value))
	else
		client_printcolor(id, "/g你將/ctr%s/g的經驗增加/ctr%d", Target_Name, str_to_num(value))

	return PLUGIN_HANDLED
}
public get_fgun(id, level ,cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	new i
	new Target[64], Target_Name[64], Say[64]
	read_argv(1, Target, 63)
	read_argv(2, Say, 63)

	if (!cmd_target(id, Target))
		return PLUGIN_HANDLED;

	get_user_name(cmd_target(id, Target), Target_Name, 63)
	for(i = 1 ; i<=6 ; i++)
	{
		combin_material[cmd_target(id, Target)][i] = 1
	}

	if (str_to_num(Say))
		client_printcolor(0, "/g管理員將/ctr%s/g的永久槍設為/ctr[1]", Target_Name)
	else
		client_printcolor(id, "/g你將/ctr%s/g的永久槍設為/ctr[1]", Target_Name)

	return PLUGIN_HANDLED
}
public lolita(id)
	g_money[id] += 10000
/////////////////////////////////////////////////////////////////Monitoring////////////////////////////////////////////////////////////////
public fw_PlayerPreThink(id)
{
	if(!is_user_connected(id) && !is_user_alive(id))
		return PLUGIN_HANDLED

	new ping, loss
	get_user_ping(id, ping, loss)
	if (ping >= 1000)
		finish_achievement(id, HIGH_PING_1000)

	if (semen[id][1] >= dildo[semen[id][0]] && semen[id][1] != 36)
	{
		semen[id][0] ++
		porn[id][4] += 2
    	}
	static buttons
        buttons = pev(id, pev_button)
        if ((buttons & IN_USE) && get_user_team(id) == 2 && space[id] == true && is_user_alive(id))
        {
                usespace(id)
        }
	
	if ( skill_cn_public )
	{
		new iNum, iPlayers[32]
		get_players(iPlayers, iNum, "c")
		for (new i = 0;i < iNum;i++){
			if ( !g_isBoss[iPlayers[i]] )
			{
				if ( iNum <= 1 )
					set_pev(iPlayers[i], pev_maxspeed, 145.0)
				else
					set_pev(iPlayers[i], pev_maxspeed, 220.0)
			}
		}
	}
	else if (get_user_team(id) == 2)
		set_pev(id, pev_maxspeed, 250.0+float(porn[id][1]))
	else if ( g_isBoss[id] && cannon_mode[id])
		set_pev(id, pev_maxspeed, 230.0)
	else if ( g_isBoss[id] )
		set_pev(id, pev_maxspeed, 310.0)

	if (get_user_team(id) == 1 && get_user_weapon(id) != CSW_KNIFE){
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
	}

	if ( g_isBoss[id] && !ssssssss)
	{
		if ( pev(id, pev_health) <= 1000.0 && game_level >= 2)
		{
			if ( !cannon_mode[id] && !cannon_mode_temp[id] )
			{
				left_time = 60
				cannon_mode[id] = true
				cannon_mode_temp[id] = true
				fm_strip_user_weapons(id)
				set_user_godmode(id, 1)
				set_pev(id, pev_health, 1000.0)
				set_task(0.1,"cannon_mode_connect_rope", id+1996)
				set_task(1.0,"check_left_time",1144)
				set_task(64.0,"un_cannon_mode",id)
				set_task(64.0,"un_godmode",id)

				set_dhudmessage(248, 65, 202, -1.0, 0.2, 0, 6.0, 4.5, 0.5, 0.5)
				show_dhudmessage(0, "動保協會憤怒了^n幫花豹裝上460mm艦上砲塔")
			}
			else if ( cannon_mode[id] )
			{
				static Float:g_next_fire[33]
				if (get_gametime() - g_next_fire[id] >= 2.0)
				{
					set_task(0.1,"fire_big_dick",id)
					set_task(0.3,"fire_big_dick",id)
					set_task(0.5,"fire_big_dick",id)
					g_next_fire[id] = get_gametime()
				}
			}
		}
	}
	return PLUGIN_HANDLED
}
public fire_big_dick(id)
{
	new sprite_ent = create_entity("env_sprite")
	entity_set_string( sprite_ent, EV_SZ_classname, "CannonDick")
	entity_set_model( sprite_ent, "models/shell_firecracker.mdl");
	entity_set_size( sprite_ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	entity_set_int( sprite_ent, EV_INT_movetype, MOVETYPE_TOSS)
	entity_set_int( sprite_ent, EV_INT_solid, SOLID_BBOX)
	entity_set_edict( sprite_ent, EV_ENT_owner, id)
	
	new Float:fAim[3],Float:fAngles[3],Float:fOrigin[3];

	velocity_by_aim(id,64,fAim)
	vector_to_angle(fAim,fAngles)
	entity_get_vector( id, EV_VEC_origin, fOrigin)
	
	fOrigin[0] += fAim[0]
	fOrigin[1] += fAim[1]
	fOrigin[2] += fAim[2]

	entity_set_vector( sprite_ent, EV_VEC_origin, fOrigin) //設定位置
	entity_set_vector( sprite_ent, EV_VEC_angles, fAngles) //設定瞄準角度

	new Float:fVel[3]
	velocity_by_aim(id, 1600, fVel)	
	entity_set_vector( sprite_ent, EV_VEC_velocity, fVel) //設定向量(才有移動的動作)
	emit_sound(sprite_ent, CHAN_VOICE, "weapons/star.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(sprite_ent)
	write_short(smoke)
	write_byte(10)
	write_byte(2)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	message_end()
}
public un_cannon_mode(id)
{
	if (is_user_connected(id))
		cannon_mode[id] = false
}
public un_godmode(id)
{
	if (is_user_connected(id))
		set_user_godmode(id, 0)
}
public check_left_time()
{
	if ( left_time > 0 )
	{
		client_print(0, print_center, "動保協會的憤怒還剩餘 %d 秒", left_time)
		set_task(1.0,"check_left_time",1144)
	}
	left_time --
}
public exp_big_dick(ptr, ptd)
{
	if (!pev_valid(ptr))
		return;

	new Float:EndOrigin[3]
	entity_get_vector(ptr, EV_VEC_origin, EndOrigin)
	new iOrigin[3]
	FVecIVec(EndOrigin,iOrigin)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_short(exp)
	write_byte(30)
	write_byte(255)
	message_end()
	emit_sound(ptr, CHAN_VOICE, "weapons/bomb.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	new Float:Torigin[3], Float:Distance
	for (new i=0 ; i< 32; i++)
	{
		entity_get_vector(i ,EV_VEC_origin, Torigin)
		Distance = get_distance_f(EndOrigin, Torigin);

		if ( Distance <= 100.0 )
		{
			if ( !g_isBoss[i] && is_user_connected(i) && is_user_alive(i))
			{
				static Owner; Owner = pev(ptr, pev_iuser1)
				static Attacker; 
				Attacker = Owner

				new Float:Damage
				Damage = 27.0
				if ( get_user_health(i) > 0 )
				{
					cannon_victim[i] ++
					if ( cannon_victim[i] >= 5 )
						finish_achievement(i, CANNON_ATTACK_5)

					new nHealth = floatround(float(get_user_health(i))-Damage)
					set_user_health(i,nHealth)

					message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, i)
					write_short(1500)
					write_short(1500)
					write_short(1<<12)
					write_byte(255)
					write_byte(0)
					write_byte(0)
					write_byte(200)
					message_end()
	
					message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, i)
					write_short((1<<12)*10)
					write_short((1<<12)*3)
					write_short((1<<12)*14)
					message_end()
				}
				else
					log_kill(Attacker,i,"460mm",0)
			}
		}
	}
	remove_entity(ptr)
}
public cannon_mode_connect_rope(id)
{
	id -= 1996
	for (new i=0 ; i < 32 ; i++){
		if ( is_user_connected(i) && is_user_alive(i) && id != i)
		{
			new Origin[3]
			get_user_origin(i, Origin)

			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMENTPOINT)
			write_short(id)
			write_coord(Origin[0])
			write_coord(Origin[1]) 
			write_coord(Origin[2]) 
			write_short(beam)
			write_byte(3) // framerate
			write_byte(3) // framerate
			write_byte(1) // life
			write_byte(6)  // width
			write_byte(0)// noise
			write_byte(random_num(1, 255))// r, g, b
			write_byte(random_num(1, 255))// r, g, b
			write_byte(random_num(1, 255))// r, g, b
			write_byte(255)	// brightness
			write_byte(20)	// speed	200
			message_end()
		}
	}
	set_task(0.1,"cannon_mode_connect_rope",id+1996)
}
/////////////////////////////////////////////////////////////////KillEvent/////////////////////////////////////////////////////////////////
public fw_Touch(toucher, touched)
{
	if (!pev_valid(toucher))
		return FMRES_IGNORED;

	if (g_isBoss[touched] && !g_isBoss[toucher])
	{
		new touched_origin[3], toucher_origin[3], Float:toucher_minsize[3], Float:touched_minsize[3]
		
		get_user_origin(touched, touched_origin)
		get_user_origin(toucher, toucher_origin)
		
		pev(toucher, pev_mins, toucher_minsize)
		pev(touched, pev_mins, touched_minsize)
		
		if (touched_minsize[2] != -18.0)
		{
			if (!(toucher_origin[2] == touched_origin[2] + 72 && toucher_minsize[2] != -18.0) && !(toucher_origin[2] == touched_origin[2] + 54 && toucher_minsize[2] == -18.0))
				return FMRES_IGNORED;
		}
		else
		{
			if (!(toucher_origin[2] == touched_origin[2] + 68 && toucher_minsize[2] != -18.0) && !(toucher_origin[2] == touched_origin[2] + 50 && toucher_minsize[2] == -18.0))
				return FMRES_IGNORED;
		}
		
		if (is_user_alive(touched) && g_on_boss_cd[toucher] <= get_gametime())
		{
			g_on_boss_cd[toucher] = get_gametime() + 1.0
			g_on_boss[toucher] += 1
			
			if (g_on_boss[toucher] >= 10)
				finish_achievement(toucher, ON_BOSS_10)
		}
	}

	new classname[32]
	pev(toucher, pev_classname, classname, charsmax(classname))
	if (equal(classname, "LowBouns") || equal(classname, "HighBouns"))
	{
		if ( get_bouns[toucher] >= 200 )
			finish_achievement(toucher, GET_BOUNS_200)
	}

	return FMRES_IGNORED
}
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (attacker == victim  || !is_user_connected(attacker))
		return HAM_IGNORED

	if(get_user_team(attacker) == 1 && g_isBoss[attacker])
	{
		if ( boss_mana[attacker]+15 > 100 )
			boss_mana[attacker] = 100
		else
			boss_mana[attacker] += 15

		semen[attacker][1] += 2500 * get_cvar_num("Ako_exp")
		client_print(attacker, print_center, "你殺了東西，獲得%d經驗值，外加10年有期徒刑", (2500 * get_cvar_num("Ako_exp")))
	}
	if(get_user_team(victim) == 1 && g_isBoss[victim])
	{
		if ( game_level == 1 ) 
		{
			set_task(0.2,"boss_death_bouns_low",victim)
			set_task(0.4,"boss_death_bouns_no",victim)
			set_task(0.6,"boss_death_bouns_no",victim)
			set_task(0.8,"boss_death_bouns_no",victim)
			set_task(1.0,"boss_death_bouns_no",victim)
			set_task(1.2,"boss_death_bouns_no",victim)
			set_task(1.4,"boss_death_bouns_no",victim);set_task(1.6,"boss_death_bouns_no",victim);set_task(1.8,"boss_death_bouns_no",victim);set_task(2.0,"boss_death_bouns_no",victim)
		}
		if ( game_level == 2 || game_level == 3 )
		{ 
			set_task(0.2,"boss_death_bouns_high",victim)
			set_task(0.4,"boss_death_bouns_low",victim)
			set_task(0.6,"boss_death_bouns_low",victim)
			set_task(0.8,"boss_death_bouns_no",victim)
			set_task(1.0,"boss_death_bouns_no",victim)
			set_task(1.2,"boss_death_bouns_no",victim)
			set_task(1.4,"boss_death_bouns_no",victim);set_task(1.6,"boss_death_bouns_no",victim);set_task(1.8,"boss_death_bouns_no",victim);set_task(2.0,"boss_death_bouns_no",victim)
		}
		if ( game_level == 4 || game_level == 5)
		{ 
			set_task(0.2,"boss_death_bouns_high",victim)
			set_task(0.4,"boss_death_bouns_low",victim)
			set_task(0.6,"boss_death_bouns_low",victim)
			set_task(0.8,"boss_death_bouns_low",victim)
			set_task(1.0,"boss_death_bouns_no",victim)
			set_task(1.2,"boss_death_bouns_no",victim)
			set_task(1.4,"boss_death_bouns_no",victim);set_task(1.6,"boss_death_bouns_no",victim);set_task(1.8,"boss_death_bouns_no",victim);set_task(2.0,"boss_death_bouns_no",victim)
		}
		if ( game_level == 6 )
		{ 
			set_task(0.2,"boss_death_bouns_high",victim)
			set_task(0.4,"boss_death_bouns_high",victim)
			set_task(0.6,"boss_death_bouns_low",victim)
			set_task(0.8,"boss_death_bouns_low",victim)
			set_task(1.0,"boss_death_bouns_low",victim)
			set_task(1.2,"boss_death_bouns_low",victim)
			set_task(1.4,"boss_death_bouns_no",victim);set_task(1.6,"boss_death_bouns_no",victim);set_task(1.8,"boss_death_bouns_no",victim);set_task(2.0,"boss_death_bouns_no",victim)
		}
		if ( game_level >= 7 )
		{ 
			set_task(0.2,"boss_death_bouns_high",victim)
			set_task(0.4,"boss_death_bouns_high",victim)
			set_task(0.6,"boss_death_bouns_low",victim)
			set_task(0.8,"boss_death_bouns_low",victim)
			set_task(1.0,"boss_death_bouns_low",victim)
			set_task(1.2,"boss_death_bouns_low",victim)
			set_task(1.4,"boss_death_bouns_low",victim)
			set_task(1.6,"boss_death_bouns_no",victim);set_task(1.8,"boss_death_bouns_no",victim);set_task(2.0,"boss_death_bouns_no",victim)
		}
		emit_sound(victim, CHAN_BODY, "Ako/boss_death.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_printcolor(0, "/g[掉落]/ctr花豹掉落寶物，原來花豹會掉落稀有寶物，大家快點屠殺花豹阿")

	}
	return HAM_IGNORED
}
public boss_death_bouns_low(id)
	make_entity(id, "LowBouns", "models/head.mdl",50,225,225)
public boss_death_bouns_high(id)
	make_entity(id, "HighBouns", "models/head.mdl",255,255,255)
public boss_death_bouns_no(id)
	make_entity(id, "NoBouns", "models/head.mdl",50,225,225)
////////////////////////////////////////////////////////////////DamageEvent////////////////////////////////////////////////////////////////
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
    	if (attacker == victim  || !is_user_connected(attacker))
                 	return HAM_IGNORED

	if ( cs_get_user_team(attacker) != cs_get_user_team(victim) )
	{
		if ( get_user_weapon(attacker) == CSW_KNIFE && get_user_team(attacker) == 2)
		{
			new this_damage = floatround(damage) + porn[attacker][0] + normal_knife_damage[kfmod[attacker]]
			g_damagedealt[attacker] += this_damage  //---------0725
			acc_damage[attacker] += this_damage
			SetHamParamFloat(4, damage + porn[attacker][0] + normal_knife_damage[kfmod[attacker]]) //---------0725
		}
		else if ( get_user_weapon(attacker) != CSW_KNIFE && get_user_team(attacker) == 2)
		{
			new this_damage2 = floatround(damage) + porn[attacker][0]
			g_damagedealt[attacker] +=  this_damage2
			acc_damage[attacker] += this_damage2
			SetHamParamFloat(  4, damage + (damage*porn[attacker][0]*0.01)  ) //---------0725
		}
		else if ( get_user_weapon(attacker) == CSW_KNIFE && get_user_team(attacker) == 1 && g_isBoss[attacker])
		{
			SetHamParamFloat(4, damage + get_cvar_float("boss_add_atk")) //---------0726
		}

		if ( g_isBoss[victim] && skill_ed[victim] )
		{
			SetHamParamFloat(4, damage * -1.0)
			skill_ed_get[victim] += floatround(damage)
		}

		while (g_damagedealt[attacker] >= 5000)
		{
			g_money[attacker] += 5
			have_sp[attacker] += 5
			semen[attacker][1] += 400 * get_cvar_num("Ako_exp") + (10-rein[attacker])*30
			g_damagedealt[attacker] -= 5000
			client_print(attacker, print_center, "累積傷害達5000，獲得%d經驗值，附加獎勵%d經驗，SP %d", (400 * get_cvar_num("Ako_exp")),(10-rein[attacker])*30,5)
	        }

		if ( g_money[attacker] >= 12345 )
			finish_achievement(attacker, SP_12345)
		if ( have_sp[attacker] >= 200 )
			finish_achievement(attacker, ROUND_SP_200)
		if ( have_sp[attacker] >= 500 )
			finish_achievement(attacker, ROUND_SP_500)
		if ( have_sp[attacker] >= 800 )
			finish_achievement(attacker, ROUND_SP_800)

		if ( g_isBoss[victim] && !round_start_takedamage )
			finish_achievement(attacker, ROUND_START_5S)

		if ( acc_damage[attacker] >= 150000 )
			finish_achievement(attacker, ACC_DAMAGE_150000)
		if ( acc_damage[attacker] >= 350000 )
			finish_achievement(attacker, ACC_DAMAGE_350000)
		if ( acc_damage[attacker] >= 800000 )
			finish_achievement(attacker, ACC_DAMAGE_800000)

	}
	else
	{
		if (pev(attacker, pev_button) & IN_ATTACK && get_user_weapon(attacker) == CSW_KNIFE)
			g_attack1_teammate[attacker]++
		else if (pev(attacker, pev_button) & IN_ATTACK2 && get_user_weapon(attacker) == CSW_KNIFE)
			g_attack2_teammate[attacker]++

		if (g_attack1_teammate[attacker] >= 500)
			finish_achievement(attacker, ATTACK_TEAMMATE_ATTACK1)

		if (g_attack2_teammate[attacker] >= 300)
			finish_achievement(attacker, ATTACK_TEAMMATE_ATTACK2)
	}
	return HAM_IGNORED
}
public LowBouns_Pickup(ptr, ptd)
{
	new const temp_arr[] = {0 ,1 ,4 ,5 ,7 ,8 ,11, 13, 14, 17, 18}
	if( is_user_alive(ptd) && pev_valid(ptr) ) 
	{ 	
		get_bouns[ptd] ++
		new item,tnum
		item = random_num(0,10)
		tnum = random_num(1,100)
		switch(tnum)
		{
			case 1..70:{
				material[ptd][15] += tnum
				client_printcolor(ptd, "/g[素材]/ctr你撿到 %s %d個", material_name[15],tnum)

				if ( material[ptd][15] >= 9999 )
					finish_achievement(ptd, CAT_9999)
			}
			case 71..100:{
				material[ptd][temp_arr[item]] ++
				client_printcolor(ptd, "/g[素材]/ctr你撿到 %s", material_name[temp_arr[item]])
			}
		}
		remove_entity(ptr)
	}
}
public HighBouns_Pickup(ptr, ptd) //ptd檢的人
{
	new const temp_arr[] = {2,3,6,9,10,12,19}
	if( is_user_alive(ptd) && pev_valid(ptr) ) 
	{ 	
		get_bouns[ptd] ++
		new item
		item = random_num(0,6)
		material[ptd][temp_arr[item]] ++
		client_printcolor(ptd, "/g[素材]/ctr你撿到/g稀有/ctr %s", material_name[temp_arr[item]])
	}
	remove_entity(ptr)
}
public NoBouns_Pickup(ptr, ptd) //ptd檢的人
{
	if( is_user_alive(ptd) && pev_valid(ptr) )
	{
		client_printcolor(ptd, "/g[素材]/ctr這是什麼?幹 是垃圾")
	}

	remove_entity(ptr)
}
////////////////////////////////////////////////////////////////Spawn Event////////////////////////////////////////////////////////////////
public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) && !is_user_connected(id))
		return PLUGIN_HANDLED

	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	g_has_handjob[id] = false

	set_task(0.4, "task_hide_money", id)
	cs_set_user_money(id, 0)

	if ( g_isBoss[id] )
	{
		set_task(1.0, "boss_beacon",id+4256,_,_,"b")
		catch_boss(id)
		set_user_health(id, boss_level[game_level]);
		cs_set_user_model(id, "posrte")
	}

	if (get_user_team(id) == 2)
	{
		weapon_switch_menu(id)
		set_user_health(id, get_user_health(id)+(porn[id][2]))
	}

	if (cs_get_user_team(id) == CS_TEAM_T)
	{
		if (!g_isBoss[id])
		{
			cs_set_user_team(id, CS_TEAM_CT)
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
	}

	return PLUGIN_HANDLED
}
/////////////////////////////////////////////////////////////////Level Gun/////////////////////////////////////////////////////////////////
public weapon_switch_menu(id)
{
	new menu[200], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w三選一 \r槍械只可在魔王出現時選擇 ^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y1.\w便宜槍 ^n") //------------------------0729
	len += formatex(menu[len], charsmax(menu) - len, "\y2.\w永久槍 ^n^n") //------------------------0729
	len += formatex(menu[len], charsmax(menu) - len, "\y3.\d便宜刀(已關閉) ^n") //------------------------0729
	len += formatex(menu[len], charsmax(menu) - len, "\y4.\r新手武器^n^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y5.\r離開")
	show_menu(id, KEYSMENU, menu, -1, "WEAPON_SWITCH")
}
public switch_for_nor(id,key)
{
	switch(key)
	{
		case 0: choose_level_maingun(id)
		case 1: forver_use_switch_menu(id)
		case 2: return//lala_knife_mod(id)
		case 3: basic_weapon_switch(id)
		case 4: return ;
	}
}
public choose_level_maingun(id)
{
	new szTempid[32]
	new menu = menu_create("\r這些都是很便宜的槍", "choose_level_maingun2")
	
	for(new i = 1; i < sizeof dildo_handjob_name; i++)
	{
		new szItems[101]
		formatex(szItems, 100, "\w%s \dLV:%d", dildo_handjob_name[i], dildo_handjob_level[i])
		num_to_str(i, szTempid, 31)
		menu_additem(menu, szItems, szTempid, 0)
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}
public choose_level_maingun2(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || get_user_team(id) == 1)
		return PLUGIN_HANDLED
	
	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)
	
	new i = str_to_num(data)
	
	if(!g_has_handjob[id])
	{
		if(semen[id][0] >= dildo_handjob_level[i])
		{
			g_has_handjob[id] = true
			fm_give_item(id, dildo_handjob_give[i])
		}
		else
			choose_level_maingun(id)
	}
	else
		choose_level_maingun(id)

	menu_destroy(menu)
	return PLUGIN_HANDLED
}
///////////////////////////////////////////////////////////////////Forge///////////////////////////////////////////////////////////////////
public craft_menu(id)
{
	new menu[250], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w[工廠\r巨屌\w老闆] ^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y1.\w用巨屌幫你作永久槍 ^n") //------------------------0725
	len += formatex(menu[len], charsmax(menu) - len, "\y2.\d用巨屌幫你作便宜刀(已關閉) ^n")//------------------------0725
	len += formatex(menu[len], charsmax(menu) - len, "\y3.\r用巨屌幫你按摩 ^n")  //------------------------0725

	show_menu(id, KEYSMENU, menu, -1, "ICraft")
}
public kk3k3(id)
{
	material[id][0] += 5;material[id][1] += 5;material[id][2] += 5;material[id][3] += 5;material[id][4] += 5;material[id][5] += 5;material[id][6] += 5;material[id][7] += 5;material[id][8] += 5
	material[id][9] += 5;material[id][10] += 5;material[id][11] += 5;material[id][12] += 5;material[id][13] += 5;material[id][14] += 5;material[id][15] += 99999999
}
public IForge(id, key)
{
	switch (key)
	{
		case 0:crafted(id)
		case 1:return//crafted_knife(id)
		case 2:{//------------------------0725
			big_dick_count[id] ++
			if ( big_dick_count[id] >= 30 )
				finish_achievement(id, BIG_DICK_30)

			client_printcolor(id,"/g[工廠老闆]/ctr被/g巨屌/ctr按摩了幾分鐘後，情慾得到了紓解")
		}
	}
}
public crafted_knife(id)  //------------------------0725
{
	new menu[400], len, i
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w[工廠\r巨屌\w老闆] ^n^n")
	for (i=0 ; i < sizeof normal_knife_name ; i++){
		len += formatex(menu[len], charsmax(menu) - len, "\r%d.\w%s 需要SP[\y%d\w] +\r%dAck^n",i+1,normal_knife_name[i],normal_knife_count[i],normal_knife_damage[i+1])
	}
	show_menu(id, KEYSMENU, menu, -1, "NORMAL_KNIFE")
}
public normal_knife(id,key) //------------------------0725
{
	if ( g_money[id] >= normal_knife_count[key] )
	{
		g_money[id] -= normal_knife_count[key]
		norkf[id][key] ++
		client_printcolor(id,"/g[系統]/ctr成功製作.")
	}
	else
		client_printcolor(id,"/g[系統]/ctr不夠做三小，過來我要肛你.")
}
public crafted(id)
{
	new szTempid[32], menu
	menu = menu_create("\w選擇所要生產的武器", "crafted2")
	for(new i = 1; i < sizeof forge; i++)
	{
		new szItems[101]
		formatex(szItems, 100, "\w%s", forge[i])
		num_to_str(i, szTempid, 31)
		menu_additem(menu, szItems, szTempid, 0)
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}
public crafted2(id, menu, item)
{
	if(item == MENU_EXIT)
	return PLUGIN_HANDLED
	
	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)
	
	new i = str_to_num(data)
	mkmenu0_switch(id,i)
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public mkmenu0_switch(id,itemkey)
{
    new szMenuBody[256]    //以new選告szMenuBody為變數，以此作為載體來儲存選單內容 

    new nLen = format( szMenuBody, 255, "\y工具坊製造^n")
    for (new i=0; i<= 5 ; i++) //sizeof(material_synthesis[i])
    {
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r%d. \w%s ^t\y[%d/%d]", i+1,material_name[material_synthesis[itemkey][i]],material[id][material_synthesis[itemkey][i]],material_count[itemkey][i])
    }
    nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r7. \w確定製作\r%s?",forge[itemkey])

    itemkey_temp[id] = itemkey
    show_menu(id, KEYSMENU, szMenuBody, -1, "ABCD")
}
public mkmenu0( id,key ){
	switch(key)
	{
		case 6:
		{
			for (new i=0 ; i <= 5 ; i++){
				if (material[id][material_synthesis[itemkey_temp[id]][i]] < material_count[itemkey_temp[id]][i])
				{
					client_printcolor(id, "/g[系統]/ctr材料不足")
					return ;
				}
			}
			for (new i=0 ; i <= 5 ; i++)
				material[id][material_synthesis[itemkey_temp[id]][i]] -= material_count[itemkey_temp[id]][i]

			client_printcolor(id, "/g[系統]/ctr生產成功！")
			combin_material[id][itemkey_temp[id]] ++;
		}
	}
}
public rein_switch_menu(id)
{
	new menu[400], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w投胎需要達到\r850000經驗值\w及\r500SP^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w投胎一定有賺有賠 \y投胎前請先申閱公開說明書^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y1.\r確認投胎^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y2.\w取消投胎^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w啊對了投胎上限最多\y十次\w還有\r黑貓的line\w可以拿^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w還可以戶籍地投胎 投完胎起薪比現在大學生都好有\r38k^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w還不快一點來投胎 \yBy投胎人才招募中心")
	show_menu(id, KEYSMENU, menu, -1, "REIN")
}
public rein_menu(id, key)
{
	switch (key){
		case 0:{
			if (semen[id][0] >= 100 && rein[id]<10 && semen[id][1] >= 850000 && g_money[id] >= 500)
			{
				if ( semen[id][1] >= 1234567 )
					finish_achievement(id, EXP_REIN_1234567)

				rein[id] ++
				semen[id][0]=1
				semen[id][1]=0
				porn[id][0]=0;porn[id][1]=0;porn[id][2]=0;porn[id][3]=0;porn[id][4]=0
				g_money[id] -= 500
				client_printcolor(id, "/g[投胎]/ctr投胎成功 [要加入KuroNeko的宗教請找他]")

				if ( rein[id] >= 10 )
					finish_achievement(id, REIN_COUNT_10)
			}
			else
				client_printcolor(id, "/g[投胎]/ctr你的時辰還未到")
		}
		case 1:
			return;
	}
}
public forver_use_switch_menu(id)
{
	new menu[300], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w永久槍選擇(持續更新中)^n^n")
	for (new i=1 ; i< sizeof forge;i++){
		len += formatex(menu[len], charsmax(menu) - len, "\y%d.%s [%s]\r數量:%d^n",i,forge[i],combin_material[id][i]?"已擁有":"未擁有",combin_material[id][i])
	}
    	show_menu(id, KEYSMENU, menu, -1, "FORVER_MENU")
}
public forver_use_menu(id,key)
{
	if(!g_has_handjob[id] && get_user_team(id) == 2)	
	{
		switch (key){
			case 0:{
				if (combin_material[id][1] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else{
					get_blockar(id)
					g_has_handjob[id] = true
				}
			}
			case 1:{
				if (combin_material[id][2] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else{
					get_t7(id)
					g_has_handjob[id] = true
				}
			}
			case 2:{
				if (combin_material[id][3] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else{
					give_cv4760r(id)
					g_has_handjob[id] = true
				}
			}
			case 3:{
				if (combin_material[id][4] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else{
					give_user_CompoundBow(id)
					g_has_handjob[id] = true
				}
			}
			case 4:{
				if (combin_material[id][5] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else{
					give_plasma(id)
					g_has_handjob[id] = true
				}
			}
			case 5:{
				if (combin_material[id][6] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else{
					give_weapon_psg1(id)
					g_has_handjob[id] = true
				}
			}
		}
	}
	else 
		forver_use_switch_menu(id)
}
public lala_knife_mod(id)  //-----------0725
{
	static menu[300], len, i
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w這些都是很便宜的刀^n^n")
	for (i=0 ; i < sizeof normal_knife_name ; i++){
		len += formatex(menu[len], charsmax(menu) - len, "\r%d.\w%s 數量:%d +\r%dAck^n",(i+1),normal_knife_name[i],norkf[id][i],normal_knife_damage[i+1])
	}
	show_menu(id, KEYSMENU, menu, -1, "SWITCH_KNIFE")
}
public switch_knife(id, key)   //-----------0725
{
	switch(key)
	{
		case 0:{
			if (norkf[id][0] >= 1){
				kfmod[id] = 1
				client_printcolor(id, "/g[系統]/ctr已裝備.")
				set_pev(id, pev_viewmodel2, "models/Ako/v_Karambit.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_Karambit.mdl")
			}
		}
		case 1:{
			if (norkf[id][1] >= 1){
				kfmod[id] = 2
				client_printcolor(id, "/g[系統]/ctr已裝備.")
				set_pev(id, pev_viewmodel2, "models/Ako/v_byknife.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_byknife.mdl")
			}
		}
		case 2:{
			if (norkf[id][2] >= 1){
				kfmod[id] = 3
				client_printcolor(id, "/g[系統]/ctr已裝備.")
				set_pev(id, pev_viewmodel2, "models/Ako/v_blueaxe.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_blueaxe.mdl")
			}
		}
		case 3:{
			if (norkf[id][3] >= 1){
				kfmod[id] = 4
				client_printcolor(id, "/g[系統]/ctr已裝備.")
				set_pev(id, pev_viewmodel2, "models/Ako/v_warhammer.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_warhammer.mdl")
			}
		}
	}
}
public basic_weapon_switch(id) //-----0726
{
	new tempid[32], menu, g_format[201]
	format(g_format, charsmax(g_format), "\r限投胎次數0~2(84萬經驗以下) \w我才不是為了你 才送你的 %s%s",g_has_handjob[id]?"\d":"\w",g_has_handjob[id]?"[已選擇]":"[未選擇]")
	menu = menu_create(g_format, "basic_weapon")

	menu_additem(menu, "按我領取免費永久槍", "1", 0)

	/*for (new i=1 ; i < sizeof forge ; i++){
		new szItems[101]
		formatex(szItems, 100, "%s",forge[i])
		num_to_str(i, tempid, 31)
		menu_additem(menu, szItems, tempid, 0)
	}*/
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}
public basic_weapon(id, menu, item)
{
	if(item == MENU_EXIT && get_user_team(id) == 1 && !is_user_alive(id))
		return PLUGIN_HANDLED


	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)
	new i = str_to_num(data)
	new mun
	mun = random_num(1,6)

	switch(i)
	{
		case 1:
		{
			if (rein[id] < 3 && !g_has_handjob[id] && semen[id][1] < 840000)
			{
				switch(mun)
				{
					case 1: 
					{
						get_blockar(id)
						g_has_handjob[id]=true
					}
					case 2:
					{
						get_t7(id)
						g_has_handjob[id]=true
					}
					case 3:
					{ 
						give_cv4760r(id) 
			 			g_has_handjob[id]=true 
					}
					case 4:
					{
						give_user_CompoundBow(id)
						g_has_handjob[id]=true
					}
					case 5:
					{
						give_plasma(id)
						g_has_handjob[id]=true
					}
					case 6:
					{
						give_weapon_psg1(id)
						g_has_handjob[id]=true
					}
				}
			}
			else
				client_printcolor(id, "/g[普通話]/ctr看清楚選單標題啦 或 你已經選過槍了(禮貌)")
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public bag_after_menu(id)
{
	if(!is_user_connected(id))
	return PLUGIN_HANDLED;

	new menu = menu_create("\y你要打開哪個部位", "open_cunt_bag_menu")

	menu_additem(menu, "\w素材欄", "1", 0)	
	menu_additem(menu, "\w重要欄", "2", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)

	return PLUGIN_HANDLED
}
public open_cunt_bag_menu(id , menu , item)
{
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu); 
		return PLUGIN_HANDLED;
	} 
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new i = str_to_num(data)
	switch(i)
	{
		case 1: tree_menu(id)
		case 2: kg_menu(id)
	}
	return PLUGIN_HANDLED
}
public tree_menu(id)
{
	if(!is_user_connected(id))
	return PLUGIN_HANDLED;

	new szTempid[32], temp_num;
	new menu = menu_create("\y素材的說","tree_menu")
	for (new i = 0; i < sizeof material_name; i++)
	{
		if (material[id][i] > 0)
		{
			new szItems[60];
			formatex(szItems, 59, "\y%s \w- \r%d", material_name[i], material[id][i] )
			num_to_str(i, szTempid, 31);
			menu_additem(menu, szItems, szTempid, 0);
			temp_num = 1
		}
	}
	if (temp_num == 0)
		menu_additem( menu, "\y沒有任何素材 \w- \r0", "1", 0)

	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL);
	menu_display(id , menu , 0); 
	
	return PLUGIN_HANDLED;
}
public kg_menu(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	new szTempid[32], temp_num;
	new menu = menu_create("\y重要的說","kg_menu")
	for (new i = 1; i < sizeof forge; i++)
	{
		if (combin_material[id][i] > 0)
		{
			new szItems[60];
			formatex(szItems, 59, "\y%s \w- \r%d", forge[i], combin_material[id][i] )
			num_to_str(i, szTempid, 31);
			menu_additem(menu, szItems, szTempid, 0);
			temp_num = 1
		}
	}
	if (temp_num == 0)
		menu_additem( menu, "\y沒有任何槍械 \w- \r0", "1", 0)

	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL);
	menu_display(id , menu , 0); 
	
	return PLUGIN_HANDLED;
}
/////////////////////////////////////////////////////////////////Main Menu/////////////////////////////////////////////////////////////////
public majaja(id)
{
	static menu[600], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w麻六甲選單 \y(色情語音群RC:\r25453746\y)^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y1\r.\w能力選單 \y[能力點:%d]^n", porn[id][4])
	len += formatex(menu[len], charsmax(menu) - len, "\y2\r.\w選擇武器^n") 
	len += formatex(menu[len], charsmax(menu) - len, "\y3\y.\w找工廠老闆^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y4\y.\w投胎招募中心^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y5\r.\w黑市交易商^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y6\r.\w打開鮑包^n") //-----------------0725
	len += formatex(menu[len], charsmax(menu) - len, "\y7\r.\r查看成就^n") //---------0726
	if((get_user_flags(id) & ADMIN_GAY))
		len += formatex(menu[len], charsmax(menu) - len, "\y8\r.\w管理員選單^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r解開成就快速提升等級^n\w還有請務必購買衝擊結界")
	show_menu(id, KEYSMENU, menu, -1, "Main Menu")

	return FMRES_SUPERCEDE
}
public main_menu(id, key)
{
	switch (key)
	{
		case 0:show_skill_menu(id)
		case 1:weapon_switch_menu(id)
		case 2:craft_menu(id)
		case 3:rein_switch_menu(id)
		case 4:buy_item_menu(id)
		case 5:bag_after_menu(id) ;  //-----------0725
		case 6:ach_menu_display(id,g_menupos[id]) ; //----------0804
		case 7:
		{
			if((get_user_flags(id) & ADMIN_GAY))
				admingaycmd(id)
		}
	}
}
public admingaycmd(id)
{
	static menu[600], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\r[管理員]\w愛的選單^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w1管理員能力選單^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w2奕娘寶寶選單^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w3衝擊結界選單^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w4免指令選槍選單^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w5領取蘿莉^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w6領取材料^n")

	show_menu(id, KEYSMENU, menu, -1, "Adm Cmd Menu")
}
public adm_cmd_menu(id, key)
{
	switch (key)
	{
		case 0:ochinchinmenu(id)
		case 1:kuroneko_menu(id)
		case 2:freehaha(id)
		case 3:nocmdfgun(id)
		case 4:lolita(id)
		case 5:kk3k3(id)
	}
}
public kuroneko_menu(id)
{
	static menu[600], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\r[管理員]\w奕娘寶寶選單^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w1特殊選單^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w2惡意選單^n")

	show_menu(id, KEYSMENU, menu, -1, "Ray Menu")
}
public ray_menu(id, key)
{
	switch (key)
	{
		case 0:freeitem(id)
		case 1:greeitem(id)
	}
}
public nocmdfgun(id)
{
	static menu[600], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\r[管理員]\w奕娘寶寶選單^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w1鐮刀^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w2樂高M4A1^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w3CV4760R^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w4普拉斯瑪槓^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w5蒼穹EX^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w6PSG-1^n")

	show_menu(id, KEYSMENU, menu, -1, "Sweet")
}
public sweet_menu(id, key)
{
	switch (key)
	{
		case 0:get_t7(id)
		case 1:get_blockar(id)
		case 2:give_cv4760r(id)
		case 3:give_plasma(id)
		case 4:give_user_CompoundBow(id)
		case 5:give_weapon_psg1(id)
	}
}
////////////////////////////////////////////////////////////////////Buy////////////////////////////////////////////////////////////////////
public buy_item_menu(id)
{
	new menu[250], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w黑市交易(請使用蘿莉交易)^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w1.夜視鏡(單生命)  COST:5隻蘿莉(SP)^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w2.衝擊結界(單場次)  COST:30隻蘿莉(SP)^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w3.現實中的蘿莉(單生命可無限使用) COST:7777隻蘿莉^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r持續更新貨物中^n")

	show_menu(id, KEYSMENU, menu, -1, "Item Buy Menu")
}
public item_buy_menu(id, key)
{
	switch (key)
	{
		case 0:
		{
			if (g_money[id] >= 5){
				client_printcolor(id, "/g你購買了夜視鏡，按/ctrN/g可以把所有東西變綠色")
				g_money[id] -= 5
				buy_night[id] = true
				cs_set_user_nvg(id)
			}
		}
		case 1:
		{
			if (g_money[id] >= 30){
				client_printcolor(id, "/g你購買了衝擊結界(CD:15sec)，按/ctrE/g可以暫時擊退花豹")
				g_money[id] -= 30
				space[id] = true

				buy_space[id] ++
				if ( buy_space[id] >= 2 )
					finish_achievement(id, BUY_SPACE_2)
				if ( buy_space[id] >= 20 )
					finish_achievement(id, BUY_SPACE_20)
			}
		}
		case 2:
		{
			if (g_money[id] >= 7777)
			{
				client_printcolor(id, "/g你購買了蘿莉你要被/ctrFBI/g逮捕了")
				g_money[id] -= 7777
				finish_achievement(id, BUY_LOLI)
			}
		}
	}
}
///////////////////////////////////////////////////////////////////Space///////////////////////////////////////////////////////////////////
public usespace(id)
{
	if ( !is_user_connected(id) && !is_user_alive(id) && get_user_team(id) == 3 )
		return PLUGIN_HANDLED

	static Float:last_check_time[33];
	if (get_gametime() - last_check_time[id] < 15.0)
		return PLUGIN_HANDLED
	last_check_time[id] = get_gametime();

	new Float:origin[3]
	pev(id, pev_origin, origin)
	create_blast(origin)

	new Float:origin1[3], Float:origin2[3], Float:range
	pev(id, pev_origin, origin1)
		
	for (new i = 1; i <= 32; i++)
	{
		if ((i != id) && is_user_alive(i))
		{
			pev(i, pev_origin, origin2);
			range = get_distance_f(origin1, origin2)

			if (range <= 500.0 && floatabs(origin2[2] - origin1[2]) <= 120.0 && get_user_team(i) != get_user_team(id))
			{
				new Float:velocity[3]
				get_speed_vector_to_entity(id, i, 1500.0, velocity)
				velocity[2] += 750.0
				set_pev(i, pev_velocity, velocity)
			}
		}	
	}
	return PLUGIN_HANDLED
}
/////////////////////////////////////////////////////////////////////////////
public Event_CurWeapon(id) //------------0725
{
	if(!is_user_alive(id))
		return
		
	if(get_user_weapon(id) == CSW_KNIFE)
	{
		switch( kfmod[id] )
		{
			case 1:{  //爪刀
				set_pev(id, pev_viewmodel2, "models/Ako/v_Karambit.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_Karambit.mdl")
			}
			case 2:{ //刺刀
				set_pev(id, pev_viewmodel2, "models/Ako/v_byknife.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_byknife.mdl")
			}
			case 3:{ //藍色鐮刀
				set_pev(id, pev_viewmodel2, "models/Ako/v_blueaxe.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_blueaxe.mdl")
			}
			case 4:{ //普通垂
				set_pev(id, pev_viewmodel2, "models/Ako/v_warhammer.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_warhammer.mdl")
			}
			default:{
				set_pev(id, pev_viewmodel2, "models/v_knife.mdl")
				set_pev(id, pev_weaponmodel2, "models/p_knife.mdl")
			}
		}
	}
}
///////////////////////////////////////////////////////////////////Skill///////////////////////////////////////////////////////////////////
public show_skill_menu(id)
{
	static menu[400], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w人生Online配點盤 \r剩餘點數:\w%d^n^n", porn[id][4])
	len += formatex(menu[len], charsmax(menu) - len, "\y1.攻擊力 \r%d/%d   [增加%d%攻擊]^n^n", porn[id][0],30+(rein[id]),porn[id][0])
	len += formatex(menu[len], charsmax(menu) - len, "\y2.移動速度   \r%d/%d   [增加%d速度]^n^n", porn[id][1], (26+rein[id]),porn[id][1])
	len += formatex(menu[len], charsmax(menu) - len, "\y3.生命值   \r%d/%d   [增加%d血量]^n^n", porn[id][2],20+(rein[id]*8),porn[id][2])
	len += formatex(menu[len], charsmax(menu) - len, "\y4.雞雞長度(你沒雞雞)   \r%d/30   [點了沒用別怪我 自己雞雞爛]^n^n", porn[id][3])

	show_menu(id, KEYSMENU, menu, -1, "Skill Menu")
}
public skill_menu(id, key)
{
	switch (key)
	{
		case 0:
		{
			if (porn[id][4] >= 1 && porn[id][0] < 30+(rein[id]))
			{
				porn[id][0] ++
				porn[id][4] --
				show_skill_menu(id)
			}
		}
		case 1:
		{
			if (porn[id][4] >= 1 && porn[id][1] < 26+rein[id])
			{
				porn[id][1] ++
				porn[id][4] --
				show_skill_menu(id)
			}
		}
		case 2:
		{
			if (porn[id][4] >= 1 && porn[id][2] < 20+(rein[id]*8))
			{
				porn[id][2] ++
				porn[id][4] -- 
				show_skill_menu(id)
			}
		}
		case 3:
		{
			if (porn[id][4] >= 1 && porn[id][3] < 30)
			{
				porn[id][3] ++
				porn[id][4] --
				show_skill_menu(id)

				if ( porn[id][0] == 0 && porn[id][1] == 0 && porn[id][2] == 0 && porn[id][3] >= 30 )
					finish_achievement(id, I_AM_30CM)
			}
		}
	}
}
public ochinchinmenu(id)
{
	static menu[400], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\r[管理員]\w特殊能力選單^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y1.攻擊力 \r%d^n^n", porn[id][0])
	len += formatex(menu[len], charsmax(menu) - len, "\y2.移動速度   \r%d^n^n", porn[id][1])
	len += formatex(menu[len], charsmax(menu) - len, "\y3.雞雞長度 \r%d^n^n", porn[id][3])
	show_menu(id, KEYSMENU, menu, -1, "Adm chinchin Menu")
}
public adm_chinchin_menu(id, key)
{
	switch (key)
	{
		case 0:
		{
			porn[id][0] += 1000
			ochinchinmenu(id)
		}
		case 1:
		{
			porn[id][1] += 320
			ochinchinmenu(id)
		}
		case 2:
		{
			porn[id][3] += 10
			ochinchinmenu(id)
		}
	}
}
/////////////////////////////////////////////////////////////////ServerHUD/////////////////////////////////////////////////////////////////
public client_connect(id)
{
	LoadData(id)
	LoadData2(id)
	LoadAch(id)

	new name[32]
	get_user_name(id, name, 31)
	client_printcolor(0, "/ctr%s/g正在連接伺服器.他是一名甲甲呢 [被肛次數:%d]", name, semen[id][0])
}
public client_disconnect(id)
{
	SaveData(id)
	SaveData2(id)
	SaveAch(id)

	if(g_isBoss[id])
		unable_boss(id)

	if ( !is_user_alive(id) )
		buy_night[id] = false
	if ( have_sp[id] > 0 )
		have_sp[id] = 0
	

	mana_limit[id] = false
	cannon_victim[id] = 0
}
public show_hud(taskid)
{
    	taskid -= 4777

	static red, green, blue
	if (g_isBoss[taskid])
	{
		red = 139
		green = 0
		blue = 255
	}
	else
	{
		red = 0
		green = 225
		blue = 25
	}
	set_hudmessage(red, green, blue, 0.65, -0.7, 0, 0.0, 0.4, 0.0, 0.0, 3)
	show_hudmessage(taskid ,"HP: %d | SP: %d | EXP倍率: %d | 里程: %d^nLevel: %d | Exp: %d/%d | 投胎: %d^n", get_user_health(taskid) ,g_money[taskid], get_cvar_num("Ako_exp"),g_mileage[taskid], semen[taskid][0], semen[taskid][1],dildo[semen[taskid][0]],rein[taskid])

	if (!g_isBoss[taskid] && is_user_alive(taskid))
		show_hudmessage(taskid ,"HP: %d | SP: %d | EXP倍率: %d | 里程: %d^nLevel: %d | Exp: %d/%d | 投胎:%d^n", get_user_health(taskid) ,g_money[taskid], get_cvar_num("Ako_exp"), g_mileage[taskid], semen[taskid][0], semen[taskid][1],dildo[semen[taskid][0]],rein[taskid])
	else if ( g_isBoss[taskid] && is_user_alive(taskid) )
		show_hudmessage(taskid ,"HP: %d | SP: %d | EXP倍率: %d | 里程: %d^nLevel: %d | Exp: %d/%d | 投胎:%d^nMP:%d |", get_user_health(taskid) ,g_money[taskid], get_cvar_num("Ako_exp"), g_mileage[taskid], semen[taskid][0], semen[taskid][1],dildo[semen[taskid][0]],rein[taskid],boss_mana[taskid])
	else
		show_hudmessage(taskid , "HP: 死亡 | SP: %d | EXP倍率: %d | 里程: %d^nLevel: %d | Exp: %d/%d | 投胎:%d^n", g_money[taskid], get_cvar_num("Ako_exp"),g_mileage[taskid], semen[taskid][0], semen[taskid][1],dildo[semen[taskid][0]],rein[taskid])
}
public fw_SetModel(entity, const model[])
{
    if (!pev_valid(entity)) return FMRES_IGNORED
 
    if (strlen(model) < 8) return FMRES_IGNORED;
 
    new ent_classname[32]
    pev(entity, pev_classname, ent_classname, charsmax(ent_classname))
    if (equal(ent_classname, "weaponbox"))
    {
        set_pev(entity, pev_nextthink, get_gametime() + 0.1)
        return FMRES_IGNORED
    }
    return FMRES_IGNORED
}
public SaveData(id)
{
	new name[32], vaultkey[64], vaultdata[256] 
              
	get_user_name(id, name, 31) 
             
	format(vaultkey, 63, "%s", name) 
	format(vaultdata, 255, "%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#",
	semen[id][0],semen[id][1],porn[id][0],porn[id][1],porn[id][2],porn[id][3],porn[id][4],material[id][0],material[id][1],material[id][2],
	material[id][3],material[id][4],material[id][5],material[id][6],material[id][7],material[id][8],material[id][9],material[id][10],material[id][11],material[id][12],material[id][13],
	material[id][14],material[id][15],material[id][16],material[id][17],material[id][18],material[id][19],material[id][20],material[id][21],material[id][22],
	combin_material[id][1],combin_material[id][2],combin_material[id][3],combin_material[id][4],combin_material[id][5],combin_material[id][6])
 
	nvault_set(g_vault, vaultkey, vaultdata)
}
public SaveData2(id)
{
	new name[32], vaultkey[64], vaultdata[256] 
              
	get_user_name(id, name, 31) 
             
	format(vaultkey, 63, "%s", name) 
	format(vaultdata, 255, "%i#%i#%i#%i#%i#%i#%i#", rein[id],norkf[id][0],norkf[id][1],norkf[id][2],g_money[id],g_mileage[id],g_play_round[id])
	nvault_set(g_vault2, vaultkey, vaultdata)
}
public LoadData(id)
{
	new name[32], vaultkey[64], vaultdata[256] 
	get_user_name(id,name,31) 
             
	format(vaultkey, 63, "%s", name)
	format(vaultdata, 255, "%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#",
	semen[id][0],semen[id][1],porn[id][0],porn[id][1],porn[id][2],porn[id][3],porn[id][4],material[id][0],material[id][1],material[id][2],
	material[id][3],material[id][4],material[id][5],material[id][6],material[id][7],material[id][8],material[id][9],material[id][10],material[id][11],material[id][12],material[id][13],
	material[id][14],material[id][15],material[id][16],material[id][17],material[id][18],material[id][19],material[id][20],material[id][21],material[id][22],
	combin_material[id][1],combin_material[id][2],combin_material[id][3],combin_material[id][4],combin_material[id][5],combin_material[id][6])

	nvault_get(g_vault, vaultkey, vaultdata, 255) 
             
	replace_all(vaultdata, 255, "#", " ")
             
	new n_lv[32],n_ex[32],s_0[32],s_1[32],s_2[32],s_3[32],s_4[32],f_m0[32],f_m1[32],f_m2[32],f_m3[32],f_m4[32],f_m5[32],f_m6[32],f_m7[32],f_m8[32],f_m9[32],f_m10[32],f_m11[32],f_m12[32],f_m13[32],f_m14[32],f_m15[32],f_m16[32],f_m17[32],f_m18[32],f_m19[32],f_m20[32],f_m21[32],f_m22[32],f_cm1[32],f_cm2[32],f_cm3[32],f_cm4[32],f_cm5[32],f_cm6[32]
	parse(vaultdata, n_lv,31,n_ex,31,s_0,31,s_1,31,s_2,31,s_3,31,s_4,31,f_m0,31,f_m1,31,f_m2,31,f_m3,31,f_m4,31,f_m5,31,f_m6,31,f_m7,31,f_m8,31,f_m9,31,f_m10,31,f_m11,31,f_m12,31,f_m13,31,f_m14,31,f_m15,31,f_m16,31,f_m17,31,f_m18,31,f_m19,31,f_m20,31,f_m21,31,f_m22,31,f_cm1,31,f_cm2,31,f_cm3,31,f_cm4,31,f_cm5,31,f_cm6,31)

	semen[id][0] = str_to_num(n_lv)
	semen[id][1] = str_to_num(n_ex)
	porn[id][0] = str_to_num(s_0)
	porn[id][1] = str_to_num(s_1)
	porn[id][2] = str_to_num(s_2)
	porn[id][3] = str_to_num(s_3)
	porn[id][4] = str_to_num(s_4)
	material[id][0] = str_to_num(f_m0)
	material[id][1] = str_to_num(f_m1)
	material[id][2] = str_to_num(f_m2)
	material[id][3] = str_to_num(f_m3)
	material[id][4] = str_to_num(f_m4)
	material[id][5] = str_to_num(f_m5)
	material[id][6] = str_to_num(f_m6)
	material[id][7] = str_to_num(f_m7)
	material[id][8] = str_to_num(f_m8)
	material[id][9] = str_to_num(f_m9)
	material[id][10] = str_to_num(f_m10)
	material[id][11] = str_to_num(f_m11)
	material[id][12] = str_to_num(f_m12)
	material[id][13] = str_to_num(f_m13)
	material[id][14] = str_to_num(f_m14)
	material[id][15] = str_to_num(f_m15)
	material[id][16] = str_to_num(f_m16)
	material[id][17] = str_to_num(f_m17)
	material[id][18] = str_to_num(f_m18)
	material[id][19] = str_to_num(f_m19)
	material[id][20] = str_to_num(f_m20)
	material[id][21] = str_to_num(f_m21)
	material[id][22] = str_to_num(f_m22)
	combin_material[id][1] = str_to_num(f_cm1)
	combin_material[id][2] = str_to_num(f_cm2)
	combin_material[id][3] = str_to_num(f_cm3)
	combin_material[id][4] = str_to_num(f_cm4)
	combin_material[id][5] = str_to_num(f_cm5)
	combin_material[id][6] = str_to_num(f_cm6)
}
public LoadData2(id)
{
	new name[32], vaultkey[64], vaultdata[256] 
	get_user_name(id,name,31) 
             
	format(vaultkey, 63, "%s", name) 
	format(vaultdata, 255, "%i#%i#%i#%i#%i#%i#%i#%i#", rein[id],norkf[id][0],norkf[id][1],norkf[id][2],g_money[id],g_mileage[id],g_play_round[id],get_bouns[id])
	nvault_get(g_vault2, vaultkey, vaultdata, 255) 

	replace_all(vaultdata, 255, "#", " ")

	new re_in[32],nkf0[32],nkf1[32],nkf2[32],gmoney[32],gmil[32],gplay[32],getbouns[32]
	parse(vaultdata, re_in,31,nkf0,31,nkf1,31,nkf2,31,gmoney,31,gmil,31,gplay,31,getbouns,31)
	rein[id] = str_to_num(re_in)
	norkf[id][0] = str_to_num(nkf0)
	norkf[id][1] = str_to_num(nkf1)
	norkf[id][2] = str_to_num(nkf2)
	g_money[id] = str_to_num(gmoney)
	g_mileage[id] = str_to_num(gmil)
	g_play_round[id] = str_to_num(gplay)
	getbouns[id] = str_to_num(get_bouns)
}
public Rape(id)
{
	SaveData(id)
	SaveData2(id)
	SaveAch(id)
	client_printcolor(id, "/g[系統]/ctr自動保存資料成功!")
	client_printcolor(id, "/g[系統]/ctr控制台輸入/menu開啟主選單，綁定方式bind f1 /menu")
}
public make_entity(victim, const classname[], const model[],redmax,greenmax,bluemax)
{
	new myitem = create_entity("info_target");
	entity_set_string(myitem, EV_SZ_classname, classname);
	entity_set_int(myitem, EV_INT_solid, SOLID_BBOX);
	entity_set_int(myitem, EV_INT_movetype, MOVETYPE_TOSS)
	entity_set_model(myitem, model)
	entity_set_size(myitem, Float:{-1.3, -1.3, -1.3}, Float:{1.3, 1.3, 1.3});

	new Float:vOrigin[3],Float:vVelocity[3];

	entity_get_vector(victim, EV_VEC_origin, vOrigin);
	entity_set_vector(myitem, EV_VEC_origin, vOrigin);
	set_rendering(myitem, kRenderFxGlowShell, random_num(1,redmax), random_num(1,greenmax), random_num(1,bluemax), kRenderNormal, 90)

	vVelocity[0] = random_float(-300.0,300.0)
	vVelocity[1] = random_float(-300.0,300.0)
	vVelocity[2] = random_float(50.0,300.0)
	set_pev(myitem,pev_velocity,vVelocity)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(myitem)
	write_short(smoke)
	write_byte(5)
	write_byte(2)
	write_byte(random_num(1,255))
	write_byte(random_num(1,255))
	write_byte(random_num(1,255))
	write_byte(220)
	message_end()
}
///////////////////////////////////////////////////////////////////Stock///////////////////////////////////////////////////////////////////
stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32];

	static msg[191];
	vformat(msg,190,input,3);

	replace_all(msg,190,"/g","^4");// 綠色文字
	replace_all(msg,190,"/y","^1");// 橘色文字
	replace_all(msg,190,"/ctr","^3");// 隊伍顏色文字

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
stock fm_strip_user_weapons(index) {
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent))
		return 0;

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}
stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

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
stock fm_create_entity(const classname[])
{
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
}
stock fm_set_user_health(index, health) 
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);

	return 1;
}
stock create_blast(const Float:originF[3])
{
	// Largest ring (大的光環)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id (TE 的代碼)
	engfunc(EngFunc_WriteCoord, originF[0]) // x (X 座標)
	engfunc(EngFunc_WriteCoord, originF[1]) // y (Y 座標)
	engfunc(EngFunc_WriteCoord, originF[2]) // z (Z 座標)
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis (X 軸)
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis (Y 軸)
	//engfunc(EngFunc_WriteCoord, originF[2]+400.0) // z axis (Z 軸)
	engfunc(EngFunc_WriteCoord, originF[2]+550.0) // z axis (Z 軸)
	write_short(spacespr) // sprite (Sprite 物件代碼)
	write_byte(0) // startframe (幀幅開始)
	write_byte(0) // framerate (幀幅頻率)
	write_byte(3) // life (時間長度)
	write_byte(30) // width (寬度)
	write_byte(0) // noise (響聲)
	write_byte(255) // red (顏色 R)
	write_byte(255) // green (顏色 G)
	write_byte(255) // blue (顏色 B)
	write_byte(50) // brightness (顏色亮度)
	write_byte(0) // speed (速度)
	message_end()
	
	// Medium ring (中的光環)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	//engfunc(EngFunc_WriteCoord, originF[2]+250.0) // z axis
	engfunc(EngFunc_WriteCoord, originF[2]+400.0)
	write_short(spacespr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(3) // life (時間長度)
	write_byte(30) // width
	write_byte(0) // noise
	write_byte(255) // red (顏色 R)
	write_byte(255) // green (顏色 G)
	write_byte(255) // blue (顏色 B)
	write_byte(100) // brightness
	write_byte(0) // speed
	message_end()
	
	// Smallest ring (小的光環)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	//engfunc(EngFunc_WriteCoord, originF[2]+100.0) // z axis
	engfunc(EngFunc_WriteCoord, originF[2]+300.0)
	write_short(spacespr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(3) // life (時間長度)
	write_byte(30) // width
	write_byte(0) // noise
	write_byte(255) // red (顏色 R)
	write_byte(255) // green (顏色 G)
	write_byte(255) // blue (顏色 B)
	write_byte(50) // brightness
	write_byte(0) // speed
	message_end()
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
stock log_kill(killer, victim, weapon[], headshot)
{
	new attacker_frags = get_user_frags(killer)
	
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	ExecuteHamB(Ham_Killed, victim, killer, 1) // set last param to 2 if you want victim to gib
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)

	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(killer)
	write_byte(victim)
	write_byte(headshot)
	write_string(weapon)
	message_end()

	if (get_user_team(killer) == get_user_team(victim))
		attacker_frags -= 1
	else
		attacker_frags += 1

	new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10]

	get_user_name(killer, kname, 31)
	get_user_team(killer, kteam, 9)
	get_user_authid(killer, kauthid, 31)
 
	get_user_name(victim, vname, 31)
	get_user_team(victim, vteam, 9)
	get_user_authid(victim, vauthid, 31)

	log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
	kname, get_user_userid(killer), kauthid, kteam, 
 	vname, get_user_userid(victim), vauthid, vteam, weapon)

 	return PLUGIN_CONTINUE
}