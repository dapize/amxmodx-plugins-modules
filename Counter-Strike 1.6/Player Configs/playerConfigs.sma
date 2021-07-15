
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <dbi>

#define PLUGIN	"playerConfigs"
#define AUTHOR	"Albernaz O Carniceiro Demoniaco"
#define VERSION	"1.1"

#define DB_NAME "playersConfigs"

#define TABLE_PLAYERS_CONFIGS "playersConfigs"
#define TABLE_PLAYERS_CONFIGS_CVARS "playersConfigsCvars"

#define TABLE_TOP_PLAYERS_CONFIGS "topPlayersConfigs"
#define TABLE_TOP_PLAYERS_CONFIGS_CVARS "topPlayersConfigsCvars"

#define SQLITE_DIGITS 5

new const TOP_PLAYERS_CONFIGS_FOLDER[] = "topPlayersConfigs"

#define EDIT_FLAG ADMIN_KICK

enum CVARS
{
	ENABLED,
	MSG_SAVE,
	MSG_LOAD,
	MSG_LOADOTHER,
	MSG_LOADTOP
}

/* Chat messages */
#define MSG_SAVE_TEXT "Player ^"%s^" has saved his personal configs"
#define MSG_LOAD_TEXT "Player ^"%s^" has loaded his personal configs"
#define MSG_LOADOTHER_TEXT "Player ^"%s^" has loaded the public configs of the player ^"%s^""
#define MSG_LOADTOP_TEXT "Player ^"%s^" has loaded the configs of the top player ^"%s^""

new CVARS_LIST[CVARS]

enum MENUS_FUNC_IDS
{
	Main,
	ManageTopPlayersConfs
}

const FUNC_ID_MAXDIGITS = 3

new menusFuncIDs[MENUS_FUNC_IDS]

new const MENU_TITLE_MAIN[] = "Menu Player Configs"
new const MENU_EXIT_TEXT[] =  "\rexit"
new const MENU_BACK_TEXT[] =  "\dback"

new MENU_MSG_CONFIG_SAVED[] = "Your configuration has been saved"
new MENU_MSG_CONFIG_LOADED[] = "Your configuration has been loaded"
new MENU_MSG_PLAYER_CONFIG_LOADED[] = "Player configuration has been loaded"
new MENU_MSG_CONFIG_CHANGED[] = "Your configuration has been changed"
new MENU_MSG_NO_CONFIGS[] = "There aren't public configs yet"
new MENU_MSG_SEL_TOP_CONFIG_TO_ADD[] = "Select a top player config to add:"
new MENU_MSG_NO_TOP_CONFIGS_TO_ADD[] = "There aren't top player configs to add"
new MENU_MSG_SEL_TOP_CONFIG_TO_DEL[] = "Select a top player config to delete:"
new MENU_MSG_NO_TOP_CONFIGS_TO_DEL[] = "There aren't top player configs to delete"
new MENU_MSG_SEL_TOP_CONFIG_TO_LOAD[] = "Select a top player config to load:"
new MENU_MSG_NO_TOP_CONFIGS_TO_LOAD[] = "There aren't top player configs to load"
new MENU_MSG_TOP_CONFIG_LOAD[] = "Top Player config has been loaded"
new MENU_MSG_TOP_CONFIG_ADDED[] = "Top Player config has been added"
new MENU_MSG_TOP_CONFIG_DELETED[] = "Top Player config has been deleted"
new MENU_MSG_TOP_CONFIG_NOT_ADDED[] = "Top Player config wasn't added. Check if already exists one with that name"
new MENU_MSG_SELECT_PLAYER[] = "Select a player:"
new MENU_MSG_MANAGE_TOP_PLAYERS[] = "Manage Top Player configs:"

new MENU_TEXT_PUBLIC[] = "Public: ^"%s^""
new MENU_TEXT_AUTOLOAD[] = "Autoload: ^"%s^"^n"
new MENU_TEXT_SAVE[] = "Save^n"

new const MENU_TEXT_YES[] = "\yyes\w"
new const MENU_TEXT_NO[] = "\yno\w"

const MENU_MSG_MAXLEN = sizeof MENU_MSG_TOP_CONFIG_NOT_ADDED;

new CVARS_NAMES[][] = 
{ 
	"spec_autodirector_internal","ati_npatch","ati_subdiv","bgmvolume","bottomcolor","brightness","cl_backspeed","cl_cmdbackup","cl_cmdrate","cl_corpsestay","cl_crosshair_color","cl_crosshair_size","cl_crosshair_translucent","cl_dlmax","cl_download_ingame","cl_dynamiccrosshair","cl_forwardspeed","cl_himodels","cl_idealpitchscale","cl_lc","cl_logocolor", 
	"cl_logofile","cl_lw","cl_minmodels","cl_radartype","cl_righthand","cl_shadows","cl_timeout","cl_updaterate","cl_vsmoothing","cl_weather","console","con_color","crosshair","fastsprites","fps_max","fps_modem","gamma","gl_dither","gl_flipmatrix","gl_fog","gl_monolights","gl_overbright","gl_polyoffset","hisound","hpk_maxsize","hud_capturemouse","hud_centerid",
	"hud_draw","hud_fastswitch","hud_saytext_internal","hud_takesshots","joystick","lookspring","lookstrafe","model","MP3FadeTime","MP3Volume","mp_decals","m_filter","m_forward","m_pitch","m_side","m_yaw","name","net_graph","net_graphpos","net_scale","r_bmodelhighfrac","r_detailtextures","sensitivity","skin","spec_drawcone_internal",
	"spec_drawnames_internal","spec_drawstatus_internal","spec_mode_internal","spec_pip","suitvolume","sv_aim","sv_voiceenable","s_a3d","s_automax_distance","s_automin_distance","s_bloat","s_distance","s_doppler","s_eax","s_leafnum","s_max_distance","s_min_distance","s_numpolys","s_polykeep","s_polysize","s_refdelay","s_refgain","s_rolloff","s_verbwet","team",
	"topcolor","viewsize","voice_enable","voice_forcemicrecord","voice_modenable","voice_scale","volume","_cl_autowepswitch","_snd_mixahead"
}

