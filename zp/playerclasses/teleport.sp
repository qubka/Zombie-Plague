/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          teleport.sp
 *  Type:          Module 
 *  Description:   Teleport handle functions.
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

/*
 * Load other teleport modules
 */
#include "zp/playerclasses/teleportmenu.sp"

/**
 * @brief Creates commands for Teleport module.
 **/
void TeleportOnCommandInit()
{
	RegAdminCmd("zp_teleport_force", TeleportForceOnCommandCatched, ADMFLAG_GENERIC, "Force teleport on a client. Usage: zp_teleport_force <client>");
	RegConsoleCmd("ztele", TeleportOnCommandCatched, "Teleport back to spawn.");
	
	TeleportMenuOnCommandInit();
}

/**
 * @brief Hook account cvar changes.
 **/
void TeleportOnCvarInit()
{
	gCvarList.TELEPORT_ESCAPE          = FindConVar("zp_teleport_escape");
	gCvarList.TELEPORT_ZOMBIE          = FindConVar("zp_teleport_zombie");
	gCvarList.TELEPORT_HUMAN           = FindConVar("zp_teleport_human");
	gCvarList.TELEPORT_DELAY_ZOMBIE    = FindConVar("zp_teleport_delay_zombie");
	gCvarList.TELEPORT_DELAY_HUMAN     = FindConVar("zp_teleport_delay_human");
	gCvarList.TELEPORT_MAX_ZOMBIE      = FindConVar("zp_teleport_max_zombie");
	gCvarList.TELEPORT_MAX_HUMAN       = FindConVar("zp_teleport_max_human");
	gCvarList.TELEPORT_AUTOCANCEL      = FindConVar("zp_teleport_autocancel");
	gCvarList.TELEPORT_AUTOCANCEL_DIST = FindConVar("zp_teleport_autocancel_distance");
}

/**
 * Console command callback (zp_teleport_force)
 * @brief Force ZSpawn on a client.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/
public Action TeleportForceOnCommandCatched(int client, int iArguments)
{
	if (iArguments < 1)
	{
		TranslationReplyToCommand(client, "teleport command force syntax");
		return Plugin_Handled;
	}
	
	static char sArgument[SMALL_LINE_LENGTH]; static char sName[SMALL_LINE_LENGTH]; int targets[MAXPLAYERS]; bool tn_is_ml;
	
	GetCmdArg(1, sArgument, sizeof(sArgument));
	
	int iCount = ProcessTargetString(sArgument, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, sName, sizeof(sName), tn_is_ml);
	
	if (iCount <= 0)
	{
		TranslationReplyToCommand(client, "teleport invalid client");
		return Plugin_Handled;
	}
	
	for (int i = 0; i < iCount; i++)
	{
		bool bSuccess = TeleportClient(targets[i], true);
		
		if (iCount == 1)
		{
			if (bSuccess)
			{
				TranslationReplyToCommand(client, "teleport command force successful", sName);
			}
			else
			{
				TranslationReplyToCommand(client, "teleport command force unsuccessful", sName);
			}
		}
		
		LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Teleport, "Force Teleport", "\"%L\" teleported \"%L\" to spawn.", client, targets[i]);
	}
	
	return Plugin_Handled;
}

/**
 * Console command callback (teleport)
 * @brief Teleport back to spawn if you are stuck.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/
public Action TeleportOnCommandCatched(int client, int iArguments)
{
	TeleportClient(client);
	return Plugin_Handled;
}

/*
 * Stocks teleport API.
 */

/**
 * @brief Teleports a client back to spawn if conditions are met.
 * 
 * @param client            The client index.
 * @param bForce            (Optional) True to force teleporting of the client, false to follow rules.
 * @return                  True if teleport was successful, false otherwise. 
 **/
