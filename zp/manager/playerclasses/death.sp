/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          death.sp
 *  Type:          Module 
 *  Description:   Death event.
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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

/**
 * Variables to store DHook calls handlers.
 **/
Handle hDHookCommitSuicide;

/**
 * Variables to store dynamic DHook offsets.
 **/
int DHook_CommitSuicide;
 
/**
 * @brief Death module init function.
 **/
void DeathOnInit(/*void*/)
{
	// Hook player events
	HookEvent("player_death", DeathOnClientDeathPre, EventHookMode_Pre);
	HookEvent("player_death", DeathOnClientDeathPost, EventHookMode_Post);

	// Load offsets
	fnInitGameConfOffset(gServerData.SDKTools, DHook_CommitSuicide, /*CBasePlayer::*/"CommitSuicide");
	
	/// CBasePlayer::CommitSuicide(CBasePlayer *this, bool a2, bool a3)
	hDHookCommitSuicide = DHookCreate(DHook_CommitSuicide, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DeathDhookOnCommitSuicide);
	DHookAddParam(hDHookCommitSuicide, HookParamType_Bool);
	DHookAddParam(hDHookCommitSuicide, HookParamType_Bool);
}

/**
 * @brief Death module load function.
 **/
void DeathOnLoad(/*void*/)
{
	// Gets infect icon
	static char sIcon[NORMAL_LINE_LENGTH];
	gCvarList.ICON_INFECT.GetString(sIcon, sizeof(sIcon));
	if (hasLength(sIcon))
	{
		// Precache custom icon
		Format(sIcon, sizeof(sIcon), "materials/panorama/images/icons/equipment/%s.svg", sIcon);
		if (FileExists(sIcon)) AddFileToDownloadsTable(sIcon); 
	}
}

/**
 * @brief Hook death cvar changes.
 **/
void DeathOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.ICON_INFECT = FindConVar("zp_icon_infect");
	gCvarList.ICON_HEAD   = FindConVar("zp_icon_head");
}

/**
 * @brief Creates commands for death module.
 **/
