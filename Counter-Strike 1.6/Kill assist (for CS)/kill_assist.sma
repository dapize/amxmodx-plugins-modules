/* --------------------------------------------------------------------------
	Kill assist (for CS) v1.2b
	  by Digi (a.k.a. Hunter-Digital)
	    www.thehunters.ro
	      -----------------------------------------------------------------

	Description:

	  When a player gets killed, this plugin checks if another player, from the same team,
	  did enough damage to the victim so that he could be an accomplice to the kill and
	  the assister will also receive a frag
	  (all of these are cvar controlled)


	CVars and default values:

	  - amx_killassist_enable 0/1/2 (default: 1)
	    Enable modes: 0 = Disable / 1 = Enable with DeathMsg / 2 = Enable with HUD message

	  - amx_killassist_mindamage 1-9999 (default: 50)
	    Minimum amount of damage to deal to be nominated for an assisted kill

	  - amx_killassist_givefrags 0/1 (default: 1)
	    Give or not give the assister frags

	  - amx_killassist_givemoney 0-16000 (default: 300)
	    Give or not give the assister some money, 0 disables, 1 or more sets how much money

	  - amx_killassist_onlyalive 0/1 (default: 0)
	    Only alive players can be of assistance in killing other players


	Credits and thanks:

	  - ConnorMcLeod - for helping with quick name changing
	  - arkshine - for helping with name squeeze
	  - joaquimandrade - code improvements
	  - anakin_cstrike - code improvements
	  - Nextra - more code improvements
	  - ajvn - some ideas
	  - Dores - and more code improvements
	  - frearmer - hud message sugestion


	Changelog:

	  v1.2b - modified public variable to "killassist_version" and fixed deathmsg not showing when you suicide with worldspawn or an entity
	  v1.2 - added no-name-changing support, prints HUD message, to activate, set enabled to 2
	  v1.1b - simplified cvar checking using clamp()
	  v1.1 - converted to CS only, new cvars: amx_killassist_onlyalive, amx_killassist_givemoney, enriched cvar handling, added team cache and fixed some bugs
	  v1.0d - Removed useless stuff xD, added pcvar on amx_mode and used formatex()
	  v1.0c - Some modifications and added g_bOnline
	  v1.0b - Fixed admin name bug
	  v1.0 - Release

		-------------------------------------------------------------- */

/* Feel free to modify these HUD message values */

#define HUD_colorR		255	// default: 255
#define HUD_colorG		155	// default: 155
#define HUD_colorB		0	// default: 0
#define HUD_posX			0.6	// default: 0.6
#define HUD_posY			0.2	// default: 0.2
#define HUD_fx			0	// default: 0
#define HUD_fxTime		0.0	// default: 0.0
#define HUD_holdTime		1.0	// default: 1.0
#define HUD_fadeInTime		0.3	// default: 0.3
#define HUD_fadeOutTime		2.0	// default: 2.0
#define HUD_channel		-1	// default: -1

/* -------------------------------------------------------------------------
	Nothing to edit below this point */

#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <fun>

#define PLUGIN_TITLE		"Kill assist (for CS)"
#define PLUGIN_VERSION		"1.2b"
#define PLUGIN_AUTHOR		"Digi (www.thehunters.ro)"
#define PLUGIN_PUBLICVAR	"killassist_version"

#define MAXPLAYERS		32 + 1

#define TEAM_NONE			0
#define TEAM_TE			1
#define TEAM_CT			2
#define TEAM_SPEC			3

#define is_player(%1) (1 <= %1 <= g_iMaxPlayers)

new msgID_sayText
new msgID_deathMsg
new msgID_scoreInfo
new msgID_money

new pCVar_amxMode

new pCVar_enabled
new pCVar_minDamage
new pCVar_giveFrags
new pCVar_giveMoney
new pCVar_onlyAlive

new ch_pCVar_enabled
new ch_pCVar_minDamage
new ch_pCVar_giveFrags
new ch_pCVar_giveMoney
new ch_pCVar_onlyAlive

new g_szName[MAXPLAYERS][32]
new g_iTeam[MAXPLAYERS]
new g_iDamage[MAXPLAYERS][MAXPLAYERS]
new bool:g_bAlive[MAXPLAYERS] = {false, ...}
new bool:g_bOnline[MAXPLAYERS] = {false, ...}

new g_iLastAmxMode
new g_iMaxPlayers = 0
new bool:g_bAmxModeExists = false

