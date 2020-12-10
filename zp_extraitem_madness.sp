#include <sourcemod>
#include <zombieplague>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

/**
 * @section Player variabes
 **/
Handle g_hMadnessTimer[MAXPLAYERS + 1];
int gStackedBuys[MAXPLAYERS + 1];
int gGlowIndex[MAXPLAYERS + 1];
int gLightOn[MAXPLAYERS + 1];
/**
 * @endsection
 **/


/**
 * @section Global variables
 **/

#define SIMPLE_PATH "zp_plugin/zombie_madness1.mp3"

char rel_path[PLATFORM_MAX_PATH];

int MODE_NORMAL,MODE_MULTI,MODE_PLAGUE,MODE_SWARM;  // modes constants

int gItem;                                          // Item index
#pragma unused gItem

ConVar hSoundLevel;                                 // Sound level
#pragma unused  hSoundLevel

ConVar g_cvDuration;                                // Duration of madness
#pragma unused g_cvDuration
/**
 * @endsection
 **/


/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: Zombie Madness",
    author          = "",
    description     = "Zombie Madness: Zombie immune for bullets for short time",
    version         = "1.0",
    url             = ""
}

/**
 * @section Library methods
 *
 * @note these library methods are very useful if we want to make zombie immune for freeze grenades
 **/

// Following convention
// see: https://wiki.alliedmods.net/Optional_Requirements_(SourceMod_Scripting)

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("ZP_IsMadZombie",   API_IsMadZombie);
	RegPluginLibrary("madness");
	return APLRes_Success;
}

#if !defined REQUIRE_PLUGIN
public void __pl_myfile_SetNTVOptional()
{
	MarkNativeAsOptional("ZP_IsMadZombie");
}
#endif

/**
 * @endsection
 **/


/**
 * @brief Called after a library is added that the current plugin references optionally.
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // If map loaded, then run custom forward
        if(ZP_IsMapLoaded())
        {
            // Execute it
            ZP_OnEngineExecute();
        }
    }
}

/**
 * @brief Gets the player exp.
 *
 * @note native int ZP_GetClientExp(client);
 **/
public int API_IsMadZombie(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell
    int client = GetNativeCell(1);

    // Return the value
    return g_hMadnessTimer[client] != null;
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{

    MODE_NORMAL= ZP_GetGameModeNameID("normal mode");
    MODE_MULTI = ZP_GetGameModeNameID("multi mode");
    MODE_PLAGUE = ZP_GetGameModeNameID("plague mode");
    MODE_SWARM = ZP_GetGameModeNameID("swarm mode");

    // Items
    gItem = ZP_GetExtraItemNameID("zombie_madness");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"zombie_madness\" wasn't find");


    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");

	g_cvDuration = CreateConVar("zp_mad_zombie_duration", "7.0", "Zombie madness duration");

    // Hook events
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end",OnRoundEnd,EventHookMode_Pre);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

    // TODO: I precached this on my own, because it was standalone plugin not coupled with ZP (expect API)
    // TODO: this is basically sound when Fast zombie pressed F4 (SKILL)
    char full_path[PLATFORM_MAX_PATH];

    Format(rel_path,sizeof(rel_path),"*/%s",SIMPLE_PATH);
    Format(full_path,sizeof(full_path),"sound/%s",SIMPLE_PATH);

    FakePrecacheSound(rel_path);
    AddFileToDownloadsTable(full_path);

    ResetAll(); // Reset all players values
}



void FakePrecacheSound( char[] szPath )
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}


/**
 * @section Hooked events
 *
 **/

/**
 * @brief Called on round end
 **/
public void OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    ResetAll();
}

/**
 * @brief Called on round start
 **/
public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    ResetAll();
}

/**
 * @brief Called after player joins a server.
 *        All stats of player are reset
 *
 * @param client            The client index.
 **/
public void OnClientPostAdminCheck(int client)
{
    ResetClient(client);
}


public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    ResetClient(GetClientOfUserId(event.GetInt("userid")));
}

/**
 * @brief Called when client disconnects
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
    ResetClient(client);
}

/**
 * @endsection
 **/