const CVARS_NAMES_SIZE = sizeof CVARS_NAMES
const CVAR_NAME_MAXLEN = 27
const CVAR_VALUE_MAXLEN = 32

const CONFIGS_DIR_LEN = 30
new CONFIGS_DIR[CONFIGS_DIR_LEN];

const TOP_PLAYER_CONFIGS_DIR_LEN = sizeof CONFIGS_DIR + 1 + sizeof TOP_PLAYERS_CONFIGS_FOLDER;
new TOP_PLAYER_CONFIGS_DIR[TOP_PLAYER_CONFIGS_DIR_LEN];

new SQL_ERROR_MSG[256]
	
const N_PLAYER_IDS = 33

new bool:autoLoadConfig[N_PLAYER_IDS]

new bool:IS_PUBLIC[N_PLAYER_IDS]
new bool:AUTOLOAD[N_PLAYER_IDS]

const bool:AUTOLOAD_DEFAULT = false;
const bool:IS_PUBLIC_DEFAULT = false;

Sql:sql_getConnection()
	return dbi_connect("", "", "", DB_NAME , SQL_ERROR_MSG, 255);

sql_updatePlayerName(id,playerConfigID)
{
	new name[32]
	get_user_name(id,name,31);
	
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"UPDATE %s SET playerName=^"%s^" WHERE ID=%d",TABLE_PLAYERS_CONFIGS,name,playerConfigID);
	
	dbi_close(connection);
	
	
}
	
sql_getTopPlayerConfigID(topPlayerName[])
{
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT ID FROM %s WHERE topPlayerName='%s'",TABLE_TOP_PLAYERS_CONFIGS,topPlayerName);
		
	new topPlayerConfigID;
	
	if(result >= RESULT_OK)
		topPlayerConfigID = dbi_field(result,1);
	
	dbi_close(connection);
	
	return topPlayerConfigID;
}

sql_getPlayerConfigName(playerConfigID,name[32])
{
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT playerName FROM %s WHERE ID='%d'",TABLE_PLAYERS_CONFIGS,playerConfigID);
		
	if(result >= RESULT_OK)
	{
		dbi_field(result,1,name,31);
		dbi_free_result(result);
	}
	
	dbi_close(connection);
}
	
sql_getTopPlayerConfigName(topPlayerConfigID,topPlayerName[32])
{
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT topPlayerName FROM %s WHERE ID='%d'",TABLE_TOP_PLAYERS_CONFIGS,topPlayerConfigID);
		
	if(result >= RESULT_OK)
	{
		dbi_field(result,1,topPlayerName,31);
		dbi_free_result(result);
	}
	
	dbi_close(connection);
}	
	
sql_getPlayerConfigID(steamID[34])
{
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT ID FROM %s WHERE steamID='%s'",TABLE_PLAYERS_CONFIGS,steamID);
	
	new playerConfigID;
	
	if(result >= RESULT_OK)
		playerConfigID = dbi_field(result,1);
	
	dbi_close(connection);
	
	return playerConfigID;
}

sql_getMyConfigID(id)
{
	new steamID[34]
	get_user_authid(id,steamID,33)
	
	return sql_getPlayerConfigID(steamID);
}

bool:sql_changeMyConfigData(id,bool:autoload,bool:isPublic)
{
	new steamID[34]
	get_user_authid(id,steamID,33);
	new Sql:connection = sql_getConnection();
	
	dbi_query(connection,"UPDATE %s SET autoload=%d,isPublic=%d WHERE steamID='%s'",TABLE_PLAYERS_CONFIGS,_:autoload,_:isPublic,steamID);
	dbi_close(connection);
}

bool:sql_getMyConfigBool(id,columnName[])
{
	new steamID[34]
	
	get_user_authid(id,steamID,33);
	
	new Sql:connection = sql_getConnection();
	
	new bool:columnValue;
	
	new Result:result = dbi_query(connection,"SELECT %s FROM %s WHERE steamID='%s'",columnName,TABLE_PLAYERS_CONFIGS,steamID);
	
	if(result >= RESULT_OK)
		columnValue = bool:dbi_field(result,1);
	
	dbi_close(connection);
	
	return columnValue;
}

