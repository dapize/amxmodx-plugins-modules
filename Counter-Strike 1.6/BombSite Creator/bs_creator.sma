/*
R3X @ 2009
HomePage: http://amxx.pl

Description:
Plugin allow you add/delete/modifify bombsites on maps. All configuration files goes to:
amxmodx/configs/bs_creator/[MAPNAME].ini

Please do not edit these files manually!

Credits:
- Miczu and his m_eel.amxx (entities laboratory :D)
- Pavulon (help with decals)

*/
#include <amxmodx>
#include <amxmisc>
#include <engine>

#define PLUGIN "BS Creator"
#define VERSION "1.3"
#define AUTHOR "R3X"

//Main Constants
//If you change it it won`t work correctly
#define ENTITY_CLASS "func_bomb_target"
#define BS_PER_PAGE 5
#define ALL_KEYS (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
#define KeysEditBS (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<7)|(1<<8)|(1<<9) // Keys: 123456890

//Rest
#define MIN_SIZE 60.0
#define INTERVAL 5.0
#define SPACER "^n========="

#define LOG_SAVE 	1
#define LOG_EDIT 	2
#define LOG_ADD 	4
#define LOG_DELETE 	8
#define LOG_RESTORE 	16

#define TASK_RADAR 1
#define TASK_BOMBONRADAR_TIME 3.0
#define TASK_LOOK 2
#define TASK_UP_DECALS 3
#define TASK_SET_DECALS 4

new szDecalName[]="{target";

new Array:g_BS;
new Array:g_BSmaxs;
new Array:g_BSmins;
new Array:g_BSorigin;
new Array:g_BSDecalorigin;

new g_iDecal;

new g_spriteLine;

//stack problems, so i put it there
new g_szCfgFile[128];
new g_szConfig[128];

new gSelectedEnt[33];
new gSelectedOption[33];
new gSelectedOffset[33];

new bool:gSetDecal=true;

new g_BSLog=0;
new bool:g_BSMenu=false;

new m_fakeHostage
new m_fakeHostageDie

new gcvarShowPos;

