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

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Addon: Movement Unlocker",
	author          = "qubka (Nikita Ushakov), Peace-Maker",     
	description     = "Removes max speed limitation from players on the ground. Feels like CS:S",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

Address pMaxSpeed[2];

/* CGameMovement::WalkMove VectorScale(wishvel, mv->m_flMaxSpeed/wishspeed, wishvel) */
int iWalkRestoreBytes;
int iWalkRestore[100];
int iWalkOffset;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved.
 **/
public void OnPluginStart()
{
	// Loads a game config file
	GameData hConfig = LoadGameConfigFile("plugin.movement_unlock");

	// Validate config
	if (!hConfig) 
	{
		SetFailState("Failed to load movement unlocker gamedata.");
		return;
	}

	// Load address
	if ((pMaxSpeed[0] = hConfig.GetAddress("m_flMaxSpeed")) == Address_Null) SetFailState("Failed to load SDK address \"m_flMaxSpeed\". Update address in \"plugin.movement_unlock\"");   

	// Load other offsets
	if ((iWalkOffset = hConfig.GetOffset("WalkOffset")) == -1) SetFailState("Failed to get offset: \"WalkOffset\". Update offset in \"plugin.movement_unlock\""); 
	if ((iWalkRestoreBytes = hConfig.GetOffset("WalkBytes")) == -1) SetFailState("Failed to get offset: \"WalkBytes\". Update offset in \"plugin.movement_unlock\""); 
	
	// Close file
	delete hConfig;
	
	// Move right in front of the instructions we want to NOP
	pMaxSpeed[0] += view_as<Address>(iWalkOffset);
	pMaxSpeed[1] = pMaxSpeed[0]; /// Store current patch addr

	/**
	 * @brief Removes max speed limitation from players on the ground. Feels like CS:S.
	 *
	 * @author This algorithm made by 'Peace-Maker'.
	 * @link https://forums.alliedmods.net/showthread.php?t=255298&page=15
	 **/
	for (int i = 0; i < iWalkRestoreBytes; i++)
	{
		// Save the current instructions, so we can restore them on unload
		iWalkRestore[i] = LoadFromAddress(pMaxSpeed[0], NumberType_Int8);
		StoreToAddress(pMaxSpeed[0], 0x90, NumberType_Int8);
		pMaxSpeed[0]++;
	}
}

/**
 * @brief Called when the plugin is about to be unloaded. 
 */
public void OnPluginEnd()
{
	/// Restore the original walk instructions, if we patched them

	// i = currect instruction
	for (int i = 0; i < iWalkRestoreBytes; i++)
	{
		StoreToAddress(pMaxSpeed[1] + view_as<Address>(i), iWalkRestore[i], NumberType_Int8);
	}
}
