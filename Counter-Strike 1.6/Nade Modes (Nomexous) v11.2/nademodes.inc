/* Flashbang Nade Modes Include File
*  Author: OT
*  
*  This include file will only work if the plugin named as flashbang_remote_control is placed in your server and it is working!
*/

#if defined _nademodesAPI_included
  #endinput
#endif
#define _nademodesAPI_included

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <hamsandwich>

/* Constants */

// Nade type -> shows what nademode the entity has
enum NadeType
{ 
	NADE_DUD = -1,   // This is a nade that does not blow up and does not do anything, plugin uses it in order to stop grenade explosions
    NADE_NORMAL = 0,
    NADE_PROXIMITY, 
    NADE_IMPACT, 
    NADE_TRIP, 
    NADE_MOTION, 
    NADE_SATCHEL, 
    NADE_HOMING
}

// Race of the nade
enum NadeRace
{
	GRENADE_EXPLOSIVE = 0,
	GRENADE_FLASHBANG,
	GRENADE_SMOKEGREN,
}

// Nade Weapon id
new stock NadeWeaponId[NadeRace] = 
{
	CSW_HEGRENADE, 
	CSW_FLASHBANG, 
	CSW_SMOKEGRENADE
}

// Constants about what the tripnade is doing
enum TripNadeMode
{
	TRIP_NOT_ATTACHED = 0, 
	TRIP_ATTACHED, 
	TRIP_WAITING, 
	TRIP_SCANNING, 
	TRIP_SHOULD_DETONATE, 
	TRIP_DETONATED
}

// Registration constants, used in hooking forwards
enum RegisterConst
{
	GR_RC_Touch,
	GR_RC_TakeDamage,
	GR_RC_TraceAttack,
	GR_RC_TakeDamage_Post,
	GR_RC_TraceAttack_Post,
	GR_RC_Think,
	GR_RC_Think_Post
}

/* Forwards */

/**
 * Description: 	
 * 		This is called before the core plugin sets the nade properties [limit, hp, dmgtime, etc]
 * Arguments:
 * 		entity -> The grenade entity id
 * 		nade_type -> What nade type the plugin has set [Use the NadeType constants]
 * Return:
 * 		PLUGIN_CONTINUE	-> Lets the core do the job the way it wants
 * 		PLUGIN_HANDLED  -> Stops the core from settings properties, the nade will work as a normal one!
 * Notes:
 * 		Will not work if the plugin is turned off by the central cvar
 */
forward fw_NM_nade_property_set(entity, NadeType:nade_type)


/**
 * Description: 	
 * 		This is called after the core plugin sets the nade properties [limit, hp, dmgtime, etc]
 * Arguments:
 * 		entity -> The grenade entity id
 * 		nade_type -> What nade type the plugin has set [Use the NadeType constants]
 * 		has_been_blocked -> Constant that shows that one plugin has blocked the fw_NM_nade_property_set forward
 * Return:
 * 		Doesn't matter what you return since it does not have any effect
 * Notes:
 * 		Will not work if the plugin is turned off by the central cvar
 */
forward fw_NM_nade_property_set_post(entity, NadeType:nade_type, bool:has_been_blocked)


/* Stocks and functions */

/**
 * Description: 	
 * 		It registers different hooks that without the core cannot exist!
 * Arguments:
 * 		Function_Name -> The name of the function that handles the forward
 * 		Function_Type -> What function you want to hook [Use RegisterConst]
 * Notes:
 * 		This is specially made to show scripters how to hook new events that the core creates
 * 
 * 		This stock is specially made for new scripters, if you will not use it, 
 * 		it will not be included in the compiled code.
 */
stock RegisterGrenadeFunctionality(Function_Name[], RegisterConst:Function_Type)
{
	switch(Function_Type)
	{
		case GR_RC_Touch:
		{
			RegisterHam(Ham_Touch, "grenade", Function_Name)
		}
		case GR_RC_Think:
		{
			RegisterHam(Ham_Think, "grenade", Function_Name)
		}
		case GR_RC_Think_Post:
		{
			RegisterHam(Ham_Think, "grenade", Function_Name, 1)
		}
		case GR_RC_TakeDamage:
		{
			RegisterHam(Ham_TakeDamage, "grenade", Function_Name)
		}
		case GR_RC_TraceAttack:
		{
			RegisterHam(Ham_TraceAttack, "grenade", Function_Name)
		}
		case GR_RC_TakeDamage_Post:
		{
			RegisterHam(Ham_TakeDamage, "grenade", Function_Name, 1)
		}
		case GR_RC_TraceAttack_Post:
		{
			RegisterHam(Ham_TraceAttack, "grenade", Function_Name, 1)
		}
	}
}

