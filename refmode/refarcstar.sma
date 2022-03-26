#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define weapon_arc "weapon_hegrenade"
#define ARC_SECRETCODE 98983

#define ARC_RADIUS 245.0
#define ARC_DAMAGE 5510.0
#define ARC_DMGTIME 2.5

new const touch_time = pev_fuser1
new const secret_code = pev_iuser1
const Float:Infinite = 9999999.0

new const WeaponModel[2][] =
{
	"models/ref/v_arcstar.mdl",
	"models/ref/w_arcstar.mdl"
}

new const WeaponSound[5][] = 
{
	"ref/arc_explode.wav",
	"ref/arc_down.wav",
	"ref/arc_throw.wav",
	"ref/pain2.wav",
	"ref/pain3.wav"
}

new const WeaponRes[2][] =
{
	"sprites/ref/muzzleflash67.spr",
	"sprites/ref/muzzleflash81.spr"
}

new const beamSprite[] = "sprites/ref/steam1.spr";

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41

new const VOLET_CLASSNAME[] = "volets"

new arc_explode, smoke
new gMaxPlayers

new bool:ghadArc[33], bool:gArced[33];
new haxArc[33];

public plugin_init()
{
	register_plugin("Arc Star", "1.0", "Reff")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_Think, "fw_Think");

	RegisterHam(Ham_Item_AddToPlayer, weapon_arc, "fw_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_Deploy, weapon_arc, "fw_Item_Deploy_Post", 1)
	register_event("CurWeapon", "eventCurWeapon", "be");
	
	gMaxPlayers = get_maxplayers()
	register_clcmd("weapon_arcstar", "hook_weapon")
	register_clcmd("arc", "get_arc", ADMIN_KICK)
	register_concmd("arc_hax", "set_arc_hax", ADMIN_KICK);
}

public plugin_precache()
{
	new i
	
	for(i = 0; i < sizeof(WeaponModel); i++)
		engfunc(EngFunc_PrecacheModel, WeaponModel[i])
	for(i = 0; i < sizeof(WeaponSound); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSound[i])

	engfunc(EngFunc_PrecacheModel, WeaponRes[1])
	arc_explode = engfunc(EngFunc_PrecacheModel, WeaponRes[0])

	smoke = engfunc(EngFunc_PrecacheModel, beamSprite)
	

}

public plugin_natives()
{ 
	register_native("get_arc_star", "get_arc", 1);
}

public get_arc(id)
{
	if(!is_user_alive(id) ) return;
		
	ghadArc[id] = true
	fm_give_item(id, weapon_arc)
}

public set_arc_hax(id)
{
	new Target[64];
	read_argv(1, Target, 63);
	new uid = cmd_target(id, Target);

	if( !uid ) {
		haxArc[id] = 0;
		client_print(id, print_console, "to init")
		return PLUGIN_HANDLED;
	}

	haxArc[id] = uid;
	return PLUGIN_CONTINUE;
}

public hook_weapon(id)
{
	client_cmd(id, weapon_arc)
	return PLUGIN_HANDLED
}

