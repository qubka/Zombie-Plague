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
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, TEAM_HUMAN, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);

	// Hook player events
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	
	// Hook entity events
	HookEvent("smokegrenade_detonate", EventEntitySmoke, EventHookMode_Post);
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
 * The flashbang nade is exployed.
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
	GrenadeOnSmokeDetonate(ownerIndex, entityIndex, flOrigin);
}

/**
 * The smoke nade is exployed.
 * 
 * @param ownerIndex		The owner index.
 * @param entityIndex		The entity index.  
 * @param flOrigin			The explosion origin.
 **/
void GrenadeOnSmokeDetonate(int ownerIndex, int entityIndex, float flOrigin[3])
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
				
				// Initialize distance variable
				float flDistance = GetVectorDistance(flOrigin, flVictimOrigin);
				
				// If distance to the entity is less than the radius of explosion
				if(flDistance <= GetConVarFloat(FindConVar("zp_grenade_freeze_radius")))
				{				
					// Freeze entity
					GrenadeOnEntityFrozen(i, flVictimOrigin);
				}
			}
		}

		// Create sparks splash effect
		TE_SetupSparks(flOrigin, NULL_VECTOR, 5000, 1000);
		TE_SendToAll();
	}
	
	// Remove grenade
	RemoveEdict(entityIndex);
}

/**
 * Player is about to freeze.
 *
 * @param clientIndex		The client index.
 * @param flClientOrigin	The client position.
 **/
void GrenadeOnEntityFrozen(int clientIndex, float flClientOrigin[3])
{
	// Verify that the client is a zombie
	if(!ZP_IsPlayerZombie(clientIndex) || (ZP_IsPlayerNemesis(clientIndex) && !GetConVarBool(FindConVar("zp_grenade_freeze_nemesis"))))
	{
		return;
	}

	// Freeze client
	SetEntityMoveType(clientIndex, MOVETYPE_NONE);

	// Set blue render color
	SetEntityRenderMode(clientIndex, RENDER_TRANSCOLOR);
	SetEntityRenderColor(clientIndex, 120, 120, 255, 255);
	
	// Create ice
	GrenadeOnCreateIce(clientIndex, flClientOrigin);

	// Emit sound
	EmitSoundToAll("*/zbm3/impalehit.mp3", clientIndex, SNDCHAN_STATIC, SNDLEVEL_NORMAL);

	// Create timer for removing freezing
	delete Task_ZombieFreezed[clientIndex];
	Task_ZombieFreezed[clientIndex] = CreateTimer(GetConVarFloat(FindConVar("zp_grenade_freeze_time")), GrenadeRemoveFreezing, clientIndex, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer for remove freeze.
 *
 * @param hTimer			The timer handle.
 * @param clientIndex		The client index.
 **/
public Action GrenadeRemoveFreezing(Handle hTimer, any clientIndex)
{
	// Clear timer 
	Task_ZombieFreezed[clientIndex] = INVALID_HANDLE;

	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Stop;
	}

	// Unfreeze client
	SetEntityMoveType(clientIndex, MOVETYPE_WALK);

	// Set standart render color
	SetEntityRenderMode(clientIndex, RENDER_TRANSCOLOR);
	SetEntityRenderColor(clientIndex, 255, 255, 255, 255);

	// Emit sound
	EmitSoundToAll("*/zbm3/zombi_wood_broken.mp3", clientIndex, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * Create the attached ice model.
 *
 * @param clientIndex		The client index.
 * @param flClientOrigin	The client position.
 **/
void GrenadeOnCreateIce(int clientIndex, float flClientOrigin[3])
{
	// Validate client
	if(IsPlayerExist(clientIndex))
	{
		// Create a prop_dynamic entity
		int iIce = CreateEntityByName("prop_dynamic");
		
		// Validate entity
		if(IsValidEdict(iIce))
		{
			// Set the model
			DispatchKeyValue(iIce, "model", "models/spree/spree.mdl");
			
			// Spawn the entity
			DispatchSpawn(iIce);
			TeleportEntity(iIce, flClientOrigin, NULL_VECTOR, NULL_VECTOR);

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