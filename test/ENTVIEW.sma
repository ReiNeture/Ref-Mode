#include <amxmodx>
#include <fakemeta>
#include <engine>

#define PLUGIN_NAME "Ent view"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Re"

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
}
public fw_PlayerPreThink(id)
{
        if (!is_user_alive(id))
		return;

	static target, body
	get_user_aiming(id, target, body)

	if (pev_valid(target))
	{
		new szName[32]
		entity_get_string(target, EV_SZ_classname, szName, 31)
		//native entity_get_string(iIndex, iKey, szReturn[], iRetLen)

		client_print(id, print_center, "%s", szName)
		
		if ( equal(szName ,"grenade") )
			remove_entity(target)
	}
}