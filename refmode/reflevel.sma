#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>

new reflevel[33][2];
new refzmkill[33];
new const y14y = 100
new sync;
new vault;
new bool:havedLoad[33];

new sz_time[22]

enum {
    LEVEL,
    EXP
}

public plugin_init(){
    register_plugin("reflevel", "Ako", "1.0");

    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1);

    register_concmd("restd", "restData");
    register_concmd("exp", "setExp");

    register_cvar("refExpRate", "2");

    sync = CreateHudSyncObj();
    vault = nvault_open("reflevel");
    set_task(30.0, "AutoSave", _, _, _, "b");
}

public plugin_natives()
{
	register_native("ref_get_level", "native_ref_get_level", 1);
}
public native_ref_get_level(id)
{
    return reflevel[id][LEVEL];
}

public client_connect(id)
{
    if( is_user_bot(id) ) return PLUGIN_CONTINUE;
    
    havedLoad[id] = false;
    LoadData(id);

    return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
    if(!is_user_bot(id) ) {
        set_task(0.2, "show_hud", id+1234);
    }

}

public client_disconnected(id)
{
    if(!is_user_bot(id) && havedLoad[id]) {
        SaveData(id);
        remove_task(id+1234);
    }
}

public show_hud(id)
{
    id -= 1234;
    if( !is_user_connected(id)) {
        remove_task(id+1234);
        return PLUGIN_HANDLED;
    }

    static red = 0;
    static green = 255;
    static blue = 255;

    set_hudmessage(red, green, blue, -0.85, 0.15, 0, 0.0, 0.3, 0.0, 0.0, -1);
    ShowSyncHudMsg(id, sync, "|血量: %d|^n|等級: %d|^n|經驗: %d / %d|^n|經驗倍率: %d|^n|Aqua Point: %d|", get_user_health(id), reflevel[id][LEVEL], reflevel[id][EXP], reflevel[id][LEVEL] * y14y, get_cvar_num("refExpRate"), refzmkill[id]);
    set_task(0.2, "show_hud", id+1234);

    return PLUGIN_HANDLED;
}

SaveData(id)
{
    get_time("%m/%d/%Y - %H:%M:%S", sz_time, charsmax(sz_time));
    client_print(id, print_console, "L %s : AUTOMATIC SAVE DATA #--", sz_time);

    new name[32], vaultKey[64], vaultData[256];

    get_user_name(id, name, 31);

    format(vaultKey, 63, "%s", name);
    format(vaultData, 255, "%i#%i#%i#", reflevel[id][LEVEL], reflevel[id][EXP], refzmkill[id]);

    nvault_set(vault, vaultKey, vaultData);
}

public LoadData(id)
{
    client_print(id, print_console, "load data.");
    new name[32], vaultKey[64], vaultData[256];

    get_user_name(id, name, 31);

    format(vaultKey, 63, "%s", name);
    // format(vaultData, 255, "%i#%i#%i#", reflevel[id][LEVEL], reflevel[id][EXP], refzmkill[id]);

    nvault_get(vault, vaultKey, vaultData, 255);

    replace_all(vaultData, 255, "#", " ");

    new lvl[32], exp[32], kill[32];

    parse(vaultData, lvl, 31, exp, 31, kill, 31);

    reflevel[id][LEVEL] = str_to_num(lvl);
    reflevel[id][EXP] = str_to_num(exp);
    refzmkill[id] = str_to_num(kill);

    havedLoad[id] = true;
}

public AutoSave()
{
    new i, iPlayers[32], iNum;
    get_players(iPlayers, iNum, "c");

    if (iNum >= 1)
    {
    	for (i = 0;i < iNum;i++)
    	{
    		if (is_user_connected(iPlayers[i]))
    		{
                SaveData(iPlayers[i]);
    		}
    	}
    }
    
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
    if(attacker == victim || !is_user_alive(attacker))
        return HAM_IGNORED;

    if(reflevel[attacker][LEVEL] <= 0)
        reflevel[attacker][LEVEL] = 1;

    new exp = 777 * get_cvar_num("refExpRate");

    if( reflevel[attacker][LEVEL] < 100 ) {
        exp *= 10;
        client_print(attacker, print_center, "擊殺了 怪人 獲得 %d 經驗值 (100等以下經驗值10倍)", exp);
    } else
        client_print(attacker, print_center, "擊殺了 怪人 獲得 %d 經驗值", exp);

    if(get_user_team(victim) == 2){
        reflevel[attacker][EXP] += exp
        refzmkill[attacker]++;
    }

    new refexp = reflevel[attacker][LEVEL] * y14y;
    while(reflevel[attacker][EXP] >= refexp) {
        reflevel[attacker][EXP] -= refexp;
        reflevel[attacker][LEVEL]++;
        refexp = reflevel[attacker][LEVEL] * y14y;
    }

    // refexp = reflevel[attacker][LEVEL] * y14y;
    // if(reflevel[attacker][EXP] >= refexp) {
    //     reflevel[attacker][EXP] = refexp-1;
    // }

    return HAM_HANDLED;
}

public restData(id)
{
    new Target[64], Target_Name[64];
    read_argv(1, Target, 63);
    
    if(!cmd_target(id, Target))
        return PLUGIN_HANDLED;

    get_user_name(cmd_target(id, Target), Target_Name, 63);
    reflevel[cmd_target(id, Target)][LEVEL] = 0;
    reflevel[cmd_target(id, Target)][EXP] = 0;
    refzmkill[cmd_target(id, Target)] = 0;
    return PLUGIN_HANDLED;
}

public setExp(id)
{
    new Target[64], Target_Name[64], Type[64], Value[64];
    read_argv(1, Target, 63);
    read_argv(2, Type, 63);
    read_argv(3, Value, 63);

    if(!cmd_target(id, Target))
        return PLUGIN_HANDLED;
    
    get_user_name(cmd_target(id, Target), Target_Name, 63);
    if(Type[0] == '+')
        reflevel[cmd_target(id, Target)][EXP] += str_to_num(Value);
    else if(Type[0] == '=')
        reflevel[cmd_target(id, Target)][EXP] = str_to_num(Value);
    return PLUGIN_HANDLED;
}

public plugin_end()
{
    nvault_close(vault);
}