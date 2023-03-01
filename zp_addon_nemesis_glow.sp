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
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Addon: Nemesis Glow",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Adds a dynamic lighting to a single nemesis",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Light index
int iLight[MAXPLAYERS+1] = { -1, ... }; 

// Mode index
int gMode;

// Cvars
ConVar hCvarNemesisRadius;
ConVar hCvarNemesisDistance;
ConVar hCvarNemesisColor;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarNemesisRadius   = CreateConVar("zp_nemesis_glow_radius", "300.0", "Glow lightning size (radius)", 0, true, 0.0);
	hCvarNemesisDistance = CreateConVar("zp_nemesis_glow_distance", "600.0", "Glow lightning size (distance)", 0, true, 0.0);
	hCvarNemesisColor    = CreateConVar("zp_nemesis_glow_color", "75 0 130 255", "Glow color in 'RGBA'");
	
	AutoExecConfig(true, "zp_addon_nemesis_glow", "sourcemod/zombieplague");
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
	gMode = ZP_GetGameModeNameID("nemesis mode");
}
/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	int entity = EntRefToEntIndex(iLight[client]);
	
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}
	
	iLight[client] = -1;
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	int entity = EntRefToEntIndex(iLight[client]);
	
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}
	
	iLight[client] = -1;
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	int entity = EntRefToEntIndex(iLight[client]);
	
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}
	
	iLight[client] = -1;
}

/**
 * @brief Called after a zombie round is started.
 *
 * @param mode              The mode index. 
 **/
public void ZP_OnGameModeStart(int mode)
{
	if (mode == gMode)
	{
		int client = ZP_GetRandomZombie();
	
		static float vPosition[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarNemesisColor.GetString(sEffect, sizeof(sEffect));
	
		int entity = UTIL_CreateLight(client, vPosition, _, _, _, _, _, _, _, sEffect, hCvarNemesisDistance.FloatValue, hCvarNemesisRadius.FloatValue);
		
		if (entity != -1)
		{
			iLight[client] = EntIndexToEntRef(entity);
		}
	}
}