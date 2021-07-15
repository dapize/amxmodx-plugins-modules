/*	
	/////////////////////////////////////
       ///////// VIRUS SMOKEGRENADE ////////
      /////////////////////////////////////
	
	(c) Copyright 2008, anakin_cstrike
	This file is provided as is (no warranties). 
	
	--| Version |-- 1.3
	
	Changelog:
		* [ 1.3 ]
			- added screenshake
			- added infection command
		* [ 1.2 ]
			- changing player's angles at infection
			- added new model to smoke
			- changed method of setting player's health
		* [ 1.1 ]
			- removed cstrike module
		* [ 1.0 ]
			- first released
			
	--| Support |--  http://forums.alliedmods.net/showthread.php?t=78305
	
	--| Description |--
	
		* General
			- this is a 'new' smoke grenade...wich "contains" a virus
			- trail and dynamic light effects
			- the nade has a green glow
			- the nade has a new model
			- at explosion, if you are in the radius zone...you will be infected with the virus and every x seconds, your hp begins to decrease with y...
			also your screen starts to fade and an icon apears and flashes on the left of the screen...
			oh, and you'll glow in green for x seconds.
			- the smokegrenade has a explosion damage
			- you maxspeed wil be changed depending on the seconds that have passed after you've been infected
			- if you thuch/touched by a player that is infected...you will be infected too
			- if you kill a player with the smokenade, he will explode forming 3 red cylinders.
			- player infection can be announced
			- when a player is infected, his screen will go in a wierd angle

		* Antidote
			- you can buy an antidot for a specific amount of $ 
			- the antidote is taken in x seconds 
			- a bar appears on the players screen, and disappears when the antidote is taken
		
	--| Cvars |--
		- virusnade_plugin 1/0 -- enable/disable plugin (default 1)
		- virusnade_impactdamage -- damage for smokenade at impact (default 10)
		- virusnade_damageinterval -- interval in seconds for hp decreasing (default 3)
		- virusnade_intervaldamage -- damage done at interval seconds, every x seconds (default 5)
		- virusnade_glow 1/0 -- enable/disable glowing player when infected (default 1)
		- virusnade_glowduration -- duration in seconds for glow effect (default 2)
		- virusnade_trail1/0 -- enable/disable nade trail (default 1)
		- virusnade_touch 1/0 -- enable/disable infection at player touch (default 1)
		- virusnade_changespeed 1/0 -- enable/disable changing speed (default 1)
		- virusnade_announce 1/0 -- enable/disable player infection annoucement (default 1)
		- virusnade_antidote 1/0 -- enable/disable the possibility to buy antidote (default 1)
		- virusnade_antidotecost -- the cost for the antidote (default 1500)
		- virusnade_antidoteduration - duration in seconds before the antidote is taken (default 10)
		- virusnade_antidoteonlyknife 1/0 -- enable/disable option that allows the player to play only with the knife while taking the antidote (default 1)
		- virusnade_antidotebuyzone 1/0 -- enable/disable buying the antidote only in the buyzone (default 1)
		NEW! Version 1.2 new cvars:
		- virusnade_angles 1/0 -- enable/disable changing player's angles at infection (default 1 )
		- virusnade_newmodel 1/0 -- enable/disable changing smoke model (default 1 )
	
	--| Command |--
		- amx_infect <player> <hp> - infect a player with a specific amount of hp
		
	--| Module Required |--
		- Fakemeta
		
	--| Client Commands |--
		- say /antidote -- buy an antidote
		- say_team /antidote -- buy an antidote

*/

/********************************* Includes & Definitions *********************************/		

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

// -------------------------------------------------
new const PLUGIN[] =		"Virus SmokeNade"
#define VERSION 		"1.3"
// -------------------------------------------------

#if cellbits == 32
	#define OFFSET_MAPZONE  235
#else
	#define OFFSET_MAPZONE  268
#endif

#define OFFSET_MONEY			115
#define OFFSET_BUYZONE			(1<<0)
#define fm_find_ent_in_sphere(%1,%2,%3) engfunc(EngFunc_FindEntityInSphere, %1, %2, %3)

// radius for virus
#define radius	200.0

// angles - thanks v3x
#define ANGLE_MIN 			25.0
#define ANGLE_MAX 			50.0

