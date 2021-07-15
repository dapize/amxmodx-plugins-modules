/*	Formatright © 2010, ConnorMcLeod

	This plugin is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this plugin; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <amxmisc>

#define VERSION "0.0.2"
#define PLUGIN "Config Adder"

new g_szMapCfgFile[128], g_szAmxxCfgFile[128], g_szPrefixCfgFile[128]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "ConnorMcLeod")
	register_dictionary("common.txt")

	register_concmd("addcfg_server", "ConCmd_AddCfg", ADMIN_CFG, "- Add a config in server.cfg")
	register_concmd("addcfg_game", "ConCmd_AddCfg", ADMIN_CFG, "- Add a config in game.cfg")
	register_concmd("amx_write_file", "ConCmd_WriteFile", ADMIN_CFG, "<file path> <fields>")
	register_concmd("amx_make_dir", "ConCmd_MkDir", ADMIN_CFG, "<dir path>")

	new szConfigsDir[64]
	get_configsdir(szConfigsDir, charsmax(szConfigsDir))

	formatex(g_szAmxxCfgFile, charsmax(g_szAmxxCfgFile), "%s/amxx.cfg", szConfigsDir)
	new szDescription[128]
	formatex(szDescription, charsmax(szDescription), "- Add a config in %s", g_szAmxxCfgFile)
	register_concmd("addcfg_amxx", "ConCmd_AddCfg", ADMIN_CFG, g_szAmxxCfgFile)

	formatex(g_szMapCfgFile, charsmax(g_szMapCfgFile), "%s/maps", szConfigsDir)
	if( !dir_exists(g_szMapCfgFile) )
	{
		mkdir(g_szMapCfgFile)
	}

	new szMapName[32]
	new n = get_mapname(szMapName, charsmax(szMapName))
	formatex(g_szMapCfgFile, charsmax(g_szMapCfgFile), "%s/maps/%s.cfg", szConfigsDir, szMapName)
	formatex(szDescription, charsmax(szDescription), "- Add a config in %s", g_szMapCfgFile)
	register_concmd("addcfg_map", "ConCmd_AddCfg", ADMIN_CFG, szDescription)

	for(new i; i<n; i++)
	{
		if( szMapName[i] == '_' )
		{
			szMapName[i] = 0
			formatex(g_szPrefixCfgFile, charsmax(g_szPrefixCfgFile), "%s/maps/prefix_%s.cfg", szConfigsDir, szMapName)	
			formatex(szDescription, charsmax(szDescription), "- Add a config in %s", g_szPrefixCfgFile)
			register_concmd("addcfg_prefix", "ConCmd_AddCfg", ADMIN_CFG, szDescription)
			break
		}
	}
}

public ConCmd_AddCfg(id, lvl, cid)
{
	if( cmd_access(id, lvl, cid, 2) )
	{
		new szCmd[16], szArgs[256]
		read_args(szArgs, charsmax(szArgs))
		if( szArgs[0] == '"' )
		{
			console_print(id, "Don't begin the config entry with a quote")
			console_print(id, "BAD : %s ^"mp_c4timer ^"35^"^"", szCmd)
			console_print(id, "BAD : %s ^"mp_c4timer 35^"", szCmd)
			console_print(id, "GOOD : %s mp_c4timer ^"35^"", szCmd)
			console_print(id, "GOOD : %s mp_c4timer 35", szCmd)
			console_print(id, "GOOD : %s mp_buytime ^"0.25^"", szCmd)
			console_print(id, "GOOD : %s sv_hostname ^"Best Server Ever^"", szCmd)
			return PLUGIN_HANDLED
		}
		new iFlags = get_user_flags(id)
		new szArg1[32], ptr
		read_argv(1, szArg1, charsmax(szArg1))

		if( (ptr = get_cvar_pointer(szArg1)) && (get_pcvar_flags(ptr) & FCVAR_PROTECTED) && (~iFlags & ADMIN_RCON) )
		{
			if( !(iFlags & ADMIN_PASSWORD && equal(szArg1, "sv_password")) )
			{
				console_print(id, "[AMXX] %L", id, "CVAR_NO_ACC")
				return PLUGIN_HANDLED
			}
		}

		read_argv(0, szCmd, charsmax(szCmd))
		new fp, szFile[128]
		switch( szCmd[7] )
		{
			case 'a': fp = copy(szFile, charsmax(szFile), g_szAmxxCfgFile)
			case 'g': fp = copy(szFile, charsmax(szFile), "game.cfg")
			case 'm': fp = copy(szFile, charsmax(szFile), g_szMapCfgFile)
			case 'p': fp = copy(szFile, charsmax(szFile), g_szPrefixCfgFile)
			case 's': fp = copy(szFile, charsmax(szFile), "server.cfg")
		}
		fp = fopen(szFile, "at")
		fprintf(fp, "^n%s^n", szArgs)
		fclose(fp)
		console_print(id, "Succeeded to write ^'%s^' in file ^'%s^'", szArgs, szFile)
	}
	return PLUGIN_HANDLED
}

public ConCmd_WriteFile(id, lvl, cid)
{
	if( cmd_access(id, lvl, cid, 3) )
	{
		new szFile[128], szArgs[384]
		new n = read_argv(1, szFile, charsmax(szFile))
		read_args(szArgs, charsmax(szArgs))
		new fp = fopen(szFile, "at")
		if( fp )
		{
			fprintf(fp, "^n%s^n", szArgs[n+1])
			fclose(fp)
			console_print(id, "Succeeded to write ^'%s^' in file ^'%s^'", szArgs[n+1], szFile)
		}
		else
		{
			console_print(id, "Failed to open file ^'%s^'", szFile)
		}
	}
	return PLUGIN_HANDLED
}

public ConCmd_MkDir(id, lvl, cid)
{
	if( cmd_access(id, lvl, cid, 2) )
	{
		new szDir[128]
		read_argv(1, szDir, charsmax(szDir))
		if( dir_exists(szDir) )
		{
			console_print(id, "Folder ^'%s^' already exists.", szDir)
		}
		else if( mkdir(szDir) )
		{
			console_print(id, "Failed to create ^'%s^' folder.", szDir)
		}
		else
		{
			console_print(id, "^'%s^' folder created.", szDir)
		}
	}
	return PLUGIN_HANDLED
}