#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

#define TEAM_SELECT_VGUI_MENU_ID 2
#define PASSWORD_MAXCHAR 20

new const filename[] = "addons/amxmodx/configs/refregister.ini";
// new const regex[16][] = {',', ' ', '!', '@', '#', '$', '&', '*', '(', ')', '%', '<', '>', '_', '+', '-', '/'}

new bool:Registed[33];
new bool:Logied[33];
new password[33][PASSWORD_MAXCHAR+1];
new TempPassword[33][PASSWORD_MAXCHAR+1];

public plugin_init()
{
	register_plugin("RefRegisterSystem", "1.0", "Reff");

	register_clcmd("rt", "displayMainMenu");
	register_clcmd("ref_register", "controlRegister");
	register_clcmd("ref_login", "controlLogin");

	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu")
}

public plugin_natives()
{ 
	register_native("get_login_status", "native_get_login_status", 1);
	register_native("show_login_menu", "displayMainMenu", 1);
}

public displayMainMenu(id)
{
	new szMsg[60];
	formatex(szMsg, 59, "湊あくあ 総長: ")
	new menu = menu_create(szMsg , "handleMainMenu");

	menu_additem(menu, "登入", "0", 0);
	menu_additem(menu, "註冊", "1", 0);
	menu_display(id, menu, 0); 
}

public handleMainMenu(id , menu , item) 
{ 	
	if(item == MENU_EXIT) { 
		menu_destroy(menu); 
		return PLUGIN_HANDLED;
	} 

	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);

	switch(key)
	{
		case 0: toLogin(id);
		case 1: toRegister(id);
    }

	menu_destroy(menu); 
	return PLUGIN_HANDLED;
}

toLogin(id)
{
	if( !checkRegisterStatus(id) ) {
		client_printcolor(id, "/y[/g你還沒有註冊 請先註冊/y]");
		displayMainMenu(id);
		return;
	} else {
    	client_printcolor(id, "/y[/g請輸入密碼登入/y]");
    	client_cmd(id, "messagemode ref_login");
	}
}

toRegister(id)
{
	if( checkRegisterStatus(id) ) {
		client_printcolor(id, "/y[/g你已經註冊過了 請登入/y]");
		displayMainMenu(id);
		return;
	} else {
    	client_printcolor(id, "/y[/g請輸入密碼註冊/y]");
    	client_cmd(id, "messagemode ref_register");
	}
}

public controlLogin(id)
{
	new args[64];
	read_args(args, charsmax(args));
	remove_quotes(args);
	trim(args);

	if( checkInputVaild(id, args) ) {

		if( equal(password[id], args) ) {
			Logied[id] = true;
			client_cmd(id, "jointeam");
			client_printcolor(id, "/y[/g你已成功登入/y]");

		} else {
			client_printcolor(id, "/y[/g密碼輸入錯誤/y]");
			displayMainMenu(id);
		}

	}
}

public controlRegister(id)
{
	new args[64];
	read_args(args, charsmax(args));
	remove_quotes(args);
	trim(args);

	if( checkInputVaild(id, args) ) {
		copy(TempPassword[id], charsmax(TempPassword), args);
		confirmPasswordMenu(id);
	} else
		displayMainMenu(id);
}

checkInputVaild(id, const args[])
{
	new len = strlen(args);

	for(new i = 0; i < len; ++i) {
		if( args[i] == ',' || args[i] == ' ' || args[i] == '!' || args[i] == '@' || args[i] == '#' || args[i] == '$' || args[i] == '&' || args[i] == '*' || args[i] == '(' || args[i] == ')' || args[i] == '%' || args[i] == '<' || args[i] == '>' || args[i] == '_' || args[i] == '+' || args[i] == '-' || args[i] == '/' ) {
			client_printcolor(id, "/y[/g輸入值請勿包含特殊字元/y]");
			return false;
		}
	}

	if( len < 4 || len > PASSWORD_MAXCHAR) {
		client_printcolor(id, "/y[/g輸入值長度請大於/ctr4/g個字小於/ctr%d/g個字/y]", PASSWORD_MAXCHAR);
		return false;
	}

	return true;
}

