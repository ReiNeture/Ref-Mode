#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

enum
{
	B1 = 1 << 0, B2 = 1 << 1, B3 = 1 << 2, B4 = 1 << 3, B5 = 1 << 4,
	B6 = 1 << 5, B7 = 1 << 6, B8 = 1 << 7, B9 = 1 << 8, B0 = 1 << 9,
};

const MAX_FUNC = 2;
enum
{
	FUNC_SWITCH = 0,
	FUNC_PLAYBACK
};

const MAX_PLAYBACK = 3;
new const PlaybackMode[MAX_PLAYBACK][] = 
{
	"隨機播放",
	"單一循環",
	"播放一次"
}
enum
{
	PLAY_RANDOM = 0,
	PLAY_REPEAT,
	PLAY_ONCE
};

const MAX_TRACK = 9;
new const MusicTrackName[MAX_TRACK][] = 
{
    "此花亭 - 菊地創",
    "眩しさの中 - 水月陵",
    "蘭の香り - 水月陵",
    "ReminiscE - 金閉開羅巧夢",
    "Time left - 天門&柳英一郎",
    "サクラ - 暫無",
    "耐える冬 - 暫無",
	"夢の歩みを見上げて - 松本文紀",
    "竜姫 奏でる - 渡邊崇"
}

new const MusicFiles[MAX_TRACK][] = 
{
	"ref/konohana.mp3",
	"ref/mabusiisa.mp3",
	"ref/kaori.mp3",
	"ref/ReminiscE.mp3",
	"ref/TimeLeft.mp3",
	"ref/narcissusakura.mp3",
	"ref/narcissufuyu.mp3",
	"ref/yumenoarumi.mp3",
	"ref/ryuhime.mp3"
}

new const Float:MUSIC_TASK[MAX_TRACK] = 
{
	101.0,
	260.0,
	149.0,
	150.0,
	185.0,
	139.0,
	142.0,
	134.0,
	92.0
}

const Float:fDelay = 7.0;
const preItem = 5;

new gKeySelectMenu, gMenuPagesMax;
new bool:playStatus[33];

new pages[33], playingTrack[33], nextTrack[33], features[33];
new playBack[33];

public plugin_init()
{
	register_plugin("RefRegisterSystem", "1.0", "Reff");
	register_clcmd("refbgm", "showMusicSelectMenu");

	MenuConstructor();
	register_menucmd(register_menuid("MusicSelectMenu"), gKeySelectMenu, "handleMusicSelectMenu");
}

public plugin_precache()
{
	for (new i=0; i < sizeof(MusicFiles); i++) 
		engfunc(EngFunc_PrecacheSound, MusicFiles[i]);
}

public plugin_natives()
{ 
	register_native("get_music_menu", "showMusicSelectMenu", 1);
}

MenuConstructor()
{
	gMenuPagesMax = floatround((float(MAX_TRACK) / float(preItem) ), floatround_ceil) - 1;
	gKeySelectMenu = (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 );
}

public showMusicSelectMenu(id)
{
	new szMenu[512], szEntry[128], szColor[3];

	formatex(szEntry, sizeof(szEntry), "湊あくあ 総長: \r播放音樂的音樂盒  \y%d/%d^n^n", pages[id]+1, gMenuPagesMax+1);
	add(szMenu, sizeof(szMenu), szEntry);

	formatex(szEntry, sizeof(szEntry), "\y7\w. 功能切換 & 重新整理^n" );
	add(szMenu, sizeof(szMenu), szEntry);

	switch( features[id] ) {
		case FUNC_SWITCH:
			formatex(szEntry, sizeof(szEntry), "\y8\w. 開關: %s^n^n", (isPlaying(id) ? "\r停止" : "\y播放" ));
		case FUNC_PLAYBACK:
			formatex(szEntry, sizeof(szEntry), "\y8\w. 播放順序: %s^n^n", PlaybackMode[ playBack[id] ]);
	}
	add(szMenu, sizeof(szMenu), szEntry);

	if( playingTrack[id] >= 0 )
		formatex(szEntry, sizeof(szEntry), "\y[\w 播放中 \r: \w%s \y]^n", MusicTrackName[ playingTrack[id] ]);
	else
		formatex(szEntry, sizeof(szEntry), "\y[\w 播放中 \r: \w無正在播放歌曲 \y]^n");
	add(szMenu, sizeof(szMenu), szEntry);

	formatex(szEntry, sizeof(szEntry), "\y[\w 下一首 \r: \w%s \y]^n^n", MusicTrackName[ nextTrack[id] ]);
	add(szMenu, sizeof(szMenu), szEntry);
	

	new start = pages[id] * preItem;
	new end = (pages[id] + 1) * (preItem - 1);
	new seqno; 

	for(new i = start; i <= end; ++i) {
		seqno = (i - start) + 1;
		szColor = ( nextTrack[id] == i ? "\r" : "\w" );

		// 音軌選項
		if( i < MAX_TRACK )
			formatex(szEntry, sizeof(szEntry), "\y%d\w. %s%s^n", seqno, szColor, MusicTrackName[i]);
		else
			formatex(szEntry, sizeof(szEntry), " ^n");

		add(szMenu, sizeof(szMenu), szEntry);
	}
	add(szMenu, sizeof(szMenu), " ^n");

	if( pages[id] < gMenuPagesMax )
		add(szMenu, sizeof(szMenu), "^n\r0\y. \w下一頁");
	else if( pages[id] >= gMenuPagesMax )
		add(szMenu, sizeof(szMenu), "^n\r0\y. \w回第一頁");

	show_menu(id, gKeySelectMenu, szMenu, -1, "MusicSelectMenu");
}

