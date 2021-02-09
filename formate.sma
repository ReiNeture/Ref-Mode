#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <xs>
#include <vector>
#include <cstrike>
#include <float>
// #include <file>
// #include <nvault>

#define strong_weapon "weapon_ak47"
#define strong_weapon_id CSW_AK47
#define strong_speed 0.9

// new keep_file; // for nvault

new color[33][3];
new status[33][3];
new type[33] = {0};
new color_switch[33] = {1};
new attackCount[33] = {0};

new const SoundFiles[7][] =
{
	"ref/hit1.wav",
	"ref/fire1.wav",
	"ref/helmet_hit.wav",
	"ref/miss1.wav",
	"ref/miss2.wav",
	"ref/miss3.wav",
	"ref/knife_slash1.wav"
}


new Float:weapon_recoil[33];
new eye, butterfly, chick, pointer;
public plugin_init()
{
	register_plugin("Format TEST", "1.0", "Ref");
	
	register_clcmd("format_test", "test_function");
	// register_clcmd("keep_data", "nvault_save");
	// register_clcmd("load_data", "nvault_load");
	
	//register_clcmd("ct_join", "Cmdmsg");
	register_clcmd("write", "test_file");
	register_clcmd("read", "my_read_file");
	register_clcmd("gay_bar", "gay_bar_func");
	register_clcmd("respawn", "set_Respawn");
	register_clcmd("hide", "hide_weapon");
	register_clcmd("say /color", "become_color");
	register_clcmd("say menu", "amx_menu");
	//register_clcmd( "drop", "block_drop" );
	
	//register_event("DeathMsg", "death_event", "a");               // listen on DeathMsg , "a" is golbal event
	//register_message(get_user_msgid("TextMsg"), "text_message");  // register_message let you hook in engine
	register_message(get_user_msgid("BarTime"), "bar_message");
	// register_message(get_user_msgid("ShowMenu"), "menu_message");
	// register_message(get_user_msgid("VGUIMenu"), "vgim_message");

	for (new i=0 ;i<32 ; i++) { color[i][0]=120;color[i][1]=0;color[i][2]=0;status[i][0]=0;status[i][1]=0;status[i][2]=0;}
	arrayset(color_switch, 1, 32);

	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_world");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_player");
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Weapon_PrimaryAttack_knife", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, strong_weapon, "fw_Weapon_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, strong_weapon, "fw_Weapon_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "fw_Item_PostFrame");
	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "fw_Ak_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_Item_AddToPlayer_Post", 1);
	
	register_event("DeathMsg", "eventPlayerDeath", "a");
	register_event("DeathMsg", "eventPlayerDeath", "bg");
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	// register_touch("buil", "*", "fw_Touch_buil");
	
	
}
public plugin_precache()
{
	eye = engfunc(EngFunc_PrecacheModel, "sprites/eye.spr");                   // precache_model("sprites/eye.spr");
	pointer = engfunc(EngFunc_PrecacheModel, "sprites/vac.spr");              // precache_model("sprites/vac.spr");
	butterfly = engfunc(EngFunc_PrecacheModel, "models/butterfly.mdl");      // precache_model("models/butterfly.mdl");
	chick = engfunc(EngFunc_PrecacheModel, "models/chick.mdl");             // precache_model("models/chick.mdl");
	engfunc(EngFunc_PrecacheModel, "models/v_katana.mdl");                    // precache_model("models/v_katana.mdl");
	engfunc(EngFunc_PrecacheModel, "models/v_ak74origin.mdl");
	engfunc(EngFunc_PrecacheModel, "models/v_cak74.mdl");

	for (new i=0; i < sizeof(SoundFiles); i++) {
		engfunc(EngFunc_PrecacheSound, SoundFiles[i]);
	}
}
public eventPlayerDeath()
{
	new index = read_data(2);
	set_task(0.1, "DeathPost", index);
}
public DeathPost(index)
{
	set_pev(index, pev_deadflag, DEAD_RESPAWNABLE);
	dllfunc(DLLFunc_Spawn, index);
	set_pev(index, pev_iuser1, 0);
}
public test_file(id) {
	new file[] = "addons\amxmodx\configs\test.ini";
	new size = file_size(file, 1);
	new steamid[32], name[32], userip[32], write_data[128];

	get_user_authid(id, steamid, 31);
	get_user_name(id, name, 31);
	get_user_ip(id, userip, 31);

	formatex(write_data, 127, "%d. %s %s %s", size, name, userip, steamid);
	write_file(file, write_data);
}
public my_read_file(id){
	new readdata[128];
	new txtlen;
	new line = 0;

	while( read_file("addons\amxmodx\configs\test.ini", line++, readdata, 127, txtlen) )
	{
		new steamid[32], name[32], userip[32], no[8];
		parse(readdata, no, 7, name, 31, userip, 31, steamid, 31);
		client_print(id, print_console, "%s %s %s %s", no, name , userip, steamid);
	}
}
public fw_PlayerPreThink(id) {
	static Float:fAim[3];
	velocity_by_aim(id, 180, fAim);
	// new swim_time = pev(id, pev_flDuckTime);
	// static Float:num; num = vector_length(fAim);

	static Float:last_time;
	if ( get_gametime() - last_time >= 0.5) {
		client_print(id, print_center, "%f # %f # 拿AK按右鍵 # 拿刀有防護罩", fAim[0],fAim[1]);
		last_time = get_gametime();
	}
	
	if ( get_user_weapon(id) == CSW_KNIFE )
		set_user_maxspeed(id, 400.0);
	else 
		set_user_maxspeed(id, 250.0);
}
public fw_Weapon_PrimaryAttack(ent) // "weapon_ak47"
{ 
	if(!pev_valid(ent)) return;
	static id; id = pev(ent, pev_owner);
	pev(ent, pev_punchangle, weapon_recoil[id]);
	// set_pdata_int(ent, 51, get_pdata_int(ent, 51, 4)+1, 4); // when each fire , ammo += 1 

	// engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("Crosshair"), 0, id);
	// write_byte(1);
	// message_end();
}
public fw_Weapon_PrimaryAttack_Post(ent) // "weapon_ak47"
{ 
	if(!pev_valid(ent)) return;

	new wid = get_pdata_cbase(ent, 41, 4);
	new clip = cs_get_weapon_ammo(ent);
	if ( clip > 0 ) 
		emit_sound(wid, CHAN_WEAPON, "ref/fire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	new Float:speed = strong_speed;
	set_pdata_float(ent, 46, get_pdata_float(ent, 46, 4) * speed, 4); // fire rate

	static id; id = pev(ent, pev_owner);
	static Float:Push[3];
	pev(id, pev_punchangle, Push);

	// xs_vec_sub(Push, weapon_recoil[id], Push);
	xs_vec_mul_scalar(Push, 0.5, Push);
	// xs_vec_add(Push,  weapon_recoil[id], Push);
	set_pev(id, pev_punchangle, Push);
	//console_print(0, "%d", get_pdata_int(ent, 51, 4)); // current ammo 
}
public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent)) return HAM_IGNORED;

	new id = get_pdata_cbase(ent, 41, 4)
	if( pev(id, pev_button) & IN_ATTACK2 ) {

		set_pev(id, pev_viewmodel2, "models/v_ak74origin.mdl");
		emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100);

		set_pev(id, pev_fov, 85);
		set_pdata_int(id, 363, 85, 5);

		set_pdata_float(id, 83, 0.72, 5); // 83 = NextAttack, 0.7sec

		// set_pev(id, pev_weaponanim, 2);
		message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, id);
		write_byte(2); // 2 = DRAW , on viewr
		write_byte(0);
		message_end();

		// message_begin(MSG_ONE, get_user_msgid("HideWeapon"), _, id);
		// write_byte(1<<6); // hide crosshair
		// message_end();

		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}
