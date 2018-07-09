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
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin UnStuck =
{
    name            = "[ZP] Menu: UnStuck",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Menu for unstucking player and teleport them on respawn point",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Array to store spawn origin
float gPosition[MAXPLAYERS+1][3];

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Create a command
        RegConsoleCmd("zstuck", Command_Unstuck, "Unstuck player from the another entity.");
    }
}

/**
 * Handles the zstuck command. Unstuck player from the another entity.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action Command_Unstuck(int clientIndex, int iArguments)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    /* 
     * Checks to see if a player would collide with MASK_SOLID. (i.e. they would be stuck)
     * Inflates player mins/maxs a little bit for better protection against sticking.
     * Thanks to Andersso for the basis of this function.
     */
    
    // Initialize vector variables
    static float vPosition[3]; static float vMax[3]; static float vMin[3]; 

    // Gets client's location
    GetClientAbsOrigin(clientIndex, vPosition);
    
    // Gets the client's min and max size vector
    GetClientMins(clientIndex, vMin);
    GetClientMaxs(clientIndex, vMax);

    // Starts up a new trace hull using a global trace result and a customized trace ray filter
    TR_TraceHullFilter(vPosition, vPosition, vMin, vMax, MASK_SOLID, FilterStuck, clientIndex);

    // Returns if there was any kind of collision along the trace ray
    if(TR_DidHit())
    {
        // Teleport player back on the previus spawn point
        TeleportEntity(clientIndex, gPosition[clientIndex], NULL_VECTOR, NULL_VECTOR);
    }
    else
    {
        // Emit fail sound
        ClientCommand(clientIndex, "play buttons/button11.wav");    
    }
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientHumanized(int clientIndex)
{
    // Validate client
    if(IsPlayerExist(clientIndex))
    {
        // Gets client's position
        GetClientAbsOrigin(clientIndex, gPosition[clientIndex]);
    }   
}


/*
 * Trace filtering functions
 */

 
/**
 * Trace filter.
 *
 * @param clientIndex       The client index.
 * @param contentsMask      The contents mask.
 * @param hitIndex          The hit index.
 **/
public bool FilterStuck(int clientIndex, int contentsMask, any hitIndex) 
{
    return (clientIndex != hitIndex);
}