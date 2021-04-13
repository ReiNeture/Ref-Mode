#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>

#define NUKE_EXPLODE_RADIUS 305.0
#define NUKE_DAMAGE 9777.0

#define RADIAN_OFFSET 45.0
#define MAX_RADIUS 540.0 // 需要能整除 CHARGE_TIME
#define PER_CHANGE_RADIUS 2.0
#define CHARGE_TIME 3.0
#define EXPLODE_TIME 12.0
#define THINK_TIME 0.1

// new const Float:RADIAN_OFFSET = 45.0;
// new const Float:MAX_RADIUS = 540.0;
// new const Float:PER_CHANGE_RADIUS = 2.0;
// new const Float:CHARGE_TIME = 5.0;
// new const Float:EXPLODE_TIME = 10.0;
// new const Float:THINK_TIME = 0.1;

new Float:MAX_CHARGE_LIFE;       // = (PER_CHANGE_RADIUS * 30.0) * 10.0;
new Float:MAX_LIFE;              // = MAX_CHARGE_LIFE + 10.0 * 10.0;
new Float:CHANGE_RANGE;          // = ((MAX_RADIUS / CHARGE_TIME) / PER_CHANGE_RADIUS ) * 0.1;

new const nukeDeviceClass[] = "r_nuke";

new const szLightLine[] = "sprites/ref/ef_gungnir_lightline2.spr";
// new const szLineEnd[] = "sprites/ref/wall_puff1.spr";
new const szDeimoExplode[] = "sprites/ref/deimosexp.spr";

new const szMissile[] = "models/ref/stinger_rocket_frk14_big.mdl";

new light, endl;

new bool:hasNuke[33];
new gMaxPlayers;

public plugin_init()
{
    register_plugin("Nuke Magic", "1.0", "Reff");

    register_forward(FM_Think, "fw_Think");
    register_clcmd("r_nuke", "doNuke");

    gMaxPlayers = get_maxplayers();
}

public plugin_precache()
{
    MAX_CHARGE_LIFE = (PER_CHANGE_RADIUS * CHARGE_TIME) / THINK_TIME; 
    MAX_LIFE = MAX_CHARGE_LIFE + (PER_CHANGE_RADIUS * EXPLODE_TIME) / THINK_TIME;
    CHANGE_RANGE = ((MAX_RADIUS / CHARGE_TIME) / PER_CHANGE_RADIUS ) * THINK_TIME;

    engfunc(EngFunc_PrecacheModel, szMissile);
    light = engfunc(EngFunc_PrecacheModel, szLightLine);
    endl = engfunc(EngFunc_PrecacheModel, szDeimoExplode);
}

public plugin_natives()
{ 
	register_native("set_nuke_magic", "doNuke", 1);
}

public doNuke(id)
{
    if( hasNuke[id] ) {
        client_print(id, print_center, "你的核彈還在衝能中...");
        return;
    }

    new Float:fOrigin[3];
    pev(id, pev_origin, fOrigin);
    fOrigin[2] -= 32.0;

    new entity;
    entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(entity) ) return;

    set_pev(entity, pev_classname, nukeDeviceClass);
    set_pev(entity, pev_owner, id);
    set_pev(entity, pev_movetype, MOVETYPE_NONE);
    set_pev(entity, pev_solid, SOLID_BBOX);
    set_pev(entity, pev_angles, {90.0, 0.0, 0.0} );
    
    set_pev(entity, pev_renderfx, kRenderFxGlowShell);
    set_pev(entity, pev_rendermode, kRenderTransAdd);
    set_pev(entity, pev_renderamt, 185.0);

    set_pev(entity, pev_fuser1, 0.0);

    engfunc(EngFunc_SetModel, entity, szMissile);
    engfunc(EngFunc_SetSize, entity, Float:{-1.3, -1.3, -3.1}, Float:{1.3, 1.3, 3.1} );
    engfunc(EngFunc_SetOrigin, entity, fOrigin);

    hasNuke[id] = true;
    set_pev(entity, pev_nextthink, get_gametime() + THINK_TIME);
}

public fw_Think(ent)
{
    if( !pev_valid(ent) ) return FMRES_IGNORED;

    static Classname[32], Float:degree;
    pev(ent, pev_classname, Classname, sizeof(Classname) );

    static Float:vOrigin[3];
    if( equal(Classname, nukeDeviceClass) ) {

        pev(ent, pev_fuser1, degree);
        set_pev(ent, pev_fuser1, (degree + PER_CHANGE_RADIUS) );

        if( degree < MAX_CHARGE_LIFE )
        {
            new i;
            for(i = 0; i <= 7; ++i ) {

                pev(ent, pev_origin, vOrigin);
                vOrigin[0] += floatcos((degree + i * RADIAN_OFFSET), degrees ) * (MAX_RADIUS - (degree * CHANGE_RANGE) );
                vOrigin[1] += floatsin((degree + i * RADIAN_OFFSET), degrees ) * (MAX_RADIUS - (degree * CHANGE_RANGE) );

                create_beam_end(vOrigin);
            }

        } else if( degree < MAX_LIFE ) {

            static Float:origin[3];
            get_spherical_coord_explode(
                vOrigin,
                random_float(30.0, 530.0),   // Float:redius
                random_float(0.0, 359.0),    // Float:level_angle
                random_float(10.0, 170.0),   // Float:vertical_angl
                origin
            );

            static Float:PlayerOrigin[3], owner;
            for(new i = 0; i < gMaxPlayers; ++i ) {

                if( !is_user_alive(i) ) continue;

                pev(i, pev_origin, PlayerOrigin);
                if(get_distance_f(vOrigin, PlayerOrigin) > NUKE_EXPLODE_RADIUS )
                    continue;

                owner = pev(ent, pev_owner);
                ExecuteHam(Ham_TakeDamage, i, owner, owner, NUKE_DAMAGE, DMG_RADIATION);
            }
            create_expload_spr(origin);

        } else {
            new owner = pev(ent, pev_owner);
            hasNuke[owner] = false;
            engfunc(EngFunc_RemoveEntity, ent);
            return FMRES_IGNORED;
        }

        set_pev(ent, pev_nextthink, get_gametime() + THINK_TIME);
    }

    return FMRES_IGNORED;
}

stock get_spherical_coord_explode(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
    new Float:length;
    length  = redius * floatcos(vertical_angle, degrees);

    origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees);
    origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees);
    origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees);
}

stock create_expload_spr(const Float:fOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(endl);
	write_byte(30);
	write_byte(20);
	write_byte(TE_EXPLFLAG_NOPARTICLES);
	message_end();
}

stock create_beam_end(const Float:fOrigin[3])
{
    // engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, {0,0,0}, 0);
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    engfunc(EngFunc_WriteCoord, fOrigin[0] );
    engfunc(EngFunc_WriteCoord, fOrigin[1] );
    engfunc(EngFunc_WriteCoord, fOrigin[2] + 1500.0);
    engfunc(EngFunc_WriteCoord, fOrigin[0] );
    engfunc(EngFunc_WriteCoord, fOrigin[1] );
    engfunc(EngFunc_WriteCoord, fOrigin[2] );
    write_short(light);
    write_byte(0);
    write_byte(20);
    write_byte(1);
    write_byte(40);
    write_byte(0);
    write_byte(255);
    write_byte(255);
    write_byte(255);
    write_byte(255);
    write_byte(0);
    message_end();
}
