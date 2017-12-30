/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          events.cpp
 *  Type:          Game 
 *  Description:   Event hooking and forwarding.
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

/**
 * Hook events used by plugin.
 **/
void EventInit(/*void*/)
{
	// Hook server events
	HookEvent("round_prestart", 		EventRoundPreStart,  		EventHookMode_Pre);
	HookEvent("round_start", 			EventRoundStart, 			EventHookMode_Post);
	HookEvent("round_end", 				EventRoundEnd, 	 			EventHookMode_Pre);
	HookEvent("cs_win_panel_round", 	EventBlockBroadCast, 	 	EventHookMode_Pre);

	// Hook player events
	HookEvent("player_spawn",      		EventPlayerSpawn, 			EventHookMode_Post);
	HookEvent("player_death", 			EventPlayerDeath, 	 		EventHookMode_Post);
	HookEvent("player_jump", 			EventPlayerJump,			EventHookMode_Post);
	HookEvent("weapon_fire",			EventPlayerFire,		 	EventHookMode_Pre);
	HookEvent("player_team", 			EventBlockBroadCast,		EventHookMode_Pre);
}

/*
 * Global player events.
 */

/**
 * Called once a client successfully connects.
 *
 * @param clientIndex		The client index.
 **/
public void OnClientConnected(int clientIndex)
{
	#define	ToolsOnClientConnect ToolsResetVars
	
	// Forward event to modules
	ToolsOnClientConnect(clientIndex);
}

/**
 * Called when a client is disconnected from the server.
 *
 * @param clientIndex		The client index.
 **/
public void OnClientDisconnect_Post(int clientIndex)
{
	#define ToolsOnClientDisconnect	ToolsResetVars
	
	// Forward event to modules
	ToolsOnClientDisconnect(clientIndex);
	RoundEndOnClientDisconnect();
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 * 
 * @param clientIndex		The client index. 
 **/
public void OnClientPostAdminCheck(int clientIndex)
{
	// Forward event to modules
	DamageClientInit(clientIndex);
	WeaponsClientInit(clientIndex);
	AntiStickClientInit(clientIndex);
}

/*
 * Global server events.
 */

/**
 * Event callback (round_prestart)
 * The round is start.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventRoundPreStart(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Forward event to modules
	RoundStartOnRoundPreStart();
}

/**
 * Event callback (round_start)
 * The round is started.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventRoundStart(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Forward event to modules
	RoundStartOnRoundStart();
}

/**
 * Event callback (round_end)
 * The round is end.
 * 
 * @param gEventHook       	The event handle.
 * @param gEventName       	The name of the event.
 * @param dontBroadcast   	If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventRoundEnd(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Forward event to modules
	RoundEndOnRoundEnd();
}

/**
 * Event callback (player_spawn)
 * Client is spawning.
 * 
 * @param gEventHook       	The event handle.
 * @param gEventName       	The name of the event.
 * @param dontBroadcast   	If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventPlayerSpawn(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));

	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// Forward event to modules
	CvarsOnClientSpawn(clientIndex);
	SpawnOnClientSpawn(clientIndex);
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param gEventHook       	The event handle.
 * @param gEventName      	The name of the event.
 * @param dontBroadcast   	If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventPlayerDeath(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get the weapon name
	static char sClassname[SMALL_LINE_LENGTH];
	GetEventString(gEventHook, "weapon", sClassname, sizeof(sClassname));

	// If client is being infected, then stop
	if(StrEqual(sClassname, "weapon_claws"))
	{
		return ACTION_HANDLED;
	}

	// Get all required event info
	int clientIndex   = GetClientOfUserId(GetEventInt(gEventHook, "userid"));
	int attackerIndex = GetClientOfUserId(GetEventInt(gEventHook, "attacker"));
	
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		// If the client isn't a player, a player really didn't die now. Some
		// other mods might sent this event with bad data.
		return ACTION_HANDLED;
	}

	// Forward event to modules
	RagdollOnClientDeath(clientIndex);
	DeathOnClientDeath(clientIndex, attackerIndex);
	
	// Allow death
	return ACTION_CONTINUE;
}

/**
 * Event callback (player_jump)
 * Client is jump.
 * 
 * @param gEventHook       	The event handle.
 * @param gEventName       	The name of the event.
 * @param dontBroadcast   	If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventPlayerJump(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));

	// Forward event to modules
	JumpBoostOnClientJump(clientIndex);
}

/**
 * Event callback (weapon_fire)
 * The player is shot.
 * 
 * @param gEventHook       	The event handle.
 * @param gEventName       	The name of the event.
 * @param dontBroadcast   	If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventPlayerFire(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));

	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}

	// Get active weapon index
	int weaponIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hActiveWeapon");
	
	// Forward event to modules
	WeaponsOnFire(clientIndex, weaponIndex);
}

/**
 * Event callback (player_team), (cs_win_panel_round)
 * The block of the event's broadcast.
 * 
 * @param gEventHook       	The event handle.
 * @param gEventName       	The name of the event.
 * @param dontBroadcast   	If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventBlockBroadCast(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Sets whether an event's broadcasting will be disabled
	if(!dontBroadcast) 
	{
		// Disable broadcasting
		SetEventBroadcast(gEventHook, true); 
	}
}

/**
 * Called when a clients movement buttons are being processed.
 *  
 * @param clientIndex		The client index.
 * @param bitFlags          Copyback buffer containing the current commands (as bitflags - see entity_prop_stocks.inc).
 * @param iImpulse          Copyback buffer containing the current impulse command.
 * @param flVelocity        Players desired velocity.
 * @param flAngles 			Players desired view angles.	
 * @param weaponIndex		Entity index of the new weapon ifplayer switches weapon, 0 otherwise.
 * @param iSubType			Weapon subtype when selected from a menu.
 * @param iCmdNum			Command number. Increments from the first command sent.
 * @param iTickCount		Tick count. A client's prediction based on the server's GetGameTickCount value.
 * @param iSeed				Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param iMouse			Mouse direction (x, y).
 **/ 
public Action OnPlayerRunCmd(int clientIndex, int &bitFlags, int &iImpulse, float flVelocity[3], float flAngles[3], int &weaponIndex, int &iSubType, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		return ACTION_CONTINUE;
	}
	
	// Forward event to modules
	return RunCmdOnPlayerRunCmd(clientIndex, bitFlags, IsPlayerAlive(clientIndex));
}