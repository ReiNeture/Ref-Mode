#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <vector>
#include <engine>

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define weapon_gas "weapon_smokegrenade"
#define GAS_SECRETCODE 66772

#define GAS_DAMAGE 430.0
#define GAS_TIME 25.0
#define GAS_DAMAGE_REPEAT 1.0

new const WeaponModel[3][] =
{
	"models/ref/v_gasgrenade.mdl",
	"models/ref/p_gasgrenade.mdl",
	"models/ref/w_gasgrenade.mdl"
}

new const WeaponSound[5][] = 
{
	"ref/gas_exp2.wav",
	"ref/cough1.wav",
	"ref/cough2.wav",
	"ref/cough3.wav",
	"ref/gas_throw.wav"
}

new const WeaponSprite[3][] =
{
	"sprites/ref/gas_puff_01g.spr",
	"sprites/ref/gbomb.spr",
	"sprites/ref/bflare.spr"
}

new const GasClass[] = "ref_gas";
new const GasEmitterClass[] = "r_gasemit";

const PDATA_SAFE = 2;
const OFFSET_LINUX_WEAPONS = 4;
const OFFSET_WEAPONOWNER = 41;

new gas, bomb, flare;
new const secret_code = pev_iuser1;

new bool:ghadGas[33];
new bool:gEnableEmit[33];

public plugin_init()
{
	register_plugin("Gas Grenade", "1.0", "Reff");
	
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_Touch, "fw_Touch");
	register_think(GasClass, "fw_Think");

	register_forward(FM_EmitSound, "fw_EmitSound");

	RegisterHam(Ham_Item_Deploy, weapon_gas, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	
	register_clcmd("weapon_gas", "hook_weapon");
	register_clcmd("gas", "get_gas", ADMIN_KICK);
}

public plugin_precache()
{
	new i;
	for(i = 0; i < sizeof(WeaponModel); i++)
		engfunc(EngFunc_PrecacheModel, WeaponModel[i]);
	for(i = 0; i < sizeof(WeaponSound); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSound[i]);

	gas = engfunc(EngFunc_PrecacheModel, WeaponSprite[0]);
	bomb = engfunc(EngFunc_PrecacheModel, WeaponSprite[1]);
	flare = engfunc(EngFunc_PrecacheModel, WeaponSprite[2]);
}

public plugin_natives()
{ 
	register_native("get_gas_grenade", "get_gas", 1);
	register_native("set_gas_emitter", "switchFunction", 1);
}

public get_gas(id)
{
	if(!is_user_alive(id) ) return;
		
	ghadGas[id] = true;
	fm_give_item(id, weapon_gas);
}

public hook_weapon(id)
{
	client_cmd(id, weapon_gas);
	return PLUGIN_HANDLED;
}

public fw_SetModel(ent, const Model[])
{
	if(!pev_valid(ent) ) return FMRES_IGNORED
		
	static Classname[32];
	pev(ent, pev_classname, Classname, sizeof(Classname) );

	if(equal(Model, "models/w_smokegrenade.mdl") )
	{
		static id; id = pev(ent, pev_owner);

		if( ghadGas[id] )
		{
			ghadGas[id] = false;
			engfunc(EngFunc_SetModel, ent, WeaponModel[2]);
			set_pev(ent, secret_code, GAS_SECRETCODE);

			emit_sound(ent, CHAN_WEAPON, WeaponSound[4], 1.0, ATTN_NORM, 0, PITCH_NORM);
			return FMRES_SUPERCEDE;
		}

	}
	return FMRES_IGNORED;
}

public fw_EmitSound(ent, iChannel, const szSample[], Float:fVol, Float:fAttn, iFlags, iPitch)
{
	static const szSmokeSound[] = "weapons/sg_explode.wav";

	if(!equal(szSample, szSmokeSound ) ) return FMRES_IGNORED;
	if(pev(ent, secret_code) != GAS_SECRETCODE ) return FMRES_IGNORED;

	new Float:vOrigin[3];
	pev(ent, pev_origin, vOrigin);
	new id = pev(ent, pev_owner);

	set_pev(ent, pev_origin, Float:{ 9999.9, 9999.9, 9999.9 });
	set_pev(ent, pev_flags, FL_KILLME);

	createGasSmoke(id, vOrigin);
	create_explosion_spr(vOrigin);
	create_sprite_trail(vOrigin);

	return FMRES_IGNORED;
}

