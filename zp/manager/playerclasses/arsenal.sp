/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          arsenal.sp
 *  Type:          Module
 *  Description:   Handles client arsenal.
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
 * @section Number of valid arsenal menus.
 **/
enum /*ArsenalType*/
{                          
	ArsenalType_Primary,   /** Primary menu */  
	ArsenalType_Secondary, /** Secondary menu */  
	ArsenalType_Melee      /** Melee menu */
};
/**
 * @endsection
 **/ 
 
/*
 * Load other accont modules
 */
#include "zp/manager/playerclasses/arsenalmenu.sp"

/**
 * @brief Initialize arsenal weapons during the loading.
 **/
void ArsenalOnLoad(/*void*/)
{
	// Validate arsenal
	if (!gCvarList.ARSENAL.BoolValue)
	{
		return;
	}
	
	// If array hasn't been created, then create
	if (gServerData.Arsenal == null)
	{
		// Initialize a type list array
		gServerData.Arsenal = new ArrayList();
	}
	else
	{
		// Clear out the array of all data
		ConfigClearKvArray(gServerData.Arsenal);
	}
	
	// Load weapons from cvars
	ArsenalSet(gCvarList.ARSENAL_PRIMARY);
	ArsenalSet(gCvarList.ARSENAL_SECONDARY);
	ArsenalSet(gCvarList.ARSENAL_MELEE);
	ArsenalSet(gCvarList.ARSENAL_ADDITIONAL);
	
	// i = client index
	for (int i = 1; i <= MaxClients; i++) 
	{
		// Validate client
		if (IsPlayerExist(i, false)) 
		{
			// x = array index
			for (int x = ArsenalType_Primary; x <= ArsenalType_Melee; x++)
			{
				// Resets stored arsenal
				gClientData[i].Arsenal[x] = -1;
			}
		}
	}
}

/**
 * @brief Hook arsenal cvar changes.
 **/
void ArsenalOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.ARSENAL                = FindConVar("zp_arsenal");
	gCvarList.ARSENAL_RANDOM_WEAPONS = FindConVar("zp_arsenal_random_weapons");
	gCvarList.ARSENAL_PRIMARY        = FindConVar("zp_arsenal_primary");
	gCvarList.ARSENAL_SECONDARY      = FindConVar("zp_arsenal_secondary");
	gCvarList.ARSENAL_MELEE          = FindConVar("zp_arsenal_melee");
	gCvarList.ARSENAL_ADDITIONAL     = FindConVar("zp_arsenal_additional");
	
	// Hook cvars
	HookConVarChange(gCvarList.ARSENAL,            ArsenalOnCvarHook);
	HookConVarChange(gCvarList.ARSENAL_PRIMARY,    ArsenalOnCvarHook);
	HookConVarChange(gCvarList.ARSENAL_SECONDARY,  ArsenalOnCvarHook);
	HookConVarChange(gCvarList.ARSENAL_MELEE,      ArsenalOnCvarHook);
	HookConVarChange(gCvarList.ARSENAL_ADDITIONAL, ArsenalOnCvarHook);
}

/**
 * @brief Creates commands for arsenal module.
 **/
void ArsenalOnCommandInit(/*void*/)
{
	// Forward event to sub-modules
	ArsenalMenuOnCommandInit();
}

/*
 * Arsenal main functions.
 */
 
/**
 * Cvar hook callback (zp_arsenal, zp_arsenal_*)
 * @brief Arsenal module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ArsenalOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	// Forward event to modules
	ArsenalOnLoad();
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 * @return                  True when menu was opened, false otherwise.
 **/
bool ArsenalOnClientUpdate(int client)
{
	// Resets the current arsenal menu
	gClientData[client].CurrentMenu = ArsenalType_Primary;
	gClientData[client].BlockMenu = false;
	
	// Validate arsenal
	if (gCvarList.ARSENAL.BoolValue)
	{
		// Give weapons and get opening state
		return ArsenallGive(client);
	}
	
	// Return on success
	return false;
}

/*
 * Stocks arsenal API.
 */

/**
 * @brief Sets the weapons ids to the string map using the appropriate key.
 * 
 * @param hConVar           The cvar handle.
 **/
void ArsenalSet(ConVar hConVar)
{
	// Initialize variables
	static char sBuffer[PLATFORM_LINE_LENGTH];
	static char sWeapon[SMALL_LINE_LENGTH][SMALL_LINE_LENGTH];
	
	// Create array of indexes
	ArrayList hList = new ArrayList(); int iType = gServerData.Types.FindString("human");
	
	// Gets the weapon string divived by commas
	hConVar.GetString(sBuffer, sizeof(sBuffer));
	int nWeapon = ExplodeString(sBuffer, ",", sWeapon, sizeof(sWeapon), sizeof(sWeapon[]));
	for (int i = 0; i < nWeapon; i++)
	{
		// Trim string
		TrimString(sWeapon[i]);

		// Validate index
		int iD = WeaponsNameToIndex(sWeapon[i]);
		if (iD != -1)
		{  
			// Gets weapon class
			int iTypes = WeaponsGetTypes(iD);
		
			// Validate access
			if (!iTypes || view_as<bool>((1 << iType) & iTypes))
			{
				// Push data into array
				hList.Push(iD);
			}
		}
	}
	
	// Push list into array 
	gServerData.Arsenal.Push(hList);
}

