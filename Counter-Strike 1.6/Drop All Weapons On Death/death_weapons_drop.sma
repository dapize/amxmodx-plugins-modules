/*	Formatleft © 2012, ConnorMcLeod

	Drop All Weapons On Death is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Drop All Weapons On Death; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

/*
	a 	p228
	b	scout
	c 	hegrenade
	d 	xm1014	
	e 	mac10
	f 	aug
	g 	smokegrenade
	h 	elite
	i 	fiveseven
	j 	ump45
	k	sg550
	l 	galil
	m 	famas
	n 	usp
	o 	glock18
	p	awp
	q 	mp5navy
	r 	m249
	s 	m3
	t 	m4a1
	u 	tmp
	v	g3sg1
	w 	flashbang
	x 	deagle
	x 	sg552
	z	ak47
	{ 	p90
	|	defuser
*/

#include < amxmodx >
#include < amxmisc >
#include < fakemeta >
#include < hamsandwich >

#pragma semicolon 1

#define VERSION "0.4.0"

const MAX_ITEM_TYPES = 6;	// hud item selection slots
const MAX_AMMO_SLOTS = 15;	// not really slots // MAX_AMMO_SLOTS // don't need to set a 32 array since max ammo index is 14

const INT_BYTES = 4;
const BYTE_BITS = 8;

// "weapon_..." offsets
const XO_CBASEPLAYERITEM = 4;
// CBasePlayerItem
const m_pPlayer = 41;
const m_pNext = 42;
const m_iId = 43;

// "player" offsets
// Store only slots 1,2 and 4 values cause we won't drop knife and let the game drop c4
// new const m_rgpPlayerItems_plr[] = {368, 369, 371}
new  const m_rgpPlayerItems_CBasePlayer[6] = { 367 , 368 , ... };
const m_pActiveItem = 373;
new const m_rgAmmo_CBasePlayer[MAX_AMMO_SLOTS] = {376,377,...};

const m_bHasDefuser = 774;

// "weaponbox" offsets
const XO_CWEAPONBOX = 4;
new const m_rgpPlayerItems_CWeaponBox[MAX_ITEM_TYPES] = { 34 , 35 , ... };
new const m_rgiszAmmo[32] = { 40 , 41 , ... };
new const m_rgAmmo_CWeaponBox[32] = { 72 , 73 , ... };
const m_cAmmoTypes = 104;

new const g_iMaxAmmo[] = {
	0, 30, 90, 200, 90,
	32, 100, 100, 35, 52,
	120, 2, 1, 1, 1
};

new const g_szOnCBasePlayer_Killed[] = "OnCBasePlayer_Killed";
new const weaponbox[] = "weaponbox";
new iszWeaponBox;

const NADES_BS = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE);

new g_iszAmmoNames[sizeof(g_iMaxAmmo)];

new g_iNoSilPluginId, g_iNoSilSetModel;

new m_usResetDecals, g_iFhPlaybackEventPost;

new g_iFhSetClientKeyValueP;

new g_iFlags;

new gmsgStatusIcon;

public plugin_init()
{
	register_plugin("Drop All Weapons On Death", VERSION, "ConnorMcLeod");

	register_event("HLTV", "Event_HLTV_New_Round", "a", "1=0", "2=0");

	RegisterHam(Ham_Killed, "player", g_szOnCBasePlayer_Killed);
	new modname[7];
	get_modname(modname, charsmax(modname));
	if( equal(modname, "czero") )
	{
		g_iFhSetClientKeyValueP = register_forward(FM_SetClientKeyValue, "OnSetClientKeyValue_P", true);
	}

	new const szAmmoNames[][] = {
		"", "338Magnum", "762Nato", "556NatoBox", "556Nato",
		"buckshot", "45ACP", "57mm", "50AE", "357SIG",
		"9mm", "Flashbang", "HEGrenade", "SmokeGrenade", "C4"
	};

	for(new i=1; i<sizeof(szAmmoNames); i++)
	{
		g_iszAmmoNames[i] = engfunc(EngFunc_AllocString, szAmmoNames[i]);
	}

	iszWeaponBox = engfunc(EngFunc_AllocString, weaponbox);

	m_usResetDecals = engfunc(EngFunc_PrecacheEvent, 1, "events/decal_reset.sc");

	gmsgStatusIcon = get_user_msgid("StatusIcon");

	register_concmd("death_drop_rules", "ConCmd_Rules", ADMIN_CFG, " - <flags>");
}

public plugin_cfg()
{
	g_iNoSilPluginId = is_plugin_loaded("NoSil");
	if( g_iNoSilPluginId > 0 )
	{
		g_iNoSilSetModel = get_func_id("fw_setmodel", g_iNoSilPluginId);
	}
}

