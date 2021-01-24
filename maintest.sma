#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>

new const ifire_range[] = {0,2000,300}
//new const doulbe:fDamage[] = {0.0,33.0,1000.0}
new mode_switch[33] = {0}

new smoke
new exp
new beam

public plugin_init()
{
	register_plugin("Yamato410", "1.0", "KuroNeko" )

	register_clcmd("per_bullet", "per_buller")
	register_clcmd("hibiki_menu","hibiki_switch_menu")

	register_touch( "Yamato", "*", "cqc")
	register_touch( "Torpedo", "player", "tpt")
	register_touch( "Yuzo", "*", "exe")
	register_touch( "Egg", "*", "ege")

	register_cvar("yamato_explore_range", "150")
	register_cvar("yamato_deviation_max", "30")
	register_cvar("yamato_damage", "27")
}
public plugin_precache()
{
	precache_model("models/head.mdl");
	precache_model("models/lv_bottle.mdl");
	smoke = precache_model("sprites/steam1.spr");
	exp = precache_model("sprites/fexplo.spr");
	beam = precache_model("sprites/plasma_beam.spr")
	precache_sound("weapons/bomb.wav");
	precache_sound("weapons/star.wav");
	precache_sound("weapons/clipin.wav");
	precache_sound("classic.wav");
}
public hibiki_switch_menu(id)
{
	new menu = menu_create("\y看\r偽戀", "war_menu")
	new itemname[64], data[2]

	format(itemname, 63, "%s410mm三連裝主砲(HE)",mode_switch[id]==1?"\r":"\w")
	data[0] = 1 ; data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	format(itemname, 63, "%s微型快動式詭雷",mode_switch[id]==2?"\r":"\w")
	data[0] = 2 ; data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	format(itemname, 63, "%s幹你娘我瘋了肏(中研院工程師太強拉)",mode_switch[id]==3?"\r":"\w")
	data[0] = 3 ; data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	format(itemname, 63, "%s888888888",mode_switch[id]==4?"\r":"\w")
	data[0] = 4 ; data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_EXITNAME, "離開")
	menu_display(id, menu, 0)
}
public war_menu(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	new data[6], itemname[64], access, callback, key
	menu_item_getinfo(menu, item, access, data,5, itemname, 63, callback)
	key = data[0]

	mode_switch[id] = key
	hibiki_switch_menu(id)

	return PLUGIN_HANDLED
}
public per_buller(id) //可執行指令
{
	static Float:last_check_time[33];
	if (get_gametime() - last_check_time[id] < 0.0)
		return ;
	last_check_time[id] = get_gametime();

	switch(mode_switch[id])
	{
		case 1:{ //410mm三連裝主砲(HE彈)
			set_task(0.1,"mode_410mm",id)
			set_task(0.2,"mode_410mm",id)
			set_task(0.3,"mode_410mm",id)
		}
		case 2:{
			parabola(id, "Torpedo", "models/lv_bottle.mdl")
		}
		case 3:{
			irregular(id)
		}
		case 4:{
			eight(id)
		}
	}
	emit_sound(id, CHAN_VOICE, "weapons/clipin.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public mode_410mm(id)
	parabola(id, "Yamato", "models/head.mdl")

public eight(id)
{
	static const Float:xpis[] = { 300.0, 300.0 , 0.0   , -300.0, -300.0, -300.0, 0.0,   300.0 }
	static const Float:ypis[] = { 0.0,   -300.0, -300.0, -300.0, 0.0,    300.0,  300.0, 300.0 }

	static const Float:xsta[] = { 20.0, 20.0 , 0.0   , -20.0, -20.0, -20.0, 0.0,   20.0 }
	static const Float:ysta[] = { 0.0,   -20.0, -20.0, -20.0, 0.0,    20.0,  20.0, 20.0 }

	for (new i=0 ; i <= 7 ; i++){

		new sprite_ent = create_entity("env_sprite")
		entity_set_string( sprite_ent, EV_SZ_classname, "Egg")
		entity_set_model( sprite_ent, "models/head.mdl");
		entity_set_size( sprite_ent, Float:{-0.7, -0.7, -0.7}, Float:{0.7, 0.7, 0.7})
		entity_set_int( sprite_ent, EV_INT_movetype, MOVETYPE_FLY)
		entity_set_int( sprite_ent, EV_INT_solid, SOLID_BBOX)
		entity_set_edict( sprite_ent, EV_ENT_owner, id)
		set_pev(sprite_ent, pev_iuser1, id)

		new Float:vVelocity[3], Float:vOrigin[3]

		entity_get_vector(id, EV_VEC_origin, vOrigin);
		vOrigin[0] += xsta[i]
		vOrigin[1] += ysta[i]
		//vOrigin[2] = 20
		entity_set_vector(sprite_ent, EV_VEC_origin, vOrigin);

		vVelocity[0] = xpis[i]
		vVelocity[1] = ypis[i]
		vVelocity[2] = 0.0
		set_pev(sprite_ent, pev_velocity, vVelocity)

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(sprite_ent)
		write_short(smoke)
		write_byte(1000)
		write_byte(3)
		write_byte(random_num(0,255))
		write_byte(random_num(0,255))
		write_byte(random_num(0,255))
		write_byte(255)
		message_end()
	}
}
public irregular(id)
{
	new sprite_ent = create_entity("env_sprite")
	entity_set_string( sprite_ent, EV_SZ_classname, "Yuzo")
	entity_set_model( sprite_ent, "models/lv_bottle.mdl");
	entity_set_size( sprite_ent, Float:{-1.5, -1.5, -1.5}, Float:{1.5, 1.5, 1.5})
	entity_set_int( sprite_ent, EV_INT_movetype, MOVETYPE_FLY)
	entity_set_int( sprite_ent, EV_INT_solid, SOLID_BBOX)
	entity_set_edict( sprite_ent, EV_ENT_owner, id)
	set_pev(sprite_ent, pev_iuser1, id)

	new Float:fAim[3],Float:fAngles[3],Float:fOrigin[3];

	velocity_by_aim(id,64,fAim)
	vector_to_angle(fAim,fAngles)
	entity_get_vector( id, EV_VEC_origin, fOrigin)
	
	fOrigin[0] += fAim[0]
	fOrigin[1] += fAim[1]
	fOrigin[2] += fAim[2]

	entity_set_vector( sprite_ent, EV_VEC_origin, fOrigin) //設定位置
	entity_set_vector( sprite_ent, EV_VEC_angles, fAngles) //設定瞄準角度

	new Float:fVel[3]
	velocity_by_aim(id, 2500, fVel)	
	entity_set_vector( sprite_ent, EV_VEC_velocity, fVel) //設定向量(才有移動的動作)
	emit_sound(sprite_ent, CHAN_VOICE, "weapons/star.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(sprite_ent)
	write_short(smoke)
	write_byte(1000000)
	write_byte(3)
	write_byte(random_num(0,255))
	write_byte(random_num(0,255))
	write_byte(random_num(0,255))
	write_byte(255)
	message_end()
}
public parabola(id, const entity_name[], const entity_model[])  // 410mm & torpedo
{
	new sprite_ent = create_entity("env_sprite")
	entity_set_string( sprite_ent, EV_SZ_classname, entity_name)
	entity_set_model( sprite_ent, entity_model);
	entity_set_size( sprite_ent, Float:{-1.5, -1.5, -1.5}, Float:{1.5, 1.5, 1.5})
	entity_set_int( sprite_ent, EV_INT_movetype, MOVETYPE_TOSS)
	entity_set_int( sprite_ent, EV_INT_solid, SOLID_BBOX)
	entity_set_edict( sprite_ent, EV_ENT_owner, id)
	set_pev(sprite_ent, pev_iuser1, id)
	
	new Float:fAim[3],Float:fAngles[3],Float:fOrigin[3];

	velocity_by_aim(id,64,fAim)
	vector_to_angle(fAim,fAngles)
	entity_get_vector( id, EV_VEC_origin, fOrigin)
	
	fOrigin[0] += fAim[0]
	fOrigin[1] += fAim[1]
	fOrigin[2] += fAim[2]+random_float(-30.0,float(get_cvar_num("yamato_deviation_max")))

	entity_set_vector( sprite_ent, EV_VEC_origin, fOrigin) //設定位置
	entity_set_vector( sprite_ent, EV_VEC_angles, fAngles) //設定瞄準角度

	new Float:fVel[3]
	velocity_by_aim(id, ifire_range[mode_switch[id]], fVel)	
	entity_set_vector( sprite_ent, EV_VEC_velocity, fVel) //設定向量(才有移動的動作)
	emit_sound(sprite_ent, CHAN_VOICE, "weapons/star.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(sprite_ent)
	write_short(smoke)
	write_byte(10)
	write_byte(3)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	message_end()
}
public exe(ptr)
{
	if (!pev_valid(ptr))
		return;

	for (new i=1 ; i<= 100 ; i++)
	{ 
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMENTPOINT)
		write_short(ptr)
		write_coord(random_num(-9999,9999))
		write_coord(random_num(-9999,9999)) 
		write_coord(random_num(-9999,9999)) 
		write_short(beam)
		write_byte(3) // framerate
		write_byte(3) // framerate
		write_byte(1000) // life
		write_byte(500)  // width
		write_byte(0)// noise
		write_byte(random_num(1, 255))// r, g, b
		write_byte(random_num(1, 255))// r, g, b
		write_byte(random_num(1, 255))// r, g, b
		write_byte(255)	// brightness
		write_byte(20)	// speed	200
		message_end()
	}
	remove_entity(ptr)
}
public tpt(ptr, ptd) //ptr撞人的 ptd被撞的 詭雷
{
	if (!pev_valid(ptr))
		return;

	new Float:EndOrigin[3]
	entity_get_vector(ptr, EV_VEC_origin, EndOrigin)
	new iOrigin[3]
	FVecIVec(EndOrigin,iOrigin)

	creat_exp_spr(iOrigin)
	emit_sound(ptr, CHAN_VOICE, "weapons/bomb.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	remove_entity(ptr)

	new Float:Torigin[3], Float:Distance
	for (new i=0 ; i< 32; i++)
	{
		entity_get_vector(i ,EV_VEC_origin, Torigin)
		Distance = get_distance_f(EndOrigin, Torigin);

		if ( Distance <= get_cvar_float("yamato_explore_range") )
			make_damageB(ptr, i)
	}
}
public cqc(ptr, ptd) //ptr撞人的 ptd被撞的 410mm
{
	if (!pev_valid(ptr))
		return;

	new Float:EndOrigin[3]
	entity_get_vector(ptr, EV_VEC_origin, EndOrigin)
	new iOrigin[3]
	FVecIVec(EndOrigin,iOrigin)

	creat_exp_spr(iOrigin)
	emit_sound(ptr, CHAN_VOICE, "weapons/bomb.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	remove_entity(ptr)

	new Float:Torigin[3], Float:Distance
	for (new i=0 ; i< 32; i++)
	{
		entity_get_vector(i ,EV_VEC_origin, Torigin)
		Distance = get_distance_f(EndOrigin, Torigin);

		if ( Distance <= get_cvar_float("yamato_explore_range") )
		{
			client_print(0, print_center, "ko ko ro pyonpyon ma chi kankan e ru mo chyo do 410")
			make_damageB(ptr, i)
		}
	}
}
public ege(ptr, ptd) //ptr撞人的 ptd被撞的
{
	if (!pev_valid(ptr))
		return;

	new Float:EndOrigin[3]
	entity_get_vector(ptr, EV_VEC_origin, EndOrigin)
	new iOrigin[3]
	FVecIVec(EndOrigin,iOrigin)

	creat_exp_spr(iOrigin)
	emit_sound(ptr, CHAN_VOICE, "weapons/bomb.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	new Float:Torigin[3], Float:Distance
	new i, iPlayers[32], iNum, iPlayer
	for (i = 0;i < iNum;i++)
	{
		iPlayer = iPlayers[i]

		entity_get_vector(iPlayer ,EV_VEC_origin, Torigin)
		Distance = get_distance_f(EndOrigin, Torigin)

		if ( Distance <= get_cvar_float("yamato_explore_range") )
		{
			client_print(0, print_center, "ko ko ro pyonpyon ma chi kankan e ru mo chyo do EGG")
			make_damageB(ptr, iPlayer)
		}
	}

	remove_entity(ptr)
}
public make_damageB(Ent, Id)
{
	static Owner; Owner = pev(Ent, pev_iuser1)
	static Attacker; 
	if(!is_user_alive(Owner)) 
	{
		Attacker = 0
		return
	} else Attacker = Owner

	if(is_user_alive(Id))
		ExecuteHamB(Ham_TakeDamage, Id, 0, Attacker, 23.0, DMG_ACID)
}
// public make_damage(id) //傷害浮點數
// {
// 	new Float:Damage
// 	Damage = get_cvar_float("yamato_damage")
// 	if (Damage > 0.0 && get_user_health(id) > 0)
// 	{
// 		new nHealth = floatround(float(get_user_health(id))-Damage)
// 		set_user_health(id,nHealth)
// 	}
// 	else
// 		user_kill(id)
// }
stock creat_exp_spr(const iOrigin[3])  //位置整數陣列X,Y,Z
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_short(exp)
	write_byte(50)
	write_byte(255)
	message_end()

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2]+215)
	write_short(smoke)
	write_byte(125)
	write_byte(5)
	message_end()
}