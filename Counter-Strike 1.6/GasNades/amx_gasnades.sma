/*	Copyright © 2008, ConnorMcLeod

	GasNades is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with GasNades; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

#define PLUGIN "GasNades"
#define AUTHOR "ConnorMcLeod"
#define VERSION "2.0.0"

#define GASP_SOUND1 		"player/gasp1.wav"
#define GASP_SOUND2 		"player/gasp2.wav"

#define PEV_PDATA_SAFE	2

#define MAX_PLAYERS	32

#define m_bitsDamageType		76 // VEN

#define OFFSET_TEAM			114
#define fm_get_user_team(%1)	get_pdata_int(%1,OFFSET_TEAM)

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord, %1)

#define GASNADE_HURT	-666
#define GASNADE_HEAL	-777

new g_pCvarRadius, g_pCvarCheckTime, g_pCvarDmg, g_pCvarFF, g_pCvarLife, g_pCvarGasp, 
	g_pCvarRestore, g_pCvarNoSmoke, g_pCvarEnabled;
new mp_friendlyfire;

new g_iMaxPlayers;

new g_iHealer;

new Float:g_fLastHurt[MAX_PLAYERS+1];
new Float:g_fDmgToRestore[MAX_PLAYERS+1];

new g_iForwardEmitSound;
new HamHook:g_iHamTouch, HamHook:g_iHamThink;

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar("gasnade", VERSION, FCVAR_SERVER);

	g_pCvarEnabled = register_cvar("amx_gasnades", "1");

	g_pCvarDmg = register_cvar("amx_gasdmg", "2");
	g_pCvarRadius = register_cvar("amx_gasradius", "175");
	g_pCvarCheckTime = register_cvar("amx_gascheck", "2");
	g_pCvarFF = register_cvar("amx_gasobeyFF", "0");
	g_pCvarLife = register_cvar("amx_gaslife", "25");
	g_pCvarGasp = register_cvar("amx_smokegasp", "1");
	g_pCvarRestore = register_cvar("amx_gas_restore", "1");
	g_pCvarNoSmoke = register_cvar("amx_gas_nosmoke", "0");

	register_event("HLTV", "Event_HLTV_NewRound", "a", "1=0", "2=0");

	g_iMaxPlayers = get_maxplayers();
	mp_friendlyfire = get_cvar_pointer("mp_friendlyfire");

	Event_HLTV_NewRound();
}

public plugin_precache()
{ 
	precache_sound(GASP_SOUND1);
	precache_sound(GASP_SOUND2);
}

public plugin_pause()
{
	new iEnt = FM_NULLENT;
	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "trigger_hurt")) > 0 )
	{
		if( pev(iEnt, pev_iuser1) == GASNADE_HURT )
			engfunc(EngFunc_RemoveEntity, iEnt);
	}
	Healer(0);
}

public Event_HLTV_NewRound()
{
	new iEnt = FM_NULLENT;
	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "trigger_hurt")) > 0 )
	{
		if( pev(iEnt, pev_iuser1) == GASNADE_HURT )
			engfunc(EngFunc_RemoveEntity, iEnt);
	}

	for(new id=1; id<=g_iMaxPlayers; id++)
	{
		g_fLastHurt[id] = g_fDmgToRestore[id] = 0.0;
	}

	if( get_pcvar_num(g_pCvarEnabled) )
	{
		if( !g_iForwardEmitSound )
		{
			g_iForwardEmitSound = register_forward(FM_EmitSound, "EmitSound");
		}

		if( g_iHamTouch )
		{
			EnableHamForward(g_iHamTouch);
		}
		else
		{
			g_iHamTouch = RegisterHam(Ham_Touch, "trigger_hurt", "HurtTouch");
		}

		if( g_iHamThink )
		{
			EnableHamForward(g_iHamThink);
		}
		else
		{		
			g_iHamThink = RegisterHam(Ham_Think, "trigger_hurt", "HurtThink");
		}

		Healer(get_pcvar_num(g_pCvarRestore) ? 1 : 0);
	}
	else
	{
		if( g_iForwardEmitSound )
		{
			unregister_forward(FM_EmitSound, g_iForwardEmitSound);
			g_iForwardEmitSound = 0;
		}

		if( g_iHamTouch )
		{
			DisableHamForward(g_iHamTouch);
		}

		if( g_iHamThink )
		{
			DisableHamForward(g_iHamThink);
		}

		Healer(0);
	}
}

public EmitSound(iEntity, iChannel, const szSample[], Float:fVol, Float:fAttn, iFlags, iPitch)
{
	if( !equal(szSample, "weapons/sg_explode.wav") )
		return;

	new iEnt = engfunc( EngFunc_CreateNamedEntity , engfunc( EngFunc_AllocString, "trigger_hurt") );

	dllfunc(DLLFunc_Spawn, iEnt);

	new Float:fRadius = get_pcvar_float(g_pCvarRadius);
	new Float:fMins[3], Float:fMaxs[3];
	for(new i; i<3; i++)
	{
		fMins[i] = -fRadius;
		fMaxs[i] = fRadius;
	}
	engfunc(EngFunc_SetSize , iEnt , fMins , fMaxs );

	new Float:fOrigin[3];
	pev(iEntity, pev_origin, fOrigin);
	engfunc(EngFunc_SetOrigin, iEnt, fOrigin);

	set_pev(iEnt, pev_dmg, get_pcvar_float(g_pCvarDmg));

	set_pev(iEnt, pev_iuser1, GASNADE_HURT);

	new iOwner = pev(iEntity, pev_owner);
	if( pev_valid(iOwner) == PEV_PDATA_SAFE )
	{
		set_pev(iEnt, pev_iuser2, fm_get_user_team(iOwner));
		set_pev(iEnt, pev_owner, iOwner);
	}

	set_pev(iEnt, pev_nextthink, get_gametime() + get_pcvar_float(g_pCvarLife));

	if( get_pcvar_num(g_pCvarNoSmoke) )
	{
		emit_sound(iEntity, iChannel, szSample, fVol, fAttn, iFlags, iPitch);
		engfunc(EngFunc_RemoveEntity, iEntity);
	}
}

public HurtThink(iEnt)
{
	if( pev(iEnt, pev_iuser1) == GASNADE_HURT )
	{
		engfunc(EngFunc_RemoveEntity, iEnt);
	}
}

public HurtTouch(iEnt, id)
{
	static iPod;
	iPod = pev(iEnt, pev_iuser1);
	if( (iPod != GASNADE_HURT && iPod != GASNADE_HEAL) ||
		!(1 <= id <= g_iMaxPlayers) )
	{
		return HAM_IGNORED;
	}

	new iOwner = pev(iEnt, pev_owner);

	if( iPod == GASNADE_HURT && get_pcvar_num(g_pCvarFF) && !get_pcvar_num(mp_friendlyfire) &&
		pev(iEnt, pev_iuser2) == fm_get_user_team(id)  )
	{
		return HAM_SUPERCEDE;
	}

	static Float:flTime, Float:flDmgTime;
	flTime = get_gametime();
	pev(iEnt, pev_dmgtime, flDmgTime);
	
	if( flDmgTime > flTime )
	{
		static Float:flPainFinished;
		pev(iEnt, pev_pain_finished, flPainFinished);
		if( flTime != flPainFinished )
		{
			static iImpulse;
			iImpulse = pev(iEnt, pev_impulse);
			if ( iImpulse & (1<<(id-1)) )
				return HAM_SUPERCEDE;

			set_pev(iEnt, pev_impulse, iImpulse | (1<<(id-1)));
		}
	}
	else
	{
		set_pev(iEnt, pev_impulse, (1<<(id-1)));
	}

	static Float:flDmg, Float:flCheckTime;
	pev(iEnt, pev_dmg, flDmg);
	flCheckTime = get_pcvar_float(g_pCvarCheckTime);

	if( iPod == GASNADE_HURT )
	{
		TakeDamage(id, iEnt, iOwner, flDmg, DMG_SLOWFREEZE);
		g_fDmgToRestore[id] += flDmg;

		if(get_pcvar_num(g_pCvarGasp))
		{
			switch (random_num(1, 2))
			{
				case 1: emit_sound(id, CHAN_VOICE, GASP_SOUND1, 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 2: emit_sound(id, CHAN_VOICE, GASP_SOUND2, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
		}
		g_fLastHurt[id] = flTime;
	}
	else
	{
		if( flTime - g_fLastHurt[id] > flCheckTime && g_fDmgToRestore[id])
		{
			if( g_fDmgToRestore[id] < flDmg )
			{
				flDmg = g_fDmgToRestore[id];
			}
			g_fDmgToRestore[id] -= flDmg;
			TakeHealth(id, flDmg);
		}
	}

	set_pev(iEnt, pev_pain_finished, flTime);
	set_pev(iEnt, pev_dmgtime, flTime + flCheckTime);

	return HAM_SUPERCEDE;
}

Healer(iStatus)
{
	if( iStatus )
	{
		if( !pev_valid(g_iHealer) )
		{
			g_iHealer = engfunc( EngFunc_CreateNamedEntity , engfunc( EngFunc_AllocString, "trigger_hurt") );
			dllfunc(DLLFunc_Spawn, g_iHealer);
			engfunc(EngFunc_SetSize , g_iHealer , Float:{-4096.0, -4096.0, -4096.0} , Float:{4096.0, 4096.0, 4096.0} );
			set_pev(g_iHealer, pev_iuser1, GASNADE_HEAL);	
		}
		set_pev(g_iHealer, pev_dmg, get_pcvar_float(g_pCvarDmg));
	}
	else
	{
		if( pev_valid(g_iHealer) )
		{
			engfunc(EngFunc_RemoveEntity, g_iHealer);
			g_iHealer = FM_NULLENT;
		}
	}
}

TakeHealth(id, Float:flDmg)
{
	new Float:flHealth, Float:flMaxHealth;

	pev(id, pev_health, flHealth);
	pev(id, pev_max_health, flMaxHealth);

	if( flMaxHealth <= flHealth )
		return;

	flHealth += flDmg;

	if( flHealth > flMaxHealth )
		flHealth = flMaxHealth;

	set_pev(id, pev_health, flHealth);
}

TakeDamage(id, iEnt, iAttacker, Float:flDmg, iDmgBit)
{
	new Float:flHealth;
	pev(id, pev_health, flHealth);

	flHealth -= flDmg;

	if( flHealth < 1 )
	{
		ExecuteHamB( Ham_Killed, id, iAttacker, 0 );
		return;
	}

	set_pev(id, pev_health, flHealth);

	set_pev(id, pev_dmg_take, flDmg);
	set_pdata_int(id, m_bitsDamageType, iDmgBit);
	set_pev(id, pev_dmg_inflictor, iEnt);
}