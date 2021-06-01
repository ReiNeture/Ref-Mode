#include < amxmodx >
#include < amxmisc >
#include < engine >
#include < cstrike >
#include < fun >
#include < fakemeta >
#include < hamsandwich >
#include < dhudmessage >
#include < xs >

native set_custom_exp(id,val)

//new const g_szLights[27][] = {"v","u","t","s","r","q","p","o","n","m","l","k","j","i","h","g","f","e","d","c","b","a","b","b","c","c","c"};
new const g_szLights[27][] = {"p","j","c","g","e","o","a","d","n","g","h","r","n","a","m","f","c","h","i","i","a","f","s","l","p","j","b"};
new const g_szBotName[ ] = "Faker";
new g_iFakeplayer,g_iLastTerr;
new public_time=1;
new boss_haken=0
new bool:public_timesel=false ;//, bool:public_isNight=false;
new bool:g_isBoss[33]={false};
new bool:unable_spawn=false
new bool:temp_con=false
new g_beacon
new bool:boss_lock = false
public plugin_init()
{  
	register_plugin("茶園你的雞雞呢555啊55555原來縮到腹腔裡了", "1.6", "KuroNeko");
	register_message(get_user_msgid("TextMsg"), "message_textmsg")
	register_message(get_user_msgid("SendAudio"), "message_sendaudio")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
	RegisterHam(Ham_Killed, "player", "fwd_Killed");
	register_event("ResetHUD", "event_NewRound", "be")
	register_message( get_user_msgid( "DeathMsg" ), "MsgDeathMsg" );
	register_logevent("EventRoundEnd", 2, "1=Round_End")
	register_cvar("boss_hp", "10000")
	set_task(30.0, "TimetoNight", _,_,_,"b");

	new iEntity, iCount;
	while( ( iEntity = find_ent_by_class( iEntity, "info_player_deathmatch" ) ) > 0 )
	if( iCount++ > 1 )
		break;
	if( iCount <= 1 )
		g_iFakeplayer = -1;
		
	set_task( 3.0, "UpdateBot" );
	set_task( 4.0, "Restar" );
	for (new i=0 ; i < 32 ; i++){
		set_task( 4.0, "player_kill", i)
	}
}
public plugin_natives()
{
     register_native("get_user_boss", "native_get_user_boss", 1);
     register_native("get_kn_time", "native_get_time", 2);
     register_native("bug_spawn", "native_bug_spawn", 3);
     register_native("get_boss_haken", "native_boss_haken", 4);

}
public plugin_precache()
{
	precache_model("models/player/posrte/posrte.mdl")
	g_beacon = precache_model("sprites/beacon.spr")
}
public native_bug_spawn(id)
	player_spawn(id)

public bool:native_get_user_boss(id)
	return g_isBoss[id];
public native_get_time()
	return public_time
public native_boss_haken()
	return boss_haken