createGasEmitter(id)
{
	new emitter = fm_create_entity("info_target");
	if( !pev_valid(emitter) ) return;

	new Float:fOrigin[3], Float:velocity[3];

	pev(id, pev_origin, fOrigin);
	get_weapon_position(id, fOrigin, 7.0, 15.0, 3.0);

	set_pev(emitter, pev_classname, GasEmitterClass);
	set_pev(emitter, pev_movetype, MOVETYPE_TOSS);
	set_pev(emitter, pev_solid, SOLID_TRIGGER);
	set_pev(emitter, pev_origin, fOrigin);
	set_pev(emitter, pev_owner, id);

	velocity_by_aim(id, 1500, velocity);
	set_pev(emitter, pev_velocity, velocity);

	engfunc(EngFunc_SetModel, emitter, WeaponModel[2]);
	engfunc(EngFunc_SetSize, emitter, Float:{-10.0, -10.0, -10.0}, Float:{10.0, 10.0, 10.0} );

	emit_sound(emitter, CHAN_WEAPON, WeaponSound[4], 1.0, ATTN_NORM, 0, PITCH_NORM);
}

createGasEmitterSmoke(id, const Float:vOrigin[3])
{
	new gase = fm_create_entity("info_target");
	if( !pev_valid(gase) ) return;

	set_pev(gase, pev_classname, GasClass);
	set_pev(gase, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(gase, pev_solid, SOLID_TRIGGER);
	set_pev(gase, pev_origin, vOrigin);
	set_pev(gase, pev_owner, id);
	set_pev(gase, pev_sequence, 1);
	set_pev(gase, pev_fuser1, get_gametime() - (GAS_TIME-4.0) );
	engfunc(EngFunc_SetSize, gase, Float:{ -150.0, -150.0, -20.0}, Float:{150.0, 150.0, 150.0} );

	set_pev(gase, pev_nextthink, get_gametime() + 0.05);
	emit_sound(gase, CHAN_STATIC, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM); 
}

createGasSmoke(id, const Float:vOrigin[3])
{
	new gase = fm_create_entity("info_target");
	if( !pev_valid(gase) ) return;

	set_pev(gase, pev_classname, GasClass);
	set_pev(gase, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(gase, pev_solid, SOLID_TRIGGER);
	set_pev(gase, pev_origin, vOrigin);
	set_pev(gase, pev_owner, id);
	set_pev(gase, pev_sequence, 1);
	set_pev(gase, pev_fuser1, get_gametime());

	engfunc(EngFunc_SetModel, gase, WeaponModel[2]);
	engfunc(EngFunc_SetSize, gase, Float:{ -150.0, -150.0, -20.0}, Float:{150.0, 150.0, 150.0} );

	set_pev(gase, pev_nextthink, get_gametime() + 0.05);
	emit_sound(gase, CHAN_STATIC, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM); 
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr) ) return FMRES_IGNORED;

	static classname[32], owner;
	pev(ptr, pev_classname, classname, 31);
	
	if (equal(classname, GasClass) ) {
	
		static Float:poisonTime[33];
		if ((1 <= ptd <= 32) && is_user_alive(ptd) ) {

			owner = pev(ptr, pev_owner);
			if( owner == ptd ) return FMRES_IGNORED;

			if( get_gametime() >= poisonTime[ptd] ) {
				if( get_user_team(owner) != get_user_team(ptd) )
					ExecuteHam(Ham_TakeDamage, ptd, ptr, owner, GAS_DAMAGE, DMG_PARALYZE);
				else
					ExecuteHam(Ham_TakeDamage, ptd, ptr, owner, 40.0, DMG_PARALYZE);

				makeScreenFade(ptd, 12, 103, 138, 85, 175);
				emit_sound(ptd, CHAN_STATIC, WeaponSound[random_num(1,3)], 1.0, ATTN_NORM, 0, PITCH_NORM);

				poisonTime[ptd] = get_gametime() + GAS_DAMAGE_REPEAT;
			}
		}
	}

	if( equal(classname, GasEmitterClass) ) {

		pev(ptd, pev_classname, classname, 31);
		owner = pev(ptr, pev_owner);

		if( !equal(classname, GasEmitterClass) && ptd != owner ) {

			new Float:vOrigin[3];
			pev(ptr, pev_origin, vOrigin);

			createGasEmitterSmoke(owner, vOrigin);
			create_explosion_spr(vOrigin);
			create_sprite_trail(vOrigin);
			engfunc(EngFunc_RemoveEntity, ptr);
		}
	}

	return FMRES_IGNORED;
}

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED;
	
	static Float:vOrigin[3], Float:gameTime;
	gameTime = get_gametime();

	if( gameTime >= pev(ent, pev_fuser1) + GAS_TIME ) {
		engfunc(EngFunc_RemoveEntity, ent)
		return FMRES_IGNORED;
	}

	pev(ent, pev_origin, vOrigin);
	create_smoke_firefield(vOrigin);
	set_pev(ent, pev_nextthink, get_gametime() + 1.0);

	return FMRES_IGNORED;
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent);
	if (!pev_valid(id) ) return;
	
	if( !ghadGas[id] ) return;
		
	set_pev(id, pev_viewmodel2, WeaponModel[0]);
	set_pev(id, pev_weaponmodel2, WeaponModel[1]);
}

