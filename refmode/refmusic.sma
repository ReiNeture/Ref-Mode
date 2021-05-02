#include <amxmodx>
#include <amxmisc>

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

const MAX_TRACK = 11;
new const MusicTrackName[MAX_TRACK][] = 
{
    "此花亭 - 菊地創",
    "眩しさの中 - 水月陵",
    "蘭の香り - 水月陵",
    "ReminiscE - 金閉開羅巧夢",
    "Time left - 天門&柳英一郎",
    "サクラ - 未知",
    "耐える冬 - 未知",
	"夢の歩みを見上げて - 松本文紀",
    "竜姫 奏でる - 渡邊崇",
	"Summer Pockets - 水月陵",
	"さくらみこBGM - 未知"
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
	"ref/SummerPocket.mp3",
	"ref/sakuramiko.mp3"
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
	260.0,
	190.0
}

const Float:fDelay = 5.0;
const preItem = 6;
const NA = (preItem - 1);

new infaceMenu[400];
new szEntry[128];
new entrySize = charsmax(szEntry);

new gKeySelectMenu, gKeyInfaceMenu, gKeyplaybackMenu, gKeyQueueMenu, gKeyQueueManagerMenu;
new gMenuPagesMax;

new pages[33], queuePages[33], playingTrack[33], features[33];
new playBack[33], bool:playStatus[33];

const MAX_QUEUE = 20;
new Array:playQueue[33];

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
	// 新增佇列
	register_menucmd(register_menuid("QueueMenu"), gKeyQueueMenu, "handleQueueMenu");
	// 佇列管理
	register_menucmd(register_menuid("QueueManagerMenu"), gKeyQueueManagerMenu, "handleQueueManagerMenu");
}

public plugin_precache()
{
	new i;
	for(i = 0; i <= 32; ++i)
		playQueue[i] = ArrayCreate();
	for (i = 0; i < sizeof(MusicFiles); i++)
		precache_sound(MusicFiles[i]);
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
	add(infaceMenu, size, "\y2. \w播放模式 ^n^n");
	add(infaceMenu, size, "\y3. \w佇列新增 ^n");
	add(infaceMenu, size, "\y4. \w播放佇列 ^n^n");

	gKeyInfaceMenu =   (B0 | B1 | B2 | B3 | B4 | B8 );
	gKeySelectMenu =   (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 );
	gKeyplaybackMenu = (B0 | B1 | B2 | B3 );
	gKeyQueueMenu =    (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 );

	// 播放佇列全檢視會更動到此變數
	gKeyQueueManagerMenu = (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 );
}

/*=========================================== SHOW MENU ============================================*/
public showInterfaceMenu(id)
{
	new menu[400], text[128], pasue[64];
	new size = charsmax(menu);

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
	new size = charsmax(menu);

	add(menu, size, "\w湊あくあ 総長: ^n\y在這裡設定你的\r 播放順序 ^n^n");
	for(new i = 0; i < MAX_PLAYBACK; ++i)
	{
		color = ( i == playBackMode(id) ? "\r" : "\w" );
		formatex(szEntry, charsmax(szEntry), "\y%d. %s%s^n", (i+1), color, PlaybackMode[i]);
		add(menu, size, szEntry);
	}
	show_menu(id, gKeyplaybackMenu, menu, -1, "PlayBackMenu");
}

public showMusicSelectMenu(id)
{
	new szMenu[512];
	new menuSize = charsmax(szMenu);

	formatex(szEntry, entrySize, "湊あくあ 総長: \r音樂列表  \y%d/%d^n^n", pages[id]+1, gMenuPagesMax+1);
	add(szMenu, menuSize, szEntry);

	formatex(szEntry, entrySize, "\y7\w. 功能切換 & 重新整理^n" );
	add(szMenu, menuSize, szEntry);

	new info[128], info2[256];
	viewSwitchPlayback(id, info);
	add(szMenu, menuSize, info);

	viewPlayStatus(id, info);
	add(szMenu, menuSize, info);

	viewTrackList(id, info2);
	add(szMenu, menuSize, info2);

	show_menu(id, gKeySelectMenu, szMenu, -1, "MusicSelectMenu");
}

public showQueueMenu(id)
{
	new szMenu[1024];
	new menuSize = charsmax(szMenu);

	formatex(szEntry, entrySize, "湊あくあ 総長: \r播放佇列^n^n");
	add(szMenu, menuSize, szEntry);
	formatex(szEntry, entrySize, "\y若佇列有歌曲時優先以佇列順序播放^n停止 或 指定歌曲時將清空佇列^n^n");
	add(szMenu, menuSize, szEntry);

	new info[256];
	viewTrackList(id, info);
	add(szMenu, menuSize, info);

	show_menu(id, gKeySelectMenu, szMenu, -1, "QueueMenu");
}

