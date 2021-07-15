#include <amxmodx>
#include <amxmisc>

#if AMXX_VERSION_NUM < 190
	#assert "This plugin requires AMXX 1.9"
#endif

enum (+= 100)
{
	TASKWARN,
 	TASKSET,
 	TASKCHECK
 }

enum PlayerData
{
	g_Ping,
	g_Samples
}

enum Cvars
{
	VarPing, 
	Float:VarCheck, 
	VarTest, 
	Float:VarDelay, 
	VarImmunity, 
	VarImmunityFlag[2],
	VarNotify, 
	VarLog, 
	FlagImmunity
}

new ePlayerData[MAX_PLAYERS +1][PlayerData], pCvars[Cvars]

public plugin_init()
{
	register_plugin("NewPingkicker", "1.3","OLO & iceeedR")
	register_cvar("NewPingkicker", "1.3", FCVAR_SERVER | FCVAR_SPONLY |FCVAR_UNLOGGED )

	register_dictionary("NewPingkicker.txt")
	
	new pCvar
	pCvar = create_cvar("amx_hpk_immunity","1", .description = "Admin have immunity?")
	bind_pcvar_num(pCvar,pCvars[VarImmunity])
	
	pCvar = create_cvar("amx_hpk_flag","a", .description = "The admin immunity flag")
	bind_pcvar_string(pCvar, pCvars[VarImmunityFlag], charsmax(pCvars[VarImmunityFlag]))
	
	pCvar = create_cvar("amx_hpk_ping","200", .description = "The maximum ping allowed before being kicked.")
	bind_pcvar_num(pCvar, pCvars[VarPing])
	
	pCvar = create_cvar("amx_hpk_check","3.0", .description = "Time between Checks")
	bind_pcvar_float(pCvar, pCvars[VarCheck])
	
	pCvar = create_cvar("amx_hpk_tests","5", .description = "Checkcount")
	bind_pcvar_num(pCvar, pCvars[VarTest])
	
	pCvar = create_cvar("amx_hpk_delay","5.0", .description = "Delay between checks")
	bind_pcvar_float(pCvar, pCvars[VarDelay])
	
	pCvar = create_cvar("amx_hpk_notify","1", .description = "Type off notify(disable / all / only admins)")
	bind_pcvar_num(pCvar, pCvars[VarNotify])
	
	pCvar = create_cvar("amx_hpk_log", "1", .description = "Log kicked players name on 'log' folder")
	bind_pcvar_num(pCvar, pCvars[VarLog])
	
	AutoExecConfig(true, "NewPingkicker")
}

public plugin_cfg()
{
	if(pCvars[VarImmunity])
		pCvars[FlagImmunity] = read_flags(pCvars[VarImmunityFlag])
}

public client_disconnected(id)
{
 	remove_task(id + TASKCHECK)
	remove_task(id + TASKWARN)
}

public client_putinserver(id) 
{
	if(pCvars[VarImmunity] && get_user_flags(id) & pCvars[FlagImmunity])
		return PLUGIN_HANDLED
		
	ePlayerData[id][g_Ping] = ePlayerData[id][g_Samples] = 0
	
	if(is_user_connected(id))
	{
		set_task_ex( 10.0 , "showWarn" , id + TASKWARN, .flags = SetTask_Once)
	    
		if (pCvars[VarTest] != 0) 
		{
			set_task_ex(pCvars[VarDelay], "taskSetting", id + TASKSET, .flags = SetTask_Once)
		}
		else 
		{	    
			set_task_ex(pCvars[VarCheck] , "checkPing" , id + TASKCHECK, .flags = SetTask_Repeat)
		}
	
	}
	return PLUGIN_HANDLED
} 

public showWarn(taskId)
{
	new id = taskId - TASKWARN

	client_print_color(id, print_team_default,"%L", id ,"WARNING_MESSAGE", pCvars[VarPing])
}

public taskSetting(taskId) 
{
	new id = taskId - TASKSET

	set_task_ex(pCvars[VarCheck], "checkPing", id + TASKCHECK, .flags = SetTask_Repeat)
}

kickPlayer(id)
{
	if(!is_user_connected(id)) return
	
	if(pCvars[VarLog])
		log_amx("%L", id, "KICK_MESSAGE", id, pCvars[VarPing])

	new KickMessage[60]
	formatex(KickMessage, charsmax(KickMessage), "%l", "KICK_MESSAGE2")

	server_cmd("kick #%d ^"%s^"", get_user_userid(id), KickMessage)
}


public checkPing(taskId) 
{ 
	new id = taskId - TASKCHECK

	if(!is_user_connected(id)) return
	
	new Ping, Loss

	get_user_ping( id , Ping , Loss ) 

	ePlayerData[id][g_Ping] += Ping
	++ePlayerData[id][g_Samples]

	if((ePlayerData[id][g_Samples] >= pCvars[VarTest]) && (ePlayerData[id][g_Ping] / ePlayerData[id][g_Samples]) >= pCvars[VarPing])
	{	
		switch(pCvars[VarNotify])
		{
			case 0:
			{
				kickPlayer(id)
			}
			case 1:
			{
				client_print_color(0, print_team_default,"%l", id, "KICK_MESSAGE", id, pCvars[VarPing])
				kickPlayer(id)
			}
			case 2:
			{
				new iPlayers[MAX_PLAYERS], iNum
				get_players_ex(iPlayers, iNum, GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV)
				for(new i = 0; i < iNum; i++)
				{	
					if(is_user_admin(iPlayers[i]))
					{
						client_print_color(iPlayers[i], print_team_default,"%L", id, "KICK_MESSAGE", id, pCvars[VarPing])
					}
				}
				kickPlayer(id)
			}
		}
	}
}