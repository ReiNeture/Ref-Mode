new semen[33][2] //0level 1exp
new porn[33][5] //0atk 1speed 2hp 3dodge 4point 5low damage
new g_damagedealt[33]
new spacespr
new bool:g_has_handjob[33]
new bool:space[33]
new g_vault,g_vault2,g_vault3
new material[33][24] //  0十字輪迴狙擊鏡 1準雷狙擊鏡 2十字輪迴架構 3準雷架構 4狙擊槍彈夾 5狙擊槍板機 6戰慄加農砲架構 7戰慄加農砲彈鼓 8散彈槍板機 9弓 10弦 11箭 12血滴子架構 13血滴子刀片 14血滴子手套 15催化劑 16淺見設計 17飛盤 18托斯魂 19幹你娘 20獨木舟設計圖 21主力艦設計圖 22航母設計圖 23吳
new combin_material[33][7] //1十字輪迴 2準雷 3戰慄加農砲 4蒼穹EX 5血滴子 6Thantatos11
new itemkey_temp[33]
new rein[33]   //投胎(轉生)
new exp,smoke //瀕死特效
new left_time //瀕死剩餘時間
new bool:cannon_mode[33] //主砲模式
new bool:cannon_mode_temp[33]
new bool:ssssssss //流程控制
//-------------0725
new norkf[33][4], kfmod[33] //普通刀儲存變數 後者為 所選的刀子(不存)
new g_money[33]
new temp_damage[33]
//------------------------------------aa10413
new g_iLastTerr;
new bool:have_boss = false
new bool:un_spawn = false
new g_isBoss[33]
new g_beacon
new g_FirstRound
new game_level
new const boss_level[] = { 10000, 30000, 60000, 90000, 120000, 140000, 200000, 270000, 450000 }
//------------------------------------aa10413
//------------------------------------bgmm
new boss_mana[33]
new bool:skill_ed[33] //吸收傷害
new bool:skill_cn[33] //牽引繩
new beam, bool:skill_cn_public
//------------------------------------bgmm

new const dildo[] = {
100, 400, 700, 1200, 1300, 2000, 3000, 3200, 3500, 6000,
6400, 6800, 7200, 10000, 10500, 12000, 13000, 17000, 18000, 20000,
8900, 9500, 11000, 11750, 14750, 15900, 18000, 25000, 26000, 26000,
26000, 40000, 44000, 48000, 50000, 51000, 53000, 60000, 66666, 69999,
70000, 99999, 99999, 99999, 99999, 110000, 120000, 127000, 130000, 140000,
145000, 147000, 167000, 170000, 177777, 188888, 200000, 210000, 220000, 225000,
230000, 233333, 256789, 260000, 266666, 300000, 300000, 300000, 307777, 317777,
320000, 325000, 330000, 333333, 350000, 358000, 360000, 360000, 370000, 377777,
400000, 400000, 410000, 415000, 421000, 428000, 436000, 445000, 450000, 461000,
474000, 488000, 503000, 519000, 536000, 545000, 564000, 584000, 660000, 671000,
999999999
} //{0 ,1 ,4 ,5 ,7 ,8 ,11, 13, 14, 17, 18} //Low new const temp_arr[] = {2,3,6,9,10,12,19}//High
new const dildo_handjob_name[][] = { "", "MP5", "披玖陵", "XM1014", "FAMAS", "Galil", "M4A1", "AK47", "G3SG1", "M249" }
new const dildo_handjob_give[][] = { "", "weapon_mp5navy", "weapon_p90", "weapon_xm1014", "weapon_famas", "weapon_galil", "weapon_m4a1", "weapon_ak47", "weapon_g3sg1", "weapon_m249" }
new const dildo_handjob_level[] = { 0, 0, 1, 2, 3, 4, 5, 6, 7, 8 }
new const material_count[][] = {{},{4,10,3,3,4407,1},{3,12,2,1,4677,20},{10,3,3,4567,1,0},{10,2,4,4759,1,0},{8,4,5,4999,1,0},{3,3,9,1,5111,0}}
new const material_synthesis[][] = {{},{0,2,4,5,15,20},{1,3,4,5,15,21},{6,7,8,15,22,23},{9,10,11,15,20,23},{12,13,14,15,21,23},{17,18,19,16,15,23}}
new const material_name[][] = {"離子推進器","慣性導引裝置","保險套", "二氯苯基胂", "燃氣渦輪機","碳鋼", "絕氣推進系統", "AGM-45百舌鳥飛彈","雷達預警接收器", "堅韌的竹" ,"大麻葉繩", "義大利火雞羽毛", "稀土金屬", "抗腐蝕金屬", "難熔金屬", "塑化劑","淺艦設計圖","鉛鉍共熔合金","磁性引信","過度金屬","R20設計圖",
"主力艦設計圖","航母設計圖","無"} //暫存材料108 = 23
new const forge[][] = { "", "樂高玩具", "Thanatos-7", "CV4760R", "蒼穹EX", "舖拉斯馬槓","PSG-1" }

