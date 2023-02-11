/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          death.sp
 *  Type:          Module 
 *  Description:   Death event.
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
void DeathOnInit()
{
	HookEvent("player_death", DeathOnClientDeathPre, EventHookMode_Pre);
	HookEvent("player_death", DeathOnClientDeathPost, EventHookMode_Post);

	fnInitGameConfOffset(gServerData.SDKTools, DHook_CommitSuicide, /*CCSPlayer::*/"CommitSuicide");
	
	hDHookCommitSuicide = DHookCreate(DHook_CommitSuicide, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DeathDhookOnCommitSuicide);
	DHookAddParam(hDHookCommitSuicide, HookParamType_Bool);
	DHookAddParam(hDHookCommitSuicide, HookParamType_Bool);
	
	if (hDHookCommitSuicide == null)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Death, "GameData Validation", "Failed to create DHook for \"CCSPlayer::CommitSuicide\". Update \"SourceMod\"");
	}
}

/**
 * @brief Death module load function.
 **/
void DeathOnLoad()
{
	static char sIcon[PLATFORM_LINE_LENGTH];
	gCvarList.ICON_INFECT.GetString(sIcon, sizeof(sIcon));
	if (hasLength(sIcon))
	{
		Format(sIcon, sizeof(sIcon), "materials/panorama/images/icons/equipment/%s.svg", sIcon);
		if (FileExists(sIcon)) AddFileToDownloadsTable(sIcon); 
	}
}

/**
 * @brief Hook death cvar changes.
 **/
void DeathOnCvarInit()
{
	gCvarList.ICON_INFECT = FindConVar("zp_icon_infect");
	gCvarList.ICON_HEAD   = FindConVar("zp_icon_head");
}

/**
 * @brief Creates commands for death module.
 **/
void DeathOnCommandInit()
{
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
	if (hDHookCommitSuicide)
	{
		DHookEntity(hDHookCommitSuicide, true, client);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Death, "DHook Validation", "Failed to attach DHook to \"CCSPlayer::CommitSuicide\". Update \"SourceMod\"");
	}
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
	if (IsPlayerExist(client, false))
	{
		return Plugin_Handled;
	}
	
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
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsPlayerExist(client, false))
	{
		return Plugin_Continue;
	}

	if (!gClientData[client].Zombie)
	{
		int weapon = EntRefToEntIndex(gClientData[client].LastKnife);
		
		if (weapon != -1) 
		{
			WeaponsDrop(client, weapon, false);

			gClientData[client].LastKnife = -1;
		}
	}
	
	int iD = gClientData[client].LastID;
	if (iD != -1)
	{
		static char sIcon[SMALL_LINE_LENGTH];
		WeaponsGetIcon(iD, sIcon, sizeof(sIcon));
		if (hasLength(sIcon)) /// Use default name
		{
			if (!dontBroadcast) 
			{
				hEvent.BroadcastDisabled = true;
			}
			
			DeathCreateIcon(hEvent.GetInt("userid"), hEvent.GetInt("attacker"), sIcon, hEvent.GetBool("headshot"), hEvent.GetBool("penetrated"), hEvent.GetBool("revenge"), hEvent.GetBool("dominated"), hEvent.GetInt("assister"));
		}
		
		gClientData[client].LastID = -1;
	}
	
	return Plugin_Continue;
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
	int client   = GetClientOfUserId(hEvent.GetInt("userid"));
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if (!IsPlayerExist(client, false))
	{
		return Plugin_Continue;
	}
	
	DeathOnClientDeath(client, IsPlayerExist(attacker, false) ? attacker : 0);
	
	return Plugin_Continue;
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.  
 * @param attacker          (Optional) The attacker index.
 **/
void DeathOnClientDeath(int client, int attacker = 0)
{
	gClientData[client].ResetTimers();
	
	ToolsSetDetecting(client, false);
	ToolsSetFlashLight(client, false);
	ToolsSetHud(client, true);
	ToolsSetFov(client);
	
	if (IsPlayerExist(attacker, false))
	{
		LevelSystemOnSetExp(attacker, gClientData[attacker].Exp + ClassGetExp(gClientData[attacker].Class, BonusType_Kill));
		AccountSetClientCash(attacker, gClientData[attacker].Money + ClassGetMoney(gClientData[attacker].Class, BonusType_Kill));
		ToolsSetHealth(attacker, ToolsGetHealth(attacker) + ClassGetLifeSteal(gClientData[attacker].Class));
	}
	
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
		ModesValidateRound();
	}

	gForwardData._OnClientDeath(client, attacker);
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
	if (!gServerData.RoundStart)
	{
		return true; /// Avoid double check in 'ModesValidateRound'
	}

	if (!ModesIsRespawn(gServerData.RoundMode))
	{
		return false;
	}
	
	int iLast = ModesGetLast(gServerData.RoundMode);
	if (fnGetHumans() < iLast || fnGetZombies() < iLast)
	{
		return false;
	}
		
	if (client == attacker && !ModesIsSuicide(gServerData.RoundMode)) 
	{
		return false;
	}

	if (gClientData[client].RespawnTimes >= ModesGetAmount(gServerData.RoundMode))
	{
		return false;
	}

	if (bTimer)
	{
		gClientData[client].RespawnTimes++;
	
		delete gClientData[client].RespawnTimer;
		gClientData[client].RespawnTimer = CreateTimer(ModesGetDelay(gServerData.RoundMode), DeathOnClientRespawning, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		ToolsForceToRespawn(client);
	}
	
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
	int client = GetClientOfUserId(userID);

	gClientData[client].RespawnTimer = null;    
	
	if (client)
	{
		Action hResult;
		gForwardData._OnClientRespawn(client, hResult);
	
		if (hResult == Plugin_Continue || hResult == Plugin_Changed)
		{
			DeathOnClientRespawn(client, _, false);
		}
	}
	
	return Plugin_Stop;
}

/**
 * DHook: Suicide the current player.
 * @note void CCSPlayer::CommitSuicide(bool, bool)
 *
 * @param client            The client index.
 **/
public MRESReturn DeathDhookOnCommitSuicide(int client)
{
	DeathOnClientDeath(client);
	
	return MRES_Handled;
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
	Event hEvent = CreateEvent("player_death");
	if (hEvent != null)
	{
		hEvent.SetInt("userid", userID);
		hEvent.SetInt("attacker", attackerID);
		hEvent.SetInt("assister", assisterID);
		hEvent.SetString("weapon", sIcon);
		hEvent.SetBool("headshot", bHead);
		hEvent.SetBool("penetrated", bPenetrated);
		hEvent.SetBool("revenge", bRevenge);
		hEvent.SetBool("dominated", bDominated);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsPlayerExist(i, false) && !IsFakeClient(i)) hEvent.FireToClient(i);
		}
		
		hEvent.Cancel();
	}
}
