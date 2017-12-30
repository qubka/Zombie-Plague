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
public Plugin HeGrenade =
{
	name        	= "[ZP] ExtraItem: Hegrenade",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon of extra items",
	version     	= "2.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"@Hegrenade" // If string has @, phrase will be taken from translation file	 	
#define EXTRA_ITEM_COST				1
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
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, TEAM_HUMAN, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);

	// Hook entity events
	HookEvent("hegrenade_detonate", EventEntityExplosion, EventHookMode_Post);
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
		if(IsPlayerHasWeapon(clientIndex, "weapon_hegrenade") || ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Handled;
		}
			
		// Give item and select it
		GivePlayerItem(clientIndex, "weapon_hegrenade");
		FakeClientCommandEx(clientIndex, "use weapon_hegrenade");
	}
	
	// Allow buying
	return Plugin_Continue;
}


/**
 * Event callback (hegrenade_detonate)
 * The hegrenade is exployed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    	If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityExplosion(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get real player index from event key
	int ownerIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 
	
	// Validate client
	if(!IsPlayerExist(ownerIndex))
	{
		return;
	}
	
	// Initialize vector variables
	float flOrigin[3];

	// Get all required event info
	int entityIndex = GetEventInt(gEventHook, "entityid");
	flOrigin[0] = GetEventFloat(gEventHook, "x"); 
	flOrigin[1] = GetEventFloat(gEventHook, "y"); 
	flOrigin[2] = GetEventFloat(gEventHook, "z");

	// If entity isn't valid, then stop
	if(!IsValidEdict(entityIndex))
	{
		return;
	}

	// Forward event to modules
	GrenadeOnHeDetonate(ownerIndex, entityIndex, flOrigin);
}

/**
 * The hegrenade nade is exployed.
 * 
 * @param ownerIndex		The owner index.
 * @param entityIndex		The entity index.  
 * @param flOrigin			The explosion origin.
 **/
void GrenadeOnHeDetonate(int ownerIndex, int entityIndex, float flOrigin[3])
{
	// Validate that thrower is human
	if(ZP_IsPlayerHuman(ownerIndex))
	{
		// Initialize vector variables
		float flVictimOrigin[3];
		
		// i = client index
		for (int i = 1; i <= MaxClients; i++)
		{
			// Validate client
			if(IsPlayerExist(i))
			{
				// Get victim's position
				GetClientAbsOrigin(i, flVictimOrigin);
				flVictimOrigin[2] += 2.0;
				
				// Initialize distance variable
				float flDistance = GetVectorDistance(flOrigin, flVictimOrigin);
				
				// If distance to the entity is less than the radius of explosion
				if(flDistance <= GetConVarFloat(FindConVar("zp_grenade_exp_radius")))
				{				
					// Push entity
					GrenadeOnEntityExploade(i, flOrigin, flVictimOrigin, flDistance);
				}
			}
		}
	}
	
	// Remove grenade
	RemoveEdict(entityIndex);
}

/**
 * Player is about to push back.
 *
 * @param clientIndex		The client index.
 * @param flOrigin			The explosion origin.
 * @param flVictimOrigin	The client origin.
 * @param flDistance		The distance bettween points.
 **/
void GrenadeOnEntityExploade(int clientIndex, float flOrigin[3], float flVictimOrigin[3], float flDistance)
{
	#pragma unused clientIndex
	
	// Verify that the client is a zombie
	if(!ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerNemesis(clientIndex))
	{
		return;
	}

	// Initialize velocity vector
	float flVelocity[3];
	
	// Get knockpback power
	float flKnockBack = GetConVarFloat(FindConVar("zp_grenade_exp_knockback")) * (1.0 - (flDistance / GetConVarFloat(FindConVar("zp_grenade_exp_radius"))));

	// Calculate velocity
	flVelocity[0] = flVictimOrigin[0] - flOrigin[0];
	flVelocity[1] = flVictimOrigin[1] - flOrigin[1];
	flVelocity[2] = flVictimOrigin[2] - flOrigin[2];
	
	// Calculate push power
	float flPower = SquareRoot(flKnockBack * flKnockBack / (flVelocity[0] * flVelocity[0] + flVelocity[1] * flVelocity[1] + flVelocity[2] * flVelocity[2]));
	flVelocity[0] *= flPower;
	flVelocity[1] *= flPower;
	flVelocity[2] *= flPower * 10.0;

	// Push away
	TeleportEntity(clientIndex, NULL_VECTOR, NULL_VECTOR, flVelocity);
}
