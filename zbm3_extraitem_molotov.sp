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
public Plugin Molotov =
{
    name            = "[ZP] ExtraItem: Molotov",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME                "Molotov" // Only will be taken from translation file         
#define EXTRA_ITEM_COST                2
#define EXTRA_ITEM_LEVEL               0
#define EXTRA_ITEM_ONLINE              0
#define EXTRA_ITEM_LIMIT               0
/**
 * @endsection
 **/
 
/**
 * @section Properties of the grenade.
 **/
#define GRENADE_IGNITE_DAMAGE          7.0     // Damage of molotov multiplier (2.0 = double damage)
#define GRENADE_IGNITE_DURATION        5.0     // Burning duration in seconds
#define GRENADE_IGNITE_SPEED_RATIO     2.0     // Burning ratio which reduce speed
#define GRENADE_IGNITE_SPEED_NEMESIS   false   // Can nemesis be slowed [false-no // true-yes]
/**
 * @endsection
 **/
 
/**
 * @section Water levels.
 **/
#define WLEVEL_CSGO_DRY                0
#define WLEVEL_CSGO_FEET               1
#define WLEVEL_CSGO_HALF               2
#define WLEVEL_CSGO_FULL               3
/**
 * @endsection
 **/

// Initialize variables
Handle Task_ZombieBurned[MAXPLAYERS+1] = INVALID_HANDLE; float flSpeed[MAXPLAYERS+1];
 
// Item index
int iItem;
#pragma unused iItem

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook player events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);

        // Initilizate extra item
        iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);
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
        // Purge timer
        Task_ZombieBurned[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Reset variable
    flSpeed[clientIndex] = 0.0;
    
    // Delete timer
    delete Task_ZombieBurned[clientIndex];
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

    // Reset variable
    flSpeed[clientIndex] = 0.0;

    // Delete timer
    delete Task_ZombieBurned[clientIndex];
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
    // Reset variable
    flSpeed[clientIndex] = 0.0;
    
    // Delete timer
    delete Task_ZombieBurned[clientIndex];
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientHumanized(int clientIndex)
{
    // Reset variable
    flSpeed[clientIndex] = 0.0;
    
    // Delete timer
    delete Task_ZombieBurned[clientIndex];
}

/**
 * Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Handled;
    }
    
    // Check the item's index
    if(extraitemIndex == iItem)
    {
        // If you don't allowed to buy, then stop
        if(IsPlayerHasWeapon(clientIndex, "MolotovNade") || ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
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
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // Check the item's index
    if(extraitemIndex == iItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, "MolotovNade");
    }
}

/**
 * Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageType        The ditfield of damage types
 **/
public void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount, int damageType)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // Client was damaged by 'fire' or 'burn'
    if(damageType & DMG_BURN || damageType & DMG_DIRECT)
    {
        // Verify that the victim is zombie
        if(ZP_IsPlayerZombie(clientIndex))
        {
            // If the victim is in the water or freezed
            if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") > WLEVEL_CSGO_FEET || GetEntityMoveType(clientIndex) == MOVETYPE_NONE)
            {
                // This instead of 'ExtinguishEntity' function
                int fireIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hEffectEntity");
                if(IsValidEdict(fireIndex))
                {
                    // Make sure the entity is a flame, so we can extinguish it
                    static char sClassname[SMALL_LINE_LENGTH];
                    GetEdictClassname(fireIndex, sClassname, sizeof(sClassname));
                    if(!strcmp(sClassname, "entityflame", false))
                    {
                        SetEntPropFloat(fireIndex, Prop_Data, "m_flLifetime", 0.0);
                    }
                }
            }
            else
            {
                // Put the fire on
                if(damageType & DMG_BURN) IgniteEntity(clientIndex, GRENADE_IGNITE_DURATION);

                // Return damage multiplier
                damageAmount *= GRENADE_IGNITE_DAMAGE;
                
                // Validate nemesis
                if(ZP_IsPlayerNemesis(clientIndex) && !GRENADE_IGNITE_SPEED_NEMESIS) 
                {
                    // Block speed reduce for nemesis
                    return;
                }
                
                // Store the current speed
                if(!flSpeed[clientIndex]) flSpeed[clientIndex] = GetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue");

                // Sets a new speed
                SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", flSpeed[clientIndex] / GRENADE_IGNITE_SPEED_RATIO);
                
                // Validate that timer not execute
                if(Task_ZombieBurned[clientIndex] == INVALID_HANDLE)
                {
                    // Create timer for removing stopping
                    delete Task_ZombieBurned[clientIndex];
                    Task_ZombieBurned[clientIndex] = CreateTimer(1.0, ClientRemoveBurnEffect, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
                }
                
                // Return on success
                return;
            }
        }
        
        // Block damage
        damageAmount *= 0.0;
    }
}

/**
 * Timer for remove burn effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveBurnEffect(Handle hTimer, int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Clear timer 
    Task_ZombieBurned[clientIndex] = INVALID_HANDLE;

    // Validate client
    if(clientIndex)
    {    
        // Sets the previous speed
        SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", flSpeed[clientIndex]);
    }
    
    // Reset variable
    flSpeed[clientIndex] = 0.0;

    // Destroy timer
    return Plugin_Stop;
}