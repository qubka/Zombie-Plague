/**
 * ============================================================================
 *
 *  Zombie Plague
 *
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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Zombie Class: Tesla",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Timer index
Handle hZombieHallucination[MAXPLAYERS+1] = { null, ... }; 

// Sound index
int gSound;

// Zombie index
int gZombie;

// Cvars
ConVar hCvarSkillRadius;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarSkillRadius = CreateConVar("zp_zclass_tesla_radius", "300.0", "Tesla radius", 0, true, 0.0);

	AutoExecConfig(true, "zp_zclass_tesla", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		if (ZP_IsMapLoaded())
		{
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gZombie = ZP_GetClassNameID("tesla");
	
	gSound = ZP_GetSoundKeyID("TESLA_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"TESLA_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	PrecacheModel("materials/sprites/physbeam.vmt", true);
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		hZombieHallucination[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
	}
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	delete hZombieHallucination[client];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	delete hZombieHallucination[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	delete hZombieHallucination[client];
}

/**
	* @brief Called when a client use a skill.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
	if (ZP_GetClientClass(client) == gZombie)
	{
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_SKILL);
		
		static float vPosition[3]; 
		GetClientEyePosition(client, vPosition); vPosition[2] += 40.0;

		delete hZombieHallucination[client];
		hZombieHallucination[client] = CreateTimer(0.1, ClientOnHallucination, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

		static char sRadius[SMALL_LINE_LENGTH];
		hCvarSkillRadius.GetString(sRadius, sizeof(sRadius));

		UTIL_CreateTesla(client, vPosition, _, _, sRadius, _, "15", "25", _, _, "7.0", "9.0", _, _, _, _, ZP_GetClassSkillDuration(gZombie));
	}
	
	return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param client            The client index.
 **/
public void ZP_OnClientSkillOver(int client)
{
	if (ZP_GetClientClass(client) == gZombie) 
	{
		delete hZombieHallucination[client];
	}
}

/**
 * @brief Timer for the hallucination process.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientOnHallucination(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);
	
	if (client)
	{
		static float vPosition[3]; static int vColor[4];

		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);

		float flRadius = hCvarSkillRadius.FloatValue;

		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			if (ZP_IsPlayerZombie(i))
			{
				continue;
			}

			vColor[0] = GetRandomInt(50, 200);
			vColor[1] = GetRandomInt(50, 200);
			vColor[2] = GetRandomInt(50, 200);
			vColor[3] = GetRandomInt(200, 230);

			UTIL_CreateFadeScreen(i, 0.1, 0.2, FFADE_IN, vColor);
			
			UTIL_CreateShakeScreen(i, 2.0, 1.0, 0.1);
		}

		return Plugin_Continue;
	}

	hZombieHallucination[client] = null;

	return Plugin_Stop;
}