public showQueueManagerMenu(id)
{
	new szMenu[512];
	new menuSize = charsmax(szMenu);

	formatex(szEntry, entrySize, "\r播放佇列管理: \y點擊移除指定佇列歌曲^n^n");
	add(szMenu, menuSize, szEntry);

	new info[256], info2[128];
	viewPlayStatus(id, info2);
	add(szMenu, menuSize, info2);

	viewQueueList(id, info);
	add(szMenu, menuSize, info);

	show_menu(id, gKeyQueueManagerMenu, szMenu, -1, "QueueManagerMenu");
}

/*============================================= VIEW ==============================================*/

viewTrackList(id, szText[256])  // 全歌曲列表
{
	szText = "";

	new textSize = charsmax(szText);
	
	new szColor[3];

	new start = pages[id] * preItem;
	new end = (pages[id] + 1) * preItem - 1;
	new seqno; 

	add(szText, textSize, "\w> \y歌曲列表 : ^n");
	for(new i = start; i <= end; ++i) {
		seqno = (i - start) + 1;
		szColor = ( playingTrack[id] == i ? "\r" : "\w" );

		if( i < MAX_TRACK )
			formatex(szEntry, entrySize, "\y%d\w. %s%s^n", seqno, szColor, MusicTrackName[i]);
		else
			formatex(szEntry, entrySize, "\w--^n");
		add(szText, textSize, szEntry);
	}

	add(szText, textSize, "^n");
	if( pages[id] < gMenuPagesMax )
		add(szText, textSize, "\r0\y. \w下一頁");
	else if( pages[id] >= gMenuPagesMax )
		add(szText, textSize, "\r0\y. \w回第一頁");
}

viewPlayStatus(id, szText[128])  // 正在播放歌曲
{
	szText = "";
	
	new textSize = charsmax(szText);

	if( playingTrack[id] >= 0 && playStatus[id] )
		formatex(szEntry, entrySize, "\y[\w 播放中 \r: \w%s \y]^n^n", MusicTrackName[ playingTrack[id] ]);
	else
		formatex(szEntry, entrySize, "\y[\w 播放中 \r: \w無正在播放歌曲 \y]^n^n");
	add(szText, textSize, szEntry);
}

viewStopAndPlay(id, szText[64])  // 播放/停止
{
	szText = "";
	formatex(szText, sizeof(szText), "\y8\w. 播放\y/\w停止: %s^n^n", (isPlaying(id) ? "\r停止" : "\y播放" ));
}

