#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <engine>

native get_music_menu(id);
native get_login_status(id);
native show_login_menu(id);
native open_refmenu(id);
native ref_get_level(id);
native get_hax_menu(id);

new const SoundFiles[6][] =
{
	"ref/hit1.wav",
	"ref/miss1.wav",
	"ref/miss2.wav",
	"ref/miss3.wav",
	"ref/helmet_hit.wav",
	"ref/knife_slash1.wav"
}
new const Float:ChickenAttackRate[4] = {1.0, 0.6, 0.4, 0.2};

new const OFFSET_AMMO[31] =  // bpammo
{
	0, 385, 0, 378, 0, 381, 0, 382, 380, 0, 386, 383, 382, 380, 380, 380, 382, 386, 377, 386, 379, 381, 380, 386, 378, 0, 384, 380, 378, 0, 383
}

const NOCLIP_WPN_BS    = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
const SHOTGUNS_BS    = ((1<<CSW_M3)|(1<<CSW_XM1014))

// weapons offsets
const m_pPlayer            = 41
const m_iId                = 43
const m_flNextPrimaryAttack    = 46
const m_flNextSecondaryAttack    = 47
const m_flTimeWeaponIdle        = 48
const m_fInReload            = 54
const m_flNextAttack = 83

stock const Float:g_fDelay[CSW_P90+1] = {
    0.00, 2.70, 0.00, 2.00, 0.00, 0.55,   0.00, 3.15, 3.30, 0.00, 4.50, 
         2.70, 3.50, 3.35, 2.45, 3.30,   2.70, 2.20, 2.50, 2.63, 4.70, 
         0.55, 3.05, 2.12, 3.50, 0.00,   2.20, 3.00, 2.45, 0.00, 3.40
}

new chick;
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
new mainmenu[512];
new freemenu[256];
new blessing[512]; 

new bool:gChangedFree[33];
new gChangedChicken[33], gChangedChicken2[33];

public plugin_init()
{
	register_plugin("RefMainSystem", "1.0", "Reff");

	register_clcmd("chooseteam", "createMainMenu");
	register_clcmd("say /menu", "createMainMenu");
	register_clcmd("say menu", "createMainMenu");
	register_clcmd("/menu", "createMainMenu");
	register_clcmd("menu", "createMainMenu");

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");

	register_event("DeathMsg", "eventPlayerDeath", "a");
	register_event("DeathMsg", "eventPlayerDeath", "bg");
	// register_event("ResetHUD", "event_hud_reset", "be")
	register_event("CurWeapon", "event_curweapon", "be", "1=1");

	register_menucmd(register_menuid("MainMenu"), KEYSMENU, "handleMainMenu");
	register_menucmd(register_menuid("FreeWeaponMenu"), KEYSMENU, "handleFreeWeaponMenu");
	register_menucmd(register_menuid("ChickenMenu"), KEYSMENU, "handleChickenMenu");

	new szWeapon[17];
	for(new i=1; i<=CSW_P90; i++)
	{
		if( !(NOCLIP_WPN_BS & (1<<i)) && get_weaponname(i, szWeapon, charsmax(szWeapon)) )
		{
			if( !(SHOTGUNS_BS & (1<<i)) )
			{
				RegisterHam(Ham_Item_PostFrame, szWeapon, "Item_PostFrame_Post", 1);
			}
		}
	}
	register_forward(FM_SetModel, "SetModel_Post", 1);
}

public plugin_precache()
{
	for (new i=0; i < sizeof(SoundFiles); i++) 
		engfunc(EngFunc_PrecacheSound, SoundFiles[i]);

	chick = engfunc(EngFunc_PrecacheModel, "models/chick.mdl");
	engfunc(EngFunc_PrecacheModel, "models/player/zombie_nnn/zombie_nnn.mdl");
	engfunc(EngFunc_PrecacheModel, "models/player/zombie_nnn/zombie_nnnT.mdl");
	createAllMenu();
}

