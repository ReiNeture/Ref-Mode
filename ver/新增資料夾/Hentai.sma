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

native give_user_tb(id);
native give_user_gatling(id);//戰力
native get_blockar(id);//樂高
native give_user_CompoundBow(id); //倉瓊
native give_user_thanatos11(id);
native give_plasma(id); //普拉斯瑪槓
native freehaha(id)
native freeitem(id)
native greeitem(id)

#include "PluginVar.sma"
#include "aa10413.sma"

////////////////////////////////////////////////////////////////////New////////////////////////////////////////////////////////////////////
public plugin_init()
{
	register_plugin("Hentai", "1.0", "Ako")
	register_clcmd("/menu", "majaja")
	register_clcmd("say /menu", "majaja")
	register_clcmd("/weapon_for_nor","weapon_switch_menu")

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_SetModel, "fw_SetModel")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1") //--------------0725
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	register_concmd("rest_data", "set_boobs", ADMIN_FAP)
	register_concmd("set_exp", "set_expp", ADMIN_FAP)
	register_concmd("give_fgun", "get_fgun", ADMIN_FAP)
	register_touch( "LowBouns", "player", "LowBouns_Pickup")
	register_touch( "HighBouns", "player", "HighBouns_Pickup")

	register_message(get_user_msgid("TextMsg"), "message_textmsg")
	register_message(get_user_msgid("SendAudio"), "message_sendaudio")
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
	register_logevent("EventRoundEnd", 2, "1=Round_End")
	register_event("DeathMsg", "event_Death", "a")

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

	//set_task( 4.0, "Restar" );
	for (new i=0 ; i < 32 ; i++){
		set_task( 4.0, "player_kill", i)
	}

	register_cvar("Ako_exp", "1")
	register_cvar("boss_add_atk", "25")
	register_cvar("boss_hp", "30000")

	g_vault = nvault_open("Ako_monster")
	g_vault2 = nvault_open("Ako_monster2")

}
public plugin_precache()
{
	spacespr = precache_model("sprites/shockwave.spr")
	precache_model("models/head.mdl");
	precache_model("models/Ako/p_Karambit.mdl")
	precache_model("models/Ako/v_Karambit.mdl")
	precache_model("models/Ako/p_blueaxe.mdl")
	precache_model("models/Ako/p_byknife.mdl")
	precache_model("models/Ako/v_blueaxe.mdl")
	precache_model("models/Ako/v_byknife.mdl")
	precache_model("models/Ako/p_warhammer.mdl")
	precache_model("models/Ako/v_warhammer.mdl")
	precache_model("models/player/posrte/posrte.mdl")
	g_beacon = precache_model("sprites/beacon.spr") 
	precache_sound("Ako/boss_death.wav");
	precache_sound("Ako/Human_Win1.wav");
	precache_sound("Ako/hurt1.wav");
	precache_sound("Ako/hurt2.wav");
	precache_sound("Ako/Zombie_Win1.wav");
}
public set_boobs(id)
{
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
public get_fgun(id)
{
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

	if (semen[id][1] >= dildo[semen[id][0]] && semen[id][1] != 36)
	{
		semen[id][0] ++
		porn[id][4] += 3
    	}
	static buttons
        buttons = pev(id, pev_button)
        if ((buttons & IN_USE) && get_user_team(id) == 2 && space[id] == true)
        {
                usespace(id)
        }
	if (((buttons & IN_DUCK) && (buttons & IN_JUMP)) && g_isBoss[id])
	{
		Bskill(id)
	}

	if (get_user_team(id) == 2)
		set_pev(id, pev_maxspeed, 250.0+float(porn[id][1]))
	else if (get_user_team(id) == 1)
		set_pev(id, pev_maxspeed, 280.0)

	if (get_user_team(id) == 1 && get_user_weapon(id) != CSW_KNIFE){
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
	}

	return PLUGIN_HANDLED
/*enum CsTeams
{
    CS_TEAM_UNASSIGNED = 0,
    CS_TEAM_T = 1,
    CS_TEAM_CT = 2,
    CS_TEAM_SPECTATOR = 3,
};*/
}
/////////////////////////////////////////////////////////////////KillEvent/////////////////////////////////////////////////////////////////
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (attacker == victim  || !is_user_connected(attacker))
		return HAM_IGNORED
	if(get_user_team(attacker) == 1 && g_isBoss[victim])
	{
		client_print(attacker, print_center, "你殺了東西，獲得%d經驗值，外加10年有期徒刑", (8000 * get_cvar_num("Ako_exp")))
		semen[attacker][1] += 8000 * get_cvar_num("Ako_exp")
	}
	if(get_user_team(victim) == 1 && g_isBoss[victim])
	{
		make_entity(victim, "HighBouns", "models/head.mdl",255,255,255,0,0)
		make_entity(victim, "LowBouns", "models/head.mdl",0,0,255,0,10)
		make_entity(victim, "LowBouns", "models/head.mdl",0,0,255,10,8)
		make_entity(victim, "LowBouns", "models/head.mdl",0,0,255,10,0)
		make_entity(victim, "LowBouns", "models/head.mdl",0,0,255,8,10)
		make_entity(victim, "LowBouns", "models/head.mdl",0,0,255,5,5)
		emit_sound(victim, CHAN_VOICE, "Ako/boss_death.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_printcolor(0, "/g[掉落]/ctr花豹掉落寶物，原來花豹會掉落稀有寶物，大家快點屠殺花豹阿")

	}
	return HAM_IGNORED
}
////////////////////////////////////////////////////////////////DamageEvent////////////////////////////////////////////////////////////////
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (attacker == victim  || !is_user_connected(attacker))
		return HAM_IGNORED

	if ( g_isBoss[victim] )
	{
		new ddfsd = random_num(0,1)
		switch(ddfsd)
		{
			case 0: 
			{ 
				emit_sound(victim, CHAN_VOICE, "Ako/hurt1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
			}
			case 1: 
			{ 
				emit_sound(victim, CHAN_VOICE, "Ako/hurt2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
			}
		}
	}

	return HAM_IGNORED
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
    	if (attacker == victim  || !is_user_connected(attacker) || cs_get_user_team(attacker) == cs_get_user_team(victim))
                 	return HAM_IGNORED

	if ( get_user_weapon(attacker) == CSW_KNIFE && get_user_team(attacker) == 2)
	{
		g_damagedealt[attacker] += floatround(damage) + porn[attacker][0] + normal_knife_damage[kfmod[attacker]]  //---------0725
		SetHamParamFloat(4, damage + porn[attacker][0] + normal_knife_damage[kfmod[attacker]]) //---------0725
		set_hudmessage(0, 255, 0, 0.49, 0.3, 1, 1.5, 0.3, 0.0, 0.0, 3)
		show_hudmessage(attacker ,"+%d",floatround(damage) + porn[attacker][0] + normal_knife_damage[kfmod[attacker]] );
	}
	else if ( get_user_weapon(attacker) != CSW_KNIFE && get_user_team(attacker) == 2)
	{
		g_damagedealt[attacker] += floatround(damage) + porn[attacker][0]  //---------0725
		SetHamParamFloat(4, damage + porn[attacker][0]) //---------0725
	}
	else if ( get_user_weapon(attacker) == CSW_KNIFE && get_user_team(attacker) == 1 && g_isBoss[attacker])
	{
		SetHamParamFloat(4, damage + get_cvar_float("boss_add_atk")) //---------0726
	}

        while (g_damagedealt[attacker] >= 3000)
        {
		client_print(attacker, print_center, "累積傷害達3000，獲得%d經驗值，附加獎勵%d經驗，金錢%d", (3000 * get_cvar_num("Ako_exp")),(10-rein[attacker])*60,2)
		semen[attacker][1] += 210 * get_cvar_num("Ako_exp") + (10-rein[attacker])*30
		g_money[attacker] += 2
		g_damagedealt[attacker] -= 3000
        }
	return HAM_IGNORED
}
public LowBouns_Pickup(ptr, ptd)
{
	new const temp_arr[] = {0 ,1 ,4 ,5 ,7 ,8 ,11, 13, 14, 17, 18}
	if( is_user_alive(ptd) && pev_valid(ptr) ) 
	{ 	
		new item,tnum
		item = random_num(0,10)
		tnum = random_num(1,100)
		switch(tnum)
		{
			case 1..90:{
				material[ptd][15] += tnum
				client_printcolor(ptd, "/g[系統]/ctr你撿到 %s %d個", material_name[15],tnum)
			}
			case 91..100:{
				material[ptd][temp_arr[item]] ++
				client_printcolor(ptd, "/g[系統]/ctr你撿到 %s", material_name[temp_arr[item]])
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
		new item
		item = random_num(0,6)
		material[ptd][temp_arr[item]] ++
		client_printcolor(ptd, "/g[系統]/ctr你撿到/g稀有/ctr %s", material_name[temp_arr[item]])
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
	weapon_switch_menu(id)
	cs_set_user_money(id, 0)

	if (get_user_team(id) == 2)
		set_user_health(id, get_user_health(id)+(porn[id][2]*3))

	if (rein[id] >= 2 && kfmod[id] == 4)
	{
		kfmod[id] = 0
		set_pev(id, pev_viewmodel2, "models/v_knife.mdl")
		set_pev(id, pev_weaponmodel2, "models/p_knife.mdl")
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
	len += formatex(menu[len], charsmax(menu) - len, "\y3.\w便宜刀 ^n^n^n") //------------------------0729
	len += formatex(menu[len], charsmax(menu) - len, "\y4.\r關閉 ")
	show_menu(id, KEYSMENU, menu, -1, "WEAPON_SWITCH")
}
public switch_for_nor(id,key)
{
	switch(key)
	{
		case 0: choose_level_maingun(id)
		case 1: forver_use_switch_menu(id)
		case 2: lala_knife_mod(id)
		case 3: return ;
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
	len += formatex(menu[len], charsmax(menu) - len, "\y1.\r用巨屌幫你作永久槍 ^n") //------------------------0725
	len += formatex(menu[len], charsmax(menu) - len, "\y2.\r用巨屌幫你作便宜刀 ^n")//------------------------0725
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
		case 1:crafted_knife(id)
		case 2:{//------------------------0725
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
		len += formatex(menu[len], charsmax(menu) - len, "\r%d.\w%s 需要金錢[\y%d\w] +\r%dAck^n",i+1,normal_knife_name[i],normal_knife_count[i],normal_knife_damage[i+1])
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
		client_printcolor(id,"/g[系統]/ctr不夠做三小過來我要肛你.")
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
    for (new i=0; i< sizeof forge ; i++) //sizeof(material_synthesis[i])
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
			for (new i=0 ; i < sizeof forge ; i++){
				if (material[id][material_synthesis[itemkey_temp[id]][i]] < material_count[itemkey_temp[id]][i])
				{
					client_printcolor(id, "/g[系統]/ctr材料不足")
					return ;
				}
			}
			for (new i=0 ; i < sizeof forge ; i++)
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
	len += formatex(menu[len], charsmax(menu) - len, "\w投胎需要達到\r800000經驗值\w及\r2金^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y1.\r確認投胎^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y2.\w取消投胎^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w啊對了投胎上限最多\y十次\w還有\r設計圖\w可以拿^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w還可以戶籍地投胎 投完胎起薪比現在大學生都好有\r38k^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w還不快一點來投胎 \yBy投胎人才招募中心")
	show_menu(id, KEYSMENU, menu, -1, "REIN")
}
public rein_menu(id, key)
{
	switch (key){
		case 0:{
			if (semen[id][0] >= 100 && rein[id]<10 && semen[id][1] >= 800000 && g_money[id] >= 2){
				rein[id] ++
				semen[id][0]=1
				semen[id][1]=0
				porn[id][0]=0;porn[id][1]=0;porn[id][2]=0;porn[id][3]=0;porn[id][4]=0
				g_money[id] -= 2
				new awerw[] = {16,20,21,22}
				new uiii = random_num(0,3)
				material[id][awerw[uiii]] ++
				client_printcolor(id, "/g[投胎]/ctr獲得%s！[要加入KuroNeko的宗教請找他]",material_name[awerw[uiii]])
			}
			else
				client_printcolor(id, "/g[投胎]/ctr條件不符合")
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
				else
					get_blockar(id)
			}
			case 1:{
				if (combin_material[id][2] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else
					give_user_tb(id)
			}
			case 2:{
				if (combin_material[id][3] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else
					give_user_gatling(id)
			}
			case 3:{
				if (combin_material[id][4] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else
					give_user_CompoundBow(id)
			}
			case 4:{
				if (combin_material[id][5] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else
					give_plasma(id)
			}
			case 5:{
				if (combin_material[id][6] < 1)
					client_printcolor(id, "/g[系統]/ctr你沒有武器(女朋友)")
				else
					give_user_thanatos11(id)
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
				client_printcolor(id, "/g[系統]/ctr已成功裝備.")
				set_pev(id, pev_viewmodel2, "models/Ako/v_Karambit.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_Karambit.mdl")
			}
		}
		case 1:{
			if (norkf[id][1] >= 1){
				kfmod[id] = 2
				client_printcolor(id, "/g[系統]/ctr已成功裝備.")
				set_pev(id, pev_viewmodel2, "models/Ako/v_byknife.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_byknife.mdl")
			}
		}
		case 2:{
			if (norkf[id][2] >= 1){
				kfmod[id] = 3
				client_printcolor(id, "/g[系統]/ctr已成功裝備.")
				set_pev(id, pev_viewmodel2, "models/Ako/v_blueaxe.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_blueaxe.mdl")
			}
		}
	}
}
public basic_weapon_switch(id) //-----0726
{
	new tempid[32], menu, g_format[201]
	format(g_format, charsmax(g_format), "\r[限投胎次數0~2] \w我才不是為了你 才送你的 %s%s",g_has_handjob[id]?"\d":"\w",g_has_handjob[id]?"[已選擇]":"[未選擇]")
	menu = menu_create(g_format, "basic_weapon")

	menu_additem(menu, "按我領取免費永久槍", "1", 0)
	menu_additem(menu, "按我領取免費普通錘", "2", 0)
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
			if (rein[id] < 3 && !g_has_handjob[id])
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
						give_user_tb(id)
						g_has_handjob[id]=true
					}
					case 3:
					{ 
						give_user_gatling(id) 
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
						give_user_thanatos11(id)
						g_has_handjob[id]=true
					}
				}
			}
		}
		case 2:
		{
			if (rein[id] < 3)
			{
				kfmod[id] = 4
				client_printcolor(id, "/g[系統]/ctr已成功裝備.")
				set_pev(id, pev_viewmodel2, "models/Ako/v_warhammer.mdl")
				set_pev(id, pev_weaponmodel2, "models/Ako/p_warhammer.mdl")
			}
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
/////////////////////////////////////////////////////////////////Main Menu/////////////////////////////////////////////////////////////////
public majaja(id)
{
	static menu[600], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w麻六甲選單 \y(色情語音群RC:\r25453746\y)^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y1\r.\w能力選單 \y[能力點:%d]^n", porn[id][4])
	len += formatex(menu[len], charsmax(menu) - len, "\y2\r.\w選擇武器(刀and槍)^n") 
	len += formatex(menu[len], charsmax(menu) - len, "\y3\r.\w找工廠老闆^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y4\r.\w投胎招募中心^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y5\r.\w黑市交易商^n")
	len += formatex(menu[len], charsmax(menu) - len, "\y6\r.\w選擇便宜刀^n") //-----------------0725
	len += formatex(menu[len], charsmax(menu) - len, "\y7\r.\r使用新手免費裝備^n") //---------0726
	if((get_user_flags(id) & ADMIN_GAY))
		len += formatex(menu[len], charsmax(menu) - len, "\y8\r.\w管理員選單^n")
        len += formatex(menu[len], charsmax(menu) - len, "\r(BUG)如在可復活情況下無法復活請自行重進")

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
		case 5:lala_knife_mod(id)  //-----------0725
		case 6:basic_weapon_switch(id) //----------0726
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
	len += formatex(menu[len], charsmax(menu) - len, "\w1準雷^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w2樂高M4A1^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w3戰慄加農砲^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w4普拉斯瑪槓^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w5蒼穹EX^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w6Thanatos11^n")

	show_menu(id, KEYSMENU, menu, -1, "Sweet")
}
public sweet_menu(id, key)
{
	switch (key)
	{
		case 0:give_user_tb(id)
		case 1:get_blockar(id)
		case 2:give_user_gatling(id)
		case 3:give_plasma(id)
		case 4:give_user_CompoundBow(id)
		case 5:give_user_thanatos11(id)
	}
}
////////////////////////////////////////////////////////////////////Buy////////////////////////////////////////////////////////////////////
public buy_item_menu(id)
{
	new menu[250], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w黑市交易(請使用蘿莉交易)^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w1.夜視鏡(單生命)  COST:5隻蘿莉^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w2.衝擊結界(單場次)  COST:200隻蘿莉^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w3.真正的現實蘿莉(單生命可無限使用) COST:99999隻蘿莉^n")
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
				cs_set_user_nvg(id)
			}
		}
		case 1:
		{
			if (g_money[id] >= 200){
				client_printcolor(id, "/g你購買了衝擊結界(CD:10sec)，按/ctrE/g可以暫時擊退花豹")
				g_money[id] -= 200
				space[id] = true
			}
		}
	}
}
///////////////////////////////////////////////////////////////////Space///////////////////////////////////////////////////////////////////
public usespace(id)
{
	static Float:last_check_time;
	if (get_gametime() - last_check_time < 10.0)
		return PLUGIN_HANDLED
	last_check_time = get_gametime();

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

			if (range <= 500.0 && floatabs(origin2[2] - origin1[2]) <= 60.0 && get_user_team(i) != get_user_team(id))
			{
				new Float:velocity[3]
				get_speed_vector_to_entity(id, i, 700.0, velocity)
				velocity[2] += 400.0
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
			case 4:{
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
	len += formatex(menu[len], charsmax(menu) - len, "\y1.攻擊力 \r%d/%d   [增加%d攻擊]^n^n", porn[id][0],30+(rein[id]*3),porn[id][0])
	len += formatex(menu[len], charsmax(menu) - len, "\y2.移動速度   \r%d/%d   [增加%d速度]^n^n", porn[id][1], (26+rein[id]*2),porn[id][1])
	len += formatex(menu[len], charsmax(menu) - len, "\y3.生命值   \r%d/%d   [增加%d血量]^n^n", porn[id][2],20+(rein[id]*4),porn[id][2]*3)
	len += formatex(menu[len], charsmax(menu) - len, "\y4.雞雞長度(你沒雞雞)   \r%d/30   [點了沒用別怪我 自己雞雞爛]^n^n", porn[id][3])

	show_menu(id, KEYSMENU, menu, -1, "Skill Menu")
}
public skill_menu(id, key)
{
	switch (key)
	{
		case 0:
		{
			if (porn[id][4] >= 1 && porn[id][0] < 30+(rein[id]*3))
			{
				porn[id][0] ++
				porn[id][4] --
				show_skill_menu(id)
			}
		}
		case 1:
		{
			if (porn[id][4] >= 1 && porn[id][1] < 26+rein[id]*2)
			{
				porn[id][1] ++
				porn[id][4] --
				show_skill_menu(id)
			}
		}
		case 2:
		{
			if (porn[id][4] >= 1 && porn[id][2] < 20+(rein[id]*4))
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
			porn[id][0] += 10000
			ochinchinmenu(id)
		}
		case 1:
		{
			porn[id][1] += 10000
			ochinchinmenu(id)
		}
		case 2:
		{
			porn[id][3] += 100000000
			ochinchinmenu(id)
		}
	}
}
/////////////////////////////////////////////////////////////////ServerHUD/////////////////////////////////////////////////////////////////
public client_connect(id)
{
	LoadData(id)
	LoadData2(id)
	new name[32]
	get_user_name(id, name, 31)
	
	set_task(120.0, "Rape",id,_,_,"b");
	client_printcolor(0, "/ctr%s/g正在連接伺服器.他是一名甲甲呢 [LV:%d]", name, semen[id][0])
}
public client_disconnect(id)
{
	SaveData(id)
	SaveData2(id)

	if(g_isBoss[id])
	{
		g_isBoss[id]=false;
		remove_task(id+4567)
		remove_task(id+4256)

		new i, iPlayers[32], iNum, iPlayer
		get_players(iPlayers, iNum, "c")
		for (i = 0;i < iNum;i++){
			iPlayer = iPlayers[i]
			set_task(5.0,"player_kill",iPlayer)
			client_printcolor(0, "/g[系統]/ctr由於魔王中出遊戲，5秒後將處死^^")
		}
	}
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
		blue = 55
	}
	set_hudmessage(red, green, blue, -0.85, 0.15, 0, 0.0, 0.4, 0.0, 0.0, 3)
	show_hudmessage(taskid ,"|---------------------|^n|血量:%d|^n|等級:%d||經驗:%d/%d|^n|經驗倍率:%d|^n|投胎次數:%d|^n|金錢:%d|^n|---------------------|", get_user_health(taskid) ,semen[taskid][0], semen[taskid][1], dildo[semen[taskid][0]], get_cvar_num("Ako_exp"),rein[taskid],g_money[taskid])

	if (is_user_alive(taskid))
	{
		show_hudmessage(taskid , "|---------------------|^n|血量:%d|^n|等級:%d||經驗:%d/%d|^n|經驗倍率:%d|^n|投胎次數:%d|^n|金錢:%d|^n|---------------------|", get_user_health(taskid) ,semen[taskid][0], semen[taskid][1], dildo[semen[taskid][0]], get_cvar_num("Ako_exp"),rein[taskid],g_money[taskid])
	}
	else
	{
		show_hudmessage(taskid , "|---------------------|^n|狀態:死亡|^n|等級:%d||經驗:%d/%d|^n|經驗倍率:%d|^n|投胎次數:%d|^n|金錢:%d|^n|---------------------|",semen[taskid][0], semen[taskid][1], dildo[semen[taskid][0]], get_cvar_num("Ako_exp"),rein[taskid],g_money[taskid])
	}
	//set_task(0.2, "show_hud", taskid+4567)
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
	format(vaultdata, 255, "%i#%i#%i#%i#%i#", rein[id],norkf[id][0],norkf[id][1],norkf[id][2],g_money[id])
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
	format(vaultdata, 255, "%i#%i#%i#%i#%i#", rein[id],norkf[id][0],norkf[id][1],norkf[id][2],g_money[id])
	nvault_get(g_vault2, vaultkey, vaultdata, 255) 

	replace_all(vaultdata, 255, "#", " ")

	new re_in[32],nkf0[32],nkf1[32],nkf2[32],gmoney[32]
	parse(vaultdata, re_in,31,nkf0,31,nkf1,31,nkf2,31,gmoney,31)
	rein[id] = str_to_num(re_in)
	norkf[id][0] = str_to_num(nkf0)
	norkf[id][1] = str_to_num(nkf1)
	norkf[id][2] = str_to_num(nkf2)
	g_money[id] = str_to_num(gmoney)
}
public Rape(id)
{
	SaveData(id)
	SaveData2(id)
	client_printcolor(id, "/g[系統]/ctr自動保存資料成功!")
	client_printcolor(id, "/g[系統]/ctr控制台輸入/menu開啟主選單，綁定方式bind f1 /menu")
}
public make_entity(victim, const classname[], const model[],redmax,greenmax,bluemax,posx,posy)
{
	new myitem = create_entity("info_target");
	entity_set_string(myitem, EV_SZ_classname, classname);
	entity_set_int(myitem, EV_INT_solid, SOLID_BBOX);

	new Float:vAim[3], Float:vOrigin[3];
	entity_get_vector(victim, EV_VEC_origin, vOrigin);

	VelocityByAim(victim, random_num(2, 4), vAim);

	vOrigin[0] += posx;
	vOrigin[1] += posy;
	vOrigin[2] += 10;

	entity_set_model(myitem, model)
	entity_set_size(myitem, Float:{-2.1, -2.1, -2.1}, Float:{2.1, 2.1, 2.1});
	entity_set_int(myitem, EV_INT_movetype, 6);
	entity_set_vector(myitem, EV_VEC_origin, vOrigin);
	set_rendering(myitem, kRenderFxGlowShell, random_num(0,redmax), random_num(0,greenmax), random_num(0,bluemax), kRenderNormal, 90)
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
//#include "d2_monstermod.sma"