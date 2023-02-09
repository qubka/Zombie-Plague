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
	name            = "[ZP] ExtraItem: Buy Nemesis",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of extra items",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Item index
int gItem;

// Type index
int gType;

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
	// Items
	gItem = ZP_GetExtraItemNameID("nemesis");
	//if (gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"nemesis\" wasn't find");

	// Types
	gType = ZP_GetClassTypeID("nemesis");
	if (gType == -1) SetFailState("[ZP] Custom class type ID from name : \"nemesis\" wasn't find");
}

/**
 * @brief Called before show an extraitem in the equipment menu.
 * 
 * @param client            The client index.
 * @param itemID            The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int client, int itemID)
{
	// Check the item's index
	if (itemID == gItem)
	{
		// If round didnt started, then stop
		if (!ZP_IsStartedRound())
		{
			return Plugin_Handled;
		}
	}

	// Allow showing
	return Plugin_Continue;
}

/**
 * @brief Called after select an extraitem in the equipment menu.
 * 
 * @param client            The client index.
 * @param itemID            The item index.
 **/
public void ZP_OnClientBuyExtraItem(int client, int itemID)
{
	// Check the item's index
	if (itemID == gItem)
	{
		// Change class to nemesis
		ZP_ChangeClient(client, -1, gType);
	}
}
