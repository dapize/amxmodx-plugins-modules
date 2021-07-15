#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <orpheu>

#define SG_EXPLOSION_TIME	pev_fuser3

new m_usEvent_Grenade = 		228
#define m_bIsC4			385

#define INT_BYTES		4
#define BYTE_BITS		8 
#define SHORT_BYTES		2

new cvar_AffectRadius, cvar_SurvivalChance,

OrpheuFunction:handle_SG_Detonate

public plugin_init()
{
	register_plugin("HEs destroy grenades", "1.1.1", "beast")
	
	handle_SG_Detonate = OrpheuGetFunction("SG_Detonate", "CGrenade")
	
	OrpheuRegisterHook(OrpheuGetFunction("Detonate3", "CGrenade"), "CGrenade_Detonate3")
	OrpheuRegisterHook(OrpheuGetFunction("SG_TumbleThink", "CGrenade"),"CGrenade_SG_TumbleThink", OrpheuHookPost)
	
	cvar_AffectRadius = register_cvar("hdg_affect_radius", "350")
	cvar_SurvivalChance = register_cvar("hdg_survival_chance", "3")	
	
	#if AMXX_VERSION_NUM >= 183
	m_usEvent_Grenade *= SHORT_BYTES
	#endif
}

public OrpheuHookReturn:CGrenade_Detonate3(he)
{
	if(!pev_valid(he))
		return OrpheuIgnored
	
	new nearbyNades[32], count, nearbyNade, nearbyNadeType, Float:dist, Float:explDelay,
	Float:affectRadius, survivalChance, Float:originHe[3], Float:originNearbyNade[3]
	
	affectRadius = get_pcvar_float(cvar_AffectRadius)
	survivalChance = get_pcvar_num(cvar_SurvivalChance)
	
	pev(he, pev_origin, originHe)
	
	// finding nearby grenades
	count = find_sphere_class(he, "grenade", affectRadius, nearbyNades, charsmax(nearbyNades))

	for(new i = 0; i < count; i++)
	{
		nearbyNade = nearbyNades[i]
		
		if(nearbyNade == he || !pev_valid(nearbyNade))
			continue
			
		nearbyNadeType = GetGrenadeType(nearbyNade)
	
		if(nearbyNadeType == CSW_C4)
			continue	
		
		pev(nearbyNade, pev_origin, originNearbyNade)
		
		dist = get_distance_f(originHe, originNearbyNade)
		
		if(survivalChance)
		{
			// grenade has a chance to survive
			if(random_float(0.0, 100.0) <= survivalChance +
			dist * random_float(0.0, 5.0) / affectRadius) // some distance based randomness
				continue
		}
		
		// some distance based explosion delay
		explDelay = get_gametime() + dist / (affectRadius * random_float(6.0, 8.0))
		
		// detonating smokenade
		if(nearbyNadeType == CSW_SMOKEGRENADE)
			set_pev(nearbyNade, SG_EXPLOSION_TIME, explDelay)
		
		// detonating he and flashbang
		else
			set_pev(nearbyNade, pev_dmgtime, explDelay)
		
	}
	
	return OrpheuIgnored
}

// smoke grenade think
public OrpheuHookReturn:CGrenade_SG_TumbleThink(sg)
{
	if(!pev_valid(sg))
		return OrpheuIgnored
		
	static Float:explTime
	
	pev(sg, SG_EXPLOSION_TIME, explTime)
	
	// time to explode
	if(explTime && get_gametime() >= explTime)
		OrpheuCall(handle_SG_Detonate, sg)
		
	return OrpheuIgnored
}

// Credits ConnorMcLeod

#if AMXX_VERSION_NUM < 183
stock bool:get_pdata_bool(ent, charbased_offset, intbase_linuxdiff = 5)
{
	return !!(get_pdata_int(ent, charbased_offset / INT_BYTES, intbase_linuxdiff) & (0xFF<<((charbased_offset % INT_BYTES) * BYTE_BITS)))
} 

stock get_pdata_short(ent, shortbased_offset, intbase_linuxdiff = 5)
{
	return (get_pdata_int(ent, shortbased_offset / SHORT_BYTES, intbase_linuxdiff)>>>((shortbased_offset % SHORT_BYTES) * BYTE_BITS) ) & 0xFFFF
}
#endif

GetGrenadeType(ent) 
{
	if(get_pdata_bool(ent, m_bIsC4, 5)) 
		return CSW_C4 
	
	new usEvent = get_pdata_short(ent, m_usEvent_Grenade, 5) 
	
	if(!usEvent) 
		return CSW_FLASHBANG
	
	static m_usHgrenExplo
	
	if(!m_usHgrenExplo) 
		m_usHgrenExplo = engfunc(EngFunc_PrecacheEvent, 1, "events/createexplo.sc") 
	
	return usEvent == m_usHgrenExplo ? CSW_HEGRENADE : CSW_SMOKEGRENADE 
}