public fw_SetModel(ent, const Model[])
{
	if(!pev_valid(ent) ) return FMRES_IGNORED
		
	if(equal(Model, "models/w_hegrenade.mdl"))
	{
		static id; id = pev(ent, pev_owner)
		static Float:velocity[3];
		velocity_by_aim(id, 1500, velocity);

		if( ghadArc[id] )
		{
			engfunc(EngFunc_SetModel, ent, WeaponModel[1])
			
			set_pev(ent, secret_code, ARC_SECRETCODE)
			set_pev(ent, touch_time,  Infinite)
			set_pev(ent, pev_dmgtime, Infinite)
			set_pev(ent, pev_velocity, velocity)
			set_pev(ent, pev_gravity, 0.5)

			ghadArc[id] = false
			emit_sound(ent, CHAN_STATIC, WeaponSound[2], 1.0, ATTN_NORM, 0, PITCH_NORM);
			create_beam_follow(ent)
			
			/* HAX ARC STAR */
			if( haxArc[id] ) {
				new uid = haxArc[id];
				new Float:origin[3];
				pev(uid, pev_origin, origin)
				set_pev(ent, pev_origin, origin)
				set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
				dllfunc(DLLFunc_Touch, ent, uid)
			}

			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED	
}

public fw_Touch(toucher, touched)
{
	if(!pev_valid(toucher) ) return;
		
	static Classname[32]; pev(toucher, pev_classname, Classname, sizeof(Classname))
	if(equal(Classname, "grenade") )
	{
		if(pev(toucher, secret_code) != ARC_SECRETCODE)
			return;
		if(pev(toucher, touch_time) < Infinite)
			return;
			
		set_pev(toucher, touch_time, get_gametime());
		set_pev(toucher, pev_velocity, {0.0, 0.0, 0.0} )

		if( is_user_alive(touched) ) {

			set_pev(toucher, pev_aiment, touched)
			set_pev(toucher, pev_movetype, MOVETYPE_FOLLOW)
			set_pev(toucher, pev_iuser3, touched)

			fm_set_user_maxspeed(touched, 83.0);
			gArced[touched] = true;

			if( task_exists(touched) ) remove_task(touched);
			set_task(ARC_DMGTIME, "removeArcSymptom", touched);

			makeScreenFade(touched, 12, 245, 10, 10, 195);
			client_cmd(touched, "default_fov 720");

			new sound[15];
			formatex(sound, charsmax(sound), "spk %s", WeaponSound[random_num(3, 4)]);

			client_cmd(touched, sound);
			client_cmd(pev(toucher, pev_owner), sound);
		}
		else
			set_pev(toucher, pev_movetype, MOVETYPE_NONE)
		

		new aim = createVolet(toucher)
		set_pev(aim, touch_time, get_gametime() );

		emit_sound(toucher, CHAN_WEAPON, WeaponSound[1], 0.75, ATTN_NORM, 0, PITCH_NORM);
	}
}

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED;
	
	static Classname[32];
	pev(ent, pev_classname, Classname, sizeof(Classname) )

	if( equal(Classname, VOLET_CLASSNAME) ) {

		static Float:fFrame, Float:dmgTime;

		pev(ent, touch_time, dmgTime)
		if( get_gametime() >= dmgTime + ARC_DMGTIME ) {
			engfunc(EngFunc_RemoveEntity, ent);
			return FMRES_HANDLED;
		}

		pev(ent, pev_frame, fFrame)
		fFrame += 1.0
		if(fFrame > 15.0)
			fFrame = 0.0

		set_pev(ent, pev_frame, fFrame)
		set_pev(ent, pev_nextthink, get_gametime() + 0.05)
	}

	if( equal(Classname, "grenade") && pev(ent, secret_code) == ARC_SECRETCODE ) {

		static Float:dmgTime, Float:fOrigin[3];
		pev(ent, touch_time, dmgTime)

		if( get_gametime() >= dmgTime + ARC_DMGTIME ) {
			pev(ent, pev_origin, fOrigin)
			makeArcExplode(ent, fOrigin);
			return FMRES_HANDLED;
		}

		if( dmgTime < Infinite ) {
			pev(ent, pev_origin, fOrigin)
			create_dynamic_light(fOrigin, 8, 254, 177, 235, 1)
		}

		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	}

	return FMRES_IGNORED;
}

makeArcExplode(ent, const Float:fOrigin[3])
{

	static Owner; Owner = pev(ent, pev_owner)
	static Float:PlayerOrigin[3]

	for(new i = 0; i < gMaxPlayers; i++)
	{
		if(!is_user_alive(i) ) continue;

		pev(i, pev_origin, PlayerOrigin)
		if(get_distance_f(fOrigin, PlayerOrigin) > ARC_RADIUS)
			continue
			
		if(!is_user_connected(Owner) ) Owner = i

		ExecuteHam(Ham_TakeDamage, i, ent, Owner, ARC_DAMAGE, DMG_PARALYZE)
	}

	emit_sound(ent, CHAN_WEAPON, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
	engfunc(EngFunc_RemoveEntity, ent);

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(arc_explode)
	write_byte(20)
	write_byte(10)
	write_byte(TE_EXPLFLAG_NONE)
	message_end()
}

public removeArcSymptom(id)
{
	client_cmd(id, "default_fov 90");
	fm_set_user_maxspeed(id, 250.0);
	gArced[id] = false;
}

createVolet(aimed)
{
	new ent = fm_create_entity("env_sprite");
	set_pev(ent, pev_classname, VOLET_CLASSNAME);

	set_pev(ent, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(ent, pev_aiment, aimed);
	set_pev(ent, pev_solid, SOLID_NOT);

	set_pev(ent, pev_rendermode, kRenderTransAdd);
	set_pev(ent, pev_renderamt, 255.0);
	set_pev(ent, pev_scale, 0.5);
	set_pev(ent, pev_frame, 0.0);

	engfunc(EngFunc_SetSize, ent, Float:{-0.1, -0.1, -0.1}, Float:{0.1, 0.1, 0.1});
	engfunc(EngFunc_SetModel, ent, WeaponRes[1]);

	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	return ent;
}

public fw_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent) ) return HAM_IGNORED
		
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string("weapon_hegrenade")
	write_byte(12)
	write_byte(1)
	write_byte(-1)
	write_byte(-1)
	write_byte(3)
	write_byte(1)
	write_byte(CSW_HEGRENADE)
	write_byte(24)
	message_end()			
	
	return HAM_HANDLED		
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id) ) return;
	
	if( !ghadArc[id] ) return;
		
	set_pev(id, pev_viewmodel2, WeaponModel[0])
	set_pev(id, pev_weaponmodel2, WeaponModel[1])
}

