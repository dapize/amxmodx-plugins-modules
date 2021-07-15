/*	Formatright © 2010, ConnorMcLeod

	Bubble Trails is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Bubble Trails; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define VERSION "0.0.1"

#define IsPlayer(%1)	( 1 <= %1 <= g_iMaxPlayers )
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1) 

const DONT_CHECK_WEAPONS_BITSUM = (1<<CSW_XM1014)|(1<<CSW_M3)|(1<<CSW_KNIFE)

new g_iMaxPlayers
new Trie:g_tClassNames

new g_sModelIndexBubbles

public plugin_precache()
{
	g_tClassNames = TrieCreate()

	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	TrieSetCell(g_tClassNames, "worldspawn", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)
	TrieSetCell(g_tClassNames, "player", 1)

	register_forward(FM_Spawn, "Spawn", 1)

	g_sModelIndexBubbles = precache_model("sprites/bubble.spr")
}

public Spawn( iEnt )
{
	if( pev_valid(iEnt) )
	{
		static szClassName[32]
		pev(iEnt, pev_classname, szClassName, charsmax(szClassName))
		if( !TrieKeyExists(g_tClassNames, szClassName) )
		{
			RegisterHam(Ham_TraceAttack, szClassName, "TraceAttack", 1)
			TrieSetCell(g_tClassNames, szClassName, 1)
		}
	}
}

public plugin_init()
{
	register_plugin("Bubble Trails", VERSION, "ConnorMcLeod")

	g_iMaxPlayers = get_maxplayers()
}

public plugin_end()
{
	TrieDestroy(g_tClassNames)
}

public TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if( !IsPlayer(iAttacker) || !is_user_alive(iAttacker) || DONT_CHECK_WEAPONS_BITSUM & (1<<get_user_weapon(iAttacker)) )
	{
		return
	}

	new Float:vecOrigin[3], Float:vecEnd[3]

	pev(iAttacker, pev_origin, vecOrigin)
	vecOrigin[2] += ((pev(iAttacker, pev_flags) & FL_DUCKING) ? 12.0 : 18.0)
	get_tr2(ptr, TR_vecEndPos, vecEnd)

	new Float:vecTemp[3]
	vecTemp[0] = vecEnd[0] - vecOrigin[0]
	vecTemp[1] = vecEnd[1] - vecOrigin[1]
	vecTemp[2] = vecEnd[2] - vecOrigin[2]

	UTIL_BubbleTrail(vecOrigin, vecEnd, floatround(vector_length(vecTemp) / 64.0) )
}

UTIL_BubbleTrail(Float:vecSource[3], Float:vecTo[3], iCount )
{
	new Float:flHeight = UTIL_WaterLevel(vecSource, vecSource[2], vecSource[2] + 256.0 )
	flHeight = flHeight - vecSource[2]

	if(flHeight < 8.0)
	{
		flHeight = UTIL_WaterLevel( vecTo,  vecTo[2], vecTo[2] + 256.0 )
		flHeight = flHeight - vecTo[2]
		if(flHeight < 8.0)
			return

		flHeight = flHeight + vecTo[2] - vecSource[2]
	}

	if(iCount > 255)
	{
		iCount = 255
	}

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	{
		write_byte( TE_BUBBLETRAIL )
		write_coord_f( vecSource[0] )	// mins
		write_coord_f( vecSource[1] )
		write_coord_f( vecSource[2] )
		write_coord_f( vecTo[0] )	// maxz
		write_coord_f( vecTo[1] )
		write_coord_f( vecTo[2] )
		write_coord_f( flHeight )			// height
		write_short( g_sModelIndexBubbles )
		write_byte( iCount ) // count
		write_coord( 8 ) // speed
	}
	message_end()
}

Float:UTIL_WaterLevel( Float:position[3], Float:minz, Float:maxz )
{
	new Float:midUp[3]
	midUp[0] = position[0]
	midUp[1] = position[1]
	midUp[2] = minz

	if (engfunc(EngFunc_PointContents, midUp) != CONTENTS_WATER)
		return minz

	midUp[2] = maxz
	if (engfunc(EngFunc_PointContents, midUp) == CONTENTS_WATER)
		return maxz

	new Float:diff = maxz - minz
	while(diff > 1.0)
	{
		midUp[2] = minz + diff/2.0
		if (engfunc(EngFunc_PointContents, midUp) == CONTENTS_WATER)
		{
			minz = midUp[2]
		}
		else
		{
			maxz = midUp[2]
		}
		diff = maxz - minz
	}

	return midUp[2]
}