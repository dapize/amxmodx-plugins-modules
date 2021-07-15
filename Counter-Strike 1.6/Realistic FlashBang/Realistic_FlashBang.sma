#include <amxmodx>
#include <fakemeta>

new const Version[] = "1.0.1"

new MsgScreenFade, MsgScreenShake 
new FLenable, FLcolor, FLradius, FLlightcolor, FLsound

new const Sound[] = "sound/ultrasound.mp3"

public plugin_precache() {
	FLsound = register_cvar("amx_rfl_sound", "1")
	
	if(get_pcvar_num(FLsound))
		precache_generic(Sound)
}

public plugin_init()
{
	register_plugin("Realistic FlashBang", Version, "GlaDiuS")
	
	FLenable = register_cvar("amx_rfl_enable", "1")
	FLcolor = register_cvar("amx_rfl_color", "128 128 128")
	FLradius = register_cvar("amx_rfl_radius","50")
	FLlightcolor = register_cvar("amx_rfl_lightcolor","255 255 255")
	
	register_event("ScreenFade","FlashEvent","b","4=255","5=255","6=255","7>199")
	register_forward(FM_EmitSound,"fw_emitsound")
	
	MsgScreenFade = get_user_msgid("ScreenFade")
	MsgScreenShake = get_user_msgid("ScreenShake");
}

public FlashEvent(id)
{	
	if(!get_pcvar_num(FLenable)) 
		return
	
	// get color
	new Colores[12], rgb[3][4], Red, Green, Blue
	get_pcvar_string(FLcolor, Colores, charsmax(Colores))
	parse(Colores, rgb[0], 3, rgb[1], 3, rgb[2], 3)
	Red = clamp(str_to_num(rgb[0]), 0, 255)
	Green = clamp(str_to_num(rgb[1]), 0, 255)
	Blue = clamp(str_to_num(rgb[2]), 0, 255)
	
	new Duration, HoldTime, Fade, Alpha
	Duration = read_data(1)
	HoldTime = read_data(2)
	Fade = read_data(3)
	Alpha = read_data(7)
	
	message_begin(MSG_ONE, MsgScreenFade, {0,0,0}, id)
	write_short(Duration)	// Duration
	write_short(HoldTime)	// Hold time
	write_short(Fade)	// Fade type
	write_byte(Red)		// Red
	write_byte(Green)		// Green
	write_byte(Blue)		// Blue
	write_byte(Alpha)	// Alpha
	message_end()
	
	set_pev(id, pev_punchangle, Float:{125.0, 125.0, 125.0})
	
	if(get_pcvar_num(FLsound)) {
		client_cmd(id, "mp3 play %s", Sound)
		set_task(8.0, "stoppedsound", id)
	}
	
	set_task(3.0, "Shake", id)
}

public Shake(id)
{
	new Dura = UTIL_FixedUnsigned16(4.0, 1 << 12)
	new Freq = UTIL_FixedUnsigned16(0.7 , 1 << 8)
	new Ampl = UTIL_FixedUnsigned16(20.0, 1 << 12)
	
	message_begin(MSG_ONE , MsgScreenShake , {0,0,0} ,id)
	write_short( Ampl ) // --| Shake amount.
	write_short( Dura ) // --| Shake lasts this long.
	write_short( Freq ) // --| Shake noise frequency.
	message_end ()
}

public stoppedsound(id)
	client_cmd(id, "mp3 stop %s", Sound)

public fw_emitsound(entity,channel,const sample[],Float:volume,Float:attenuation,fFlags,pitch)
{
	if(!get_pcvar_num(FLenable))
		return FMRES_IGNORED
	
	// not a flashbang exploding
	if(!equali(sample,"weapons/flashbang-1.wav") && !equali(sample,"weapons/flashbang-2.wav"))
		return FMRES_IGNORED
	
	// light effect
	flashbang_explode(entity)
	
	return FMRES_IGNORED
}

public flashbang_explode(greindex)
{
	if(!pev_valid(greindex)) 
		return
	
	// get origin of explosion
	new Float:origin[3]
	pev(greindex, pev_origin, origin)
	
	// get color
	new Colores[12], rgb[3][4], Red, Green, Blue
	get_pcvar_string(FLlightcolor, Colores, charsmax(Colores))
	parse(Colores, rgb[0], 3, rgb[1], 3, rgb[2], 3)
	Red = clamp(str_to_num(rgb[0]), 0, 255)
	Green = clamp(str_to_num(rgb[1]), 0, 255)
	Blue = clamp(str_to_num(rgb[2]), 0, 255)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_DLIGHT) // 27
	write_coord(floatround(origin[0])) // x
	write_coord(floatround(origin[1])) // y
	write_coord(floatround(origin[2])) // z
	write_byte(get_pcvar_num(FLradius)) // radius
	write_byte(Red) // Red
	write_byte(Green) // Green
	write_byte(Blue) // Blue
	write_byte(8) // life
	write_byte(60) // decay rate
	message_end()
}

UTIL_FixedUnsigned16 ( const Float:Value, const Scale ) {
	return clamp( floatround( Value * Scale ), 0, 0xFFFF );
}
