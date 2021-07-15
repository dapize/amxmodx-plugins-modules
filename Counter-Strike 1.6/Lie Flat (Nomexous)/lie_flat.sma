#include <amxmodx>
#include <fakemeta>
#include <xs>

#define PLUGIN "Lie Flat"
#define VERSION "1.1"
#define AUTHOR "Nomexous"

/*

Version 1.0
 - Initial release
 
Version 1.1
 - Fixed error message when 0 was passed as the weapon entity. (Reported by Voi)

*/

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_Touch, "fw_touch")
}

public fw_touch(touched, weapon)
{
	if (!pev_valid(weapon)) return FMRES_IGNORED
	
	static class[32]
	pev(weapon, pev_classname, class, 31)
	
	if (equal(class, "weaponbox") || equal(class, "weapon_shield") || equal(class, "grenade") || equal(class, "item_thighpack"))
	{
		lie_flat(weapon)
	}
	
	return FMRES_IGNORED
}

stock lie_flat(ent)
{
	// If the entity is not on the ground, don't bother continuing.
	if (pev(ent, pev_flags) & ~FL_ONGROUND) return
	
	// I decided to make all the variables static; suprisingly, the touch function can be called upwards of 5 times per drop.
	// I dunno why, but I suspect it's because the item "skips" on the ground.
	static Float:origin[3], Float:traceto[3], trace = 0, Float:fraction, Float:angles[3], Float:angles2[3]
	
	pev(ent, pev_origin, origin)
	pev(ent, pev_angles, angles)
	
	// We want to trace downwards 10 units.
	xs_vec_sub(origin, Float:{0.0, 0.0, 10.0}, traceto)
	
	engfunc(EngFunc_TraceLine, origin, traceto, IGNORE_MONSTERS, ent, trace)
	
	// Most likely if the entity has the FL_ONGROUND flag, flFraction will be less than 1.0, but we need to make sure.
	get_tr2(trace, TR_flFraction, fraction)
	if (fraction == 1.0) return
	
	// Normally, once an item is dropped, the X and Y-axis rotations (aka roll and pitch) are set to 0, making them lie "flat."
	// We find the forward vector: the direction the ent is facing before we mess with its angles.
	static Float:original_forward[3]
	angle_vector(angles, ANGLEVECTOR_FORWARD, original_forward)
	
	// If your head was an entity, no matter which direction you face, these vectors would be sticking out of your right ear,
	// up out the top of your head, and forward out from your nose.
	static Float:right[3], Float:up[3], Float:fwd[3]
	
	// The plane's normal line will be our new ANGLEVECTOR_UP.
	get_tr2(trace, TR_vecPlaneNormal, up)
	
	// This checks to see if the ground is flat. If it is, don't bother continuing.
	if (up[2] == 1.0) return
	
	// The cross product (aka vector product) will give us a vector, which is in essence our ANGLEVECTOR_RIGHT.
	xs_vec_cross(original_forward, up, right)
	// And this cross product will give us our new ANGLEVECTOR_FORWARD.
	xs_vec_cross(up, right, fwd)
	
	// Converts from the forward vector to angles. Unfortunately, vectors don't provide enough info to determine X-axis rotation (roll),
	// so we have to find it by pretending our right anglevector is a forward, calculating the angles, and pulling the corresponding value
	// that would be the roll.
	vector_to_angle(fwd, angles)
	vector_to_angle(right, angles2)
	
	// Multiply by -1 because pitch increases as we look down.
	angles[2] = -1.0 * angles2[0]
	
	// Finally, we turn our entity to lie flat.
	set_pev(ent, pev_angles, angles)
}
