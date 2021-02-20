#include <amxmodx>
#include <hamsandwich>
#include <d2lod>
#include <fakemeta>

new PLUGIN_NAME[] = "毒性傷害"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"
new const TASKID_POISON = 17000;
new Skill_Level = 77;

new const Float:DmgDagPoison[MAX_P_SKILLS] =  // Poison dagger damage %.
{
	8.0, 14.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 65.0, 70.0, 75.0, 80.0, 85.0, 90.0, 95.0, 100.0, 115.0
};

new g_SkillId;

// new bool: g_IsPoisonDagger[33];
new g_iCurSkill[33];

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	RegisterHam(Ham_TakeDamage, "func_wall", "fwd_PlayerDamaged");
	RegisterHam(Ham_TakeDamage, "player", "fwd_PlayerDamaged");
	RegisterHam(Ham_Killed, "func_wall", "fw_PlayerKilled", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1);

	g_SkillId = register_d2_skill(PLUGIN_NAME, "讓你的刀有毒性", MAKO, Skill_Level, DISPLAY)
}

public fwd_PlayerDamaged(victim, inflictor, attacker, Float:damage, damagebits)
{
	if( !pev_valid(victim) ) return HAM_IGNORED;
	if( g_iCurSkill[attacker] != g_SkillId || get_p_hero(attacker) != MAKO || get_p_skill(attacker, g_SkillId ) <= 0 ) return HAM_IGNORED;
	if( get_p_mana(attacker) < 13 || victim == attacker && IsPlayerNearByMonster(victim) && is_p_protected(victim) ) return HAM_IGNORED;

	new dmg[2];
	dmg[0] = attacker;
	dmg[1] = floatround( ( damage / 100.0 ) * DmgDagPoison[ get_p_skill( attacker, g_SkillId ) - 1 ] );
	
	if( !pev(victim, pev_iuser4) ) {
		set_pev(victim, pev_iuser4, 1);
		fm_set_user_rendering(victim, kRenderFxGlowShell, 0, 245, 0, kRenderNormal, 100)
		set_task( 0.5, "Start_poison_damage", victim + TASKID_POISON, dmg, sizeof dmg, "b");
		set_task( 1.5, "End_poison_damage", victim);
		set_p_mana(attacker , get_p_mana(attacker) - 13);
	}
	return HAM_HANDLED;
}

public Start_poison_damage(Param[], victim)
{
	victim = victim - TASKID_POISON;
	if( !pev_valid(victim)) {
		End_poison_damage(victim);
		return;
	}

	new name[32];
	pev(victim, pev_classname, name, charsmax(name));
	new attack = Param[0];
	new Float:Damage = float(Param[1]);

	if( equal( name, "func_wall") || is_user_alive(victim) ) {
		ExecuteHam(Ham_TakeDamage, victim, attack, attack, Damage, DMG_ENERGYBEAM);
	}
}

public End_poison_damage(victim)
{
	if ( task_exists( victim + TASKID_POISON ) )
	{
		set_pev(victim, pev_iuser4, 0);
		fm_set_user_rendering(victim);
		remove_task( victim + TASKID_POISON );
	}
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	End_poison_damage(victim);
}

public client_disconnect(id)
{
}

public d2_skill_selected(id, skill_id)
{
	g_iCurSkill[id] = skill_id;
}

public d2_skill_fired(id)
{

}

public d2_logged(id, log_type)
{
	if ( log_type == UNLOGGED )
	{
		
	}
}
// public d2_dagger_poisondamage(victim, attacker, Float:iDamage[1])
// {
// 	if ( get_p_hero(attacker) == COMBAT && get_p_skill( attacker, g_SkillId ) > 0 && get_p_mana(attacker) >= Mana_PoisonDagger )
// 	{
// 		iDamage[0] = iDamage[0] + ( ( iDamage[0] / 100.0 ) * DmgDagPoison[ get_p_skill( attacker, g_SkillId ) - 1 ] );

// 		set_p_mana(attacker, get_p_mana(attacker) - Mana_PoisonDagger );
// 	}
// }

stock fm_set_user_rendering(index, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
	return fm_set_rendering(index, fx, r, g, b, render, amount);
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}