new const normal_knife_name[][] = {"爪刀","刺刀","蒼藍碎牙", "普通的錘子"} //------------------------0725
new const normal_knife_damage[] = {0, 7, 15, 25, 40} //------------------------0725
new const normal_knife_count[] = {170, 250, 350, 500} //------------------------0725
new g_fwPrecacheSound
new bool:ewowe = false
new bool:bug_fix
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
new sound_eff[][] = 
{
	"Ako/hurt1.wav",
	"Ako/hurt2.wav",
	"Ako/boss_death.wav",
	"Ako/Human_Win1.wav",
	"Ako/Zombie_Win1.wav"
}
new BGM[][] =
{
	"Ako/bg1.mp3",
	"Ako/bg2.mp3",
	"Ako/bg3.mp3"
}
new BGM_TASK[] =
{
	107,
	101,
	346
}
enum _:MAX_COUNT
{
	ED_DAMAGE_25000,
	HIGH_PING_1000,
	BIG_DICK_30,
	PM_KILL_543,
	REIN_COUNT_10,
	KNIFE_KILL_1HP,
	MP5_KILL,
	SP_12345,
	CAT_9999,
	EXP_REIN_1234567,
	I_AM_30CM,
	BUY_LOLI,
	ON_BOSS_10,
	ED_DAMAGE_0000,
	ED_DAMAGE_444,
	PLAY_ROUND_100,
	PLAY_ROUND_200,
	PLAY_ROUND_300,
	P90_KILL,
	AK47_KILL,
	XM1014_KILL,
	FAMAS_KILL,
	SO_LONG,
	ROUND_SP_200,
	ROUND_SP_500,
	ROUND_SP_800,
	MAP_KILLMYSELF_3,
	IN_SKY_KILL,
	ALIVE_1HP,
	ALIVE_150HP_ABOVE,
	ALIVE_44HP,
	ALIVE_15HP_FOLLOWING,
	ATTACK_TEAMMATE_ATTACK1,
	ATTACK_TEAMMATE_ATTACK2,
	IN_DARK_ALIVE,
	TAKE_KNIFE_KILL,
	BUY_SPACE_2,
	BUY_SPACE_20,
	LAST_BULLET_KILL,
	MANA_100,
	MANA_NOT_60,
	ROUND_START_5S,
	NO_SWITCH_GUN,
	ACC_DAMAGE_150000,
	ACC_DAMAGE_350000,
	ACC_DAMAGE_800000,
	GET_BOUNS_200,
	KILL_VI,
	KILL_VII,
	KILL_X,
	CANNON_ATTACK_5
}
new const ach_name[MAX_COUNT][] = 
{
	"單次吸收25000傷害以上",
	"Ping值達到1000",
	"是一名甲甲",
	"在下午5點67分獵殺花豹",
	"投胎10次",
	"1HP拿刀獵殺花豹",
	"使用MP5獵殺花豹",
	"擁有12345個SP",
	"擁有9999個塑化劑",
	"超過1234567經驗再投胎",
	"先把雞雞長度點滿",
	"購買現實蘿莉",
	"在花豹頭上10秒",//12
	"單次吸收0傷害",
	"單次吸收444傷害",
	"進行100回合",
	"進行200回合",
	"進行300回合",
	"使用P90獵殺花豹",
	"使用AK47獵殺花豹",
	"使用XM1014獵殺花豹", //20
	"使用FAMAS獵殺花豹",
	"按Y輸入火山矽肺症英文全名",
	"一回合獲得200SP",
	"一回合獲得500SP",
	"一回合獲得800SP",
	"一張地圖內自殺3次",
	"在空中時獵殺花豹",
	"1HP存活",
	"150HP以上存活",
	"44HP存活", //30
	"15HP以下存活",
	"拿刀輕砍隊友500下",
	"拿刀重砍隊友300下",
	"夜戰時不購買夜視鏡並存活", //34
	"拿刀獵殺花豹",
	"一張地圖購買2次衝擊結界",
	"一張地圖購買20次衝擊結界",
	"用最後一發子彈獵殺花豹",
	"成為花豹時魔力達到100",
	"成為花豹時一回合魔力不超過60", //40
	"開場5秒內攻擊到花豹",
	"整個回合都沒有選槍", //42
	"一張地圖累積傷害達到150000",
	"一張地圖累積傷害達到350000",
	"一張地圖累積傷害達到800000",
	"寶物獵人",
	"獵殺階級VI的花豹", //47
	"獵殺階級VII的花豹",
	"獵殺階級X的花豹",
	"承受5次動保協會的憤怒攻擊"   //50
}
//------------------------------------Ach
new g_up[33][MAX_COUNT]
new g_menupos[33]
new g_UPNum
new g_mileage[33]
new skill_ed_get[33], big_dick_count[33], g_on_boss[33]
new float:g_on_boss_cd[33]
new g_play_round[33] //save
new have_sp[33]
new selfkill_count[33]
new g_attack1_teammate[33], g_attack2_teammate[33]
new bool:in_dark
new bool:buy_night[33]
new buy_space[33]
new bool:mana_limit[33]
new bool:round_start_takedamage
new acc_damage[33]
new get_bouns[33] //save
new cannon_victim[33]
new omg_bug
//------------------------------------Ach
/*
	new iNum, iPlayers[32]
	get_players(iPlayers, iNum, "c")
	for (new i = 0;i < iNum;i++){
		if ( iPlayers[i] != id )
	}
*/