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
#include "zp/playerclasses/arsenalmenu.sp"

/**
 * @brief Initialize arsenal weapons during the loading.
 **/
void ArsenalOnLoad()
{
	if (!gCvarList.ARSENAL.BoolValue)
	{
		return;
	}
	
	if (gServerData.Arsenal == null)
	{
		gServerData.Arsenal = new ArrayList();
	}
	else
	{
		ClearArrayList(gServerData.Arsenal);
	}
	
	ArsenalSet(gCvarList.ARSENAL_PRIMARY);
	ArsenalSet(gCvarList.ARSENAL_SECONDARY);
	ArsenalSet(gCvarList.ARSENAL_MELEE);
	ArsenalSet(gCvarList.ARSENAL_ADDITIONAL);
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientValid(i, false)) 
		{
			for (int x = ArsenalType_Primary; x <= ArsenalType_Melee; x++)
			{
				gClientData[i].Arsenal[x] = -1;
			}
		}
	}
}

/**
 * @brief Hook arsenal cvar changes.
 **/
void ArsenalOnCvarInit()
{
	gCvarList.ARSENAL                = FindConVar("zp_arsenal");
	gCvarList.ARSENAL_RANDOM_WEAPONS = FindConVar("zp_arsenal_random_weapons");
	gCvarList.ARSENAL_PRIMARY        = FindConVar("zp_arsenal_primary");
	gCvarList.ARSENAL_SECONDARY      = FindConVar("zp_arsenal_secondary");
	gCvarList.ARSENAL_MELEE          = FindConVar("zp_arsenal_melee");
	gCvarList.ARSENAL_ADDITIONAL     = FindConVar("zp_arsenal_additional");
	
	HookConVarChange(gCvarList.ARSENAL,            ArsenalOnCvarHook);
	HookConVarChange(gCvarList.ARSENAL_PRIMARY,    ArsenalOnCvarHook);
	HookConVarChange(gCvarList.ARSENAL_SECONDARY,  ArsenalOnCvarHook);
	HookConVarChange(gCvarList.ARSENAL_MELEE,      ArsenalOnCvarHook);
	HookConVarChange(gCvarList.ARSENAL_ADDITIONAL, ArsenalOnCvarHook);
}

/**
 * @brief Creates commands for arsenal module.
 **/
void ArsenalOnCommandInit()
{
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
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
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
	gClientData[client].CurrentMenu = ArsenalType_Primary;
	gClientData[client].BlockMenu = false;
	
	if (gCvarList.ARSENAL.BoolValue)
	{
		return ArsenallDistribute(client);
	}
	
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
	static char sBuffer[PLATFORM_LINE_LENGTH];
	static char sWeapon[SMALL_LINE_LENGTH][SMALL_LINE_LENGTH];
	
	ArrayList hList = new ArrayList();
	
	hConVar.GetString(sBuffer, sizeof(sBuffer));
	int nWeapon = ExplodeString(sBuffer, ",", sWeapon, sizeof(sWeapon), sizeof(sWeapon[]));
	for (int i = 0; i < nWeapon; i++)
	{
		TrimString(sWeapon[i]);

		int iD = WeaponsNameToIndex(sWeapon[i]);
		if (iD != -1)
		{  
			if (ClassHasTypeBits(WeaponsGetTypes(iD), gServerData.Human))
			{
				hList.Push(iD);
			}
			else
			{
				hConVar.GetName(sBuffer, sizeof(sBuffer));
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Arsenal, "ConVar Validation", "ConVar: \"%s\" constains weapon: \"%s\" that does not available to use for default human class type!", sBuffer, sWeapon[i]);
			}
		}
		else
		{
			hConVar.GetName(sBuffer, sizeof(sBuffer));
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Arsenal, "ConVar Validation", "ConVar: \"%s\" couldn't cache weapon data for: \"%s\" (check weapons config)", sBuffer, sWeapon[i]);
		}
	}
	
	gServerData.Arsenal.Push(hList);
}

/**
 * @brief Open the arsenal menu at which the section is at. (or next available)
 * 
 * @param client            The client index.
 * @param iSection          The section index.
 * @return                  True or false.
 **/