public ConCmd_Rules(id, level, cid)
{
	if( cmd_access(id, level, cid, 2) )
	{
		static const iWeaponsIds[] = {CSW_P228, CSW_SCOUT, CSW_HEGRENADE, CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_SMOKEGRENADE, 
								CSW_ELITE, CSW_FIVESEVEN, CSW_UMP45, CSW_SG550, CSW_GALIL, CSW_FAMAS, CSW_USP, CSW_GLOCK18, CSW_AWP, 
								CSW_MP5NAVY, CSW_M249, CSW_M3, CSW_M4A1, CSW_TMP, CSW_G3SG1, CSW_FLASHBANG, CSW_DEAGLE, CSW_SG552, 
								CSW_AK47, CSW_P90, 0}; 

		new szFlags[sizeof(iWeaponsIds)+1];
		read_argv(1, szFlags, charsmax(szFlags));

		new i, cLetter, iVal;
		g_iFlags = 0;

		while( (cLetter = szFlags[i++]) )
		{
			iVal = cLetter - 'a';
			if( 0 <= iVal < sizeof(iWeaponsIds) )
			{
				g_iFlags |= 1 << iWeaponsIds[iVal];
			}
		}
	}
	return PLUGIN_HANDLED;
}

public OnSetClientKeyValue_P(id, const key[])
{
	if( equal(key, "*bot") )
	{
		RegisterHamFromEntity(Ham_Killed, id, g_szOnCBasePlayer_Killed);
		unregister_forward(FM_SetClientKeyValue, g_iFhSetClientKeyValueP, true);
	}
}

public Event_HLTV_New_Round()
{
	if( !g_iFhPlaybackEventPost )
	{
		g_iFhPlaybackEventPost = register_forward(FM_PlaybackEvent, "OnPlaybackEvent_Post", true);
	}
}

// proceed here at the end of CHalfLifeMultiplay::RestartRound so other weaponbox has already been removed
public OnPlaybackEvent_Post(flags, pInvoker, eventindex)
{
	if( g_iFhPlaybackEventPost && eventindex == m_usResetDecals )
	{
		unregister_forward(FM_PlaybackEvent, g_iFhPlaybackEventPost, true);
		g_iFhPlaybackEventPost = 0;

		new iWpnBx = FM_NULLENT;

		while( (iWpnBx = engfunc(EngFunc_FindEntityByString, iWpnBx, "classname", weaponbox)) > 0 )
		{
			WeaponBox_Killed(iWpnBx);
		}
	}
}

public OnCBasePlayer_Killed( id )
{
	new iActiveItem = get_pdata_cbase(id, m_pActiveItem);
	if( iActiveItem > 0 && pev_valid( iActiveItem ) )
	{
		if(	~NADES_BS & (1<<get_pdata_int(iActiveItem, m_iId, XO_CBASEPLAYERITEM))
		||	~pev(id, pev_button) & IN_ATTACK	)
		{
			ExecuteHam(Ham_Item_Holster, iActiveItem, 1);
			iActiveItem = 0;
		}
	}
	else
	{
		iActiveItem = 0; // depending on windows/linux it can be -1
	}

	if( g_iFlags & 1<<0 && get_pdata_bool(id, m_bHasDefuser) ) // defuser
	{
		set_pdata_bool(id, m_bHasDefuser, false);
		set_pev(id, pev_body, 0);
		message_begin(MSG_ONE, gmsgStatusIcon, _, id);
		write_byte(0);
		write_string("defuser");
		message_end();
	}

	new iWeapon, iWeaponBox, iAmmoId, iBpAmmo, iNextWeapon;
	new szWeapon[20], szModel[26];
	new Float:flOrigin[3], Float:flAngles[3], Float:flWpnBxVelocity[3];
	
	pev(id, pev_origin, flOrigin);
	pev(id, pev_angles, flAngles);

	flAngles[0] = 0.0;
	flAngles[2] = 0.0;

	new iId;
	for(new i=1; i<sizeof(m_rgpPlayerItems_CBasePlayer); i++)
	{
		if( i != 1 && i != 2 && i!= 4 ) // primary, secondary, nades
		{
			continue;
		}
		iWeapon = get_pdata_cbase(id, m_rgpPlayerItems_CBasePlayer[i]);
		while( iWeapon > 0 && pev_valid( iWeapon ) == 2 )
		{
			iNextWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
			if(	i == 4
			&&	iWeapon == iActiveItem // ready to launch nade
			&&	get_pdata_int(id, m_rgAmmo_CBasePlayer[ ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon) ]) <= 1	)
			{
				iActiveItem = 0;
				iWeapon = iNextWeapon;
				continue;
			}

			iWeaponBox = engfunc(EngFunc_CreateNamedEntity, iszWeaponBox);
			
			if( pev_valid(iWeaponBox) )
			{
				set_pev(iWeaponBox, pev_owner, id);

				engfunc(EngFunc_SetOrigin, iWeaponBox, flOrigin);

				set_pev(iWeaponBox, pev_angles, flAngles);
				ExecuteHamB(Ham_Spawn, iWeaponBox);

				flWpnBxVelocity[0] = random_float(-250.0,250.0);
				flWpnBxVelocity[1] = random_float(-250.0,250.0);
				set_pev(iWeaponBox, pev_velocity, flWpnBxVelocity);

				iId = get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM);
				if( !WeaponBox_PackWeapon(iWeaponBox, iWeapon, id, iId) )
				{
					set_pev(iWeaponBox, pev_flags, FL_KILLME);
				}
				else
				{
					if( !iActiveItem || iWeapon != iActiveItem )
					{
						iAmmoId = ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon);

						iBpAmmo = get_pdata_int(id, m_rgAmmo_CBasePlayer[iAmmoId]);
					}

					set_pdata_int(id, m_rgAmmo_CBasePlayer[iAmmoId], 0);			

					WeaponBox_PackAmmo(iWeaponBox, iAmmoId, i == 4 ? iBpAmmo - 1 : iBpAmmo);

					pev(iWeapon, pev_classname, szWeapon, charsmax(szWeapon));

					if( szWeapon[10] == 'n' ) // weapon_mp5navy
					{
						// replace(szWeapon, charsmax(szWeapon), "navy", "")
						szWeapon[10] = EOS;
					}
					formatex(szModel, charsmax(szModel), "models/w_%s.mdl", szWeapon[7]);

					engfunc(EngFunc_SetModel, iWeaponBox, szModel);

					const SILENT_WPN_BS = (1<<CSW_USP)|(1<<CSW_M4A1);

					if(	g_iNoSilPluginId > 0
					&&	g_iNoSilSetModel > 0
					&&	(1<<iId) & SILENT_WPN_BS	)
					{
						callfunc_begin_i(g_iNoSilSetModel, g_iNoSilPluginId);
						callfunc_push_int(iWeaponBox);
						callfunc_push_str(szModel);
						callfunc_end();
					}

				}
			}

			iWeapon = iNextWeapon;
		}
	}
	return HAM_HANDLED;
}

