#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define weapon_arc "weapon_hegrenade"
#define ARC_SECRETCODE 98983

#define ARC_RADIUS 275.0
#define ARC_DAMAGE 5000.0
#define ARC_DMGTIME 2.5

new const touch_time = pev_fuser1
new const secret_code = pev_iuser1

new const WeaponModel[2][] =
{
	"models/ref/v_arcstar.mdl",
	"models/ref/w_arcstar.mdl"
}

new const WeaponSound[3][] = 
{
	"ref/arc_explode.wav",
	"ref/arc_down.wav",
	"ref/arc_throw.wav"
}

new const WeaponRes[2][] =
{
	"sprites/ref/muzzleflash67.spr",
	"sprites/ref/muzzleflash81.spr"
}

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41

new const VOLET_CLASSNAME[] = "volets"

new arc_explode
new gMaxPlayers

new bool:ghadArc[33]

public plugin_init()
{
	register_plugin("Arc Star", "1.0", "Reff")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_Think, "fw_Think");

	RegisterHam(Ham_Item_AddToPlayer, weapon_arc, "fw_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_Deploy, weapon_arc, "fw_Item_Deploy_Post", 1)
	
	gMaxPlayers = get_maxplayers()
	register_clcmd("weapon_holybomb", "hook_weapon")
	register_clcmd("arc", "get_arc", ADMIN_KICK)
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

public hook_weapon(id)
{
	client_cmd(id, weapon_arc)
	return PLUGIN_HANDLED
}

public fw_SetModel(ent, const Model[])
{
	if(!pev_valid(ent) ) return FMRES_IGNORED
		
	static Classname[32]; pev(ent, pev_classname, Classname, sizeof(Classname))
	if(equal(Model, "models/w_hegrenade.mdl"))
	{
		static id; id = pev(ent, pev_owner)
		static Float:velocity[3];
		velocity_by_aim(id, 1500, velocity);

		if( ghadArc[id] )
		{
			engfunc(EngFunc_SetModel, ent, WeaponModel[1])
			
			set_pev(ent, secret_code, ARC_SECRETCODE)
			set_pev(ent, pev_dmgtime, 9999999.0)
			set_pev(ent, touch_time, 9999999.0)
			set_pev(ent, pev_velocity, velocity)
			set_pev(ent, pev_gravity, 0.4)

			ghadArc[id] = false
			emit_sound(ent, CHAN_STATIC, WeaponSound[2], 1.0, ATTN_NORM, 0, PITCH_NORM);
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED	
}

public fw_Touch(toucher, touched)
{
	if(!pev_valid(toucher) ) return;
		
	static Classname[32]; pev(toucher, pev_classname, Classname, sizeof(Classname))
	if(equal(Classname, "grenade"))
	{
		if(pev(toucher, secret_code) != ARC_SECRETCODE)
			return;
			
		set_pev(toucher, touch_time, get_gametime());
		set_pev(toucher, pev_velocity, {0.0, 0.0, 0.0} )

		if( is_user_alive(touched) ) {
			set_pev(toucher, pev_aiment, touched)
			set_pev(toucher, pev_movetype, MOVETYPE_FOLLOW)
			set_pev(toucher, pev_iuser3, touched)
		}
		else
			set_pev(toucher, pev_movetype, MOVETYPE_NONE)
		

		new aim = createVolet()
		set_pev(aim, pev_aiment, toucher);
		set_pev(aim, touch_time, get_gametime());

		emit_sound(toucher, CHAN_WEAPON, WeaponSound[1], 1.0, ATTN_NORM, 0, PITCH_NORM);
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

		static Float:dmgTime;
		pev(ent, touch_time, dmgTime)
		if( get_gametime() >= dmgTime + ARC_DMGTIME ) {

			new Float:fOrigin[3]
			pev(ent, pev_origin, fOrigin)

			makeArcExplode(ent, fOrigin);
			return FMRES_HANDLED;
		}

		// static touched; touched = pev(ent, pev_iuser3)
		// if( touched && !is_user_alive(touched) ) {
		// 	removeArcStar(ent)
		// 	return FMRES_HANDLED;
		// }
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	}

	return FMRES_IGNORED;
}

makeArcExplode(ent, const Float:fOrigin[3])
{

	static Owner; Owner = pev(ent, pev_owner)
	static Float:PlayerOrigin[3]

	emit_sound(ent, CHAN_WEAPON, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
	engfunc(EngFunc_RemoveEntity, ent);

	for(new i = 0; i < gMaxPlayers; i++)
	{
		if(!is_user_alive(i) ) continue;

		pev(i, pev_origin, PlayerOrigin)
		if(get_distance_f(fOrigin, PlayerOrigin) > ARC_RADIUS)
			continue
			
		if(!is_user_connected(Owner) ) Owner = i

		ExecuteHam(Ham_TakeDamage, i, "Arc Star", Owner, ARC_DAMAGE, DMG_SONIC)
	}

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

// removeArcStar(ent)
// {
// 	new aiment = pev(ent, pev_iuser2);
// 	engfunc(EngFunc_RemoveEntity, aiment);
// 	engfunc(EngFunc_RemoveEntity, ent);
// }

createVolet()
{
	new ent = fm_create_entity("env_sprite");
	set_pev(ent, pev_classname, VOLET_CLASSNAME);

	set_pev(ent, pev_movetype, MOVETYPE_FOLLOW);
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

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
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