void DeathOnCommandInit(/*void*/)
{
	// Hook listeners
	AddCommandListener(DeathOnCommandListened, "kill");
	AddCommandListener(DeathOnCommandListened, "explode");
	AddCommandListener(DeathOnCommandListened, "killvector");
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void DeathOnClientInit(int client)
{
	// Hook entity callbacks
	DHookEntity(hDHookCommitSuicide, true, client);
}

/**
 * Listener command callback (kill, explode, killvector)
 * @brief Blocks the suicide.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action DeathOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	// Validate client 
	if (IsPlayerExist(client, false))
	{
		// Block command
		return Plugin_Handled;
	}
	
	// Allow command
	return Plugin_Continue;
}

/**
 * Event callback (player_death)
 * @brief Client is going to die.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action DeathOnClientDeathPre(Event hEvent, char[] sName, bool dontBroadcast) 
{
	// Gets all required event info
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	// Validate human
	if (!gClientData[client].Zombie)
	{
		// Gets weapon index from the client
		int weapon = EntRefToEntIndex(gClientData[client].LastKnife);
		
		// Validate weapon
		if (weapon != -1) 
		{
			// Drop weapon
			WeaponsDrop(client, weapon, false);

			// Resets weapon index, which used to store knife
			gClientData[client].LastKnife = -1;
		}
	}
	
	// Validate custom index
	int iD = gClientData[client].LastID;
	if (iD != -1)
	{
		// Gets death icon
		static char sIcon[SMALL_LINE_LENGTH];
		WeaponsGetIcon(iD, sIcon, sizeof(sIcon));
		if (hasLength(sIcon)) /// Use default name
		{
			// Sets whether an event broadcasting will be disabled
			if (!dontBroadcast) 
			{
				// Disable broadcasting
				hEvent.BroadcastDisabled = true;
			}
			
			// Create a fake death event
			DeathCreateIcon(hEvent.GetInt("userid"), hEvent.GetInt("attacker"), sIcon, hEvent.GetBool("headshot"), hEvent.GetBool("penetrated"), hEvent.GetBool("revenge"), hEvent.GetBool("dominated"), hEvent.GetInt("assister"));
		}
		
		// Resets weapon id, which used to kill
		gClientData[client].LastID = -1;
	}
}

/**
 * Event callback (player_death)
 * @brief Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action DeathOnClientDeathPost(Event hEvent, char[] sName, bool dontBroadcast) 
{
	// Gets all required event info
	int client   = GetClientOfUserId(hEvent.GetInt("userid"));
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}
	
	// Forward event to sub-modules
	DeathOnClientDeath(client, IsPlayerExist(attacker, false) ? attacker : 0);
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.  
 * @param attacker          (Optional) The attacker index.
 **/
void DeathOnClientDeath(int client, int attacker = 0)
{
	// Delete player timers
	gClientData[client].ResetTimers();
	
	// Resets some tools
	ToolsSetDetecting(client, false);
	ToolsSetFlashLight(client, false);
	ToolsSetHud(client, true);
	ToolsSetFov(client);
	
	// Call forward
	gForwardData._OnClientDeath(client, attacker);
	
	// Forward event to modules
	RagdollOnClientDeath(client);
	HealthOnClientDeath(client);
	SoundsOnClientDeath(client);
	VEffectsOnClientDeath(client);
	WeaponsOnClientDeath(client);
	VOverlayOnClientDeath(client);
	AccountOnClientDeath(client);
	CostumesOnClientDeath(client);
	LevelSystemOnClientDeath(client);
	if (!DeathOnClientRespawn(client, attacker))
	{
		// Terminate the round
		ModesValidateRound();
	}
}

/**
 * @brief Validate respawning.
 *
 * @param client            The client index.
 * @param attacker          (Optional) The attacker index.
 * @param bTimer            If true, run the respawning timer, false to respawn instantly.
 **/
bool DeathOnClientRespawn(int client, int attacker = 0,  bool bTimer = true)
{
	// If mode doesn't started yet, then stop
	if (!gServerData.RoundStart)
	{
		return true; /// Avoid double check in 'ModesValidateRound'
	}

	// If respawn disabled on the current game mode, then stop
	if (!ModesIsRespawn(gServerData.RoundMode))
	{
		return false;
	}
	
	// If any last humans/zombies are left, then stop
	int iLast = ModesGetLast(gServerData.RoundMode);
	if (fnGetHumans() < iLast || fnGetZombies() < iLast)
	{
		return false;
	}
		
	// If player was killed by world, then stop
	if (client == attacker && !ModesIsSuicide(gServerData.RoundMode)) 
	{
		return false;
	}

	// If respawn amount exceed limit, the stop
	if (gClientData[client].RespawnTimes >= ModesGetAmount(gServerData.RoundMode))
	{
		return false;
	}

	// Verify that the attacker is exist
	if (IsPlayerExist(attacker, false))
	{
		// Gets class exp and money bonuses
		static int iExp[6]; static int iMoney[6];
		ClassGetExp(gClientData[attacker].Class, iExp, sizeof(iExp));
		ClassGetMoney(gClientData[attacker].Class, iMoney, sizeof(iMoney));

		// Increment money/exp/health
		LevelSystemOnSetExp(attacker, gClientData[attacker].Exp + iExp[BonusType_Kill]);
		AccountSetClientCash(attacker, gClientData[attacker].Money + iMoney[BonusType_Kill]);
		ToolsSetHealth(attacker, ToolsGetHealth(attacker) + ClassGetLifeSteal(gClientData[attacker].Class));
	}
		
	// Validate timer
	if (bTimer)
	{
		// Increment count
		gClientData[client].RespawnTimes++;
	
		// Sets timer for respawn player
		delete gClientData[client].RespawnTimer;
		gClientData[client].RespawnTimer = CreateTimer(ModesGetDelay(gServerData.RoundMode), DeathOnClientRespawning, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		// Respawn a player
		ToolsForceToRespawn(client);
	}
	
	// Return on success
	return true;
}

/**
 * @brief Timer callback, respawning a player.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action DeathOnClientRespawning(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Clear timer
	gClientData[client].RespawnTimer = null;    
	
	// Validate client
	if (client)
	{
		// Call forward
		Action hResult;
		gForwardData._OnClientRespawn(client, hResult);
	
		// Validate handle
		if (hResult == Plugin_Continue || hResult == Plugin_Changed)
		{
			// Call respawning
			DeathOnClientRespawn(client, _, false);
		}
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * DHook: Suicide the current player.
 * @note void CBasePlayer::CommitSuicide(bool, bool)
 *
 * @param client            The client index.
 **/
public MRESReturn DeathDhookOnCommitSuicide(int client)
{
	// Forward event to sub-modules
	DeathOnClientDeath(client);
}

/*
 * Stocks death API.
 */

/**
 * @brief Create a death icon.
 * 
 * @param userID            The user id who victim.
 * @param attackerID        The user id who killed.
 * @param sIcon             The icon name.
 * @param bHead             (Optional) States the additional headshot icon.
 * @param bPenetrated       (Optional) Number of objects shot penetrated before killing target.
 * @param bRevenge          (Optional) Killer get revenge on victim with this kill.
 * @param bDominated        (Optional) Did killer dominate victim with this kill.
 * @param assisterID        (Optional) The user id who assisted in the kill.
 **/
void DeathCreateIcon(int userID, int attackerID, char[] sIcon, bool bHead = false, bool bPenetrated = false, bool bRevenge = false, bool bDominated = false, int assisterID = 0)
{
	// Creates and send custom death icon
	Event hEvent = CreateEvent("player_death");
	if (hEvent != null)
	{
		// Sets event properties
		hEvent.SetInt("userid", userID);
		hEvent.SetInt("attacker", attackerID);
		hEvent.SetInt("assister", assisterID);
		hEvent.SetString("weapon", sIcon);
		hEvent.SetBool("headshot", bHead);
		hEvent.SetBool("penetrated", bPenetrated);
		hEvent.SetBool("revenge", bRevenge);
		hEvent.SetBool("dominated", bDominated);

		// i = client index
		for (int i = 1; i <= MaxClients; i++)
		{
			// Send fake event
			if (IsPlayerExist(i, false) && !IsFakeClient(i)) hEvent.FireToClient(i);
		}
		
		// Close it
		hEvent.Cancel();
	}
}