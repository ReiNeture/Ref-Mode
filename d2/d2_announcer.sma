#include <amxmodx>
#include <d2lod>

new PLUGIN_NAME[] = "Diablo II LOD 登入資訊"
new PLUGIN_AUTHOR[] = "xbatista"
new PLUGIN_VERSION[] = "1.0"

new const HEROES[][] = 
{
	"問號",
	"初心者",
	"吹雪",
	"百花",
	"元素師",
	"魔導士",
	"漂流者",
	"隼人"
}

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
}
public d2_logged(id, log_type)
{
	static name[32] ; get_user_name(id, name, charsmax(name));

	if ( log_type == LOGGED )
	{
		client_printcolor( 0, "/y[ /g%s /y] - /ctr%s /y已登入.", name, HEROES[ get_p_hero(id) ]);
	}
	else
	{
		client_printcolor( 0, "/y[ /g%s /y] - /ctr%s /y已登出.", name, HEROES[ get_p_hero(id) ]);
	}
}