// access needed to use the command
#define ACCESS				ADMIN_BAN
// comand this if you don't want an information message at infection by command
#define COMMAND_INFO

// new smoke models
#define V_MODEL 		"models/v_virusnade.mdl"
#define W_MODEL			"models/w_virusnade.mdl"

// DONT CHANGE!
#define SMOKE_W_MODEL 		"models/w_smokegrenade.mdl"

enum g_NadeColors
{
	Red,
	Green,
	Blue
};

new const g_Colors[ g_NadeColors ] = { 0, 255, 0 };

/********************************* Global Variables *********************************/

new
toggle_plugin, toggle_damage, toggle_interval, toggle_intdamage,
toggle_glowduration, toggle_antidot, toggle_antidotcost, toggle_angles,
toggle_glow, toggle_announce, toggle_antidotdur, toggle_antidotknife,
toggle_trail, toggle_speed, toggle_touch, toggle_antidotzone, toggle_model;

new 
p_toggle, p_damage, p_int, p_dmg, p_announce, p_speed, 
p_glowdur, p_anticost, p_antidur, p_angles, p_model;

new 
g_msgscreenfade, g_msgstatusicon, g_msgbartime, g_msgsaytext, 
g_msgscoreinfo, g_msgdeathmsg, g_msgmoney, g_msghealth, g_msgscreenshake;

new g_Timer, pointer;

new g_trail, g_explode, g_smoke;

new bool:g_Virused[ 33 ], bool:g_Antidot[ 33 ];
new g_Count[ 33 ];


/********************************* Initialization *********************************/

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, "anakin_cstrike" );
	
	/* Fakemeta Forwards */
	register_forward( FM_Touch, "fw_touch" );
	register_forward( FM_EmitSound, "fw_emitsound" );
	register_forward( FM_SetModel, "fw_setmodel", 1 );
	register_forward( FM_PlayerPreThink, "fw_prethink" );
	
	/* Command */
	register_concmd( "amx_infect", "infect_cmd", ACCESS, "- <target> <hp> - infect player with x hp" );
	
	/* Events */
	register_event( "CurWeapon", "hook_curwpn", "be", "1=1", "2!29" );
	register_event( "HLTV", "hook_newround","a", "1=0", "2=0" );
	register_event( "ResetHUD", "hook_reset", "b" );
	register_clcmd( "say_team /antidote", "antidote_cmd" );
	register_clcmd( "say /antidote", "antidote_cmd" );
	
	/* Cvars */
	toggle_plugin = register_cvar( "virusnade_plugin", "1" );
	toggle_damage = register_cvar(" virusnade_impactdamage", "10" );
	toggle_interval = register_cvar( "virusnade_damageinterval", "3" );
	toggle_intdamage = register_cvar(" virusnade_intervaldamage", "5" );
	toggle_glow = register_cvar( "virusnade_glow", "1" );
	toggle_glowduration = register_cvar( "virusnade_glowduration", "2" );
	toggle_trail = register_cvar( "virusnade_trail", "1" );
	toggle_touch = register_cvar( "virusnade_touch", "1" );
	toggle_angles = register_cvar( "virusnade_angles", "1" );
	toggle_model = register_cvar( "virusnade_newmodel", "1" );
	toggle_speed = register_cvar( "virusnade_changespeed", "1" );
	toggle_announce = register_cvar( "virusnade_announce", "1" );
	toggle_antidot = register_cvar( "virusnade_antidote", "1" );
	toggle_antidotcost = register_cvar( "virusnade_antidotecost", "1500" );
	toggle_antidotdur = register_cvar( "virusnade_antidoteduration", "10" );
	toggle_antidotknife = register_cvar( "virusnade_antidoteonlyknife", "1" );
	toggle_antidotzone = register_cvar( "virusnade_antidotebuyzone", "1" );
	
	/* Messages */
	g_msgscreenshake = get_user_msgid( "ScreenShake" );
	g_msgscreenfade = get_user_msgid( "ScreenFade" );
	g_msgstatusicon = get_user_msgid( "StatusIcon" );
	g_msgscoreinfo = get_user_msgid( "ScoreInfo" );
	g_msgdeathmsg = get_user_msgid( "DeathMsg" );
	g_msgsaytext = get_user_msgid( "SayText" );
	g_msgbartime = get_user_msgid( "BarTime" );
	g_msghealth = get_user_msgid( "Health" );
	g_msgmoney = get_user_msgid( "Money" );
	
	pointer = get_cvar_pointer( "amx_show_activity" );
}

