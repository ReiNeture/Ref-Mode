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

enum {
    LEVEL,
    EXP
}

public plugin_init(){
    register_plugin("reflevel", "Ako", "1.0");

    //register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1);

    register_concmd("restd", "restData");
    register_concmd("exp", "setExp");

    register_cvar("refExpRate", "1");

    sync = CreateHudSyncObj();
    vault = nvault_open("reflevel");
}

public client_putinserver(id)
{
    if(!is_user_bot(id)) {
        LoadData(id);
        show_hud(id+1234);
        set_task(120.0, "AutoSave", id, _, _, "b");
    }

}

public client_disconnect(id)
{
    if(!is_user_bot(id)) {
        SaveData(id);
    }
}

public show_hud(id)
{
    id -= 1234;
    static red = 0;
    static green = 255;
    static blue = 255;

    set_hudmessage(red, green, blue, -0.85, 0.15, 0, 0.0, 0.3, 0.0, 0.0, -1);
    ShowSyncHudMsg(id, sync, "|炫光彩色雞雞|^n|血量: %d|^n|等級: %d|^n|經驗: %d / %d|^n|經驗倍率: %d|^n|擊殺數: %d|", get_user_health(id), reflevel[id][LEVEL], reflevel[id][EXP], reflevel[id][LEVEL] * y14y, get_cvar_num("refExpRate"), refzmkill[id]);
    set_task(0.2, "show_hud", id+1234);
}

SaveData(id)
{
    
    new name[32], vaultKey[64], vaultData[64];

    get_user_name(id, name, 31);

    format(vaultKey, 63, "%s", name);
    format(vaultData, 255, "%i#%i#%i#", reflevel[id][LEVEL], reflevel[id][EXP], refzmkill[id]);

    nvault_set(vault, vaultKey, vaultData);
}

LoadData(id)
{

    new name[32], vaultKey[64], vaultData[64];

    get_user_name(id, name, 31);

    format(vaultKey, 63, "%s", name);
    format(vaultData, 255, "%i#%i#%i#", reflevel[id][LEVEL], reflevel[id][EXP], refzmkill[id]);

    nvault_get(vault, vaultKey, vaultData, 255);

    replace_all(vaultData, 255, "#", " ");

    new lvl[32], exp[32], kill[32];

    parse(vaultData, lvl, 31, exp, 31, kill, 31);

    reflevel[id][LEVEL] = str_to_num(lvl);
    reflevel[id][EXP] = str_to_num(exp);
    refzmkill[id] = str_to_num(kill);

}

public AutoSave(id)
{
    SaveData(id);
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
    if(attacker == victim || !is_user_alive(attacker))
        return HAM_IGNORED;

    if(reflevel[attacker][LEVEL] <= 0)
        reflevel[attacker][LEVEL] = 1;

    if(get_user_team(victim) == 2){
        reflevel[attacker][EXP] += 1000 * get_cvar_num("refExpRate");
        refzmkill[attacker]++;
    }

    new refexp = reflevel[attacker][LEVEL] * y14y;
    if(reflevel[attacker][EXP] >= refexp) {
        reflevel[attacker][EXP] -= refexp;
        reflevel[attacker][LEVEL]++;
    }

    refexp = reflevel[attacker][LEVEL] * y14y;
    if(reflevel[attacker][EXP] >= refexp) {
        reflevel[attacker][EXP] = refexp-1;
    }

    return HAM_IGNORED;
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