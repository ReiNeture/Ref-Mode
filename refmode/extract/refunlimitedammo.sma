#include <amxmodx>
#include <fakemeta>

new const OFFSET_AMMO[31] =  // bpammo
{
	0, 385, 0, 378, 0, 381, 0, 382, 380, 0, 386, 383, 382, 380, 380, 380, 382, 386, 377, 386, 379, 381, 380, 386, 378, 0, 384, 380, 378, 0, 383
}

public plugin_init()
{
    register_plugin("無限備彈", "1.0", "Reff")
    register_event("CurWeapon", "event_curweapon", "be", "1=1")
}

public event_curweapon(id)
{
	if( !is_user_alive(id) )
        return PLUGIN_CONTINUE
        
	new weaponID= read_data(2)
	if(weaponID==CSW_C4 || weaponID==CSW_KNIFE || weaponID==CSW_HEGRENADE || weaponID==CSW_SMOKEGRENADE || weaponID==CSW_FLASHBANG)
		return PLUGIN_CONTINUE

	set_pdata_int(id, OFFSET_AMMO[weaponID], 120, 5)
	return PLUGIN_CONTINUE
}