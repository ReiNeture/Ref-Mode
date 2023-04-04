#include <amxmodx>
#include <fakemeta>
#include <xs>
new const modelname[] = "models/circles3.mdl"

public plugin_init()
{
	register_plugin("Test Entity Model", "1.0", "Reff")
    register_forward(FM_Think, "fw_Think")
	// register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_clcmd("summon", "summon_entity")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, modelname)
}

public summon_entity(id)
{
		new circle = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(circle, pev_movetype, MOVETYPE_FLY)
		set_pev(circle, pev_owner, id)
		set_pev(circle, pev_classname, "ball")
		set_pev(circle, pev_solid, SOLID_NOT)
		// set_pev(circle, pev_aiment, id)

		new Float:circle_origin[3]
	get_random_groundposition(id, circle_origin)

		// pev(id, pev_origin, circle_origin)
		set_pev(circle, pev_origin, circle_origin)
		engfunc(EngFunc_SetModel, circle, modelname)
    	// set_pev(circle, pev_nextthink, get_gametime() + 1.0)
}

public fw_Think(ent)
{
	if(!pev_valid(ent) ) return FMRES_IGNORED

	static classname[32]
	pev(ent, pev_classname, classname, sizeof(classname))

	if( equal(classname, "ball") ) {
		engfunc(EngFunc_RemoveEntity, ent)
		// static id
		// id = pev(ent, pev_owner)

		// static Float:v_angles[3], Float:oriugi[3]
		// pev(id, pev_v_angle, v_angles)
		// get_position(id, 100.0, 0.0, 0.0, oriugi)
		// v_angles[0] *= -1.0
		// set_pev(ent, pev_angles, v_angles)
		// set_pev(ent, pev_origin, oriugi)
		// set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	}
	return FMRES_IGNORED
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock get_random_groundposition(id, Float:vecOut[3])
{
	new Float:fStart[3], Float:fEnd[3], Float:EndPos2[3]

	pev(id, pev_origin, fStart)
	fStart[0] += random_float(-1000.0, 1000.0)
	fStart[1] += random_float(-1000.0, 1000.0)
	fStart[2] -= 15.0

	xs_vec_copy(fStart, fEnd)
	fEnd[2] = -9999.9

	new tr = create_tr2()
	engfunc(EngFunc_TraceLine, fStart, fEnd, 0, id, tr)
	get_tr2(tr, TR_vecEndPos, EndPos2)

	xs_vec_copy(EndPos2, vecOut)
}