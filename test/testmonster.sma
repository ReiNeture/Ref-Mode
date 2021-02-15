#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <xs>
#include <vector>

new ccc;
new ttt;

public plugin_init()
{
    register_plugin("RefMenu", "1.0", "Reff");
    RegisterHam(Ham_Touch, "env_sprite", "fw_touch");
    register_clcmd("s0", "ss0");
    register_clcmd("s1", "ss1");
    register_clcmd("s2", "ss2");
    register_clcmd("s3", "ss3");
    register_clcmd("s4", "ss4");

    register_clcmd("mo0", "momo0");
    register_clcmd("mo1", "momo1");
    register_clcmd("mo2", "momo2");
    register_clcmd("mo3", "momo3");
    register_clcmd("mo4", "momo4");
    register_clcmd("mo5", "momo5");
    register_clcmd("mo6", "momo6");
    register_clcmd("mo7", "momo7");
    register_clcmd("mo8", "momo8");
    register_clcmd("mo9", "momo9");
    register_clcmd("mo10", "momo10");
    register_clcmd("mo11", "momo11");

    register_clcmd("xxx", "xxxfie");
}
public plugin_precache()
{
    precache_model("sprites/ref/tpball.spr");

}
public fw_touch(ent, ptr)
{
	if (!is_valid_ent(ent)) return HAM_IGNORED;

	new szClassName[32], ptrClassName[32];
	entity_get_string(ent, EV_SZ_classname, szClassName, charsmax(szClassName));
	entity_get_string(ptr, EV_SZ_classname, ptrClassName, charsmax(ptrClassName));

	new Float:fOrigin[3];
	new id = entity_get_edict(ent, EV_ENT_owner);

	if(equal(szClassName, "tttt") && !equal(ptrClassName, "tttt") && id != ptr ) {

			ExecuteHam(Ham_TakeDamage, ptr, ptr, id, 2000.0, DMG_ENERGYBEAM);

			remove_entity(ent);
	}
	return FMRES_HANDLED;
}

public xxxfie(id)
{
	new Float:vOrigin[3], Float:vVelocity[3];
	new ent = create_entity("env_sprite");

	entity_get_vector(id, EV_VEC_origin, vOrigin)

	entity_set_string(ent, EV_SZ_classname, "tttt");
	entity_set_int(ent, EV_INT_solid, ccc);
	entity_set_int(ent, EV_INT_movetype, ttt);

	entity_set_model(ent, "sprites/ref/tpball.spr");

    velocity_by_aim(id, 150, vVelocity);
    vOrigin[0] += vVelocity[0];
    vOrigin[1] += vVelocity[1];
    vOrigin[2] += vVelocity[2];
	entity_set_origin(ent, vOrigin);
    entity_set_edict(ent, EV_ENT_owner, id);
	entity_set_size(ent, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0});

	entity_set_int(ent, EV_INT_rendermode, kRenderTransAdd);
	entity_set_float(ent, EV_FL_renderamt, 255.0);
	entity_set_float(ent, EV_FL_scale, random_float(0.1, 0.4));
	entity_set_int(ent, EV_INT_iuser1, id);

	velocity_by_aim(id, 660, vVelocity);

	entity_set_vector(ent, EV_VEC_velocity, vVelocity);

}

public ss0(id){
    ccc = SOLID_NOT;
}
    
public ss1(id){
    ccc = SOLID_TRIGGER;
}

public ss2(id){
    ccc = SOLID_BBOX;
}

public ss3(id){
    ccc = SOLID_SLIDEBOX;
}

public ss4(id){
    ccc = SOLID_BSP;
}

public momo0(id){
    ttt = MOVETYPE_NONE;
}
public momo1(id){
    ttt = MOVETYPE_WALK;
}
public momo2(id){
    ttt = MOVETYPE_STEP;
}
public momo3(id){
    ttt = MOVETYPE_FLY;
}
public momo4(id){
    ttt = MOVETYPE_TOSS;
}
public momo5(id){
    ttt = MOVETYPE_PUSH;
}
public momo6(id){
    ttt = MOVETYPE_NOCLIP;
}
public momo7(id){
    ttt = MOVETYPE_FLYMISSILE;
}
public momo8(id){
    ttt = MOVETYPE_BOUNCE;
}
public momo9(id){
    ttt = MOVETYPE_BOUNCEMISSILE;
}
public momo10(id){
    ttt = MOVETYPE_FOLLOW;
}
public momo11(id){
    ttt = MOVETYPE_PUSHSTEP;
}