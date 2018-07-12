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
public Plugin Armor =
{
    name            = "[ZP] ExtraItem: Armor",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME                "Anti-Infection Armor"    // Only will be taken from translation file    
#define EXTRA_ITEM_COST                5
#define EXTRA_ITEM_LEVEL               0
#define EXTRA_ITEM_ONLINE              0
#define EXTRA_ITEM_LIMIT               0
/**
 * @endsection
 **/
 
// Initialize variable
bool bArmored[MAXPLAYERS+1];

// ConVar for sound level
ConVar hSoundLevel;
 
// Item index
int gItem;
#pragma unused gItem

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initilizate extra item
        gItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);
    }
}

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been executed, and all plugin configs are done executing.
 **/
public void OnConfigsExecuted(/*void*/)
{
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
    // Reset variable
    bArmored[clientIndex] = false;
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
    bArmored[clientIndex] = false;
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientHumanized(int clientIndex)
{
    // Reset variable
    bArmored[clientIndex] = false;
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
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Stop;
    }
    
    // Check the item's index
    if(extraitemIndex == gItem)
    {
        // If you don't allowed to buy, then stop
        if(GetClientArmor(clientIndex) >= 100 || ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
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
    if(extraitemIndex == gItem)
    {
        // Give item
        SetEntProp(clientIndex, Prop_Send, "m_ArmorValue", 100, 1);
        
        // Validate no armor before
        if(!bArmored[clientIndex]) 
        {
            // Create an effect
            FakeCreateParticle(clientIndex, _, "nimb_final", 9999.9);
            bArmored[clientIndex] = true;
        }
        
        // Emit sound
        EmitSoundToAll("*/zbm3/kevlar.mp3", clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
    }
}
