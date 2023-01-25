/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
	name            = "[ZP] Weapon: Melee",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Weapon index
int gWeaponSpanner; int gWeaponAxe; int gWeaponHammer; 
#pragma unused gWeaponSpanner, gWeaponAxe, gWeaponHammer

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
	gWeaponSpanner = ZP_GetWeaponNameID("spanner");
	if (gWeaponSpanner == -1) SetFailState("[ZP] Custom weapon ID from name : \"spanner\" wasn't find");
	gWeaponAxe = ZP_GetWeaponNameID("axe");
	if (gWeaponAxe == -1) SetFailState("[ZP] Custom weapon ID from name : \"axe\" wasn't find");
	gWeaponHammer = ZP_GetWeaponNameID("hammer");
	if (gWeaponHammer == -1) SetFailState("[ZP] Custom weapon ID from name : \"hammer\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

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
	// Validate custom weapon
	if (weaponID == gWeaponSpanner || weaponID == gWeaponAxe || weaponID == gWeaponHammer)
	{
		// Button secondary attack press
		if (iButtons & IN_ATTACK2)
		{
			iButtons &= (~IN_ATTACK2); //! Bugfix
			return Plugin_Changed;
		}
	}
	
	// Allow button
	return Plugin_Continue;
}
