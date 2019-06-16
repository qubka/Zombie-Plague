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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: JetPack",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of custom weapon",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Timer index
Handle hItemReload[MAXPLAYERS+1] = null; Handle hItemDuration[MAXPLAYERS+1];

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Item index
int gWeapon;
#pragma unused gWeapon

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
        
        // If map loaded, then run custom forward
        if(ZP_IsMapLoaded())
        {
            // Execute it
            ZP_OnEngineExecute();
        }
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
        hItemReload[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
        hItemDuration[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("jetpack");
    //if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"jetpack\" wasn't find");
    
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
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
    // Delete timers
    delete hItemReload[client];
    delete hItemDuration[client];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
    // Delete timers
    delete hItemReload[client];
    delete hItemDuration[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
    // Delete timer
    delete hItemReload[client];
    delete hItemDuration[client];
}

/**
 * @brief Called before show a weapon in the weapons menu.
 * 
 * @param client            The client index.
 * @param weaponID          The weapon index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
public Action ZP_OnClientValidateWeapon(int client, int weaponID)
{
    // Check the weapon index
    if(weaponID == gWeapon)
    {
        // Validate access
        if(GetEntProp(client, Prop_Send, "m_bHasDefuser"))
        {
            return Plugin_Handled;
        }
    }

    // Allow showing
    return Plugin_Continue;
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Item_OnActive(int client)
{
    // Validate delay
    if(IsItemActive(client, 0.1))
    {
        return;
    }
    
    // If jetpack is reloaded, then stop
    if(hItemReload[client] != null)
    {
        return;
    }
    
    // If jetpack isn't started, then begin
    if(hItemDuration[client] == null)
    {
        // Get the working duration
        float flDuration = ZP_GetWeaponDeploy(gWeapon);
        
        // Create a disabling timer
        hItemDuration[client] = CreateTimer(flDuration, Item_OnDisable, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    
        // Sets progress bar
        ZP_SetProgressBarTime(client, RoundToNearest(flDuration));
    }
    
    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; 
    
    // Gets client angle
    GetClientEyeAngles(client, vAngle); vAngle[0] = -40.0;
    
    // Gets location's angles
    GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
    
    // Scale vector for the boost
    ScaleVector(vVelocity, ZP_GetWeaponSpeed(gWeapon));
    
    // Push the player
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
    
    // Play sound
    ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, hSoundLevel.IntValue);
    
    // Gets backback index
    int entity = ZP_GetClientAttachModel(client, BitType_DefuseKit);

    // Validate entity
    if(entity != -1)
    {
        // Gets attachment position
        ZP_GetAttachment(entity, "1", vPosition, vAngle);
        
        // Gets weapon muzzleflesh
        static char sMuzzle[NORMAL_LINE_LENGTH];
        ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
        
        // Create an effect
        UTIL_CreateParticle(entity, vPosition, _, _, sMuzzle, 0.5);
    }
}

/**
 * @brief Timer for disabled jetpack.
 *
 * @param hTimer            The timer handle.
 * @param client            The user id.
 **/
public Action Item_OnDisable(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID);
    
    // Clear timer 
    hItemDuration[client] = null;
    
    // Validate client
    if(client)
    {
        // Resets the progress bar
        ZP_SetProgressBarTime(client, 0);
        
        // Show message
        SetGlobalTransTarget(client);
        PrintHintText(client, "%t", "jetpack empty");
        
        // Create a reloading timer
        delete hItemReload[client];
        hItemReload[client] = CreateTimer(ZP_GetWeaponReload(gWeapon), Item_OnReload, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Timer for reload jetpack.
 *
 * @param hTimer            The timer handle.
 * @param client            The user id.
 **/
public Action Item_OnReload(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID);
    
    // Clear timer 
    hItemReload[client] = null;
    
    // Validate client
    if(client)
    {
        // Show message
        SetGlobalTransTarget(client);
        PrintHintText(client, "%t", "jetpack reloaded");
    }
    
    // Destroy timer
    return Plugin_Stop;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1) \
                     \
    Item_On%0        \
    (                \
        %1           \
    )    
    
/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param client            The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
    // Button jump/duck press
    if((iButtons & IN_JUMP) && (iButtons & IN_DUCK))
    {
        // Validate defuser
        if(GetEntProp(client, Prop_Send, "m_bHasDefuser"))
        {
            // Call event
            _call.Active(client);
        }
    }
    
    // Allow button
    return Plugin_Continue;
}

//**********************************************
//* Useful stocks.                             *
//**********************************************

/**
 * @brief Validate the active delay.
 * 
 * @param client            The client index.
 * @param flTimeDelay       The delay time.
 **/
stock bool IsItemActive(int client, float flTimeDelay)
{
    // Initialize delay
    static float flActiveTime[MAXPLAYERS+1];
    
    // Gets simulated game time
    float flCurrentTime = GetTickedTime();
    
    // Validate delay
    if((flCurrentTime - flActiveTime[client]) < flTimeDelay)
    {
        return true;
    }
    
    // Update the active delay
    flActiveTime[client] = flCurrentTime;
    return false;
}