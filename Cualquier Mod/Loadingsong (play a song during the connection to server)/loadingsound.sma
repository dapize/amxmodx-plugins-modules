/*
* Play a sound during the connection.
*
* Random code part taken from plugin
* connectsound by White Panther
*
* v1.0
*
*/

#include <amxmodx>
#define Maxsounds 6

// sounds localized in gcf cache (valve/media)
// you can add more song if you want.
new soundlist[Maxsounds][] = {"Half-Life01","Half-Life02","Half-Life04","Half-Life12","Half-Life13","Half-Life17"}

public client_connect(id) {
	new i
	i = random_num(0,Maxsounds-1)
	client_cmd(id,"mp3 play media/%s",soundlist[i])
	return PLUGIN_CONTINUE
}

public plugin_init() {
	register_plugin("Loading Sound","1.0","Amxx User")
	return PLUGIN_CONTINUE
}