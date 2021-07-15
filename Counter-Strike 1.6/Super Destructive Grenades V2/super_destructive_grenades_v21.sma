
	/*
		Author 	: hornet
		Plugin 	: Super Destructive Grenades
		Version : v2.1.0
		
		<>
		
		For Support : http://forums.alliedmods.net/showthread.php?p=1525339
	
		This plugin is free software; you can redistribute it and/or modify it
		under the terms of the GNU General Public License as published by the
		Free Software Foundation; either version 2 of the License, or (at
		your option) any later version.
	
		This plugin is distributed in the hope that it will be useful, but
		WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
		General Public License for more details.
	
		You should have received a copy of the GNU General Public License
		along with this plugin; if not, write to the Free Software Foundation,
		Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
		
		<>
	*/
	
#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <orpheu>
#include <xs>

#define VERSION			"2.1.0"

#define m_usEvent		114
#define m_iPlayerTeam		114

#define NADETYPE_HEGRENADE	1<<0

#define XO_WEAPON		4
#define XO_ARMOURY		4
#define XO_PLAYER		5

#define pev_startorigin		pev_vuser1
#define pev_shouldreset		pev_iuser1

new g_pExplodeDamage, g_pBreakMode, g_pWallHit, g_pExplodeRadius, g_pKnockbackPlayer, g_pKnockbackWeapon, g_pFriendlyFire;

new g_iMaxPlayers;

	/*	Array holding our entity class list	*/

new g_szKnockbackEnts[][] = 
{
	"player", "weaponbox", "armoury_entity", "func_breakable"
};

enum
{
	ENT_PLAYER,
	ENT_WEAPONBOX,
	ENT_ARMOURY,
	ENT_BREAKABLE
};

