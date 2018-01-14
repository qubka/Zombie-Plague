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
public Plugin Flare =
{
	name        	= "[ZP] ExtraItem: Flare",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon of extra items",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"@Flare Grenade" // If string has @, phrase will be taken from translation file		 
#define EXTRA_ITEM_COST				7
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
    }
}

/**
 * Called after select an extraitem in equipment menu.
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
		if(IsPlayerHasWeapon(clientIndex, "weapon_decoy") || ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Handled;
		}
		
		// Give item and select it
		GivePlayerItem(clientIndex, "weapon_decoy");
		FakeClientCommandEx(clientIndex, "use weapon_decoy");
	}
	
	// Allow buying
	return Plugin_Continue;
}

/**
 * Event callback (decoy_firing)
 * The decoy nade is fired.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    	If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityDecoy(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get real player index from event key
	int ownerIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 
	
	// Validate client
	if(IsPlayerExist(ownerIndex) && ZP_IsPlayerHuman(ownerIndex))
	{
        // Initialize vectors
        float vExpOrigin[3];

        // Get all required event info
        int entityIndex = GetEventInt(gEventHook, "entityid");
        vExpOrigin[0] = GetEventFloat(gEventHook, "x"); 
        vExpOrigin[1] = GetEventFloat(gEventHook, "y"); 
        vExpOrigin[2] = GetEventFloat(gEventHook, "z");

        // Validate entity
        if(IsValidEdict(entityIndex))
        {
            // Initialize grenade color
            static char sGrenadeColorLight[SMALL_LINE_LENGTH];
            GetConVarString(FindConVar("zp_grenade_light_color"), sGrenadeColorLight, sizeof(sGrenadeColorLight)); 
            
            // Generate color for random choose
            if(!IsCharNumeric(sGrenadeColorLight[0]))
            {
                Format(sGrenadeColorLight, sizeof(sGrenadeColorLight), "%i %i %i 255", GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255));
            }
            
            // Emit sound
            EmitSoundToAll("items/nvg_on.wav", entityIndex, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
            
            // Create an light_dynamic entity
            int iLight = CreateEntityByName("light_dynamic");
            
            // If entity isn't valid, then skip
            if(IsValidEdict(iLight))
            {
                // Set the inner (bright) angle
                DispatchKeyValue(iLight, "inner_cone", "0");
                
                // Set the outer (fading) angle
                DispatchKeyValue(iLight, "cone", "80");
                
                // Set the light brightness
                DispatchKeyValue(iLight, "brightness", "1");
                
                // Used instead of Pitch Yaw Roll's value for reasons unknown
                DispatchKeyValue(iLight, "pitch", "90");
                
                // Change the lightstyle (see Appearance field for possible values)
                DispatchKeyValue(iLight, "style", "1");
                
                // Set the light's render color (R G B)
                DispatchKeyValue(iLight, "_light", sGrenadeColorLight);
                
                // Set the maximum light distance
                DispatchKeyValueFloat(iLight, "distance", GetConVarFloat(FindConVar("zp_grenade_light_distance")));
                
                // Set the radius of the spotlight at the end point
                DispatchKeyValueFloat(iLight, "spotlight_radius", GetConVarFloat(FindConVar("zp_grenade_light_radius")));

                // Spawn the entity
                DispatchSpawn(iLight);

                // Activate the enity
                AcceptEntityInput(iLight, "TurnOn");

                // Teleport the entity
                TeleportEntity(iLight, vExpOrigin, NULL_VECTOR, NULL_VECTOR);

                // Initialize time
                static char sTime[SMALL_LINE_LENGTH];
                Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", GetConVarFloat(FindConVar("zp_grenade_light_duration")));
                
                // Set modified flags on the entity
                SetVariantString(sTime);
                AcceptEntityInput(iLight, "AddOutput");
                AcceptEntityInput(iLight, "FireUser1");
            }
             
            // Create dust effect
            TE_SetupDust(vExpOrigin, NULL_VECTOR, 10.0, 1.0);
            TE_SendToAll();
            
            // Remove grenade
            AcceptEntityInput(entityIndex, "Kill");
        }
    }
}