bool TeleportClient(int client, bool bForce = false)
{
	if (!IsClientValid(client))
	{
		return false;
	}
	
	bool bTeleportEscape = gCvarList.TELEPORT_ESCAPE.BoolValue;
	if (!bForce && bTeleportEscape && !ModesIsEscape(gServerData.RoundMode))
	{
		TranslationPrintToChat(client, "teleport restricted escape");
		return false;
	}
	
	bool bInfect = gClientData[client].Zombie;

	bool bTeleportZombie = gCvarList.TELEPORT_ZOMBIE.BoolValue;
	if (!bForce && bInfect && !bTeleportZombie)
	{
		TranslationPrintToChat(client, "teleport restricted zombie");
		return false;
	}

	bool bTeleportHuman = gCvarList.TELEPORT_HUMAN.BoolValue;
	if (!bForce && !bInfect && !bTeleportHuman)
	{
		TranslationPrintToChat(client, "teleport restricted human");
		return false;
	}
	
	int iTeleportMax = bInfect ? gCvarList.TELEPORT_MAX_ZOMBIE.IntValue : gCvarList.TELEPORT_MAX_HUMAN.IntValue;
	if (!bForce && gClientData[client].TeleTimes >= iTeleportMax)
	{
		TranslationPrintToChat(client, "teleport max", iTeleportMax);
		return false;
	}
	
	if (gClientData[client].TeleTimer != null)
	{
		if (!bForce)
		{
			TranslationPrintToChat(client, "teleport in progress");
		}
		return false;
	}
	
	if (bForce)
	{
		SpawnTeleportToRespawn(client);
		return true;
	}
	
	ToolsGetAbsOrigin(client, gClientData[client].TeleOrigin);
	
	gClientData[client].TeleCounter = bInfect ? gCvarList.TELEPORT_DELAY_ZOMBIE.IntValue : gCvarList.TELEPORT_DELAY_HUMAN.IntValue;
	if (gClientData[client].TeleCounter > 0)
	{
		TranslationPrintHintText(client, "teleport countdown", gClientData[client].TeleCounter);
		
		gClientData[client].TeleTimer = CreateTimer(1.0, TeleportOnClientCount, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	else
	{
		SpawnTeleportToRespawn(client);
		
		gClientData[client].TeleTimes++;
		
		TranslationPrintHintText(client, "teleport countdown end", gClientData[client].TeleTimes, iTeleportMax);
	}
	
	return true;
}

/**
 * @brief Timer callback, counts down teleport to the client.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action TeleportOnClientCount(Handle timer, int userID)
{
	int client = GetClientOfUserId(userID);

	if (client)
	{
		if (gCvarList.TELEPORT_AUTOCANCEL.BoolValue)
		{
			static float vPosition[3];
			ToolsGetAbsOrigin(client, vPosition); 
			
			float flDistance = GetVectorDistance(vPosition, gClientData[client].TeleOrigin);
			float flAutoCancelDist = gCvarList.TELEPORT_AUTOCANCEL_DIST.FloatValue;
  
			if (flDistance > flAutoCancelDist)
			{
				TranslationPrintHintText(client, "teleport autocancel centertext");
				TranslationPrintToChat(client, "teleport autocancel text", RoundToNearest(flAutoCancelDist));
				
				gClientData[client].TeleTimer = null;
				
				return Plugin_Stop;
			}
		}

		gClientData[client].TeleCounter--;
		
		TranslationPrintHintText(client, "teleport countdown", gClientData[client].TeleCounter);
		
		if (gClientData[client].TeleCounter <= 0)
		{
			SpawnTeleportToRespawn(client);
			
			gClientData[client].TeleTimes++;
			
			TranslationPrintHintText(client, "teleport countdown end", gClientData[client].TeleTimes, gClientData[client].Zombie ? gCvarList.TELEPORT_MAX_ZOMBIE.IntValue : gCvarList.TELEPORT_MAX_HUMAN.IntValue);
			
			gClientData[client].TeleTimer = null;
			
			return Plugin_Stop;
		}
		
		return Plugin_Continue;
	}
	
	gClientData[client].TeleTimer = null;
	
	return Plugin_Stop;
}