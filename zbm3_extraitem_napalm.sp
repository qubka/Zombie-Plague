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
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(StrEqual(sLibrary, "zombieplague"))
    {
        // Initilizate extra item
        iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, TEAM_HUMAN, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);

        // Hook entity events
        HookEvent("hegrenade_detonate", EventEntityExplosion, EventHookMode_Post);
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
	if(IsPlayerExist(ownerIndex) && ZP_IsPlayerHuman(ownerIndex))
	{
        // Initialize vectors
        static float vExpOrigin[3]; static float vVictimOrigin[3]; static float vVelocity[3];

        // Get all required event info
        int entityIndex = GetEventInt(gEventHook, "entityid");
        vExpOrigin[0] = GetEventFloat(gEventHook, "x"); 
        vExpOrigin[1] = GetEventFloat(gEventHook, "y"); 
        vExpOrigin[2] = GetEventFloat(gEventHook, "z");

        // Validate entity
        if(IsValidEdict(entityIndex))
        {
            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate client
                if(IsPlayerExist(i) && ZP_IsPlayerZombie(i) && !ZP_IsPlayerNemesis(i))
                {
                    // Get victim's origin
                    GetClientAbsOrigin(i, vVictimOrigin);
                    
                    // Calculate the distance
                    float flDistance = GetVectorDistance(vExpOrigin, vVictimOrigin);
                    
                    // Validate distance
                    if(flDistance <= GetConVarFloat(FindConVar("zp_grenade_exp_radius")))
                    {				
                        // Calculate the push power
                        float flKnockBack = FloatMul(GetConVarFloat(FindConVar("zp_grenade_exp_knockback")), (1.0 - (FloatDiv(flDistance, GetConVarFloat(FindConVar("zp_grenade_exp_radius"))))));

                        // Calculate the velocity's vector
                        SubtractVectors(vVictimOrigin, vExpOrigin, vVelocity);
                        
                        // Normalize the vector (equal magnitude at varying distances)
                        NormalizeVector(vVelocity, vVelocity);
                        
                        // Apply the magnitude by scaling the vector
                        ScaleVector(vVelocity, SquareRoot(FloatDiv(FloatMul(flKnockBack, flKnockBack), (FloatAdd(FloatAdd(FloatMul(vVelocity[0], vVelocity[0]), FloatMul(vVelocity[1], vVelocity[1])), FloatMul(vVelocity[2], vVelocity[2])))))); FloatMul(vVelocity[2], 10.0);

                        // Push the victim
                        TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vVelocity);
                    }
                }
            }
            
            // Remove grenade
            AcceptEntityInput(entityIndex, "Kill");
        }
    }
}