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
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: Armor",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Initialize variable
bool bArmored[MAXPLAYERS+1];

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Item index
int gItem;
#pragma unused gItem

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItem = ZP_GetExtraItemNameID("anti infection armor");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"anti infection armor\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("ARMOR_BUY_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"ARMOR_BUY_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    if(hSoundLevel == INVALID_HANDLE) SetFailState("[ZP] Custom cvar key ID from name : \"zp_game_custom_sound_level\" wasn't find");
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
 * @param extraitemIndex    The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item's index
    if(extraitemIndex == gItem)
    {
        // Validate class
        if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
        {
            return Plugin_Stop;
        }

        // Validate access
        if(GetClientArmor(clientIndex) >= 100)
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
 * @param extraitemIndex    The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item's index
    if(extraitemIndex == gItem)
    {
        // Give item
        SetEntProp(clientIndex, Prop_Send, "m_ArmorValue", 100, 1);
        
        // Validate no armor before
        if(!bArmored[clientIndex]) 
        {
            // Initialize vectors
            static float vPosition[3];
            
            // Gets the client origin
            GetClientAbsOrigin(clientIndex, vPosition);
    
            // Create an effect
            FakeCreateParticle(clientIndex, vPosition, _, "nimb_final", 9999.9);
            bArmored[clientIndex] = true;
        }
        
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound));
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
    }
}
