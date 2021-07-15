/* AMX Mod X
*   Blue Room Unlocker for Crossfire
*
* (c) Copyright 2009 by KORD_12.7
*
* This file is provided as is (no warranties)
*/

#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Blue Room Unlocker"
#define VERSION "v1.0"
#define AUTHOR "KORD_12.7"

#define SPAWNFLAGS 768

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("br_unlock", VERSION, FCVAR_SERVER)
	
	unlock_secret_door()
}

unlock_secret_door()
{
	new map_name[10]; get_mapname(map_name, charsmax(map_name))
	
	if(equal(map_name,"crossfire"))
	{
		new eEnt = engfunc(EngFunc_FindEntityByString, eEnt, "targetname", "secret_door")
		set_pev(eEnt, pev_spawnflags, SPAWNFLAGS)
		
		server_print("--- Blue room unlocked, enjoy :D ---")
	}
}