/**
 * Description: 	
 * 		It gets the grenade race!
 * Arguments:
 * 		ent -> The grenade entity
 * Notes:
 * 		This stock is specially made for new scripters, if you will not use it, 
 * 		it will not be included in the compiled code.
 */
stock get_grenade_race(ent)
{
	switch (cs_get_weapon_id(ent))
	{
		case CSW_HEGRENADE: 	return _:GRENADE_EXPLOSIVE
		case CSW_FLASHBANG: 	return _:GRENADE_FLASHBANG
		case CSW_SMOKEGRENADE: 	return _:GRENADE_SMOKEGREN
	}
	
	return -1
}


/**
 * Description: 	
 * 		It show wether the entity is grenade or not
 * Arguments:
 * 		ent -> The grenade entity
 * 		enforce -> If you want also to check by weapon id and not just the classname
 * Notes:
 * 		This stock is specially made for new scripters, if you will not use it, 
 * 		it will not be included in the compiled code.
 */
stock is_grenade(ent, bool:enforce = false)
{
	if (!is_valid_ent(ent))
	{
		return 0
	}
	
	if (enforce)
	{
		if (!is_classname(ent, "grenade"))
			return 0
	}
	
	static weapon_id
	weapon_id = cs_get_weapon_id(ent)
	
	for (new i=0;i<3;i++)
	{
		if (weapon_id == NADE_WPID[NadeRace:i])
			return 1
	}
	
	return 0
}

/**
 * Efficency note: 	
 * 		These are small stocks which would be recommended to be turned into macros.
 * 		I will leave them as they are since there are a lot of scripters which don't know how macros work.
 * 		Before using these functions be sure to check the entity so that you won't have false detections/invalid operations.
 */

 
/**
 * Description: 	
 * 		Makes the grenade entity explode
 * Arguments:
 * 		grenade -> The grenade entity
 */
stock make_explode(grenade)
	entity_set_float(grenade, EV_FL_dmgtime, 0)

/**
 * Description: 	
 * 		Gets the arming time of the trip nade (Ex: The trip grenade waits before it draws a line[arms itself])
 * Arguments:
 * 		grenade -> The trip grenade entity
 */
stock Float:get_trip_grenade_arm_time(grenade) 
	return entity_get_float(grenade, EV_FL_fuser1)

/**
 * Description: 	
 * 		If the nade can explode (Ex: The proximity nade waits one second before it starts searching for players)
 * Arguments:
 * 		grenade -> The grenade entity
 */
stock can_the_nade_explode(grenade)
	return (get_gametime() < entity_get_float(grenade, EV_FL_fuser2)) ? 0 : 1
	
/**
 * Description: 	
 * 		Gets the nadetype [NadeType constants]
 * Arguments:
 * 		grenade -> The grenade entity
 */
stock NadeType:get_grenade_type(grenade)
	return NadeType:entity_get_int(grenade, EV_INT_iuser1)

	
/**
 * Description: 	
 * 		Gets the trip grenade mode of operation [TripNadeMode constants]
 * Arguments:
 * 		grenade -> The grenade entity
 */
stock TripNadeMode:get_trip_grenade_mode(grenade) 
	return TripNadeMode:entity_get_int(grenade, EV_INT_iuser3)

	
/**
 * Description: 	
 * 		Gets the entity on which the trip grenade has attached
 * 		0 -> worldspawn
 * 		!0 -> Any other entity
 * Arguments:
 * 		grenade -> The grenade entity
 */
stock get_trip_grenade_attached_to(grenade) 
	return entity_get_int(grenade, EV_INT_iuser4)

	
/**
 * Description: 	
 * 		Gets the ending orgin of the laser that the tripnade draws
 * Arguments:
 * 		grenade -> The grenade entity
 * 		vector -> returned origin
 */
stock get_trip_grenade_end_origin(grenade, Float:vector[3]) 
	return TripNadeMode:entity_get_vector(grenade, EV_VEC_vuser1, vector)


/**
 * Description: 	
 * 		Gets the fly velocity of the trip nade, only available if trip mode reaction is set to "fly"
 * Arguments:
 * 		grenade -> The grenade entity
 * 		vector -> returned velocity
 */
 stock get_trip_grenade_fly_velocity(grenade, Float:vector[3]) 
	return TripNadeMode:entity_get_vector(grenade, EV_VEC_vuser2, vector)
