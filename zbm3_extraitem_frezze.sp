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
public Plugin Freeze =
{
	name        	= "[ZP] ExtraItem: Freeze",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon of extra items",
	version     	= "2.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"@Freeze Grenade" // If string has @, phrase will be taken from translation file		
#define EXTRA_ITEM_COST				5
#define EXTRA_ITEM_LEVEL			0
#define EXTRA_ITEM_ONLINE			0
#define EXTRA_ITEM_LIMIT			0
/**
 * @endsection
 **/

// Initialize variables
Handle Task_ZombieFreezed[MAXPLAYERS+1] = INVALID_HANDLE; 

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
        
        // Hook player events
        HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
        
        // Hook entity events
        HookEvent("smokegrenade_detonate", EventEntitySmoke, EventHookMode_Post);
    }
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Sounds
	FakePrecacheSound("zbm3/impalehit.mp3");
	FakePrecacheSound("zbm3/zombi_wood_broken.mp3");
	
	// Models
	FakePrecacheModel("models/spree/spree.mdl");
	AddFileToDownloadsTable("materials/models/spree/spree.vtf");
	AddFileToDownloadsTable("materials/models/hypy/hype.vmt");
	
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param clientIndex		The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
	// Delete timer
	delete Task_ZombieFreezed[clientIndex];
}

/**
 * Called when a client became a zombie.
 * 
 * @param clientIndex		The client index.
 * @param attackerIndex		The attacker index.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
	// Delete timer
	delete Task_ZombieFreezed[clientIndex];
}

/**
 * Event callback (player_spawn)
 * Client is spawning into the game.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    	If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerSpawn(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Delete timer
	delete Task_ZombieFreezed[GetClientOfUserId(GetEventInt(gEventHook, "userid"))];
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    	If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerDeath(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));

	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		// If the client isn't a player, a player really didn't die now. Some
		// other mods might sent this event with bad data.
		return;
	}

	// Delete timer
	delete Task_ZombieFreezed[clientIndex];
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
		if(IsPlayerHasWeapon(clientIndex, "weapon_smokegrenade") || ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Handled;
		}
			
		// Give item and select it
		GivePlayerItem(clientIndex, "weapon_smokegrenade");
		FakeClientCommandEx(clientIndex, "use weapon_smokegrenade");
	}
	
	// Allow buying
	return Plugin_Continue;
}

/**
 * Event callback (smokegrenade_detonate)
 * The smokegrenade is exployed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    	If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntitySmoke(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get real player index from event key
	int ownerIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 
	
	// Validate client
	if(IsPlayerExist(ownerIndex) && ZP_IsPlayerHuman(ownerIndex))
	{
        // Initialize vectors
        static float vExpOrigin[3]; static float vVictimOrigin[3]; static float vVictimAngle[3];

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
                if(IsPlayerExist(i) && (ZP_IsPlayerZombie(i) || ZP_IsPlayerNemesis(i) && GetConVarBool(FindConVar("zp_grenade_freeze_nemesis"))))
                {
                    // Get victim's origin
                    GetClientAbsOrigin(i, vVictimOrigin);
                    
                    // Get victim's eye angle
                    GetClientEyeAngles(i, vVictimAngle);
                    
                    // Calculate the distance
                    float flDistance = GetVectorDistance(vExpOrigin, vVictimOrigin);
                    
                    // Validate distance
                    if(flDistance <= GetConVarFloat(FindConVar("zp_grenade_freeze_radius")))
                    {			
                        // Freeze the client
                        SetEntityMoveType(i, MOVETYPE_NONE);

                        // Set blue render color
                        SetEntityRenderMode(i, RENDER_TRANSCOLOR);
                        SetEntityRenderColor(i, 120, 120, 255, 255);
                        
                        // Emit sound
                        EmitSoundToAll("*/zbm3/impalehit.mp3", i, SNDCHAN_STATIC, SNDLEVEL_NORMAL);

                        // Create timer for removing freezing
                        delete Task_ZombieFreezed[i];
                        Task_ZombieFreezed[i] = CreateTimer(GetConVarFloat(FindConVar("zp_grenade_freeze_time")), ClientRemoveFreezing, i, TIMER_FLAG_NO_MAPCHANGE);
                        
                        // Create a prop_dynamic entity
                        int iIce = CreateEntityByName("prop_dynamic");
                        
                        // Validate entity
                        if(IsValidEdict(iIce))
                        {
                            // Set the model
                            DispatchKeyValue(iIce, "model", "models/spree/spree.mdl");
                            
                            // Spawn the entity
                            DispatchSpawn(iIce);
                            TeleportEntity(iIce, vVictimOrigin, vVictimAngle, NULL_VECTOR);

                            // Sets the parent for the entity
                            SetVariantString("!activator");
                            AcceptEntityInput(iIce, "SetParent", i, i);
                            
                            // Initialize char
                            static char sTime[SMALL_LINE_LENGTH];
                            Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", GetConVarFloat(FindConVar("zp_grenade_freeze_time")));
                            
                            // Sets modified flags on entity
                            SetVariantString(sTime);
                            AcceptEntityInput(iIce, "AddOutput");
                            AcceptEntityInput(iIce, "FireUser1");
                        }
                    }
                }
            }

            // Create sparks splash effect
            TE_SetupSparks(vExpOrigin, NULL_VECTOR, 5000, 1000);
            TE_SendToAll();

            // Remove grenade
            AcceptEntityInput(entityIndex, "Kill");
        }
    }
}

/**
 * Timer for remove freeze.
 *
 * @param hTimer			The timer handle.
 * @param clientIndex		The client index.
 **/
public Action ClientRemoveFreezing(Handle hTimer, any clientIndex)
{
	// Clear timer 
	Task_ZombieFreezed[clientIndex] = INVALID_HANDLE;

	// Validate client
	if(IsPlayerExist(clientIndex))
	{
        // Unfreeze the client
        SetEntityMoveType(clientIndex, MOVETYPE_WALK);

        // Set standart render color
        SetEntityRenderMode(clientIndex, RENDER_TRANSCOLOR);
        SetEntityRenderColor(clientIndex, 255, 255, 255, 255);

        // Emit sound
        EmitSoundToAll("*/zbm3/zombi_wood_broken.mp3", clientIndex, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
	}
    
	// Destroy timer
	return Plugin_Stop;
}