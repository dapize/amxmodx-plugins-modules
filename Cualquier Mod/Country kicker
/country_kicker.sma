/* Country kicker

About:
This plugin is used if you only want ppl from spesfic countrys on your server, or wanna prevent ppl from a spesfic countrys from entering

Forum topic: http://www.amxmodx.org/forums/viewtopic.php?t=12063

Modules required: geoip

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicker & CheesyPeteza ) 
xeroblood Explode string func

Setting up plugin:
sv_country 
 1 Only allow ppl from this country  
 2 Everyone exect from this country

sv_country_name use commas to seperate country names
like:
sv_country_name "NOR,DEN"

Changelog
1.0.0( 18.12.2004 )
	- First public release
*/ 

#include <amxmodx> 
#include <geoip>

#define MAX_COUNTRYS 15

new g_Mode
new g_CC[MAX_COUNTRYS+1][4]
new g_Countries
new CountyList[128]

public plugin_init()
{ 
	register_plugin("Country kicker","1.0.0","EKS")
	register_cvar("sv_country_name","NOR,DEN")
	register_cvar("sv_country","1")
}

public plugin_cfg()
{
	g_Mode = get_cvar_num("sv_country")
	
	new CvarInfo[MAX_COUNTRYS*3+MAX_COUNTRYS+2]
	get_cvar_string("sv_country_name",CvarInfo,MAX_COUNTRYS*3+MAX_COUNTRYS+2)
	
	g_Countries = ExplodeString( g_CC, MAX_COUNTRYS, 3, CvarInfo, ',' )
	
	for(new i=0;i<=g_Countries;i++)
		format(CountyList,127,"%s %s",CountyList,g_CC[i])
}
stock ExplodeString( p_szOutput[][], p_nMax, p_nSize, p_szInput[], p_szDelimiter ) 
{ 
    new nIdx = 0, l = strlen(p_szInput) 
    new nLen = (1 + copyc( p_szOutput[nIdx], p_nSize, p_szInput, p_szDelimiter )) 
    while( (nLen < l) && (++nIdx < p_nMax) ) 
        nLen += (1 + copyc( p_szOutput[nIdx], p_nSize, p_szInput[nLen], p_szDelimiter )) 
    return nIdx
} 
stock IsConInArray(Con[4])
{
	for(new i=0;i<=g_Countries;i++)
	{
		if(equal(Con,g_CC[i]))
			return 1
	}
	return 0
}
stock IsLocalIp(IP[32])
{
	new tIP[32]
	
	copy(tIP,3,IP)
	if(equal(tIP,"10.") || equal(tIP,"127"))
		return 1
	copy(tIP,7,IP)
	if(equal(tIP,"192.168"))
		return 1

	return 0
}
public client_connect(id)
{
	new userip[32]
	new CC[4]
	get_user_ip(id,userip,31,1)

	geoip_code3(userip,CC)
	if(strlen(userip) == 0)
	{
		get_user_ip(id,userip,31,1)		
		if(!IsLocalIp(userip))
			log_amx("%s made a error when passed though geoip",userip)
		return PLUGIN_HANDLED
	}
	
	if(g_Mode == 1 && !IsConInArray(CC))
	{
		server_cmd("kick #%d Only ppl from %s are allowed",get_user_userid(id),CountyList)
		
		new Name[32]
		get_user_name(id,Name,31)
		client_print(0,print_chat,"%s was kicked because he is not from %s",Name,CountyList)
	}
	else if(g_Mode == 2 && IsConInArray(CC))
	{
		server_cmd("kick #%d No %s are allowed on this server",get_user_userid(id),CC)
		
		new Name[32]
		get_user_name(id,Name,31)
		client_print(0,print_chat,"%s was kicked because he is from %s",Name,CC)
	}
	return PLUGIN_HANDLED
}