public fw_TraceAttack_world(this, id, Float:damage, Float:direction[3], tracehandle, damagebits) {
	// if replace [id] eqaul original code.
	if ( color_switch[id] == -1) {
		static const ruel[6][3] = 
		{
			{1,0,0}, {1,1,0}, {0,1,0},
			{0,1,1}, {0,0,1},
			{1,0,1}//, {1,1,1}
		}
		new i = 0;
		static command[50];
		
		for( i=0; i<=2; ++i ) { 
			if (  ruel[type[id]][i] != 1 && color[id][i] > 0 ) {
				color[id][i] -= 30;
				break;
			} else if ( ruel[type[id]][i] == 1 && color[id][i] < 250 ) {
				color[id][i] += 30;
				//continue;
			}

			if ( ruel[type[id]][i] == 1 && color[id][i] >= 250 && status[id][i] == 0 )
				status[id][i] = 1;
			if ( ruel[type[id]][i] == 0 && color[id][i] <= 0 && status[id][i] == 1 )
				status[id][i] = 0;
		}
		if ( status[id][0] == ruel[type[id]][0] && status[id][1] == ruel[type[id]][1] && status[id][2] == ruel[type[id]][2] ) {
			type[id]++; if(type[id]>5) type[id]=0;
		}
		formatex(command, sizeof command-1, "cl_crosshair_color ^"%d %d %d^"", color[id][0],color[id][1],color[id][2]);
		client_cmd(id, command);
	}
	//console_print(0, "%s  Type: %d", command, type[id]);
	//console_print(0, "this:%d - idattacker: %d - direction:%f>%f>%f, damage:%f^n-------The message is from Ham_TraceAttack listen of worldspawn.-------", this, id, direction[0], direction[1], direction[2], damage);
	new Float:orig[3];
	get_tr2(tracehandle, TR_vecEndPos, orig);

	// message_begin(MSG_ALL, SVC_TEMPENTITY);
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_SPARKS);  // 槍命中金屬的火光
	engfunc(EngFunc_WriteCoord, orig[0]);
	engfunc(EngFunc_WriteCoord, orig[1]);
	engfunc(EngFunc_WriteCoord, orig[2]);
	message_end();

	trace_effect(id);

}
public fw_TraceAttack_player(this, id, Float:damage, Float:direction[3], tracehandle, damagebits) {
	if ( !is_user_alive(id))
		return;

	if (get_user_weapon(this) == CSW_KNIFE)
	{
		if( !is_user_bot(this) )
			SetHamParamFloat(3, damage * 0.1);

		new wav[20];
		formatex(wav, 19, "ref/miss%d.wav", random_num(1, 3));
		emit_sound(this, CHAN_WEAPON, wav, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		static Float:last_time;
		if ( get_gametime() - last_time >= 0.2) 
		{
			new Float:origin[3];
			get_tr2(tracehandle, TR_vecEndPos, origin);

			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
			write_byte(TE_GLOWSPRITE); 
			engfunc(EngFunc_WriteCoord, origin[0]); // write_coord(origin[0]);
			engfunc(EngFunc_WriteCoord, origin[1]); // write_coord(origin[1]);
			engfunc(EngFunc_WriteCoord, origin[2]); // write_coord(origin[2]);
			write_short(pointer);    // 光盾
			write_byte(1);           // 淡出時間
			write_byte(3);           // width
			write_byte(175);         // 亮度
			message_end();
			last_time = get_gametime();
		}
	} else if (get_tr2(tracehandle, TR_iHitgroup) == HIT_HEAD) {
		emit_sound(id, CHAN_BODY, "ref/helmet_hit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	} else {
		// message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
		write_byte(TE_BEAMRING); // 雙人光圈
		write_short(id);
		write_short(this);
		write_short(eye);
		write_byte(1);   // start frame
		write_byte(100); // frame time
		write_byte(30);  // life
		write_byte(10);  // width
		write_byte(0);  // noise
		write_byte(random_num(1, 255));
		write_byte(random_num(1, 255));
		write_byte(random_num(1, 255));
		write_byte(255);
		write_byte(10);
		message_end();
	}
	trace_effect(id);
}
public fw_PlayerKilled(this, idattacker, shouldgib) {
	if ( !is_user_alive(idattacker) )
		return PLUGIN_HANDLED;

	new ida_origin[3], this_origin[3], distance;
	get_user_origin(this,       this_origin, 0);
	get_user_origin(idattacker, ida_origin,  0);
	distance = get_distance(this_origin, ida_origin);

	new Float:volume = 0.0;
	switch (distance/200) {
		case 0: volume = 1.0;
		case 1..3: volume = 0.8;
		case 4..5: volume = 0.7;
		case 6..7: volume = 0.6;
		default:   volume = 0.4;
	}
	emit_sound(idattacker, CHAN_STATIC, "ref/hit1.wav", volume, ATTN_NORM, 0, PITCH_NORM);
	new Float:heal = float(pev(idattacker, pev_health));
	set_pev(idattacker, pev_health, heal+50.0);

	// message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, idattacker);
	engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, idattacker);
	write_short(1<<10); // Duration --> Note: Duration and HoldTime is in special units. 1 second is equal to (1<<12) i.e. 4096 units.
	write_short(1<<10); // Holdtime
	write_short(0x0000); // 0x0001 Fade in
	write_byte(0);
	write_byte(255);
	write_byte(0);
	write_byte(20);  // Alpha
	message_end();

	// message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_FIREFIELD);     // 領域特效
	write_coord(this_origin[0]);
	write_coord(this_origin[1]);
	write_coord(this_origin[2]);
	write_short(100); // radius
	write_short(butterfly);
	write_byte(12); // count
	write_byte(TEFIRE_FLAG_SOMEFLOAT);
	write_byte(100); // life 0.1's
	message_end();
	
	new Float:this_aim[3];
	velocity_by_aim(idattacker, 780, this_aim);
	// message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_BREAKMODEL);
	write_coord(this_origin[0]);
	write_coord(this_origin[1]);
	write_coord(this_origin[2]+24);
	write_coord(16); // size x
	write_coord(16); // size y
	write_coord(16); // size z
	engfunc(EngFunc_WriteCoord, this_aim[0]); // write_coord(this_aim[0]); // velocity x 
	engfunc(EngFunc_WriteCoord, this_aim[1]); // write_coord(this_aim[1]); // velocity y
	engfunc(EngFunc_WriteCoord, this_aim[2]); // write_coord(this_aim[2]); // velocity z default 165
	write_byte(10); // random velocity
	write_short(chick);
	write_byte(7); // count
	write_byte(10); // life 0.1's
	write_byte(4); // 1 : Glass sounds and models draw at 50% opacity  2 : Metal sounds  4 : Flesh sounds  8 : Wood sounds  64 : Rock sounds 
	message_end();

	return PLUGIN_HANDLED;
	//set_task(1.0, "fm_cs_user_spawn", this);
}
public fw_PlayerTakeDamage(this, idinflictor, idattacker, Float:damage, damagebits) {
	if ( !is_user_alive(this) )
		return PLUGIN_HANDLED;

	return PLUGIN_HANDLED;
}
public fw_PlayerSpawn(id) {
	if ( is_user_bot(id) ) {
		set_pev(id, pev_health, random_float(700.0, 2500.0));
	}
	//fm_give_item(id, strong_weapon);
	return PLUGIN_HANDLED;
}
public death_event() {
	new r1, r2, r3, r4[50];
	
	r1 = read_data(1);          // byte:attacker id
	r2 = read_data(2);			// byte:vimtimer id
	r3 = read_data(3);			// bool:IsHeadshot
	read_data(4, r4, 49);		// string:WeaponName[]
	
	console_print(0, "%d - %d - %d - %s", r1,r2,r3,r4);
}
public fw_Item_AddToPlayer_Post(item, id) {

}
public fw_Item_Deploy_Post(ent) {
	if (!pev_valid(ent))
		return;
	static id;id = pev(ent, pev_owner);
	set_pev(id, pev_viewmodel2, "models/v_katana.mdl");
}
public fw_Ak_Deploy_Post(ent) {
	if (!pev_valid(ent))
		return;
	static id;id = pev(ent, pev_owner);
	set_pev(id, pev_viewmodel2, "models/v_cak74.mdl");
}
public fw_Weapon_PrimaryAttack_knife(ent) // knife
{ 
	if(!pev_valid(ent)) return;

	static id; id = get_pdata_cbase(ent, 41, 4);
	new Float:oldRate = get_pdata_float(ent, 46, 4);

	attackCount[id]++;

	if( attackCount[id] >= 10 ) {
		set_pdata_float(ent, 46, oldRate, 4);
		attackCount[id] = 0;
	} else if( attackCount[id] >= 4 )
		set_pdata_float(ent, 46, oldRate*0.25, 4);
	
	emit_sound(ent, CHAN_WEAPON, "ref/knife_slash1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
// public vgim_message(msgid, dest, id) {
// 	//console_print(0, "vgim_message: ");
// 	return PLUGIN_CONTINUE;
// 	//return PLUGIN_HANDLED;
// }
// public menu_message(msgid, dest, id) {
// 	static buffer[32];
// 	get_msg_arg_string(4, buffer, sizeof buffer-1);
// 	//console_print(0, "menu_message: %s", buffer);
// 	return PLUGIN_CONTINUE;
// }
public hide_weapon(id) {
	message_begin(MSG_ONE, get_user_msgid("HideWeapon"), _, id);
	write_byte(1<<2);
	message_end();
}
public bar_message(msgid, dest, id) {
	new Duration = get_msg_arg_int(1);
	set_msg_arg_int(1, ARG_SHORT, Duration-Duration);
	
	return PLUGIN_CONTINUE;
}
public text_message(iMsg, iDest, iEntity) {
	static txtmsg[32];
	get_msg_arg_string(2, txtmsg, sizeof txtmsg-1 );    // 取得格式化TextMsg訊息字串
	
	if ( equal(txtmsg, "#Game_bomb_drop") ) {           // 如果字串為C4掉落
		set_msg_arg_string(2, "#Bomb_Planted");         // 設定訊息字串如左 也可以直接設定為純文字 另外還會觸發BarTime 0秒
	}	
	//console_print(0, "text_message: %s", txtmsg);
	//console_print(0, "%d", get_msg_arg_int(1));         
	// TextMsg包含兩個參數 
	// byte:DestinationType 訊息抵達的方式 請參照amxconst.inc的Destination types for client_print()
	// string:Message 顯示在螢幕的內容  Example: #Weapon_Cannot_Be_Dropped
	
	return PLUGIN_CONTINUE;								// 繼續傳送訊息
}
// public Cmdmsg()
// {
//     message_begin(MSG_ALL, get_user_msgid("TextMsg"), {0,0,0}, 0);
//     write_byte(2);
//     write_string("#Game_join_ct"); // 只是格式化字串
//     write_string("Pimp Daddy");
//     message_end();
//     return PLUGIN_HANDLED;
// }  
public gay_bar_func(id) {
	// message_begin(MSG_BROADCAST, get_user_msgid("BarTime"), {100,200,50}, id);
	// write_short(3);
	// message_end();
	new origin[3]; get_user_origin(id, origin, 0);

	// message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_BEAMFOLLOW); // 車尾燈
	write_short(id);
	write_short(eye);
	write_byte(50); // life
	write_byte(10); // width
	write_byte(255); // r
	write_byte(255); // g
	write_byte(255); // b
	write_byte(127); // brightness
	message_end();

	new Float:pi = 3.14;
	for (new Float:i=0.0; i<=(pi*2.0); i+=0.19625) {
		console_print(id, "%f", floatsin(i));
	}
}
// [ STRING ]
public test_function(id) {
	new name[32], vauname[32], vaudata[100], vau3[10];
	get_user_name(id, name, 31);
	
	format(vauname, 31, "%s", name);
	console_print(id, "%s", vauname);
	
	format(vaudata, 99, "%d#%d#%d#", 1,2,3);
	console_print(id, "%s", vaudata);
	
	formatex(vau3, 9, "#");
	console_print(id, "%s", vau3);
	
	
	new str[100] = "3#1#7#8#1#2#3#4#";
	new left[50], all[100];
	new len = 0;
	for( new i=0; i<=7 ; i++ ) {
		strtok(str, left, 49, str, 99, '#');
		len += format(all[len], charsmax(all) - len, "%s", left);
	}
	console_print(id, "%s", all);
}

// [ NVAULT ]
// public nvault_save(id) {
// 	keep_file = nvault_open("nvault_test");   // nvault handle
// 	new Vault_Key[64], Vault_data[100], N[4];
// 	get_user_name(id, Vault_Key, 63);
// 	replace_all(Vault_Key, 63, "'", "\'");
	
// 	for ( new i=0 ; i<=3 ; ++i )
// 		N[i] = random_num(1, 100);
		
// 	formatex(Vault_data, 99, "%d#%d#%d#%d#", N[0],N[1],N[2],N[3]); // "77#88#99#1010#"
// 	console_print(0, "Vault_data: %s", Vault_data);
	
// 	nvault_set(keep_file, Vault_Key, Vault_data);
// 	nvault_close(keep_file);
// }
// public nvault_load(id) {
// 	keep_file = nvault_open("nvault_test");   // nvault handle
// 	new Vault_Key[64], Vault_data[100], User_data[4];
// 	get_user_name(id, Vault_Key, 63);
// 	replace_all(Vault_Key, 63, "'", "\'");
	
// 	new left[10];
// 	nvault_get(keep_file, Vault_Key, Vault_data, 99);  // Vault_data is "77#88#99#1010#"
// 	for (new i=0; i< sizeof(User_data); i++) {
// 		strtok(Vault_data, left, sizeof(left)-1, Vault_data, sizeof(Vault_data)-1, '#');
// 		User_data[i] = str_to_num(left);
// 	}
// 	console_print(id, "%d - %d - %d - %d", User_data[0],User_data[1],User_data[2],User_data[3]);
// 	console_print(id, "%d", User_data[0]+User_data[1]+User_data[2]+User_data[3]);
// 	nvault_close(keep_file);
// }
public set_Respawn(id) {
	cs_user_spawn(id);
	fm_give_item(id, "weapon_knife");
	return PLUGIN_HANDLED;
}
public become_color(id) {
	color_switch[id] *= (-1);
}
public block_drop(id) {
	client_print(id, print_center, "Drop block.");
	return PLUGIN_HANDLED;
}
public bomb_planting(planter) {
	if ( !is_user_admin(planter) )
		user_slap(planter, 0, 0);
}
// public client_putinserver(id) {
// 	cs_set_user_team(id, CS_TEAM_T, 0);
// 	set_task(0.1, "DeathPost", id);
// }
public amx_menu(id) {
	client_cmd(id, "amx_menu");
}
stock trace_effect(id) {
	new start[3], end[3];
	get_user_origin(id, start, 1);
	get_user_origin(id, end, 3);

	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_TRACER);
	write_coord(start[0]);
	write_coord(start[1]);
	write_coord(start[2]);
	write_coord(end[0]);
	write_coord(end[1]);
	write_coord(end[2]);
	message_end();
}
stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;
	#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
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

		// static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"));
		// if( !pev_valid(ent) ) return;
		// entity_set_string(ent, EV_SZ_classname, "buil");
		// engfunc(EngFunc_SetModel, ent, "sprites/plasma_beam.spr");
		// set_pev(ent, pev_mins, Float:{-0.1, -0.1, -0.1});
		// set_pev(ent, pev_maxs, Float:{0.1, 0.1, 0.1});
		// set_pev(ent, pev_scale, 2.0);
		// set_pev(ent, pev_movetype, MOVETYPE_FLY);
		// set_pev(ent, pev_solid, SOLID_TRIGGER);
		// set_pev(ent, pev_origin, origin);
		// set_pev(ent, pev_gravity, 0.01);
		// // xs_vec_add(this_aim, random_velocity, this_aim);
		// set_pev(ent, pev_velocity, this_aim);
		// set_pev(ent, pev_iuser1, this);

// public fw_Touch_buil(ent, id) {
// 	if( !pev_valid(ent) ) return;

// 	static attacker; attacker = pev(ent, pev_iuser1);
// 	if ( is_user_alive(id) )  
// 		ExecuteHamB(Ham_TakeDamage, id, 0, attacker, 3.0, DMG_ACID);

// 	engfunc(EngFunc_RemoveEntity, ent);
// }