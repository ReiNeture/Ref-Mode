#include <amxmodx>
#include <amxmisc>
#include "trackinfo"

#define PLAYING_TASK 7866
#define ID_TASK (id+PLAYING_TASK)

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

const MAX_PLAYBACK = 4;
new const PlaybackMode[MAX_PLAYBACK][] = 
{
	"隨機播放",
	"單一循環",
	"播放一次",
	"預設順序"
}
enum
{
	PLAY_RANDOM = 0,
	PLAY_REPEAT,
	PLAY_ONCE,
	PLAY_DEFAULT
};

// 每首歌曲播放間格
const Float:fDelay = 5.0;

// 音樂列表每頁顯示數量
const PRE_ITEM = 6;  
const NA = (PRE_ITEM - 1);

new infaceMenu[400];
new szEntry[128];
new entrySize = charsmax(szEntry);

new gKeySelectMenu, gKeyInfaceMenu, gKeyplaybackMenu, gKeyQueueMenu, gKeyQueueManagerMenu;
new gMenuPagesMax;

new pages[33], queuePages[33], playingTrack[33], features[33];
new playBack[33], bool:playStatus[33];

const MAX_QUEUE = 20;
new Array:playQueue[33];
new Array:playRecord[33];

public plugin_init()
{
	register_plugin("RefRegisterSystem", "1.0", "Reff");
	register_clcmd("ref_bgm", "showInterfaceMenu");

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
	for(i = 0; i <= 32; ++i) {
		playQueue[i] = ArrayCreate();
		playRecord[i] = ArrayCreate(64);
	}

	new name[32];
	for (i = 0; i < sizeof(MusicFiles); i++) {
		formatex(name, charsmax(name), "ref/%s", MusicFiles[i]);
		precache_sound(name);
	}
}

public plugin_natives()
{ 
	register_native("get_music_menu", "showInterfaceMenu", 1);
}

MenuConstructor()
{
	// 計算音樂列表最大頁數 從零開始
	gMenuPagesMax = floatround((float(MAX_TRACK) / float(PRE_ITEM) ), floatround_ceil) - 1;

	new size = sizeof(infaceMenu);
	add(infaceMenu, size, "\w湊あくあ 総長: \y播放音樂的\r 音樂盒 \w|||^n^n");
	add(infaceMenu, size, "\y1. \w音樂列表 ^n");
	add(infaceMenu, size, "\y2. \w播放模式 ^n^n");
	add(infaceMenu, size, "\y3. \w佇列新增 ^n");
	add(infaceMenu, size, "\y4. \w播放佇列 ^n^n");
	add(infaceMenu, size, "\y5. \w播放紀錄 ^n");
	add(infaceMenu, size, "\y6. \w歌曲資訊 ^n^n");
	add(infaceMenu, size, "\y9. \w下一首 ^n");

	gKeyInfaceMenu =   (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B8 | B9 );
	gKeySelectMenu =   (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 );
	gKeyplaybackMenu = (B0 | B1 | B2 | B3 | B4 );
	gKeyQueueMenu =    (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 );

	// 播放佇列全檢視會更動到此變數
	gKeyQueueManagerMenu = (B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 );
}

/*=========================================== SHOW MENU ============================================*/
public showInterfaceMenu(id)
{
	new szMenu[500];
	new menuSize = charsmax(szMenu);

	addPlayStatus(id, szMenu, menuSize);
	add(szMenu, menuSize, infaceMenu);
	addStopAndPlay(id, szMenu, menuSize, 0);

	show_menu(id, gKeyInfaceMenu, szMenu, -1, "InterfaceMenu");
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

	formatex(szEntry, entrySize, "湊あくあ 総長: \r音樂列表 ^n^n");
	add(szMenu, menuSize, szEntry);
	formatex(szEntry, entrySize, "\y7\w. 功能切換 & 重新整理^n" );
	add(szMenu, menuSize, szEntry);

	addSwitchPlayback(id, szMenu, menuSize);
	addPlayStatus(id, szMenu, menuSize);
	addTrackList(id, szMenu, menuSize);

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

	addTrackList(id, szMenu, menuSize);

	show_menu(id, gKeySelectMenu, szMenu, -1, "QueueMenu");
}

