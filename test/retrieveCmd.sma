#include <amxmodx>
#include <amxmisc>

public plugin_init()
{
    register_plugin("UAU", "1.0", "Reff");
    register_clcmd("viewcmd", "displayAllCommand");
    register_clcmd("viewclc", "displayAllClcmd");
}

public displayAllCommand(id)
{
    new PluginState[32];
    new PluginName[64];
    new Command[64];
	new CommandAccess;

    for (new i=0, max=get_pluginsnum(); i<max; i++) {
        get_plugin(i,"",0,PluginName,charsmax(PluginName),"",0,"",0,PluginState,charsmax(PluginState));    
        client_print(id, print_chat, "%d. %s^n", i, PluginName);

        for (new c=0, max2=get_concmdsnum(-1,-1); c<max2; c++) {
            if (get_concmd_plid(c,-1,-1) == i) {
                get_concmd(c,Command,charsmax(Command),CommandAccess, "",0, -1, -1);
                client_print(id, print_chat, "%s^n", i, Command);
            }
        }
        client_print(id, print_chat, "%s^n", "====================================");
    }

}

public displayAllClcmd(id)
{
    new command[64], info[64];
    new flag;

    for (new i=0, max=get_clcmdsnum(-1); i<max; ++i) {
        get_clcmd(i, command, sizeof(command), flag, info, sizeof(info), -1);
        client_print(id, print_console, "%s", command);
    }
}