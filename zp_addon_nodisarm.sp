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
	name            = "[ZP] Addon: NoDisarm",
	author          = "qubka (Nikita Ushakov), Phoenix (˙·٠●Феникс●٠·˙)",     
	description     = "Addon of no fists disarm",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

Address pNoDisarmMod_Start, pNoDisarmMod_End;
int iNoDisarmMod_Restore;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved.
 **/
public void OnPluginStart()
{
	// Loads a game config file
	GameData hConfig = LoadGameConfigFile("plugin.nodisarm");

	// Validate config
	if (!hConfig) 
	{
		SetFailState("Failed to load nodisarm gamedata.");
		return;
	}

	// Load addresses
	if ((pNoDisarmMod_Start = hConfig.GetAddress("FX_Disarm_Start")) == Address_Null) SetFailState("Failed to load SDK address \"FX_Disarm_Start\". Update address in \"plugin.nodisarm\"");   
	if ((pNoDisarmMod_End = hConfig.GetAddress("FX_Disarm_End")) == Address_Null) SetFailState("Failed to load SDK address \"FX_Disarm_End\". Update address in \"plugin.nodisarm\"");   
	
	// Close file
	delete hConfig;
	
	// Validate extracted data
	if (LoadFromAddress(pNoDisarmMod_Start, NumberType_Int8) != 0x80 || LoadFromAddress(pNoDisarmMod_End, NumberType_Int8) != 0x8B)
	{
		SetFailState("Found not what they expected.");
		return;
	}
	
	/// Store current patch offset
	iNoDisarmMod_Restore = LoadFromAddress(pNoDisarmMod_Start + view_as<Address>(1), NumberType_Int32);
	
	// Gets the jmp instruction
	int jmp = view_as<int>(pNoDisarmMod_End - pNoDisarmMod_Start) - 5;
	
	// Write new jmp instruction
	StoreToAddress(pNoDisarmMod_Start, 0xE9, NumberType_Int8);
	StoreToAddress(pNoDisarmMod_Start + view_as<Address>(1), jmp, NumberType_Int32);
}

/**
 * @brief Called when the plugin is about to be unloaded. 
 */
public void OnPluginEnd()
{
	/// Restore the original disarm instructions, if we patched them
	StoreToAddress(pNoDisarmMod_Start, 0x80, NumberType_Int8);
	StoreToAddress(pNoDisarmMod_Start + view_as<Address>(1), iNoDisarmMod_Restore, NumberType_Int32);
}