public fw_PlayerPreThink(id){
	static buttons;
	buttons = pev(id, pev_button);
	if (((buttons & IN_DUCK) && (buttons & IN_JUMP)) && g_isBoss[id])
		Bskill(id);
}
public Bskill(id)
{
	static Float:last_check_time;
	if (get_gametime() - last_check_time < 8.0)
		return
	last_check_time = get_gametime();

	static Float:velocity[3]
	velocity_by_aim(id, 640, velocity);
	velocity[2] = 320.0;
	set_pev(id, pev_velocity, velocity);
}
public RandTerr(){
	if (boss_haken == 1 || boss_lock)
		return PLUGIN_HANDLED

	new i, iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum, "c" );

	if( iNum <= 1 )
		return PLUGIN_CONTINUE;
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( cs_get_user_team( iPlayer ) == CS_TEAM_T )
			cs_set_user_team( iPlayer, CS_TEAM_CT );
	}
	new iRandomPlayer, CsTeams:iTeam;
	
	while( ( iRandomPlayer = iPlayers[ random_num( 0, iNum - 1 ) ] ) == g_iLastTerr ) { }
	
	g_iLastTerr = iRandomPlayer;
	
	iTeam = cs_get_user_team( iRandomPlayer );
	
	if( iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T) {
		g_isBoss[iRandomPlayer] = true;
		boss_haken = 1
		unable_spawn = true
		catch_boss(iRandomPlayer);
		set_user_health(iRandomPlayer, get_cvar_num("boss_hp"));
		cs_set_user_team(iRandomPlayer, CS_TEAM_T);
		cs_set_user_model(iRandomPlayer, "posrte")
		set_task(1.0, "boss_beacon",iRandomPlayer+4256)
		boss_lock = true
		set_dhudmessage(111, 15, 142, -0.3, -0.65, 0, 0.0, 8.0, 0.3, 0.3)
		show_dhudmessage(0 ,"花豹已放出 請在時效內選槍");

		for (new i = 0;i < 32;i++){
			client_cmd(i, "/weapon_for_nor")
		}
		Remove_All_Bouns_Ents()
	}
	else
		set_task(1.0, "RandTerr")

	return PLUGIN_CONTINUE;
}
public boss_beacon(id)
{
	id -= 4256
	if (is_user_alive(id) && g_isBoss[id])
	{
		static origin[3]
		get_user_origin(id, origin)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMCYLINDER) // TE_BEAMCYLINDER (21)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]-20)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+1000)
		write_short(g_beacon)
		write_byte(0)
		write_byte(1)
		write_byte(6)
		write_byte(2)
		write_byte(1)
		write_byte(255)
		write_byte(0)
		write_byte(0)
		write_byte(255)
		write_byte(6)
		message_end()
	}
	set_task(1.0, "boss_beacon",id+4256)
}
public TimetoNight(){     //天亮到夜晚 public_timesel = false ;; 夜晚到天亮 public_timesel = true ;
	if (public_time>=26)
		public_timesel=true;
	else if (public_time<=0)
		public_timesel=false;

	(!public_timesel) ? public_time++ : public_time--;
	new n_random = random_num(1,100)
	if ( n_random >= 90 )
	{
		RandTerr();
	}

	if (boss_haken == 0)
		set_lights(g_szLights[public_time][0]);

	//if (public_time == 23 && !public_timesel)
}
public catch_boss(id){
	if (g_isBoss[id])
		set_task(0.1, "show_hud",id+4567,_,_,"b")
}
public show_hud(id){
	id -= 4567;
	//set_dhudmessage(200, 0, 0, 0.45, 0.2, 0, 0.0, 0.3, 0.0, 0.0)
	set_hudmessage(255, 0, 0, 0.45, 0.2, 0, 0.0, 0.4, 0.0, 0.0, 4)
	show_hudmessage(0 ,"逃脫花豹血量:%d",get_user_health(id));
}
public fwd_Killed(victim, attack, shouldgib){
    	if (!is_user_connected(attack))
                 	return HAM_IGNORED

	cs_set_user_money(attack, 0)

	if (g_isBoss[attack]) //-------------0725
	{
		set_custom_exp(attack,1000)
		client_print(attack, print_center, "你抓到肉了，獲得%d經驗值", 1000)
	}

	if (g_isBoss[victim]){
		boss_haken = 0
		set_task(50.0,"locklock")
		set_task(0.5,"unable_boss",victim);
		for (new i = 0;i < 32;i++){
			strip_weapon_give_knife(i)
			set_task(1.2,"player_spawn",i); //-------------0725
		}
	}
	else
		set_task(0.5,"player_spawn",victim);


	return HAM_IGNORED
}
public EventRoundEnd()
	temp_con = true

public event_NewRound(id) 
{
	set_task(50.0,"locklock")
	boss_haken = 0
	temp_con = false
	if (g_isBoss[id])
	{
		unable_boss(id)
		ExecuteHamB(Ham_CS_RoundRespawn, id);
	}
}
public client_disconnect(id)
{
	if(g_isBoss[id]){
		unable_spawn = false
		boss_haken = 0
		set_task(50.0,"locklock")
		g_isBoss[id]=false;
		remove_task(id+4567)
		remove_task(id+4256)

		//new i, iPlayers[32], iNum
		//get_players(iPlayers, iNum, "c")
		for (new i = 0;i < 32;i++){
			strip_weapon_give_knife(i)
			set_task(3.0,"player_spawn",i);
		}
	}
}
public client_putinserver(id)
{
	if(!unable_spawn)
		set_task(3.0,"player_spawn",id)
}
public player_kill(id){
	if ( !is_user_connected(id) || !is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR )
		return;

	user_silentkill(id);
}
public player_spawn(id){
	if ( !is_user_connected(id) || is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR)
		return;
	if ( unable_spawn && !g_isBoss[id])
		return;

	ExecuteHamB(Ham_CS_RoundRespawn, id);
	cs_set_user_money(id, 0)
}
public unable_boss(id)
{
	unable_spawn = false
	boss_haken = 0
	g_isBoss[id]=false;
	cs_set_user_team(id, CS_TEAM_CT );
	cs_set_user_model(id, "gsg9")
	remove_task(id+4567)
	remove_task(id+4256)
}
public strip_weapon_give_knife(id)
{
	if (!is_user_connected(id) || !is_user_alive(id))
		return;

	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
}
public Remove_All_Bouns_Ents()
{
	new bouns_ent = find_ent_by_class(-1, "LowBouns")
	
	while ( bouns_ent ) 
	{
		remove_entity(bouns_ent)
		bouns_ent = find_ent_by_class(bouns_ent, "LowBouns")
	}
}
public locklock()
	boss_lock = false