/**
 * @brief Open the arsenal menu at which the section is at. (or next available)
 * 
 * @param client            The client index.
 * @param mSection          The section index.
 * @return                  True or false.
 **/
bool ArsenalOpen(int client, int mSection)
{
	// i = array index
	for (int i = mSection; i <= ArsenalType_Melee; i++) 
	{
		// Validate arsenal at given index
		ArrayList hList = gServerData.Arsenal.Get(i);
		if (hList.Length > 0)
		{
			// Opens menu
			ArsenalMenu(client, i);
			return true;
		}
	}
	
	// Return on failure
	return false;
}

/**
 * @brief Gives an arsenal weapons.
 *
 * @param client            The client index.
 * @return 					True if the menu was open, false otherwise.
 **/
bool ArsenallGive(int client)
{
	// Validate any except human, then stop
	if (gClientData[client].Zombie || gClientData[client].Custom)
	{
		return false;
	}
	
	// If mode already started, then stop
	if ((gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode)) || gServerData.RoundEnd)
	{ 
		return false;
	}
	
	// Random weapons setting enabled / Bots pick their weapons randomly
	if (gCvarList.ARSENAL_RANDOM_WEAPONS || IsFakeClient(client))
	{
		// Give additional weapons
		int weapon = ArsenalGiveAdds(client);

		// i = array index
		for (int i = ArsenalType_Melee; i != -1; i--)
		{
			// Validate that slot is knife
			if (i != ArsenalType_Melee)
			{
				// If knife is non default skip
				int weapon2 = GetPlayerWeaponSlot(client, i);
				if (weapon2 != -1 && ToolsGetCustomID(weapon2) != gServerData.Melee)
				{
					continue;
				}
			}
			
			// Gets current arsenal list
			ArrayList hList = gServerData.Arsenal.Get(i);
			
			// Validate size
			int iSize = hList.Length;
			if (iSize > 0)
			{
				// Give random weapons
				weapon = WeaponsGive(client, hList.Get(GetRandomInt(0, iSize - 1)), false);
			}
		}
		
		// Validate weapon
		if (weapon != -1)
		{
			// Switch weapon
			WeaponsSwitch(client, weapon);
		}
	}
	else 
	{
		// Open menu if autoselect turn off
		if (!gClientData[client].AutoSelect) 
		{
			return ArsenalOpen(client, ArsenalType_Primary);
		}
		else 
		{
			// i = array index
			for (int i = ArsenalType_Primary; i <= ArsenalType_Melee; i++)
			{
				// Open menu if autoselect turn on but some default not set
				ArrayList hList = gServerData.Arsenal.Get(i);
				if (gClientData[client].Arsenal[i] == -1 && hList.Length > 0)
				{
					return ArsenalOpen(client, ArsenalType_Primary);
				}
			}
			
			// Give additional weapons
			int weapon = ArsenalGiveAdds(client);

			// i = array index
			for (int i = ArsenalType_Melee; i != -1; i--)
			{
				// Validate that slot is knife
				if (i != ArsenalType_Melee)
				{
					// If knife is non default skip
					int weapon2 = GetPlayerWeaponSlot(client, i);
					if (weapon2 != -1 && ToolsGetCustomID(weapon2) != gServerData.Melee)
					{
						continue;
					}
				}
				
				// Give main weapons
				weapon = WeaponsGive(client, gClientData[client].Arsenal[i], false);
			}
			
			// Validate weapon
			if (weapon != -1)
			{
				// Switch weapon
				WeaponsSwitch(client, weapon);
			}
		}
	}
	
	// Return on success
	return false;
}

/**
 * @brief Gives an additional weapons.
 *
 * @param client            The client index.
 * @return                  The last weapon index.
 **/
int ArsenalGiveAdds(int client)
{
	// Gets additional weapons
	ArrayList hList = gServerData.Arsenal.Get(gServerData.Arsenal.Length - 1); int weapon = -1;
	
	// i = array index
	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Give additional weapons
		weapon = WeaponsGive(client, hList.Get(i), false);
	}

	// Block arsenal from use
	gClientData[client].CurrentMenu = ArsenalType_Primary;
	gClientData[client].BlockMenu = true;
	
	// Return last weapon index
	return weapon;
}