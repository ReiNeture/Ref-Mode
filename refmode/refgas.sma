#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define weapon_gas "weapon_smokegrenade"
#define GAS_SECRETCODE 66772

#define GAS_DAMAGE 780.0
#define GAS_TIME 18.0
#define GAS_DAMAGE_REPEAT 0.9

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

new const gasClass[] = "ref_gas";

const PDATA_SAFE = 2;
const OFFSET_LINUX_WEAPONS = 4;
const OFFSET_WEAPONOWNER = 41;

new gas, bomb, flare;
new const secret_code = pev_iuser1;

new bool:ghadGas[33];

public plugin_init()
{
	register_plugin("Gas Grenade", "1.0", "Reff");
	
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_Touch, "fw_Touch");
	register_forward(FM_Think, "fw_Think");
	register_forward(FM_EmitSound, "fw_EmitSound");

	RegisterHam(Ham_Item_Deploy, weapon_gas, "fw_Item_Deploy_Post", 1);
	
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

	emit_sound(ent, CHAN_STATIC, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM); 
	set_pev(ent, pev_origin, Float:{ 9999.9, 9999.9, 9999.9 });
	set_pev(ent, pev_flags, FL_KILLME);

	createGasSmoke(id, vOrigin);

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

	return FMRES_IGNORED;
}

createGasSmoke(id, const Float:vOrigin[3])
{
	new gase = fm_create_entity("info_target");
	if( !pev_valid(gase) ) return;

	set_pev(gase, pev_classname, gasClass);
	set_pev(gase, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(gase, pev_solid, SOLID_TRIGGER);
	set_pev(gase, pev_origin, vOrigin);
	set_pev(gase, pev_owner, id);
	set_pev(gase, pev_sequence, 1);
	set_pev(gase, pev_fuser1, get_gametime());

	engfunc(EngFunc_SetModel, gase, WeaponModel[2]);
	engfunc(EngFunc_SetSize, gase, Float:{ -150.0, -150.0, -20.0}, Float:{150.0, 150.0, 150.0} );

	set_pev(gase, pev_nextthink, get_gametime() + 0.05);
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr) ) return FMRES_IGNORED;

	static classname[32];
	pev(ptr, pev_classname, classname, 31);
	
	if (!equal(classname, gasClass))
		return FMRES_IGNORED;
	
	static Float:poisonTime[33], owner;
	if ((1 <= ptd <= 32) && is_user_alive(ptd) ) {

		owner = pev(ptr, pev_owner);
		if( owner == ptd ) return FMRES_IGNORED;

		if( get_gametime() >= poisonTime[ptd] ) {
			if( get_user_team(owner) != get_user_team(ptd) )
				ExecuteHam(Ham_TakeDamage, ptd, owner, owner, GAS_DAMAGE, DMG_PARALYZE);
			else
				ExecuteHam(Ham_TakeDamage, ptd, owner, owner, 40.0, DMG_PARALYZE);

			makeScreenFade(ptd, 12, 103, 138, 85, 175);
			emit_sound(ptd, CHAN_STATIC, WeaponSound[random_num(1,3)], 1.0, ATTN_NORM, 0, PITCH_NORM);

			poisonTime[ptd] = get_gametime() + GAS_DAMAGE_REPEAT;
		}
	}

	return FMRES_IGNORED;
}

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED;
	
	static Classname[32], Float:vOrigin[3], Float:gameTime;
	pev(ent, pev_classname, Classname, sizeof(Classname) )

	if( equal(Classname, gasClass) ) {

		gameTime = get_gametime();
		if( gameTime >= pev(ent, pev_fuser1) + GAS_TIME ) {
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_IGNORED;
		}

		pev(ent, pev_origin, vOrigin);
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_FIREFIELD);
		engfunc(EngFunc_WriteCoord, vOrigin[0] );
		engfunc(EngFunc_WriteCoord, vOrigin[1] );
		engfunc(EngFunc_WriteCoord, vOrigin[2] );
		write_short(150);
		write_short(gas);
		write_byte(70);
		write_byte(TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT);
		write_byte(10);
		message_end();

		set_pev(ent, pev_nextthink, get_gametime() + 1.0);
	}

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

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
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