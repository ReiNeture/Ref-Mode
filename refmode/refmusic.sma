#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

enum
{
	N1, N2, N3, N4, N5, N6, N7, N8, N9, N0
};

enum
{
	B1 = 1 << N1, B2 = 1 << N2, B3 = 1 << N3, B4 = 1 << N4, B5 = 1 << N5,
	B6 = 1 << N6, B7 = 1 << N7, B8 = 1 << N8, B9 = 1 << N9, B0 = 1 << N0,
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

const MAX_TRACK = 10;
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
    "竜姫 奏でる - 渡邊崇",
	"Summer Pockets - 水月陵"
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
	"ref/ryuhime.mp3",
	"ref/SummerPocket.mp3"
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
	92.0,
	260.0
}

const Float:fDelay = 7.0;
const preItem = 6;

new infaceMenu[400];
new szEntry[128];

new gKeySelectMenu, gKeyInfaceMenu, gKeyplaybackMenu
new gMenuPagesMax;

new pages[33], playingTrack[33], features[33];
new playBack[33], bool:playStatus[33];

public plugin_init()
{
	register_plugin("RefRegisterSystem", "1.0", "Reff");
	register_clcmd("refbgm2", "showMusicSelectMenu");
	register_clcmd("refbgm", "showInterfaceMenu")

	MenuConstructor();
	// 主介面選單
	register_menucmd(register_menuid("InterfaceMenu"), gKeyInfaceMenu, "handleInterfaceMenu");
	// 音樂列表
	register_menucmd(register_menuid("MusicSelectMenu"), gKeySelectMenu, "handleMusicSelectMenu");
	// 播放順序
	register_menucmd(register_menuid("PlayBackMenu"), gKeyInfaceMenu, "handlePlayBackMenu");
}

public plugin_precache()
{
	for (new i=0; i < sizeof(MusicFiles); i++) 
		engfunc(EngFunc_PrecacheSound, MusicFiles[i]);
}

public plugin_natives()
{ 
	register_native("get_music_menu", "showInterfaceMenu", 1);
}

MenuConstructor()
{
	gMenuPagesMax = floatround((float(MAX_TRACK) / float(preItem) ), floatround_ceil) - 1;

	new size = sizeof(infaceMenu);
	add(infaceMenu, size, "\w湊あくあ 総長: \y播放音樂的\r 音樂盒 \w|||^n^n");
	add(infaceMenu, size, "\y1. \w音樂列表 ^n");
	add(infaceMenu, size, "\y2. \w播放順序 ^n");
	add(infaceMenu, size, "\y3. \w播放柱列 ^n^n");

	gKeyInfaceMenu =   (B0 | B1 | B2 | B3 | B8);
	gKeySelectMenu =   (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 );
	gKeyplaybackMenu = (B0 | B1 | B2 | B3);
}

/*=========================================== SHOW MENU ============================================*/
public showInterfaceMenu(id)
{
	new menu[400], text[128], pasue[64];
	new size = sizeof(menu);

	viewPlayStatus(id, text);
	add(menu, size, text);
	add(menu, size, infaceMenu);

	viewStopAndPlay(id, pasue);
	add(menu, size, pasue);

	show_menu(id, gKeyInfaceMenu, menu, -1, "InterfaceMenu");
}

public showPlaybackMenu(id)
{
	new menu[200], color[3];
	new size = sizeof(menu);

	add(menu, size, "\w湊あくあ 総長: \y在這裡設定你的\r 播放順序 ^n^n");
	for(new i = 0; i < MAX_PLAYBACK; ++i)
	{
		color = ( i == playBackMode(id) ? "\r" : "\w" );
		formatex(szEntry, sizeof(szEntry), "\y%d. %s%s^n", (i+1), color, PlaybackMode[i]);
		add(menu, size, szEntry);
	}
	show_menu(id, gKeyplaybackMenu, menu, -1, "PlayBackMenu");
}

public showMusicSelectMenu(id)
{
	new szMenu[512];
	new menuSize = sizeof(szMenu);
	new entrySize = sizeof(szEntry);

	formatex(szEntry, entrySize, "湊あくあ 総長: \r音樂列表  \y%d/%d^n^n", pages[id]+1, gMenuPagesMax+1);
	add(szMenu, menuSize, szEntry);

	formatex(szEntry, entrySize, "\y7\w. 功能切換 & 重新整理^n" );
	add(szMenu, menuSize, szEntry);

	new info[128];

	viewSwitchPlayback(id, info);
	add(szMenu, menuSize, info);

	viewPlayStatus(id, info);
	add(szMenu, menuSize, info);

	viewTrackList(id, szMenu);

	show_menu(id, gKeySelectMenu, szMenu, -1, "MusicSelectMenu");
}