public plugin_init()
{
	register_plugin(PLUGIN_TITLE, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_PUBLICVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	pCVar_enabled = register_cvar("amx_killassist_enabled", "1")
	pCVar_minDamage = register_cvar("amx_killassist_mindamage", "50")
	pCVar_giveFrags = register_cvar("amx_killassist_givefrags", "1")
	pCVar_giveMoney = register_cvar("amx_killassist_givemoney", "300")
	pCVar_onlyAlive = register_cvar("amx_killassist_onlyalive", "0")

	if(cvar_exists("amx_mode"))
	{
		pCVar_amxMode = get_cvar_pointer("amx_mode")

		g_bAmxModeExists = true
	}

	msgID_money = get_user_msgid("Money")
	msgID_sayText = get_user_msgid("SayText")
	msgID_deathMsg = get_user_msgid("DeathMsg")
	msgID_scoreInfo = get_user_msgid("ScoreInfo")

	register_message(msgID_deathMsg, "msg_deathMsg")

	register_logevent("event_roundStart", 2, "1=Round_Start")

	register_event("Damage", "player_damage", "be", "2!0", "3=0", "4!0")
	register_event("DeathMsg", "player_die", "ae")
	register_event("TeamInfo", "player_joinTeam", "a")

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)

	g_iMaxPlayers = get_maxplayers()
}

public plugin_cfg() event_roundStart()

public event_roundStart()
{
	ch_pCVar_enabled = clamp(get_pcvar_num(pCVar_enabled), 0, 2)
	ch_pCVar_minDamage = clamp(get_pcvar_num(pCVar_minDamage), 0, 9999)
	ch_pCVar_giveFrags = clamp(get_pcvar_num(pCVar_giveFrags), 0, 1)
	ch_pCVar_giveMoney = clamp(get_pcvar_num(pCVar_giveMoney), 0, 16000)
	ch_pCVar_onlyAlive = clamp(get_pcvar_num(pCVar_onlyAlive), 0, 1)
}

public client_putinserver(iPlayer)
{
	g_bOnline[iPlayer] = true

	get_user_name(iPlayer, g_szName[iPlayer], 31)
}

public client_disconnect(iPlayer)
{
	g_iTeam[iPlayer] = TEAM_NONE
	g_bAlive[iPlayer] = false
	g_bOnline[iPlayer] = false
}

public player_joinTeam()
{
	new iPlayer, szTeam[2]

	iPlayer = read_data(1)
	read_data(2, szTeam, 1)

	switch(szTeam[0])
	{
		case 'T': g_iTeam[iPlayer] = TEAM_TE
		case 'C': g_iTeam[iPlayer] = TEAM_CT
		default: g_iTeam[iPlayer] = TEAM_SPEC // since you can't transfer yourself to unassigned team...
	}

	return PLUGIN_CONTINUE
}

public player_spawn(iPlayer)
{
	if(!is_user_alive(iPlayer))
		return HAM_IGNORED

	g_bAlive[iPlayer] = true // he's alive !

	new szName[32]

	get_user_name(iPlayer, szName, 31)

	if(!equali(szName, g_szName[iPlayer])) // make sure he has his name !
	{
		set_msg_block(msgID_sayText, BLOCK_ONCE)
		set_user_info(iPlayer, "name", g_szName[iPlayer])
	}

	// reset damage meters

	for(new p = 1; p <= g_iMaxPlayers; p++)
		g_iDamage[iPlayer][p] = 0

	return HAM_IGNORED
}

public player_damage(iVictim)
{
	if(!ch_pCVar_enabled || !is_player(iVictim))
		return PLUGIN_CONTINUE

	new iAttacker = get_user_attacker(iVictim)

	if(!is_player(iAttacker))
		return PLUGIN_CONTINUE

	g_iDamage[iAttacker][iVictim] += read_data(2)

	return PLUGIN_CONTINUE
}

