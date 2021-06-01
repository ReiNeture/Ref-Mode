//new const g_szLights[27][] = {"p","j","c","g","e","o","a","d","n","g","h","r","n","a","m","f","c","h","i","i","a","f","s","l","p","j","b"};
public Bskill(id)
{
	static Float:last_check_time;
	if (get_gametime() - last_check_time < 7.0)
		return
	last_check_time = get_gametime();

	static Float:velocity[3]
	velocity_by_aim(id, 1240, velocity);
	velocity[2] = 720.0;
	set_pev(id, pev_velocity, velocity);
}
public RandTerr(){

	new i, iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum, "c" );

	if( iNum <= 1 )
		return PLUGIN_CONTINUE;
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( g_isBoss[iPlayer] )
			unable_boss(iPlayer)
	}
	new iRandomPlayer, CsTeams:iTeam;
	
	while( ( iRandomPlayer = iPlayers[ random_num( 0, iNum - 1 ) ] ) == g_iLastTerr ) { }
	
	g_iLastTerr = iRandomPlayer;
	
	iTeam = cs_get_user_team( iRandomPlayer );
	
	if( iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T) {
		g_isBoss[iRandomPlayer] = true;
		have_boss = true
		catch_boss(iRandomPlayer);
		set_user_health(iRandomPlayer, get_cvar_num("boss_hp"));
		cs_set_user_team(iRandomPlayer, CS_TEAM_T);
		cs_set_user_model(iRandomPlayer, "posrte")
		set_task(1.0, "boss_beacon",iRandomPlayer+4256)
		set_dhudmessage(111, 15, 142, -0.3, -0.55, 0, 0.0, 8.0, 0.3, 0.3)
		show_dhudmessage(0 ,"花豹已放出");
		set_task(15.0, "un_spawn_event")
	}

	return PLUGIN_CONTINUE;
}
public event_RoundStart()
{
	un_spawn = false
	//play_bgm()
	set_task(3.0,"RandTerr")

	new i, iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "c")
	for (i = 0;i < iNum;i++)
	{
		iPlayer = iPlayers[i]
		if ( g_isBoss[iPlayer] )
			unable_boss(iPlayer)
	}
}
public EventRoundEnd()
{
	remove_task(7866)
	for (new j=0 ; j < 32 ; j++)
		client_cmd(j, "mp3 stop")

	new i, iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "c")
	for (i = 0;i < iNum;i++)
	{
		iPlayer = iPlayers[i]
		if ( g_isBoss[iPlayer] )
		{
			set_task(1.0,"unable_boss",iPlayer)
		}
	}
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
public catch_boss(id){
	if (g_isBoss[id])
		set_task(0.1, "show_boss_hp_hud",id+4567,_,_,"b")
}
public show_boss_hp_hud(id){
	id -= 4567;
	set_hudmessage(255, 0, 0, 0.45, 0.2, 0, 0.0, 0.4, 0.0, 0.0, 4)
	if (get_user_health(id) > 0 )
		show_hudmessage(0 ,"逃脫花豹血量:%d",get_user_health(id));
	else
		show_hudmessage(0 ,"逃脫花豹已被捕獲");
}
public event_Death()
{
	new id = read_data(2) 
	if ( g_isBoss[id] )
	{
		set_task(3.0,"unable_boss",id)
	}
}
public client_putinserver(id)
{
	set_task(0.1, "show_hud", id+4777, "", 0, "b", 0);
	if ( un_spawn )
	{
		player_kill(id)
		client_printcolor(id, "/g[系統]/ctr你遲到15秒，已被自動處死")
	}
}
public player_kill(id){
	if ( !is_user_connected(id) || !is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR )
		return;

	user_silentkill(id);
}
public player_spawn(id){
	if ( !is_user_connected(id) || is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR)
		return;

	ExecuteHamB(Ham_CS_RoundRespawn, id);
	cs_set_user_money(id, 0)
}
public un_spawn_event()
{
	un_spawn = true
}
public unable_boss(id)
{
	g_isBoss[id]=false;
	cs_set_user_team(id, CS_TEAM_CT );
	cs_set_user_model(id, "gsg9")
	remove_task(id+4567)
	remove_task(id+4256)
}
public Restar( )
	server_cmd("sv_restartround 1")

/*public play_bgm()
{
	new iPlayers[32], iNum
	new sound = random_num(0, sizeof BGM - 1)
	get_players(iPlayers, iNum, "c")
	for (new i = 0;i < iNum;i++)
	{
		client_cmd(iPlayers[i], "mp3 play ^"sound/%s^"", BGM[sound])
	}
	set_task(float(BGM_TASK[sound]), "play_bgm", 7866)
}*/
/*****************************************BOT*****************************************/
// Block CS round win audio messages, since we're playing our own instead
public message_sendaudio()
{
       static audio[17]
       get_msg_arg_string(2, audio, sizeof audio - 1)
       
       /*if(equal(audio[7], "terwin"))
       {
		new iPlayers[32], iNum
		get_players(iPlayers, iNum, "c")
		for (new i = 0;i < iNum;i++){
			client_cmd(iPlayers[i], "mp3 play ^"sound/%s^"", sound_eff[4])
		}
       }
       else if(equal(audio[7], "ctwin"))
       {
		new iPlayers[32], iNum
		get_players(iPlayers, iNum, "c")
		for (new i = 0;i < iNum;i++){
			client_cmd(iPlayers[i], "mp3 play ^"sound/%s^"", sound_eff[3])
		}
       }*/

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