/********************************* Precache *********************************/

public plugin_precache()
{
	engfunc( EngFunc_PrecacheModel,V_MODEL );
	engfunc( EngFunc_PrecacheModel,W_MODEL );
	
	g_trail = precache_model( "sprites/laserbeam.spr" );
	g_explode = precache_model( "sprites/shockwave.spr" );
	g_smoke = precache_model( "sprites/steam1.spr" );
}

/********************************* Get Values *********************************/

public hook_newround()
{
	p_toggle = get_pcvar_num( toggle_plugin );
	p_damage = get_pcvar_num( toggle_damage );
	p_dmg = get_pcvar_num( toggle_intdamage );
	p_int = get_pcvar_num( toggle_interval );
	p_announce = get_pcvar_num( toggle_announce );
	p_speed = get_pcvar_num( toggle_speed );
	p_glowdur = get_pcvar_num( toggle_glowduration );
	p_anticost = get_pcvar_num( toggle_antidotcost );
	p_antidur = get_pcvar_num( toggle_antidotdur );
	p_angles = get_pcvar_num( toggle_angles );
	p_model = get_pcvar_num( toggle_model );
	
	g_Timer = p_antidur;
}
	
	
/********************************* Antidote *********************************/	

public antidote_cmd( id )
{
	// make sure the plugin is enabled
	if( p_toggle != 1 )
		return PLUGIN_HANDLED;
	
	// check if buying antidote option is enabled
	if( get_pcvar_num( toggle_antidot ) != 1)
	{
		print( id, "You're not allowed to buy an antidote!" );
		return PLUGIN_HANDLED;
	}
	
	// make sure the player is alive
	if( !is_user_alive( id ) )
	{
		print( id, "You must be alive to buy an antidote!" );
		return PLUGIN_HANDLED;
	}
	
	// check if is in buyzone
	if( !fm_get_user_buyzone( id ) && get_pcvar_num( toggle_antidotzone ) == 1)
	{
		print( id, "You must be in Buyzone to buy an antidote!" );
		return PLUGIN_CONTINUE;
	}
	
	// make sure he has enough money
	new money = fm_get_user_money( id );
	if( money < p_anticost )
	{
		print( id, "Not enough money, you need $%d to buy an antidote!", p_anticost );
		center( id, "#Cstrike_TitlesTXT_Not_Enough_Money" );
		return PLUGIN_CONTINUE;
	}
	
	// check if is infected
	if( !g_Virused[ id ] )
	{
		print( id, "You're not infected with the virus!" );
		return PLUGIN_CONTINUE;
	}
	
	// check if he allready bought an antidote
	if( g_Antidot[ id ] )
	{
		print( id, "You've already bought the antidote!" );
		center( id, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore" );
		return PLUGIN_HANDLED;
	}
	
	g_Timer = p_antidur;
	g_Antidot[ id ] = true;
	
	// remove flashing icon, set a normal 
	Icon( id, 1, "dmg_gas", 0, 255, 0 );
	set_task( 1.0, "countdown",id+12345,_,_,"b");
	fm_set_user_money( id, money - 1500,1 ); // remove money
	
	// create a bar
	message_begin( MSG_ONE, g_msgbartime, _, id );
	write_short( p_antidur );
	message_end();
	
	print( id, "You've bought an antidote for $%d !", p_anticost );
	
	return PLUGIN_CONTINUE;
}

/********************************* Infect Command *********************************/

public infect_cmd( id, level, cid )
{
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
		
	new arg[ 32 ], arg2[ 4 ], name[ 32 ], Float: fAngle[ 3 ];
	read_argv( 1, arg, sizeof arg - 1 );
	read_argv( 2, arg2, sizeof arg2 - 1 );
	get_user_name( id, name, sizeof name - 1 );
	
	new x = str_to_num( arg2 );
	new point = get_pcvar_num( pointer );
	
	new target = cmd_target( id, arg, 7 );
	if( !target )
		return PLUGIN_HANDLED;
	if( g_Virused[ target ] || task_exists( target + 123 ) )
		return PLUGIN_HANDLED;
	new name2[ 32 ];
	get_user_name( target, name2, sizeof name2 - 1 );
	new hp = get_user_health( target );
	
	g_Virused[ target ] = true;
	fm_set_user_health( target, float( hp - x ) );
	set_task( float( p_int ), "virus", target+123, _, _, "b" );
	
	if( p_angles == 1 )
	{
		fAngle[ 0 ] = random_float( ANGLE_MIN , ANGLE_MAX );
		fAngle[ 1 ] = random_float( ANGLE_MIN , ANGLE_MAX );
		fAngle[ 2 ] = random_float( ANGLE_MIN , ANGLE_MAX );
			
		set_pev( target, pev_punchangle, fAngle );
	}
				
	if( get_pcvar_num( toggle_glow ) == 1 )
	{
		// glow player
		Render( target, kRenderFxGlowShell, g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], kRenderNormal, 20 );
		set_task( float( p_glowdur ), "glow_normal", target );
	}
	
	// screenfade
	Fade( target, (1<<10), (1<<10), (1<<12), g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], 75 );
	// screenshake
	Shake( target, (1<<13), (1<<13), (1<<13) );
	// set an icon on the left of the player's screen
	Icon( target, 2, "dmg_gas", g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ] );
	
	if( p_announce == 1 )
	{
		// anounce infection
		set_hudmessage( 0, 200, 0, 0.05, 0.25, 0, 6.0, 3.0 )
		show_hudmessage( 0, "%s has been infected with the virus!", name2 );
	}
	
	#if defined COMMAND_INFO
		print( 0, "ADMIN %s: Infected %s", point == 1 ? "" : name, name2 );
	#endif
	log_amx( "ADMIN %s: Infected %s", name, name2 );
	
	return PLUGIN_HANDLED;
}