public createAllMenu()
{
	new size = sizeof(mainmenu);
	add(mainmenu, size, "\y遊戲主選單 \w(Game Menu)^n^n");
	add(mainmenu, size, "\w你可以案\r M \w再次開啟此選單^n");
	add(mainmenu, size, "\w(You can press \r'M'\w to open this menu again.)^n^n");
	add(mainmenu, size, "\r1. \w選擇免費武器^n\y(Choose free weapons)^n^n");
	add(mainmenu, size, "\r2. \w基礎特殊選單: 等級需求100^n\y(Basic special menu: Level required 100)^n^n");
	add(mainmenu, size, "\r3. \w進階特殊選單: 等級需求200^n\y(Advanced special menu: Level required 200)^n^n");
	add(mainmenu, size, "\r4. \w雞雞的祝福 \y(Chicken blessing)^n^n");
	add(mainmenu, size, "\r5. \w音樂盒 <煩請開啟音樂> \y(Mp3 Player)^n^n");
	add(mainmenu, size, "\r6. \w重生 \y(Respawn)^n^n");

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
	add(blessing, size, "\w雞雞的祝福 \y(Chicken blessing)^n^n");
	add(blessing, size, "\y0. \r雞雞的被動(已自動開啟) \y(Automatic switch on)^n");
	add(blessing, size, "\y擊殺敵人能補血上限400^n^n");
	add(blessing, size, "\r開啟雞雞的祝福能夠增加換彈速^n\y(Increase weapon reload speed)^n^n");
	add(blessing, size, "\r1. %s雞雞的祝福C(lv.30)^n\y(Chicken blessing level C)^n^n");
	add(blessing, size, "\r2. %s雞雞的祝福B(lv.150)^n\y(Chicken blessing level B)^n^n");
	add(blessing, size, "\r3. %s雞雞的祝福A(lv.250)^n\y(Chicken blessing level A)^n^n^n");
	add(blessing, size, "\r4. %s雞雞祝福NR(lv.100) \y(提高槍傷3趴)^n");
	add(blessing, size, "\r5. %s雞雞祝福SR(lv.260) \y(提高槍傷5趴)^n");
}

public createChickenMenu(id)
{
	new col[3], col2[3], col3[3], col4[3], col5[3];
	new szMenu[512];
	
	col = (gChangedChicken[id] == 1) ? "\r" : "\w";
	col2 = (gChangedChicken[id] == 2) ? "\r" : "\w";
	col3 = (gChangedChicken[id] == 3) ? "\r" : "\w";

	col4 = (gChangedChicken2[id] == 4) ? "\r" : "\w";
	col5 = (gChangedChicken2[id] == 5) ? "\r" : "\w";

	format(szMenu, 512, blessing, col, col2, col3, col4, col5);
	show_menu(id, KEYSMENU, szMenu, -1, "ChickenMenu");
	
	return PLUGIN_HANDLED;
}
public handleChickenMenu(id, key)
{
	new const level[5] = {30, 150, 250, 100, 260};

	if( key>=0 && key<=2 && ref_get_level(id) >= level[key] )
		gChangedChicken[id] = key+1;
	else if( key>=3 && key<=4 && ref_get_level(id) >= level[key])
		gChangedChicken2[id] = key+1;
	else
		createChickenMenu(id);

	if(key==0 || key==1 || key==2|| key==3|| key==4)
		createChickenMenu(id);

	return PLUGIN_HANDLED;
}

public createMainMenu(id)
{
	if(is_user_bot(id) ) return PLUGIN_CONTINUE;

	if( get_login_status(id) )
		show_menu(id, KEYSMENU, mainmenu, -1, "MainMenu");
	else
		show_login_menu(id);

	return PLUGIN_HANDLED;
}

