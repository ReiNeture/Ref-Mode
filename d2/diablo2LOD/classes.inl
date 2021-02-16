// 玩家類型的功能/效果.

// 選擇職業路線
select_spells(id)
{
    if ( !g_iLogged[id] ) return;

    if( g_PlayerLevel[id][g_CurrentChar[id]] < 30 ) return;

    if( g_PlayerHero[id][g_CurrentChar[id]] != NEWBIE ) return;

    g_PlayerHero[id][g_CurrentChar[id]] = SPELLS

    new name[64];
    get_user_name(id, name, sizeof(name))
    client_printcolor(0, "/ctr%s /y成功轉職為 /ctr%s/y!", name, HEROES[SPELLS])
}
select_combat(id)
{
    if ( !g_iLogged[id] ) return;

    if( g_PlayerLevel[id][g_CurrentChar[id]] < 30 ) return;

    if( g_PlayerHero[id][g_CurrentChar[id]] != NEWBIE ) return;

    g_PlayerHero[id][g_CurrentChar[id]] = COMBAT

    new name[64];
    get_user_name(id, name, sizeof(name))
    client_printcolor(0, "/ctr%s /y成功轉職為 /ctr%s/y!", name, HEROES[COMBAT])
}