new gbPlanted=false;
new gbWantBSonRadar[33];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("common.txt");
	register_dictionary("bs_creator.txt");
	if(g_BSMenu){
		register_clcmd("bs_menu","cmd_bs_menu", ADMIN_CFG, "BombSite Menu");
		register_concmd("bs_default", "cmd_bs_default",ADMIN_CFG, "Restore default BS");
		//Link to AmxModMenu
		server_cmd("amx_addmenuitem ^"BS Creator^" ^"bs_menu^" ^"hu^" ^"bs_creator.amxx^"");
	}
	m_fakeHostage = get_user_msgid("HostagePos");
	m_fakeHostageDie = get_user_msgid("HostageK");
	gcvarShowPos=register_cvar("amx_bs_draw","1");
	register_clcmd("bs_radar", "cmd_bs_radar");
	
	register_menucmd(register_menuid("EditBS"), KeysEditBS, "PressedEditBS")
	register_menucmd(register_menuid("BSMenu"), ALL_KEYS, "PressedBSMenu");
	register_event("HLTV", "eventInitRound", "a", "1=0", "2=0");
	register_event("ResetHUD","eventResetHUD","be");
	register_event("BombDrop","bomb_planted","a","4=1");
	set_task(TASK_BOMBONRADAR_TIME, "task_UpDateRadar",TASK_RADAR,_,_,"b");
}
public plugin_precache(){
	g_iDecal = get_decal_index (szDecalName);
	g_spriteLine=precache_model("sprites/dot.spr");
	bomb_cfg();
}
public bomb_cfg(){
	get_configsdir(g_szCfgFile, 75);
	formatex(g_szConfig, 127, "%s/bs_creator/bsconfig", g_szCfgFile);
	//Config
	if(file_exists(g_szConfig)){
		new szLine[64], iLen;
		new szFlags[10];
		for(new i=0;read_file(g_szConfig,i,szLine, 64,iLen);i++){
			trim(szLine);
			if(szLine[0]==';') continue;
			replace_all(szLine, 64, " ", "");
			new i=containi(szLine, "LOGS=");
			if(i>=0){
				copy(szFlags, 9, szLine[i+5]);
				g_BSLog = read_flags(szFlags);
				continue;
			}
			i=containi(szLine, "MENU=");
			if(i>=0){
				copy(szFlags, 9, szLine[i+5]);
				g_BSMenu=(str_to_num(szFlags)==1);
				continue;
			}	
		}
	}
	else{
		g_BSMenu=true;
		g_BSLog=LOG_SAVE|LOG_EDIT|LOG_ADD|LOG_RESTORE;
	}
	new szMapName[32];
	get_mapname(szMapName, 31);
	format(g_szCfgFile, 127, "%s/bs_creator/%s.ini", g_szCfgFile, szMapName);
	g_BS = ArrayCreate(1, 2);
	g_BSmaxs = ArrayCreate(3, 2);
	g_BSmins = ArrayCreate(3, 2);
	g_BSorigin = ArrayCreate(3, 2);
	g_BSDecalorigin = ArrayCreate(3, 2);
	
	//BombSites
	if(file_exists(g_szCfgFile)){
		remove_entity_name(ENTITY_CLASS);
		LoadFromFile();
	}
	else{
		set_task(1.0, "task_Look4BS", TASK_LOOK);
	}
	
}
//List of exists BS
public task_Look4BS(){
	new ent = -1;
	new Float:fMax[3], Float:fMin[3], Float:fOrigin[3];
	new Float:fMinS[3], Float:fMaxS[3];
	do{
		ent = find_ent_by_class ( ent, ENTITY_CLASS);
		if(is_valid_ent ( ent )){ 
			entity_get_vector(ent, EV_VEC_absmin, fMin);
			entity_get_vector(ent, EV_VEC_absmax, fMax);
			get_brush_entity_origin(ent, fOrigin);
			engine_get_size(fMax, fOrigin, fMinS, fMaxS);
			register_bombsite(ent, fMinS, fMaxS, fOrigin);
		}
	}
	while(ent);
}
//---------------
//BS
//---------------
stock engine_get_size(const Float:fMax[3], Float:fOrigin[3], Float:fMinS[3], Float:fMaxS[3]){
	//count Mins and Maxs
	for(new i=0;i<3;i++){
			fMaxS[i]=fMax[i]-fOrigin[i];
			fMinS[i]=fOrigin[i]-fMax[i];
	}
}
CreateBS(Float:fMin[3], Float:fMax[3], Float:fOrigin[3]){
	new bombtarget = create_entity(ENTITY_CLASS);
	if(bombtarget > 0)
	{
		DispatchKeyValue(bombtarget, "classname", ENTITY_CLASS);
		DispatchSpawn(bombtarget);
		entity_set_string(bombtarget, EV_SZ_classname, ENTITY_CLASS);
		entity_set_origin(bombtarget, fOrigin);
		entity_set_size(bombtarget, fMin, fMax);
		entity_set_edict(bombtarget, EV_ENT_owner, 0);
		entity_set_int(bombtarget, EV_INT_movetype, 0);
		entity_set_int(bombtarget, EV_INT_solid, SOLID_TRIGGER);
		entity_set_float(bombtarget,EV_FL_nextthink, halflife_time() + 0.01);
		set_task(5.0 ,"BS_set_decal", TASK_SET_DECALS+bombtarget);
		new ent=-1;
		new szTargetName[32];
		do{
			ent=find_ent_in_sphere( ent, fOrigin, 300.0);
			if(is_valid_ent(ent)){
				entity_get_string(ent, EV_SZ_classname,szTargetName,31);
				if(!equal(szTargetName, "func_breakable")) continue;
				if(entity_get_float(ent, EV_FL_dmg_take)==0.0){
					entity_get_string(ent, EV_SZ_targetname, szTargetName,31);
					if(szTargetName[0]){
						entity_set_string(bombtarget, EV_SZ_target, szTargetName);
						break;
					}
				}
			}
		}
		while(ent);
	}
	return bombtarget;
}
public BS_set_decal(ent){
	ent-=TASK_SET_DECALS;
	new Float:fOrigin[3];
	entity_get_vector(ent, EV_VEC_origin, fOrigin);
	new temp=create_entity("info_target");
	entity_set_origin(temp, fOrigin);
	entity_set_size(temp, Float:{0.0, 0.0, 0.0}, Float:{1.0, 1.0, 1.0});
	drop_to_floor(temp);
	entity_get_vector(temp, EV_VEC_origin, fOrigin);
	remove_entity(temp);
	for(new i=0;i<ArraySize(g_BS);i++){
		if(ArrayGetCell(g_BS, i)==ent){
			ArraySetArray(g_BSDecalorigin, i, fOrigin);
		}
	}
}
BSSetSize(id){
	new BS=gSelectedOption[id]-1;
	if(gSelectedEnt[id]){
		new Float:fMins[3], Float:fMaxs[3], Float:fOrigin[3];
		ArrayGetArray(g_BSmins, BS, fMins);
		ArrayGetArray(g_BSmaxs, BS, fMaxs);
		ArrayGetArray(g_BSorigin, BS, fOrigin);
		entity_set_size(gSelectedEnt[id], fMins, fMaxs);
		entity_set_vector(gSelectedEnt[id], EV_VEC_origin, fOrigin);
	}
}
register_bombsite(ent, Float:fMin[3], Float:fMax[3], Float:fOrigin[3]){
	ArrayPushCell(g_BS, ent);
	ArrayPushArray(g_BSmins, fMin);
	ArrayPushArray(g_BSmaxs, fMax);
	ArrayPushArray(g_BSorigin, fOrigin);
	ArrayPushArray(g_BSDecalorigin, Float:{0.0, 0.0, 0.0});
}
bool:is_too_small(Float:fMin[3], Float:fMax[3]){
	new Float:fSize[3];
	for(new i=0; i<3;i++)
		fSize[i]=fMax[i]-fMin[i];
	return bool:(fSize[0] < MIN_SIZE || fSize[1] < MIN_SIZE || fSize[2] < MIN_SIZE );
}
//---------------
//Events
//---------------
public eventInitRound(){
	gSetDecal=true;
	set_task(0.1, "setDecals");
	gbPlanted=false;
}
public eventResetHUD(id){
	if(!task_exists(TASK_UP_DECALS))
		set_task(3.0, "setDecals",TASK_UP_DECALS);
}
public client_putinserver(id){
	gbWantBSonRadar[id]=true;
}
public bomb_planted(planter){
	gbPlanted = true;
}
//---------------
//Menu
//---------------
needRestart(id){
	new szMsg[64];
	formatex(szMsg, 63, "* [BS Creator] %L", id, "NEED_RESTART");
	client_print(id, print_console, "%s",szMsg);
	client_print(id, print_chat, "%s",szMsg);
}
public cmd_bs_default(id, level, cid){
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	delete_file(g_szCfgFile);
	needRestart(id);
	log(id, LOG_RESTORE);
	return PLUGIN_HANDLED;
}
public cmd_bs_menu(id, level, cid){
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	new KeysBSMenu=(1<<7)|(1<<8)|(1<<9);
	new szBSMenu[188], iLen=0;
	iLen+=copy(szBSMenu[iLen], 187, "\yBombSite Menu^n");
	new iCount=ArraySize(g_BS);
	new iStart=gSelectedOffset[id], iStop=gSelectedOffset[id]+BS_PER_PAGE ;
	
	if(iStop > iCount)
		iStop=iCount;
	new iOff;
	for(new i=iStart;i<iStop;i++){
		iOff=i-gSelectedOffset[id];
		iLen+=formatex(szBSMenu[iLen], 187, "^n\w%d. BS#%d", iOff+1, i+1);
		KeysBSMenu|=(1<<iOff);
	}
	new bool:added=false;
	if(iStart>0){
		KeysBSMenu|=(1<<5);
		iLen+=formatex(szBSMenu[iLen], 187, "%s^n\w6. %L",(added)?"":SPACER, id, "BACK");
		added=true;
	}
	if(iStop < iCount){
		KeysBSMenu|=(1<<6);
		iLen+=formatex(szBSMenu[iLen], 187, "%s^n\w7. %L",(added)?"":SPACER, id, "MORE");
	}
	iLen+=formatex(szBSMenu[iLen], 187, "^n^n\w8. %L BombSite", id ,"WORD_ADD");
	iLen+=formatex(szBSMenu[iLen], 187, "^n\r9. \w%L",id,"BS_SAVE");
	iLen+=formatex(szBSMenu[iLen], 187, "^n^n\w0. %L", id, "EXIT");
	show_menu(id, KeysBSMenu, szBSMenu, -1, "BSMenu") // Display menu
	return PLUGIN_HANDLED;
}
public PressedBSMenu(id, key) {
	/* Menu:
	* BombSite Menu
	*/
	switch (key) {
		case 5:{
			gSelectedOffset[id]-=BS_PER_PAGE;
			client_cmd(id, "bs_menu");
			return;
		}
		case 6:{
			gSelectedOffset[id]+=BS_PER_PAGE;
			client_cmd(id, "bs_menu");
			return;
			
		}
		case 7: { // 8
			new Float:fMin[3]={-MIN_SIZE, -MIN_SIZE, -MIN_SIZE};
			new Float:fMax[3]={MIN_SIZE, MIN_SIZE, MIN_SIZE};
			new Float:fOrigin[3];
			entity_get_vector(id, EV_VEC_origin, fOrigin);
			new ent=CreateBS(fMin, fMax, fOrigin);
			register_bombsite(ent, fMin, fMax, fOrigin);
			gSelectedEnt[id]=ent;
			gSelectedOption[id]=ArraySize(g_BS);
			log(id, LOG_ADD);
			ShowEditBS(id);
			return;
		}
		case 8: { // 9
			SaveToFile(id);
			gSelectedOffset[id]=0;
			needRestart(id);
			log(id, LOG_SAVE);
			return;
		}
		case 9: { // 0
			gSelectedEnt[id]=0;
			gSelectedOption[id]=0;
			gSelectedOffset[id]=0;
			needRestart(id);
			return;
		}
	}
	key+=gSelectedOffset[id];
	if(key >= ArraySize(g_BS))
		return;
	new ent=ArrayGetCell(g_BS, key);
	gSelectedEnt[id]=ent;
	gSelectedOption[id]=key+1;
	ShowEditBS(id);
}
public ShowEditBS(id){
	if(gSelectedOption[id]==0)
		return;
	new BS=gSelectedOption[id];
	new szMenu[256], iLen=0;
	new szAxis[10],szMore[10], szLess[10];
	formatex(szAxis, 9 ,"%L",id ,"WORD_AXIS");
	formatex(szMore, 9 ,"%L",id ,"WORD_MORE");
	formatex(szLess, 9 ,"%L",id ,"WORD_LESS");
	iLen+=formatex(szMenu[iLen], 255, "\yBombSite#%d Edit^n^n\r%L (%s X)^n", BS, id, "WORD_WIDTH", szAxis);
	iLen+=formatex(szMenu[iLen], 255,"\w1. %s 2. %s^n^n\r",szMore, szLess);
	iLen+=formatex(szMenu[iLen], 255,"%L (%s Y)^n\w3. %s 4. %s^n^n",id,"WORD_LENGTH", szAxis, szMore, szLess);
	iLen+=formatex(szMenu[iLen], 255,"\r%L (%s Z)^n\w5. %s 6. %s^n^n",id,"WORD_HEIGHT", szAxis, szMore, szLess);
	iLen+=formatex(szMenu[iLen], 255,"\y8. %L BS^n^n\w9. %L^n0. %L^n", id, "WORD_DELETE", id, "WORD_RETURN", id, "EXIT");
	show_menu(id, KeysEditBS, szMenu, -1, "EditBS") // Display menu
}
public PressedEditBS(id, key) {
	/* Menu:
	* BombSite#2 Edit
	* 
	* Width (axis X)
	* 1. More 2. Less
	* 
	* Length (axis Y)
	* 3. More 4. Less
	* 
	* Height (axis Z)
	* 5. More 6. Less
	* 
	* 8. Delete BS
	* 
	* 9. Return
	* 0. Exit
	*/
	new BS=gSelectedOption[id]-1;
	new Float:fMins[3], Float:fMaxs[3], Float:fOrigin[3];
	ArrayGetArray(g_BSmins, BS, fMins);
	ArrayGetArray(g_BSmaxs, BS, fMaxs);
	ArrayGetArray(g_BSorigin, BS, fOrigin);
	switch (key) {
		case 0: { // 1
			fMins[0]-=INTERVAL;
			fMaxs[0]+=INTERVAL;
		}
		case 1: { // 2
			fMins[0]+=INTERVAL;
			fMaxs[0]-=INTERVAL;
		}
		case 2: { // 3
			fMins[1]-=INTERVAL;
			fMaxs[1]+=INTERVAL;
		}
		case 3: { // 4
			fMins[1]+=INTERVAL;
			fMaxs[1]-=INTERVAL;
		}
		case 4: { // 5
			fMaxs[2]+=INTERVAL;
			fMins[2]-=INTERVAL;
			fOrigin[2]+=INTERVAL;
		}
		case 5: { // 6
			fMaxs[2]-=INTERVAL;
			fMins[2]+=INTERVAL;
			fOrigin[2]-=INTERVAL;
		}
		case 7: { // 8
			//DELETE BS
			new BS=gSelectedOption[id]-1;
			gSelectedOption[id]=0;
			gSelectedEnt[id]=0;
			gSelectedOffset[id]=0;
			ArrayDeleteItem(g_BS, BS);
			ArrayDeleteItem(g_BSmaxs, BS);
			ArrayDeleteItem(g_BSmins, BS);
			ArrayDeleteItem(g_BSorigin, BS);
			log(id, LOG_DELETE);
			client_cmd(id, "bs_menu");
			return;
		}
		case 8: { // 9
			gSelectedOption[id]=0;
			gSelectedEnt[id]=0;
			client_cmd(id, "bs_menu");
			log(id, LOG_EDIT);
			return;
		}
		case 9: { // 0
			gSelectedEnt[id]=0;
			gSelectedOption[id]=0;
			gSelectedOffset[id]=0;
			return;
		}
	}
	
	if(!is_too_small(fMins, fMaxs)){
		ArraySetArray(g_BSmins, BS, fMins);
		ArraySetArray(g_BSmaxs, BS, fMaxs);
		ArraySetArray(g_BSorigin, BS, fOrigin);
		BSSetSize(id);
	}
	ShowEditBS(id);
}