public Restar( )
	server_cmd("sv_restartround 1")
/*****************************************BOT*****************************************/
public UpdateBot( ) {
	if( g_iFakeplayer == -1 )
		return;
		
	new id = find_player( "i" );
		
	if( !id ) {
		id = engfunc( EngFunc_CreateFakeClient, g_szBotName );
		if( pev_valid( id ) ) {
			engfunc( EngFunc_FreeEntPrivateData, id );
			dllfunc( MetaFunc_CallGameEntity, "player", id );
			set_user_info( id, "rate", "3500" );
			set_user_info( id, "cl_updaterate", "25" );
			set_user_info( id, "cl_lw", "1" );
			set_user_info( id, "cl_lc", "1" );
			set_user_info( id, "cl_dlmax", "128" );
			set_user_info( id, "cl_righthand", "1" );
			set_user_info( id, "_vgui_menus", "0" );
			set_user_info( id, "_ah", "0" );
			set_user_info( id, "dm", "0" );
			set_user_info( id, "tracker", "0" );
			set_user_info( id, "friends", "0" );
			set_user_info( id, "*bot", "1" );
			set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT );
			set_pev( id, pev_colormap, id );
				
			new szMsg[ 128 ];
			dllfunc( DLLFunc_ClientConnect, id, g_szBotName, "127.0.0.1", szMsg );
			dllfunc( DLLFunc_ClientPutInServer, id );
				
			cs_set_user_team( id, CS_TEAM_T );
			ExecuteHamB( Ham_CS_RoundRespawn, id );
				
			set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
			set_pev( id, pev_solid, SOLID_NOT );
			dllfunc( DLLFunc_Think, id );
				
			g_iFakeplayer = id;
		}
	}
}
public MsgDeathMsg( const iMsgId, const iMsgDest, const id ) {
	if( get_msg_arg_int( 2 ) == g_iFakeplayer )
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}
public FwdHamPlayerSpawn( id ) {
	if( g_iFakeplayer == id ) {
		set_pev( id, pev_frags, -87.0 );
		cs_set_user_deaths( id, 87 );
		set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
		set_pev( id, pev_solid, SOLID_NOT );
		entity_set_origin( id, Float:{ 999999.0, 999999.0, 999999.0 } );
		dllfunc( DLLFunc_Think, id );
	}
}
/*****************************************BOT*****************************************/
// Block CS round win audio messages, since we're playing our own instead
public message_sendaudio()
{
       static audio[17]
       get_msg_arg_string(2, audio, sizeof audio - 1)
       
       if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
              return PLUGIN_HANDLED;
       
       return PLUGIN_CONTINUE;
}
// Block some text messages
public message_textmsg()
{
	static textmsg[22]
	get_msg_arg_string(2, textmsg, sizeof textmsg - 1);
        // Block round end related messages
	if (equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") || equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win"))
	{
              return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
/*******************************************************阻擋訊息*************************************************/
stock log_kill(killer, victim, weapon[], headshot)
{
	new attacker_frags = get_user_frags(killer)
	
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	ExecuteHamB(Ham_Killed, victim, killer, 1) // set last param to 2 if you want victim to gib
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)

	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(killer)
	write_byte(victim)
	write_byte(headshot)
	write_string(weapon)
	message_end()

	if (get_user_team(killer) == get_user_team(victim))
		attacker_frags -= 1
	else
		attacker_frags += 1

	new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10]

	get_user_name(killer, kname, 31)
	get_user_team(killer, kteam, 9)
	get_user_authid(killer, kauthid, 31)
 
	get_user_name(victim, vname, 31)
	get_user_team(victim, vteam, 9)
	get_user_authid(victim, vauthid, 31)

	log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
	kname, get_user_userid(killer), kauthid, kteam, 
 	vname, get_user_userid(victim), vauthid, vteam, weapon)

 	return PLUGIN_CONTINUE
}
stock fm_create_entity(const classname[])
{
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
}
stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = fm_create_entity(item);
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}
stock fm_strip_user_weapons(index) {
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent))
		return 0;

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}