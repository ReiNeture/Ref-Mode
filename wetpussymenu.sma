#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
#include <fakemeta>

new gKeysMainMenu;
enum
{
	N1, N2, N3, N4, N5, N6, N7, N8, N9, N0
};

enum
{
	B1 = 1 << N1, B2 = 1 << N2, B3 = 1 << N3, B4 = 1 << N4, B5 = 1 << N5,
	B6 = 1 << N6, B7 = 1 << N7, B8 = 1 << N8, B9 = 1 << N9, B0 = 1 << N0,
};
new gszMainMenu[200];
public plugin_init()
{
	register_plugin("武器", "1.0", "Hua");
	register_clcmd("wpmenu", "showMenu");
	createMenu();
	register_menucmd(register_menuid("wpmenuMainMenu"), gKeysMainMenu, "handleMainMenu");
}

createMenu()
{
	//main
	new size = sizeof(gszMainMenu);
	add(gszMainMenu, size, "\w武器選單 ^n^n");
	add(gszMainMenu, size, "\r1. \wAK-47 %s ^n");
	add(gszMainMenu, size, "\r2. \wM4A1 %s ^n");
	add(gszMainMenu, size, "\r3. \wMP5 %s ^n");
	add(gszMainMenu, size, "\r4. \w夜鷹 %s ^n");
	add(gszMainMenu, size, "\r5. \wUSP %s ^n");
	add(gszMainMenu, size, "\r6. \wFAMAS %s ^n");
	add(gszMainMenu, size, "\r7. \wM249 %s ^n");
	add(gszMainMenu, size, "\r8. \wAUG %s ^n");
	add(gszMainMenu, size, "\r9. \w下一頁 %s ^n");
	add(gszMainMenu, size, "\r0. \wclose %s ^n");
	gKeysMainMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B0;


}

public showMenu(id){
	new menu[200];
	format(menu, sizeof(menu), gszMainMenu, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0);
	show_menu(id, gKeysMainMenu, menu, -1, "wpmenuMainMenu");
	return PLUGIN_HANDLED;
}



public handleMainMenu(id, num){
	switch(num){
	case N1: { give_item(id,"weapon_ak47") 
			cs_set_user_bpammo(id,CSW_AK47,255);}
	case N2: { give_item(id,"weapon_m4a1") 
			cs_set_user_bpammo(id,CSW_M4A1,255);}
	case N3: { give_item(id,"weapon_mp5navy")
			cs_set_user_bpammo(id,CSW_MP5NAVY,255);}
	case N4: { give_item(id,"weapon_deagle")
			cs_set_user_bpammo(id,CSW_DEAGLE,255);}
	case N5: { give_item(id,"weapon_usp") 
			cs_set_user_bpammo(id,CSW_USP,255);}
	case N6: { give_item(id,"weapon_famas") 
			cs_set_user_bpammo(id,CSW_FAMAS,120);}
	case N7: { give_item(id,"weapon_m249")
			cs_set_user_bpammo(id,CSW_M249,255);}
	case N8: { give_item(id,"weapon_aug")
			cs_set_user_bpammo(id,CSW_AUG,255);}
	case N0: { menu_destroy(gKeysMainMenu); }
	}
}