public showQueueManagerMenu(id)
{
	new szMenu[512];
	new menuSize = charsmax(szMenu);

	formatex(szEntry, entrySize, "\r播放佇列管理: \y點擊移除指定佇列歌曲^n^n");
	add(szMenu, menuSize, szEntry);
	
	toQueueCorrectPage(id);
	addPlayStatus(id, szMenu, menuSize);
	addQueueList(id, szMenu, menuSize);
	
	show_menu(id, gKeyQueueManagerMenu, szMenu, -1, "QueueManagerMenu");
}

public showRecordMenu(id)
{
	new szMenu[512];
	new menuSize = charsmax(szMenu);

	formatex(szEntry, entrySize, "\r播放紀錄: \y最後五首紀錄^n^n");
	add(szMenu, menuSize, szEntry);

	addRecordList(id, szMenu, menuSize);

	formatex(szEntry, entrySize, "\y—^n");
	add(szMenu, menuSize, szEntry);

	show_menu(id, gKeyQueueManagerMenu, szMenu);
}

/*============================================= VIEW ==============================================*/

addTrackList(id, szText[], textSize)  // 全歌曲列表
{
	new szColor[3];
	new start = pages[id] * PRE_ITEM;
	new end = (pages[id] + 1) * PRE_ITEM - 1;
	new seqno; 

	formatex(szEntry, entrySize, "\w> \y歌曲列表 (%d/%d) : ^n", pages[id]+1, gMenuPagesMax+1);
	add(szText, textSize, szEntry);

	for(new i = start; i <= end; ++i) {
		seqno = (i - start) + 1;
		szColor = ( playingTrack[id] == i ? "\r" : "\w" );

		if( i < MAX_TRACK )
			formatex(szEntry, entrySize, "\y%d\w. %s%s - %s^n", seqno, szColor, MusicTrackName[i], MusicArtistName[i]);
		else
			formatex(szEntry, entrySize, "\w--^n");
		add(szText, textSize, szEntry);
	}

	add(szText, textSize, "^n");
	if( pages[id] < gMenuPagesMax )
		add(szText, textSize, "\y9\w. 下一頁");
	else if( pages[id] >= gMenuPagesMax )
		add(szText, textSize, "\y9\w. \r回第一頁");
}

addPlayStatus(id, szText[], textSize)  // 正在播放歌曲
{
	if( playingTrack[id] >= 0 && playStatus[id] )
		formatex(szEntry, entrySize, "\y[\w 播放中 \r: \w%s \y]^n^n", MusicTrackName[ playingTrack[id] ]);
	else
		formatex(szEntry, entrySize, "\y[\w 播放中 \r: \w無 \y]^n^n");
	add(szText, textSize, szEntry);
}

addStopAndPlay(id, szText[], textSize, option)  // 播放/停止
{
	formatex(szEntry, entrySize, "\y%d\w. 播放\y/\w停止: %s^n^n", option, (isPlaying(id) ? "\r停止" : "\y播放" ));
	add(szText, textSize, szEntry);
}

addPlaySequence(id, szText[], textSize)
{
	formatex(szEntry, entrySize, "\y8\w. 目前模式: %s^n^n", PlaybackMode[ playBack[id] ]);
	add(szText, textSize, szEntry);
}

addSwitchPlayback(id, szText[], textSize)
{
	switch( features[id] ) {
		case FUNC_SWITCH: addStopAndPlay(id, szText, textSize, 8);
		case FUNC_PLAYBACK: addPlaySequence(id, szText, textSize);
	}
}