viewPlaySequence(id, szText[64])
{
	szText = "";
	formatex(szText, sizeof(szText), "\y8\w. 目前模式: %s^n^n", PlaybackMode[ playBack[id] ]);
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

viewQueueTop3(id, szText[256])  // 播放佇列前三首
{
	szText = "";
	
	new textSize = charsmax(szText);

	new item, length = ArraySize(playQueue[id]);
	if( playQueue[id] )
		item = (length > 3 ) ? 3 : ArraySize(playQueue[id]);

	add(szText, textSize, "\w> \y播放佇列(前三首) : ^n");
	for(new i = 0; i < item; ++i) {
		static track; 
		track = ArrayGetCell(playQueue[id], i);

		formatex(szEntry, entrySize, "\y%d\w. %s^n", i+1, MusicTrackName[track]);
		add(szText, textSize, szEntry);
	}

	if( length > 3) add(szText, textSize, "...^n");
	add(szText, textSize, "^n");
}

viewQueueList(id, szText[256])  // 播放佇列全檢視
{
	szText = "";
	gKeyQueueManagerMenu = B0;
	new textSize = charsmax(szText);
	
	// 5 item in one page
	new queueSize = ArraySize(playQueue[id]);
	new maxQueuePage = floatround(float(queueSize) / 5.0, floatround_ceil);

	new start = queuePages[id] * 5;
	new end = ( queueSize > 5 ? ((queuePages[id] + 1) * 5 - 1) : queueSize - 1 );

	if( queueSize > 0 )
		formatex(szEntry, entrySize, "\w> \y播放佇列\r(%d) \y: \w%d/%d ^n^n", queueSize, queuePages[id] + 1, maxQueuePage);
	else
		formatex(szEntry, entrySize, "\w> \y播放佇列\r(%d) ^n^n", queueSize);
	add(szText, textSize, szEntry);

	for(new i = start; i <= end; ++i) {

		if( i >= ArraySize(playQueue[id]) ) break;

		formatex(szEntry, entrySize, "\y%d\w. %s^n", (i - start) + 1, MusicTrackName[ArrayGetCell(playQueue[id], i)]);
		add(szText, textSize, szEntry);
		gKeyQueueManagerMenu |= (1 << (i - start) );
	}

	add(szText, textSize, "^n");
	if( maxQueuePage > 1 ) {

		gKeyQueueManagerMenu |= (B0);

		if( queuePages[id] < maxQueuePage - 1 )
			add(szText, textSize, "\r0\y. \w下一頁");
		else if( queuePages[id] >= maxQueuePage - 1 )
			add(szText, textSize, "\r0\y. \w回第一頁");
	}
}

/*=========================================== MENU HANDLE ============================================*/
public handleMusicSelectMenu(id, num)
{
	switch(num)
	{
		case N7: features[id] = (++features[id] % MAX_FUNC); // 功能切換
		case N8: doFeatures(id);  // 執行功能
		case N0: toNextPage(id);
		case N1..NA: chooseTrack(id, num);
		default: return PLUGIN_HANDLED;
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
		case N3: showQueueMenu(id);
		case N4: showQueueManagerMenu(id);
		case N8: { 
			stopAndPlay(id);
			showInterfaceMenu(id);
		}
	}
}

public handlePlayBackMenu(id, num)
{
	switch(num) {
		case N0: showInterfaceMenu(id);
		default: { 
			playBack[id] = num;
			showPlaybackMenu(id);
		}
	}
}

public handleQueueMenu(id, num)
{
	switch(num)
	{
		case N0: toNextPage(id);
		case N1..NA: addTrackToQueue(id, num);
		default: return PLUGIN_HANDLED;
	}
	showQueueMenu(id);

	return PLUGIN_HANDLED;
}

public handleQueueManagerMenu(id, num)
{
	switch(num)
	{
		case N0: toQueueNextPage(id);
		default: removeFromQueue(id, num);
	}
	showQueueManagerMenu(id);

	return PLUGIN_HANDLED;
}


/*============================================ CONTROL ===============================================*/
addTrackToQueue(id, num)
{
	if( !playQueue[id] ) playQueue[id] = ArrayCreate();

	new length = ArraySize(playQueue[id]);

	if( length >= MAX_QUEUE ) {
		client_printcolor(id, "\y[\g播放佇列已達上限\ctr%d\y]", MAX_QUEUE);
		return;
	}

	num += ( preItem * pages[id] );
	if ( num < MAX_TRACK )
	{
		ArrayPushCell(playQueue[id], num);
		client_printcolor(id, "\y[\g已將\ctr%s\g加入播放佇列中\y]", MusicTrackName[num] );
	}
}

chooseTrack(id, num)
{
	num += ( preItem * pages[id] );
	if ( num < MAX_TRACK )
	{
		stopMusic(id);
		playingTrack[id] = num;
		playSpecificTrack(id);
		client_printcolor(id, "\y[\g你播放了\ctr %s\y]", MusicTrackName[num]);
	}
}

toNextPage(id)
{
	new sentinel = pages[id];

	if( ++sentinel <= gMenuPagesMax )
		pages[id] = sentinel;
	else
		pages[id] = 0;
}

toQueueNextPage(id)
{
	new const maxQueuePage = floatround(float(ArraySize(playQueue[id])) / 5.0, floatround_ceil);
	new sentinel = queuePages[id];

	if( ++sentinel <= maxQueuePage - 1 )
		queuePages[id] = sentinel;
	else
		queuePages[id] = 0;
}

toQueuePreviousPage(id)
{
	if( queuePages[id] > 0 ) --queuePages[id];
}

removeFromQueue(id, num)
{
	num += ( 5 * queuePages[id] );
	ArrayDeleteItem(playQueue[id], num);
	client_printcolor(id, "\y[\g已將\ctr%d:%s\g從播放佇列移除\y]", num+1, MusicTrackName[num] );

	new const maxQueuePage = floatround(float(ArraySize(playQueue[id])) / 5.0, floatround_ceil);
	while( queuePages[id] >= maxQueuePage && queuePages[id] > 0 )
		toQueuePreviousPage(id);
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

	if( playQueue[id] && ArraySize(playQueue[id]) > 0 ) {

		playingTrack[id] = ArrayGetCell(playQueue[id], 0);
		ArrayDeleteItem(playQueue[id], 0);
		playSpecificTrack(id);
		return;
	}

	switch( playBack[id] )
	{
		case PLAY_REPEAT: {}
		case PLAY_RANDOM: setPlayingTrackRandom(id);
		case PLAY_ONCE  : {}
	}

	if( playingTrack[id] >= 0 ) playSpecificTrack(id);
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
	set_task(MUSIC_TASK[track] + fDelay, "automaticPlaySelectMusic", id+7866);
}

public stopMusic(id)
{
	if( task_exists(id+7866) )
		remove_task(id+7866);

	playingTrack[id] = -1;
	playStatus[id] = false;
	ArrayClear(playQueue[id]);
	client_cmd(id, "mp3 stop");
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

public client_disconnected(id)
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