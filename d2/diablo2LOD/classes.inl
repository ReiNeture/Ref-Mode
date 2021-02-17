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
/////////////////////////////////////
select_hayato(id)
{
    if ( !g_iLogged[id] ) return;
    if( g_PlayerLevel[id][g_CurrentChar[id]] < 70 ) return;
    if( g_PlayerHero[id][g_CurrentChar[id]] != COMBAT ) return;

    g_PlayerHero[id][g_CurrentChar[id]] = HAYATO
    new name[64];
    get_user_name(id, name, sizeof(name))
    client_printcolor(0, "/ctr%s /y成功轉職為 /ctr%s/y!", name, HEROES[HAYATO])
}
select_mako(id)
{
    if ( !g_iLogged[id] ) return;
    if( g_PlayerLevel[id][g_CurrentChar[id]] < 70 ) return;
    if( g_PlayerHero[id][g_CurrentChar[id]] != COMBAT ) return;

    g_PlayerHero[id][g_CurrentChar[id]] = MAKO
    new name[64];
    get_user_name(id, name, sizeof(name))
    client_printcolor(0, "/ctr%s /y成功轉職為 /ctr%s/y!", name, HEROES[MAKO])
}
select_element(id)
{
    if ( !g_iLogged[id] ) return;
    if( g_PlayerLevel[id][g_CurrentChar[id]] < 70 ) return;
    if( g_PlayerHero[id][g_CurrentChar[id]] != SPELLS ) return;

    g_PlayerHero[id][g_CurrentChar[id]] = ELEMENT
    new name[64];
    get_user_name(id, name, sizeof(name))
    client_printcolor(0, "/ctr%s /y成功轉職為 /ctr%s/y!", name, HEROES[ELEMENT])
}
select_magician(id)
{
    if ( !g_iLogged[id] ) return;
    if( g_PlayerLevel[id][g_CurrentChar[id]] < 70 ) return;
    if( g_PlayerHero[id][g_CurrentChar[id]] != SPELLS ) return;

    g_PlayerHero[id][g_CurrentChar[id]] = MAGIC
    new name[64];
    get_user_name(id, name, sizeof(name))
    client_printcolor(0, "/ctr%s /y成功轉職為 /ctr%s/y!", name, HEROES[MAGIC])
}