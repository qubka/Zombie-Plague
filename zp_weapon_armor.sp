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
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Weapon: Armor",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Item index
int gWeaponKevlar; int gWeaponAssault; int gWeaponHeavy;

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		if (ZP_IsMapLoaded())
		{
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeaponKevlar = ZP_GetWeaponNameID("kevlar");
	if (gWeaponKevlar == -1) SetFailState("[ZP] Custom weapon ID from name : \"kevlar\" wasn't find");
	gWeaponAssault = ZP_GetWeaponNameID("assaultsuit");
	if (gWeaponAssault == -1) SetFailState("[ZP] Custom weapon ID from name : \"assaultsuit\" wasn't find");
	gWeaponHeavy = ZP_GetWeaponNameID("heavysuit");
	if (gWeaponHeavy == -1) SetFailState("[ZP] Custom weapon ID from name : \"heavysuit\" wasn't find");
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
	if (weaponID == gWeaponKevlar)
	{
		if (GetEntProp(client, Prop_Send, "m_ArmorValue") >= ZP_GetWeaponClip(gWeaponKevlar))
		{
			return Plugin_Handled;
		}
	}
	else if (weaponID == gWeaponAssault)
	{
		if (GetEntProp(client, Prop_Send, "m_ArmorValue") >= ZP_GetWeaponClip(gWeaponAssault) || GetEntProp(client, Prop_Send, "m_bHasHelmet"))
		{
			return Plugin_Handled;
		}
	}
	else if (weaponID == gWeaponHeavy)
	{
		if (GetEntProp(client, Prop_Send, "m_ArmorValue") >= ZP_GetWeaponClip(gWeaponHeavy) || GetEntProp(client, Prop_Send, "m_bHasHeavyArmor"))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}