/********************************* Spreading Virus >:) *********************************/
	
public fw_emitsound( Ent, Channel, const Sound[], Float:Volume, Float:Attenuation, Flags, Pitch )	
{
	// make sure the plugin is enabled
	if( p_toggle != 1 )
		return FMRES_IGNORED;
	// make sure was a smokenade	
	if( !equali( Sound, "weapons/sg_explode.wav" ) )
		return FMRES_IGNORED;
		
	static 
	Float:origin[ 3 ], Float:iorigin[ 3 ], Float:fAngle[ 3 ],
	name[ 32 ], owner, total, hp, i;
	pev( Ent, pev_origin, origin );
	owner = pev( Ent, pev_owner );
	
	Light( origin ); // makes a nice light effect
	Render( Ent, kRenderFxNone, 255, 255, 255, 15 ); //set the glow back to normal
	
	while( ( i = fm_find_ent_in_sphere( i, origin, radius ) ) != 0 )
	{
		if( !is_user_alive( i ) )
			continue;
		// check if is allready infected	
		if( g_Virused[ i ])
			continue;
			
		pev( i, pev_origin, iorigin );	
		g_Virused[ i ] = true;	
		
		hp = get_user_health( i );
		// check if hp is less or equal to nade damage
		if( hp <= p_damage )
		{
			Kill( owner, i ); // kill the player
			
			// explode effects
			Smoke( iorigin );
			Cylinder( iorigin );
			
			// lets make a nice screenfade
			Fade( i, (6<<10), (5<<10), (1<<12), g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], 175 );
			
			continue;
		} else {
			
			total = hp - p_damage;	
			fm_set_user_health( i, float( total ) ); //inflict damage
			
			// screenfade
			Fade( i, (1<<10), (1<<10), (1<<12), g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], 75 );
			// screenshake
			Shake( i, (1<<13), (1<<13), (1<<13) );
			
			if( p_angles == 1 )
			{
				fAngle[ 0 ] = random_float( ANGLE_MIN , ANGLE_MAX );
				fAngle[ 1 ] = random_float( ANGLE_MIN , ANGLE_MAX );
				fAngle[ 2 ] = random_float( ANGLE_MIN , ANGLE_MAX );
			
				set_pev( i, pev_punchangle, fAngle );
			}
				
			if( get_pcvar_num( toggle_glow ) == 1 )
			{
				// glow player
				Render( i, kRenderFxGlowShell, g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], kRenderNormal, 20 );
				set_task( float( p_glowdur ), "glow_normal", i );
				
				// set an icon on the left of the player's screen
				Icon( i, 2, "dmg_gas", g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ] );
			}
			set_task( float( p_int ), "virus", i+123, _, _, "b" );
			
			if( p_announce == 1 )
			{
				// anounce infection
				get_user_name( i, name, 31 );
				set_hudmessage( 0, 200, 0, 0.05, 0.25, 0, 6.0, 3.0 )
				show_hudmessage( 0, "%s has been infected with the virus!", name );
			}
		}
	}
	
	return FMRES_IGNORED;
}

