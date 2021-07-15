/***************************************************************************
* This plugin reads keyword/wav/mp3 combinations from a configfile and when
* a player says one of the keywords, it will trigger HL to play that Wav/MP3
* file to all or dead/alive players. It allows reloading of the file without
* restarting the current level, as well as adding keyword/wav/mp3
* combinations from the console during gameplay. Also includes banning
* players from playing sounds.
*
* Credits:
*	- Luke Sankey           -> original author
*	- HunteR                -> modifications
*
* Functions included in this plugin:
*	mp_sank_sounds_download	1/0            - turn internal download system on/off
*	amx_sound                              - turn Sank Sounds on/off
*	amx_sound_help                         - prints all available sounds to console
*	amx_sound_play <dir/sound>             - plays a specific wav/mp3/speech
*	amx_sound_add <keyword> <dir/sound>    - adds a word/wav/mp3/speech
*	amx_sound_reload <filename>           - reload your snd-list.cfg or custom .cfg
*	amx_sound_remove <keyword> <dir/sound> - remove a word/wav/mp3
*	amx_sound_write <filename>             - write all settings to custom .cfg
*	amx_sound_reset <player>               - resets quota for specified player
*	amx_sound_debug                        - prints debugs (debug mode must be on, see define below)
*	amx_sound_ban <player>                 - bans player from using sounds for current map
*	amx_sound_unban <player>               - unbans player from using sounds for current map
*	amx_sound_top <x>                      - shows the top <x> most played keywords (leave <x> away for top 10)
*
* Config file settings:
*	SND_WARN                - The number at which a player will get warned for playing too many sounds each map
*	SND_MAX                 - The number at which a player will get muted for playing too many sounds each map
*	SND_MAX_DUR             - The maximum amount of seconds a player can play sounds each map (float )
*	SND_JOIN                - The Sounds to play when a person joins the game
*	SND_EXIT                - The Sounds to play when a person exits the game
*	SND_DELAY               - Minimum delay between sounds (float)
*	SND_MODE XX             - Determinates who can play and who can hear sounds (see readme.txt for details)
*	SND_IMMUNITY "XYZ"      - Determine the access levels which shall have immunity to warn/ban
*	SND_OBEY_DUR XX         - Determine who shall obey duration before next sound will be played
*	EXACT_MATCH 1/0         - Determinates if plugin triggers on exact match, or partial speech match
*	ADMINS_ONLY 1/0         - Determinates if only admins are allowed to play sounds
*	DISPLAY_KEYWORDS 1/0    - Determinates if keywords are shown in chat or not
*	FREEZE_TIME_CON XX      - Time in seconds to wait till first sounds are played (applies only to connect/disconnect sounds)
*
* Commands available for each player:
*	amx_sound_help          -    prints all available sounds to console
*	say "/soundson"         -    now the player can hear sounds again
*	say "/soundsoff"        -    player disables ability to hear sounds
*	say "/sounds"           -    shows a list of all sounds
*	say "/soundlist"        -    shows a list of all sounds
*
* ported to Amx Mod X by White Panther
*
* v1.0.2 (original 4.1 but this is AmxModX):
*	- initial release for AmxModX
*	- renamed commands to fit with AmxModX
*	- Admin sounds cannot be seen by normal people when using amx_sound_help
*	- sounds are precached from file
*	- fix: check if soundfile exist before precache (that should solve some probs)
*	- fix: if chat message was longer than 29 chars the first wav in cfg was played
*
* v1.1.3 :
*	- fixed bug with spaces between keywords and wavs
*	- multiple Join and Exit sounds can now be used
*	- fixed bug where connect and disconnect sound have not been played
*	- fixed bug where dead players could not hear sounds
*	- added bot check
*	- added option to only allow admins to play sounds
*
* v 1.2.4 :
*	- added mp3 support (they have to be in <Mod-Dir>/sound too) (engine module needed therefore) (+ hotfix: wavs not being played)
*	- changed the way of initializing each sound file (if bad file it wont be loaded and error msg will be printed)
*	- changed SND_KICK to SND_MAX
*	- increased default defines ( words: 40 - > 80 / each wavs: 10 -> 14  / file chars: 30 -> 60 )
*	- fixed bug for 32 players
*	- increased memory usage for variables to 64K (should fix probs)
*	- while parsing there is now a check if file exists (if not it wont be put in list)
*
* v1.2.5:
*	- added a cvar to enable or disable auto download (change will take place after restart/mapchange)
*
* v1.3:
*	- fixed:
*		- fixed prob where strings were copied into other strings with no size match
*		- removed bot detection (maybe this was causing some problems, playing sounds to bots does not do any harm)
*		- admin sounds could not be played (eg: hallo; misc/hi.wav;@misc/hi2.wav -> hi2.wav was not played, even by admins)
*	- added:
*		- type "/sounds" in chat to get a MOTD window with all sounds available (not all mods support MOTD window)
*		- ability for speech sounds (like the AmxModX's speechmenu)
*		- admin check to "amx_sound_debug" so in debugmode only admins can use it
*		- list is now sorted by name for more readable output (sort by Bailopan) (sort can be turned off by define)
*
* v1.3.2:
*	- fixed:
*		- mp3 support not working
*	- changed:
*		- mp3 now dont need to be in sound folder but anywhere you want (anywhere in your mod folder though)
*			just specify the correct path (eg: music/mymusic/my.mp3 or sound/testmp3/test.mp3 or mainfolder.mp3)
*		- amx_sound_debug can now also be used if debug mode is off (this function prints the sound matrix)
*
* v1.3.3:
*	- added:
*		- cvar "mp_sank_sounds_freezetime" to define when first connect/disconnect sounds are played after mapchange (in seconds)
*
* v1.3.4:
*	- fixed:
*		- error where some players could not hear any sound
*	- changed:
*		- some log messages got better checks
*		- reimplemented check for bots
*
* v1.3.5:
*	- added:
*		- with "/soundson" and "/soundsoff" each player can activate/deactivate the ability to hear sounds
*
* v1.3.7:
*	- added:
*		- "DISPLAY_KEYWORDS" to config, it determinates if keywords are shown in chat or not
*		- option to load specific sounds only on specific maps
*	- changed:
*		- "SND_DELAY" is now a float
*
* v1.4.0:
*	- added:
*		- option to load packages of sounds, packages cycle with each map-change (packages must be numbered)
*		- ability to ban people from using sounds (only for current map) ( amx_sound_ban <player> <1/0 OR on/off> )
*	- changed:
*		- precache method changed
*		- all keywords are now stored into buffer, even those sounds that are not precached
*		- code improvements
*
* v1.4.1:
*	- fixed:
*		- when setting DISPLAY_KEYWORDS to 0 chat was disabled
*
* v1.4.2:
*	- fixed:
*		- players could be banned from sounds after reconnect
*	- added:
*		- option to include sounds from "half-life.gcf" and <current mod>.gcf
*
* v1.4.2b:
*	- fixed:
*		- compile error when disabling mp3 support
*
* v1.4.3:
*	- fixed:
*		- keywords without or with wrong files will not be added anymore
*		- possible errors fixed
*		- error with MOTD display fixed
*
* v1.4.5:
*	- fixed:
*		- ADMINS_ONLY was not working always
*		- players could only play less sound than specified in SND_MAX
*		- runtime error with amx_sound_reload
*	- added:
*		- sounds can now also be used in team chat
*		- amx_sound_unban to unban players
*	- changed:
*		- keyword check tweaked
*		- amx_sound_ban now do not expect additional parameter "on / off" or "1 / 0"
*
* v1.4.7:
*	- fixed:
*		- keywords with admin and public sounds, could block normal players from playing normal sounds
*		- runtime error which could stop plugin to work
*		- message telling players to wait till next sound can be played is not displayed on every word anymore
*
* v1.5.0: ( AmxModX 1.71 or better ONLY )
*	- fixed:
*		- sounds being not in a subfolder ( eg: sound/mysound.wav ) will now be played
*		- reconnecting to reset quota will not work anymore
*		- no more overlapping sounds ( Join and Exit sounds will still overlap other but others cannot overlap them )
*		- amx_sound_reset now accepts IDs too
*		- sound quota could be increased even if no sound was played
*	- added:
*		- sound duration is now calculated
*	- changed:
*		- SND_DELAY does not affect admins anymore
*		- SND_SPLIT has been replaced with more customizable SND_MODE
*		- removed support to disable MP3
*
* v1.5.0b:
*	- fixed:
*		- rare runtime error
*
* v1.5.1:
*	- fixed:
*		- calculation for MP3's encoded with MPEG 2
*	- added:
*		- saying "/soundlist" will now show sound list like "/sounds" does
*		- CVAR: "mp_sank_sounds_obey_duration" to determine if sounds may overlap or not ( default: 1 = do not overlap )
*
* v1.5.1b:
*	- fixed:
*		- runtime error in mp3 calculation
*
* v1.5.2:
*	- fixed:
*		- support for SND_DELAY was accidently removed
*		- some possible minor bugs
*	- added:
*		- SND_MAX_DUR: maximum of seconds a player can play sounds each map
*		- two new options for SND_MODE ( read help for more information )
*
* v1.5.3:
*	- fixed:
*		- admin being able to play sounds when "mp_sank_sounds_obey_duration" was on
*	- added:
*		- CVAR: "mp_sank_sounds_motd_address" to use a website to show all sounds ( empty cvar = no website will be used )
*
* v1.5.4:
*	- fixed:
*		- error in mp3 calculation
*		- when using "mapnameonly" option, following options have been ignored
*	- added:
*		- minor detection for damaged/invalid files
*	- changed:
*		- both "SND-LIST.CFG" and "snd-list.cfg" will work now ( linux )
*		- code improvements
*		- faster config parsing/writing
*
* v1.5.5:
*	- fixed:
*		- error in mp3 calculation ( once again :( )
*	- added:
*		- additional debug info for mp3's when compiled in DEGUB_MODE 1
*
* v1.5.6:
*	- fixed:
*		- sounds located in <MODDIR>/sounds/ (no subfolder) not being played if dead and alive not being splitted
*		- long lines not being parsed correctly
*		- players could play one more sound than allowed
*
* v1.6.0: (16.4.2007)
*	- fixed:
*		- speech sounds not being played
*		- join / exit sound duration was incorrect
*		- SND_WARN / SND_MAX error checking could display wrong error
*	- added:
*		- access can be defined for every sound and keyword seperately
*	- changed:
*		- partly rewritten
*		- way of saving data
*		- sounds when enabling and disabling Sank Sounds are not precached anymore ( hard coded )
*		- many code improvements
*
* v1.6.2: (16.01.2008)
*	- fixed:
*		- removed debug message
*		- admins are not included in overlapping check anymore
*		- non admins could see sounds that are for admins only
*		- bug when adding and removing sounds ingame to list (wierd keywords and sounds)
*	- added:
*		- "PLAY_COUNT_KEY" and "PLAY_COUNT" to data structure to count how often a key and sound has been used
*		- messages for players when enabling/disabling sounds and if players have to wait cause of delay
*	- changed:
*		- sank sounds is now precaching sounds after plugin init (fakemeta modul needed)
*		- no more engine, but therefore fakemeta is needed
*		- minor code tweaks
*
* v1.6.3: (29.02.2008)
*	- fixed:
*		- runtime error if more sounds added than defined in MAX_KEYWORDS
*		- commenting SND_JOIN and SND_EXIT (adding # or // infront of them) made the following sounds to be added to these options
*	- changed:
*		- CVAR "mp_sank_sounds_obey_duration" is now a bitmask (see readme.txt)
*
* v1.6.4: (21.12.2008)
*	- added:
*		- warning for unsupported mp3 files
*	- changed:
*		- mp3 detection code rewritten
*
* v1.6.5: (14.01.2009)
*	- fixed:
*		- wav detection for bad files
*
* v1.6.5b: (22.01.2009)
*	- changed:
*		- removed warning for unsupported mp3s (they are supported)
*
* v1.6.6: (03.03.2009)
*	- fixed:
*		- last entry in configfile was not sorted
*		- runtime error with keywords without any sound
*		- exploit where SND_JOIN and SND_EXIT could be used as keywords
*	- changed:
*		- SND_JOIN and SND_JOIN do not have to be before any other keyword
*
* v1.6.6b: (29.03.2009)
*	- fixed:
*		- runtime error
*		- if SND_JOIN or SND_JOIN was not at the beginning and more sounds were added afterwards, those new sounds overwrote previous sounds
*
* v1.6.6c: (30.06.2009)
*	- fixed:
*		- removed debug message
*
* v1.6.6d: (03.07.2009)
*	- fixed:
*		- speech files not being played
*
* v1.7.0: (08.08.2011)
*	- added:
*		- further checks for bad configfiles
*		- new option SND_IMMUNITY (defines all levels that shall get immunity)
*		- info when used last sound
*		- amx_sound_top <x> shows the top <x> (default 10) most played keywords during current map
*		- using keywords followed by a ! (eg: haha!) will play the sound bound to a location (WAVs only)
*		  you can move away from the sound. NO config change needed
*	- changed:
*		- WAVs are not bound to <mod-dir>/sound folder anymore (config change needed unfortunately)
*		  all sounds now need the full path (eg: haha; sound/misc/haha.wav)
*
* v1.7.1: (11.08.2011)
*	- fixed:
*		- WAVs not downloading and producing error messages
*
* v1.8.0: (11.01.2012)
*	- fixed:
*		- adding new sounds with console command could add it but it would not be available
*	- changed:
*		- dynamic arrays are now used to store key/sound data to remove limits
*		- saving to default config file is now allowed
*
* v1.8.1: (14.03.2013)
*	- fixed:
*		- determination if sound can be played for admins
*		- "amx_sound_add" could add empty keywords if sound was invalid
*		- "amx_sound_add" is not checking sounds if they exist anymore
*	- changed:
*		- increased motd webpage link length to 255 characters
*
* v1.8.2: (01.09.2013)
*	- fixed:
*		- exit sounds could be replaced by keyword sounds
*
* v1.8.3: (21.10.2013)
*	- fixed:
*		- ADMINS_ONLY setting was ignored
*
* v1.8.4: (06.01.2014)
*	- fixed:
*		- admins could get spammed with "You are muted" messages
*
* v1.8.5: (04.05.2014)
*	- added:
*		- support to also load files from "<MOD>_downloads" folder
*	- fixed:
*		- issue with ADMINS_ONLY and RCON access level
*
* v1.8.6: (22.05.2016)
*	- fixed:
*		- players could get stuck in a "spectator" mode state or being kicked if trying to play a sound with exactly TOK_LENGTH length
*
* v1.8.7: (2017.11.26)
*	- fixed:
*		- console warnings when "developer" is set to "1"
*		- misc
*	- changed:
*		- support to also load files from "<MOD>_<xxx>" folders
*
* v1.8.8: (2019.05.05)
*	- fixed:
*		- Players had to wait up to SND_DELAY after map change before being able to play sounds
*		- Some warnings not being displayed
*		- Issue where downloading was not working for WAV files (due to "developer 1" fix)
*
* v1.8.9: (2019.10.03)
*	- added:
*		- Option to allow bots to use sounds
*	- fixed:
*		- Always playing first sound.
*
* v1.9.0: (2020.09.10)
*	- changed:
*		- CVAR "mp_sank_sounds_obey_duration" replaced with config "SND_OBEY_DUR"
*		- CVAR "mp_sank_sounds_freezetime" replaced with config "FREEZE_TIME_CON"
*	- fixed:
*		- Obey duration for admins would prevent them from playing any sound
*
* v1.9.1: (2021.07.02)
*	- changed:
*		- using precache generic for all types (instead of precache sound for WAVs)
*
* v1.9.2: (2021.07.11)
*	- changed:
*		- adjustments to array initialization
*
* IMPORTANT:
*	a) if u want to use the internal download system do not use more than 200 sounds (HL cannot handle it)
*		(also depending on map, you may need to use even less)
*		but if u disable the internal download system u can use as many sounds as the plugin can handle
*		(max should be over 100000 sounds (depending on the Array Defines ), BUT the plugin speed
*		is another question with thousands of sounds ;) )
*
*	b) File has to look like this:
*		SND_MAX;		20
*		SND_MAX_DUR;	180.0
*		SND_WARN;		17
*		SND_JOIN;		misc/hi.wav
*		SND_EXIT;		misc/comeagain.wav
*		SND_DELAY;		0.0
*		SND_MODE;		15
*		SND_IMMUNITY;		"l"
*		SND_OBEY_DUR;		1
*		EXACT_MATCH;		1
*		ADMINS_ONLY;		0
*		DISPLAY_KEYWORDS;	1
*		FREEZE_TIME_CON;	0
*
*		# Word/Sound combinations:
*		crap;			misc/awwcrap.Wav;misc/awwcrap2.wav
*		woohoo;			misc/woohoo.wav
*		@ha ha;			misc/haha.wav
*		@abm@godlike;	misc/godlike.wav
*		doh;			misc/doh.wav;misc/doh2.wav;@misc/doh3.wav
*		mp3;			sound/mymp3.mp3;music/mymp3s/number2.mp3;mainfolder.mp3
*		target;			"target destroyed"
*
*		mapname TESTMAP
*		testmap;		misc/doh.wav
*		mapname TESTMAP2
*		testmap2;		misc/haha.wav;sound/mymp3.mp3
*		testmap3;		misc/hi.wav
*
*		package 1
*		haha2;			misc/haha.wav
*		doh3;			misc/doh3.wav
*		package 2
*		hi;				misc/hi.wav
*
*		modspecific
*		<keyword>;		<location>/<name>.wav
*
*		Follow these instructions
*		wavs:
*			- base directory is "mod-dir/sound/"
*			- put EXACT PATH to the wav beginning from base directory (eg misc/test.wav or test2.wav)
*		mp3:
*			- base directory is "mod-dir/"
*			- put the EXACT PATH to the mp3 (eg sound/test.mp3 or music/mymp3s/test2.mp3 or mainfolder.mp3)
*		speech:
*			- base directory is "mod-dir/sound/vox/"
*			- these files are inside the steam package
*			- for a list look at c)
*		mapname:
*			- type mapname <space> the real mapname (without .bsp)
*			- everthing below will be loaded only on this map
*		mapnameonly:
*			- type mapnameonly <space> the real mapname (without .bsp)
*			- everthing below will be loaded only on this map
*			- everthing below will be only available on this map
*		package:
*			- type package <space> number
*			- everthing below will be loaded only once and switched to next package on map-change
*			- if only 1 package this package will be used every map-change
*		modspecific:
*			- every sound below that line must be inside half-life.gcf or <yourmod>.gcf
*			- if you add other files then said above they may/will crash your server as these sounds are assumed to be existent
*
*	c) speech sounds must be put in quotes (eg: target; "target destroyed")
*		you may not put different speech types into 1 speech or the speech wont be played
*		speech without directory is used from "vox/.."
*		first specify the speech type (ONLY ONCE eg hgrunt/) and then put the words with spaces between each speech
*		eg "hgrunt/yessir barney/stop1" will not work as 2 different speeches
*		BUT "hgrunt/yessir no" will work
*		get all available speech sounds here:
*			"http://www.adminmod.org/help/online/Admin_Mod_Reference/Half_Life_Sounds.htm"
*
*	d) "@" infront of a
*		- word means only admin can use this word
*		- wav/mp3/speech/word means players can use the word but this sound is only played by admins
*
*	e) custom admin access:
*		- infront of a word/sound add @<ACCESS_LEVELS>@
*		- replace <ACCESS_LEVELS> with the access levels you desire
*		- @abc@ means: everyone with access a, b or c can use it
***************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

// set this to 1 to get some debug messages
#define	DEBUG_MODE	0

// turn this off to stop list from being sorted by keywords in alphabetic order
#define	ALLOW_SORT	1

// Array Defines, ATTENTION: ( MAX_RANDOM + 1 ) * TOK_LENGTH must be smaller 2048 !!!
#define BUFFER_LEN    2048 // Maximum number of space per line to use when reading configfile
#define MAX_RANDOM    15  // Maximum number of tries to find a sound file
#define TOK_LENGTH    60  // Maximum length of keyword and sound file strings
#define MAX_BANS      32  // Maximum number of bans stored
#define NUM_PER_LINE  6   // Number of words per line from amx_sound_help

//#pragma dynamic 16384
#pragma dynamic 65536

#define ACCESS_ADMIN	ADMIN_LEVEL_A

#define PLUGIN_AUTHOR		"White Panther, Luke Sankey, HunteR"
#define PLUGIN_VERSION		"1.9.2"

new Enable_Sound[] =  "sound/misc/woohoo.wav"   // Sound played when Sank Sounds being enabled
new Disable_Sound[] = "sound/misc/awwcrap.wav"  // Sound played when Sank Sounds being disabled

new config_filename[128]

new SndCount[33] = {0, ...}               // Holds the number telling how many sounds a player has played
new Float:SndLenghtCount[33] = {0.0, ...}
new SndOn[33] = {1, ...}

new SND_WARN = 0                          // The number at which a player will get warned for playing too many sounds
new SND_MAX = 0                           // The number at which a player will get muted for playing too many sounds
new Float:SND_MAX_DUR = 0.0
new Float:SND_DELAY = 0.0                 // Minimum delay between sounds
new SND_MODE = 15                         // Determinates who can play and who can hear sounds (dead and alive)
new SND_IMMUNITY = ACCESS_ADMIN           // Determine the access levels which shall have immunity to warn/ban (default ACCESS_ADMIN for backwards compatability)
new SND_OBEY_DUR = 1                      // Determine who shall obey duration before next sound will be played
new EXACT_MATCH = 1                       // Determinates if plugin triggers on exact match, or partial speech match
new ADMINS_ONLY = 0                       // Determinates if only admins are allowed to play sounds
new DISPLAY_KEYWORDS = 1                  // Determinates if keywords are shown in chat or not
new FREEZE_TIME_CON = 0                   // Time in seconds to wait till first sounds are played (applies only to connect/disconnect sounds)

new Float:NextSoundTime                   // spam protection
new Float:Join_exit_SoundTime             // spam protection 2
new Float:LastSoundTime = 0.0
new bSoundsEnabled = 1                    // amx_sound <on/off> or <1/0>

new g_max_players
new banned_player_steamids[MAX_BANS][60]
new restrict_playing_sounds[33]
new sound_quota_steamids[33][60]

new motd_sound_list_address[256]

new Array:modSearchPaths

enum
{
	PARSE_SND_MAX,
	PARSE_SND_MAX_DUR,
	PARSE_SND_WARN,
	PARSE_SND_DELAY,
	PARSE_SND_MODE,
	PARSE_SND_IMMUNITY,
	PARSE_SND_OBEY_DUR,
	PARSE_EXACT_MATCH,
	PARSE_ADMINS_ONLY,
	PARSE_DISPLAY_KEYWORDS,
	PARSE_FREEZE_TIME_CON,
	PARSE_KEYWORD
}

enum
{
	ERROR_NONE,
	ERROR_MAX_KEYWORDS,
	ERROR_STRING_LENGTH
}

enum
{
	RESULT_OK = 1,
	RESULT_BAD_ALIVE_STATUS = 0,
	RESULT_QUOTA_EXCEEDED = -1,
	RESULT_QUOTA_DURATION_EXCEEDED = -2,
	RESULT_SOUND_DELAY = -3,
	RESULT_ADMINS_ONLY = -4,
}

enum
{
	FLAG_IGNORE_AMOUNT = 1,
	FLAGS_JOIN_SND = 2,
	FLAGS_EXIT_SND = 4
}

enum
{
	SOUND_TYPE_SPEECH,
	SOUND_TYPE_MP3,
	SOUND_TYPE_WAV,
	SOUND_TYPE_WAV_LOCAL
}

enum _:SOUND_DATA_BASE
{
	KEYWORD[TOK_LENGTH + 1],
	ADMIN_LEVEL_BASE,
	SOUND_AMOUNT,
	FLAGS,
	PLAY_COUNT_KEY,
	Array:SUB_INDEX
}
enum _:SOUND_DATA_SUB
{
	SOUND_FILE[TOK_LENGTH + 1],
	Float:DURATION,
	ADMIN_LEVEL,
	SOUND_TYPE,
	PLAY_COUNT
}
new Array:soundData

public plugin_init( )
{
	register_plugin("Sank Sounds Plugin", PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar("sanksounds_version", PLUGIN_VERSION, FCVAR_SERVER)
	new tmpStr[32]
	get_cvar_string("sanksounds_version", tmpStr, 31)
	if ( !equal(tmpStr, PLUGIN_VERSION) )
	{
		set_cvar_string("sanksounds_version", PLUGIN_VERSION)
	}
	
	register_concmd("amx_sound_reset", "amx_sound_reset", ACCESS_ADMIN, " <user | all> : Resets sound quota for ^"user^", or everyone if ^"all^"")
	register_concmd("amx_sound_add", "amx_sound_add", ACCESS_ADMIN, " <keyword> <dir/sound> : Adds a Word/Sound combo to the sound list")
	register_clcmd("amx_sound_help", "amx_sound_help")
	register_concmd("amx_sound", "amx_sound", ACCESS_ADMIN, " :  Turns sounds on/off")
	register_concmd("amx_sound_play", "amx_sound_play", ACCESS_ADMIN, " <dir/sound> : Plays sound to all users")
	register_concmd("amx_sound_reload", "amx_sound_reload", ACCESS_ADMIN, " : Reloads config file. Filename is optional. If no filename, default is loaded")
	register_concmd("amx_sound_remove", "amx_sound_remove", ACCESS_ADMIN, " <keyword> <dir/sound> : Removes a Word/Sound combo from the sound list. Must use quotes")
	register_concmd("amx_sound_write", "amx_sound_write", ACCESS_ADMIN, " :  Writes current sound configuration to file")
	register_concmd("amx_sound_debug", "amx_sound_debug", ACCESS_ADMIN, "prints the whole Word/Sound combo list")
	register_concmd("amx_sound_ban", "amx_sound_ban", ACCESS_ADMIN, " <name or #userid>: Bans player from using sounds for current map")
	register_concmd("amx_sound_unban", "amx_sound_unban", ACCESS_ADMIN, " <name or #userid>: Unbans player from using sounds for current map")
	register_concmd("amx_sound_top", "amx_sound_top", ACCESS_ADMIN, " <number> (optional): Shows the top X (default 10) most used keywords during this map")
	
	register_clcmd("say", "HandleSay")
	register_clcmd("say_team", "HandleSay")
	
	register_cvar("mp_sank_sounds_download", "1")
	register_cvar("mp_sank_sounds_motd_address", "")
	
	g_max_players = get_maxplayers()
	NextSoundTime = get_gametime() - SND_DELAY
	LastSoundTime = NextSoundTime  
	
	array_initialize()
	modSearchPaths = ArrayCreate(64)
	
	new tmpLen = strlen(Enable_Sound)
	if ( tmpLen > 4
		&& equali(Enable_Sound[tmpLen - 4], ".wav") )
	{
		Enable_Sound[tmpLen - 4] = 0
	}
	tmpLen = strlen(Disable_Sound)
	if ( tmpLen > 4
		&& equali(Disable_Sound[tmpLen - 4], ".wav") )
	{
		Disable_Sound[tmpLen - 4] = 0
	}
}

public plugin_cfg( )
{
	get_cvar_string("mp_sank_sounds_motd_address", motd_sound_list_address, 255)
	
	new configpath[61]
	get_configsdir(configpath, 60)
	format(config_filename, 127, "%s/SND-LIST.CFG", configpath)	// Name of file to parse
	
	// check if file in capital letter exists
	// otherwise make it all lowercase and try to load it
	if ( file_exists(config_filename) )
	{
		parse_sound_file(config_filename)
	}else
	{
		strtolower(config_filename)
		parse_sound_file(config_filename)
	}
}

public client_putinserver( id )
{
	restrict_playing_sounds[id] = -1
	
	new steamid[60], i
	get_user_authid(id, steamid, 59)
	for ( i = 0; i < MAX_BANS; ++i )
	{
		if ( equal(steamid, banned_player_steamids[i]) )
			restrict_playing_sounds[id] = i
	}
	
	if ( !equal(steamid, sound_quota_steamids[id]) )
	{
		copy(sound_quota_steamids[id], 59, steamid)
		SndCount[id] = 0
		SndLenghtCount[id] = 0.0
	}
	
	SndOn[id] = 1
	
	new Float:gametime = get_gametime()
	if ( gametime <= FREEZE_TIME_CON )
		return
	
	new sData[SOUND_DATA_BASE]
	ArrayGetArray(soundData, 0, sData)
	if ( sData[SOUND_AMOUNT] == 0 )
		return
	
	if ( Join_exit_SoundTime >= gametime )
		return
	
	if ( sData[SOUND_AMOUNT] == 0 )
		return
	
	new rand = random(sData[SOUND_AMOUNT])
	new subData[SOUND_DATA_SUB]
	ArrayGetArray(sData[SUB_INDEX], rand, subData)
	
	if ( subData[ADMIN_LEVEL] != 0
		&& !(get_user_flags(id) & subData[ADMIN_LEVEL]) )
		return
	
	playsoundall(subData[SOUND_FILE], subData[SOUND_TYPE])
	
	Join_exit_SoundTime = gametime + subData[DURATION]
	if ( NextSoundTime < Join_exit_SoundTime )
		NextSoundTime = Join_exit_SoundTime
}

#if AMXX_VERSION_NUM < 183
public client_disconnect( id )
#else
public client_disconnected( id )
#endif
{
	SndOn[id] = 1
	restrict_playing_sounds[id] = -1
	
	new Float:gametime = get_gametime()
	if ( gametime <= FREEZE_TIME_CON )
		return
	
	new sData[SOUND_DATA_BASE]
	ArrayGetArray(soundData, 1, sData)
	if ( sData[SOUND_AMOUNT] == 0 )
		return
	
	if ( Join_exit_SoundTime >= gametime )
		return
	
	if ( sData[SOUND_AMOUNT] == 0 )
		return
	
	new rand = random(sData[SOUND_AMOUNT])
	new subData[SOUND_DATA_SUB]
	ArrayGetArray(sData[SUB_INDEX], rand, subData)
	
	if ( subData[ADMIN_LEVEL] != 0
		&& !(get_user_flags(id) & subData[ADMIN_LEVEL]) )
		return
	
	playsoundall(subData[SOUND_FILE], subData[SOUND_TYPE])
	
	Join_exit_SoundTime = gametime + subData[DURATION]
	if ( NextSoundTime < Join_exit_SoundTime )
		NextSoundTime = Join_exit_SoundTime
}

public amx_sound_reset( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
	
	new arg[33], target
	read_argv(1, arg, 32)
	if ( equal(arg, "all") == 1 )
	{
		client_print(id, print_console, "Sank Sounds >> Quota has been reseted for all players")
		for ( target = 1; target <= g_max_players; ++target )
		{
			SndCount[target] = 0
			SndLenghtCount[target] = 0.0
		}
	}else
	{
		target = cmd_target(id, arg, 1)
		if ( !target )
			return PLUGIN_HANDLED
		
		SndCount[target] = 0
		SndLenghtCount[target] = 0.0
		new name[33]
		get_user_name(target, name, 32)
		client_print(id, print_console, "Sank Sounds >> Quota has been reseted for ^"%s^"", name)
	}
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Adds a Word/Sound combo to the list. If it is a valid line in the config
// file, then it is a valid parameter here. The only difference is you can
// only specify one Sound file at a time with this command.
//
// Usage: amx_sound_add <keyword> <dir/sound>
// Usage: amx_sound_add <setting> <value>
//////////////////////////////////////////////////////////////////////////////
public amx_sound_add( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
	
	new Word[TOK_LENGTH + 1], Sound[TOK_LENGTH + 1]
	new configOption = 0
	
	read_argv(1, Word, TOK_LENGTH)
	read_argv(2, Sound, TOK_LENGTH)
	if ( strlen(Word) <= 0
		|| strlen(Sound) == 0 )
	{
		client_print(id, print_console, "Sank Sounds >>Invalid format")
		client_print(id, print_console, "Sank Sounds >>USAGE: amx_sound_add keyword <dir/sound>")
		
		return PLUGIN_HANDLED
	}
	
	// First look for special parameters
	if ( equali(Word, "SND_MAX") )
	{
		SND_MAX = str_to_num(Sound)
		configOption = 1
	}else if ( equali(Word, "SND_MAX_DUR") )
	{
		SND_MAX_DUR = floatstr(Sound)
		configOption = 1
	}else if ( equali(Word, "SND_WARN") )
	{
		SND_WARN = str_to_num(Sound)
		configOption = 1
	}else if ( equali(Word, "SND_DELAY") )
	{
		SND_DELAY = floatstr(Sound)
		configOption = 1
	}else if ( equali(Word, "SND_MODE") )
	{
		SND_MODE = str_to_num(Sound)
		configOption = 1
	}else if ( equali(Word, "SND_IMMUNITY") )
	{
		SND_IMMUNITY = str_to_num(Sound)
		configOption = 1
	}else if ( equali(Word, "SND_OBEY_DUR") )
	{
		SND_OBEY_DUR = str_to_num(Sound)
		configOption = 1
	}else if ( equali(Word, "EXACT_MATCH") )
	{
		EXACT_MATCH = str_to_num(Sound)
		configOption = 1
	}else if ( equali(Word, "ADMINS_ONLY") )
	{
		ADMINS_ONLY = str_to_num(Sound)
		configOption = 1
	}else if ( equali(Word, "DISPLAY_KEYWORDS") )
	{
		DISPLAY_KEYWORDS = str_to_num(Sound)
		configOption = 1
	}else if ( equali(Word, "FREEZE_TIME_CON") )
	{
		FREEZE_TIME_CON = str_to_num(Sound)
		configOption = 1
	}
	
	if ( configOption )
	{
		// Do some error checking on the user-input numbers
		ErrorCheck()
		
		return PLUGIN_HANDLED
	}
	
	// Loop once for each keyword
	new i, j
	new sData[SOUND_DATA_BASE]
	new subData[SOUND_DATA_SUB]
	new aLen = ArraySize(soundData)
	new subLen
	new resCode
	for( i = 0; i < aLen; ++i )
	{
		ArrayGetArray(soundData, i, sData)
		// If no match found, keep looping
		if ( !equal(Word, sData[KEYWORD], TOK_LENGTH) )
			continue
		
		// See if the Sound already exists
		subLen = ArraySize(sData[SUB_INDEX])
		for( j = 0; j < subLen; ++j )
		{
			ArrayGetArray(sData[SUB_INDEX], j, subData)
			// See if this is the same as the new Sound
			if ( equali(Sound, subData[SOUND_FILE], TOK_LENGTH) )
			{
				client_print(id, print_console, "Sank Sounds >> ^"%s; %s^" already exists", Word, Sound)
				
				return PLUGIN_HANDLED
			}
		}
		
		// Word exists, but Sound is new to the list, so add entry
		resCode = array_add_inner_element(i, j, Sound, 0)
		if ( resCode != -1 )
			client_print(id, print_console, "Sank Sounds >> ^"%s^" successfully added to ^"%s^"", Sound, Word)
		
		return PLUGIN_HANDLED
	}
	
	// Word/Sound combo is new to the list, so make a new entry
	resCode = -1
	new arrayIndex = array_add_element(Word)
	resCode = array_add_inner_element(arrayIndex, 0, Sound, 0)
	if ( resCode != -1 )
	{
		ArraySort(soundData, "sortSoundDataFunc")
		client_print(id, print_console, "Sank Sounds >> ^"%s; %s^" successfully added", Word, Sound)
	}else
	{
		// removed keyword because no sound could be added
		array_remove(i)
	}
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// amx_sound_help lists all amx_sound commands and keywords to the user.
//
// Usage: amx_sound_help
//////////////////////////////////////////////////////////////////////////////
public amx_sound_help( id )
{
	print_sound_list(id)
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Turns on/off the playing of the Sound files for this plugin only
//////////////////////////////////////////////////////////////////////////////
public amx_sound( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
	
	new onoff[5]
	read_argv(1, onoff, 4)
	if ( equal(onoff, "on")
		|| equal(onoff, "1") )
	{
		if ( bSoundsEnabled == 1 )
			console_print(id, "Sank Sounds >> Plugin already enabled")
		else
		{
			bSoundsEnabled = 1
			console_print(id, "Sank Sounds >> Plugin enabled")
			client_print(0, print_chat, "Sank Sounds >> Plugin has been enabled")
			if ( Enable_Sound[0] )
			{
				new type = Enable_Sound[0] == '^"' ? SOUND_TYPE_SPEECH : ( Enable_Sound[strlen(Enable_Sound) - 1] == '3' ? SOUND_TYPE_MP3 : SOUND_TYPE_WAV )
				playsoundall(Enable_Sound, type)
			}
		}
		
		return PLUGIN_HANDLED
	}else if ( equal(onoff, "off")
		|| equal(onoff, "0") )
	{
		if ( bSoundsEnabled == 0 )
			console_print(id, "Sank Sounds >> Plugin already disabled")
		else
		{
			bSoundsEnabled = 0
			console_print(id, "Sank Sounds >> Plugin disabled")
			client_print(0, print_chat, "Sank Sounds >> Plugin has been disabled")
			if ( Disable_Sound[0] )
			{
				new type = Disable_Sound[0] == '^"' ? SOUND_TYPE_SPEECH : ( Disable_Sound[strlen(Disable_Sound) - 1] == '3' ? SOUND_TYPE_MP3 : SOUND_TYPE_WAV )
				playsoundall(Disable_Sound, type)
			}
		}
	}
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Plays a sound to all players
//
// Usage: amx_sound_play <dir/sound>
//////////////////////////////////////////////////////////////////////////////
public amx_sound_play( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
	
	new arg[128]
	read_argv(1, arg, 127)
	
	new arg_len = strlen(arg)
	if ( arg_len < 1 )
	{
		client_print(id, print_console, "Sank Sounds >> Sound is invalid.")
		
		return PLUGIN_HANDLED
	}
	
	new type = arg[0] == '^"' ? SOUND_TYPE_SPEECH : ( arg[arg_len - 1] == '3' ? SOUND_TYPE_MP3 : SOUND_TYPE_WAV )
	if ( type == SOUND_TYPE_WAV
		&& arg_len > 4
		&& equali(arg[arg_len - 4], ".wav") ) // WAV with extension
	{
		arg[arg_len - 4] = 0
	}
	playsoundall(arg, type)
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Reloads the Word/Sound combos from filename
//
// Usage: amx_sound_reload <filename>
//////////////////////////////////////////////////////////////////////////////
public amx_sound_reload( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 0) )
		return PLUGIN_HANDLED
	
	new parsefile[128]
	read_argv(1, parsefile, 127)
	// Initialize sound_data array
	array_clear()
	array_initialize()
	
	parse_sound_file(parsefile, 0)
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Removes a Word/Sound combo from the list. You must specify a keyword, but it
// is not necessary to specify a Sound if you want to remove all Sounds associated
// with that keyword
//
// Usage: amx_sound_remove <keyWord> <dir/sound>"
//////////////////////////////////////////////////////////////////////////////
public amx_sound_remove( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
	
	new Word[TOK_LENGTH + 1], Sound[TOK_LENGTH + 1]
	
	read_argv(1, Word, TOK_LENGTH)
	read_argv(2, Sound, TOK_LENGTH)
	if ( strlen(Word) == 0 )
	{
		client_print(id, print_console, "Sank Sounds >> Invalid format")
		client_print(id, print_console, "Sank Sounds >> USAGE: amx_sound_remove keyword <dir/sound>")
		
		return PLUGIN_HANDLED
	}
	
	// speech must have extra ""
	if ( strlen(Sound) != 0
		&& containi(Sound, ".wav") == -1
		&& containi(Sound, ".mp") == -1 )
		format(Sound, TOK_LENGTH, "^"%s^"", Sound)
	
	// Loop once for each keyWord
	new iCurWord, jCurSound
	new sData[SOUND_DATA_BASE]
	new subData[SOUND_DATA_SUB]
	new aLen = ArraySize(soundData)
	new subLen
	for( iCurWord = 0; iCurWord < aLen; ++iCurWord )
	{
		ArrayGetArray(soundData, iCurWord, sData)
		// Look for a Word match
		if ( !equali(Word, sData[KEYWORD], TOK_LENGTH) )
			continue
		
		// If no Sound was specified, then remove the whole Word's entry
		if ( strlen(Sound) == 0 )
		{
			array_remove(iCurWord)
			
			client_print(id, print_console, "Sank Sounds >> %s successfully removed", Word)
			
			return PLUGIN_HANDLED
		}
		
		// Just remove the one Sound, if it exists
		subLen = ArraySize(sData[SUB_INDEX])
		for( jCurSound = 0; jCurSound < subLen; ++jCurSound )
		{
			ArrayGetArray(sData[SUB_INDEX], iCurWord, subData)
			// Look for a Sound match
			if ( !equali(Sound, subData[SOUND_FILE], TOK_LENGTH) )
				continue
			
			if ( sData[SOUND_AMOUNT] == 1 )		// If this is the only Sound entry, then remove the entry altogether
			{
				array_remove(iCurWord)
				
				client_print(id, print_console, "Sank Sounds >> %s successfully removed", Word)
			}else
			{
				array_remove_inner(iCurWord, jCurSound)
				
				client_print(id, print_console, "Sank Sounds >> %s successfully removed from %s", Sound, Word)
			}
			
			return PLUGIN_HANDLED
		}
		// We reached the end for this Word, and the Sound didn't exist
		client_print(id, print_console, "Sank Sounds >> %s not found", Sound)
		
		return PLUGIN_HANDLED
	}
	// We reached the end, and the Word didn't exist
	client_print(id, print_console, "Sank Sounds >> %s not found", Word)
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Saves the current configuration of Word/Sound combos to filename for possible
// reloading at a later time. You cannot overwrite the default file.
//
// Usage: amx_sound_write <filename>
//////////////////////////////////////////////////////////////////////////////
public amx_sound_write( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
	
	new savefile[128]
	
	read_argv(1, savefile, 127)
	if ( strlen(savefile) <= 1 )
	{
		if ( strlen(savefile) == 1
			&& savefile[0] == '!' )
			copy(savefile, 127, config_filename)
		else
		{
			client_print(id, print_console, "Sank Sounds >> You have not specified any filename. To save to default configfile use ! as filename/parameter.")
			return PLUGIN_HANDLED
		}
	}
	
	new TimeStamp[128], name[33], Text[64]
	new Textlen = 63
	get_user_name(id, name, 32)
	get_time("%H:%M:%S %A %B %d, %Y", TimeStamp, 127)
	
	new file = fopen(savefile, "w+")
	if ( !file )
	{
		log_amx("Sank Sounds >> Unable to read from ^"%s^" file", savefile)
		
		return PLUGIN_HANDLED
	}
	
	formatex(Text, Textlen, "# TimeStamp:^t^t%s^n", TimeStamp)
	fputs(file, Text)
	formatex(Text, Textlen, "# File created by:^t%s^n", name)
	fputs(file, Text)
	fputs(file, "^n")		// blank line
	fputs(file, "# Important parameters:^n")
	formatex(Text, Textlen, "SND_MAX;^t^t%d^n", SND_MAX)
	fputs(file, Text)
	formatex(Text, Textlen, "SND_MAX_DUR;^t^t%.1f^n", SND_MAX_DUR)
	fputs(file, Text)
	formatex(Text, Textlen, "SND_WARN;^t^t%d^n", SND_WARN)
	fputs(file, Text)
	
	new sData[SOUND_DATA_BASE]
	new subData[SOUND_DATA_SUB]
	ArrayGetArray(soundData, 0, sData);
	new subLen = ArraySize(sData[SUB_INDEX])
	fputs(file, "SND_JOIN;^t^t")
	for ( new j = 0; j < subLen; ++j )
	{
		ArrayGetArray(sData[SUB_INDEX], j, subData);
		cfg_write_keysound(file, subData)
	}
	fputc(file, '^n')
	ArrayGetArray(soundData, 1, sData);
	subLen = ArraySize(sData[SUB_INDEX])
	fputs(file, "SND_EXIT;^t^t")
	for ( new j = 0; j < subLen; ++j )
	{
		ArrayGetArray(sData[SUB_INDEX], j, subData);
		cfg_write_keysound(file, subData)
	}
	fputc(file, '^n')
	formatex(Text, Textlen, "SND_DELAY;^t^t%f^n", SND_DELAY)
	fputs(file, Text)
	formatex(Text, Textlen, "SND_MODE;^t^t%d^n", SND_MODE)
	fputs(file, Text)
	new snd_imm_str[32]
	get_flags(SND_IMMUNITY, snd_imm_str, 26)
	formatex(Text, Textlen, "SND_IMMUNITY;^t^t^"%s^"^n", snd_imm_str)
	fputs(file, Text)
	formatex(Text, Textlen, "SND_OBEY_DUR;^t^t%d^n", SND_OBEY_DUR)
	fputs(file, Text)
	formatex(Text, Textlen, "EXACT_MATCH;^t^t%d^n", EXACT_MATCH)
	fputs(file, Text)
	formatex(Text, Textlen, "ADMINS_ONLY;^t^t%d^n", ADMINS_ONLY)
	fputs(file, Text)
	formatex(Text, Textlen, "DISPLAY_KEYWORDS;^t%d^n", DISPLAY_KEYWORDS)
	fputs(file, Text)
	formatex(Text, Textlen, "FREEZE_TIME_CON;^t%d^n", FREEZE_TIME_CON)
	fputs(file, Text)
	fputs(file, "^n")		// blank line
	fputs(file, "# Word/Sound combinations:^n")
	
	new aLen = ArraySize(soundData)
	new j
	for ( new i = 2; i < aLen; ++i )	// first 2 elements are reserved for Join / Exit sounds
	{
		ArrayGetArray(soundData, i, sData);
		
		cfg_write_keyword(file, sData)
		subLen = ArraySize(sData[SUB_INDEX])
		for ( j = 0; j < subLen; ++j )
		{
			ArrayGetArray(sData[SUB_INDEX], j, subData);
			cfg_write_keysound(file, subData)
		}
		fputc(file, '^n')
	}
	
	fclose(file)
	
	client_print(id, print_console, "Sank Sounds >> Configuration successfully written to %s", savefile)
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Prints out Word/Sound combo matrix for debugging purposes. Kinda cool, even
// if you're not really debugging.
//
// Usage: amx_sound_debug
// Usage: amx_sound_reload <filename>
//////////////////////////////////////////////////////////////////////////////
public amx_sound_debug( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 1)
		&& id > 0 )
		return PLUGIN_HANDLED
	
	new i, j, join_snd_buff[BUFFER_LEN], exit_snd_buff[BUFFER_LEN]
	
	if ( !is_dedicated_server()
		&& id == 1 )	// for listenserver and with id = 1 we can use server_print
		id = 0
	
	if ( id )
		client_print(id, print_console, "SND_WARN: %d^nSND_MAX: %d^nSND_MAX_DUR: %5.1f^n", SND_WARN, SND_MAX, SND_MAX_DUR)
	else
		server_print("SND_WARN: %d^nSND_MAX: %d^nSND_MAX_DUR: %5.1f", SND_WARN, SND_MAX, SND_MAX_DUR)
	
	new sData[SOUND_DATA_BASE]
	new subData[SOUND_DATA_SUB]
	new aLen = ArraySize(soundData)
	new subLen
	ArrayGetArray(soundData, 0, sData)
	subLen = ArraySize(sData[SUB_INDEX])
	new tempstr[TOK_LENGTH]
	for( i = 0; i < subLen; ++i )
	{
		ArrayGetArray(sData[SUB_INDEX], i, subData)
		formatex(tempstr, TOK_LENGTH, "%s;", subData[SOUND_FILE])
		add(join_snd_buff, BUFFER_LEN, tempstr)
	}
	ArrayGetArray(soundData, 1, sData)
	subLen = ArraySize(sData[SUB_INDEX])
	for( i = 0; i < subLen; ++i )
	{
		ArrayGetArray(sData[SUB_INDEX], i, subData)
		formatex(tempstr, TOK_LENGTH, "%s;", subData[SOUND_FILE])
		add(exit_snd_buff, BUFFER_LEN, tempstr)
	}
	
	new snd_imm_str[32]
	get_flags(SND_IMMUNITY, snd_imm_str, 26)
	if ( id )
	{
		client_print(id, print_console, "SND_JOIN: %s", join_snd_buff)
		client_print(id, print_console, "SND_EXIT: %s", exit_snd_buff)
		client_print(id, print_console, "SND_DELAY: %f^nSND_MODE: %d^nSND_IMMUNITY: %s^nSND_OBEY_DUR: %d^nEXACT_MATCH: %d", SND_DELAY, SND_MODE, snd_imm_str, SND_OBEY_DUR, EXACT_MATCH)
		client_print(id, print_console, "ADMINS_ONLY: %d^nDISPLAY_KEYWORDS: %d^nFREEZE_TIME_CON: %d", ADMINS_ONLY, DISPLAY_KEYWORDS, FREEZE_TIME_CON)
	}else
	{
		server_print("SND_JOIN: %s", join_snd_buff)
		server_print("SND_EXIT: %s", exit_snd_buff)
		server_print("SND_DELAY: %f^nSND_MODE: %d^nSND_IMMUNITY: %s^nSND_OBEY_DUR: %d^nEXACT_MATCH: %d", SND_DELAY, SND_MODE, snd_imm_str, SND_OBEY_DUR, EXACT_MATCH)
		server_print("ADMINS_ONLY: %d^nDISPLAY_KEYWORDS: %d^nFREEZE_TIME_CON: %d", ADMINS_ONLY, DISPLAY_KEYWORDS, FREEZE_TIME_CON)
	}
	
	// Print out the matrix of sound data, so we got what we think we did
	for( i = 2; i < aLen; ++i )	// first 2 elements are reserved for Join / Exit sounds
	{
		ArrayGetArray(soundData, i, sData)
		
		new access_level[32]
		get_flags(sData[ADMIN_LEVEL_BASE], access_level, 31)
		if ( id )
			client_print(id, print_console, "^n[%d] ^"%s^" with %d sound%s and level ^"%s^" (played: %d)", i - 2, sData[KEYWORD], sData[SOUND_AMOUNT], sData[SOUND_AMOUNT] > 1 ? "s" : "", access_level, sData[PLAY_COUNT_KEY])
		else
			server_print("^n[%d] ^"%s^" with %d sound%s and level ^"%s^" (played: %d)", i - 2, sData[KEYWORD], sData[SOUND_AMOUNT], sData[SOUND_AMOUNT] > 1 ? "s" : "", access_level, sData[PLAY_COUNT_KEY])
		subLen = ArraySize(sData[SUB_INDEX])
		for( j = 0; j < subLen; ++j )
		{
			ArrayGetArray(sData[SUB_INDEX], j, subData)
			
			get_flags(subData[ADMIN_LEVEL], access_level, 31)
			if ( id )
				client_print(id, print_console, " ^"%s^" - time: %5.2f - admin level ^"%s^" (played: %d)", subData[SOUND_FILE], subData[DURATION], access_level, subData[PLAY_COUNT])
			else
				server_print(" ^"%s^" - time: %5.2f - admin level ^"%s^" (played: %d)", subData[SOUND_FILE], subData[DURATION], access_level, subData[PLAY_COUNT])
		}
	}
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Bans players from using sounds for current map
//
// Usage: amx_sound_ban <player>
//////////////////////////////////////////////////////////////////////////////
public amx_sound_ban( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
	
	new arg[33]
	read_argv(1, arg, 32)
	new player = cmd_target(id, arg, 1)
	if ( !player )
		return PLUGIN_HANDLED
	
	if ( get_user_flags(player) & (SND_IMMUNITY | ACCESS_ADMIN) )
		return PLUGIN_HANDLED
	
	if ( restrict_playing_sounds[player] == -1 )
	{
		new found, empty = -1
		new steamid[60]
		get_user_authid(id, steamid, 59)
		for ( new i = 0; i < MAX_BANS; ++i )
		{
			if ( empty == -1
				&& !banned_player_steamids[i][0] )
				empty = i
			
			if ( !equal(steamid, banned_player_steamids[i]) )
				continue
			
			found = 1
			
			break
		}
		if ( !found )
		{
			if ( empty == -1 )
				empty = 0
			
			copy(banned_player_steamids[empty], 59, steamid)
			
			restrict_playing_sounds[player] = empty
		}
	}
	
	new name[33]
	get_user_name(player, name, 32)
	client_print(id, print_console, "Sank Sounds >> Player ^"%s^" has been banned from using sounds", name)
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Unbans players from using sounds for current map
//
// Usage: amx_sound_unban <player>
//////////////////////////////////////////////////////////////////////////////
public amx_sound_unban( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
	
	new arg[33]
	read_argv(1, arg, 32)
	new player = cmd_target(id, arg)
	if ( !player )
		return PLUGIN_HANDLED
	
	if ( restrict_playing_sounds[player] != -1 )
	{
		new found = -1
		new steamid[60]
		get_user_authid(id, steamid, 59)
		for ( new i = 0; i < MAX_BANS; ++i )
		{
			if ( !equal(steamid, banned_player_steamids[i]) )
				continue
			
			found = i
			
			break
		}
		if ( found != -1 )
			banned_player_steamids[found][0] = 0
		
		restrict_playing_sounds[player] = -1
	}
	
	new name[33]
	get_user_name(player, name, 32)
	client_print(id, print_console, "Sank Sounds >> Player ^"%s^" has been unbanned from using sounds", name)
	
	return PLUGIN_HANDLED
}

public amx_sound_top( id , level , cid )
{
	if ( !cmd_access(id, level, cid, 1) )
		return PLUGIN_HANDLED
	
	new arg[33]
	read_argv(1, arg, 32)
	new topX = 10
	if ( strlen(arg) > 0 )
		topX = str_to_num(arg)
	
	if ( topX < 1
		|| topX > 50 )
	{
		client_print(id, print_console, "Sank Sounds >> Set a value from 1 to 50 or leave it blank")
		return PLUGIN_HANDLED
	}
	
	new topIDs[50] = {-1, ...}
	new topCount[50] = {0, ...}
	new sData[SOUND_DATA_BASE]
	new aLen = ArraySize(soundData)
	for ( new keyIndex = 0; keyIndex < aLen; ++keyIndex )
	{
		ArrayGetArray(soundData, keyIndex, sData)
		
		for ( new i = 0; i < topX; ++i )
		{
			if ( sData[PLAY_COUNT_KEY] <= topCount[i] )
				continue
			
			// copy all other down
			for ( new j = topX - 1; j > i; --j )
			{
				topIDs[j] = topIDs[j - 1]
				topCount[j] = topCount[j - 1]
			}
			topIDs[i] = keyIndex
			topCount[i] = sData[PLAY_COUNT_KEY]
			break
		}
	}
	new text[512]
	new counter = 0
	client_print(id, print_console, "Sank Sounds >> Top %d:", topX)
	while ( counter < topX )
	{
		if ( topIDs[counter] != -1 )
		{
			ArrayGetArray(soundData, topIDs[counter], sData)
			format(text, 511, "%s(%d) %s^n", text, topCount[counter], sData[KEYWORD])
		}else
			counter = topX - 1
		if ( (counter % 10 == 0
				&& counter != 0 )
			|| counter == topX - 1 )
		{
			client_print(id, print_console, text)
			text[0] = 0
		}
		++counter
	}
	
	return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////
// Everything a person says goes through here, and we determine if we want to
// play a sound or not.
//
// Usage: say <anything>
//////////////////////////////////////////////////////////////////////////////
public HandleSay( id )
{
	// If sounds are not enabled, then skip this whole thing
	if ( !bSoundsEnabled )
		return PLUGIN_CONTINUE
	
	// player is banned from playing sounds
	if ( restrict_playing_sounds[id] != -1 )
		return PLUGIN_CONTINUE
	
	new Speech[128]
	read_args(Speech, 127)
	remove_quotes(Speech)
	
	// credit to SR71Goku for fixing this oversight:
	new speachLen = strlen(Speech)
	if ( !speachLen )
		return PLUGIN_CONTINUE
	
	if ( equal(Speech, "/sound", 6) )
	{
		if ( Speech[6] == 's' )
		{
			if ( Speech[7] == 'o'
				&& Speech[8] == 'n'
				&& Speech[9] == 0 )
			{
				SndOn[id] = 1
				client_print(id, print_chat, "Sank Sounds >> You will hear all sounds again")
			}else if ( Speech[7] == 'o'
				&& Speech[8] == 'f'
				&& Speech[9] == 'f'
				&& Speech[10] == 0 )
			{
				SndOn[id] = 0
				client_print(id, print_chat, "Sank Sounds >> I will stop playing sounds for you")
			}else if ( Speech[7] == 0 )
				print_sound_list(id, 1)
			else
				return PLUGIN_CONTINUE
			
			return PLUGIN_HANDLED
		}else if ( Speech[6] == 'l'
			&& Speech[7] == 'i'
			&& Speech[8] == 's'
			&& Speech[9] == 't'
			&& Speech[10] == 0 )
		{
			print_sound_list(id, 1)
			
			return PLUGIN_HANDLED
		}
		
		return PLUGIN_CONTINUE
	}
	
	new ListIndex = -1
	new pinToLocation = (Speech[speachLen - 1] == '!')
	new sData[SOUND_DATA_BASE]
	new subData[SOUND_DATA_SUB]
	new aLen = ArraySize(soundData)
	// Check to see if what the player said is a trigger for a sound
	for ( new i = 2; i < aLen; ++i )	// first 2 elements are reserved for Join / Exit sounds
	{
		ArrayGetArray(soundData, i, sData)
		
		if ( equali(Speech, sData[KEYWORD])
			|| (EXACT_MATCH == 1
				&& pinToLocation == 1
				&& speachLen == strlen(sData[KEYWORD]) + 1
				&& equali(Speech, sData[KEYWORD], speachLen - 1) )
			|| ( EXACT_MATCH == 0
				&& containi(Speech, sData[KEYWORD]) != -1 ) )
		{
			// check for access
			if ( sData[ADMIN_LEVEL_BASE] == 0
				|| get_user_flags(id) & sData[ADMIN_LEVEL_BASE] )
				ListIndex = i
			
			break
		}
	}
	
	// check If player used NO sound trigger
	if ( ListIndex == -1 )
		return PLUGIN_CONTINUE
	
	if ( sData[SOUND_AMOUNT] == 0 )
		return PLUGIN_CONTINUE
	
	new Float:gametime = get_gametime()
	new allowedToPlay = isUserAllowed2Play(id, gametime)
	if ( allowedToPlay == RESULT_OK )
	{
		displayQuotaWarning(id)
		new rand
		new timeout
		
		// This for loop runs around until it finds a real file to play
		// Defaults to the first Sound file, if no file is found at random.
		new foundFile = false
		for( timeout = MAX_RANDOM;			// Initial condition
			timeout >= 0;	// While these are true
			--timeout )				// Update each iteration
		{
			rand = random(sData[SOUND_AMOUNT])
			ArrayGetArray(sData[SUB_INDEX], rand, subData)
			// check if sound has access defined, if so only allow admins to use it
			if ( subData[ADMIN_LEVEL] == 0
				|| ( get_user_flags(id) & subData[ADMIN_LEVEL] ) )
			{
				foundFile = true
				break;
			}
		}
		if ( foundFile )
		{
			NextSoundTime = gametime + subData[DURATION]
			
			// Increment their playsound count
			++SndCount[id]
			SndLenghtCount[id] += subData[DURATION]
			
			// increment counter
			++sData[PLAY_COUNT_KEY]
			++subData[PLAY_COUNT]
			
			new type = subData[SOUND_TYPE]
			if ( pinToLocation == 1
				&& type == SOUND_TYPE_WAV )
				type = SOUND_TYPE_WAV_LOCAL
			playsoundall(subData[SOUND_FILE], type, SND_MODE & 16, is_user_alive(id))
			
			LastSoundTime = gametime
			ArraySetArray(sData[SUB_INDEX], rand, subData)
			ArraySetArray(soundData, ListIndex, sData)
		}
	}else if ( allowedToPlay == RESULT_QUOTA_EXCEEDED
		|| allowedToPlay == RESULT_QUOTA_DURATION_EXCEEDED
		|| allowedToPlay == RESULT_SOUND_DELAY )
	{
		if ( !displayQuotaExceeded(id) )
		{
			if ( allowedToPlay == RESULT_SOUND_DELAY )
				client_print(id, print_chat, "Sank Sounds >> Sound is still playing ( wait %3.1f seconds )", NextSoundTime + SND_DELAY - gametime)
			else if ( allowedToPlay != RESULT_QUOTA_EXCEEDED
				&& allowedToPlay != RESULT_QUOTA_DURATION_EXCEEDED )
				client_print(id, print_chat, "Sank Sounds >> Do not use sounds too often ( wait %3.1f seconds )", LastSoundTime + SND_DELAY - gametime)
		}
	}
	
	if ( DISPLAY_KEYWORDS == 0 )
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

//////////////////////////////////////////////////////////////////////////////
// Parses the sound file specified by loadfile. If loadfile is empty, then
// it parses the default config_filename.
//////////////////////////////////////////////////////////////////////////////
parse_sound_file( loadfile[] , precache_sounds = 1 )
{
	if ( !strlen(loadfile) )
		copy(loadfile, 127, config_filename)
	
	if ( !file_exists(loadfile) )
	{
		// file does not exist
		log_amx("Sank Sounds >> Cannot find ^"%s^" file", loadfile)
		
		return
	}
	
	new current_package_str[4]
	new current_package, package_num
	if ( vaultdata_exists("sank_sounds_current_package") )
	{
		get_vaultdata("sank_sounds_current_package", current_package_str, 3)
		current_package = str_to_num(current_package_str)
	}
	
	new allowed_to_precache = 1, allow_check_existence = 1, allow_to_use_sounds = 1
	new allow_global_precache = get_cvar_num("mp_sank_sounds_download")
	new mapname[32]
	get_mapname(mapname, 31)
	
	new i
	new ListIndex = -1
	new maxLineBuf_len = BUFFER_LEN - 1
	new strLineBuf[BUFFER_LEN]
	
	new error_code = ERROR_NONE
	new parse_option = PARSE_KEYWORD
	new temp_str[128]
	new check_for_semi
	new position
	
	new sData[SOUND_DATA_BASE]
	
	new file = fopen(loadfile, "r")
	if ( !file )
	{
		log_amx("Sank Sounds >> Unable to read from ^"%s^" file", loadfile)

		return
	}
	
	while ( fgets(file, strLineBuf, maxLineBuf_len) )
	{
		if ( (strLineBuf[0] == '^n')						// empty line
			|| ( strLineBuf[0] == 10 && strLineBuf[1] == '^n' )		// empty line
			|| ( strLineBuf[0] == '/' && strLineBuf[1] == '/' )		// comment
			|| (strLineBuf[0] == '#') )					// another comment
			continue
		
		trim(strLineBuf)	// remove newline and spaces
		
		if ( equali(strLineBuf, "package ", 8) )
		{
			++package_num
			if ( current_package )
			{
				if ( current_package == str_to_num(strLineBuf[8]) )
					allowed_to_precache = 1
				else
					allowed_to_precache = 0
			}else
			{
				current_package = 1
				allowed_to_precache = 1
			}
			
			allow_to_use_sounds = 1
			allow_check_existence = 1
			
			continue
		}else if ( equali(strLineBuf, "mapname ", 8) )
		{
			if ( equali(strLineBuf[8], mapname) )
				allowed_to_precache = 1
			else
				allowed_to_precache = 0
			
			allow_to_use_sounds = 1
			allow_check_existence = 1
			
			continue
		}else if ( equali(strLineBuf, "mapnameonly ", 12) )
		{
			if ( equali(strLineBuf[12], mapname) )
			{
				allowed_to_precache = 1
				allow_to_use_sounds = 1
			}else
			{
				allowed_to_precache = 0
				allow_to_use_sounds = 0
			}
			
			allow_check_existence = 1
			
			continue
		}else if ( equali(strLineBuf, "modspecific", 11) )
		{
			allow_to_use_sounds = 1
			allow_check_existence = 0
			
			continue
		}
		
		if ( !allow_to_use_sounds )	// check for sounds that can be used only on specified map
			continue
		
		ListIndex = -1
		error_code = ERROR_NONE
		position = 0
		for( i = 0; ; ++i )
		{
			// check if reached end of buffer ( input has been parsed )
			if ( position >= strlen(strLineBuf) )
			{
				strLineBuf[0] = 0
				break
			}
			
			temp_str[0] = 0		// reset
			check_for_semi = contain(strLineBuf[position], ";")
			if ( check_for_semi != -1 )
			{
				copyc(temp_str, 127, strLineBuf[position], ';')
				position += check_for_semi + 1
			}else
			{
				copy(temp_str, 127, strLineBuf[position])
				position += strlen(temp_str)
			}
			
			// Now remove any spaces or tabs from around the strings -- clean them up
			trim(temp_str)
			
			// check if file length is bigger than array
			if ( strlen(temp_str) > TOK_LENGTH )
			{
				error_code = ERROR_STRING_LENGTH
				
				break
			}
			
			if ( i == 0 )
			{	// first entry is not a sound file
				if ( equali(temp_str, "SND_MAX") )
					parse_option = PARSE_SND_MAX
				else if ( equali(temp_str, "SND_MAX_DUR") )
					parse_option = PARSE_SND_MAX_DUR
				else if ( equali(temp_str, "SND_WARN") )
					parse_option = PARSE_SND_WARN
				else if ( equali(temp_str, "SND_DELAY") )
					parse_option = PARSE_SND_DELAY
				else if ( equali(temp_str, "SND_MODE") )
					parse_option = PARSE_SND_MODE
				else if ( equali(temp_str, "SND_IMMUNITY") )
					parse_option = PARSE_SND_IMMUNITY
				else if ( equali(temp_str, "SND_OBEY_DUR") )
					parse_option = PARSE_SND_OBEY_DUR
				else if ( equali(temp_str, "EXACT_MATCH") )
					parse_option = PARSE_EXACT_MATCH
				else if ( equali(temp_str, "ADMINS_ONLY") )
					parse_option = PARSE_ADMINS_ONLY
				else if ( equali(temp_str, "DISPLAY_KEYWORDS") )
					parse_option = PARSE_DISPLAY_KEYWORDS
				else if ( equali(temp_str, "FREEZE_TIME_CON") )
					parse_option = PARSE_FREEZE_TIME_CON
				else
				{
					parse_option = PARSE_KEYWORD
					ListIndex = array_add_element(temp_str)
				}
			}else
			{
				switch ( parse_option )
				{
					case PARSE_SND_MAX:
					{
						SND_MAX = str_to_num(temp_str)
					}
					case PARSE_SND_MAX_DUR:
					{
						SND_MAX_DUR = floatstr(temp_str)
					}
					case PARSE_SND_WARN:
					{
						SND_WARN = str_to_num(temp_str)
					}
					case PARSE_SND_DELAY:
					{
						SND_DELAY = floatstr(temp_str)
					}
					case PARSE_SND_MODE:
					{
						SND_MODE = str_to_num(temp_str)
					}
					case PARSE_SND_IMMUNITY:
					{
						if ( temp_str[0] == '^"' )
						{
							new temp_str2[32]
							copyc(temp_str2, 31, temp_str[1], '^"')
							if ( strlen(temp_str2) == 0 )
								SND_IMMUNITY = (1<<30)
							else
								SND_IMMUNITY = read_flags(temp_str2)
						}else
							SND_IMMUNITY = read_flags(temp_str)
					}
					case PARSE_SND_OBEY_DUR:
					{
						SND_OBEY_DUR = str_to_num(temp_str)
					}
					case PARSE_EXACT_MATCH:
					{
						EXACT_MATCH = str_to_num(temp_str)
					}
					case PARSE_ADMINS_ONLY:
					{
						ADMINS_ONLY = str_to_num(temp_str)
					}
					case PARSE_DISPLAY_KEYWORDS:
					{
						DISPLAY_KEYWORDS = str_to_num(temp_str)
					}
					case PARSE_FREEZE_TIME_CON:
					{
						FREEZE_TIME_CON = str_to_num(temp_str)
					}
					case PARSE_KEYWORD:
					{
						new error_value = array_add_inner_element(ListIndex, i - 1, temp_str, allow_check_existence, allow_global_precache, precache_sounds, allowed_to_precache)
						if ( error_value == -1 )
						{
							// sound could not be added
							continue
						}
					}
				}
			}
		}
		
		if ( ListIndex != -1 )
		{
			ArrayGetArray(soundData, ListIndex, sData)
			if ( sData[SOUND_AMOUNT] == 0
				&& !(sData[FLAGS] & FLAG_IGNORE_AMOUNT) )	// check if allowed to ignore amount of sounds ( eg: SND_JOIN / SND_EXIT )
			{
				log_amx("Sank Sounds >> Found keyword without any valid sound. Skipping this keyword: ^"%s^"", sData[KEYWORD])
				array_remove(ListIndex)
			}
		}
		
		if ( error_code == ERROR_STRING_LENGTH )
		{
			log_amx("Sank Sounds >> Skipping this word/sound combo. Word or Sound is too long: ^"%s^". Length is %i but max is %i (change name/remove spaces in config or increase TOK_LENGTH)", temp_str, strlen(temp_str), TOK_LENGTH)
			
			continue
		}
		if ( error_code != ERROR_NONE )
		{
			log_amx("Sank Sounds >> Fatal Error")
			
			continue
		}
		
		// If we finished MAX_RANDOM times, and strLineBuf[position] still has contents
		// then we should have a bigger MAX_RANDOM
		else if ( position < strlen(strLineBuf) )
		{
			log_amx("Sank Sounds >> Sound list partially truncated. Increase MAX_RANDOM. Continuing to parse file ^"%s^"^n", loadfile)
		}
	}
	
	fclose(file)
	
	// Now we have all of the data from the text file in our data structures.
	// Next we do some error checking, some setup, and we're done parsing!
	ErrorCheck()
	
	++current_package
	if ( current_package > package_num )
		current_package = 1
	
	num_to_str(current_package, current_package_str, 3)
	set_vaultdata("sank_sounds_current_package", current_package_str)
	
#if ALLOW_SORT == 1
	ArraySort(soundData, "sortSoundDataFunc")
#endif
}

//////////////////////////////////////////////////////////////////////////////
// Returns status indicating if user is allowed to play a sound
// or the reason why he is not
//////////////////////////////////////////////////////////////////////////////
isUserAllowed2Play( id , Float:gametime )
{
	// order of checks is important
	
	new admin_flags = get_user_flags(id)
	new will_sound_overlap = gametime < NextSoundTime + SND_DELAY
	
	// check if super admin
	if ( admin_flags & ADMIN_RCON )
	{
		// check if super admin has to obey duration
		if ( !will_sound_overlap
			|| !(SND_OBEY_DUR & 4) )
			return RESULT_OK
		return RESULT_SOUND_DELAY
	}
	
	// check if only admins can play sounds
	if ( ADMINS_ONLY
		&& !(admin_flags & ACCESS_ADMIN) )
		return RESULT_ADMINS_ONLY
	
	// check if admin
	if ( admin_flags & ACCESS_ADMIN )
	{
		// check if admin has to obey duration
		if ( !will_sound_overlap
			|| !(SND_OBEY_DUR & 2) )
			return RESULT_OK
		return RESULT_SOUND_DELAY
	}
	
	if ( SND_MAX != 0
		&& SndCount[id] >= SND_MAX )
		return RESULT_QUOTA_EXCEEDED
	
	if ( SND_MAX_DUR != 0.0
		&& SndLenghtCount[id] > SND_MAX_DUR )
		return RESULT_QUOTA_DURATION_EXCEEDED
	
	// check if player is allowed to play sounds depending on alive config
	if ( !(SND_MODE & (is_user_alive(id) + 1)) )
		return RESULT_BAD_ALIVE_STATUS
	
	// check for sound overlapping + delay time
	if ( !will_sound_overlap )
		return RESULT_OK
	
	// check if overlapping is allowed
	// or for delay time
	if ( !(SND_OBEY_DUR & 1)
		&& gametime > LastSoundTime + SND_DELAY )
		return RESULT_OK
	
	return RESULT_SOUND_DELAY
}

displayQuotaWarning( id )
{
	new admin_flags = get_user_flags(id)
	if ( (admin_flags & (SND_IMMUNITY | ACCESS_ADMIN)) > 0)
		return
	
	if ( SND_MAX != 0 )
	{
		if ( SndCount[id] >= SND_WARN )
		{
			if ( SndCount[id] + 1 == SND_MAX )
				client_print(id, print_chat, "Sank Sounds >> This was your last sound")
			else
				client_print(id, print_chat, "Sank Sounds >> You have %d left before you get muted", SND_MAX - SndCount[id] - 1)
		}
	}
}

displayQuotaExceeded( id )
{
	new admin_flags = get_user_flags(id)
	if ( (admin_flags & (SND_IMMUNITY | ACCESS_ADMIN)) > 0)
		return 0
	
	if ( SND_MAX != 0 )
	{
		if ( SndCount[id] >= SND_MAX )
		{
			if ( SndCount[id] - 3 < SND_MAX )
			{
				client_print(id, print_chat, "Sank Sounds >> You were warned, you are muted")

				// player is already muted, we increament here to save a variable to protect player from "you are muted" spam ( only 3 warnings )
				++SndCount[id]
			}
			return 1
		}
	}
	return 0
}

//////////////////////////////////////////////////////////////////////////////
// Checks the input variables for invalid values
//////////////////////////////////////////////////////////////////////////////
ErrorCheck( )
{
	// Can't have negative delay between sounds
	if ( SND_DELAY < 0.0 )
	{
		log_amx("Sank Sounds >> SND_DELAY cannot be negative. Setting to value: 0")
		SND_DELAY = 0.0
	}
	
	// If SND_MAX is zero, then sounds quota is disabled. Can't have negative quota
	if ( SND_MAX < 0 )
	{
		SND_MAX = 0	// in case it was negative
		log_amx("Sank Sounds >> SND_MAX cannot be negative. Setting to value: 0")
	}
	
	// If SND_MAX_DUR is zero, then sounds quota is disabled. Can't have negative quota
	if ( SND_MAX_DUR < 0.0 )
	{
		SND_MAX_DUR = 0.0	// in case it was negative
		log_amx("Sank Sounds >> SND_MAX_DUR cannot be negative. Setting to value: 0.0")
	}
	
	// If SND_WARN is zero, then we can't have warning every time a keyword is said,
	// so we default to 3 less than max
	else if ( ( SND_WARN <= 0 && SND_MAX != 0 )
		|| SND_MAX < SND_WARN )
	{
		if ( SND_MAX < SND_WARN  )
			// And finally, if they want to warn after a person has been
			// muted, that's silly, so we'll fix it.
			log_amx("Sank Sounds >> SND_WARN cannot be higher than SND_MAX")
		else if ( SND_WARN <= 0 )
			log_amx("Sank Sounds >> SND_WARN cannot be set to zero")
		
		if ( SND_MAX > 3 )
			SND_WARN = SND_MAX - 3
		else
			SND_WARN = SND_MAX - 1
		
		log_amx("Sank Sounds >> SND_WARN set to default value: %i", SND_WARN)
	}
}

playsoundall( sound[] , type , split_dead_alive = 0 , sender_alive_status = 0 )
{
	new alive
	for( new i = 1; i <= g_max_players; ++i )
	{
		if ( !is_user_connected(i) )
			continue
		
		if ( is_user_bot(i)
			&& !(SND_MODE & 128) )
			continue
		
		if ( !SndOn[i] )
			continue
		
		alive = is_user_alive(i)
		if ( !(SND_MODE & ( alive * 4 + 4 )) )
			continue
		
		if ( split_dead_alive
			&& alive != sender_alive_status		// make sure if splited both are in same group
			&& !(SND_MODE & ( alive * 32 + 32 )) )	// OR check if different groups may hear each other
			continue
		
		if ( type == SOUND_TYPE_MP3 )
			client_cmd(i, "mp3 play ^"%s^"", sound)
		else if ( type == SOUND_TYPE_WAV_LOCAL )
			client_cmd(i, "play ^"%s^"", sound)
		else if ( type == SOUND_TYPE_SPEECH )
		{
			if ( sound[0] == '^"' )
				client_cmd(i, "spk %s", sound)
			else
				client_cmd(i, "spk ^"%s^"", sound)
		}else
			client_cmd(i, "spk ^"%s^"", sound)
	}
}

print_sound_list( id , motd_msg = 0 )
{
	new text[256], motd_buffer[2048], ilen, skip_for_loop
	new info_text[64] = "say < keyword >: plays A sound. keYwords are listed Below:"
	if ( strlen(motd_sound_list_address) > 3 )	// make sure at least you have something like: a.b ( http://a.b )
	{
		copy(motd_buffer, 255, motd_sound_list_address)
		skip_for_loop = 1
		motd_msg = 1
	}else if ( motd_msg )
		ilen = format(motd_buffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>%s^n", info_text)
	else
		client_print(id, print_console, info_text)
	
	// Loop once for each keyword
	new i, j = -1
	new sData[SOUND_DATA_BASE]
	new aLen = ArraySize(soundData)
	for ( i = 2; i < aLen && skip_for_loop == 0; ++i )	// first 2 elements are reserved for Join / Exit sounds
	{
		ArrayGetArray(soundData, i, sData)
		
		// check if player can see admin sounds
		++j
		new found_stricted = 0
		if ( sData[ADMIN_LEVEL_BASE] == 0
			|| get_user_flags(id) & sData[ADMIN_LEVEL_BASE] )
		{
			if ( motd_msg )
				ilen += format(motd_buffer[ilen], 2047 - ilen, "%s", sData[KEYWORD])
			else
				add(text, 255, sData[KEYWORD])
		}else
		{
			--j
			found_stricted = 1
		}
		
		if ( !found_stricted )
		{
			if ( j % NUM_PER_LINE == NUM_PER_LINE - 1 )
			{
				// We got NUM_PER_LINE on this line,
				// so print it and start on the next line
				if ( motd_msg )
					ilen += format(motd_buffer[ilen], 2047 - ilen, "^n")
				else
				{
					client_print(id, print_console, "%s", text)
					text[0] = 0
				}
			}else
			{
				if ( motd_msg )
					ilen += format(motd_buffer[ilen], 2047 - ilen, " | ")
				else
					add(text, 255, " | ")
			}
		}
	}
	if ( motd_msg
		&& strlen(motd_buffer) )
		show_motd(id, motd_buffer)
	else if ( strlen(text) )
		client_print(id, print_console, text)
}

#if ALLOW_SORT == 1
public sortSoundDataFunc( Array:array , item1 , item2 , const data[] , data_size )
{
	new data1[SOUND_DATA_BASE]
	new data2[SOUND_DATA_BASE]
	ArrayGetArray(array, item1, data1)
	ArrayGetArray(array, item2, data2)
	if ( (data1[FLAGS] & FLAGS_JOIN_SND) == FLAGS_JOIN_SND )
		return -1;
	if ( (data2[FLAGS] & FLAGS_JOIN_SND) == FLAGS_JOIN_SND )
		return 1;
	if ( (data1[FLAGS] & FLAGS_EXIT_SND) == FLAGS_EXIT_SND )
		return -1;
	if ( (data2[FLAGS] & FLAGS_EXIT_SND) == FLAGS_EXIT_SND )
		return 1;
	return strcmp(data1[KEYWORD], data2[KEYWORD])
}
#endif

array_add_element( keyword[] )
{
	new join_check = equali(keyword, "SND_JOIN")
	new exit_check = equali(keyword, "SND_EXIT")
	
	new sData[SOUND_DATA_BASE]
	// index 0 and 1 are reserved for join/exit
	new num = -1
	if ( join_check != 0 )
	{
		num = 0
		exit_check = -1
		sData[FLAGS] |= FLAGS_JOIN_SND | FLAG_IGNORE_AMOUNT
	} else if ( exit_check != 0 )
	{
		num = 1
		join_check = -1
		sData[FLAGS] |= FLAGS_EXIT_SND | FLAG_IGNORE_AMOUNT
	}
	
	sData[ADMIN_LEVEL_BASE] = cfg_parse_access(keyword)
	copy(sData[KEYWORD], TOK_LENGTH, keyword)
	sData[PLAY_COUNT_KEY] = 0
	sData[SUB_INDEX] = _:ArrayCreate(SOUND_DATA_SUB)
	if ( num == 0
		|| num == 1	)
		ArraySetArray(soundData, num, sData)
	else
	{
		num = ArraySize(soundData)
		ArrayPushArray(soundData, sData)
	}
	
	return num
}

array_add_inner_element( num , elem , soundfile[] , allow_check_existence = 1 , allow_global_precache = 0 , precache_sounds = 0 , allowed_to_precache = 0 )
{
	new subData[SOUND_DATA_SUB]
	subData[ADMIN_LEVEL] = cfg_parse_access(soundfile)
	subData[SOUND_TYPE] = soundfile[0] == '^"' ? SOUND_TYPE_SPEECH : ( soundfile[strlen(soundfile) - 1] == '3' ? SOUND_TYPE_MP3 : SOUND_TYPE_WAV )
	subData[PLAY_COUNT] = 0
	
	if ( subData[SOUND_TYPE] == SOUND_TYPE_SPEECH )
	{
		// remove the quotes
		copy(soundfile, strlen(soundfile) - 2, soundfile[1]);
	}else
	{
		new sound_file_name[TOK_LENGTH + 1 + 10]
		new is_mp3 = ( containi(soundfile, ".mp3") != -1 )
		if ( !is_mp3 // ".mp3" in not in the string
			&& !equali(soundfile, "sound/", 6) )
		{
			formatex(sound_file_name, TOK_LENGTH + 10, "sound/../%s", soundfile)
		} else
		{
			copy(sound_file_name, TOK_LENGTH + 10, soundfile)
		}
		
		if ( allow_check_existence )
		{
			if ( !file_exists(sound_file_name) )
			{
				// now check for all sub folders that start with the same name followed by an underscore
				if ( ArraySize(modSearchPaths) == 0 )
				{
					new modname[32 + 1]
					get_modname(modname, 31)
					new modName_len = strlen(modname)
					modname[modName_len + 1] = 0
					modname[modName_len] = '_'
					++modName_len
					
					new dirFileName[64]
					new dirFileName_len = charsmax(dirFileName)
					new dirHandle = open_dir("..", dirFileName, dirFileName_len)
					if ( dirHandle != 0 )
					{
						do
						{
							if ( !equali(modname, dirFileName, modName_len) )
								continue
							ArrayPushArray(modSearchPaths, dirFileName)
						} while ( next_file(dirHandle, dirFileName, dirFileName_len) )
						close_dir(dirHandle)
					}
				}
				
				new foundFile = false
				new alt_sound_file_name[TOK_LENGTH + 1 + 10 + 32]
				new i
				new modSearchPath[64]
				for ( i = 0; i < ArraySize(modSearchPaths); ++i )
				{
					ArrayGetArray(modSearchPaths, i, modSearchPath)
					formatex(alt_sound_file_name, TOK_LENGTH + 10 + 32, "../%s/%s", modSearchPath, sound_file_name)
					if ( file_exists(alt_sound_file_name) )
					{
						foundFile = true
						copy(sound_file_name, TOK_LENGTH + 10, alt_sound_file_name);
						break
					}
				}
				
				if ( !foundFile )
				{
					log_amx("Sank Sounds >> Trying to load a file that does not exist. Skipping this file: ^"%s^"", sound_file_name)
					
					return -1
				}
			}
			
			subData[DURATION] = _:cfg_get_duration(sound_file_name, is_mp3 ? SOUND_TYPE_MP3 : SOUND_TYPE_WAV )
			
			if ( subData[DURATION] <= 0.0 )
			{
				log_amx("Sank Sounds >> Sound duration is not valid. File is damaged. Skipping this file: ^"%s^"", sound_file_name)
				
				return -1
			}
		}
		
		if ( allow_global_precache
			&& precache_sounds == 1
			&& allowed_to_precache )
		{
			engfunc(EngFunc_PrecacheGeneric, soundfile)
		}
		
		// remove ".wav" from files to prevent runtime warnings (using: developer 1)
		if ( subData[SOUND_TYPE] == SOUND_TYPE_WAV )
		{
			new len = strlen(soundfile)
			if ( len > 4
				&& equali(soundfile[len - 4], ".wav") )
			{
				soundfile[len - 4] = 0;
			}
		}
	}
	
	copy(subData[SOUND_FILE], TOK_LENGTH, soundfile)
	subData[SOUND_FILE][TOK_LENGTH] = 0 // ensure that string operations will terminate
	
	new sData[SOUND_DATA_BASE]
	ArrayGetArray(soundData, num, sData)
	++sData[SOUND_AMOUNT]
	if ( elem < ArraySize(sData[SUB_INDEX]) )
		ArrayInsertArrayBefore(sData[SUB_INDEX], elem, subData)
	else
		ArrayPushArray(sData[SUB_INDEX], subData)
	ArraySetArray(soundData, num, sData)
	
	return 1
}

array_clear( )
{
	new sData[SOUND_DATA_BASE]
	new aLen = ArraySize(soundData)
	for ( new i = 0; i < aLen; ++i )
	{
		ArrayGetArray(soundData, i, sData)
		ArrayDestroy(sData[SUB_INDEX])
	}
	ArrayDestroy(soundData)
}

array_remove( index )
{
	new sData[SOUND_DATA_BASE]
	ArrayGetArray(soundData, index, sData)
	ArrayDestroy(sData[SUB_INDEX])
	if ( index > 1 ) // join/exit keywords may not be removed
		ArrayDeleteItem(soundData, index)
	else
		sData[SUB_INDEX] = _:ArrayCreate(SOUND_DATA_SUB)
}

array_remove_inner( index , elem )
{
	new sData[SOUND_DATA_BASE]
	ArrayGetArray(soundData, index, sData)
	--sData[SOUND_AMOUNT]
	ArrayDeleteItem(sData[SUB_INDEX], elem)
	ArraySetArray(soundData, index, sData)
}

array_initialize( )
{
	soundData = ArrayCreate(SOUND_DATA_BASE)
	
	new sData[SOUND_DATA_BASE]
	ArrayPushArray(soundData, sData)
	ArrayPushArray(soundData, sData)
}

cfg_write_keyword( file , data[] )
{
	if ( data[ADMIN_LEVEL_BASE] )
	{
		new access_str[32]
		get_flags(data[ADMIN_LEVEL_BASE], access_str, 31)
		fputc(file, '@')
		fputs(file, access_str)
		fputc(file, '@')
	}
	fputs(file, data[KEYWORD])
	fputs(file, ";^t^t")
}

cfg_write_keysound( file , subdata[] )
{
	if ( subdata[ADMIN_LEVEL] )
	{
		new access_str[32]
		get_flags(subdata[ADMIN_LEVEL], access_str, 31)
		fputc(file, '@')
		fputs(file, access_str)
		fputc(file, '@')
	}
	fputs(file, subdata[SOUND_FILE])
	fputs(file, ";")
}

cfg_parse_access( str[] )
{
	new access_level
	if ( str[0] == '@' )
	{
		new second_at = contain(str[1], "@")
		if ( second_at != -1 )
		{
			new temp_access[32]
			copy(temp_access, second_at, str[1])
			strtolower(temp_access)
			access_level = read_flags(temp_access)
			copy(str, 127, str[second_at + 1 + 1])
		}else
		{
			access_level = SND_IMMUNITY
			copy(str, 127, str[1])
		}
	}
	
	return access_level
}

Float:cfg_get_duration( sound_file[] , type )
{
	switch ( type )
	{
		case SOUND_TYPE_WAV:
		{
			return cfg_get_wav_duration(sound_file)
		}
		case SOUND_TYPE_MP3:
		{
			return cfg_get_mp3_duration(sound_file)
		}
	}
	
	return 0.0
}

Float:cfg_get_wav_duration( wav_file[] )
{
	new file = fopen(wav_file, "rb")
	new dummy_input
	new i
	for ( i = 0; i < 24; ++i )
		dummy_input = fgetc(file)
	
	// 24th byte
	new hertz = fgetc(file)
	// 25th byte
	hertz += fgetc(file) * 256
	// 26th byte
	hertz += fgetc(file) * 256 * 256
	
	for ( i = 27; i < 34; ++i )
		dummy_input = fgetc(file)
	
	// 34th byte
	new bitrate = fgetc(file)
	
	// bytes for data length start right after ascii "data", so search for it
	// normally it is at 35 but also saw at 44, so just in case add bigger search area
	new data_found
	
	do
	{
		dummy_input = fgetc(file)
		if ( dummy_input == 'd' )
			data_found = 1
		else if ( dummy_input == 'a'
			&& data_found == 1 )
			data_found = 2
		else if ( dummy_input == 't'
			&& data_found == 2 )
			data_found = 3
		else if ( dummy_input == 'a'
			&& data_found == 3 )
			data_found = 4
		else
			data_found = 0
	}while ( dummy_input != -1 && data_found < 4 )
	
	if ( dummy_input == -1
		|| hertz <= 0
		|| bitrate <= 0
		|| data_found != 4 )
	{
		fclose(file)
		return 0.0
	}
	
	// 1st byte after data
	new data_length = fgetc(file)
	// 2nd byte after data
	data_length += fgetc(file) * 256
	// 3rd byte after data
	data_length += fgetc(file) * 256 * 256
	// 4th byte after data
	data_length += fgetc(file) * 256 * 256 * 256
	
	fclose(file)
	
	return float(data_length) / ( float(hertz * bitrate) / 8.0 )
}

enum
{
	MP3_MPEG_VERSION_BIT1 = 8,
	MP3_MPEG_VERSION_BIT2 = 16,
	MP3_LAYER_BIT1 = 2,
	MP3_LAYER_BIT2 = 4,
	MP3_PROTECT_BIT = 1,
	
	MP3_BITRATE_BIT1 = 16,
	MP3_BITRATE_BIT2 = 32,
	MP3_BITRATE_BIT3 = 64,
	MP3_BITRATE_BIT4 = 128,
	MP3_BITRATE_INVALID = 15,
	MP3_SAMPLERATE_BIT1 = 4,
	MP3_SAMPLERATE_BIT2 = 8,
	MP3_SAMPLERATE_INVALID = 3,
	MP3_PADDING_BIT = 2,
	MP3_PRIVATE_BIT = 1,
}

// bitrate info
new const bitrate_table[] = {
	//MPEG 2 & 2.5
	0, 32, 48, 56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256, -1,	// Layer I
	0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160, -1,	// Layer II
	0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160, -1,	// Layer III
	//MPEG 1
	0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, -1,	// Layer I
	0, 32, 48, 56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384, -1,	// Layer II
	0, 32, 40, 48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, -1,	// Layer III
}

#if DEBUG_MODE == 1
// frequency info
new const samplingrate_table[] = {
	11025, 12000,  8000, 0,	// MPEG 2.5	// have not seen MPEG 2.5, so UNTESTED
	   -1,    -1,    -1, 0,	// reserved
	22050, 24000, 16000, 0,	// MPEG 2
	44100, 48000, 32000, 0	// MPEG 1
}
#endif

Float:cfg_get_mp3_duration( mp3_file[] )
{
	new file = fopen(mp3_file, "rb")
	new byte, found_header, file_pos
	new byte2
	
	new mpeg_version
	new layer
	new mp3_bitrate
	new mp3_samplerate
	new result = -1
	do
	{
		byte = fgetc(file)
		if ( byte == -1 )
			break
		
		++file_pos
		if ( byte != 255 )
			continue
		
		byte = fgetc(file)
		byte2 = fgetc(file)
		result = verify_header(byte, byte2, mpeg_version, layer, mp3_bitrate, mp3_samplerate)
		if ( result == -1 )
		{
			fseek(file, file_pos, SEEK_SET)
			++file_pos
			continue
		}else
			break
	}while ( !found_header && byte != -1 )
	
	fclose(file)
	
	if ( byte == -1 )
		return 0.0
	
	new mpeg_version_for_bitrate = 0
	if ( mpeg_version == 3 )
		mpeg_version_for_bitrate = 1
	new mp3_bitrate_kbps = bitrate_table[mpeg_version_for_bitrate * ( 3 * 16 ) + ( layer - 1 ) * 16 + mp3_bitrate]
	
#if DEBUG_MODE == 1
	log_amx("Sank Sounds >> DEBUG for file ^"%s^"", mp3_file)
	log_amx("Sank Sounds >> Data bytes = %i / %i", byte, byte2)
	log_amx("Sank Sounds >> Header position = %i", file_pos)
	new mpeg_version_str[10]
	if ( mpeg_version == 0 )
		copy(mpeg_version_str, 9, "MPEG 2.5")
	else if ( mpeg_version == 2 )
		copy(mpeg_version_str, 9, "MPEG 2")
	else if ( mpeg_version == 3 )
		copy(mpeg_version_str, 9, "MPEG 1")
	log_amx("Sank Sounds >> MPEG version = %i / Format: %s", mpeg_version, mpeg_version_str)
	log_amx("Sank Sounds >> Layer = %i", layer)
	log_amx("Sank Sounds >> Bitrate = %iKbps (%i)", mp3_bitrate_kbps, mp3_bitrate)
	
	new mp3_samplerate_hz = samplingrate_table[mpeg_version * 4 + mp3_samplerate]
	
	log_amx("Sank Sounds >> Samplerate = %iHz (%i)", mp3_samplerate_hz, mp3_samplerate)
#endif
	new size_of_file = file_size(mp3_file, 0)
	
	if ( mp3_bitrate_kbps == 0 )
		return 0.0
	
	//song length...
	return float(size_of_file) / ( float(mp3_bitrate_kbps) * 1000.0 ) * 8.0
}

verify_header( header , header2 , &mpeg_version , &layer , &mp3_bitrate , &mp3_samplerate)
{
	// check if first 3 bits set
	if ( header & 0xe0 != 0xe0 )
		return -1
	
	layer = 4
		- ( header & MP3_LAYER_BIT1 ) / MP3_LAYER_BIT1
		+ ( header & MP3_LAYER_BIT2 ) / MP3_LAYER_BIT1
	
	if ( layer != 3 )
		return -1
	
	mp3_bitrate = ( header2 & MP3_BITRATE_BIT1 ) / MP3_BITRATE_BIT1
		+ ( header2 & MP3_BITRATE_BIT2 ) / MP3_BITRATE_BIT1
		+ ( header2 & MP3_BITRATE_BIT3 ) / MP3_BITRATE_BIT1
		+ ( header2 & MP3_BITRATE_BIT4 ) / MP3_BITRATE_BIT1
	
	if ( mp3_bitrate & MP3_BITRATE_INVALID == MP3_BITRATE_INVALID )
		return -1
	
	mp3_samplerate = ( header2 & MP3_SAMPLERATE_BIT1 ) / MP3_SAMPLERATE_BIT1
		+ ( header2 & MP3_SAMPLERATE_BIT2 ) / MP3_SAMPLERATE_BIT1
	
	if ( mp3_samplerate & MP3_SAMPLERATE_INVALID == MP3_SAMPLERATE_INVALID )
		return -1
	
	mpeg_version = ( header & MP3_MPEG_VERSION_BIT1 ) / MP3_MPEG_VERSION_BIT1
		+ ( header & MP3_MPEG_VERSION_BIT2 ) / MP3_MPEG_VERSION_BIT1
	
	return 1
}

/*
* plugin_sank_sounds.sma
* Author: Luke Sankey
* Date: March 21, 2001 - Original hard-coded version
* Date: July 2, 2001   - Rewrote to be text file configurable
* Date: November 18, 2001 - Added admin_sound_play command, new variables
*       SND_DELAY, SND_SPLIT and EXACT_MATCH, as well as the ability to
*       have admin-only sounds, like the original version had.
* Date: March 30, 2002 - Now ignores speech of length zero.
* Date: May 30, 2002 - Updated for use with new playerinfo function
* Date: November 12, 2002 - Moved snd-list.cfg file to new location, and
*       made it all lower-case.  Sorry, linux guys, if it confuses you.
*       Added some new ideas from Bill Bateman:
*       1.) added SND_PUNISH and changed SND_KICK to SND_MAX
*       2.) ability to either speak or play sounds
*
* Last Updated: May 12, 2003
*
*
*
* HunteR's modifications:
*	- Players no longer kicked, they are "muted" (no longer able to play sounds)
*	- All sounds are now "spoken" (using the speak command)
*	- As a result, all "\" must become "/"
*	- Ability to reset a player's sound count mid-game
*
* My most deepest thanks goes to William Bateman (aka HunteR)
*  http://thepit.shacknet.nu
*  huntercc@hotmail.com
* For he was the one who got me motivated once again to write this plugin
* since I don't run a server anymore. And besides that, he helped write
* parts of it.
*
* I hope you enjoy this new functionality on the old plugin_sank_sounds
*/
