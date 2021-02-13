#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

native test_tr(id);      // 財寶
native open_refmenu(id); // 內部特選
native ref_get_level(id);

new const SoundFiles[6][] =
{
	"ref/hit1.wav",
	"ref/miss1.wav",
	"ref/miss2.wav",
	"ref/miss3.wav",
	"ref/helmet_hit.wav",
	"ref/knife_slash1.wav"
}
new chick;
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
new mainmenu[512];
new freemenu[256];
new blessing[256]; 

new bool:gChangedFree[33];
new gChangedChicken[33];

public plugin_init()
{//set_pdata_int(id, OFFSET_AMMO[g_WeaponID], AMMO, OFFSET_LINUX)
	register_plugin("RefMainSystem", "1.0", "Reff");

	register_clcmd("chooseteam", "createMainMenu");

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_world");

	register_event("DeathMsg", "eventPlayerDeath", "a");
	register_event("DeathMsg", "eventPlayerDeath", "bg");
	register_event("CurWeapon", "event_curweapon", "be", "1=1");

	register_menucmd(register_menuid("MainMenu"), KEYSMENU, "handleMainMenu");
	register_menucmd(register_menuid("FreeWeaponMenu"), KEYSMENU, "handleFreeWeaponMenu");
	register_menucmd(register_menuid("ChickenMenu"), KEYSMENU, "handleChickenMenu");
}

public plugin_precache()
{
	for (new i=0; i < sizeof(SoundFiles); i++) {
		engfunc(EngFunc_PrecacheSound, SoundFiles[i]);
	}
	chick = engfunc(EngFunc_PrecacheModel, "models/chick.mdl");
	createAllMenu();
}

public createAllMenu()
{
	new size = sizeof(mainmenu);
	add(mainmenu, size, "\y遊戲主選單 \w(Game Menu)^n^n");
	add(mainmenu, size, "\w你可以在案\rM\w再次開啟此選單^n");
	add(mainmenu, size, "\w(You can press \r'M'\w to open this menu again.)^n^n");
	add(mainmenu, size, "\r1. \w選擇免費武器^n\y(Choose free weapons)^n^n");
	add(mainmenu, size, "\r2. \w基礎特殊選單: 等級需求50^n\y(Basic special menu: Level required 50)^n^n");
	add(mainmenu, size, "\r3. \w進階特殊選單: 等級需求200^n\y(Advanced special menu: Level required 200)^n^n");
	add(mainmenu, size, "\r4. \w重生^n\y(Respawn)^n^n^n");
	add(mainmenu, size, "\r0. \w關閉 (Close menu)^n");

	size = sizeof(freemenu);
	add(freemenu, size, "\w重生再次選取 (When respawn selecting again) ^n^n");
	add(freemenu, size, "\r1. \wAK-47 ^n");
	add(freemenu, size, "\r2. \wM4A1 ^n");
	add(freemenu, size, "\r3. \wMP5 ^n");
	add(freemenu, size, "\r4. \wDesert Eagle ^n");
	add(freemenu, size, "\r5. \wUSP ^n");
	add(freemenu, size, "\r6. \wFAMAS ^n");
	add(freemenu, size, "\r7. \wM249 ^n");
	add(freemenu, size, "\r8. \wAUG ^n^n");
	add(freemenu, size, "\r0. \wClose ^n");

	size = sizeof(blessing);
	add(blessing, size, "\w雞雞的祝福 (Chicken blessing) ^n^n");
	add(blessing, size, "\r0. \w雞雞的被動(自動開啟)^n(Automatic switch on)");
	add(blessing, size, "\y擊殺敵人能補血上限1000^n^n");
	add(blessing, size, "\r開啟雞雞的祝福能夠增加攻擊速度及傷害^n\y(Increase weapon attack speed and damage)^n^n");
	add(blessing, size, "\r1. \w雞雞的祝福C^n(Chicken blessing level C)^n");
	add(blessing, size, "\r2. \w雞雞的祝福B^n(Chicken blessing level B)^n");
	add(blessing, size, "\r3. \w雞雞的祝福A^n(Chicken blessing level A)^n");
}

public createChickenMenu(id)
{
	show_menu(id, KEYSMENU, blessing, -1, "ChickenMenu");
	return PLUGIN_HANDLED;
}
public handleChickenMenu(id, key)
{

}

public createMainMenu(id)
{
	show_menu(id, KEYSMENU, mainmenu, -1, "MainMenu");
	return PLUGIN_HANDLED;
}
public handleMainMenu(id, key)
{
	switch(key)
	{
		case 0: createFreeWeaponMenu(id);
		case 1: {return PLUGIN_HANDLED;}
		case 2: {
			if( ref_get_level(id) >= 200)
				open_refmenu(id);
			else
				client_print(id, print_chat, "等級不足");
		}
		case 3: DeathPost(id);
		case 9: menu_destroy(KEYSMENU);
		default: createMainMenu(id);
	}
	return PLUGIN_HANDLED;
}

