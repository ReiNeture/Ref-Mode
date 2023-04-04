#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

new const killEffectSound[] = "ref/hit1.wav"

public plugin_init()
{
	register_plugin("擊殺效果", "1.0", "Reff")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, killEffectSound);
}

public fw_PlayerKilled(this, attack, shouldgib)
{
	if ( !is_user_alive(attack) || !is_user_connected(attack) ) 
		return HAM_IGNORED

	// 擊殺音效
	emit_sound(attack, CHAN_STATIC, killEffectSound, 1.0, ATTN_NORM, 0, PITCH_NORM)

	// 擊殺後螢幕顏色效果
	/*
	engfunc(EngFunc_MessageBegin, MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, attack)
	write_short(1<<10)
	write_short(1<<9)
	write_short(0x0000)
	write_byte(0)
	write_byte(235)
	write_byte(0)
	write_byte(20)
	message_end()
	*/
	
	return HAM_IGNORED
}