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
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin Ammunition =
{
	name        	= "[ZP] Addon: ",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Give grenades on the spawn",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Hook player events
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

/**
 * Event callback (player_spawn)
 * The player is spawning.
 * 
 * @param gEventHook      	The event handle.
 * @param gEventName        The name of the event.
 * @dontBroadcast   	    If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerSpawn(Event gEventHook, const char[] gEventName, bool dontBroadcast)
{
	// Get real player index from event key
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 

	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}

	// Get string with grenades
	static char sGrenades[NORMAL_LINE_LENGTH];
	GetConVarString(FindConVar("zp_human_grenades"), sGrenades, sizeof(sGrenades));
	
	// Check if string is empty, then skip
	if(strlen(sGrenades))
	{
		// Convert cvar string to pieces
		static char sType[6][SMALL_LINE_LENGTH];
		int  nPieces = ExplodeString(sGrenades, ",", sType, sizeof(sType), sizeof(sType[]));
		
		// Loop throught pieces
		for(int i = 0; i < nPieces; i++)
		{
			// Trim string
			TrimString(sType[i]);
			
			// Switch type with the current grenade
			switch(sType[i][0])
			{
				case 'i' : if(!IsPlayerHasWeapon(clientIndex, "weapon_incgrenade")) 	GivePlayerItem(clientIndex, "weapon_incgrenade");
				case 'd' : if(!IsPlayerHasWeapon(clientIndex, "weapon_decoy")) 		 	GivePlayerItem(clientIndex, "weapon_decoy");
				case 'm' : if(!IsPlayerHasWeapon(clientIndex, "weapon_molotov")) 	 	GivePlayerItem(clientIndex, "weapon_molotov");
				case 'f' : if(!IsPlayerHasWeapon(clientIndex, "weapon_flashbang")) 	 	GivePlayerItem(clientIndex, "weapon_flashbang");
				case 's' : if(!IsPlayerHasWeapon(clientIndex, "weapon_smokegrenade")) 	GivePlayerItem(clientIndex, "weapon_smokegrenade");
				case 'h' : if(!IsPlayerHasWeapon(clientIndex, "weapon_hegrenade")) 	 	GivePlayerItem(clientIndex, "weapon_hegrenade");
			}	
		}
	}
}