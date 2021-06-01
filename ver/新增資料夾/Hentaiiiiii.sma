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

native get_user_boss(id);
native give_user_tb(id);
native give_user_gatling(id);

new semen[33][2] //0level 1exp
new porn[33][5] //0atk 1speed 2hp 3dodge 4point
new g_damagedealt[33]
new bool:g_has_handjob[33]
new g_sync1
new g_vault
new material[33][17] //  0十字輪迴狙擊鏡 1準雷狙擊鏡 2十字輪迴架構 3準雷架構 4狙擊槍彈夾 5狙擊槍板機 6戰慄加農砲架構 7戰慄加農砲彈鼓 8散彈槍板機 9弓 10弦 11箭 12血滴子架構 13血滴子刀片 14血滴子手套 15催化劑 16無
new combin_material[33][6] //1十字輪迴 2準雷 3戰慄加農砲 4蒼穹EX 5血滴子
new itemkey_temp[33]

new const dildo[] = {
100, 200, 300, 400, 700, 900, 1100, 1400, 1700, 2000,
2400, 2900, 3000, 3500, 4200, 5000, 6000, 7500, 9000, 11000,
14000, 17000, 22000, 26000, 31000, 3700, 43000, 49000, 55000, 65000,
70000, 73000, 76000, 80000, 83000, 85000, 90000, 95000, 100000, 110000,
120000, 130000, 140000, 150000, 160000, 170000, 180000, 190000, 200000, 210000,
220000, 240000, 260000, 270000, 280000, 290000, 300000, 320000, 330000, 350000,
360000, 370000, 380000, 390000, 400000, 420000, 430000, 450000, 460000, 480000,
500000, 510000, 520000, 530000, 540000, 550000, 560000, 580000, 600000, 610000,
630000, 650000, 680000, 710000, 740000, 750000, 760000, 780000, 800000, 840000,
880000, 930000, 950000, 1000000, 1100000, 1300000, 1500000, 1700000, 2000000, 2100000,
2200000, 2400000, 2600000, 2700000, 2800000, 2900000, 3000000, 3200000, 3300000, 3500000,
3600000, 3700000, 3800000, 3900000, 4000000, 4200000, 4300000, 4500000, 4600000, 4800000,
5000000, 5100000, 5200000, 5300000, 5400000, 5500000, 5600000, 5800000, 6000000, 6100000,
6300000, 6500000, 6800000, 7100000, 7400000, 7500000, 7600000, 7800000, 8000000, 8400000,
8800000, 9300000, 9500000, 10000000, 11000000, 13000000, 15000000, 17000000, 20000000, 21000000,
}
new const dildo_handjob_name[][] = { "", "MP5", "M3", "P90", "XM1014", "AWP", "FAMAS", "AUG", "Galil", "M4A1", "AK47", "G3SG1", "SG550", "M249" }
new const dildo_handjob_give[][] = { "", "weapon_mp5navy", "weapon_m3", "weapon_p90", "weapon_xm1014", "weapon_awp", "weapon_famas", "weapon_aug", 
"weapon_galil", "weapon_m4a1", "weapon_ak47", "weapon_g3sg1", "weapon_sg550", "weapon_m249" }
new const dildo_handjob_level[] = { 0, 0, 3, 7, 12, 15, 17, 20, 21, 25, 26, 30, 31, 32 }
new const material_count[][] = {{},{1,1,4,1,300},{1,1,4,1,450},{1,1,1,350,0},{1,1,15,500,0},{1,10,1,450,0}}
new const material_synthesis[][] = {{},{0,2,4,5,15},{1,3,4,5,15},{6,7,8,15,16},{9,10,11,15,16},{12,13,14,15,16}}
new const material_name[][] = {"十字輪迴狙擊鏡","準雷狙擊鏡","十字輪迴架構", "準雷架構", "狙擊槍彈夾","狙擊槍板機", "戰慄加農砲架構", "戰慄加農砲彈鼓","散彈槍板機", "弓" ,"弦", "箭", "血滴子架構", "血滴子瑞士刀片", "血滴子刺青袖套", "催產劑","無"}
new const forge[][] = { "", "十字輪迴", "準雷", "戰慄加農砲", "蒼穹EX", "血滴子" }

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
////////////////////////////////////////////////////////////////////New////////////////////////////////////////////////////////////////////
public plugin_natives()
{
	register_native("set_user_exp", "native_set_user_exp", 1);
	register_native("open_normal_menu", "native_open_normal_menu", 2)
	register_native("open_forver_menu", "native_open_forver_menu", 3)
}
public native_set_user_exp(id)
	semen[id][1] += 5000*get_cvar_num("Ako_exp");