WeaponBox_PackWeapon(iWeaponBox, iWeapon, id, iId)
{
	if( !ExecuteHam(Ham_RemovePlayerItem, id, iWeapon) )
	{
		return 0;
	}

	if( g_iFlags & 1 << iId )
	{
		ExecuteHam(Ham_Item_Kill, iWeapon);
		user_has_weapon(id, iId, 0);
		return 0;
	}

	new iWeaponSlot = ExecuteHam(Ham_Item_ItemSlot, iWeapon);

	set_pdata_cbase(iWeaponBox, m_rgpPlayerItems_CWeaponBox[ iWeaponSlot ], iWeapon, XO_CWEAPONBOX);
	set_pdata_cbase(iWeapon, m_pNext, -1, XO_CBASEPLAYERITEM);

	set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN);
	set_pev(iWeapon, pev_movetype, MOVETYPE_NONE);
	set_pev(iWeapon, pev_solid, SOLID_NOT);
	set_pev(iWeapon, pev_effects, EF_NODRAW);
	set_pev(iWeapon, pev_modelindex, 0);
	set_pev(iWeapon, pev_model, 0);
	set_pev(iWeapon, pev_owner, iWeaponBox);
	set_pdata_cbase(iWeapon, m_pPlayer, -1, XO_CBASEPLAYERITEM);

	return 1;
}

WeaponBox_Killed(iWpnBx)
{
	new iWeapon;
	for(new i=0; i<MAX_ITEM_TYPES; i++)
	{
		iWeapon = get_pdata_cbase(iWpnBx, m_rgpPlayerItems_CWeaponBox[ i ], XO_CWEAPONBOX);
		if( pev_valid(iWeapon) )
		{
			set_pev(iWeapon, pev_flags, FL_KILLME);
		}
		// don't implement pNext system as it's a custom weaponbox that doesn't use it
	}
	set_pev(iWpnBx, pev_flags, FL_KILLME);
}

WeaponBox_PackAmmo(iWeaponBox, iAmmoId, iCount)
{
	if( !iCount )
	{
		return;
	}

	new iMaxCarry = g_iMaxAmmo[iAmmoId];

	if( iCount > iMaxCarry )
	{
		iCount = iMaxCarry;
	}

	set_pdata_int(iWeaponBox, m_rgiszAmmo[0], g_iszAmmoNames[iAmmoId], XO_CWEAPONBOX);
	set_pdata_int(iWeaponBox, m_rgAmmo_CWeaponBox[0], iCount, XO_CWEAPONBOX);
}

bool:get_pdata_bool(ent, charbased_offset, intbase_linuxdiff = 5)
{
	return !!( get_pdata_int(ent, charbased_offset / INT_BYTES, intbase_linuxdiff) & (0xFF<<((charbased_offset % INT_BYTES) * BYTE_BITS)) );
}

set_pdata_char(ent, charbased_offset, value, intbase_linuxdiff = 5)
{
	value &= 0xFF;
	new int_offset_value = get_pdata_int(ent, charbased_offset / INT_BYTES, intbase_linuxdiff);
	new bit_decal = (charbased_offset % INT_BYTES) * BYTE_BITS;
	int_offset_value &= ~(0xFF<<bit_decal); // clear byte
	int_offset_value |= value<<bit_decal;
	set_pdata_int(ent, charbased_offset / INT_BYTES, int_offset_value, intbase_linuxdiff);
	return 1;
}

set_pdata_bool(ent, charbased_offset, bool:value, intbase_linuxdiff = 5)
{
	set_pdata_char(ent, charbased_offset, _:value, intbase_linuxdiff);
}