public handleMainMenu(id, key)
{
	switch(key)
	{
		case 0: createFreeWeaponMenu(id);
		case 1: {
			if( ref_get_level(id) >= 100)
				get_hax_menu(id);
			else
				client_print(id, print_chat, "等級不足 (Level required 100)");
		}
		case 2: {
			if( ref_get_level(id) >= 200)
				open_refmenu(id);
			else
				client_print(id, print_chat, "等級不足 (Level required 200)");
		}
		case 3: createChickenMenu(id);
		case 4: get_music_menu(id);
		case 5: DeathPost(id);
		default: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public createFreeWeaponMenu(id)
{
	if(gChangedFree[id]) return PLUGIN_CONTINUE;
	show_menu(id, KEYSMENU, freemenu, -1, "FreeWeaponMenu");
	return PLUGIN_HANDLED;
}
public handleFreeWeaponMenu(id, key)
{
	gChangedFree[id] = true;
	new wepId;
	switch(key) {
		case 0: {
			fm_give_item(id, "weapon_ak47") ;
			wepId = get_weaponid("weapon_ak47")
		}
		case 1: {
			fm_give_item(id, "weapon_m4a1");
			wepId = get_weaponid("weapon_m4a1")
		}
		case 2: {
			fm_give_item(id, "weapon_mp5navy");
			wepId = get_weaponid("weapon_mp5navy")
		}
		case 3: {
			fm_give_item(id, "weapon_deagle");
			wepId = get_weaponid("weapon_deagle")
		}
		case 4: {
			fm_give_item(id, "weapon_usp");
			wepId = get_weaponid("weapon_usp")
		}
		case 5: { 
			fm_give_item(id, "weapon_famas");
			wepId = get_weaponid("weapon_famas")
		}
		case 6: {
			fm_give_item(id, "weapon_m249");
			wepId = get_weaponid("weapon_m249")
		}
		case 7: {
			fm_give_item(id, "weapon_aug");
			wepId = get_weaponid("weapon_aug")
		}
		default: { gChangedFree[id] = false;}
	}

	set_pdata_int(id, OFFSET_AMMO[wepId], 120, 5);
	return PLUGIN_HANDLED;
}

public fw_PlayerKilled(this, attack, shouldgib)
{
	if ( !is_user_alive(attack) || !is_user_connected(attack) ) return HAM_IGNORED;

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
	if( heal < 400.0 )
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
	velocity_by_aim(attack, 880, this_aim);

	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_BREAKMODEL);
	write_coord(this_origin[0]);
	write_coord(this_origin[1]);
	write_coord(this_origin[2]+30);
	write_coord(16); // size x
	write_coord(16); // size y
	write_coord(16); // size z
	engfunc(EngFunc_WriteCoord, this_aim[0]); // write_coord(this_aim[0]); // velocity x 
	engfunc(EngFunc_WriteCoord, this_aim[1]); // write_coord(this_aim[1]); // velocity y
	engfunc(EngFunc_WriteCoord, this_aim[2]); // write_coord(this_aim[2]); // velocity z default 165
	write_byte(30); // random velocity
	write_short(chick);
	write_byte(2); // count
	write_byte(5); // life 0.1's
	write_byte(4); // 1 : Glass sounds and models draw at 50% opacity  2 : Metal sounds  4 : Flesh sounds  8 : Wood sounds  64 : Rock sounds 
	message_end();

	return PLUGIN_HANDLED;
}
public fw_TraceAttack(this, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(!is_user_connected(id) ) return HAM_IGNORED;

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

	if (gChangedChicken2[id] == 4) SetHamParamFloat(3, damage * 1.03);
	if (gChangedChicken2[id] == 5) SetHamParamFloat(3, damage * 1.05);

	return HAM_HANDLED;
}
public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) && !is_user_connected(id))
		return HAM_IGNORED;

	gChangedFree[id] = false;
	createMainMenu(id);
	fm_strip_user_weapons(id);
	fm_give_item(id, "weapon_knife");
	
	if ( is_user_bot(id) ) {
		cs_set_user_model(id, "zombie_nnn");
		set_pev(id, pev_health, random_float(2500.0, 2500.0));
	}

	return HAM_HANDLED;
}
public Item_PostFrame_Post(iEnt)
{    
    if( get_pdata_int(iEnt, m_fInReload, 4))
    {
		static id; id = get_pdata_cbase(iEnt, m_pPlayer, 4);
		if(gChangedChicken[id]) {
			new const Float:RELOAD_RATIO = ChickenAttackRate[gChangedChicken[id]];
			new Float:fDelay = g_fDelay[get_pdata_int(iEnt, m_iId, 4)] * RELOAD_RATIO;
			set_pdata_float(id, m_flNextAttack, fDelay, 5);
			set_pdata_float(iEnt, m_flTimeWeaponIdle, fDelay + 0.5, 4);
			set_pev(id, pev_framerate, RELOAD_RATIO);
		}
    }
} 
public SetModel_Post(entity, const model[])
{
	if (!pev_valid(entity)) return FMRES_IGNORED;

	new classname[32];
	pev(entity, pev_classname, classname, charsmax(classname));

	if (equal(classname, "weaponbox"))
		set_pev(entity, pev_nextthink, get_gametime());
	return FMRES_HANDLED;
} 

public event_curweapon(id)
{
	if( !is_user_alive(id)) return PLUGIN_CONTINUE;
	new weaponID= read_data(2);

	if(weaponID==CSW_C4 || weaponID==CSW_KNIFE || weaponID==CSW_HEGRENADE || weaponID==CSW_SMOKEGRENADE || weaponID==CSW_FLASHBANG)
		return PLUGIN_CONTINUE;

	set_pdata_int(id, OFFSET_AMMO[weaponID], 120, 5);
	return PLUGIN_HANDLED;
}

public client_putinserver(id)
{
	if(!is_user_connected(id) || is_user_bot(id) ) return PLUGIN_CONTINUE;

	set_task(1.0, "setChick", id);

	return PLUGIN_HANDLED;
}
public setChick(id)
{

	new lv = ref_get_level(id);
	if( lv >= 250 )
		gChangedChicken[id] = 3;
	else if( lv >= 150 )
		gChangedChicken[id] = 2;
	else if( lv >= 30)
		gChangedChicken[id] = 1;

	if( lv >= 260 )
		gChangedChicken2[id] = 5;
	else if( lv >= 100 )
		gChangedChicken2[id] = 4;
}

public eventPlayerDeath()
{
	new index = read_data(2);
	set_task(0.16, "DeathPost", index);
}
public DeathPost(index)
{
	if(is_user_alive(index) ) return;

	// set_pev(index, pev_deadflag, DEAD_RESPAWNABLE);
	// dllfunc(DLLFunc_Spawn, index);
	// set_pev(index, pev_iuser1, 0);
	ExecuteHamB(Ham_CS_RoundRespawn, index);
}

stock get_user_weaponame(id, szWeapon[20])
{
	new iWeapon = get_user_weapon(id);
	if ( iWeapon ) get_weaponname(iWeapon, szWeapon, 19);
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