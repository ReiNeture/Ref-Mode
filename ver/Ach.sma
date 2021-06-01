public finish_achievement(id, item)
{
	if ( !g_up[id][item] && cs_get_user_team(id) != CS_TEAM_SPECTATOR )
	{
		g_up[id][item] ++
		g_mileage[id] += 10
		semen[id][1] += 17000

		new name[64]
		get_user_name(id, name, 63)
		client_printcolor(0, "/g[成就]/ctr %s %s",name,ach_name[item])
		client_printcolor(id, "/g[成就]/ctr 解開成就 並獲得10里程點 1.7萬經驗值")
	}
}
ach_menu_display(id,pos)
{
	if (pos < 0)
		return;

	new menu[512], len
	new start = pos * 8

	len = 0
	len = format(menu, 511,"\r成就列表\R%d/%d^n^n", pos + 1, (g_UPNum / 8) + (((g_UPNum % 8) > 0) ? 1 : 0))
	new end = start + 8
	if (end > g_UPNum)
		end = g_UPNum

	for (new i = start;i < end;++i){
		if ( g_up[id][i] >= 1)
			len += formatex(menu[len], charsmax(menu) - len, "\w%d. \r%s^n",i,ach_name[i])
		else
			len += formatex(menu[len], charsmax(menu) - len, "\d%d. %s^n",i,ach_name[i])
	}
	len += formatex(menu[len], charsmax(menu) - len, "^n\w1.上一頁   2.下一頁   3.第一頁   5.里程商店   0.關閉")
	show_menu(id, KEYSMENU, menu, -1, "ACH_MENU")
}
public ach_menu_switch(id, key)
{
	switch(key)
	{
		case 0: 
		{
			if ( g_menupos[id] - 1 < 0 )
				ach_menu_display(id,g_menupos[id] = 0)
			else
				ach_menu_display(id,--g_menupos[id])
		}
		case 1:
		{
			if (g_menupos[id] + 1 == (g_UPNum / 8) + (((g_UPNum % 8) > 0) ? 1 : 0))
				ach_menu_display(id, g_menupos[id])
			else
				ach_menu_display(id, ++g_menupos[id])
		}
		case 2 : ach_menu_display(id,g_menupos[id] = 0)
		case 4 : ach_shop_menu_display(id)
		case 9 : return PLUGIN_HANDLED;
		default : ach_menu_display(id,g_menupos[id])
	}
	return PLUGIN_HANDLED
}
public ach_shop_menu_display(id)
{
	static menu[400], len
	len = 0
	len += formatex(menu[len], charsmax(menu) - len, "\r里程點商店^n^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w1.隨機獲得\r藍素材x1 cost:10^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w2.隨機獲得\r紅素材x1 cost:10^n")
	len += formatex(menu[len], charsmax(menu) - len, "\w3.隨機獲得\r設計圖x1 cost:15")
	show_menu(id, KEYSMENU, menu, -1, "ACH_SHOP_MENU")
}
public ach_shop_menu_switch(id, key)
{
	new const blue[] = {0 ,1 ,4 ,5 ,7 ,8 ,11, 13, 14, 17, 18}
	new const red[] = {2, 3, 6, 9, 10, 12, 19}
	new const design[] = {16, 20, 21, 22}
	new random_of_tree
	switch(key)
	{
		case 0:
		{
			if ( g_mileage[id] >= 10 )
			{
				random_of_tree = random_num(0,10)
				client_printcolor(id, "/g[里程]/ctr抽到了 %s", material_name[blue[random_of_tree]])
				material[id][blue[random_of_tree]] ++
				g_mileage[id] -= 10
			}
		}
		case 1:
		{
			if ( g_mileage[id] >= 10 )
			{
				random_of_tree = random_num(0,6)
				client_printcolor(id, "/g[里程]/ctr抽到了 %s", material_name[red[random_of_tree]])
				material[id][red[random_of_tree]] ++
				g_mileage[id] -= 7
			}
		}
		case 2:
		{
			if ( g_mileage[id] >= 15 )
			{
				random_of_tree = random_num(0,3)
				client_printcolor(id, "/g[里程]/ctr抽到了 %s", material_name[design[random_of_tree]])
				material[id][design[random_of_tree]] ++
				g_mileage[id] -= 15
			}
		}
	}
}
public pneum(id)
{
	finish_achievement(id, SO_LONG)
}
public SaveAch(id)
{
	new Vault_Key[64]
	get_user_name(id, Vault_Key, 63)
	replace_all(Vault_Key, 63, "'", "\'" )
	new iLen = 0
	static szData[9000]
	iLen = 0
	szData = ""
	iLen += formatex(szData[iLen], charsmax(szData) - iLen, "#")
	for(new up = 0;up < MAX_COUNT;up++)
	{
		iLen += formatex(szData[iLen], charsmax(szData) - iLen, "%d#", g_up[id][up])
	}
	nvault_set(g_vault3, Vault_Key, szData)
}
public LoadAch(id)
{
	new Vault_Key[64], szClassLevel[512]//, szClassLevel2[512]
	//new szStatpoint[32], szCrit[32], szLucky[32], szDamage[32], szSpeed[32], szHealth[32], szLevel[32], szMoney[32], szLmoney[32], szSmoney[32], szRespawn[32], szOldplayer[32], szTimeS[32], szTimeM[32], szTimeH[32]
	new szUP[32]   /*,szSBN[32], szDWN[32], szKON[32], szHBK[32], szMKN[32], szSKN[32], szGAKN[32], szPKN[32], szSAKN[32], szKDN[32], szA1T[32], szA2T[32],
	szUM[32], szHBH[32], szKBN[32], szKSBN[32], szHKBN[32], szBBKHN[32], szSBBK[32], szSBBA[32], szLN[32], szCN[32], szCU[32], szLGK[32], szOB[32],
	szPR[32], szRHN[32], szDUN[32], szOBWKN[32], szOSWKN[32], szFG[32],
	szM1[32], szM2[32], szM3[32], szM4[32]*/
	static szData3[9000], szAllItems3[9000]//, szData[9000], szAllItems[9000], szData2[9000], szAllItems2[9000], szAllItems4[9000], szData4[9000], szData5[9000], szData6[9000]
	get_user_name(id, Vault_Key, 63)
	replace_all(Vault_Key, 63, "'", "\'" )
	//nvault_get(g_save1, Vault_Key, szData, charsmax(szData))
	//nvault_get(g_save2, Vault_Key, szData2, charsmax(szData2))
	nvault_get(g_vault3, Vault_Key, szData3, charsmax(szData3))
	//nvault_get(g_save4, Vault_Key, szData6, charsmax(szData6))
	//strtok(szData, szData, sizeof(szData) - 1, szAllItems, sizeof(szAllItems) - 1, '#')
	//strtok(szData2, szData2, sizeof(szData2) - 1, szAllItems2, sizeof(szAllItems2) - 1, '#')
	strtok(szData3, szData3, sizeof(szData3) - 1, szAllItems3, sizeof(szAllItems3) - 1, '#')
	//strtok(szData6, szData6, sizeof(szData6) - 1, szAllItems4, sizeof(szAllItems4) - 1, '#')
	//parse(szData, szStatpoint, 31, szCrit, 31, szLucky, 31, szDamage, 31, szSpeed, 31, szHealth, 31, szLevel, 31, szMoney, 31, szLmoney, 31, szSmoney, 31, szRespawn, 31,
	//szOldplayer, 31, szTimeS, 31, szTimeM, 31, szTimeH, 31, szM1, 31, szM2, 31, szM3, 31, szM4, 31)
	//parse(szData2, szSBN, 31, szDWN, 31, szKON, 31, szHBK, 31, szMKN, 31, szSKN, 31, szGAKN, 31, szPKN, 31, szSAKN, 31, szKDN, 31, szData4, charsmax(szData4))
	//parse(szData4, szA1T, 31, szA2T, 31, szUM, 31, szHBH, 31, szKBN, 31, szKSBN, 31, szHKBN, 31, szBBKHN, 31, szSBBK, 31, szSBBA, 31, szData5, charsmax(szData5))
	//parse(szData5, szLN, 31, szCN, 31, szCU, 31, szLGK, 31, szOB, 31, szPR, 31, szRHN, 31, szDUN, 31, szOBWKN, 31, szOSWKN, 31)

	for(new up = 0;up < MAX_COUNT;up++)
	{
		strtok(szAllItems3, szClassLevel, sizeof(szClassLevel) - 1, szAllItems3, sizeof(szAllItems3) - 1, '#')
		strtok(szClassLevel, szUP, sizeof(szUP) - 1, szClassLevel, sizeof(szClassLevel) - 1, ' ')
		g_up[id][up] = str_to_num(szUP)
	}
}