/********************************* SetModel Forward *********************************/	

public fw_setmodel( ent, model[] )
{
	// make sure the plugin is enabled
	if( p_toggle != 1 )
		return FMRES_IGNORED;
	// make sure was is a smokenade		
	if( !equali( model, SMOKE_W_MODEL ) )
		return FMRES_IGNORED;
	// glow nade
	Render( ent, kRenderFxGlowShell,g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ] ,kRenderNormal, 15 );
	if( get_pcvar_num(toggle_trail ) == 1 )
		Follow( ent, g_trail, 10, 5, g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], 175 ); // set the trail
	
	if( p_model == 1 )
	{
		static classname[ 32 ];
		pev( ent, pev_classname, classname, sizeof classname - 1 );
	
		if( !strcmp( classname, "weaponbox" ) || !strcmp( classname, "armoury_entity" ) || !strcmp( classname, "grenade" ) )
		{
			engfunc( EngFunc_SetModel, ent, W_MODEL );
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

/********************************* PreThink *********************************/	

public fw_prethink( id )
{
	// make sure the plugin is enabled
	if( p_toggle != 1 )
		return FMRES_IGNORED;
	// must be alive	
	if( !is_user_alive( id ) )
		return FMRES_IGNORED;
	// check if is infected	
	if( !g_Virused[ id ] )
		return FMRES_IGNORED;
	// stop if the changing speed cvar is disabled	
	if( p_speed != 1 )
		return FMRES_IGNORED;
		
	if( g_Count[ id ] >= 5 ) Speed( id, 200.0 );
	else if( g_Count[ id ] >= 10 ) Speed( id, 150.0 );
	else if( g_Count[ id ] >= 15 ) Speed( id, 100.0 );
	
	return FMRES_IGNORED;
}

/********************************* Touch Stuff *********************************/
	
public fw_touch( touched, toucher )
{
	// make sure the plugin is enabled
	if( p_toggle != 1 )
		return FMRES_IGNORED;
	// make sure the touch option is enabled	
	if( get_pcvar_num( toggle_touch ) != 1)
		return FMRES_IGNORED;
	
	static 
	dclass[ 32 ], rclass[ 32 ], 
	dname[ 32 ], rname[ 32 ],
	Float:fAngle[ 3 ];
	
	// get class and name
	pev( touched, pev_classname, dclass, sizeof dclass - 1 );
	pev( toucher, pev_classname, rclass, sizeof rclass - 1 );
	get_user_name( touched, dname, sizeof dname - 1 );
	get_user_name( toucher, rname, sizeof rname - 1 );
	
	if( equali( dclass, "player" ) && equali( rclass, "player" ) )
	{
		if( g_Virused[ toucher ] )
		{
			if( !g_Virused[ touched ] )
			{
				g_Virused[ touched ] = true;
				
				// create a screenfade
				Fade( toucher, (1<<10), (1<<10), (1<<12), g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], 75 );
				Icon( toucher,2, "dmg_gas", g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ] );
				
				if( p_angles == 1 )
				{
					fAngle[ 0 ] = random_float( ANGLE_MIN , ANGLE_MAX );
					fAngle[ 1 ] = random_float( ANGLE_MIN , ANGLE_MAX );
					fAngle[ 2 ] = random_float( ANGLE_MIN , ANGLE_MAX );
			
					set_pev( touched, pev_punchangle, fAngle );
				}
				
				// glow player
				if( get_pcvar_num( toggle_glow ) == 1 )
				{
					Render( touched, kRenderFxGlowShell, g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], kRenderNormal, 20 );
					set_task( float( p_glowdur ), "glow_normal",touched );
				}
				set_task( float( p_int ), "virus", touched+123, _, _,"b" );
				
				// anounce infection
				if( p_announce == 1 )
				{
					set_hudmessage( 0, 200, 0, 0.05, 0.25, 0, 6.0, 3.0 );
					show_hudmessage( 0, "%s has take the virus^n from %s", dname, rname );
				}
			}
		}
	}
	
	return FMRES_IGNORED;
}

