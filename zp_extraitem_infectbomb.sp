/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: InfectBomb",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the grenade.
 **/
#define GRENADE_INFECT_RADIUS          200.0        // Infection size (radius)
#define GRENADE_INFECT_LAST            false        // Can last human infect [false-no // true-yes]
#define GRENADE_INFECT_EXP_TIME        2.0          // Duration of the explosion effect in seconds
#define GRENADE_INFECT_ATTACH          false        // If true, will be attached to the wall, false to bounce from wall
/**
 * @endsection
 **/
 
// Sound index and XRay vision
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook entity events
        HookEvent("tagrenade_detonate", EventEntityTanade, EventHookMode_Post);
        
        // Hooks server sounds
        AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItem = ZP_GetExtraItemNameID("infect bomb");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"infect bomb\" wasn't find");
    
    // Weapons
    gWeapon = ZP_GetWeaponNameID("infect bomb");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"infect bomb\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("INFECT_GRENADE_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"INFECT_GRENADE_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Validate access
        if(ZP_IsPlayerHasWeapon(clientIndex, gWeapon) || !ZP_IsGameModeInfect(ZP_GetCurrentGameMode()))
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
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, gWeapon);
    }
}

/**
 * @brief Called after a custom grenade is created.
 *
 * @param clientIndex       The client index.
 * @param grenadeIndex      The grenade index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnGrenadeCreated(int clientIndex, int grenadeIndex, int weaponID)
{
    // Validate custom grenade
    if(weaponID == gWeapon) /* OR if(ZP_GetWeaponID(grenadeIndex) == gWeapon)*/
    {
        // Hook entity callbacks
        SDKHook(grenadeIndex, SDKHook_Touch, TanadeTouchHook);
    }
}

/**
 * @brief Tagrenade touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action TanadeTouchHook(int entityIndex, int targetIndex)
{
    #if GRENADE_INFECT_ATTACH == true
    return Plugin_Continue;
    #else
    return Plugin_Handled;
    #endif
}

/**
 * Event callback (tagrenade_detonate)
 * @brief The tagrenade is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityTanade(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Gets real player index from event key
    int ownerIndex = GetClientOfUserId(hEvent.GetInt("userid")); 

    // Initialize vectors
    static float vEntPosition[3]; static float vVictimPosition[3];

    // Gets all required event info
    int grenadeIndex = hEvent.GetInt("entityid");
    vEntPosition[0] = hEvent.GetFloat("x"); 
    vEntPosition[1] = hEvent.GetFloat("y"); 
    vEntPosition[2] = hEvent.GetFloat("z");

    // Validate entity
    if(IsValidEdict(grenadeIndex))
    {
        // Validate custom grenade
        if(ZP_GetWeaponID(grenadeIndex) == gWeapon)
        {
            // Validate infection round
            if(ZP_IsGameModeInfect(ZP_GetCurrentGameMode()) && ZP_IsStartedRound())
            {
                // i = client index
                for(int i = 1; i <= MaxClients; i++)
                {
                    // Validate human
                    if(IsPlayerExist(i) && ZP_IsPlayerHuman(i))
                    {
                        // Gets victim origin
                        GetClientAbsOrigin(i, vVictimPosition);

                        // Calculate the distance
                        float flDistance = GetVectorDistance(vEntPosition, vVictimPosition);

                        // Validate distance
                        if(flDistance <= GRENADE_INFECT_RADIUS)
                        {            
                            // Change class to zombie
                            if(ZP_GetHumanAmount() > 1 || GRENADE_INFECT_LAST) ZP_ChangeClient(i, ownerIndex, "zombie");
                        }
                        
                        // Reset glow on the next frame
                        RequestFrame(view_as<RequestFrameCallback>(EventEntityTanadePost), i);
                    }
                }
            }

            // Create a info_target entity
            int infoIndex = ZP_CreateEntity(vEntPosition, GRENADE_INFECT_EXP_TIME);

            // Validate entity
            if(infoIndex != INVALID_ENT_REFERENCE)
            {
                // Create an explosion effect
                ZP_CreateParticle(infoIndex, vEntPosition, _, "explosion_hegrenade_dirt", GRENADE_INFECT_EXP_TIME);
            }
            
            // Remove grenade
            AcceptEntityInput(grenadeIndex, "Kill");
        }
    }
}

/**
 * EventFake callback (tagrenade_detonate)
 * @brief The tagrenade was exployed. (Post)
 * 
 * @param clientIndex       The client index.
 **/
public void EventEntityTanadePost(int clientIndex)
{
    // Bugfix with tagrenade glow
    if(IsPlayerExist(clientIndex) && ZP_IsPlayerHuman(clientIndex)) SetEntPropFloat(clientIndex, Prop_Send, "m_flDetectedByEnemySensorTime", ZP_IsGameModeXRay(ZP_GetCurrentGameMode()) ? (GetGameTime() + 9999.0) : 0.0);
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
 * @param numClients        Number of clients in the array (modify this value if you add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entityIndex       Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFlags            The sound flags.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS-1], int &numClients, char[] sSample, int &entityIndex, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags)
{
    // Validate client
    if(IsValidEdict(entityIndex))
    {
        // Validate custom grenade
        if(ZP_GetWeaponID(entityIndex) == gWeapon)
        {
            // Initialize sound char
            static char sSound[PLATFORM_LINE_LENGTH];

            // Validate sound
            if(!strncmp(sSample[30], "arm", 3, false))
            {
                // Emit a custom bounce sound
                ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
                EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
            else if(!strncmp(sSample[30], "det", 3, false))
            {
                // Emit a custom bounce sound
                ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
                EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
            else if(!strncmp(sSample[30], "exp", 3, false))
            {
                // Emit explosion sound
                ZP_GetSound(gSound, sSound, sizeof(sSound), 3);
                EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }

            // Block sounds
            return Plugin_Stop; 
        }
    }
    
    // Allow sounds
    return Plugin_Continue;
}