/*============================================-= VIEW =======-=======================================*/
viewTrackList(id, szMenu[512])
{
	new menuSize = sizeof(szMenu);
	new entrySize = sizeof(szEntry);
	new szColor[3];

	new start = pages[id] * preItem;
	new end = (pages[id] + 1) * preItem - 1;
	new seqno; 

	for(new i = start; i <= end; ++i) {
		seqno = (i - start) + 1;
		szColor = ( playingTrack[id] == i ? "\r" : "\w" );

		if( i < MAX_TRACK )
			formatex(szEntry, entrySize, "\y%d\w. %s%s^n", seqno, szColor, MusicTrackName[i]);
		else
			formatex(szEntry, entrySize, "--^n");
		add(szMenu, menuSize, szEntry);
	}
	add(szMenu, menuSize, " ^n");

	if( pages[id] < gMenuPagesMax )
		add(szMenu, sizeof(szMenu), "^n\r0\y. \w下一頁");
	else if( pages[id] >= gMenuPagesMax )
		add(szMenu, sizeof(szMenu), "^n\r0\y. \w回第一頁");
}

viewPlayStatus(id, szText[128])
{
	szText = "";
	new entrySize = sizeof(szEntry);
	new textSize = sizeof(szText);

	if( playingTrack[id] >= 0 && playStatus[id] )
		formatex(szEntry, entrySize, "\y[\w 播放中 \r: \w%s \y]^n^n", MusicTrackName[ playingTrack[id] ]);
	else
		formatex(szEntry, entrySize, "\y[\w 播放中 \r: \w無正在播放歌曲 \y]^n^n");
	add(szText, textSize, szEntry);
}

viewStopAndPlay(id, szText[64])
{
	szText = "";
	formatex(szText, sizeof(szText), "\y8\w. 播放\y/\w停止: %s^n^n", (isPlaying(id) ? "\r停止" : "\y播放" ));
}

viewPlaySequence(id, szText[64])
{
	szText = "";
	formatex(szText, sizeof(szText), "\y8\w. 播放順序: %s^n^n", PlaybackMode[ playBack[id] ]);
}

viewSwitchPlayback(id, szText[128])
{
	szText = "";

	new temp[64];
	switch( features[id] ) {
		case FUNC_SWITCH: viewStopAndPlay(id, temp);
		case FUNC_PLAYBACK: viewPlaySequence(id, temp);
	}
	szText = temp;
}

/*=========================================== MENU HANDLE ============================================*/
public handleMusicSelectMenu(id, num)
{
	new sentinel = pages[id];
	switch(num)
	{
		case N7: features[id] = (++features[id] % MAX_FUNC); // 功能切換
		case N8: doFeatures(id);  // 執行功能
		case N0: toNextPage(id, sentinel);
		default: chooseTrack(id, num);
	}

	showMusicSelectMenu(id);
	return PLUGIN_HANDLED;
}

public handleInterfaceMenu(id, num)
{
	switch(num)
	{
		case N1: showMusicSelectMenu(id);
		case N2: showPlaybackMenu(id);
		case N8: { stopAndPlay(id);showInterfaceMenu(id);}
	}
}

public handlePlayBackMenu(id, num)
{
	switch(num) {
		case N0: showInterfaceMenu(id);
		default: { playBack[id] = num; showPlaybackMenu(id); }
	}
}
/*============================================ CONTROL ===============================================*/
chooseTrack(id, num)
{
	num += ( preItem * pages[id] );
	if ( num < MAX_TRACK )
	{
		directPlay(id, num);
		client_printcolor(id, "\y[\g你播放了\ctr %s\y]", MusicTrackName[num] );
	}
}

toNextPage(id, sentinel)
{
	if( ++sentinel <= gMenuPagesMax )
		pages[id] = sentinel;
	else
		pages[id] = 0;
}

doFeatures(id)
{
	new selectFeatures = features[id];
	switch( selectFeatures )
	{
		case FUNC_SWITCH: stopAndPlay(id);
		case FUNC_PLAYBACK: playBack[id] = (++playBack[id] % MAX_PLAYBACK);
	}
}

public automaticPlaySelectMusic(id)
{
	if( task_exists(id) ) remove_task(id);

	id = id - 7866;
	if( !is_user_connected(id) ) return;

	switch( playBack[id] )
	{
		// case PLAY_REPEAT: return;
		case PLAY_RANDOM: setPlayingTrackRandom(id);
		// case PLAY_ONCE: setNextTrack(id, -1);
	}

	if( playingTrack[id] >= 0) playSpecificTrack(id);
}

setPlayingTrackRandom(id)
{
	new track = playingTrack[id];
	while( track == playingTrack[id] )
		playingTrack[id] = random_num(0, MAX_TRACK-1);
}

playSpecificTrack(id)
{
	new track = playingTrack[id];
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

directPlay(id, num)
{
	stopMusic(id);
	playingTrack[id] = num;
	playSpecificTrack(id);
}

stopAndPlay(id)
{
	isPlaying(id) ? stopMusic(id) : automaticPlaySelectMusic(id+7866);
}

/*========================================== FORWARD & CHECK FUNC ===========================================*/
public client_putinserver(id)
{
	resetInfo(id);
	set_task(fDelay-3.0, "automaticPlaySelectMusic", id+7866);
}

resetInfo(id)
{
	stopMusic(id);
	playBack[id] = 0;
	pages[id] = 0;
}

public client_disconnect(id)
{
	stopMusic(id);
}

public isPlaying(id)
{
	return playStatus[id];
}

public playBackMode(id)
{
	return playBack[id];
}

/*============================================ STOCK ==================================================*/
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


		// case 9: {  // 上一頁
		// 	if( --p >= 0 ) pages[id] = p;
		// }