#include <amxmodx>
#include <d2lod>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

new PLUGIN_NAME[] = "魔靈彈"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

new Skill_Level = 43;
new Mana_FireBolt = 7;

new const SorcFireCast[] = "d2lod/firecast.wav";
new const WerewolfSpr[] = "sprites/xfire2.spr";
new const FireCast[] = "sprites/ion_laserflame.spr";
// new const FireCast[] = "sprites/rjet1.spr";

new const Float:FireBoltDamage[MAX_P_SKILLS] =  // 術士火球傷害值.
{
	28.0, 30.0, 35.0, 38.0, 42.0, 45.0, 50.0, 53.0, 55.0, 58.0, 64.0, 70.0, 	75.0, 78.0, 82.0, 85.0, 90.0, 95.0, 100.0, 150.0
};

new g_SkillId;

new g_iCurSkill[33];
new Float:g_LastPressedSkill[33];

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	g_SkillId = register_d2_skill(PLUGIN_NAME, "傷害隨魔力能力提升", SPELLS, Skill_Level, DISPLAY)

	register_forward(FM_Touch, "Entity_Touched");
}

public plugin_precache()
{
	precache_sound( SorcFireCast );
	precache_model( WerewolfSpr );
	precache_model( FireCast ); 
}

public d2_skill_selected(id, skill_id)
{
	g_iCurSkill[id] = skill_id;
}

public d2_skill_fired(id)
{
	if ( g_iCurSkill[id] == g_SkillId )
	{
		static Float:cdown;
		cdown = 0.1;

		if (get_gametime() - g_LastPressedSkill[id] <= cdown) 
		{
			return PLUGIN_HANDLED;
		}
		else if ( get_gametime() - g_LastPressedSkill[id] >= cdown )
		{
			g_LastPressedSkill[id] = get_gametime()
		}

		if ( get_p_skill( id, g_SkillId ) > 0 && get_p_mana(id) >= Mana_FireBolt )
		{
			emit_sound(id, CHAN_ITEM, SorcFireCast, 1.0, ATTN_NORM, 0, PITCH_NORM);

			set_p_mana( id, get_p_mana(id) - Mana_FireBolt);

			Set_Sprite_FireBolt(id, FireCast, 50.0, 0.4, "FireBolt");

			Set_Sprite_Task(id, WerewolfSpr, 2.5, 1, 0.8, "Morph");
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Entity_Touched(ent, victim)
{
	if ( !pev_valid(ent) ) return;
	
	new classname[32]
	pev( ent, pev_classname, classname, 31)

	new attacker = entity_get_edict(ent, EV_ENT_owner);
	
	if(equal(classname,"FireBolt")) 
	{ 
		new rate = 1;
		if(get_p_manaskill(attacker) >= 50) rate = get_p_manaskill(attacker)/50;

		new Float:Damage = FireBoltDamage[get_p_skill( attacker, g_SkillId ) - 1] * float(rate)
		if( is_user_alive(victim) ) {

			if ( victim != attacker && !IsPlayerNearByMonster(victim) && !is_p_protected(victim) && get_p_skill( attacker, g_SkillId ) > 0 )
				dmg_kill_player(victim, attacker, Damage, "FireBolt");

		} else {

			if( get_p_skill( attacker, g_SkillId ) > 0 )
				ExecuteHam(Ham_TakeDamage, victim, victim, attacker, Damage, DMG_ENERGYBEAM);
		}	
		set_pev( ent, pev_flags, FL_KILLME);
	}
}
public d2_takedamage(victim, attacker, Float:iDamage[1])
{

}

public Set_Sprite_Task(id, const sprite[], Float:scale, istask, Float:task_time, const classname[])
{
	new sprite_ent = create_entity("env_sprite")

	entity_set_string(sprite_ent, EV_SZ_classname, classname)
	entity_set_int(sprite_ent, EV_INT_movetype, MOVETYPE_FOLLOW)
	entity_set_edict(sprite_ent, EV_ENT_aiment, id );
	entity_set_model(sprite_ent, sprite)

	entity_set_int( sprite_ent, EV_INT_rendermode, kRenderTransAdd)
	entity_set_float( sprite_ent, EV_FL_renderamt, 200.0 )
    
	entity_set_float( sprite_ent, EV_FL_framerate, 22.0 )
	entity_set_float( sprite_ent, EV_FL_scale, scale )
	entity_set_int( sprite_ent, EV_INT_spawnflags, SF_SPRITE_STARTON)
	DispatchSpawn( sprite_ent )

	if ( istask )
	{
		set_task(task_time, "End_Sprite_Task", sprite_ent);
	}
}
public End_Sprite_Task(sprite_ent)
{
	if ( is_valid_ent(sprite_ent) )
	{
		remove_entity(sprite_ent);
	}
}
public Set_Sprite_FireBolt(id, const sprite[], Float:framerate, Float:scale, const classname[])
{
	new sprite_ent = create_entity("env_sprite")

	entity_set_string( sprite_ent, EV_SZ_classname, classname)
	entity_set_model( sprite_ent, sprite);

	entity_set_edict( sprite_ent, EV_ENT_owner, id)

	entity_set_size( sprite_ent, Float:{-1.1, -1.1, -1.1}, Float:{1.1, 1.1, 1.1})

	entity_set_int( sprite_ent, EV_INT_rendermode, kRenderTransAdd)
	entity_set_float( sprite_ent, EV_FL_renderamt, 200.0 )
    
	entity_set_float( sprite_ent, EV_FL_framerate, framerate )
	entity_set_float( sprite_ent, EV_FL_scale, scale )

	DispatchSpawn(sprite_ent);
	entity_set_int( sprite_ent, EV_INT_spawnflags, SF_SPRITE_STARTON)

	entity_set_int( sprite_ent, EV_INT_solid, SOLID_BBOX)
	entity_set_int( sprite_ent, EV_INT_movetype, MOVETYPE_FLYMISSILE)

	new Float:fAim[3],Float:fAngles[3],Float:fOrigin[3];

	velocity_by_aim(id,32,fAim)
	vector_to_angle(fAim,fAngles)
	entity_get_vector( id, EV_VEC_origin, fOrigin)
	
	fOrigin[0] += fAim[0]
	fOrigin[1] += fAim[1]
	fOrigin[2] += fAim[2] + 25.0
	
	entity_set_vector( sprite_ent, EV_VEC_origin, fOrigin)
	entity_set_vector( sprite_ent, EV_VEC_angles, fAngles)
	
	new Float:fVel[3]
	velocity_by_aim(id, 900, fVel)	

	entity_set_vector( sprite_ent, EV_VEC_velocity, fVel)
}