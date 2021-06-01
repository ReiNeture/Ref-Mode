public check_boss( ) {
	if( ewowe )
		return PLUGIN_CONTINUE;
	
	new i, iPlayers[ 32 ], iTerrors, iNum, iRealPlayers, CsTeams:iTeam;
	get_players( iPlayers, iNum, "c" );
	
	if( iNum <= 3 )
		return PLUGIN_CONTINUE;
	
	for( i = 0; i < iNum; i++ ) {
		iTeam = cs_get_user_team( iPlayers[ i ] );
		
		if( iTeam == CS_TEAM_T )
			iTerrors++;
		
		if( iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT )
			iRealPlayers++;
	}
	
	if( iRealPlayers <= 3 ) {
		
		for( i = 0; i < iNum; i++ )
			client_printcolor(iPlayers[ i ], "/g[系統]/ctr人數不足，無法開始遊戲")
		
		return PLUGIN_CONTINUE;
	}
	
	if( iTerrors == 0 ) {
		for( i = 0; i < iNum; i++ ) {
			omg_bug = true
			client_printcolor(iPlayers[ i ], "/g[系統]/ctr偵測沒有魔王刷新遊戲")
			if( is_user_alive( iPlayers[ i ] ) && !g_isBoss[iPlayers[ i ]] )
			{
				bug_fix = true
				RandTerr()
				set_task(1.5,"player_kill",iPlayers[ i ])
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}
public RandTerr(){

	new i, iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum, "c" );

	if( iNum <= 3 )
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
		set_user_health(iRandomPlayer, boss_level[game_level]);
		cs_set_user_team(iRandomPlayer, CS_TEAM_T);
		boss_mana[iRandomPlayer] = random_num(30,45)
		client_printcolor(0, "測試用 另外要加入我KuroNeko的宗教請來找我")
	}
	else
		RandTerr()

	return PLUGIN_CONTINUE;
}
public event_RoundStart()
{
	round_start_takedamage = false
	set_task(5.0, "ssssstofalse")
	set_task(5.0, "ssssssssss5s")
	omg_bug = false
	ewowe = false
	un_spawn = false
	set_task(15.0, "un_spawn_event")
	play_bgm()
	if ( g_FirstRound )
	{
		set_task(3.0, "RestartRound")
		g_FirstRound = false
		return PLUGIN_CONTINUE;
	}
	new Light_per = random_num(1,100)
	if ( Light_per >= 90 )
	{
		set_lights("a")
		in_dark = true
	}
	else
	{
		set_lights("#OFF")
		in_dark = false
	}

	return PLUGIN_CONTINUE;
}
public ssssstofalse()
{
	ssssssss = false
}
public ssssssssss5s()
{
	round_start_takedamage = true
}
public EventRoundEnd()
{
	ssssssss = true
	ewowe = true
	remove_task(7866)

	new iNum, iPlayers[32],i, iPlayer
	get_players(iPlayers, iNum, "c")
	for (i = 0;i < iNum;i++)
	{
		client_cmd(iPlayers[i], "mp3 stop")

		if ( g_isBoss[iPlayers[i]] && !bug_fix )
			set_task(1.3,"unable_boss",iPlayers[i])
	}

	if ( bug_fix )
		set_task( 2.0, "fuck_bugggggggggggggggggg" )
	else
		set_task( 2.0, "RandTerr" )

	for (i = 0;i < iNum;i++)
	{
		if ( !omg_bug )
		{
			cannon_victim[iPlayers[i]] = 0
			if ( is_user_connected(iPlayers[i]) )
			{
				g_play_round[iPlayers[i]] ++
				if ( g_play_round[iPlayers[i]] >= 100 )
					finish_achievement(iPlayers[i], PLAY_ROUND_100)
				if ( g_play_round[iPlayers[i]] >= 200 )
					finish_achievement(iPlayers[i], PLAY_ROUND_200)
				if ( g_play_round[iPlayers[i]] >= 300 )
					finish_achievement(iPlayers[i], PLAY_ROUND_300)
			}

			if ( have_sp[iPlayers[i]] > 0 )
				have_sp[iPlayers[i]] = 0
	
			if ( is_user_alive(iPlayers[i]) && is_user_connected(iPlayers[i]) )
			{
				if ( get_user_health(iPlayers[i]) == 1 )
					finish_achievement(iPlayers[i], ALIVE_1HP)
				if ( get_user_health(iPlayers[i]) >= 150 )
					finish_achievement(iPlayers[i], ALIVE_150HP_ABOVE)
				if ( get_user_health(iPlayers[i]) == 44 )
					finish_achievement(iPlayers[i], ALIVE_44HP)
				if ( get_user_health(iPlayers[i]) <= 15 )
					finish_achievement(iPlayers[i], ALIVE_15HP_FOLLOWING)
			}

			if ( in_dark && is_user_alive(iPlayers[i]) && !buy_night[iPlayers[i]] )
				finish_achievement(iPlayers[i], IN_DARK_ALIVE)
			if ( !is_user_alive(iPlayers[i]) )
				buy_night[iPlayers[i]] = false

			if ( !mana_limit[iPlayers[i]] )
				finish_achievement(iPlayers[i], MANA_NOT_60)
			else
				mana_limit[iPlayers[i]] = false

			if ( !g_has_handjob[iPlayers[i]] )
				finish_achievement(iPlayers[i], NO_SWITCH_GUN)
		}
	}
}

public fuck_bugggggggggggggggggg()
	bug_fix = false

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

		if ( boss_mana[id]+2 > 100 )
		{
			boss_mana[id] = 100
			finish_achievement(id, MANA_100)
		}
		else
			boss_mana[id] += 2

		if ( !mana_limit[id] && boss_mana[id] >= 60 && g_isBoss[id] )
		{
			mana_limit[id] = true
		}
	}
}
public catch_boss(id){
	if (g_isBoss[id])
		set_task(0.1, "show_boss_hp_hud",id+4567,_,_,"b")
}
public show_boss_hp_hud(id)
{
	id -= 4567;
	set_hudmessage(75, 218, 186, 0.45, 0.15, 0, 0.0, 0.4, 0.0, 0.0, 4)
	if (get_user_health(id) > 0 )
	{
		if ( boss_mana[id] < 10 )
			show_hudmessage(0 ,"逃脫花豹血量:%d^n逃脫花豹魔力:?/100",get_user_health(id));
		else if ( boss_mana[id] >= 10 && boss_mana[id] < 100 )
			show_hudmessage(0 ,"逃脫花豹血量:%d^n逃脫花豹魔力:??/100",get_user_health(id));
		else if ( boss_mana[id] >= 100 )
			show_hudmessage(0 ,"逃脫花豹血量:%d^n逃脫花豹魔力:100/100",get_user_health(id));
	}
	else
		show_hudmessage(0 ,"逃脫花豹已被捕獲");
}
public event_Death()
{
	new weapon_name[64]
	read_data(4, weapon_name, 63)

	new attacker = read_data(1)
	new victim = read_data(2)

	if ( skill_cn[victim] )
		skill_cn_off(victim)

	if ( attacker != victim )
	{
		new Time_Hour[10], Time_Minute[10]
		get_time("%H", Time_Hour, 9)
		get_time("%M", Time_Minute, 9)
		if (str_to_num(Time_Hour) == 18 && str_to_num(Time_Minute) == 7)
			finish_achievement(attacker, PM_KILL_543)

		if ( equal(weapon_name, "knife") && get_user_health(attacker) == 1)
			finish_achievement(attacker, KNIFE_KILL_1HP)

		if ( equal(weapon_name, "knife") )
			finish_achievement(attacker, TAKE_KNIFE_KILL)
		if ( equal(weapon_name, "mp5navy") )
			finish_achievement(attacker, MP5_KILL)
		if ( equal(weapon_name, "p90") )
			finish_achievement(attacker, P90_KILL)
		if ( equal(weapon_name, "ak47") )
			finish_achievement(attacker, AK47_KILL)
		if ( equal(weapon_name, "xm1014") )
			finish_achievement(attacker, XM1014_KILL)
		if ( equal(weapon_name, "famas") )
			finish_achievement(attacker, FAMAS_KILL)

		if (!(pev(attacker, pev_flags) & FL_ONGROUND) && is_user_alive(attacker) && is_user_connected(attacker))
			finish_achievement(attacker, IN_SKY_KILL)

		new clip, ammo
		get_user_weapon(attacker, clip, ammo)
		if ( clip == 1 )
			finish_achievement(attacker, LAST_BULLET_KILL)

		if ( game_level >= 6 )
			finish_achievement(attacker, KILL_VI)
		if ( game_level >= 7 )
			finish_achievement(attacker, KILL_VII)
		if ( game_level == 8 )
			finish_achievement(attacker, KILL_X)
	}
	else if ( attacker == victim && !omg_bug)
	{
		selfkill_count[victim] ++

		if ( selfkill_count[victim] >= 3 )
			finish_achievement(victim, MAP_KILLMYSELF_3)
	}
}
public client_putinserver(id)
{
	
	set_task(0.1, "show_hud", id+4777, "", 0, "b", 0);
	set_task(60.0, "Rape",id,_,_,"b");
	if ( un_spawn )
	{
		user_silentkill(id)
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
	remove_task(id+4567)
	remove_task(id+4256)

	if ( cannon_mode[id] )
	{
		cannon_mode[id] = false
		remove_task(1144)
	}
	if ( cannon_mode_temp[id] )
	{
		cannon_mode_temp[id]=false
		remove_task(id+1996)
	}
	if ( skill_cn_public )
	{
		skill_cn[id] = false
		skill_cn_public = false
		remove_task(id+1333)
	}
	if ( is_user_connected(id) )
	{
		cs_set_user_team(id, CS_TEAM_CT );
		cs_set_user_model(id, "gsg9")
	}
}
public RestartRound()
	server_cmd("sv_restartround 1")

public play_bgm()
{
	new iPlayers[32], iNum
	new sound = random_num(0, sizeof BGM - 1)
	get_players(iPlayers, iNum, "c")
	for (new i = 0;i < iNum;i++)
	{
		client_cmd(iPlayers[i], "mp3 play ^"sound/%s^"", BGM[sound])
	}
	set_task(float(BGM_TASK[sound]), "play_bgm", 7866)
}
public task_hide_money(id)
{
	if (!is_user_alive(id))
		return;

	message_begin(MSG_ONE, get_user_msgid("HideWeapon"), _, id)
	write_byte((1<<5))
	message_end()
}
/*****************************************BOT*****************************************/
// Block CS round win audio messages, since we're playing our own instead
public message_sendaudio()
{
       static audio[17]
       get_msg_arg_string(2, audio, sizeof audio - 1)
       
       if(equal(audio[7], "terwin"))
       {
		client_cmd(0, "speak ^"sound/%s^"", sound_eff[4])
		if ( game_level > 0 )
			game_level --
       }
       else if(equal(audio[7], "ctwin"))
       {
		client_cmd(0, "speak ^"sound/%s^"", sound_eff[3])
		if ( game_level < 8 )
			game_level ++
       }

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