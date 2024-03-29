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
	name            = "[ZP] Game Mode: Plague",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of game modes",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Mode index
int gMode;

// Type index
int gNemesis; int gSurvivor;

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
	gMode = ZP_GetGameModeNameID("plague mode");
	
	gNemesis = ZP_GetClassTypeID("nemesis");
	if (gNemesis == -1) SetFailState("[ZP] Custom class type ID from name : \"nemesis\" wasn't find");
	gSurvivor = ZP_GetClassTypeID("survivor");
	if (gSurvivor == -1) SetFailState("[ZP] Custom class type ID from name : \"survivor\" wasn't find");
}

/**
 * @brief Called after a zombie round is started.
 *
 * @param mode              The mode index. 
 **/
public void ZP_OnGameModeStart(int mode)
{
	if (mode == gMode) /* OR if (ZP_GetCurrentGameMode() == ZP_GetGameModeNameID("plague mode"))*/
	{
		ZP_ChangeClient(ZP_GetRandomZombie(), _, gNemesis);
		ZP_ChangeClient(ZP_GetRandomHuman(), _, gSurvivor);
	}
}