/**
 * @brief Called before show an extraitem in the equipment menu.
 *
 * @param client            The client index.
 * @param itemID            The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int client, int itemID)
{
    // Check the item's index
    if(itemID == gItem)
    {
        // Validate access
        if( !ZP_IsPlayerZombie(client))
        {
            return Plugin_Handled;
        }

        // Get current mode
        int mode = ZP_GetCurrentGameMode();

        // Use only in modes with zombies
        if (!(mode == MODE_NORMAL || mode == MODE_MULTI || mode == MODE_PLAGUE || mode == MODE_SWARM))
        {
            return Plugin_Handled;
        }

    }
    // Allow showing
    return Plugin_Continue;
}

/**
 * @brief Called after select an extraitem in the equipment menu.
 *
 * @param client            The client index.
 * @param itemID            The item index.
 **/
public void ZP_OnClientBuyExtraItem(int client, int itemID)
{
    // Check the item's index
    if(itemID == gItem)
    {
        // client bought item
        gStackedBuys[client]++;

        // we start madness only if it is first buys
        // otherwise it will be restarted by timer basing on gStackedBuys[client]
    	if (gStackedBuys[client] == 1)
        	StartMadness(client);

    }
}


/**
 * @brief Called when client validated and bought item
 *
 * @param client            The client index.
 **/
public void StartMadness(int client)
{
        if(!gLightOn[client])
        {
            // Turn on player light
            float position[3];
            GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
            gLightOn[client] = UTIL_CreateLight(client,position, _, _, _, _,_,_,_,"255 0 0 255",300.0,200.0, _ ); // duration
        }

        // Emit sound to all players
        EmitSoundToAll(rel_path,client,SNDCHAN_VOICE,hSoundLevel.IntValue);
        // Create finish timer
		g_hMadnessTimer[client] = CreateTimer(g_cvDuration.FloatValue, Timer_MadnessFinished, client);
        // Set client immune
        SetClientImmuneToBullets(client,true);
}

/**
 * @brief Called when madness finished, but may be restarted due to stacked buys
 *
 * @param client            The client index.
 **/
public void FinishMadness(int client){

        // We disable red light glow of player
        if (gLightOn[client])
        {
            // TODO: There are sometimes exceptions
            // TODO: probably because not-existing entities are deleted
            // TODO: this is ugly woraround so they don't reoccur
            int temp = gLightOn[client];
            gLightOn[client] = 0;
            UTIL_RemoveEntity(temp,0.0);
        }

        // we set timer to null as we use this in flow control
		g_hMadnessTimer[client] = null;

        // Client is no longer immune
        SetClientImmuneToBullets(client,false);
}


/**
 * @brief Called when madness finished, but may be restarted due to stacked buys
 *
 * @param timer             Handle to timer
 * @param client            The client index.
 **/
public Action Timer_MadnessFinished(Handle timer, any client)
{
    // when madness ends, we decrease buy counter
	gStackedBuys[client]--;

	// if buy counter is zero, we dont start new madness
    if (gStackedBuys[client] > 0)
    		StartMadness(client);
    else
    	    FinishMadness(client);
}

/**
 * @brief Reset all clients
 * @note called when: plugin loaded, round started, round ended
 **/
public void ResetAll(){
  	for (int client  = 1 ; client <= MaxClients ; client++)
        ResetClient(client);
}

/**
 * @brief Reset single client
 * @note called when: client joins, client leaves, client dies
 **/
public void ResetClient(int client){
    if (g_hMadnessTimer[client] != null)
    {
        KillTimer(g_hMadnessTimer[client]);
        g_hMadnessTimer[client] = null;
    }
	gGlowIndex[client] = 0;
    gStackedBuys[client] = 0;
}

/**
 * @brief Set client immune to bullets
 *
 * @param client            The client index.
 * @param immune            if true then player is immune
 **/
void SetClientImmuneToBullets(int client,bool immune)
{
    // Player is immune to attacks
    SetEntProp(client, Prop_Data, "m_takedamage", immune ? 0 : 2, 1);
}