#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <vector>

new const hachamaModel[] = "models/ref/devil.mdl";
new const hachamaClassName[] = "ref_hachama";

public plugin_init()
{
    register_plugin("Ref Npc", "1.0", "Reff");
    register_clcmd("hacha", "createHachama");

    register_think(hachamaClassName, "hachamaThink");
    RegisterHam(Ham_TakeDamage, "info_target", "hachama_TakeDamage", 1);
}

public plugin_precache()
{
    precache_model(hachamaModel);
}

public hachama_TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if( !is_valid_ent(this) ) return HAM_IGNORED;

	static className[32];
	pev(this, pev_classname, className, charsmax(className));

	if(equali(className, hachamaClassName) ) {
        client_print(idattacker, print_chat, "%d", pev(this, pev_health));
    }

    return HAM_IGNORED;
}

public createHachama(id)
{
    new entity;
    entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(entity) ) return;

    new Float:vOrigin[3];
    pev(id, pev_origin, vOrigin);
    vOrigin[1] += 50.0;

    set_pev(entity, pev_classname, hachamaClassName);
    set_pev(entity, pev_movetype, MOVETYPE_PUSHSTEP);
    set_pev(entity, pev_solid, SOLID_BBOX);

    set_pev(entity, pev_takedamage, DAMAGE_YES);
    set_pev(entity, pev_health, 500.0);

    set_pev(entity, pev_sequence, 0);
    set_pev(entity, pev_framerate, 1.2);
    set_pev(entity, pev_animtime, 1.0);

    engfunc(EngFunc_SetModel, entity, hachamaModel);
    engfunc(EngFunc_SetSize, entity, Float:{-15.0, -15.0, -35.0}, Float:{15.0, 15.0, 35.0} );
    engfunc(EngFunc_SetOrigin, entity, vOrigin);

    drop_to_floor(entity);
    set_pev(entity, pev_nextthink, halflife_time() + 3.0);
}

public hachamaThink(entity)
{
    static Float:playerOrigin[3], Float:entityOrigin[3], Float:velocity[3];

    new player = findNearPlayers(entity);

    pev(player, pev_origin, playerOrigin);
    pev(entity, pev_origin, entityOrigin);

    get_speed_vector(entityOrigin, playerOrigin, 100.0, velocity);

    set_pev(entity, pev_velocity, velocity);
    velocity[2] = 0.0;

    set_pev(entity, pev_nextthink, halflife_time() + 0.1);
}

findNearPlayers(id)
{
	new near = 0;
	new Float:minDistance = 99999.9;

	static Float:vOrigin[3], Float:eOrigin[3];
	pev(id, pev_origin, vOrigin);

	for(new i = 1; i <= 32; ++i) {

		if( !is_user_connected(i) || !is_user_alive(i) ) continue;	

		pev(i, pev_origin, eOrigin);
		new Float:temp = get_distance_f(vOrigin, eOrigin);

		if( temp <= 3000.0 && temp < minDistance) {

			if( nonBlockedByWorld(id, vOrigin, eOrigin) ) {

				minDistance = temp;
				near = i;
			}
		}
	}

	return near;
}

nonBlockedByWorld(id, Float:origin1[3], Float:origin2[3])
{
	static trace;
	trace = create_tr2();
	engfunc(EngFunc_TraceLine, origin1, origin2, IGNORE_MONSTERS, id, trace);

	static Float:fraction;
	get_tr2(trace, TR_flFraction, fraction);
	free_tr2(trace);

	return fraction == 1.0;
}

get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0];
	new_velocity[1] = origin2[1] - origin1[1];
	new_velocity[2] = origin2[2] - origin1[2];

	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]));

	new_velocity[0] *= num;
	new_velocity[1] *= num;
	new_velocity[2] *= num;

	return 1;
}