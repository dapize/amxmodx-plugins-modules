/*	
	/////////////////////////////////////
       ///////// NAME REPLACER ////////
      /////////////////////////////////////
	
	http://forums.alliedmods.net/showthread.php?t=77401
	
	
	(c) Copyright 2008, anakin_cstrike
	This file is provided as is (no warranties). 
	
	--| Version |-- 1.1.0
	
	Changelog:
		* [ 1.1.0 ]
			- added cvars
			- 3 options: name change, kick or ban
			- you can choose the way the name is changed: from list or the last name the player used
			- admins can have immunity
			
		* [ 1.0 ]
			- first released
*/

#include <amxmodx>
#include <amxmisc>

new PLUGIN[] =		"Name Replacer"
#define VERSION 	"1.1.0"

// * editable
#define NAMES		32
#define DELAY		10.0
#define ACCESS		ADMIN_IMMUNITY

new const g_File[] = 	"name_list.txt";
// *

new g_NameList[ 2 ][ NAMES ][ 32 ], g_Count;
new toggle_plugin, toggle_ban, toggle_list, toggle_evoy;

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, "anakin_cstrike" );
	
	toggle_plugin = register_cvar( "namereplacer_mode", "1" );
	toggle_list = register_cvar( "namereplacer_list", "1" );
	toggle_ban = register_cvar( "namereplacer_banlenght", "1200" );
	toggle_evoy = register_cvar( "namereplacer_evoyadmins", "0" );
}

public plugin_cfg()
{
	new iDir[ 64 ], iFile[ 64 ];
	get_configsdir( iDir, sizeof iDir - 1 );
	formatex( iFile, sizeof iFile - 1, "%s/%s", iDir, g_File );
	
	if( !file_exists( iFile ) )
		write_file( iFile, "[Name Replacer]", -1 );
		
	new szFile = fopen( iFile, "rt" ), Buffer[ 512 ];
	
	while( !feof( szFile ) )
	{
		fgets( szFile, Buffer,sizeof Buffer - 1 );
		if( !Buffer[ 0 ] || Buffer[ 0 ] == ';' || strlen( Buffer ) < 3 )
			continue;
		
		trim( Buffer );
		strtok( Buffer, g_NameList[ 0 ][ g_Count ], sizeof g_NameList[ ][ ] - 1, g_NameList[ 1 ][ g_Count ], sizeof g_NameList[ ][ ] - 1, ';', 0 );
		
		g_Count++;
	}
	
	fclose( szFile );
}

public client_putinserver( id )
{
	if( !get_pcvar_num( toggle_plugin ) )
		return PLUGIN_CONTINUE;
	
	set_task( DELAY, "verify", id );
	return PLUGIN_CONTINUE;
}

public verify( id )
{
	if( !is_user_connected( id ) )
		return PLUGIN_CONTINUE;
	if( get_pcvar_num( toggle_evoy ) && IsAdmin( id ) )
		return PLUGIN_CONTINUE;
		
	new name[ 32 ], i;
	get_user_name( id, name, sizeof name - 1 );
	
	new userid = get_user_userid( id );
	
	for( i = 0; i < g_Count; i++ )
	{
		if( equali( name, g_NameList[ 0 ][ i ] ) )
		{
			switch( get_pcvar_num( toggle_plugin ) )
			{
				case 1:
				{
					client_print( id, print_chat, "That name is not allowed here! Changing name to ^"%s^"",g_NameList[ 1 ][ i ] );
					client_cmd( id, "name ^"%s^"", g_NameList[ 1 ][ i ]);
				}
				
				case 2: server_cmd( "kick #%d ^"Name forbidden!^"", userid );
				
				case 3:
				{
					new authid[ 32 ];
					get_user_authid( id, authid, sizeof authid - 1 );
					server_cmd( "amx_ban ^"%s^" %d ^"Name forbidden!^"", authid, get_pcvar_num( toggle_ban ) );
				}
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_infochanged( id )
{
	if( !get_pcvar_num( toggle_plugin ) )
		return PLUGIN_CONTINUE;
		
	if( get_pcvar_num( toggle_evoy ) && IsAdmin( id ) )
		return PLUGIN_CONTINUE;
		
	new newname[ 32 ], oldname[ 32 ], i;
	get_user_info( id, "name", newname, sizeof newname - 1 );
	get_user_name( id, oldname, sizeof oldname - 1 );
	
	if( equali( newname, oldname ) )
		return PLUGIN_CONTINUE;
		
	new userid = get_user_userid( id );
	
	for( i = 0; i < g_Count; i++ )
	{
		if( equali( newname, g_NameList[ 0 ][ i ] ) )
		{
			switch( get_pcvar_num( toggle_plugin ) )
			{
				case 1:
				{
					switch( get_pcvar_num( toggle_list ) )
					{
						case 0:
						{
							client_print( id, print_chat, "That name is not allowed here! Changing name to ^"%s^"", oldname );
							client_cmd( id, "name ^"%s^"", oldname );
						}
						
						case 1:
						{
							client_print( id, print_chat, "That name is not allowed here! Changing name to ^"%s^"", g_NameList[ 1 ][ i ] );
							client_cmd( id, "name ^"%s^"", g_NameList[ 1 ][ i ] );
						}
					}
				}
				
				case 2: server_cmd( "kick #%d ^"Name forbidden!^"", userid );
				
				case 3:
				{
					new authid[ 32 ];
					get_user_authid( id, authid, sizeof authid - 1 );
					server_cmd( "amx_ban ^"%s^" %d ^"Name forbidden!^"", authid, get_pcvar_num( toggle_ban ) );
				}
			}
				
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

bool: IsAdmin( index )
{
	if( ! ( get_user_flags( index ) & ACCESS ) )
		return true;
		
	return false;
}