public plugin_init() 
{
	register_plugin( "Super Destructive Grenades", VERSION, "hornet" );
	
	register_cvar( "sdg_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	
	g_iMaxPlayers = get_maxplayers();
	
	g_pExplodeDamage = register_cvar( "sdg_breakables_damage", "75" );
	g_pExplodeRadius = register_cvar( "sdg_explode_radius", "300" );
	g_pBreakMode 	 = register_cvar( "sdg_break_mode", "1" );
	g_pWallHit 	 = register_cvar( "sdg_through_walls", "0" );
	
	g_pKnockbackPlayer = register_cvar( "sdg_knockback_player", "8" );
	g_pKnockbackWeapon = register_cvar( "sdg_knockback_weapons", "10" );
	
	g_pFriendlyFire = get_cvar_pointer( "mp_friendlyfire" );
	
	register_event( "HLTV", "Event_RoundStart", "a", "1=0", "2=0" );
	
	OrpheuRegisterHook( OrpheuGetFunction( "Detonate3", "CGrenade" ), "CGrenade_Detonate3" );
}

public Event_RoundStart()
{
	
		/*	Find all moved armoury_entity's and send them back to their original origin	*/
	
	new iEnt = -1;
	new Float:flOrigin[ 3 ];
	
	while( ( iEnt = engfunc( EngFunc_FindEntityByString, iEnt, "classname", "armoury_entity" ) ) )
	{
		if( pev( iEnt, pev_shouldreset ) )
		{
			pev( iEnt, pev_startorigin, flOrigin );
			set_pev( iEnt, pev_origin, flOrigin );
			set_pev( iEnt, pev_startorigin, { 0.0, 0.0, 0.0 } );
			set_pev( iEnt, pev_shouldreset, 0 );
			
			DispatchSpawn( iEnt );
		}
	}
}

public OrpheuHookReturn:CGrenade_Detonate3( iEnt )
{
	if( pev_valid( iEnt ) )
	{
		
			/*	Check for HE Grenades only	*/
		
		if( get_pdata_int( iEnt, m_usEvent, XO_WEAPON ) & NADETYPE_HEGRENADE )
		{
			new iOwner = pev( iEnt, pev_owner );
			new bool:bFriendlyFire = bool:get_pcvar_num( g_pFriendlyFire );
			
			new Float:flRadius = get_pcvar_float( g_pExplodeRadius );
			new Float:flOrigin[ 3 ];
			
			new iBreakMode = get_pcvar_num( g_pBreakMode );
			new Float:flDamage = get_pcvar_float( g_pExplodeDamage );
			
			pev( iEnt, pev_origin, flOrigin );
			
			new iWallHit = get_pcvar_num( g_pWallHit );
			
				/*	Search for entities we can knockback or ones we can break	*/
			
			for( new i ; i < sizeof g_szKnockbackEnts ; i ++ )
				find_knockback_entities( i, iEnt, iOwner, flOrigin, flRadius, flDamage, bFriendlyFire, iBreakMode, iWallHit );
		}
	}
}

find_knockback_entities( j, iEnt, iOwner, Float:flOrigin[ 3 ], Float:flRadius, Float:flDamage, bool:bFriendlyFire, iBreakMode, iWallHit )
{
	new iTarget, iNum, Float:flDistance;
	static Float:flTargetOrigin[ 3 ], Ents[ 32 ];
	
	iNum = find_sphere_class( iEnt, g_szKnockbackEnts[ j ], flRadius, Ents, sizeof Ents, flOrigin );
	
	for( new i ; i < iNum ; i ++ )
	{
		iTarget = Ents[ i ];
		
		if( !iTarget )
			break;
		
		if( !iWallHit && !ExecuteHam( Ham_FVisible, iEnt, iTarget ) )
			continue;
		
			/*	Set knockback for entities	*/
		
		if( j < ENT_BREAKABLE )
		{
			if( get_pdata_int( iOwner, m_iPlayerTeam, XO_PLAYER ) != get_pdata_int( iTarget, m_iPlayerTeam, XO_PLAYER ) || bFriendlyFire || iTarget == iOwner || j != ENT_PLAYER )
			{
				pev( iTarget, pev_origin, flTargetOrigin );
				set_entity_knockback( j, iTarget, flOrigin, flTargetOrigin, flRadius );
			}
		}
		else
		{
				/*	Set damage on breakable entities	*/
				
			switch( iBreakMode )
			{
				case 0:
				{
						/*	No damage	*/
					
					break;
				}
				
				case 1:
				{
						/*	Set damage	*/
					
					pev( iTarget, pev_origin, flTargetOrigin );
					vector_distance( flOrigin, flTargetOrigin );
					set_pev( iTarget, pev_health, pev( iTarget, pev_health ) - ( flDamage * flRadius / flDistance ) );
				}
				
				case 2:
				{
						/* 	Destroy entity - includes bomb targeted entities aswell		*/
					
					dllfunc( DLLFunc_Use, iTarget, 0 );
				}
			}
		}
	}
}

set_entity_knockback( j, iEnt, Float:flOrigin[ 3 ], Float:flTargetOrigin[ 3 ], Float:flRadius )
{
	static Float:flDistance, Float:flVelocity[ 3 ];
	
	flDistance = vector_distance( flOrigin, flTargetOrigin );

	new Float:flKnockback;
	
		/*	Get knocback power 	*/
		/*	Also set nade origin lower to create more realistic physics	*/
	
	if( iEnt > g_iMaxPlayers )
	{
		flKnockback = get_pcvar_float( g_pKnockbackWeapon );
		flOrigin[ 2 ] -= 25.0;
	}
	else	
	{
		flKnockback = get_pcvar_float( g_pKnockbackPlayer );
		flOrigin[ 2 ] -= 50.0;
	}
	
		/*	Send entity flying in the opposite direction	*/
	
	xs_vec_sub( flTargetOrigin, flOrigin, flVelocity );
	xs_vec_mul_scalar( flVelocity, flKnockback * ( flRadius / flDistance ) / 5, flVelocity );
	
	set_pev( iEnt, pev_velocity, flVelocity );
	
		/*	Check for armoury_entity's that havent moved yet	*/
	
	if( j == ENT_ARMOURY && !pev( iEnt, pev_shouldreset ) )
	{
		
			/*	Store their original origina so we can reset them later		*/
		
		static Float:flResetOrigin[ 3 ] ;
		
		pev( iEnt, pev_origin, flResetOrigin );
		set_pev( iEnt, pev_startorigin, flResetOrigin );
		set_pev( iEnt, pev_shouldreset, 1 );
	}
}