public fw_TraceAttack(this, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if (!is_user_alive(id) || damagebits == DMG_GENERIC ) return HAM_IGNORED;

	static Float:coldTime[33];
	if( random_num(1, 100) <= 5 ) {

		if( gEnableEmit[id] && get_gametime() >= coldTime[id]) {
			
			createGasEmitter(id);
			coldTime[id] = get_gametime() + 3.0;
		}
	}

	return HAM_IGNORED;
}

public switchFunction(id)
{
    gEnableEmit[id] ^= true;
}

public client_putinserver(id)
{
	gEnableEmit[id] = false;
}

public client_disconnected(id)
{
	gEnableEmit[id] = false;
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock get_weapon_position(id, Float:fOrigin[], Float:add_forward = 0.0, Float:add_right = 0.0, Float:add_up = 0.0)
{
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3]
	static Float:Forward[3], Float:Right[3], Float:Up[3]
	
	pev(id, pev_v_angle, vAngles)
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, ViewOfs)
	xs_vec_add(fOrigin, ViewOfs, fOrigin)
	
	pev(id, pev_angles, Angles)
	
	Angles[0] = vAngles[0]
	
	engfunc(EngFunc_MakeVectors, Angles)
	
	global_get(glb_v_forward, Forward)
	global_get(glb_v_right, Right)
	global_get(glb_v_up, Up)
	
	xs_vec_mul_scalar(Forward, add_forward, Forward)
	xs_vec_mul_scalar(Right, add_right, Right)
	xs_vec_mul_scalar(Up, add_up, Up)
	
	fOrigin[0] = fOrigin[0] + Forward[0] + Right[0] + Up[0]
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1]
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2]
}

stock create_smoke_firefield(const Float:vOrigin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_FIREFIELD);
	engfunc(EngFunc_WriteCoord, vOrigin[0] );
	engfunc(EngFunc_WriteCoord, vOrigin[1] );
	engfunc(EngFunc_WriteCoord, vOrigin[2] );
	write_short(150);
	write_short(gas);
	write_byte(100);
	write_byte(TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT);
	write_byte(10);
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
	engfunc(EngFunc_WriteCoord, vOrigin[2]+10.0);
	write_short(flare);
	write_byte(30);
	write_byte(5);
	write_byte(5);
	write_byte(30);
	write_byte(10);
	message_end();

}

stock create_explosion_spr(const Float:vOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vOrigin[0]);
	engfunc(EngFunc_WriteCoord, vOrigin[1]);
	engfunc(EngFunc_WriteCoord, vOrigin[2]);
	write_short(bomb);
	write_byte(6);
	write_byte(15);
	write_byte(TE_EXPLFLAG_NONE | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
	message_end();

}

stock makeScreenFade(id, const time=12, const r=255, const g=255, const b=255, const alpha=255)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), {0.0, 0.0, 0.0}, id);
	write_short(1<<time);
	write_short(1<<12);
	write_short(0x0000);
	write_byte(r);
	write_byte(g);
	write_byte(b);
	write_byte(alpha);
	message_end();

}