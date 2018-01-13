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
public Plugin AntiDot =
{
	name        	= "[ZP] ExtraItem: Antidot",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon of extra items",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"@Antidot" // If string has @, phrase will be taken from translation file 	
#define EXTRA_ITEM_COST				20			
#define EXTRA_ITEM_LEVEL			0
#define EXTRA_ITEM_ONLINE			0
#define EXTRA_ITEM_LIMIT			0
/**
 * @endsection
 **/

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
    if(StrEqual(sLibrary, "zombieplague"))
    {
        // Initilizate extra item
        iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, TEAM_ZOMBIE, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);
    }
}

/**
 * Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex		The client index.
 * @param extraitemIndex	The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return					Plugin_Handled or Plugin_Stop to block purhase. Anything else
 *                          	(like Plugin_Continue) to allow purhase and taking ammopacks.
 **/
public Action ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
	#pragma unused clientIndex, extraitemIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Handled;
	}
	
	// Check the item's index
	if(extraitemIndex == iItem)
	{
		// If you don't allowed to buy, then return ammopacks
		if(ZP_GetZombieAmount() <= 1 || ZP_IsPlayerHuman(clientIndex))
		{
			return Plugin_Handled;
		}
		
		// Initialize round type
		int CMode = ZP_GetRoundState(SERVER_ROUND_MODE);

		// Switch game round
		switch(CMode)
		{
			// If specific game round modes, then don't allowed to buy and return ammopacks
			case MODE_NONE, MODE_NEMESIS, MODE_SURVIVOR, MODE_ARMAGEDDON : return Plugin_Handled;
			
			// Change class to human
			default : ZP_SwitchClientClass(clientIndex, TYPE_HUMAN);
		}
	}
	
	// Allow buying
	return Plugin_Continue;
}