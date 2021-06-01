new semen[33][2] //0level 1exp
new porn[33][5] //0atk 1speed 2hp 3dodge 4point 5low damage
new g_damagedealt[33]
new spacespr
new bool:g_has_handjob[33]
new bool:space[33]
new g_vault,g_vault2
new material[33][24] //  0十字輪迴狙擊鏡 1準雷狙擊鏡 2十字輪迴架構 3準雷架構 4狙擊槍彈夾 5狙擊槍板機 6戰慄加農砲架構 7戰慄加農砲彈鼓 8散彈槍板機 9弓 10弦 11箭 12血滴子架構 13血滴子刀片 14血滴子手套 15催化劑 16淺見設計 17飛盤 18托斯魂 19幹你娘 20獨木舟設計圖 21主力艦設計圖 22航母設計圖 23吳
new combin_material[33][7] //1十字輪迴 2準雷 3戰慄加農砲 4蒼穹EX 5血滴子 6Thantatos11
new itemkey_temp[33]
new rein[33]   //投胎(轉生)
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
//------------------------------------aa10413
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
474000, 488000, 503000, 519000, 536000, 545000, 564000, 584000, 600000, 621000,
999999999
}
new const dildo_handjob_name[][] = { "", "MP5", "披玖陵", "XM1014", "FAMAS", "Galil", "M4A1", "AK47", "G3SG1", "M249" }
new const dildo_handjob_give[][] = { "", "weapon_mp5navy", "weapon_p90", "weapon_xm1014", "weapon_famas", "weapon_galil", "weapon_m4a1", "weapon_ak47", "weapon_g3sg1", "weapon_m249" }
new const dildo_handjob_level[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
new const material_count[][] = {{},{1,1,4,1,2907,1},{1,1,4,1,3555,1},{1,1,1,2999,1,0},{1,1,15,3759,0,1},{1,10,1,3598,1,0},{5,3,1,1,3751,0}}
new const material_synthesis[][] = {{},{0,2,4,5,15,20},{1,3,4,5,15,21},{6,7,8,15,22,23},{9,10,11,15,23,20},{12,13,14,15,21,23},{17,18,19,16,15,23}}
new const material_name[][] = {"離子推進器","慣性導引裝置","保險套", "二氯苯基胂", "燃氣渦輪機","碳鋼", "絕氣推進系統", "AGM-45百舌鳥飛彈","雷達預警接收器", "弓" ,"弦", "箭", "壓水反應爐", "抗腐蝕金屬", "高級矽膠", "催產劑","淺艦設計圖","鉛鉍共熔合金","磁性引信","幹你娘","R20設計圖",
"主力艦設計圖","航母設計圖","無"}
new const forge[][] = { "", "CV4760R", "準雷", "戰慄加農砲", "蒼穹EX", "血滴子","Thanatos11" }

new const normal_knife_name[][] = {"爪刀","刺刀","蒼藍碎牙", "普通的錘子"} //------------------------0725
new const normal_knife_damage[] = {0, 240, 280, 320, 400} //------------------------0725
new const normal_knife_count[] = {170, 350, 720, 9999999} //------------------------0725

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
/*new sound_eff[][] = 
{
	"Ako/hurt1.wav",
	"Ako/hurt2.wav",
	"Ako/boss_death.wav",
	"Ako/Human_Win1.wav",
	"Ako/Zombie_Win1.wav"
}*/
/*new BGM[][] =
{
	"Ako/bg1.mp3",
	"Ako/bg2.mp3",
	"Ako/bg3.mp3"
}
new BGM_TASK[] =
{
	196,
	130,
	185
}*/