addQueueList(id, szText[], textSize)  // 播放佇列全檢視
{
	gKeyQueueManagerMenu = B0;
	
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

		formatex(szEntry, entrySize, "\y%d\w. %s - %s^n", (i - start) + 1, 
		MusicTrackName[ArrayGetCell(playQueue[id], i)], 
		MusicArtistName[ArrayGetCell(playQueue[id], i)]);

		add(szText, textSize, szEntry);

		// 設定可按按鍵範圍
		gKeyQueueManagerMenu |= (1 << (i - start) );
	}

	add(szText, textSize, "^n");
	if( maxQueuePage > 1 ) {

		if( queuePages[id] < maxQueuePage - 1 )
			add(szText, textSize, "\y9\w. 下一頁");
		else if( queuePages[id] >= maxQueuePage - 1 )
			add(szText, textSize, "\y9\w. \r回第一頁");
	}
}

addRecordList(id, szText[], textSize)  // 播放記錄最後五首
{
	new size = ArraySize(playRecord[id]);

	static info[64];
	for(new i = size - 1; i >= 0 ; --i) {
		ArrayGetString(playRecord[id], i, info, charsmax(info));
		add(szText, textSize, info);
	}
}

/*=========================================== MENU HANDLE ============================================*/

public handleInterfaceMenu(id, num)
{
	switch(num)
	{
		case N1: showMusicSelectMenu(id);
		case N2: showPlaybackMenu(id);
		case N3: showQueueMenu(id);
		case N4: showQueueManagerMenu(id);
		case N5: showRecordMenu(id);
		case N6: {
			motdTrackInfo(id);
			showInterfaceMenu(id);
		}
		case N9: {
			automaticPlaySelectMusic(ID_TASK);
			showInterfaceMenu(id);
		}
		case N0: { 
			stopAndPlay(id);
			showInterfaceMenu(id);
		}
	}
}

public handleMusicSelectMenu(id, num)
{
	switch(num)
	{
		case N1..NA: chooseTrack(id, num);
		case N7: features[id] = (++features[id] % MAX_FUNC); // 功能切換
		case N8: doFeatures(id);  // 執行功能
		case N9: toNextPage(id);
		case N0: {
			showInterfaceMenu(id);
			return PLUGIN_HANDLED;
		}
	}

	showMusicSelectMenu(id);
	return PLUGIN_HANDLED;
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
		case N1..NA: trackToQueue(id, num);
		case N9: toNextPage(id);
		case N0: {
			showInterfaceMenu(id);
			return PLUGIN_HANDLED;
		}
	}

	showQueueMenu(id);
	return PLUGIN_HANDLED;
}

public handleQueueManagerMenu(id, num)
{
	switch(num)
	{
		case N9: toQueueNextPage(id);
		case N0: {
			showInterfaceMenu(id);
			return PLUGIN_HANDLED;
		}
		default: removeFromQueue(id, num);
	}

	showQueueManagerMenu(id);
	return PLUGIN_HANDLED;
}


/*============================================ CONTROL ===============================================*/
trackToQueue(id, num)
{
	if( !playQueue[id] ) playQueue[id] = ArrayCreate();

	new length = ArraySize(playQueue[id]);

	if( length >= MAX_QUEUE ) {
		client_printcolor(id, "\y[\g播放佇列已達上限\ctr%d\y]", MAX_QUEUE);
		return;
	}

	num += ( PRE_ITEM * pages[id] );
	if ( num < MAX_TRACK )
	{
		ArrayPushCell(playQueue[id], num);
		client_printcolor(id, "\y[\g已將\ctr%s\g加入播放佇列中\y]", MusicTrackName[num] );
	}
}

chooseTrack(id, num)
{
	num += ( PRE_ITEM * pages[id] );
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

toQueueCorrectPage(id)
{
	new const maxQueuePage = floatround(float(ArraySize(playQueue[id])) / 5.0, floatround_ceil);
	while( queuePages[id] >= maxQueuePage && queuePages[id] > 0 )
		if( queuePages[id] > 0 ) --queuePages[id];
}

removeFromQueue(id, num)
{
	num += ( 5 * queuePages[id] );
	new tempTrack = ArrayGetCell(playQueue[id], num);

	ArrayDeleteItem(playQueue[id], num);
	client_printcolor(id, "\y[\g已將\ctr%d:%s\g從播放佇列移除\y]", num+1, MusicTrackName[tempTrack] );
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

	id = id - PLAYING_TASK;
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
		case PLAY_DEFAULT: setPlayingTrackDefault(id);
	}

	if( playingTrack[id] >= 0 ) playSpecificTrack(id);
}

