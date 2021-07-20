#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Crossbow Only"
#define VERSION "0.73b"
#define AUTHOR "Facundo Montero (facuarmo)"

// Ucomment to enable server console debugging.
// #define DEBUG

/*
 * Global TODOs:
 *
 * - Cleanup the code so that more constants are used instead of plain strings.
 * - Improve the performance of the code by decreasing the amount of strings usage.
 * - Handle events properly, so that we don't have to use arbitrarily timed tasks anymore.
 * - Currently, arbitrary multiplications are being used in the hope for task IDs to not repeat,
 *   it's clearly known though, that this approach might not be reliable and should be investigated.
 */

/*
 * The constants OFFSET_CLIP and OFFSET_LINUX are based off the following work:
 *
 * https://forums.alliedmods.net/showthread.php?t=132825
 */
const OFFSET_CLIP = 40;
const OFFSET_LINUX = 4;

const CROSSBOW_MAX_CLIP = 5;

const ENTITY_INVALID = 0;

// TODO: Rewrite this constant arrays block, so that it uses constant weapon IDs instead.
new const ammo[9][] = {
	"357",
	"9mmAR",
	"9mmbox",
	"9mmclip",
	"ARgrenades",
	"buckshot",
	"crossbow",
	"gaussclip",
	"rpgclip"
};

new const weapons[13][] = {
	"357",
	"9mmAR",
	"9mmhandgun",
	// "crossbow"
	"crowbar",
	"egon",
	"gauss",
	"handgrenade",
	"hornetgun",
	"rpg",
	"satchel",
	"shotgun",
	"snark",
	"tripmine"
};

/*
 * @param int entity
 *
 * @return void
 */
remove_entity_safe(entity_id) {
	#if defined DEBUG
	new entity_str[32];

	num_to_str(entity_id, entity_str, 32);
	#endif

	if (pev_valid(entity_id) == ENTITY_INVALID) {
		#if defined DEBUG
		server_print("pev: invalid for %s", entity_str);
		#endif
		
		return;
	}

	remove_entity(entity_id);
}

/*
 * @param String entity_name[]
 * @param String entity_class[] (defaults to empty to discard underscore sub-classed tags)
 *
 * @return void
 */
remove_entity_with_class(entity_name[], entity_class[] = "") {
	new target_entity[64] = "";

	if (strlen(entity_class) > 0) {
		strcat(target_entity, entity_class, 64);
		strcat(target_entity, "_", 64);
	}

	strcat(target_entity, entity_name, 64);

	#if defined DEBUG
	server_print("preparing to remove @ %s", target_entity);
	#endif

	remove_entity_name(target_entity);

	#if defined DEBUG
	server_print("remove_entity_name: %s", target_entity);
	#endif
}

/*
 * This method forces the player to drop its weapons.
 *
 * @param  int player_id
 * @return int
 */
public drop_weapons(player_id) {
	#if defined DEBUG
	new user_name[512], user_weapon_index_str[3];

	get_user_name(player_id, user_name, 512);
	#endif
	
	new user_weapons[32], user_weapon_count = 0;

	new user_weapon_name[32];

	get_user_weapons(player_id, user_weapons, user_weapon_count);

	for (new user_weapon_index = 0; user_weapon_index < user_weapon_count; user_weapon_index++) {
		get_weaponname(user_weapons[user_weapon_index], user_weapon_name, 32);

		#if defined DEBUG
		num_to_str(user_weapon_index, user_weapon_index_str, 3);

		server_print("drop_weapons @ %s: user_weapon_name %s, user_weapons[user_weapon_index] %s", user_name, user_weapon_name, user_weapon_index_str);
		#endif

		if (!equali(user_weapon_name, "weapon_crossbow")) {
			engclient_cmd(player_id, "drop", user_weapon_name);

			#if defined DEBUG
			server_print("engclient_cmd @ %s: sent 'drop %s'", user_name, user_weapon_name);
			#endif
		}
	}

	return PLUGIN_CONTINUE;
}

/*
 * This method checks if the player is alive, if it is and it doesn't have a crossbow yet, one will
 * be provided.
 *
 * @param int player_id
 * @param int task_id
 * @return int
 */
public handle_weapons(player_id, task_id) {
	if (is_user_alive(player_id)) {
		#if defined DEBUG
		server_print("handle_weapons: calling drop_weapons()...");
		#endif

		drop_weapons(player_id);
	}

	return PLUGIN_HANDLED;
}

/*
 * This method will detect when a player changes a weapon and then, it'll delay a task to run
 * "handle_weapons" so that it doesn't trigger fast enough to crash the server.
 *
 * NOTE: I'm pretty sure there's a better way to do this, please don't hurt me, I'm new to Pawn. :)
 *
 * @param int player_id
 * @return int
 */
public weapon_changed(player_id) {
	#if defined DEBUG
	server_print("weapon_changed: calling handle_weapons()...");
	#endif

	set_task(0.1, "handle_weapons", player_id);

	return PLUGIN_HANDLED;
}

/*
 * This method will iterate through each of the constant arrays defined above and try to get rid of
 * any matching entity in a safe and controlled manner (by "thinking" and then actually removing the
 * entity).
 *
 * @return void
 */
public remove_entities_from_arrays() {
	for (new index = 0; index < sizeof(ammo); index++) {
		remove_entity_with_class(ammo[index], "ammo");
	}

	for (new index = 0; index < sizeof(weapons); index++) {
		remove_entity_with_class(weapons[index], "weapon");
	}
}

/*
 * This method is a forwarded call from HamSandwich, which from the expectation of the touch of a
 * weaponbox, it'll try to remove the entity that's just been rendered and the player touched.
 *
 * @param int entity_id
 * @param int player_id
 *
 * @return void
 */
public fwd_weaponbox_touched(entity_id, player_id) {
	#if defined DEBUG
	new entity_id_str[32], player_id_str[512];

	num_to_str(entity_id, entity_id_str, 32);
	num_to_str(player_id, player_id_str, 512);

	server_print("fwd_weaponbox_touched: entity_id %s, player_id %s", entity_id_str, player_id_str);
	#endif

	remove_entity_safe(entity_id);

	if (is_user_connected(player_id) && !user_has_weapon(player_id, HLW_CROSSBOW)) {
		give_item(player_id, "weapon_crossbow");

		drop_weapons(player_id);
	}
}

/*
 * This method will handle the primary attack so that it can reset the entity ammo to its default
 * (which is 5 for the crossbow). This operation, in fact, provides support for infinite ammo.
 *
 * @param int entity_id
 * @return int
 */
public handle_primary_attack(entity_id) {
	set_pdata_int(entity_id, OFFSET_CLIP, CROSSBOW_MAX_CLIP, OFFSET_LINUX);

	#if defined DEBUG
	server_print("handle_primary_attack: set ammo.");
	#endif

	return PLUGIN_CONTINUE;
}

public plugin_init() {
	remove_entities_from_arrays();

	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon","weapon_changed","b","1=1");
	RegisterHam( Ham_Touch, "weaponbox", "fwd_weaponbox_touched", 1 );
	RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_crossbow", "handle_primary_attack", 1 );

	return PLUGIN_CONTINUE;
}