public native_open_normal_menu(id)
	choose_gun(id)
public native_open_forver_menu(id)
	craft_menu(id)

public plugin_init()
{
	register_plugin("Hentai", "1.0", "Ako")
	register_clcmd("/menu", "majaja")
	//register_clcmd("say /cm", "craft_menu")
	register_clcmd("say /test", "kk3k3")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	register_concmd("rest_data", "set_boobs", ADMIN_FAP)
	register_concmd("set_exp", "set_expp", ADMIN_FAP)

	register_menu("Skill Menu", KEYSMENU, "skill_menu")
	register_menu("Main Menu", KEYSMENU, "main_menu")
	register_menu("ICraft", KEYSMENU, "IForge")

    	register_menucmd(register_menuid("\y工具坊製造"), 1023, "confirm0" )

	register_cvar("Ako_exp", "1")

	g_sync1 = CreateHudSyncObj()
	g_vault = nvault_open("Ako_monster")

}
public set_boobs(id)
{
	new Target[64], Target_Name[64]
	read_argv(1, Target, 63)

	if (!cmd_target(id, Target))
	return PLUGIN_HANDLED;
	get_user_name(cmd_target(id, Target), Target_Name, 63)
	porn[cmd_target(id, Target)][0] = 0
	porn[cmd_target(id, Target)][1] = 0
	porn[cmd_target(id, Target)][2] = 0
	porn[cmd_target(id, Target)][3] = 0
	porn[cmd_target(id, Target)][4] = 0
	semen[cmd_target(id, Target)][0] = 0
	semen[cmd_target(id, Target)][1] = 0
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
/////////////////////////////////////////////////////////////////Monitoring////////////////////////////////////////////////////////////////
public fw_PlayerPreThink(id)
{
	if(!is_user_connected(id) && !is_user_alive(id))
		return PLUGIN_HANDLED

	if (semen[id][1] >= dildo[semen[id][0]] && semen[id][1] != 36)
	{
		semen[id][1] -= dildo[semen[id][0]]
		semen[id][0] ++
		porn[id][4] += 3
		new name[32]
		get_user_name(id, name, 31)
		client_printcolor(0, "/ctr%s/g的等級提升至/ctr%d", name, semen[id][0])
    	}

	if (get_user_team(id) == 1 && get_user_weapon(id) != CSW_KNIFE)
		fm_give_item(id, "weapon_knife")
	return PLUGIN_HANDLED
}
/////////////////////////////////////////////////////////////////KillEvent/////////////////////////////////////////////////////////////////
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (attacker == victim  || !is_user_connected(attacker))
		return HAM_IGNORED
	if(get_user_team(attacker) == 2)
	{
		client_print(attacker, print_center, "你殺了東西，獲得%d經驗值", (300 * get_cvar_num("Ako_exp")))
		semen[attacker][1] += 300 * get_cvar_num("Ako_exp")
	}
	return HAM_IGNORED
}
////////////////////////////////////////////////////////////////DamageEvent////////////////////////////////////////////////////////////////
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
    	if (attacker == victim  || !is_user_connected(attacker) || cs_get_user_team(attacker) == cs_get_user_team(victim))
                 	return HAM_IGNORED

	g_damagedealt[attacker] += (floatround(damage) + (porn[attacker][0]))

        while (g_damagedealt[attacker] >= 500)
        {
		client_print(attacker, print_center, "累積傷害達500，獲得%d經驗值", (100 * get_cvar_num("Ako_exp")))
		semen[attacker][1] += 100 * get_cvar_num("Ako_exp")
		g_damagedealt[attacker] -= 500
        }
	return HAM_IGNORED
}
////////////////////////////////////////////////////////////////Spawn Event////////////////////////////////////////////////////////////////
public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) && !is_user_connected(id))
		return PLUGIN_HANDLED

	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	g_has_handjob[id] = false
	return PLUGIN_HANDLED
}
/////////////////////////////////////////////////////////////////Level Gun/////////////////////////////////////////////////////////////////
public choose_level_maingun(id)
{
	new szTempid[32]
	new menu = menu_create("\r等級槍", "choose_level_maingun2")
	
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
		{
			choose_level_maingun(id)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public choose_gun(id)
{
	new menu = menu_create("\y選擇一種武器", "choose_gun2")
	menu_additem(menu, "\w等級槍", "1", 0)
    	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
    	menu_display(id, menu, 0)
}
public choose_gun2(id,  menu, item)
{
    if (item == MENU_EXIT)
    {
         menu_destroy(menu)
         return PLUGIN_HANDLED
    }
    new data[6], iName[64]
    new access, callback
    menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)

    new key = str_to_num(data)
    switch(key)
    {
    	case 1: choose_level_maingun(id)
    }
    menu_destroy(menu)
    return PLUGIN_HANDLED
}
///////////////////////////////////////////////////////////////////Forge///////////////////////////////////////////////////////////////////
public craft_menu(id)
{
	static menu[250], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w[武器製作選單] ^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w1.製作武器 ^n")

	show_menu(id, KEYSMENU, menu, -1, "ICraft")
}
public kk3k3(id)
{
	material[id][0] += 5;material[id][1] += 5;material[id][2] += 5;material[id][3] += 5;material[id][4] += 5;material[id][5] += 5;material[id][6] += 5;material[id][7] += 5;material[id][8] += 5
	material[id][9] += 5;material[id][10] += 5;material[id][11] += 5;material[id][12] += 5;material[id][13] += 5;material[id][14] += 5;material[id][15] += 2000
}
public IForge(id, key)
{
	switch (key)
	{
		case 0:crafted(id)
	}
}

public crafted(id)
{
	new szTempid[32], menu
	menu = menu_create("\w選擇所要製作的武器", "crafted2")
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
	mkmenu0(id,i)
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public mkmenu0(id,itemkey)
{
    new szMenuBody[256]    //以new選告szMenuBody為變數，以此作為載體來儲存選單內容 
    new keys    //宣告按鍵 
    new nLen = format( szMenuBody, 255, "\y工具坊製造^n")//, forge[itemkey])
    //nLen += format( szMenuBody[nLen], 255-nLen, "1. %s" ) 
    for (new i=0; i<= 4 ; i++) //sizeof(material_synthesis[i])
    {
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r%d. \w%s ^t\y[%d/%d]", i+1,material_name[material_synthesis[itemkey][i]],material[id][material_synthesis[itemkey][i]],material_count[itemkey][i])
    }
    nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r7. \w確定製作\r%s?",forge[itemkey])
    keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
    itemkey_temp[id] = itemkey
    show_menu( id, keys, szMenuBody, -1 )    //顯示選單 
}
public confirm0( id,key ){
	switch(key)
	{
		case 6:
		{
			for (new i=0 ; i <= 4 ; i++){
				if (material[id][material_synthesis[itemkey_temp[id]][i]] < material_count[itemkey_temp[id]][i]){
					client_print(id, print_chat,"材料不足")
					return;
				}
			}
			for (new i=0 ; i <= 4 ; i++)
				material[id][material_synthesis[itemkey_temp[id]][i]] -= material_count[itemkey_temp[id]][i]

			client_print(id, print_chat,"製作成功！")
			combin_material[id][itemkey_temp[id]] = 1;
		}
	}
}
/////////////////////////////////////////////////////////////////Main Menu/////////////////////////////////////////////////////////////////
public majaja(id)
{
	static menu[250], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w目錄選單 \y(色情語音群RC:25453746)^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w1.能力選單 \d[能力點:%d]^n", porn[id][4])
	if (!g_has_handjob[id])
		len += formatex(menu[len], charsmax(menu) - len, "\w2.選擇武器 [可選擇]^n")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\w2.選擇武器 \d[已選擇]^n")

	show_menu(id, KEYSMENU, menu, -1, "Main Menu")
}
public main_menu(id, key)
{
	switch (key)
	{
		case 0:show_skill_menu(id)
		case 1:choose_gun(id)
	}
}
///////////////////////////////////////////////////////////////////Skill///////////////////////////////////////////////////////////////////
public show_skill_menu(id)
{
	static menu[250], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\w能力點:%d^n^n", porn[id][4])
	len += formatex(menu[len], charsmax(menu) - len, "\y1.攻擊力 \r%d/75   [增加%d攻擊]^n^n", porn[id][0], porn[id][0])
	len += formatex(menu[len], charsmax(menu) - len, "\y2.速度   \r%d/26   [增加%d速度]^n^n", porn[id][1], porn[id][1])
	len += formatex(menu[len], charsmax(menu) - len, "\y3.血量   \r%d/36   [增加%d血量]^n^n", porn[id][2], porn[id][2]*3)
	len += formatex(menu[len], charsmax(menu) - len, "\y4.閃躲   \r%d/10   [增加%d機率]^n", porn[id][3], porn[id][3])
	show_menu(id, KEYSMENU, menu, -1, "Skill Menu")
}
public skill_menu(id, key)
{
	switch (key)
	{
		case 0:
		{
			if (porn[id][4] >= 1 && porn[id][0] < 75)
			{
				porn[id][0] ++
				porn[id][4] --
				show_skill_menu(id)
			}
		}
		case 1:
		{
			if (porn[id][4] >= 1 && porn[id][1] < 26)
			{
				porn[id][1] ++
				porn[id][4] --
				show_skill_menu(id)
			}
		}
		case 2:
		{
			if (porn[id][4] >= 1 && porn[id][2] < 36)
			{
				porn[id][2] ++
				porn[id][4] -- 
				show_skill_menu(id)
			}
		}
		case 3:
		{
			if (porn[id][4] >= 1 && porn[id][3] < 10)
			{
				porn[id][3] ++
				porn[id][4] --
				show_skill_menu(id)
			}
		}
	}
}
/////////////////////////////////////////////////////////////////ServerHUD/////////////////////////////////////////////////////////////////
public client_connect(id)
{
	new name[32]
	get_user_name(id, name, 31)
	set_task(0.1, "show_hud", id+4567, "", 0, "b", 0);
	LoadData(id)
	set_task(120.0, "Rape",id,_,_,"b");
	client_printcolor(0, "/ctr%s/g正在連接伺服器. [LV:%d]", name, semen[id][0])
}
public client_disconnect(id)
{
	SaveData(id)
}
public show_hud(taskid)
{
    taskid -= 4567

	static red, green, blue
	if (get_user_boss(taskid))
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
	set_hudmessage(red, green, blue, -0.85, 0.15, 0, 0.0, 0.2, 0.0, 0.0, 2)
	show_hudmessage(taskid ,"|聽說RAY很色很淫蕩|^n|血量:%d|^n|等級:%d||經驗:%d/%d|^n|經驗倍率:%d|", get_user_health(taskid) ,semen[taskid][0], semen[taskid][1], dildo[semen[taskid][0]], get_cvar_num("Ako_exp"))

	if (is_user_alive(taskid))
	{
		show_hudmessage(taskid , "|聽說RAY很色很淫蕩|^n|血量:%d|^n|等級:%d||經驗:%d/%d|^n|經驗倍率:%d|", get_user_health(taskid) ,semen[taskid][0], semen[taskid][1], dildo[semen[taskid][0]], get_cvar_num("Ako_exp"))
	}
	else
	{
		show_hudmessage(taskid , "|聽說RAY很色很淫蕩|^n|狀態:死亡|^n|等級:%d||經驗:%d/%d|^n|經驗倍率:%d|",semen[taskid][0], semen[taskid][1], dildo[semen[taskid][0]], get_cvar_num("Ako_exp"))
	}
	//set_task(0.2, "show_hud", taskid+4567)
}
public SaveData(id)
{
	new name[32], vaultkey[64], vaultdata[256] 
              
	get_user_name(id, name, 31) 
             
	format(vaultkey, 63, "%s", name) 
	format(vaultdata, 255, "%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#",
	semen[id][0],semen[id][1],porn[id][0],porn[id][1],porn[id][2],porn[id][3],porn[id][4],material[id][0],material[id][1],material[id][2],
	material[id][3],material[id][4],material[id][5],material[id][6],material[id][7],material[id][8],material[id][9],material[id][10],material[id][11],material[id][12],material[id][13],
	material[id][14],material[id][15],combin_material[id][1],combin_material[id][2],combin_material[id][3],combin_material[id][4],combin_material[id][5])
 
	nvault_set(g_vault, vaultkey, vaultdata)
}
public LoadData(id)
{
	new name[32], vaultkey[64], vaultdata[256] 
	get_user_name(id,name,31) 
             
	format(vaultkey, 63, "%s", name) 
	format(vaultdata, 255, "%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#",
	semen[id][0],semen[id][1],porn[id][0],porn[id][1],porn[id][2],porn[id][3],porn[id][4],material[id][0],material[id][1],material[id][2],
	material[id][3],material[id][4],material[id][5],material[id][6],material[id][7],material[id][8],material[id][9],material[id][10],material[id][11],material[id][12],material[id][13],
	material[id][14],material[id][15],combin_material[id][1],combin_material[id][2],combin_material[id][3],combin_material[id][4],combin_material[id][5])

	nvault_get(g_vault, vaultkey, vaultdata, 255) 
             
	replace_all(vaultdata, 255, "#", " ")
             
	new n_lv[32],n_ex[32],s_0[32],s_1[32],s_2[32],s_3[32],s_4[32],f_m0[32],f_m1[32],f_m2[32],f_m3[32],f_m4[32],f_m5[32],f_m6[32],f_m7[32],f_m8[32],f_m9[32],f_m10[32],f_m11[32],f_m12[32],f_m13[32],f_m14[32],f_m15[32],f_cm1[32],f_cm2[32],f_cm3[32],f_cm4[32],f_cm5[32]
	parse(vaultdata, n_lv,31,n_ex,31,s_0,31,s_1,31,s_2,31,s_3,31,s_4,31,f_m0,31,f_m1,31,f_m2,31,f_m3,31,f_m4,31,f_m5,31,f_m6,31,f_m7,31,f_m8,31,f_m9,31,f_m10,31,f_m11,31,f_m12,31,f_m13,31,f_m14,31,f_m15,31,f_cm1,31,f_cm2,31,f_cm3,31,f_cm4,31,f_cm5,31)

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
	combin_material[id][1] = str_to_num(f_cm1)
	combin_material[id][2] = str_to_num(f_cm2)
	combin_material[id][3] = str_to_num(f_cm3)
	combin_material[id][4] = str_to_num(f_cm4)
	combin_material[id][5] = str_to_num(f_cm5)
}
public Rape(id)
{
	SaveData(id)
	client_printcolor(id, "/g系統:/ctr自動保存資料成功!")
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