sql_existsPlayerConfig(steamID[34])
{
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT * FROM %s WHERE steamID=^"%s^"",TABLE_PLAYERS_CONFIGS,steamID)
	
	new bool:exists = (result >= RESULT_OK)
	
	if(exists)
		dbi_free_result(result);
	
	dbi_close(connection);
	
	return exists;
}

sql_existsTopPlayerConfig(topPlayerName[])
{
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT * FROM %s WHERE topPlayerName=^"%s^"",TABLE_TOP_PLAYERS_CONFIGS,topPlayerName)
	
	new bool:exists = (result >= RESULT_OK)
	
	if(exists)
		dbi_free_result(result);
	
	dbi_close(connection);
	
	return exists;
}

sql_registerMyConfig(id,bool:isPublic,bool:autoLoad)
{
	new steamID[34];
	get_user_authid(id,steamID,33);
	
	new name[32];
	get_user_name(id,name,31);
	
	return sql_registerPlayerConfig(steamID,name,isPublic,autoLoad);
}

sql_deletePlayerConfig(steamID[34])
{
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"DELETE FROM %s WHERE steamID='%s'",TABLE_PLAYERS_CONFIGS,steamID);
	dbi_close(connection);
}

sql_deleteTopPlayerConfig(topPlayerConfigID)
{
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"DELETE FROM %s WHERE ID='%d'",TABLE_TOP_PLAYERS_CONFIGS,topPlayerConfigID);
	dbi_close(connection);
}

sql_registerPlayerConfig(steamID[34],name[32],bool:isPublic,bool:autoLoad)
{
	sql_deletePlayerConfig(steamID);
	
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"INSERT INTO %s (steamID,playerName,isPublic,autoLoad) VALUES ('%s',^"%s^",%d,%d)",TABLE_PLAYERS_CONFIGS,steamID,name,isPublic,autoLoad);
	
	dbi_close(connection);
	
	new playerConfigID =  sql_getPlayerConfigID(steamID);	
	
	sql_deletePlayerConfigCvars(playerConfigID);
	
	return playerConfigID;
}

sql_registerTopPlayerConfig(topPlayerName[])
{	
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"INSERT INTO %s (topPlayerName) VALUES (^"%s^")",TABLE_TOP_PLAYERS_CONFIGS,topPlayerName);
	
	dbi_close(connection);
	
	new topPlayerConfigID =  sql_getTopPlayerConfigID(topPlayerName);
	
	return topPlayerConfigID;
}

sql_deletePlayerConfigCvars(playerConfigID)
{
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"DELETE FROM %s WHERE playerConfigID='%d'",TABLE_PLAYERS_CONFIGS_CVARS,playerConfigID);
	dbi_close(connection);
}

sql_deleteTopPlayerConfigCvars(topPlayerConfigID)
{
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"DELETE FROM %s WHERE topPlayerConfigID='%d'",TABLE_TOP_PLAYERS_CONFIGS_CVARS,topPlayerConfigID);
	dbi_close(connection);
}
sql_savePlayerConfigCvar(playerConfigID,cvarName[],cvarValue[])
{
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"INSERT INTO %s (playerConfigID,cvarName,cvarValue) VALUES (%d,'%s','%s')",TABLE_PLAYERS_CONFIGS_CVARS,playerConfigID,cvarName,cvarValue);
	dbi_close(connection);
}

sql_saveTopPlayerConfigCvar(topPlayerConfigID,cvarName[],cvarValue[])
{
	new Sql:connection = sql_getConnection();
	dbi_query(connection,"INSERT INTO %s (topPlayerConfigID,cvarName,cvarValue) VALUES (%d,'%s','%s')",TABLE_TOP_PLAYERS_CONFIGS_CVARS,topPlayerConfigID,cvarName,cvarValue);
	dbi_close(connection);
}

sql_loadTopPlayerConfig(id,topPlayerConfigID)
{
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT cvarName,cvarValue FROM %s WHERE topPlayerConfigID =%d",TABLE_TOP_PLAYERS_CONFIGS_CVARS,topPlayerConfigID);
	
	if(result >= RESULT_OK)
	{
		while(dbi_nextrow(result))
		{
			new cvarName[CVAR_NAME_MAXLEN];
			new cvarValue[CVAR_VALUE_MAXLEN];
			
			dbi_field(result,1,cvarName,CVAR_NAME_MAXLEN -1);
			dbi_field(result,2,cvarValue,CVAR_VALUE_MAXLEN -1);
			
			client_cmd(id,"%s ^"%s^"",cvarName,cvarValue);
		}
	}
	
	dbi_close(connection);
}
sql_loadPlayerConfig(id,playerConfigID)
{
	new Sql:connection = sql_getConnection();
		
	new Result:result = dbi_query(connection,"SELECT cvarName,cvarValue FROM %s WHERE playerConfigID =%d",TABLE_PLAYERS_CONFIGS_CVARS,playerConfigID);
	
	if(result >= RESULT_OK)
	{
		while(dbi_nextrow(result))
		{
			new cvarName[CVAR_NAME_MAXLEN];
			new cvarValue[CVAR_VALUE_MAXLEN];
			
			dbi_field(result,1,cvarName,CVAR_NAME_MAXLEN -1);
			dbi_field(result,2,cvarValue,CVAR_VALUE_MAXLEN -1);
			
			client_cmd(id,"%s ^"%s^"",cvarName,cvarValue);
		}
	}
	
	dbi_close(connection);
}

