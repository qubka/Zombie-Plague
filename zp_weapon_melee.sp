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
    name            = "[ZP] Weapon: Melee",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Weapon index
int gWeapon1; int gWeapon2; int gWeapon3; int gWeapon4; 
#pragma unused gWeapon1, gWeapon2, gWeapon3, gWeapon4

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon1 = ZP_GetWeaponNameID("fists");
    if(gWeapon1 == -1) SetFailState("[ZP] Custom weapon ID from name : \"fists\" wasn't find");
    gWeapon2 = ZP_GetWeaponNameID("spanner");
    if(gWeapon2 == -1) SetFailState("[ZP] Custom weapon ID from name : \"spanner\" wasn't find");
    gWeapon3 = ZP_GetWeaponNameID("axe");
    if(gWeapon3 == -1) SetFailState("[ZP] Custom weapon ID from name : \"axe\" wasn't find");
    gWeapon4 = ZP_GetWeaponNameID("hammer");
    if(gWeapon4 == -1) SetFailState("[ZP] Custom weapon ID from name : \"hammer\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param clientIndex       The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon1 || weaponID == gWeapon2 || weaponID == gWeapon3 || weaponID == gWeapon4)
    {
        // Button secondary attack press
        if(iButtons & IN_ATTACK2)
        {
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
    }
    
    // Allow button
    return Plugin_Continue;
}