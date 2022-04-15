#include <amxmodx>
#include <fakemeta>

public plugin_init()
{
	register_plugin("即時清除掉落物", "1.0", "Reff")
	register_forward(FM_SetModel, "SetModel_Post", 1)
}

public SetModel_Post(entity, const model[])
{
	if (!pev_valid(entity) ) return FMRES_IGNORED

	new classname[32];
	pev(entity, pev_classname, classname, charsmax(classname))

	if (equal(classname, "weaponbox"))
		set_pev(entity, pev_nextthink, get_gametime())

	return FMRES_HANDLED
} 