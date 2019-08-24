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
    name            = "[ZP] Weapon: C4 Charge",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

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
    if (!strcmp(sLibrary, "zombieplague", false))
    {
        // If map loaded, then run custom forward
        if (ZP_IsMapLoaded())
        {
            // Execute it
            ZP_OnEngineExecute();
        }
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("breachcharge");
    //if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"breachcharge\" wasn't find");
}

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param bits              The ditfield of damage types.
 * @param weapon            The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &weapon)
{
    // Client was damaged by 'explosion'
    if (iBits & DMG_BLAST)
    {
        // Validate inflicter
        if (IsValidEdict(inflictor))
        {
            // Validate custom grenade
            if (GetEntProp(inflictor, Prop_Data, "m_iHammerID") == gWeapon)
            {
                // Resets explosion damage
                flDamage *= ZP_IsPlayerHuman(client) ? 0.0 : ZP_GetWeaponDamage(gWeapon);
            }
        }
    }
}