#include <amxmodx>
#include <d2lod>
#include <engine>
#include <hamsandwich>
#include <fakemeta>

new PLUGIN_NAME[] = "Diablo II LOD 怪物補助插件"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

#define MAX_MONSTERS 15

#define COINS_CLASSNAME "CoinsMonster"

new const Monster_Models[MAX_MONSTERS][] =
{
	"models/agrunt.mdl",
	"models/big_mom.mdl",
	"models/bullsquid.mdl",
	"models/controller.mdl",
	"models/garg.mdl",
	"models/headcrab.mdl",
	"models/houndeye.mdl",
	"models/islave.mdl",
	"models/w_squeak.mdl",
	"models/zombie.mdl",
	"models/hgrunt.mdl",
	"models/tentacle.mdl",
	"models/babygarg.mdl",
	"models/bigrat.mdl",
	"models/gonome.mdl"
}
new const Monster_Xp[MAX_MONSTERS] =
{
	1700,
	600,
	10000,
	120,
	0,
	100,
	0,
	120,
	0,
	800,
	0,
	0,
	0,
	0,
	7500
}
new const Monster_Coins[MAX_MONSTERS] =
{
	20,
	70,
	10,
	20,
	0,
	3,
	0,
	25,
	0,
	15,
	0,
	0,
	0,
	0,
	125
}
new const Monster_Names[MAX_MONSTERS][] =
{
	"異型戰士",
	"大媽 (王)",
	"鱷魚",
	"首腦",
	"巨人 (王)",
	"食腦蟲",
	"百募狗",
	"弗地崗人",
	"聖甲蟲",
	"殭屍",
	"人類戰士",
	"鷹爪",
	"小型巨人 (王)",
	"老鼠",
	"殭屍王"
}

new g_iMaxPlayers;
new Float:times[33];

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	RegisterHam(Ham_Killed, "func_wall", "Monster_Killed");
	RegisterHam(Ham_Player_PreThink, "player", "fw_Monster_PreThink");

	register_touch( COINS_CLASSNAME, "player", "Coins_Pickup")

	register_logevent("Event_Round_End", 2, "1=Round_End");

	g_iMaxPlayers = get_maxplayers();
}

public Event_Round_End()
{
	Remove_All_Coin_Ents();
}

public Monster_Killed(this, idattacker, shouldgib)
{
	if ( !( 1 <= idattacker <= g_iMaxPlayers ) || !is_valid_ent(this) || !get_player_logged(idattacker) )
		return HAM_IGNORED;

	new MonsterMdl[32];

	entity_get_string( this, EV_SZ_model, MonsterMdl, charsmax(MonsterMdl) );

	for(new monsters = 0; monsters < MAX_MONSTERS; monsters++) 
	{
		if( equal( MonsterMdl, Monster_Models[monsters] ) ) 
		{
			new exp = Monster_Xp[monsters]*get_exp_scale()
			if ( Monster_Xp[monsters] > 0 )
				set_p_xp( idattacker, get_p_xp(idattacker) + exp);

			new coin;
			if ( Monster_Coins[monsters] > 0 && is_user_alive(idattacker) ) {

				coin = Monster_Coins[monsters];
				set_p_gold( idattacker, get_p_gold(idattacker) + coin );
				// drop_coins( this, COINS_CLASSNAME, Monster_Coins[monsters] + (get_p_level(idattacker) / 4) );
			}
			client_print( idattacker, print_center, "你殺了 %s, +%d經驗, +%d金錢", Monster_Names[monsters], exp, coin);
		}
	}

	return HAM_IGNORED;
}

public fw_Monster_PreThink(this, idattacker)
{
	if(!is_valid_ent(this) || halflife_time() < times[this] ) return HAM_IGNORED

	times[this] = halflife_time() + 0.07;
	new iTarget, iTemp, szMonsterModel[33], szClassname[33]; //, szCheckModel[33]

	get_user_aiming(this, iTarget, iTemp);
	entity_get_string(iTarget, EV_SZ_model, szMonsterModel, sizeof(szMonsterModel));
	entity_get_string(iTarget, EV_SZ_classname, szClassname, sizeof(szClassname));

	for(new i = 0; i < MAX_MONSTERS; i++)
	{
		// format(szCheckModel, sizeof(szCheckModel), "models/%s.mdl", Monster_Models[i])
		if(equal(szClassname, "func_wall"))
		{
			if(equal(szMonsterModel, Monster_Models[i]))
			{
				set_hudmessage(0, 191, 255, 0.10, 0.55, 0, 0.0, 0.2, 0.0, 0.0, 4)
				show_hudmessage(this, "怪物: %s^n血量: %d^n經驗: %d", Monster_Names[i], floatround(entity_get_float(iTarget, EV_FL_health)), Monster_Xp[i] * get_exp_scale())
			}
		}
	}
	return HAM_HANDLED
}

// Touch, coins
public Coins_Pickup(ptr, ptd)
{
	if( is_user_alive(ptd) && pev_valid(ptr) ) 
	{ 	
		new gold = entity_get_int(ptr , EV_INT_iuser1)

		set_p_gold(ptd, get_p_gold(ptd) + gold)
					
		remove_entity(ptr)
	}
}
public Remove_All_Coin_Ents()
{
	new coin_ent = find_ent_by_class(-1, COINS_CLASSNAME)
	
	while ( coin_ent ) 
	{
		remove_entity(coin_ent)
		coin_ent = find_ent_by_class(coin_ent, COINS_CLASSNAME)
	}
}