/********************************* Curent Weapon stuff *********************************/	

public hook_curwpn( id )
{
	// make sure the plugin is enabled
	if( p_toggle != 1 )
		return PLUGIN_CONTINUE;	
	if( !is_user_alive( id ) )
		return PLUGIN_CONTINUE;
	
	if( p_model == 1 )
	{
		new wID = read_data( 2 );
		if( wID == CSW_SMOKEGRENADE )
			set_pev( id, pev_viewmodel2, V_MODEL );
	}
	
	// allow player to play only with the knife	
	if( g_Antidot[ id ] && get_pcvar_num( toggle_antidotknife ) == 1)
		engclient_cmd( id, "weapon_knife" );
	
	return PLUGIN_CONTINUE;
}

/********************************* Antidote task *********************************/	

public countdown( task )
{
	new id = task - 12345;
	
	if( !is_user_connected( id ) )
		return 0;
		
	set_hudmessage( 0, 255, 0, 0.02, 0.20, 0, 6.0, 2.0 );
	show_hudmessage( id, "Taking antidote: %d",g_Timer );
	g_Timer--;
	
	if( g_Timer <= 0 )
	{
		// remove decreasing task
		if( task_exists( id+12345 ) )
			remove_task( id+12345 );
		
		g_Antidot[ id ] = false;
		g_Virused[ id ] = false;
		
		Icon( id, 0, "dmg_gas", 0 ,0, 0 );
		Speed( id, 280.0 ); // set speed back to normal
		remove_task( id+123 );
		
		set_hudmessage( 0, 255, 0, 0.02, 0.20, 0, 6.0, 3.0 );
		show_hudmessage( id, "Antidote taken!" );
		
		return 0;
	}
	return 0;
}

// normal glow */
public glow_normal( id ) Render( id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255 );

/********************************* Virus Effect *********************************/	

public virus( task )
{
	new index = task-123;
	g_Count[ index ]++;
	
	// get player's health
	new hp = get_user_health( index );
	new total = hp - p_dmg;
	
	// get player's name
	new name[ 32 ];
	get_user_name( index, name, 31 );
	
	if( total <= 0 )
	{
		user_kill( index );
		Icon( index, 0, "dmg_gas", 0, 0, 0 );
		
		Speed( index, 280.0 );
		g_Count[ index ] = 0;
		
		// anounce player death
		if( p_announce == 1 )
		{
			set_hudmessage( 0, 200, 0, 0.05, 0.25, 0, 6.0, 3.0) ;
			show_hudmessage( 0, "%s was truck down by the virus!", name );
		}
	} else
		is_user_alive( index ) ? fm_set_user_health( index, float( total ) ) : remove_task( index ); //remove hp
	
	Fade( index, (1<<10), (1<<10), (1<<12), g_Colors[ Red ], g_Colors[ Green ], g_Colors[ Blue ], 35 );
	
	// change speed
	if( p_speed == 1 )
	{
		if( g_Count[ index ] >= 5) Speed( index, 200.0 );
		else if( g_Count[ index ] >= 10) Speed( index, 150.0 );
		else if( g_Count[ index ] >= 15) Speed( index, 100.0 );
	}
}

/********************************* Reset Hud *********************************/	

public hook_reset( id )
{
	g_Virused[ id]  = false;
	Icon( id, 0, "dmg_gas" ,0, 0, 0 );
	
	if( task_exists( id+123 ) )
	{
		remove_task( id+123 );
		
		Speed( id, 280.0 );
		g_Count[ id ] = 0;
	}
}

/********************************* Effects *********************************/	

public Light( Float:forigin[ 3 ] )
{
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY );
	write_byte( TE_DLIGHT );
	write_coord( floatround( forigin[ 0 ] ) ); 
	write_coord( floatround( forigin[ 1 ] ) ); 
	write_coord( floatround( forigin[ 2 ] ) ); 
	write_byte( 60 );
	write_byte( 0 );
	write_byte( 185 );
	write_byte( 0 );
	write_byte( 8 ) ;
	write_byte( 60 );
	message_end();
}

