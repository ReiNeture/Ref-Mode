/* 紀載所有歌曲的資訊 */

const MAX_TRACK = 10;

new const MusicTrackName[MAX_TRACK][] = 
{
    "此花亭",
    "眩しさの中",
    "蘭の香り",
    "ReminiscE",
    "Time left",
    "サクラ",
	"夢の歩みを見上げて",
    "竜姫 奏でる",
	"Summer Pockets",
	"さくらみこBGM"
}

new const MusicArtistName[MAX_TRACK][] = 
{
    "菊地創",
    "水月陵",
    "水月陵",
    "金閉開羅巧夢",
    "天門&柳英一郎",
    "ステージ なな",
	"松本文紀",
    "渡邊崇",
	"水月陵",
	"未知"
}

// 專輯圖片路徑使用檔案名稱
new const MusicFiles[MAX_TRACK][] = 
{
	"konohana.mp3",
	"mabusiisa.mp3",
	"kaori.mp3",
	"ReminiscE.mp3",
	"TimeLeft.mp3",
	"narcissusakura.mp3",
	"yumenoarumi.mp3",
	"ryuhime.mp3",
	"SummerPocket.mp3",
	"sakuramiko.mp3"
}

new const TrackOfAlbum[MAX_TRACK][] = 
{
	"TVアニメ「このはな綺譚」オリジナルサウンドトラック",
	"Summer Pockets Original SoundTrack",
	"はつゆきさくら COMPLETE SOUNDTRACK",
	"Re:LieF 親愛なるあなたへ OriginaL SounD TracK",
	"Eden* ORIGINAL SOUNDTRACK Asterisk",
	"Narcissu Side 2nd SoundTrack",
	"サクラノ詩 -櫻の森の上を舞う- サウンドトラック",
	"マナリアフレンズ オリジナルサウンドトラック(OST)",
	"Summer Pockets Orchestra Album『Echoes of Summer』",
	"來源YouTube"
}

new const Float:MUSIC_TASK[MAX_TRACK] = 
{
	101.0,
	260.0,
	149.0,
	150.0,
	185.0,
	142.0,
	134.0,
	92.0,
	260.0,
	190.0
}

// 歌曲資訊網頁路徑
new const trackInfoHTML[] = "addons\amxmodx\refmusic\track_info.html"; 