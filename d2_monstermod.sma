#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <d2lod>

#define MONSTER_COUNT 33

new g_szMonsterNameList[MONSTER_COUNT][] =
{
	"蜜蜂手", "大媽(BOSS)",  "鱷魚(BOSS)", "外星首腦",
	"大藍(BOSS)", "食腦蟲", "百目狗", "弗地岡人",
	"聖甲蟲", "殭屍", "陸戰隊", "AH-64A 直昇機(BOSS)",
	"特務隊", "小食腦", "警察", "警長",
	"小灰(BOSS)", "魚龍", "水蛭", "鷹爪(BOSS)",
	"殭屍王(BOSS)", "特務隊", "范佐憲(軍官)", "突變食腦蟲",
 	"食腦王蟲", "鋼鐵鱷魚 (副本Boss)" , "暗黑大藍 (副本Boss)" , "藤壺怪" , "血腥鱷魚(突變BOSS)", "詭異的殭屍",
        "憤怒大媽(副本Boss)", "突變小灰(BOSS)" , "公務員" 	
}
new g_szMonsterModelList[MONSTER_COUNT][] =
{
	"agrunt", "big_mom",  "bullsquid", "controller",
	"garg", "headcrab", "houndeye", "islave",
	"w_squeak", "zombie", "hgrunt", "apache",
	"hassassin", "baby_headcrab" , "barney", "otis", 
	"babygarg", "icky", "leech", "tentacle2",
	"gonome", "massn", "gruntcmdr", "chick",
	"headcrabclassic", "iron_bullsquid", "dark_garg" , "barnacle", "bullsquid2", "ghost_zombie",
        "big_momX", "510", "gman"
}
new g_iMonsterExpList[MONSTER_COUNT] =
{
	700, 25000,  4250, 300,
	46000, 100, 350, 350,
	50, 270, 500, 30000,
	500, 10, 300, 300,
	18000, 700, 0, 30000,
	5400, 500, 400, 350,
	380, 16000, 60000, 380, 15000, 680,
        120000, 70000, 50
}
new g_iMonsterCoinsList[MONSTER_COUNT] =
{
	0, 900,  200, 25,
	2000, 8, 32, 28,
	1, 20, 0, 2000,
	20, 1, 0, 0,
	500, 50, 0, 1500,
	150, 0, 150, 0,
	50 , 1000,2000, 50, 500, 50,
        900, 900, 100
}
public plugin_init()
{
	register_plugin("Diablo II LOD 怪物補助插件", "1.0", "Lie")
	RegisterHam(Ham_Player_PreThink, "player", "fw_Monster_PreThink")
	RegisterHam(Ham_Killed, "func_wall", "fw_Monster_Killed")
	register_touch("CoinsMonster", "player", "fw_Touch")
	register_logevent("Event_Round_End", 2, "1=Round_End")
}
public Event_Round_End()
	Remove_All_Coin_Ents()