sql_loadMyConfig(id)
{
	new steamID[34];
	get_user_authid(id,steamID,33);
	
	new playerConfigID = sql_getPlayerConfigID(steamID);
	
	sql_loadPlayerConfig(id,playerConfigID);
}

loadMyConfig(id)
{
	sql_loadMyConfig(id);
}

saveMyConfig(id,bool:isPublic,bool:autoLoad)
{
	new myConfigID = sql_registerMyConfig(id,isPublic,autoLoad)
	
	if(myConfigID)
		saveMyCvars(id,myConfigID)
}

public saveMyCvars(id,myConfigID)
{
	new params[1]
	params[0] = myConfigID;
	
	for(new i=0;i<CVARS_NAMES_SIZE;i++)
		query_client_cvar(id,CVARS_NAMES[i],"saveMyCvar",1,params);
}

public saveMyCvar(id,cvarName[], cvarValue[],params[])
{
	new myConfigID = params[0];
	sql_savePlayerConfigCvar(myConfigID,cvarName,cvarValue);
}

public client_putinserver(id)
{
	autoLoadConfig[id] = false;
	
	new playerConfigID = sql_getMyConfigID(id)
	
	if(playerConfigID)
	{
		sql_updatePlayerName(id,playerConfigID)
	
		autoLoadConfig[id] = sql_getMyConfigBool(id,"autoLoad")
	}	
}

public playerSpawn(id)
{
	if(autoLoadConfig[id])
	{
		loadMyConfig(id);
		autoLoadConfig[id] = false;
	}
}

public plugin_cfg()
{
	get_configsdir(CONFIGS_DIR,CONFIGS_DIR_LEN-1);
	
	format(TOP_PLAYER_CONFIGS_DIR,TOP_PLAYER_CONFIGS_DIR_LEN-1,"%s/%s",CONFIGS_DIR,TOP_PLAYERS_CONFIGS_FOLDER);
	
	if(!dir_exists(TOP_PLAYER_CONFIGS_DIR))
		mkdir(TOP_PLAYER_CONFIGS_DIR);
	
	menusFuncIDs[Main] = get_func_id("showMenuMain", -1);
	menusFuncIDs[ManageTopPlayersConfs] = get_func_id("showMenuManageTopPlayerConfs",-1);
	
	CVARS_LIST[ENABLED] = register_cvar("playerconfs_enabled", "1");
	CVARS_LIST[MSG_SAVE] = register_cvar("playerconfs_msg_save", "0");
	CVARS_LIST[MSG_LOAD] = register_cvar("playerconfs_msg_load", "1");
	CVARS_LIST[MSG_LOADOTHER] = register_cvar("playerconfs_msg_loadother", "1");
	CVARS_LIST[MSG_LOADTOP] = register_cvar("playerconfs_msg_loadtop", "1");
}

public readTopPlayerConfigFile(name[])
{
	const topPlayerConfigFileLen = sizeof TOP_PLAYER_CONFIGS_DIR + 1+ 32 + 4;
	new topPlayerConfigFile[topPlayerConfigFileLen]
	
	format(topPlayerConfigFile,topPlayerConfigFileLen-1,"%s/%s.cfg",TOP_PLAYER_CONFIGS_DIR,name);
	
	if(file_exists(topPlayerConfigFile))
	{
		if(!sql_existsTopPlayerConfig(name))
		{
			new topPlayerConfigID = sql_registerTopPlayerConfig(name);
			
			new word[CVAR_NAME_MAXLEN]		
			
			const lineLen = CVAR_NAME_MAXLEN + 2 + CVAR_VALUE_MAXLEN + 1;
			new line[lineLen]
			
			new fileHandle = fopen(topPlayerConfigFile,"r");
			
			while( !feof(fileHandle) )
			{
				fgets (fileHandle, line, lineLen-1);
				
				new spacePos = strfind(line," ") 
				
				if(spacePos != -1)
				{
					strbreak(line,word,spacePos,line,lineLen-spacePos);
			
					new spacePos = strfind(line[1],"^"") 
					
					if(spacePos != -1)
					{
						format(line,spacePos,"%s",line[1]);
						
						if(strcmp(word,"exec") & strcmp(word,"bind") & strcmp(word,"setinfo") & strcmp(word,"//") & strcmp(word,"alias") ) 
						{
							sql_saveTopPlayerConfigCvar(topPlayerConfigID,word,line)
						}
						
					}
				}
			}
			
			fclose(fileHandle);
		
			return 1;
		}
	}
	
	return 0;
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)	
	
	register_clcmd("playerconfigs","showMenuMain");
	register_clcmd("playerconfs","showMenuMain");
	register_clcmd("say playerconfigs","showMenuMain");
	register_clcmd("say playerconfs","showMenuMain");
	
	RegisterHam(Ham_Spawn,"player","playerSpawn");
}

