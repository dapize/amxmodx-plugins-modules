/*
Server Connect Message

- Current version: 0.7.0 -

- Description -

Basically it displays a message when players connect.

- Cvars -

amx_connect_msg_on < 1 / 0> < On / Off> < Def: 1 >
amx_connect_msg_on < # > < Symbol used to seperate message lines. > < Def: '$' >
amx_conmsg < Message(max 191 symbols) > < Connect Message. Use the 'Token' to seperate lines(works just like /n and ^n) > < Def: "Welcome to my server!$Enjoy playing here.$Please, don't cheat!" >
amx_connect_store_type < 1 / 2 > < SteamID / IP. The method how plugin saves player info for reconnect. I made it for IP so that non-steam users could also use this. > < Def: 1 >

- ScreenShot -

http://img162.imageshack.us/img162/7344/screen1kiq.jpg

- Change Log -

0.7.0
*Initial Release

*/

#include <amxmodx>

#define VERSION "0.7.0"

#define MAXPLAYERS 32 + 1

//Cells for user info storage
#define TEMP_CELLS 33

//Time after player reconnect to remove player info. Used to remove it if player disconnects after reconnect
#define RECONNECT_TASK_TIME 3.0

//User info store methods
enum
{
	STORE_STEAM = 1,
	STORE_IP
}

//Connect Messages are stored here
new g_Messages[3][192]

//Cells currently occupied by user info's
new g_CurCells

//A multi-dimensional array that holds player info
new g_PlayerReconnectInfo[TEMP_CELLS][33]

//Cvars
new c_OnOff,c_Message,c_Token,c_StoreType

public plugin_init() {
	
	register_plugin("Server Connect Message",VERSION,"shine")
	
	register_cvar("servconmsg",VERSION,FCVAR_SERVER|FCVAR_SPONLY)
	
	//Cvars
	c_OnOff = register_cvar("amx_connect_msg_on","1")
	c_Token = register_cvar("amx_connect_msg_token","$")
	c_Message = register_cvar("amx_conmsg","Welcome to my server!$Enjoy playing here.$Please, don't cheat!")
	c_StoreType = register_cvar("amx_connect_store_type","1")	//1 - steamid, 2 - ip
	
	new tStr[192],Token[2]
	
	//Get Connect Messages from cvars
	get_pcvar_string(c_Message,tStr,191)
	get_pcvar_string(c_Token,Token,1)
	
	//Write them to a global array
	for(new i=0;i < 3;i++) strtok(tStr,g_Messages[i],191,tStr,191,Token[0])
}

public client_connect(id) {
	
	//Check if user hasn't already been forced to reconnect and check if he isn't a bot
	if(!CheckReconnect(id) && get_pcvar_num(c_OnOff) && !is_user_bot(id)) {
		
		//Set player cvars
		static i
		
		for(i = 1; i < 3; i++) client_cmd(id,"scr_connectmsg%d ^"%s^"",i,g_Messages[i])
		
		client_cmd(id,"scr_connectmsg ^"%s^"",g_Messages[0])
		
		//Store player Info
		switch(get_pcvar_num(c_StoreType)) {
			
			case STORE_STEAM : {
				
				get_user_authid(id,g_PlayerReconnectInfo[g_CurCells],32)
			}
			
			case STORE_IP : {
				
				get_user_ip(id,g_PlayerReconnectInfo[g_CurCells],32)
			}
		}
		
		//Set the time the user info will be automatically removed if user doesn't reconnect
		set_task(RECONNECT_TASK_TIME,"RemoveCell",_,g_PlayerReconnectInfo[g_CurCells],32)
		
		g_CurCells++
		
		//Force user to reconnect
		client_cmd(id,"reconnect")
	}
}

public RemoveCell(Data[]) {
	
	new i
	
	for(i = 0; i < g_CurCells; i++) {
		
		if(equal(Data,g_PlayerReconnectInfo[i])) {
			
			MoveCellsUp(i)
		}
	}
}
	

public client_disconnect(id) remove_task(id)

//Make a 1 second delay after user has joined the game to remove those connect messages
public client_putinserver(id) if(get_pcvar_num(c_OnOff) && !is_user_bot(id)) set_task(1.0,"ClearPlayerMessages",id)

public ClearPlayerMessages(id) {
	
	//Reset player cvars
	new i
	
	for(i = 1; i < 3; i++) client_cmd(id,"scr_connectmsg%d ^"^"",i)
	
	client_cmd(id,"scr_connectmsg ^"^"")
}

public CheckReconnect(id) {
	
	new SteamID_IP[33],i
	
	switch(get_pcvar_num(c_StoreType)) {
		
		case STORE_STEAM : {
			
			get_user_authid(id,SteamID_IP,32)
		}
		
		case STORE_IP : {
			
			get_user_ip(id,SteamID_IP,32)
		}
	}
	
	//Compare every info cell to player info. If it matches then return true and clean his info cell.
	for(i = 0; i < g_CurCells; i++) {
		
		if(equal(SteamID_IP,g_PlayerReconnectInfo[i])) {
			
			MoveCellsUp(i)
			
			return true
		}
	}
	
	//If no matching info was found - return false
	return false
}

public MoveCellsUp(Line) {

	new i
	
	for(i = Line; i < g_CurCells - 1; i++) {
		
		copy(g_PlayerReconnectInfo[i],191,g_PlayerReconnectInfo[i+1])
	}
	
	g_CurCells--
}