native get_my_team(id)
native get_team_leader(id)
native get_my_team2(id)
native Add_killnum(id)
native add_user_donate(id, num)
public fw_Monster_Killed(this, idattacker, shouldgib)
{
	if (!(1 <= idattacker <= get_maxplayers()) || !is_valid_ent(this) || !get_player_logged(idattacker))
		return HAM_IGNORED

	Add_killnum(idattacker)
	new szMonsterModel[33], szCheckModel[33]
	entity_get_string(this, EV_SZ_model, szMonsterModel, charsmax(szMonsterModel))
	for(new i = 0;i < MONSTER_COUNT;i++)
	{
		format(szCheckModel, sizeof(szCheckModel), "models/%s.mdl", g_szMonsterModelList[i])
		if(equal(szMonsterModel, szCheckModel))
		{
			if(g_iMonsterExpList[i] > 0)
			{
				add_user_donate(idattacker, g_iMonsterExpList[i])
				if(get_p_level(idattacker) <= 30)
				{
					if( get_user_flags(idattacker) & ADMIN_VIP_B )
					{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 3))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(30等以下+VIP 經驗三倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 3)
					}
					else
					{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 2))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(30等以下經驗二倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 2)
					}
				}
				else if ( get_user_flags(idattacker) & ADMIN_VIP_B )
				{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] + g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox")))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(VIP經驗2倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] + g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))
				}
				else
				{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox")))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))
				}
				if(get_p_level(idattacker) >= 150)
				{
					if( get_user_flags(idattacker) & ADMIN_VIP_B )
					{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 3))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(150等以上傳奇玩家+VIP 經驗三倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 3)
					}
					else
					{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 2))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(150等以上老練玩家 經驗二倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 2)
					}
				}
				if(get_p_level(idattacker) >= 200)
				{
					if( get_user_flags(idattacker) & ADMIN_VIP_B )
					{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 4))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(200等以上傳奇玩家+VIP 經驗四倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 4)
					}
					else
					{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 3))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(200等以上長期老練玩家 經驗三倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 3)
					}
				}
				if(get_p_level(idattacker) >= 220)
				{
					if( get_user_flags(idattacker) & ADMIN_VIP_B )
					{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 6))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(220等以上不朽傳奇+VIP 經驗六倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 6)
					}
					else
					{
					set_p_xp(idattacker, get_p_xp(idattacker) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 4))
					client_print(idattacker, print_center, "你殺了 %s, +%d經驗(220等以上不朽傳奇玩家 經驗四倍)", g_szMonsterNameList[i], g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox") * 4)
					}
			}



			}
			if(g_iMonsterCoinsList[i] > 0)
			{
				drop_coins(this, "CoinsMonster", random_num(0, g_iMonsterCoinsList[i]))
			}

			for(new player=1; player<=get_maxplayers(); player++)
			{
				if (get_my_team(player) && get_my_team(player) == get_my_team(idattacker))
				{
					if ( g_iMonsterExpList[i] > 0 && idattacker != player)
					{
						if(!get_my_team2(idattacker))
						{
							if(get_team_leader(player))
							{
								set_p_xp( player, get_p_xp(player) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))/2 );
								new random_coin = random_num(1,5)
								set_p_gold(player, get_p_gold(player) + random_coin)
								client_print( player, print_center, "隊伍經驗共享(普通隊長倍率1/2) +%d經驗 +%d金錢, ", (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))/2 , random_coin);
							}
							else
							{
								set_p_xp( player, get_p_xp(player) + (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))/10 );
								new random_coin = random_num(2,8)
								set_p_gold(player, get_p_gold(player) + random_coin)
								client_print( player, print_center, "隊伍經驗共享(普通隊員倍率1/10) +%d經驗 +%d金錢, ", (g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))/10 , random_coin);
							}
						}
						if(get_my_team2(idattacker))
						{
							if(get_team_leader(player))
							{
								set_p_xp( player, get_p_xp(player) + ((g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))/2)+100 );
								new random_coin = random_num(1,10)
								set_p_gold(player, get_p_gold(player) + random_coin)
								client_print( player, print_center, "隊伍經驗共享(高級隊長倍率1/2 +100) +%d經驗 +%d金錢, ", ((g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))/2) +100 , random_coin);
							}
							else
							{
								set_p_xp( player, get_p_xp(player) + ((g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))/5)+50 );
								new random_coin = random_num(1,12)
								set_p_gold(player, get_p_gold(player) + random_coin)
								client_print( player, print_center, "隊伍經驗共享(高級隊員倍率1/5 +50) +%d經驗 +%d金錢, ", ((g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))/5)+50 , random_coin);
							}
						}
					}
				}
			}

		}
	}
	return HAM_IGNORED
}
public fw_Monster_PreThink(this, idattacker)
{
	if(!is_valid_ent(this))
		return HAM_IGNORED

	new iTarget, iTemp, szMonsterModel[33], szCheckModel[33], szClassname[33]
	get_user_aiming(this, iTarget, iTemp)
	entity_get_string(iTarget, EV_SZ_model, szMonsterModel, sizeof(szMonsterModel))
	entity_get_string(iTarget, EV_SZ_classname, szClassname, sizeof(szClassname))
	for(new i = 0;i < MONSTER_COUNT;i++)
	{
		format(szCheckModel, sizeof(szCheckModel), "models/%s.mdl", g_szMonsterModelList[i])
		if(equal(szClassname, "func_wall"))
		{
			if(equal(szMonsterModel, szCheckModel))
			{
				if(g_iMonsterExpList[i] > 0)
				{
					set_hudmessage(0, 191, 255, 0.10, 0.55, 0, 0.2, 0.4, 0.1, 0.1, 3)
					show_hudmessage(this, "怪物: %s^n血量: %d^n經驗: %d", g_szMonsterNameList[i], floatround(entity_get_float(iTarget, EV_FL_health)), g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))
				}
				else
				{
					set_hudmessage(0, 191, 255, 0.10, 0.55, 0, 0.2, 0.4, 0.1, 0.1, 3)
					show_hudmessage(this, "怪物: %s^n血量: %d^n經驗: %d", g_szMonsterNameList[i], floatround(entity_get_float(iTarget, EV_FL_health)), g_iMonsterExpList[i] * get_cvar_num("d2_exp_ox"))
				}
				break
			}
		}
	}
	return HAM_HANDLED
}
public fw_Touch(ptr, ptd)
{
	if(is_user_alive(ptd) && pev_valid(ptr))
	{
		set_p_gold(ptd, get_p_gold(ptd) + entity_get_int(ptr, EV_INT_iuser1))
		client_printcolor(ptd, "/g[私の絶対領域: 你撿到了 /ctr%d /g金錢]", entity_get_int(ptr, EV_INT_iuser1))
		remove_entity(ptr)
	}
}
public Remove_All_Coin_Ents()
{
	new coin_ent = find_ent_by_class(-1, "CoinsMonster")
	while(coin_ent)
	{
		remove_entity(coin_ent)
		coin_ent = find_ent_by_class(coin_ent, "CoinsMonster")
	}
}