public handleMusicSelectMenu(id, num)
{
	new p = pages[id];
	switch(num)
	{
		case 6: {  // 功能切換
			features[id] = (++features[id] % MAX_FUNC);
		}
		case 7: doFeatures(id);  // 執行功能
		case 9: {  // 下一頁
			if( ++p <= gMenuPagesMax ) pages[id] = p;
			else pages[id] = 0;
		}
		// case 9: {  // 上一頁
		// 	if( --p >= 0 ) pages[id] = p;
		// }
		default: {  // 歌曲選擇
			num += ( preItem * pages[id] );
			if ( num < MAX_TRACK )
			{
				nextTrack[id] = num;
				client_printcolor(id, "\y[\g你選擇了\ctr %s \g為下一次播放曲目\y]", MusicTrackName[num] );
			}
		}
	}
	showMusicSelectMenu(id);
	return PLUGIN_HANDLED;
}

doFeatures(id)
{
	new selectFeatures = features[id];
	switch( selectFeatures )
	{
		case FUNC_SWITCH: isPlaying(id) ? stopMusic(id) : automaticPlaySelectMusic(id+7866);
		case FUNC_PLAYBACK: playBack[id] = (++playBack[id] % MAX_PLAYBACK);
	}
}

public automaticPlaySelectMusic(id)
{
	if( task_exists(id) ) remove_task(id);

	id = id - 7866;
	if( !is_user_connected(id) ) return;
	playSpecificTrack(id, nextTrack[id]);

	switch( playBack[id] )
	{
		case PLAY_RANDOM: setNextTrackRandom(id);
		case PLAY_REPEAT: return;
		case PLAY_ONCE: stopMusic(id);
	}
}

setNextTrackRandom(id)
{
	new track = nextTrack[id];
	while( track == nextTrack[id] )
		nextTrack[id] = random_num(0, MAX_TRACK-1);
}

playSpecificTrack(id, track)
{
	playingTrack[id] = track;
	playStatus[id] = true;
	client_cmd(id, "mp3 play ^"sound/%s^"", MusicFiles[track]);
	set_task(MUSIC_TASK[track]+fDelay, "automaticPlaySelectMusic", id+7866);
}

public stopMusic(id)
{
	if( task_exists(id+7866) )
		remove_task(id+7866);

	playingTrack[id] = -1;
	playStatus[id] = false;
	client_cmd(id, "mp3 stop");
}

public client_putinserver(id)
{
	stopMusic(id);
	nextTrack[id] = random_num(0, MAX_TRACK-1);
	set_task(fDelay-3.0, "automaticPlaySelectMusic", id+7866);
}

public client_disconnect(id)
{
	stopMusic(id);
}

public isPlaying(id)
{
	return playStatus[id];
}

stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32];

	static msg[191];
	vformat(msg,190,input,3);

	replace_all(msg,190,"\g","^4");// 綠色文字.
	replace_all(msg,190,"\y","^1");// 橘色文字.
	replace_all(msg,190,"\ctr","^3");// 隊伍顏色文字.

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