public createFreeWeaponMenu(id)
{
	if(gChangedFree[id]) return PLUGIN_HANDLED;
	show_menu(id, KEYSMENU, freemenu, -1, "FreeWeaponMenu");
	return PLUGIN_HANDLED;
}
public handleFreeWeaponMenu(id, key)
{
	gChangedFree[id] = true;
	switch(key) {
		case 0: {
			fm_give_item(id, "weapon_ak47") ;
			cs_set_user_bpammo(id, CSW_AK47, 90);
		}
		case 1: {
			fm_give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 90);
		}
		case 2: {
			fm_give_item(id, "weapon_mp5navy");
			cs_set_user_bpammo(id,CSW_MP5NAVY,90);
		}
		case 3: {
			fm_give_item(id, "weapon_deagle");
			cs_set_user_bpammo(id,CSW_DEAGLE,90);}
		case 4: {
			fm_give_item(id, "weapon_usp") ;
			cs_set_user_bpammo(id,CSW_USP,90);
		}
		case 5: { 
			fm_give_item(id, "weapon_famas");
			cs_set_user_bpammo(id,CSW_FAMAS,90);
		}
		case 6: {
			fm_give_item(id, "weapon_m249");
			cs_set_user_bpammo(id,CSW_M249,120);
		}
		case 7: {
			fm_give_item(id, "weapon_aug");
			cs_set_user_bpammo(id,CSW_AUG,90);
		}
		default: { menu_destroy(KEYSMENU); gChangedFree[id] = false;}
	}
	return PLUGIN_HANDLED;
}

public fw_PlayerKilled(this, attack, shouldgib)
{
	if ( !is_user_alive(attack) || !is_user_connected(attack) ) return PLUGIN_HANDLED;

	// 擊殺音效控制
	static Float:thisOrigin[3], Float:attOrigin[3], distance;
	pev(this,   pev_origin, thisOrigin);
	pev(attack, pev_origin, attOrigin );

	distance = floatround(get_distance_f(thisOrigin, attOrigin));

	new Float:volume;
	switch (distance/100) {
		case 0: volume = 1.0;
		case 1..3: volume = 0.8;
		case 4..5: volume = 0.7;
		case 6..7: volume = 0.6;
		default:   volume = 0.4;
	}
	emit_sound(attack, CHAN_STATIC, SoundFiles[0], volume, ATTN_NORM, 0, PITCH_NORM);

	// 擊殺補血控制
	new Float:heal = float(pev(attack, pev_health));
	if( heal < 1000.0 )
		set_pev(attack, pev_health, heal+10.0);

	engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, attack);
	write_short(1<<10); // Duration --> Note: Duration and HoldTime is in special units. 1 second is equal to (1<<12) i.e. 4096 units.
	write_short(1<<9); // Holdtime
	write_short(0x0000); // 0x0001 Fade in
	write_byte(0);
	write_byte(255);
	write_byte(0);
	write_byte(20);  // Alpha
	message_end();


	// 擊殺噴小雞
	new Float:this_aim[3], this_origin[3];
	get_user_origin(this, this_origin, 0);
	velocity_by_aim(attack, 780, this_aim);

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
	write_byte(30); // random velocity
	write_short(chick);
	write_byte(3); // count
	write_byte(10); // life 0.1's
	write_byte(4); // 1 : Glass sounds and models draw at 50% opacity  2 : Metal sounds  4 : Flesh sounds  8 : Wood sounds  64 : Rock sounds 
	message_end();

	return PLUGIN_HANDLED;
}
public fw_TraceAttack_world(this, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if( get_user_weapon(id) != CSW_KNIFE) {
		new Float:end[3];
		new start[3];
		get_tr2(tracehandle, TR_vecEndPos, end);
		get_user_origin(id, start, 1);

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
		write_byte(TE_TRACER);
		write_coord(start[0]);
		write_coord(start[1]);
		write_coord(start[2]);
		write_coord(floatround(end[0]));
		write_coord(floatround(end[1]));
		write_coord(floatround(end[2]));
		message_end();
	}
}
public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) && !is_user_connected(id))
		return PLUGIN_HANDLED;

	gChangedFree[id] = false;
	createMainMenu(id);
	fm_strip_user_weapons(id);
	fm_give_item(id, "weapon_knife");
	
	if ( is_user_bot(id) )
		set_pev(id, pev_health, random_float(200.0, 500.0));

	return PLUGIN_CONTINUE;
}

public event_curweapon(id)
{
	if( !is_user_alive(id)) return PLUGIN_CONTINUE;
	new weaponID= read_data(2);
	
	if(weaponID==CSW_C4 || weaponID==CSW_KNIFE || weaponID==CSW_HEGRENADE || weaponID==CSW_SMOKEGRENADE || weaponID==CSW_FLASHBANG)
		return PLUGIN_CONTINUE;
		
	cs_set_user_bpammo(id, weaponID, 120);

	return PLUGIN_CONTINUE;
}
public client_putinserver(id)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;

	set_task(1.0, "checkIsAlivePost", id);

	return PLUGIN_HANDLED;
}
public checkIsAlivePost(id)
{
	if(!is_user_connected(id)) return;
	if(!is_user_alive(id)) DeathPost(id);
}
public eventPlayerDeath()
{
	new index = read_data(2);
	set_task(0.16, "DeathPost", index);
}
public DeathPost(index)
{
	if(!is_user_alive(index)) {
		set_pev(index, pev_deadflag, DEAD_RESPAWNABLE);
		dllfunc(DLLFunc_Spawn, index);
		set_pev(index, pev_iuser1, 0);
	}
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
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return;

	static Float:originF[3], save
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;

	engfunc(EngFunc_RemoveEntity, ent)
}
stock fm_create_entity(const classname[])
{
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
}