bool ArsenalOpen(int client, int iSection)
{
	for (int i = iSection; i <= ArsenalType_Melee; i++) 
	{
		ArrayList hList = gServerData.Arsenal.Get(i);
		if (hList.Length > 0)
		{
			ArsenalMenu(client, i);
			return true;
		}
	}
	
	return false;
}

/**
 * @brief Distibutes an arsenal weapons.
 *
 * @param client            The client index.
 * @return 					True if the menu was open, false otherwise.
 **/
bool ArsenallDistribute(int client)
{
	if (gClientData[client].Zombie || gClientData[client].Custom)
	{
		return false;
	}

	if (gCvarList.ARSENAL_RANDOM_WEAPONS.BoolValue || IsFakeClient(client))
	{
		int weapon = ArsenalGiveAdds(client);

		for (int i = ArsenalType_Melee; i != -1; i--)
		{
			ArrayList hList = gServerData.Arsenal.Get(i);
			
			int iSize = hList.Length;
			if (iSize > 0)
			{
				weapon = ArsenalGiveMain(client, i, hList.Get(GetRandomInt(0, iSize - 1)));
			}
		}
		
		if (weapon != -1)
		{
			WeaponsSwitch(client, weapon);
		}
	}
	else 
	{
		if (!gClientData[client].AutoSelect) 
		{
			return ArsenalOpen(client, ArsenalType_Primary);
		}
		else 
		{
			for (int i = ArsenalType_Primary; i <= ArsenalType_Melee; i++)
			{
				ArrayList hList = gServerData.Arsenal.Get(i);
				if (gClientData[client].Arsenal[i] == -1 && hList.Length > 0)
				{
					return ArsenalOpen(client, ArsenalType_Primary);
				}
			}
			
			int weapon = ArsenalGiveAdds(client);

			for (int i = ArsenalType_Melee; i != -1; i--)
			{
				weapon = ArsenalGiveMain(client, i, gClientData[client].Arsenal[i]);
			}
			
			if (weapon != -1)
			{
				WeaponsSwitch(client, weapon);
			}
		}
	}
	
	return false;
}


/**
 * @brief Creates a main weapon.
 *
 * @param client            The client index.
 * @param iSection          The section index.
 * @param iD                The weapon id.
 * @return                  The last weapon index.
 **/
int ArsenalGiveMain(int client, int iSection, int iD)
{
	int weapon = -1;

	int weapon2 = GetPlayerWeaponSlot(client, iSection);
	if (weapon2 == -1 || ToolsGetCustomID(weapon2) == gServerData.Melee)
	{
		weapon = WeaponsGive(client, iD, false);
	}
	else
	{
		static float vPosition[3]; static float vAngle[3];
	
		ToolsGetAbsOrigin(client, vPosition); 
		ToolsGetAbsAngles(client, vAngle);
		
		WeaponsCreate(iD, vPosition, vAngle);
	}
	
	return weapon;
}

/**
 * @brief Creates an additional weapons.
 *
 * @param client            The client index.
 * @return                  The last weapon index.
 **/
int ArsenalGiveAdds(int client)
{
	static char sClassname[SMALL_LINE_LENGTH];
	
	ArrayList hList = gServerData.Arsenal.Get(gServerData.Arsenal.Length - 1); int weapon = -1;
	
	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		int iD = hList.Get(i);
		
		WeaponsGetEntity(iD, sClassname, sizeof(sClassname));
		
		int weapon2 = WeaponsFindByName(client, sClassname);
		if (weapon2 == -1)
		{
			weapon = WeaponsGive(client, iD, false);
		}
		else
		{
			static float vPosition[3]; static float vAngle[3];
		
			ToolsGetAbsOrigin(client, vPosition); 
			ToolsGetAbsAngles(client, vAngle);
			
			WeaponsCreate(iD, vPosition, vAngle);
		}
	}

	gClientData[client].CurrentMenu = ArsenalType_Primary;
	gClientData[client].BlockMenu = true;
	
	return weapon;
}