/* Smoke Effect */

public Smoke( Float:forigin[ 3 ] )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SMOKE );
	write_coord( floatround( forigin[ 0 ] ) );
	write_coord( floatround( forigin[ 1 ] ) );
	write_coord( floatround( forigin[ 2 ] ) );
	write_short( g_smoke );
	write_byte( random_num( 30, 40 ) );
	write_byte( 5 );
	message_end();
}
/* Explode stuff */

public Cylinder( Float:forigin[ 3 ] )
{
	new origin[ 3 ];
	FVecIVec( forigin, origin );	
	
	CreateCylinder( origin, 550, g_explode, 0, 0, 6, 60, 0, 0, 210, 0, 175, 0 );
	CreateCylinder( origin, 700, g_explode, 0, 0, 6, 60, 0, 0, 235, 0, 150, 0 );
	CreateCylinder( origin, 850, g_explode, 0, 0, 6, 60, 0, 15, 255, 15, 100, 0 );
}

/********************************* Usefull stocks  *********************************/	
/*********************************                 *********************************/

/* Usefull and less code xD - Cylinder */
CreateCylinder( origin[ 3 ], addrad, sprite, startfrate, framerate, life, width, amplitude, red, green, blue, brightness, speed )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + addrad );
	write_short( sprite );
	write_byte( startfrate );
	write_byte( framerate );
	write_byte(life );
	write_byte( width );
	write_byte( amplitude );
	write_byte( red );
	write_byte( green );
	write_byte( blue );
	write_byte( brightness );
	write_byte( speed );
	message_end();
}

/* Kill player, update score, money */
Kill( killer, victim )
{
	user_silentkill( victim );
	
	new kteam = get_user_team( killer );
	new vteam = get_user_team( victim );
	new kmoney = fm_get_user_money( killer );
	new kfrags;
	
	// remove money if teamkill
	if( kteam == vteam )
	{
		kfrags = get_user_frags( killer ) - 1;
		fm_set_user_money( killer, kmoney - 300, 1 );
	} else {
		kfrags = get_user_frags( killer ) + 1;
		fm_set_user_money( killer, kmoney + 300, 1 ); // otherwise give kill bonus
	}
	
	new vfrags = get_user_frags( victim );
	new kdeaths = get_user_deaths( killer );
	new vdeaths = get_user_deaths( victim );
	
	// update score
	message_begin( MSG_ALL, g_msgscoreinfo );
	write_byte( killer );
	write_short( kfrags );
	write_short( kdeaths );
	write_short( 0 );
	write_short( kteam );
	message_end();
	
	message_begin (MSG_ALL, g_msgscoreinfo );
	write_byte( victim );
	write_short( vfrags+1 );
	write_short( vdeaths );
	write_short( 0 );
	write_short( vteam );
	message_end();
	
	// set a death message
	message_begin( MSG_ALL, g_msgdeathmsg, { 0, 0, 0 }, 0 );
	write_byte( killer );
	write_byte( victim );
	write_byte( 0 );
	write_string( "virusnade" );
	message_end();
	
	Log( killer, victim, "virusnade" );
}

/* Log Kill */
Log( killer, victim, weapond[] )
{
	new Buffer[ 256 ];
	new kname[ 32 ], vname[ 32 ];
	new kteam[ 16 ], vteam[ 16 ];
	new kauth[ 32 ], vauth[ 32 ];
	new kid, vid;
	
	// killer info
	get_user_name( killer, kname, 31 );
	get_user_team( killer, kteam,15 );
	get_user_authid( killer, kauth,31 );
	kid = get_user_userid( killer );
	
	// victim info
	get_user_name( victim, vname, 31 );
	get_user_team( victim, vteam, 15 );
	get_user_authid( victim, vauth, 31 );
	vid = get_user_userid( victim );
	
	// teamkill message
	(killer == victim) 
	?
		format( Buffer, sizeof Buffer - 1, "^"%s<%d><%s><%s>^" committed suicide with ^"%s^"", vname, vid, vteam, vauth, weapond )
	:
		format( Buffer, sizeof Buffer - 1, "^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", kname, kid, kteam, kauth, vname, vid, vteam, vauth, weapond );
	
	log_message( "%s", Buffer );
}