writePasswordToFile(const name[], const args[])
{
	new files = fopen(filename, "a");
	new data[128];
	formatex(data, charsmax(data), "^"%s^" ^"%s^"^n", name, args);

	new temp = fputs(files, data);
	fclose(files);
	return temp;
}

confirmPasswordMenu(id)
{
	new szMsg[60];
	formatex(szMsg, charsmax(szMsg), "\w湊あくあ 総長: \y確認你的註冊密碼為 \r%s \y?", TempPassword[id]);
	new menu = menu_create(szMsg , "handleconfirmPasswordMenu");

	menu_additem(menu, "確定", "0", 0);
	menu_additem(menu, "取消", "1", 0);
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0); 
}

public handleconfirmPasswordMenu(id , menu , item) 
{ 
	if(item == MENU_EXIT) { 
		menu_destroy(menu); 
		return PLUGIN_HANDLED;
	} 
	
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback);
	new key = str_to_num(data);

	switch(key) {
		case 0: finishConfirm(id);
		case 1: displayMainMenu(id);
    }

	menu_destroy(menu); 
	return PLUGIN_HANDLED;
}

public finishConfirm(id)
{
	new name[64];
	get_user_name(id, name, charsmax(name));

	if( writePasswordToFile(name, TempPassword[id]) == 0 ) {
		Registed[id] = true;
		password[id] = TempPassword[id];
		client_printcolor(id, "/y[/g註冊成功 你的密碼是 /ctr %s/y]", password[id]);
		client_printcolor(id, "/y[/g註冊成功 你的密碼是 /ctr %s/y]", password[id]);
		client_printcolor(id, "/y[/g註冊成功 你的密碼是 /ctr %s/y]", password[id]);
	}
}

public getPasswordByPlayerName(id)
{
	new name[64], data[256];
	new detail[64], detail2[PASSWORD_MAXCHAR+1];
	get_user_name(id, name, charsmax(name));

	new files = fopen(filename, "r");
	while (!feof(files) ) {
		// 讀取
		if( fgets(files, data, charsmax(data)) == 0 )
			continue;

		if ( data[0] == ';' || data[0] == '[' )
			continue;

		if ( parse(data, detail, charsmax(detail), detail2, charsmax(detail2)) < 1)
			continue;

		// 取得密碼
		if( equal(detail, name) ) {
			Registed[id] = true;
			copy(password[id], charsmax(password), detail2);
			break;
		}
	}
	fclose(files);
}

checkRegisterStatus(id)
{
    return Registed[id];
}

public client_putinserver(id)
{
	Logied[id] = false;
	Registed[id] = false;
	set_task(0.2, "getPasswordByPlayerName", id);
	set_task(0.2, "displayMainMenu", id);
}

public message_vgui_menu(msgid, dest, id) {
	if (get_msg_arg_int(1) != TEAM_SELECT_VGUI_MENU_ID ) return PLUGIN_CONTINUE;

	if( !Logied[id] ) return PLUGIN_HANDLED;   // 阻擋未登入玩家進入時開啟隊伍選單
	
	static param_menu[1];
	param_menu[0] = msgid;
	set_task(0.1, "Task_VGUI", id, param_menu, sizeof param_menu);

	return PLUGIN_CONTINUE;
}

public Task_VGUI(param_menu[], id)
{
	if ( !is_user_connected(id) ) return;
	
	// 登入後自動開啟隊伍選單 並強制選擇TR隊伍
	static Msg_Block;
	Msg_Block = get_msg_block( param_menu[0] );
	set_msg_block(param_menu[0], BLOCK_SET);
	engclient_cmd(id, "jointeam", "1");
	engclient_cmd(id, "joinclass", "1");
	set_msg_block(param_menu[0], Msg_Block);
}

public native_get_login_status(id)
{
	return Logied[id];
}

stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32];

	static msg[191];
	vformat(msg,190,input,3);

	replace_all(msg,190,"/g","^4");// 綠色文字.
	replace_all(msg,190,"/y","^1");// 橘色文字.
	replace_all(msg,190,"/ctr","^3");// 隊伍顏色文字.

	if (id) players[0] = id; 
	else get_players(players,count,"ch");

	for (new i=0;i<count;i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
	}
}