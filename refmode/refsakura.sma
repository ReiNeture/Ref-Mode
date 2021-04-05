#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

new const szMikoClass[] = "sakuraMiko";
new const szSakuraTree[] = "models/ref/rs_sakura.mdl";
new const szFireFlies[] = "models/ref/rs_fireflies.mdl";
new const szSakuraExpSound[] = "ref/sakura_exp2.wav"
new const szPinkDot[] = "sprites/ref/pflare.spr"
new const szBlueDot[] = "sprites/ref/bflare.spr"

new flare, flies;
new flare_b;

public plugin_init()
{
    register_plugin("Sakura Barrier", "1.0", "Reff");
    register_clcmd("miko", "makeSakuraMiko");

    register_forward(FM_Think, "fw_Think");
}

public plugin_precache()
{
    engfunc(EngFunc_PrecacheModel, szSakuraTree);
    flies = engfunc(EngFunc_PrecacheModel, szFireFlies);
    flare = engfunc(EngFunc_PrecacheModel, szPinkDot);
    flare_b = engfunc(EngFunc_PrecacheModel, szBlueDot);
    engfunc(EngFunc_PrecacheSound, szSakuraExpSound);
}

public plugin_natives()
{ 
	register_native("get_sakura_miko", "makeSakuraMiko", 1);
}

public makeSakuraMiko(id)
{
    static originEntity;
    originEntity = fm_find_ent_by_owner(-1, szMikoClass, id);
    if( originEntity ) {
        engfunc(EngFunc_RemoveEntity, originEntity);
        return;
    }

    static entity;
    entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(entity) ) return;

    new Float:vOrigin[3];
    pev(id, pev_origin, vOrigin);

    set_pev(entity, pev_classname, szMikoClass);
    set_pev(entity, pev_owner, id);
    set_pev(entity, pev_movetype, MOVETYPE_NOCLIP);
    set_pev(entity, pev_solid, SOLID_TRIGGER);
    set_pev(entity, pev_sequence, 0);
    set_pev(entity, pev_framerate, 1.0);

    new Float:traceto[3];
    traceto[0] = vOrigin[0];
    traceto[1] = vOrigin[1];
    traceto[2] = vOrigin[2] - 4096.0;

    new trace;
    engfunc(EngFunc_TraceLine, vOrigin, traceto, IGNORE_MONSTERS, id, trace);

    new Float:end_origin[3];
    get_tr2(trace, TR_vecEndPos, end_origin);

    vOrigin[2] = end_origin[2] + 220.0;
    engfunc(EngFunc_SetModel, entity, szSakuraTree);
    engfunc(EngFunc_SetSize, entity, Float:{ -250.0, -250.0, -240.0}, Float:{250.0, 250.0, 260.0} );
    engfunc(EngFunc_SetOrigin, entity, vOrigin);

    create_dynamic_light(vOrigin, 300, 255, 179, 250, 30);
    set_pev(entity, pev_nextthink, get_gametime() + 3.0);
}

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED;
	
	static Classname[32], Float:vOrigin[3];
	pev(ent, pev_classname, Classname, sizeof(Classname) )

	if( equal(Classname, szMikoClass) ) {

        pev(ent, pev_origin, vOrigin);
        create_dynamic_light(vOrigin, 300, 255, 179, 250, 30);
        create_sprite_trail(vOrigin);
        create_fire_field(vOrigin);
        emit_sound(ent, CHAN_STATIC, szSakuraExpSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

        new Float:victimOrigin[3];
        new victim = FM_NULLENT;
        new id = pev(ent, pev_owner);
        
        while((victim = engfunc(EngFunc_FindEntityInSphere, victim, vOrigin, 500.0) ) != 0) {

            if(!is_user_alive(victim) || id == victim )
                continue;

            if(get_user_team(victim) == get_user_team(id) ) 
                continue;

            pev(victim, pev_origin, victimOrigin);
            create_sprite_trail2(victimOrigin);

            ExecuteHam(Ham_TakeDamage, victim, id, id, 4000.0, DMG_ENERGYBEAM);

        }
        set_pev(ent, pev_nextthink, get_gametime() + 3.0);
    }

    return FMRES_IGNORED;
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}

stock create_screen_fade(id)
{
    engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), 0, id);
    write_short(1<<10);
    write_short(1<<11);
    write_short(0x0000);
    write_byte(255);
    write_byte(179);
    write_byte(250);
    write_byte(30);
    message_end();
}

stock create_fire_field(const Float:vOrigin[3])
{
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
    write_byte(TE_FIREFIELD);
    engfunc(EngFunc_WriteCoord, vOrigin[0] );
    engfunc(EngFunc_WriteCoord, vOrigin[1] );
    engfunc(EngFunc_WriteCoord, vOrigin[2] );
    write_short(200);
    write_short(flies);
    write_byte(7);
    write_byte(TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_ALLFLOAT);
    write_byte(20);
    message_end();
}

stock create_sprite_trail(const Float:vOrigin[3])
{
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
    write_byte(TE_SPRITETRAIL);
    engfunc(EngFunc_WriteCoord, vOrigin[0]);
    engfunc(EngFunc_WriteCoord, vOrigin[1]);
    engfunc(EngFunc_WriteCoord, vOrigin[2]);
    engfunc(EngFunc_WriteCoord, vOrigin[0]);
    engfunc(EngFunc_WriteCoord, vOrigin[1]);
    engfunc(EngFunc_WriteCoord, vOrigin[2]+100.0);
    write_short(flare);
    write_byte(50);
    write_byte(20);
    write_byte(5);
    write_byte(80);
    write_byte(20);
    message_end();
}

stock create_sprite_trail2(const Float:vOrigin[3])
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_SPRITETRAIL);
    engfunc(EngFunc_WriteCoord, vOrigin[0]);
    engfunc(EngFunc_WriteCoord, vOrigin[1]);
    engfunc(EngFunc_WriteCoord, vOrigin[2]);
    engfunc(EngFunc_WriteCoord, vOrigin[0]);
    engfunc(EngFunc_WriteCoord, vOrigin[1]);
    engfunc(EngFunc_WriteCoord, vOrigin[2]);
    write_short(flare_b);
    write_byte(1);
    write_byte(10);
    write_byte(5);
    write_byte(10);
    write_byte(0);
    message_end();
}

stock create_dynamic_light(const Float:originF[3], radius, red, green, blue, life)
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, originF, 0);
	write_byte(TE_DLIGHT) 
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2])
	write_byte(radius)
	write_byte(red)
	write_byte(green)
	write_byte(blue)
	write_byte(life)
	write_byte(3)
	message_end()
}