/* Fakemeta Rendering */
Render( index, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16 )
{
	set_pev( index, pev_renderfx, fx );
	
	new Float:RenderColor[ 3 ];
	RenderColor[ 0 ] = float( r );  
	RenderColor[ 1 ] = float( g );  
	RenderColor[ 2 ] = float( b ); 
	
	set_pev( index, pev_rendercolor, RenderColor );
	set_pev( index, pev_rendermode, render );  
	set_pev( index, pev_renderamt, float( amount ) );
	
	return 1; 
}

/* Set a BeamFollow */
Follow( entity, index, life, width, red, green, blue, alpha )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( entity );
	write_short( index );
	write_byte( life );
	write_byte( width );
	write_byte( red );
	write_byte( green );
	write_byte( blue );
	write_byte( alpha );
	message_end();
}

/* An usefull and advanced print stock */
print( id, const message[], { Float, Sql, Result, _ }:... )
{
	new Buffer[ 128 ],Buffer2[ 128 ];
	new players[ 32 ], index, num, i;
	
	formatex( Buffer2, sizeof Buffer2 - 1, "%s",message );
	vformat( Buffer, sizeof Buffer - 1, Buffer2, 3 );
	get_players( players, num, "c" );
	
	if( id )
	{
		if( !is_user_connected( id ))
			return;
			
		message_begin( MSG_ONE, g_msgsaytext, _, id );
		write_byte( id );
		write_string( Buffer );
		message_end();
	
	} else {
		
		for( i = 0; i < num;i++ )
		{
			index = players[ i ];
			if( !is_user_connected( index )) 
				continue;
				
			message_begin( MSG_ONE, g_msgsaytext, _, index );
			write_byte( index );
			write_string( Buffer );
			message_end();
		}
	}
}

/* ScreenFade */
Fade( index, duration, holdtime, flags, red, green ,blue, alpha )
{
	message_begin( MSG_ONE, g_msgscreenfade, { 0, 0, 0 }, index );
	write_short( duration );
	write_short( holdtime );
	write_short( flags );
	write_byte( red );
	write_byte( green );
	write_byte( blue) ;
	write_byte( alpha );
	message_end();
}

/* Status Icon */
Icon( index, mode = 2, const sprite[], red = 0, green = 255, blue = 0 )
{
	message_begin( MSG_ONE, g_msgstatusicon, { 0, 0, 0 }, index );
	write_byte( mode );
	write_string( sprite ); 
	write_byte( red );
	write_byte( green ); 
	write_byte( blue ); 
	message_end();
}

/* ScreenShake */
Shake( index, amplitude, duration, frequency )
{
	message_begin( MSG_ONE, g_msgscreenshake, { 0, 0, 0 }, index );
	write_short( amplitude );
	write_short( duration );
	write_short( frequency );
	message_end();
}

/* Center message */
center( index, const message[] )
{
	if( !is_user_connected( index ) ) 
		return 0;
	
	client_print( index, print_center, "%s", message );
	
	return 1;
}

/* Get & Set user money */
fm_get_user_money( index )
{
	new money = get_pdata_int( index, OFFSET_MONEY );
	
	return money;
}
fm_set_user_money( index, money, flash = 1 )
{
	set_pdata_int( index, OFFSET_MONEY, money );
	
	message_begin( MSG_ONE, g_msgmoney, {0, 0, 0}, index );
	write_long( money );
	write_byte( flash ? 1 : 0 );
	message_end();
	
	return 1;
}

/* Get user buyzone */
fm_get_user_buyzone( index )
{
	if( get_pdata_int( index, OFFSET_MAPZONE ) & OFFSET_BUYZONE )
		return 1;
	
	return 0;
}

/* Set user health */
fm_set_user_health( index, Float: hp )
{
	message_begin( MSG_ONE, g_msghealth, {0,0,0}, index );
	write_byte( floatround( hp ) );
	message_end();
	
	set_pev( index, pev_health, hp );
}

/* Set user maxspeed */
Speed( index, Float:speed ) set_pev( index, pev_maxspeed, speed );