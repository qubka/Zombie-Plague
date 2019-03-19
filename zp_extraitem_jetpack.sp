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
    name            = "[ZP] ExtraItem: JetPack",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Timer index
Handle Task_JetPackReload[MAXPLAYERS+1] = null; int gItemDuration[MAXPLAYERS+1]; 
 
// Sound index
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
        // Load translations phrases used by plugin
        LoadTranslations("zombieplague.phrases");
    }
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timers
        Task_JetPackReload[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItem = ZP_GetExtraItemNameID("jetpack");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"jetpack\" wasn't find");
    
    // Weapons
    gWeapon = ZP_GetWeaponNameID("jetpack");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"jetpack\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("JETPACK_FLY_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JETPACK_FLY_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Reset duration
    gItemDuration[clientIndex] = 0;
    
    // Delete timer
    delete Task_JetPackReload[clientIndex];
}

/**
 * Event callback (player_death)
 * @brief Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerDeath(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));
    
    // Reset duration
    gItemDuration[clientIndex] = 0;
    
    // Delete timer
    delete Task_JetPackReload[clientIndex];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientUpdated(int clientIndex, int attackerIndex)
{
    // Reset duration
    gItemDuration[clientIndex] = 0;

    // Delete timer
    delete Task_JetPackReload[clientIndex];
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
        if(GetEntProp(clientIndex, Prop_Send, "m_bHasDefuser"))
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

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Item_OnActivate(int clientIndex)
{
    // Validate delay
    if(IsDelay(clientIndex, 0.1))
    {
        return;
    }

    // Validate duration
    if(gItemDuration[clientIndex] < ZP_GetWeaponClip(gWeapon))
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; 
        
        // Gets client angle
        GetClientEyeAngles(clientIndex, vAngle); vAngle[0] = -40.0;
        
        // Gets location's angles
        GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
        
        // Scale vector for the boost
        ScaleVector(vVelocity, ZP_GetWeaponSpeed(gWeapon));
        
        // Push the player
        TeleportEntity(clientIndex, NULL_VECTOR, NULL_VECTOR, vVelocity);
        
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound));
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Gets backback index
        int entityIndex = ZP_GetClientAttachModel(clientIndex, BitType_DefuseKit);

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Gets attachment position
            ZP_GetAttachment(entityIndex, "1", vPosition, vAngle);
            
            // Create an effect
            ZP_CreateParticle(entityIndex, vPosition, _, "smoking", 0.5);
        }
    }
    else
    {
        // Validate limit 
        if(gItemDuration[clientIndex] == ZP_GetWeaponClip(gWeapon))
        {
            // Create a reloading timer
            delete Task_JetPackReload[clientIndex];
            Task_JetPackReload[clientIndex] = CreateTimer(ZP_GetWeaponReload(gWeapon), ItemOnReload, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
        }
        // If it in process of reloading, show the message
        else
        {
            // Show message
            SetGlobalTransTarget(clientIndex);
            PrintHintText(clientIndex, "%t", "jetpack empty");
        }
    }
    
    // Update duration
    gItemDuration[clientIndex]++;
}

/**
 * @brief Timer for reload jetpack.
 *
 * @param hTimer            The timer handle.
 * @param clientIndex       The user id.
 **/
public Action ItemOnReload(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Clear timer 
    Task_JetPackReload[clientIndex] = null;
    
    // Validate client
    if(clientIndex)
    {
        // Reset duration
        gItemDuration[clientIndex] = 0;

        // Show message
        SetGlobalTransTarget(clientIndex);
        PrintHintText(clientIndex, "%t", "jetpack reloaded");
    }
    
    // Destroy timer
    return Plugin_Stop;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1)            \
                                \
    Item_On%0                   \
    (                           \
        %1                      \
    )    
    
/**
 * Event: ItemPostFrame
 * @brief Item is holding.
 *  
 * @param clientIndex       The client index.
 * @param iButtons          Copyback buffer containing the current commands (as bitflags - see entity_prop_stocks.inc).
 * @param iImpulse          Copyback buffer containing the current impulse command.
 * @param flVelocity        Players desired velocity.
 * @param flAngles          Players desired view angles.    
 * @param weaponID          The entity index of the new weapon if player switches weapon, 0 otherwise.
 * @param iSubType          Weapon subtype when selected from a menu.
 * @param iCmdNum           Command number. Increments from the first command sent.
 * @param iTickCount        Tick count. A client prediction based on the server GetGameTickCount value.
 * @param iSeed             Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param iMouse            Mouse direction (x, y).
 **/ 
public Action OnPlayerRunCmd(int clientIndex, int &iButtons, int &iImpulse, float flVelocity[3], float flAngles[3], int &weaponID, int &iSubType, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
    // Button jump/duck press
    if((iButtons & IN_JUMP) && (iButtons & IN_DUCK))
    {
        // Validate defuser
        if(GetEntProp(clientIndex, Prop_Send, "m_bHasDefuser"))
        {
            // Call event
            _call.Activate(clientIndex);
        }
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * @brief Delay function.
 * 
 * @param clientIndex       The client index.
 * @param flDelay           The delay time.
 **/
stock bool IsDelay(int clientIndex, float flDelay)
{
    // Initialize delay
    static float flTime[MAXPLAYERS+1];
    
    // Gets simulated game time
    float flCurrentTime = GetTickedTime();
    
    // Validate delay
    if((flCurrentTime - flTime[clientIndex]) < flDelay)
    {
        // Block usage
        return true;
    }
    
    // Update countdown time
    flTime[clientIndex] = flCurrentTime;
    return false;
}