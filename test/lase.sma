#include <amxmodx>
#include <fakemeta>
#include <xs>
#include <engine>

#define PLUGIN "Draw Normal Laser Example"
#define VERSION "1.0"
#define AUTHOR "Nomexous"

new beampoint
new ent

public plugin_precache()
{
    // Needed to show the laser.
    beampoint = precache_model("sprites/eye.spr");
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_clcmd("la", "shoot_laser");
    register_clcmd("sd", "sd");
    register_clcmd("cre", "cre");
    register_clcmd("mov", "mov");
    register_clcmd("lig", "lig");
    register_message(SVC_PRINT, "hkmsg");

    // I included the entire plugin because in order to draw the laser, you need to precache a sprite. Incorporate
    // these elements into your own plugin.
    
    // The shoot_laser() will (if the entity is on the floor) fire a laser from the entity, normal to the surface it's resting on.
}
public hkmsg(msgid, dest, id) {
	new eid = get_msg_arg_int(1);
	client_print(0, print_chat, "--%d", eid);
	return PLUGIN_CONTINUE;
}
public lig(id)
{
    client_print(id, print_console, "reworepwr3324");
    new origin[3];
    get_user_origin(id, origin, 0);

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_ELIGHT)
    write_short(id)
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2])
    write_coord(100)
    write_byte(120)
    write_byte(20)
    write_byte(20)
    write_byte(100)
    write_coord(50)
    message_end();
}
public cre(id)
{
    static entity;
    if((entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite")))) {
        static Float:vOrigin[3];
        pev(id, pev_origin, vOrigin);
        set_pev(entity, pev_classname, "MOVE");
        set_pev(entity, pev_movetype, MOVETYPE_NONE);
        set_pev(entity, pev_solid, SOLID_TRIGGER);
        engfunc(EngFunc_SetModel, entity, "models/haachama/haachama.mdl");
        engfunc(EngFunc_SetOrigin, entity, vOrigin);
        engfunc(EngFunc_SetSize, entity, Float:{ -1.5, -1.0, -1.0 }, Float:{ 1.5, 1.0, 1.0 });
        drop_to_floor(entity);
    }
    ent = entity;
}
public mov(id)
{
    static Float:vOrigin[3];
    pev(id, pev_origin, vOrigin);
    engfunc(EngFunc_MoveToOrigin, ent, vOrigin, 10.0, 0);
}

public sd(id)
{
    new Float:origin[3], Float:velocity[3];
    pev(id, pev_origin, origin)
    velocity_by_aim(id, 2000, velocity);

    new Float:end[3];
    xs_vec_add(origin, velocity, end); 

    new Float:fAimOrigin[3]
    new iTr// = create_tr2()
    engfunc( EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, id, iTr )
    get_tr2( iTr, TR_vecEndPos, fAimOrigin )
    // get_tr2( iTr, TR_vecPlaneNormal, fNormalVector )
    free_tr2( iTr )

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_EXPLOSION)
    write_coord(floatround(fAimOrigin[0]))
    write_coord(floatround(fAimOrigin[1]))
    write_coord(floatround(fAimOrigin[2]))
    write_short(beampoint)
    write_byte(100)
    write_byte(2)
    write_byte(1)
    message_end()
}
public shoot_laser(ent)
{
    // We get the origin of the entity.
    new Float:origin[3], Float:velocity[3];
    pev(ent, pev_origin, origin)
    velocity_by_aim(ent, 1000, velocity);

    new Float:end[3];
    xs_vec_add(origin, velocity, end);

    
    new trace = 0
    // Draw the traceline. We're assuming the object is resting on the floor.
    engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, ent, trace)
    new Float:fraction
    get_tr2(trace, TR_flFraction, fraction)
    // If we didn't hit anything, then we won't get a valid TR_vecPlaneNormal.
    if (fraction == 1.0) return
    xs_vec_mul_scalar(velocity, fraction, velocity)
    xs_vec_add(origin, velocity, end);
    
    new Float:normal[3]
    get_tr2(trace, TR_vecPlaneNormal, normal)
    // We'll multiply the the normal vector by a scalar to make it longer.
    normal[0] *= 200.0 // Mathematically, we multiplied the length of the vector by 400*(3)^(1/2),
    normal[1] *= 200.0 // or, in words, four hundred times root three.
    normal[2] *= 200.0
    
    // To get the endpoint, we add the normal vector and the origin.
    new Float:endpoint[3]
    endpoint[0] = end[0] + normal[0]
    endpoint[1] = end[1] + normal[1]
    endpoint[2] = end[2] + normal[2]
    
    // Finally, we draw from the laser!
    draw_laser(end, endpoint, 200) // Make it stay for 10 seconds. Not a typo; staytime is in 10ths of a second.
}

public draw_laser(Float:start[3], Float:end[3], staytime)
{                    
    message_begin(MSG_ALL, SVC_TEMPENTITY)
    write_byte(TE_BEAMPOINTS)
    engfunc(EngFunc_WriteCoord, start[0])
    engfunc(EngFunc_WriteCoord, start[1])
    engfunc(EngFunc_WriteCoord, start[2])
    engfunc(EngFunc_WriteCoord, end[0])
    engfunc(EngFunc_WriteCoord, end[1])
    engfunc(EngFunc_WriteCoord, end[2])
    write_short(beampoint)
    write_byte(0)
    write_byte(0)
    write_byte(staytime) // In tenths of a second.
    write_byte(10)
    write_byte(1)
    write_byte(255) // Red
    write_byte(0) // Green
    write_byte(0) // Blue
    write_byte(127)
    write_byte(1)
    message_end()
} 