public showMenuWarning(id,msg[],menuFuncID)
{
	new menu = menu_create("","handleMenuWarning");
	
	const fullTitleLen = sizeof MENU_TITLE_MAIN + 2 + MENU_MSG_MAXLEN;
	new fullTitle[fullTitleLen]
	
	format(fullTitle,fullTitleLen-1,"%s^n^n%s",MENU_TITLE_MAIN,msg);
	
	menu_setprop(menu,MPROP_TITLE,fullTitle);
	menu_setprop(menu, MPROP_EXITNAME,MENU_EXIT_TEXT);
	
	new menuFuncIDString[FUNC_ID_MAXDIGITS+1]
	num_to_str(menuFuncID,menuFuncIDString,FUNC_ID_MAXDIGITS)
	
	menu_additem(menu,MENU_BACK_TEXT,menuFuncIDString);
	
	menu_display(id,menu);	
}

public handleMenuWarning(id , menu , item)
{
	if( item < 0 ) 
	{	
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new menuFuncIDString[FUNC_ID_MAXDIGITS+1];		
	menu_item_getinfo(menu,item,access, menuFuncIDString ,FUNC_ID_MAXDIGITS,_,_, callback);		
	menu_destroy(menu);
	
	new menuFuncID = str_to_num(menuFuncIDString);
	
	callfunc_begin_i(menuFuncID,-1)
	callfunc_push_int(id)
	callfunc_end()
	
	return PLUGIN_HANDLED;
}

public showMenuMain(id)
{
	if(get_pcvar_num(CVARS_LIST[ENABLED]))
	{
		new menu = menu_create("","handleMenuMain");
		menu_setprop(menu,MPROP_TITLE,MENU_TITLE_MAIN);
		
		new steamID[34];
		get_user_authid(id,steamID,33);
		
		if(sql_existsPlayerConfig(steamID))
		{
			menu_additem(menu,"Save own","1");
			menu_additem(menu,"Load own","2");
			menu_additem(menu,"Edit own settings^n","3");
		}
		else
		{
			menu_additem(menu,"Save own^n","1");
		}
		
		menu_additem(menu,"Load server's player config","4");
		menu_additem(menu,"Load top player config^n","5");
		
		if(get_user_flags(id) & EDIT_FLAG)
			menu_additem(menu,"Edit top player configs","6");
		
		menu_setprop(menu, MPROP_EXITNAME,MENU_EXIT_TEXT);	
		
		menu_display(id,menu);	
	}
	return PLUGIN_HANDLED;
}

public handleMenuMain(id , menu , item)
{
	if( item < 0 ) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new actionString[2];		
	menu_item_getinfo(menu,item,access, actionString ,1,_,_, callback);		
	menu_destroy(menu);
	new action = str_to_num(actionString);	
	
	switch(action)
	{
		case 1:
		{
			goToMenuSaveConfig(id)
		}		
		case 2:
		{
			if(get_pcvar_num(CVARS_LIST[MSG_LOAD]))
			{
				new name[32]
				get_user_name(id,name,31);
				client_print(0,print_chat,MSG_LOAD_TEXT,name);
			}
			
			loadMyConfig(id);
			showMenuWarning(id,MENU_MSG_CONFIG_LOADED,menusFuncIDs[Main]);
		}
		case 3:
		{
			goToMenuEditConfig(id);
		}
		case 4:
		{
			showMenuSelectServerPlayer(id);
		}
		case 5:
		{
			showMenuSelTopPlayerConfLoad(id);
		}
		case 6:
		{
			showMenuManageTopPlayerConfs(id);
		}
		
	}
	
	return PLUGIN_HANDLED;
}

public goToMenuEditConfig(id)
{
	AUTOLOAD[id] = sql_getMyConfigBool(id,"autoload");
	IS_PUBLIC[id] = sql_getMyConfigBool(id,"isPublic");
	
	showMenuEditConfig(id);
}

public showMenuEditConfig(id)
{
	new menu = menu_create("","handleMenuEditConfig");
	menu_setprop(menu,MPROP_TITLE,MENU_TITLE_MAIN);
	
	const textPublicLen = sizeof MENU_TEXT_PUBLIC + sizeof MENU_TEXT_YES;
	new textPublic[textPublicLen]
	
	const textAutoloadLen = sizeof MENU_TEXT_AUTOLOAD + sizeof MENU_TEXT_YES;
	new textAutoload[textAutoloadLen] 
	
	format(textPublic,textPublicLen-1,MENU_TEXT_PUBLIC, IS_PUBLIC[id] ? MENU_TEXT_YES : MENU_TEXT_NO);
	format(textAutoload,textAutoloadLen-1,MENU_TEXT_AUTOLOAD,AUTOLOAD[id] ? MENU_TEXT_YES : MENU_TEXT_NO);
	
	menu_additem(menu,textPublic,"1");
	menu_additem(menu,textAutoload,"2");
	
	menu_additem(menu,MENU_TEXT_SAVE,"3");
	
	menu_additem(menu,MENU_BACK_TEXT,"0");
	
	menu_setprop(menu, MPROP_EXITNAME,MENU_EXIT_TEXT);	
	
	menu_display(id,menu);
	
	return PLUGIN_HANDLED;
}
public handleMenuEditConfig(id , menu , item)
{
	if( item < 0 ) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new actionString[2];		
	menu_item_getinfo(menu,item,access, actionString ,1,_,_, callback);		
	menu_destroy(menu);
	new action = str_to_num(actionString);	
	
	switch(action)
	{
		case 0:
		{
			showMenuMain(id)
		}
		case 1:
		{
			IS_PUBLIC[id] = !IS_PUBLIC[id];
			showMenuEditConfig(id)
		}		
		case 2:
		{
			AUTOLOAD[id] = !AUTOLOAD[id];
			showMenuEditConfig(id)
		}
		case 3:
		{
			sql_changeMyConfigData(id,AUTOLOAD[id],IS_PUBLIC[id]);
			showMenuWarning(id,MENU_MSG_CONFIG_CHANGED,menusFuncIDs[Main]);
		}
		
	}
	
	return PLUGIN_HANDLED;
}

public goToMenuSaveConfig(id)
{
	AUTOLOAD[id] = AUTOLOAD_DEFAULT;
	IS_PUBLIC[id] = IS_PUBLIC_DEFAULT;
	
	showMenuSaveConfig(id);
}

public showMenuSaveConfig(id)
{
	new menu = menu_create("","handleMenuSaveConfig");
	menu_setprop(menu,MPROP_TITLE,MENU_TITLE_MAIN);
	
	const textPublicLen = sizeof MENU_TEXT_PUBLIC + sizeof MENU_TEXT_YES;
	new textPublic[textPublicLen]
	
	const textAutoloadLen = sizeof MENU_TEXT_AUTOLOAD + sizeof MENU_TEXT_YES;
	new textAutoload[textAutoloadLen] 
	
	format(textPublic,textPublicLen-1,MENU_TEXT_PUBLIC, IS_PUBLIC[id] ? MENU_TEXT_YES : MENU_TEXT_NO);
	format(textAutoload,textAutoloadLen-1,MENU_TEXT_AUTOLOAD,AUTOLOAD[id] ? MENU_TEXT_YES : MENU_TEXT_NO);
	
	menu_additem(menu,textPublic,"1");
	menu_additem(menu,textAutoload,"2");
	
	menu_additem(menu,MENU_TEXT_SAVE,"3");
	
	menu_additem(menu,MENU_BACK_TEXT,"0");
	
	menu_setprop(menu, MPROP_EXITNAME,MENU_EXIT_TEXT);	
	
	menu_display(id,menu);
	
	return PLUGIN_HANDLED;
}

public handleMenuSaveConfig(id , menu , item)
{
	if( item < 0 ) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new actionString[2];		
	menu_item_getinfo(menu,item,access, actionString ,1,_,_, callback);		
	menu_destroy(menu);
	new action = str_to_num(actionString);	
	
	switch(action)
	{
		case 0:
		{
			showMenuMain(id)
		}
		case 1:
		{
			IS_PUBLIC[id] = !IS_PUBLIC[id];
			showMenuSaveConfig(id)
		}		
		case 2:
		{
			AUTOLOAD[id] = !AUTOLOAD[id];
			showMenuSaveConfig(id)
		}
		case 3:
		{
			if(get_pcvar_num(CVARS_LIST[MSG_SAVE]))
			{
				new name[32]
				get_user_name(id,name,31);
				client_print(0,print_chat,MSG_SAVE_TEXT,name);
			}

			saveMyConfig(id,IS_PUBLIC[id],AUTOLOAD[id]);
			showMenuWarning(id,MENU_MSG_CONFIG_SAVED,menusFuncIDs[Main]);
		}
		
	}
	
	return PLUGIN_HANDLED;
}

public showMenuSelectServerPlayer(id)
{
	new menu = menu_create("","handleMenuSelectServerPlayer");
	menu_setprop(menu,MPROP_TITLE,MENU_TITLE_MAIN);
	
	new Sql:connection = sql_getConnection();
	
	new steamID[34];
	get_user_authid(id,steamID,33);
	
	new Result:result = dbi_query(connection,"SELECT ID,playerName FROM %s WHERE isPublic=1 AND steamID!='%s'",TABLE_PLAYERS_CONFIGS,steamID);
	
	if(result >= RESULT_OK)
	{
		const titleLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_SELECT_PLAYER
		new title[titleLen]
		
		format(title,titleLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_SELECT_PLAYER);
		
		menu_setprop(menu,MPROP_TITLE,title);
		
		while(dbi_nextrow(result))
		{
			new playerConfigID = dbi_field(result,1);
			new playerName[32]
			dbi_field(result,2,playerName,31);
			
			new playerConfigIDString[SQLITE_DIGITS+1]
			num_to_str(playerConfigID,playerConfigIDString,SQLITE_DIGITS);
			
			menu_additem(menu,playerName,playerConfigIDString);
		}
	}
	else
	{
		const titleNoConfigsLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_NO_CONFIGS
		new titleNoConfigs[titleNoConfigsLen]
		
		format(titleNoConfigs,titleNoConfigsLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_NO_CONFIGS);
		
		menu_setprop(menu,MPROP_TITLE,titleNoConfigs);
		
		menu_additem(menu,MENU_BACK_TEXT,"0");
	}
	
	menu_setprop(menu, MPROP_EXITNAME,MENU_EXIT_TEXT);	
	
	menu_display(id,menu);
	
	dbi_close(connection);
	
	return PLUGIN_HANDLED;
}

public handleMenuSelectServerPlayer(id , menu , item)
{
	if( item < 0 ) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new playerConfigIDString[SQLITE_DIGITS+1];		
	menu_item_getinfo(menu,item,access,playerConfigIDString,SQLITE_DIGITS,_,_, callback);		
	menu_destroy(menu);
	new playerConfigID = str_to_num(playerConfigIDString);	
	
	switch(playerConfigID)
	{
		case 0:
		{
			showMenuMain(id);
		}
		default:
		{
			if(get_pcvar_num(CVARS_LIST[MSG_LOADOTHER]))
			{
				new name[32]
				get_user_name(id,name,31);
				
				new nameOther[32]
				sql_getPlayerConfigName(playerConfigID,nameOther);
				
				client_print(0,print_chat,MSG_LOADOTHER_TEXT,name,nameOther);
			}
			
			sql_loadPlayerConfig(id,playerConfigID);
			showMenuWarning(id,MENU_MSG_PLAYER_CONFIG_LOADED,menusFuncIDs[Main]);
		}
	}
	
	return PLUGIN_HANDLED;
}

public showMenuManageTopPlayerConfs(id)
{
	new menu = menu_create("","handleMenuManageTopPlayerConfs");
	
	const titleLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_MANAGE_TOP_PLAYERS;
	new title[titleLen]
	
	format(title,titleLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_MANAGE_TOP_PLAYERS);
	
	menu_setprop(menu,MPROP_TITLE,title);
	
	menu_setprop(menu, MPROP_EXITNAME,MENU_EXIT_TEXT);	
	
	menu_additem(menu,"Add","1");
	menu_additem(menu,"Delete^n","2");
	
	menu_additem(menu,MENU_BACK_TEXT,"0");
	
	menu_display(id,menu);
	
	
	return PLUGIN_HANDLED;
}

public handleMenuManageTopPlayerConfs(id , menu , item)
{
	if( item < 0 ) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new actionString[2];		
	menu_item_getinfo(menu,item,access,actionString,1,_,_, callback);		
	menu_destroy(menu);
	new action = str_to_num(actionString);	
	
	switch(action)
	{
		case 0:
		{
			showMenuMain(id)
		}
		case 1:
		{
			showMenuSelTopPlayerConfToAdd(id)
		}
		case 2:
		{
			showMenuSelTopPlayerConfToDel(id);
		}
	}
	
	return PLUGIN_HANDLED;
}


public showMenuSelTopPlayerConfToAdd(id)
{
	new menu = menu_create("","handleMenuSelTopPlayerConfToAdd");
	
	new fileName[37];
	new topPlayerName[32]
	
	new bool:hasFiles;
	
	new dirHandle = open_dir(TOP_PLAYER_CONFIGS_DIR,fileName,36)
	
	if(dirHandle)
	{
		if(next_file(dirHandle,fileName,36))
		{
			while(next_file(dirHandle,fileName,36))
			{
				new len = strlen(fileName);
				
				if(contain(fileName[len-5],".cfg"))
				{
					hasFiles = true;
					
					format(topPlayerName,len-4,fileName);
					
					menu_additem(menu,topPlayerName,topPlayerName);
				}					
			}
		}
	}
	
	if(hasFiles)
	{
		const titleLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_SEL_TOP_CONFIG_TO_ADD;
		new title[titleLen]
		
		format(title,titleLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_SEL_TOP_CONFIG_TO_ADD);
		
		menu_setprop(menu,MPROP_TITLE,title);
	}
	else
	{
		const titleNoFilesLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_NO_TOP_CONFIGS_TO_ADD;
		new titleNoFiles[titleNoFilesLen]
		
		format(titleNoFiles,titleNoFilesLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_NO_TOP_CONFIGS_TO_ADD);
		
		menu_setprop(menu,MPROP_TITLE,titleNoFiles);
		menu_additem(menu,MENU_BACK_TEXT,"0");
	}
		
	menu_setprop(menu, MPROP_EXITNAME,MENU_EXIT_TEXT);	
	
	menu_display(id,menu);
	
	return PLUGIN_HANDLED;
}

public handleMenuSelTopPlayerConfToAdd(id , menu , item)
{
	if( item < 0 ) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new topPlayerName[32];		
	menu_item_getinfo(menu,item,access,topPlayerName,31,_,_, callback);		
	menu_destroy(menu);
	
	if(topPlayerName[0] == '0')
	{
		showMenuManageTopPlayerConfs(id)
	}
	else
	{
		new result = readTopPlayerConfigFile(topPlayerName);
		
		if(result)
		{
			showMenuWarning(id,MENU_MSG_TOP_CONFIG_ADDED,menusFuncIDs[ManageTopPlayersConfs]);	
		}
		else
		{
			showMenuWarning(id,MENU_MSG_TOP_CONFIG_NOT_ADDED,menusFuncIDs[ManageTopPlayersConfs]);	
		}
	}
	
	return PLUGIN_HANDLED;
}

public showMenuSelTopPlayerConfToDel(id)
{
	new menu = menu_create("","handleMenuSelTopPlayerConfToDel");
	
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT ID,topPlayerName FROM %s ORDER BY topPlayerName",TABLE_TOP_PLAYERS_CONFIGS);
	
	if(result >= RESULT_OK)
	{
		const titleLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_SEL_TOP_CONFIG_TO_DEL;
		new title[titleLen]
		
		format(title,titleLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_SEL_TOP_CONFIG_TO_DEL);
		
		menu_setprop(menu,MPROP_TITLE,title);
		
		while(dbi_nextrow(result))
		{
			new topPlayerConfigID = dbi_field(result,1);
			new topPlayerName[32]
			dbi_field(result,2,topPlayerName,31);
			
			new topPlayerConfigIDString[SQLITE_DIGITS+1];
			num_to_str(topPlayerConfigID,topPlayerConfigIDString,SQLITE_DIGITS);
			
			menu_additem(menu,topPlayerName,topPlayerConfigIDString);
		}
	}
	else
	{
		const titleNoFilesLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_NO_TOP_CONFIGS_TO_DEL;
		new titleNoFiles[titleNoFilesLen]
		
		format(titleNoFiles,titleNoFilesLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_NO_TOP_CONFIGS_TO_DEL);
		
		menu_setprop(menu,MPROP_TITLE,titleNoFiles);
		
		menu_additem(menu,MENU_BACK_TEXT,"0");
	}
	
	menu_display(id,menu);
	
	dbi_close(connection);
}

public handleMenuSelTopPlayerConfToDel(id , menu , item)
{
	if( item < 0 ) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new topPlayerConfigIDString[SQLITE_DIGITS+1]
	menu_item_getinfo(menu,item,access,topPlayerConfigIDString,SQLITE_DIGITS,_,_, callback);		
	menu_destroy(menu);
	
	new topPlayerConfigID = str_to_num(topPlayerConfigIDString);
	
	if(topPlayerConfigID)
	{
		showMenuWarning(id,MENU_MSG_TOP_CONFIG_DELETED,menusFuncIDs[ManageTopPlayersConfs]);	
		
		sql_deleteTopPlayerConfig(topPlayerConfigID);
		sql_deleteTopPlayerConfigCvars(topPlayerConfigID);
	}
	else
	{
		showMenuManageTopPlayerConfs(id);
	}
	
	return PLUGIN_HANDLED;
}

public showMenuSelTopPlayerConfLoad(id)
{
	new menu = menu_create("","handleMenuSelTopPlayerConfLoad");
	
	new Sql:connection = sql_getConnection();
	
	new Result:result = dbi_query(connection,"SELECT ID,topPlayerName FROM %s ORDER BY topPlayerName",TABLE_TOP_PLAYERS_CONFIGS);
	
	if(result >= RESULT_OK)
	{
		const titleLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_SEL_TOP_CONFIG_TO_LOAD;
		new title[titleLen]
		
		format(title,titleLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_SEL_TOP_CONFIG_TO_LOAD);
		
		menu_setprop(menu,MPROP_TITLE,title);
		
		while(dbi_nextrow(result))
		{
			new topPlayerConfigID = dbi_field(result,1);
			new topPlayerName[32]
			dbi_field(result,2,topPlayerName,31);
			
			new topPlayerConfigIDString[SQLITE_DIGITS+1];
			num_to_str(topPlayerConfigID,topPlayerConfigIDString,SQLITE_DIGITS);
			
			menu_additem(menu,topPlayerName,topPlayerConfigIDString);
		}
	}
	else
	{
		const titleNoFilesLen = sizeof MENU_TITLE_MAIN + 2 + sizeof MENU_MSG_NO_TOP_CONFIGS_TO_LOAD;
		new titleNoFiles[titleNoFilesLen]
		
		format(titleNoFiles,titleNoFilesLen-1,"%s^n^n%s",MENU_TITLE_MAIN,MENU_MSG_NO_TOP_CONFIGS_TO_LOAD);
		
		menu_setprop(menu,MPROP_TITLE,titleNoFiles);
		
		menu_additem(menu,MENU_BACK_TEXT,"0");
	}
	
	menu_display(id,menu);
	
	dbi_close(connection);
}

public handleMenuSelTopPlayerConfLoad(id , menu , item)
{
	if( item < 0 ) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new access, callback; 
	
	new topPlayerConfigIDString[SQLITE_DIGITS+1]
	menu_item_getinfo(menu,item,access,topPlayerConfigIDString,SQLITE_DIGITS,_,_, callback);		
	menu_destroy(menu);
	
	new topPlayerConfigID = str_to_num(topPlayerConfigIDString);
	
	if(topPlayerConfigID)
	{
		if(get_pcvar_num(CVARS_LIST[MSG_LOADTOP]))
		{
			new name[32]
			get_user_name(id,name,31);
			
			new topPlayerName[32]

			sql_getTopPlayerConfigName(topPlayerConfigID,topPlayerName);
			
			client_print(0,print_chat,MSG_LOADTOP_TEXT,name,topPlayerName);
		}
		
		sql_loadTopPlayerConfig(id,topPlayerConfigID);
		showMenuWarning(id,MENU_MSG_TOP_CONFIG_LOAD,menusFuncIDs[Main]);	
	}
	else
	{
		showMenuMain(id);
	}
	
	return PLUGIN_HANDLED;
}
