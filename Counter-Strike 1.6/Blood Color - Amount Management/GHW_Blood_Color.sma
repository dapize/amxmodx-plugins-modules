/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 07-04-09
*
*  ============
*   Changelog:
*  ============
*
*  v2.0
*    -Changed blood_amount to blood_gore
*    -Added arkshine's HAM method of changing blood color
*    -Changed how gore sprites are sent
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"2.0"

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>

#define TE_BLOODSPRITE		115

new blood
new blood_gore
new blood_color

public plugin_init()
{
	register_plugin("Blood Color/Amount Management",VERSION,"GHW_Chronic")
	register_event("Damage","Damage","3=DMG_BULLET")
	register_concmd("amx_bloodcolors","cmdbc")
	blood_gore = register_cvar("blood_gore","1")
	blood_color = register_cvar("blood_color","229")
	RegisterHam(Ham_BloodColor,"player","Hook_BloodColor")
}

public plugin_precache()
{
	blood = precache_model("sprites/blood.spr")
}

public Hook_BloodColor(id)
{
	SetHamReturnInteger(get_pcvar_num(blood_color))
	return HAM_SUPERCEDE;
}

public Damage(id)
{
	if(is_user_connected(id) && get_user_health(id)!=100 && get_pcvar_num(blood_gore))
	{
		new origin[3]
		get_user_origin(id,origin)
		new hitpoint, weapon
		get_user_attacker(id,weapon,hitpoint)
		switch(hitpoint)
		{
			case 1:
			{
				get_user_origin(id,origin,1)
			}
			case 2:
			{
				origin[2] += 25
			}
			case 3:
			{
				origin[2] += 10
			}
			case 4:
			{
				origin[2] += 10
				origin[0] += 5
				origin[1] += 5
			}
			case 5:
			{
				origin[2] += 10
				origin[0] -= 5
				origin[1] -= 5
			}
			case 6:
			{
				origin[2] -= 10
				origin[0] += 5
				origin[1] += 5
			}
			case 7:
			{
				origin[2] -= 10
				origin[0] -= 5
				origin[1] -= 5
			}
		}
		if(get_pcvar_num(blood_gore))
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2])
			write_short(blood)
			write_short(blood)
			write_byte(get_pcvar_num(blood_color))
			write_byte(10)
			message_end()
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2])
			write_short(blood)
			write_short(blood)
			write_byte(get_pcvar_num(blood_color))
			write_byte(12)
			message_end()
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2])
			write_short(blood)
			write_short(blood)
			write_byte(get_pcvar_num(blood_color))
			write_byte(15)
			message_end()
		}
	}
}

public cmdbc(id)
{
	show_motd(id,"<body bgcolor=black><center><font color=white><B>Note: Only colors after 127 work!</B><BR><BR><img src=^"http://forums.alliedmods.net/attachment.php?attachmentid=5979&d=1146477307^"></font></center></body>","Colors")
	return PLUGIN_HANDLED
}
