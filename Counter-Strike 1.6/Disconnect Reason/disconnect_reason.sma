
/*
	- Disconnect Reason -
	      by bugsy
*/

#include <amxmodx>
#include <amxmisc>
#include <orpheu>

new const Version[] = "0.6";

enum ReasonCodes
{
	DR_TIMEDOUT,
	DR_DROPPED,
	DR_KICKED,
	DR_LEVELCHANGE,
	DR_OTHER
}
new const DisconnectMessages[ ReasonCodes ][] = 
{
	"Timed out", 
	"Client sent 'drop'",
	"Kicked",
	"Dropping fakeclient on level change",
	""
};
enum DisconnectData
{
	ReasonCode,
	ReasonMessage[ 50 ]
}

new g_pEnabled , bool:g_bEnabled , g_szName[ 33 ][ 33 ] , g_DisconnectInfo[ DisconnectData ] , g_iFwdDisconnect;

public plugin_init()
{
	register_plugin( "Disconnect Reason" , Version , "bugsy" );
	
	g_pEnabled = register_cvar( "dr_enabled" , "1" );
	register_cvar( "disconnectreason_version" , Version , ( FCVAR_SERVER | FCVAR_SPONLY ) );
	
	OrpheuRegisterHook( OrpheuGetFunction( "SV_DropClient" ) , "SV_DropClient"  );
	
	register_message( get_user_msgid( "TextMsg" ) , "fw_MsgTextMsg" );
	
	g_iFwdDisconnect = CreateMultiForward( "client_disconnect_reason", ET_CONTINUE , FP_CELL , FP_CELL , FP_STRING );
}

public client_putinserver( id )
{
	get_user_name( id , g_szName[ id ] , charsmax( g_szName[] ) );
}

public OrpheuHookReturn:SV_DropClient( a , b , const szMessage[] )
{	
	if ( ( g_bEnabled = bool:!!get_pcvar_num( g_pEnabled ) ) )
	{
		copy( g_DisconnectInfo[ ReasonMessage ] , charsmax( g_DisconnectInfo[ ReasonMessage ] ) , szMessage );
		
		new ReasonCodes:rcReason;
		for ( rcReason = DR_TIMEDOUT ; rcReason < ReasonCodes ; rcReason++ )
		{
			if ( equal( szMessage , DisconnectMessages[ rcReason ] ) )
				break;
		}
		
		g_DisconnectInfo[ ReasonCode ] = _:rcReason;
	}
}

public client_disconnect( id )
{		
	new iReturn;
	ExecuteForward( g_iFwdDisconnect , iReturn , id , g_DisconnectInfo[ ReasonCode ] , g_DisconnectInfo[ ReasonMessage ] );
	
	if ( g_bEnabled )
	{
		console_print( 0 , "* %s has disconnected - Reason [ %s ]" , g_szName[ id ] , g_DisconnectInfo[ ReasonMessage ] );
		ChatNotify( id );
	}
}

public fw_MsgTextMsg( iMsgID , iMsgDest , iMsgArgs )
{
	static szMessage[ 19 ];
	return ( g_bEnabled && get_msg_arg_string( 2 , szMessage , charsmax( szMessage ) ) && equal( szMessage , "#Game_disconnected" ) ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

ChatNotify( iDisconnectID )
{
	static szMessage[ 100 ] , iMsgSayText;
	formatex( szMessage , charsmax( szMessage ) , "^1*^3 %s ^1has disconnected - Reason [^4 %s ^1]" , g_szName[ iDisconnectID ] , g_DisconnectInfo[ ReasonMessage ] );
	
	emessage_begin( MSG_BROADCAST , iMsgSayText ? iMsgSayText : ( iMsgSayText = get_user_msgid( "SayText" ) ) , _ , 0 );
	ewrite_byte( iDisconnectID );		
	ewrite_string( szMessage );
	emessage_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
