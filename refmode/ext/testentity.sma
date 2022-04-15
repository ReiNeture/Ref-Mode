#include <amxmodx>
#include <fakemeta>
#include <xs>

public plugin_init()
{
	register_plugin("Test Entity Model", "1.0", "Reff")
    register_forward(FM_Think, "fw_Think")
	register_clcmd("summon", "summon_entity")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, "models/ref/element.mdl")
}

public summon_entity(id)
{
	new Float:circle_origin[3]

	new circle = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(circle, pev_movetype, MOVETYPE_NONE)
	set_pev(circle, pev_owner, id)
	set_pev(circle, pev_classname, "ball")
	set_pev(circle, pev_solid, SOLID_NOT)
    set_pev(circle, pev_aiment, id)
    set_pev(circle, pev_animtime, get_gametime())
    set_pev(circle, pev_framerate, 1.0)

    pev(id, pev_origin, circle_origin)
    circle_origin[2] -= 20.0
	set_pev(circle, pev_origin, circle_origin)
	engfunc(EngFunc_SetModel, circle, "models/ref/element.mdl")
    set_pev(circle, pev_nextthink, get_gametime() + 1.0)
}

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED

	static classname[32]
	pev(ent, pev_classname, classname, sizeof(classname))

	if( equal(classname, "ball") ) {
        set_pev(ent, pev_animtime, get_gametime())
        set_pev(ent, pev_nextthink, get_gametime() + 1.0)
	}
	return FMRES_IGNORED
}