public player_die()
{
	if(!ch_pCVar_enabled)
		return PLUGIN_CONTINUE

	new iVictim = read_data(2)
	new iKiller = read_data(1)
	new iHS = read_data(3)
	new szWeapon[24]
	read_data(4, szWeapon, 23)

	if(!is_player(iVictim))
	{
		do_deathmsg(iKiller, iVictim, iHS, szWeapon)

		return PLUGIN_CONTINUE
	}

	g_bAlive[iVictim] = false

	if(!is_player(iKiller))
	{
		do_deathmsg(iKiller, iVictim, iHS, szWeapon)

		return PLUGIN_CONTINUE
	}

	new iKillerTeam = g_iTeam[iKiller]

	if(iKiller != iVictim && g_iTeam[iVictim] != iKillerTeam)
	{
		new iKiller2 = 0
		new iDamage2 = 0

		for(new p = 1; p <= g_iMaxPlayers; p++)
		{
			if(p != iKiller && g_bOnline[p] && (ch_pCVar_onlyAlive && g_bAlive[p] || !ch_pCVar_onlyAlive) && iKillerTeam == g_iTeam[p] && g_iDamage[p][iVictim] >= ch_pCVar_minDamage && g_iDamage[p][iVictim] > iDamage2)
			{
				iKiller2 = p
				iDamage2 = g_iDamage[p][iVictim]
			}

			g_iDamage[p][iVictim] = 0
		}

		if(iKiller2 > 0 && iDamage2 > ch_pCVar_minDamage)
		{
			if(ch_pCVar_giveFrags)
			{
				new iFrags = get_user_frags(iKiller2)+1

				set_user_frags(iKiller2, iFrags)

				message_begin(MSG_ALL, msgID_scoreInfo)
				write_byte(iKiller2)
				write_short(iFrags)
				write_short(get_user_deaths(iKiller2))
				write_short(0)
				write_short(iKillerTeam)
				message_end()
			}

			if(ch_pCVar_giveMoney)
			{
				new iMoney = cs_get_user_money(iKiller2) + ch_pCVar_giveMoney

				if(iMoney > 16000)
					iMoney = 16000

				cs_set_user_money(iKiller2, iMoney)

				if(g_bAlive[iKiller2]) // no reason to send a money message when the player has no hud :}
				{
					message_begin(MSG_ONE_UNRELIABLE, msgID_money, _, iKiller2)
					write_long(iMoney)
					write_byte(1)
					message_end()
				}
			}

			if(ch_pCVar_enabled == 2)
			{
				new szName1[32], szName2[32], szName3[32], szMsg[128]

				get_user_name(iKiller, szName1, 31)
				get_user_name(iKiller2, szName2, 31)
 				get_user_name(iVictim, szName3, 31)

				formatex(szMsg, 63, "%s killed %s assisted by %s", szName1, szName3, szName2)

				set_hudmessage(HUD_colorR, HUD_colorG, HUD_colorB, HUD_posX, HUD_posY, HUD_fx, HUD_fxTime, HUD_holdTime, HUD_fadeInTime, HUD_fadeOutTime, HUD_channel)
				show_hudmessage(0, szMsg)
			}
			else
			{
				new szName1[32], iName1Len, szName2[32], iName2Len, szNames[32], szWeaponLong[32]

				iName1Len = get_user_name(iKiller, szName1, 31)
				iName2Len = get_user_name(iKiller2, szName2, 31)
 
				g_szName[iKiller] = szName1

				if(iName1Len < 14)
				{
					formatex(szName1, iName1Len, "%s", szName1)
					formatex(szName2, 28-iName1Len, "%s", szName2)
				}
				else if(iName2Len < 14)
				{
					formatex(szName1, 28-iName2Len, "%s", szName1)
					formatex(szName2, iName2Len, "%s", szName2)
				}
				else
				{
					formatex(szName1, 13, "%s", szName1)
					formatex(szName2, 13, "%s", szName2)
				}

				formatex(szNames, 31, "%s + %s", szName1, szName2)

				set_msg_block(msgID_sayText, BLOCK_ONCE)
				set_user_info(iKiller, "name", szNames)

				if(g_bAmxModeExists)
				{
					g_iLastAmxMode = get_pcvar_num(pCVar_amxMode)

					set_pcvar_num(pCVar_amxMode, 0)
				}

				if(equali(szWeapon, "grenade"))
					szWeaponLong = "weapon_hegrenade"
				else
					formatex(szWeaponLong, 31, "weapon_%s", szWeapon)

				new args[4]

				args[0] = iVictim
				args[1] = iKiller
				args[2] = iHS
				args[3] = get_weaponid(szWeaponLong)

				set_task(0.1, "player_diePost", 0, args, 4)
			}
		}
		else if(ch_pCVar_enabled == 1)
			do_deathmsg(iKiller, iVictim, iHS, szWeapon)
	}
	else if(ch_pCVar_enabled == 1)
		do_deathmsg(iVictim, iVictim, iHS, szWeapon)

	return PLUGIN_CONTINUE
}

public player_diePost(arg[])
{
	new szWeapon[24]
	new iKiller = arg[1]

	get_weaponname(arg[3], szWeapon, 23)
	replace(szWeapon, 23, "weapon_", "")

	do_deathmsg(iKiller, arg[0], arg[2], szWeapon)

	set_msg_block(msgID_sayText, BLOCK_ONCE)
	set_user_info(iKiller, "name", g_szName[iKiller])

	if(g_bAmxModeExists)
		set_pcvar_num(pCVar_amxMode, g_iLastAmxMode)

	return PLUGIN_CONTINUE
}

public msg_deathMsg()
	return ch_pCVar_enabled == 1 ? PLUGIN_HANDLED : PLUGIN_CONTINUE

/* originally from messages_stocks.inc, but simplified */

stock do_deathmsg(iKiller, iVictim, iHS, const szWeapon[])
{
	message_begin(MSG_ALL, msgID_deathMsg)
	write_byte(iKiller)
	write_byte(iVictim)
	write_byte(iHS)
	write_string(szWeapon)
	message_end()
}

/* --------------------------------------------------------------------------
	EOF
		-------------------------------------------------------------- */