#include <amxmodx>
#include <hamsandwich>

#define RESPAWN_TIME 0.16

public plugin_init()
{
    register_plugin("自動重生", "1.0", "Reff")
    register_event("DeathMsg", "eventPlayerDeath", "a")
    register_event("DeathMsg", "eventPlayerDeath", "bg")
}

public eventPlayerDeath()
{
	new id = read_data(2)
	set_task(RESPAWN_TIME, "DeathPost", id)
}

public DeathPost(id)
{
	if( is_user_alive(id) ) return
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}