setPlayingTrackRandom(id)
{
	new track = playingTrack[id];
	while( track == playingTrack[id] )
		playingTrack[id] = random_num(0, MAX_TRACK-1);
}

setPlayingTrackDefault(id)
{
	playingTrack[id] = (++playingTrack[id] % MAX_TRACK);
}

playSpecificTrack(id)
{
	new track = playingTrack[id];
	playStatus[id] = true;

	client_cmd(id, "mp3 play ^"sound/ref/%s^"", MusicFiles[track]);
	pushToRecord(id, track);

	set_task(MUSIC_TASK[track] + fDelay, "automaticPlaySelectMusic", ID_TASK);
}

pushToRecord(id, track)
{
	#define FIRST_ITEM 0
	new Array:arrayHandle = playRecord[id];
	static playingInfo[64], times[10];

	get_time("%H:%M:%S", times, charsmax(times));
	formatex(playingInfo, charsmax(playingInfo), "\y¦-%s\r: \w%s - %s^n", times, MusicTrackName[track], MusicArtistName[track] );

	if( ArraySize(arrayHandle) >= 5 )
		ArrayDeleteItem(arrayHandle, FIRST_ITEM);

	ArrayPushString(arrayHandle, playingInfo);
}

public stopMusic(id)
{
	if( task_exists(ID_TASK) )
		remove_task(ID_TASK);

	playingTrack[id] = -1;
	playStatus[id] = false;

	queuePages[id] = 0;
	ArrayClear(playQueue[id]);
	
	client_cmd(id, "mp3 stop");
}

resetInfo(id)
{
	stopMusic(id);
	playBack[id] = PLAY_DEFAULT;
	pages[id] = 0;
}

stopAndPlay(id)
{
	isPlaying(id) ? stopMusic(id) : automaticPlaySelectMusic(ID_TASK);
}

motdTrackInfo(id)
{
	static html[2048];
	new track = playingTrack[id];

	if( track > -1 ) {
		makeTrackInfoHTML(track, html, charsmax(html) );
		show_motd(id, html, "正在播放的歌曲資訊");

	} else
		client_printcolor(id, "\y[\g無正在播放歌曲\y]");
}

makeTrackInfoHTML(track, html[], textSize)
{
	copy(html, textSize, "");
	new files = fopen(trackInfoHTML, "r");

	while ( !feof(files) ) {

		static buffer[512];
		fgets(files, buffer, charsmax(buffer) );

		if( strfind(buffer, "ALBUM_PATH") != -1 )
			replace_string(buffer, charsmax(buffer), "ALBUM_PATH", MusicFiles[track]);
		if( strfind(buffer, "TRACK_NAME") != -1 )
			replace_string(buffer, charsmax(buffer), "TRACK_NAME", MusicTrackName[track]);
		if( strfind(buffer, "ARTIST_NAME") != -1 )
			replace_string(buffer, charsmax(buffer), "ARTIST_NAME", MusicArtistName[track]);
		if( strfind(buffer, "ALBUM_NAME") != -1 )
			replace_string(buffer, charsmax(buffer), "ALBUM_NAME", TrackOfAlbum[track]);

		add(html, textSize, buffer);
	}
	fclose(files);
}

/*========================================== FORWARD & CHECK FUNC ===========================================*/

public client_putinserver(id)
{
	resetInfo(id);
	set_task(fDelay-3.0, "automaticPlaySelectMusic", ID_TASK);
}

public client_disconnected(id)
{
	resetInfo(id);
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

	replace_all(msg,190,"\g","^4");   // 綠色文字.
	replace_all(msg,190,"\y","^1");   // 橘色文字.
	replace_all(msg,190,"\ctr","^3"); // 隊伍顏色文字.

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