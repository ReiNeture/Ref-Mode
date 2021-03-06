#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>

const MAX_ITEM = 10;

new const ItemName[MAX_ITEM][] = 
{
    "炫光雞雞",
    "彩色雞雞",
    "無垢雞雞",
    "無料雞雞",
    "有料雞雞",
    "黑色雞雞",
    "紅色雞雞",
    "白色雞雞",
    "藍色雞雞",
    "綠色雞雞"
}
new itemData[33][MAX_ITEM];


public plugin_init()
{
    register_plugin("tests", "1.0", "Ako");

    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

    register_clcmd("te", "showItemMenu");
    register_clcmd("te2", "gitem");
}

public gitem(id)
{
    for(new i = 0; i < MAX_ITEM; ++i)
        itemData[id][i]++;
}

public showItemMenu(id)
{
    new Info[64];
    formatex(Info, sizeof(Info), "\w我的背包");
    new itemMenu = menu_create(Info, "handleItemMenu");

    new szTempid[32];
    new item;

    for(new i = 0; i < MAX_ITEM; i++) {
        if(itemData[id][i] > 0) {
            item = itemData[id][i];
            num_to_str(i, szTempid, 31);

            menu_additem(itemMenu, ItemName[i], szTempid, 0);
        }
    }

    if(item <= 0)
        menu_additem(itemMenu, "\w--", "雞雞", 0);

    menu_setprop(itemMenu, MPROP_EXIT, MEXIT_ALL);

    menu_display(id, itemMenu, 0);

    return PLUGIN_HANDLED;
}

public handleItemMenu(id, itemMenu, item)
{
    if(item == MENU_EXIT) {
        menu_destroy(itemMenu);
        return PLUGIN_HANDLED;
    }
    
    showItemMenu(id);

    menu_destroy(itemMenu);
    return PLUGIN_HANDLED;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
    if(attacker == victim || !is_user_connected(attacker)) return HAM_IGNORED;

    new randomItem = random(MAX_ITEM);

    if(random_num(1, 2) == 1 && get_user_team(victim) == 2) {
        client_printcolor(attacker, "/g[掉落]/ctr你擊殺敵人獲得了/y[%s]", ItemName[randomItem]);
        itemData[attacker][randomItem]++;
        return HAM_HANDLED;
    }

    return HAM_IGNORED;
}

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