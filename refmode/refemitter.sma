#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

new const szHegrenadeModel[] = "models/w_hegrenade.mdl";

public plugin_init()
{
    register_plugin("Grenade Emitter", "1.0", "Reff");
    register_clcmd("r_emit", "fireEmitter");
}

public fireEmitter(id)
{
    static entity;
    entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target") );
    if (!pev_valid(entity) ) return;

    engfunc(EngFunc_SetModel, entity, szHegrenadeModel);
}