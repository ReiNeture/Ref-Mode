#include <amxmodx>

new gKeysMainMenu;

native get_refknife(id);
native use_firestar(id);
native use_moonsword(id);
native use_enchant(id);
native use_moonbreak(id);
native use_chanmo(id);
native get_element_status(id);
native use_icewing(id);

enum
{
	N1, N2, N3, N4, N5, N6, N7, N8, N9, N0
};

enum
{
	B1 = 1 << N1, B2 = 1 << N2, B3 = 1 << N3, B4 = 1 << N4, B5 = 1 << N5,
	B6 = 1 << N6, B7 = 1 << N7, B8 = 1 << N8, B9 = 1 << N9, B0 = 1 << N0,
};

new akoMainMenu[256];

public plugin_init()
{
	register_plugin("kf", "1.0", "Ako");

	register_clcmd("kf", "showMenu");

	createMenu();

	register_menucmd(register_menuid("kfMainMenu"), gKeysMainMenu, "handleMainMenu");
}

createMenu()
{
	new size = sizeof(akoMainMenu);
	add(akoMainMenu, size, "\w大雞雞>< ^n^n");
	add(akoMainMenu, size, "\r1. \w雞雞刀 ^n");
	add(akoMainMenu, size, "\r2. \w附魔 ^n");
	add(akoMainMenu, size, "\r3. \w月光劍 ^n");
	add(akoMainMenu, size, "\r4. \w破月 ^n");
	add(akoMainMenu, size, "\r5. \w常魔紋 ^n");
	add(akoMainMenu, size, "\r6. \w冰風暴 ^n");
	add(akoMainMenu, size, "\r7. \w火流星 ^n");
	add(akoMainMenu, size, "\r8. \w一次施放 ^n^n^n");
	add(akoMainMenu, size, "\r0. \w關閉");
	gKeysMainMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B0
}

public showMenu(id)
{
	new menu[256];

	format(menu, 256, akoMainMenu);

	show_menu(id, gKeysMainMenu, menu, -1, "kfMainMenu");

	return PLUGIN_HANDLED;
}

public handleMainMenu(id, num)
{
	switch(num) {
		case N1: { get_refknife(id); }
		case N2: { use_enchant(id); }
		case N3: { use_moonsword(id); }
		case N4: { use_moonbreak(id); }
		case N5: { use_chanmo(id); }
		case N6: { use_icewing(id); }
		case N7: { use_firestar(id); }
		case N8: 
		{ 
			use_moonsword(id);
			use_moonbreak(id);
			use_chanmo(id);
			use_icewing(id);
			use_firestar(id);
		 }
		case N0: { return; }
	}

	if(num != N0)
		showMenu(id);
}