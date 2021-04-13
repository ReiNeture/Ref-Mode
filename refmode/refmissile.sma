#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>

new const missileClass[] = "r_missile";

new const szMissile[] = "models/ref/stinger_rocket_frk14.mdl";
new const szHitSmoke[] = "sprites/ref/smoke_ia.spr";
new const szMissileExp[] = "sprites/ref/zerogxplode.spr";
new const szMissileExpSound[] = "ref/arc_explode.wav";
new const szMissileHitSound[] = "ref/misile_hit.wav";

new hit, exp;

#define MISSILE_HEIGHT 900.0
#define MISSILE_RADIUS 175.0
#define MISSILE_DAMAGE 1475.0
#define MISSILE_FALL_DAMAGE 280.0

new bool:Enabled[33];

public plugin_init()
{
    register_plugin("Sky Missile", "1.0", "Reff");

    register_forward(FM_Think, "fw_Think");
    register_forward(FM_Touch, "fw_Touch");

    RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack");
    RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");

    register_clcmd("r_missile", "doMissile");
}

public plugin_precache()
{
    engfunc(EngFunc_PrecacheModel, szMissile);
    engfunc(EngFunc_PrecacheSound, szMissileExpSound);
    engfunc(EngFunc_PrecacheSound, szMissileHitSound);

    hit = engfunc(EngFunc_PrecacheModel, szHitSmoke);
    exp = engfunc(EngFunc_PrecacheModel, szMissileExp);
}

public plugin_natives()
{ 
	register_native("set_missile_switch", "switchFunction", 1);
}

public doMissile(id, const Float:aim_origin[3])
{
    // new Float:aim_origin[3];
    // fm_get_aim_origin(id, aim_origin);

    new Float:high_origin[3];
    xs_vec_copy(aim_origin, high_origin);
    high_origin[2] += MISSILE_HEIGHT;

    new Float:new_velocity[3];
    get_speed_vector(high_origin, aim_origin, 1200.0, new_velocity);

    static entity;
    entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(entity) ) return;

    set_pev(entity, pev_classname, missileClass);
    set_pev(entity, pev_owner, id);
    set_pev(entity, pev_movetype, MOVETYPE_NOCLIP);
    set_pev(entity, pev_solid, SOLID_TRIGGER);
    set_pev(entity, pev_gravity, 0.4);
    set_pev(entity, pev_angles, {-90.0, 0.0, 0.0} );
    set_pev(entity, pev_fuser1, aim_origin[2] );

    engfunc(EngFunc_SetModel, entity, szMissile);
    engfunc(EngFunc_SetSize, entity, Float:{-1.3, -1.3, -3.1}, Float:{1.3, 1.3, 3.1} );
    engfunc(EngFunc_SetOrigin, entity, high_origin);

    set_pev(entity, pev_velocity, new_velocity);
    set_pev(entity, pev_nextthink, get_gametime() + 0.1);
}

public fw_Think(ent)
{
    if( !pev_valid(ent) ) return FMRES_IGNORED;

    static Classname[32], Float:fOrigin[3];
    pev(ent, pev_classname, Classname, sizeof(Classname) );

    if( equal(Classname, missileClass) ) {

        pev(ent, pev_origin, fOrigin);
        if( fOrigin[2] - pev(ent, pev_fuser1) <= 36.0 )
            doArrivals(ent);
        else
            set_pev(ent, pev_nextthink, get_gametime() + 0.01);
    }

    return FMRES_IGNORED;
}

doArrivals(entity)
{
    set_pev(entity, pev_movetype, MOVETYPE_TOSS);
    set_pev(entity, pev_nextthink, 0.0);
}

public fw_Touch(toucher, touched)
{
    if(!pev_valid(toucher) ) return FMRES_IGNORED;
            
    static Classname[32];
    pev(toucher, pev_classname, Classname, sizeof(Classname));

    if( equal(Classname, missileClass) ) {

        if( pev(toucher, pev_iuser1) == 1 ) return FMRES_IGNORED;

        set_pev(toucher, pev_iuser1, 1);
        if( !task_exists(toucher) )
            set_task(0.7, "doMissileExplode", toucher);

        pev(touched, pev_classname, Classname, sizeof(Classname));
        if( equal(Classname, "worldspawn") ) {

            new Float:fOrigin[3];
            pev(toucher, pev_origin, fOrigin);

            create_smoke_sprite(fOrigin);
            emit_sound(toucher, CHAN_WEAPON, szMissileHitSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

        }else if( equal(Classname, "player") ) {

            new id = pev(toucher, pev_owner);
            if( id != touched )
                ExecuteHam(Ham_TakeDamage, touched, id, id, MISSILE_FALL_DAMAGE, DMG_CRUSH);
        }
    }

    return FMRES_IGNORED;
}

public doMissileExplode(entity)
{
    if(!pev_valid(entity) ) return;

    static Float:vOrigin[3];
    new victim = FM_NULLENT
    new id = pev(entity, pev_owner);

    pev(entity, pev_origin, vOrigin);
    create_explode_sprite(vOrigin);
    emit_sound(entity, CHAN_WEAPON, szMissileExpSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

    while((victim = engfunc(EngFunc_FindEntityInSphere, victim, vOrigin, MISSILE_RADIUS) ) != 0) {

        if( (1 > victim > 32) || !is_user_alive(victim) || id == victim )
            continue;

        ExecuteHam(Ham_TakeDamage, victim, id, id, MISSILE_DAMAGE, DMG_RADIATION);
    }

    engfunc(EngFunc_RemoveEntity, entity);
}

public fw_TraceAttack(this, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
    if ( !Enabled[id] || !is_user_alive(id) || !is_user_connected(id) ) return HAM_IGNORED;

    if( random_num(1, 100) <= 10) {

        static Float:vOrigin[3];
        get_tr2(tracehandle, TR_vecEndPos, vOrigin);
        doMissile(id, vOrigin);
    }

    return HAM_IGNORED;
}

public switchFunction(id)
{
    Enabled[id] ^= true;
}

public client_putinserver(id)
{
	Enabled[id] = false;
}

public client_disconnected(id)
{
	Enabled[id] = false;
}

stock fm_get_aim_origin(index, Float:origin[3])
{
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);

	new Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);

	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);

	return 1;
}

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num

	return 1;
}

stock create_explode_sprite(const Float:fOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(exp);
	write_byte(20);
	write_byte(13);
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
	message_end();
}

stock create_smoke_sprite(const Float:fOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(hit);
	write_byte(10);
	write_byte(200);
	message_end();
}