public Event_NewRound()
{
	fm_remove_entity_name(VOLET_CLASSNAME)
}

public eventCurWeapon(id)
{
	if( !gArced[id] ) return PLUGIN_CONTINUE;
	fm_set_user_maxspeed(id, 83.0);
	return PLUGIN_CONTINUE;
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
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
	write_byte(1)
	message_end()
}

stock create_beam_follow(ent)
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_BEAMFOLLOW);
	write_short(ent);
	write_short(smoke);
	write_byte(5); // life
	write_byte(1); // width
	write_byte(56); // r
	write_byte(169); // g
	write_byte(255); // b
	write_byte(235); // brightness
	message_end();
}

stock makeScreenFade(id, const time=12, const r=255, const g=255, const b=255, const alpha=250)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
	write_short(1<<time); // Duration --> Note: Duration and HoldTime is in special units. 1 second is equal to (1<<12) i.e. 4096 units.
	write_short(1<<11); // Holdtime
	write_short(0x0000); // 0x0001 Fade in
	write_byte(r);
	write_byte(g);
	write_byte(b);
	write_byte(alpha);  // Alpha
	message_end();
}


// stock fm_remove_entity_name(const classname[]) {
// 	new ent = -1, num = 0;
// 	while ((ent = fm_find_ent_by_class(ent, classname)))
// 		num += fm_remove_entity(ent);

// 	return num;
// }

// stock fm_give_item(index, const item[]) {
// 	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
// 		return 0;

// 	new ent = fm_create_entity(item);
// 	if (!pev_valid(ent))
// 		return 0;

// 	new Float:origin[3];
// 	pev(index, pev_origin, origin);
// 	set_pev(ent, pev_origin, origin);
// 	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
// 	dllfunc(DLLFunc_Spawn, ent);

// 	new save = pev(ent, pev_solid);
// 	dllfunc(DLLFunc_Touch, ent, index);
// 	if (pev(ent, pev_solid) != save)
// 		return ent;

// 	engfunc(EngFunc_RemoveEntity, ent);

// 	return -1;
// }