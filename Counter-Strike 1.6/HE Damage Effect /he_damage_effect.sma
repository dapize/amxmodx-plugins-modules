//#define USE_AMX

#if defined USE_AMX
 #include <amxmod>
 #include <VexdUM>
#else
 #include <amxmodx>
 #include <engine>
#endif

new gMsgScreenShake , gMsgScreenFade;

#define CVAR_STATUS "he_damage_effect"

public plugin_init() {
  register_plugin("HE damage effect" , "0.2" , "v3x");
  register_event("Damage" , "event_Damage" , "b" , "2>0");
  register_cvar(CVAR_STATUS , "1");
  gMsgScreenShake = get_user_msgid("ScreenShake");
  gMsgScreenFade = get_user_msgid("ScreenFade");
}

#if defined USE_AMX
 #define DEFAULT_VOLUME 0.8
#endif

#define PA_LOW  25.0
#define PA_HIGH 50.0

#if !defined USE_AMX
new Float:gVolume[33];

public client_connect(id) {
  if(!is_user_bot(id)) {
    query_client_cvar(id , "volume" , "cvar_result");
  }
}

public cvar_result(id, const cvar[] , const value[]) {
  gVolume[id] = str_to_float(value);
}
#endif

public event_Damage(id) {
  if(get_cvar_num(CVAR_STATUS) <= 0 
  || !is_user_connected(id) 
  || !is_user_alive(id)
  || is_user_bot(id)) return;
  new iWeapID, attacker = get_user_attacker(id , iWeapID);
  if(!is_user_connected(attacker)) return;
  if(iWeapID == 4) {
    client_cmd(id , "volume 0");
    set_task(0.5 , "volume_up_1" , id);
    new Float:fVec[3];
    fVec[0] = random_float(PA_LOW , PA_HIGH);
    fVec[1] = random_float(PA_LOW , PA_HIGH);
    fVec[2] = random_float(PA_LOW , PA_HIGH);
    entity_set_vector(id , EV_VEC_punchangle , fVec);
    message_begin(MSG_ONE , gMsgScreenShake , {0,0,0} ,id)
    write_short( 1<<14 );
    write_short( 1<<14 );
    write_short( 1<<14 );
    message_end();

    message_begin(MSG_ONE_UNRELIABLE , gMsgScreenFade , {0,0,0} , id);
    write_short( 1<<10 );
    write_short( 1<<10 );
    write_short( 1<<12 );
    write_byte( 225 );
    write_byte( 0 );
    write_byte( 0 );
    write_byte( 125 );
    message_end();
  }
}

public volume_up_1(id) {
  client_cmd(id , "volume 0.1");
  set_task(0.2 , "volume_up_2" , id);
}

public volume_up_2(id) {
  client_cmd(id , "volume 0.2");
  set_task(0.2 , "volume_up_3" , id);
}

public volume_up_3(id) {
  client_cmd(id , "volume 0.3");
  set_task(0.2 , "volume_up_4" , id);
}

public volume_up_4(id) {
  client_cmd(id , "volume 0.4");
  set_task(0.2 , "volume_up_5" , id);
}

public volume_up_5(id) {
  client_cmd(id , "volume 0.5");
  set_task(0.2 , "volume_up_6" , id);
}

public volume_up_6(id) {
  client_cmd(id , "volume 0.6");
  set_task(0.2 , "volume_up_7" , id);
}

public volume_up_7(id) {
  client_cmd(id , "volume 0.7");
  set_task(0.2 , "volume_up_8" , id);
}

public volume_up_8(id) {
  #if !defined USE_AMX
   client_cmd(id , "volume %f" , gVolume[id]);
  #else
   client_cmd(id , "volume %f" , float(DEFAULT_VOLUME));
  #endif
}