//---------------
//ToFile
//---------------
SaveToFile(id){
	if(file_exists(g_szCfgFile))
		delete_file(g_szCfgFile);
	new iVector[3];
	new szLine[128];
	if(ArraySize(g_BS)==0){
		new fp=fopen(g_szCfgFile, "w");
		fclose(fp);
	}
	else
	for(new i=0;i<ArraySize(g_BS);i++){
		ArrayGetArray(g_BSmins, i, iVector);
		formatex(szLine, 63, "%.0f %.0f %.0f", iVector[0],iVector[1],iVector[2]);
		ArrayGetArray(g_BSmaxs, i, iVector);
		format(szLine, 127, "%s %.0f %.0f %.0f", szLine, iVector[0],iVector[1],iVector[2]);
		ArrayGetArray(g_BSorigin, i, iVector);
		format(szLine, 127, "%s %.0f %.0f %.0f", szLine, iVector[0],iVector[1],iVector[2]);
		write_file(g_szCfgFile, szLine);
	}
	client_print(id, print_center, "%L",id,"BS_SAVED");
}
LoadFromFile(){
	new szLine[64], iLen;
	new szMin[3][10], szMax[3][10], szOrigin[3][10];
	new Float:fMin[3], Float:fMax[3], Float:fOrigin[3];
	for(new i=0;read_file(g_szCfgFile,i,szLine, 64,iLen);i++){
		trim(szLine);
		if(szLine[0]==';') continue;
		parse(szLine, szMin[0], 9,szMin[1], 9, szMin[2], 9, szMax[0], 9, szMax[1], 9, szMax[2], 9, szOrigin[0], 9,szOrigin[1], 9, szOrigin[2], 9);
		for(new j=0;j<3;j++){
			fMin[j]=str_to_float(szMin[j]);
			fMax[j]=str_to_float(szMax[j]);
			fOrigin[j]=str_to_float(szOrigin[j]);
		}
		new ent=CreateBS(fMin, fMax, fOrigin);
		if(ent!=-1){
			register_bombsite(ent, fMin, fMax, fOrigin);
		}	
	}
}
//---------------
//Box
//---------------
public client_PreThink(id){
	if(gSelectedEnt[id])
		Create_Box(id, gSelectedEnt[id]);
}
public Create_Box(id, ent){
	if( !is_user_connected(id) || !is_valid_ent(ent)) return;
	new Float:fMins[3], Float:fMaxs[3];
	entity_get_vector(ent, EV_VEC_absmin,fMins);
	entity_get_vector(ent, EV_VEC_absmax,fMaxs);
	new iMins[3], iMaxs[3];
	for(new i=0;i<3;i++){
		iMins[i]=floatround(fMins[i]);
		iMaxs[i]=floatround(fMaxs[i]);
	}
	DrawLine(id,iMaxs[0], iMaxs[1], iMaxs[2], iMins[0], iMaxs[1], iMaxs[2]);
	DrawLine(id,iMaxs[0], iMaxs[1], iMaxs[2], iMaxs[0], iMins[1], iMaxs[2]);
	DrawLine(id,iMaxs[0], iMaxs[1], iMaxs[2], iMaxs[0], iMaxs[1], iMins[2]);

	DrawLine(id,iMins[0], iMins[1], iMins[2], iMaxs[0], iMins[1], iMins[2]);
	DrawLine(id,iMins[0], iMins[1], iMins[2], iMins[0], iMaxs[1], iMins[2]);
	DrawLine(id,iMins[0], iMins[1], iMins[2], iMins[0], iMins[1], iMaxs[2]);

	DrawLine(id,iMins[0], iMaxs[1], iMaxs[2], iMins[0], iMaxs[1], iMins[2]);
	DrawLine(id,iMins[0], iMaxs[1], iMins[2], iMaxs[0], iMaxs[1], iMins[2]);
	DrawLine(id,iMaxs[0], iMaxs[1], iMins[2], iMaxs[0], iMins[1], iMins[2]);
	
	DrawLine(id,iMaxs[0], iMins[1], iMins[2], iMaxs[0], iMins[1], iMaxs[2]);
	DrawLine(id,iMaxs[0], iMins[1], iMaxs[2], iMins[0], iMins[1], iMaxs[2]);
	DrawLine(id,iMins[0], iMins[1], iMaxs[2], iMins[0], iMaxs[1], iMaxs[2]);
}
public DrawLine(id,x1, y1, z1, x2, y2, z2) 
{
	new start[3];
	new stop[3];
	
	start[0]=(x1);
	start[1]=(y1);
	start[2]=(z1);
	
	stop[0]=(x2);
	stop[1]=(y2);
	stop[2]=(z2);

	Create_Line(id,start, stop);
}
public Create_Line(id,start[],stop[]){
	message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},id);
	write_byte(0);
	write_coord(start[0]);
	write_coord(start[1]);
	write_coord(start[2]);
	write_coord(stop[0]);
	write_coord(stop[1]);
	write_coord(stop[2]);
	write_short(g_spriteLine);
	write_byte(1);
	write_byte(5);
	write_byte(1);//lifetime
	write_byte(3);
	write_byte(0);
	write_byte(255);	// RED
	write_byte(0);	// GREEN
	write_byte(0);	// BLUE					
	write_byte(250);	// brightness
	write_byte(5);
	message_end();
}
//---------------
//Radar
//---------------
public cmd_bs_radar(id){
	gbWantBSonRadar[id]=!gbWantBSonRadar[id];
	client_print(id, print_center, "BS Radar: %s", gbWantBSonRadar[id]?"On":"Off");
	return PLUGIN_HANDLED;
}
public showOnRadar(id, i) 
{
	if(m_fakeHostage && m_fakeHostageDie)	//only 0 is false
	{
		new ent=ArrayGetCell(g_BS, i);
		new Float: ori_min[3]
		new Float: ori_max[3]	
		
		entity_get_vector(ent,EV_VEC_absmin,ori_min)
		entity_get_vector(ent,EV_VEC_absmax,ori_max)	
		
		message_begin(MSG_ONE_UNRELIABLE, m_fakeHostage, {0,0,0}, id);
		write_byte(id);
		write_byte(i+20);
		write_coord(floatround((ori_max[0]+ori_min[0])/2));
		write_coord(floatround((ori_max[1]+ori_min[1])/2));
		write_coord(floatround((ori_max[2]+ori_min[2])/2));
		message_end();
	
		message_begin(MSG_ONE_UNRELIABLE, m_fakeHostageDie, {0,0,0}, id);
		write_byte(i+20);
		message_end();
	}
}
public task_UpDateRadar(){
	if(get_pcvar_num(gcvarShowPos)==0) return;
	new Players[32];
	new playerCount, id;
	get_players(Players, playerCount);
	for ( new i=0; i<playerCount; i++){
		id = Players[i];
		if(get_user_team(id)==1 && gbPlanted) continue;
		if(is_user_alive(id) && gbWantBSonRadar[id])
			UpDate_Radar(id);
	}
	
}
public UpDate_Radar(id){
	if(id>TASK_RADAR)
		id-=TASK_RADAR;
	if(!is_user_connected(id)) return;
	for(new i=0; i<ArraySize(g_BSorigin); i++){
		showOnRadar(id, i);
	}
}
//---------------
//Decal
//---------------
// Wrapper for TE_WORLDDECAL message.
DrawDecal( Float:fOrigin[3], tid ){
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
    write_byte( tid <= 256 ? TE_WORLDDECAL : TE_WORLDDECALHIGH );
    write_coord(  floatround( fOrigin[0]) );
    write_coord(  floatround( fOrigin[1]) );
    write_coord(  floatround( fOrigin[2]) );
    write_byte( tid <= 256 ? tid : tid - 256 );
    message_end();
}
public setDecals(){
	if(!gSetDecal) return;
	new Float:fOrigin[3];
	for(new i=0; i<ArraySize(g_BSDecalorigin); i++){
		ArrayGetArray(g_BSDecalorigin,i,fOrigin);
		if(fOrigin[0]!=0.0 && fOrigin[1]!=0.0 && fOrigin[2]!=0.0){
			DrawDecal(fOrigin, g_iDecal);
		}
	}
	gSetDecal=false;
}
//---------------
//LOGS
//---------------
log(id, LOG_FLAG){
	if((g_BSLog&LOG_FLAG)==0) return;
	new szName[33];
	get_user_name(id, szName, 32);
	switch(LOG_FLAG){
		case LOG_SAVE:{
			log_amx("Admin %s saved map BombSites to file", szName);
		}
		case LOG_EDIT:{
			log_amx("Admin %s edited map BombSite", szName);
		}
		case LOG_ADD:{
			log_amx("Admin %s added map BombSite", szName);
		}
		case LOG_DELETE:{
			log_amx("Admin %s deleted map BombSite", szName);
		}
		case LOG_RESTORE:{
			log_amx("Admin %s restored original map BombSites", szName);
		}
	}
}
