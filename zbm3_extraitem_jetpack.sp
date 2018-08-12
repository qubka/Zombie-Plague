/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: JetPack",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_REFERENCE           "jetpack" // Name in weapons.ini from translation file  
#define EXTRA_ITEM_INFO                "jetpack info" // Only will be taken from translation file 
#define EXTRA_ITEM_COST                50
#define EXTRA_ITEM_LEVEL               0
#define EXTRA_ITEM_ONLINE              0
#define EXTRA_ITEM_LIMIT               0
#define EXTRA_ITEM_GROUP               ""
/**
 * @endsection
 **/

// Initialize variables
Handle Task_JetPackReload[MAXPLAYERS+1] = INVALID_HANDLE; int gItemDuration[MAXPLAYERS+1]; 
 
// Variables for the key sound block
int gSound; ConVar hSoundLevel;

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initialize extra item
        gItem = ZP_RegisterExtraItem(EXTRA_ITEM_REFERENCE, EXTRA_ITEM_INFO, EXTRA_ITEM_COST, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT, EXTRA_ITEM_GROUP);
    
        // Load translations phrases used by plugin
        LoadTranslations("zombieplague.phrases");
    }
}

/**
 * The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timers
        Task_JetPackReload[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(EXTRA_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", EXTRA_ITEM_REFERENCE);
    
    // Sounds
    gSound = ZP_GetSoundKeyID("JETPACK_FLY_SOUNDS");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

/**
 * Called when a client is disconnecting from the server.
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
 * Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerDeath(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));
    
    // Reset duration
    gItemDuration[clientIndex] = 0;
    
    // Delete timer
    delete Task_JetPackReload[clientIndex];
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param victimIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param nemesisMode       Indicates that client will be a nemesis.
 * @param respawnMode       Indicates that infection was on spawn.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex, bool nemesisMode, bool respawnMode)
{
    // Reset duration
    gItemDuration[clientIndex] = 0;

    // Delete timer
    delete Task_JetPackReload[clientIndex];
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 * @param survivorMode      Indicates that client will be a survivor.
 * @param respawnMode       Indicates that humanizing was on spawn.
 **/
public void ZP_OnClientHumanized(int clientIndex, bool survivorMode, bool respawnMode)
{
    // Reset duration
    gItemDuration[clientIndex] = 0;

    // Delete timer
    delete Task_JetPackReload[clientIndex];
}

/**
 * Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Validate class
        if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
        {
            return Plugin_Stop;
        }

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
 * Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The index of extraitem from ZP_RegisterExtraItem() native.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, EXTRA_ITEM_REFERENCE);
    }
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Item_OnActivate(const int clientIndex)
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
        static float vPosition[3]; static float vVelocity[3]; static float vAngle[3];
        
        // Gets the client angle
        GetClientEyeAngles(clientIndex, vAngle); vAngle[0] = -40.0;
        
        // Gets location's angles
        GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
        
        // Scale vector for the boost
        ScaleVector(vVelocity, ZP_GetWeaponSpeed(gWeapon));
        
        // Push the player
        TeleportEntity(clientIndex, NULL_VECTOR, NULL_VECTOR, vVelocity);
        
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound));
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Gets the backback index
        int entityIndex = ZP_GetClientAttachModel(clientIndex, BitType_DefuseKit);

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Gets attachment position
            ZP_GetAttachment(entityIndex, "1", vPosition, vAngle);
            
            // Create an effect
            FakeCreateParticle(entityIndex, vPosition, _, "smoking", 0.5);
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
 * Timer for reload jetpack.
 *
 * @param hTimer            The timer handle.
 * @param clientIndex       The user id.
 **/
public Action ItemOnReload(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Clear timer 
    Task_JetPackReload[clientIndex] = INVALID_HANDLE;
    
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
 * Item is holding.
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
 * Delay function.
 * 
 * @param clientIndex        The client index.
 * @param flDelay            The delay time.
 **/
stock bool IsDelay(const int clientIndex, const float flDelay)
{
    // Initialize variable
    static float flTime[MAXPLAYERS+1];
    
    // Returns the game time based on the game tick
    float flCurrentTime = GetGameTime();
    
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