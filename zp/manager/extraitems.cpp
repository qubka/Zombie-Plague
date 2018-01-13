/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          extraitems.cpp
 *  Type:          Manager 
 *  Description:   Extra Items generator.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * Number of max valid extra items.
 **/
#define ExtraItemMax 64

/**
 * Array handle to store extra item native data.
 **/
ArrayList arrayExtraItems;
 
/**
 * Item native data indexes.
 **/
enum
{
	EXTRAITEMS_DATA_NAME,
	EXTRAITEMS_DATA_COST,
	EXTRAITEMS_DATA_TEAM,
	EXTRAITEMS_DATA_LEVEL,
	EXTRAITEMS_DATA_ONLINE,
	EXTRAITEMS_DATA_LIMIT
}

/**
 * Array to store the item limit to player.
 **/
int gExtraBuyLimit[MAXPLAYERS+1][ExtraItemMax];

/**
 * Initialization of extra items. 
 **/
void ExtraItemsLoad(/*void*/)
{
	// No extra items?
	if(arrayExtraItems == NULL)
	{
		LogEvent(false, LogType_Normal, LOG_CORE_EVENTS, LogModule_Extraitems, "Extra Items Validation", "No extra items loaded");
	}
}

/*
 * Extra items natives API.
 */

/**
 * Give the extra item to the client.
 *
 * native bool ZP_GiveClientExtraItem(clientIndex, iD);
 **/
public int API_GiveClientExtraItem(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));
	
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Player doens't exist (%d)", cBasePlayer->Index);
		return -1;
	}
	
	// Get item index from native cell
	int iD = GetNativeCell(2);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Call forward
	Action resultHandle = API_OnClientBuyExtraItem(cBasePlayer->Index, iD);
	
	// Return on success
	return (resultHandle == ACTION_HANDLED || resultHandle == ACTION_STOP) ? false : true;
}

/**
 * Sets the buy limit of the current player's item.
 *
 * native void ZP_SetClientExtraItemLimit(clientIndex, iD, limit);
 **/
public int API_SetClientExtraItemLimit(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));
	
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Player doens't exist (%d)", cBasePlayer->Index);
		return -1;
	}
	
	// Get item index from native cell
	int iD = GetNativeCell(2);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Set buy limit of the current player's item
	ItemsSetLimits(cBasePlayer->Index, iD, GetNativeCell(3));
	
	// Return on success
	return iD;
}

/**
 * Gets the buy limit of the current player's item.
 *
 * native int ZP_GetClientExtraItemLimit(clientIndex, iD);
 **/
public int API_GetClientExtraItemLimit(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));
	
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Player doens't exist (%d)", cBasePlayer->Index);
		return -1;
	}
	
	// Get item index from native cell
	int iD = GetNativeCell(2);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Return buy limit of the current player's item
	return ItemsGetLimits(cBasePlayer->Index, iD);
}
 
/**
 * Load extra items from other plugin.
 *
 * native int ZP_RegisterExtraItem(name, cost, team, level, online, limit)
 **/
public int API_RegisterExtraItem(Handle isPlugin, int iNumParams)
{
	// If array hasn't been created, then create
	if(arrayExtraItems == NULL)
	{
		// Create array in handle
		arrayExtraItems = CreateArray(ExtraItemMax);
	}
	
	// Retrieves the string length from a native parameter string
	int iLenth;
	GetNativeStringLength(1, iLenth);
	
	// Strings are empty ?
	if(iLenth <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Can't register extra item with an empty name");
		return -1;
	}
	
	// Maximum amout of extra items
	if(GetArraySize(arrayExtraItems) >= ExtraItemMax)
	{
		LogEvent(false, LogType_Normal, LOG_CORE_EVENTS, LogModule_Extraitems, "ExtraItems Validation",  "Maximum number of extra items reached (%d). Skipping other items.", ExtraItemMax);
		return -1;
	}
	
	// Get native data
	static char sItemName[SMALL_LINE_LENGTH];
	
	// General
	GetNativeString(1, sItemName, sizeof(sItemName));
	
	// Initialize array block
	ArrayList arrayExtraItem = CreateArray(ExtraItemMax);
	
	// Push native data into array
	PushArrayString(arrayExtraItem, sItemName);  	 	// Index: 0
	PushArrayCell(arrayExtraItem, GetNativeCell(2)); 	// Index: 1
	PushArrayCell(arrayExtraItem, GetNativeCell(3)); 	// Index: 2
	PushArrayCell(arrayExtraItem, GetNativeCell(4)); 	// Index: 3
	PushArrayCell(arrayExtraItem, GetNativeCell(5)); 	// Index: 4
	PushArrayCell(arrayExtraItem, GetNativeCell(6)); 	// Index: 5
	
	// Store this handle in the main array
	PushArrayCell(arrayExtraItems, arrayExtraItem);
	
	// Return id under which we registered the item
	return GetArraySize(arrayExtraItems)-1;
}

/**
 * Gets the amount of all extra items.
 *
 * native int ZP_GetNumberExtraItem();
 **/
public int API_GetNumberExtraItem(Handle isPlugin, int iNumParams)
{
	return GetArraySize(arrayExtraItems);
}

/**
 * Gets the name of a extra item at a given index.
 *
 * native void ZP_GetExtraItemName(iD, sName, maxLen);
 **/
public int API_GetExtraItemName(Handle isPlugin, int iNumParams)
{
	// Get item index from native cell
	int iD = GetNativeCell(1);

	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize name char
	static char sName[PLATFORM_MAX_PATH];
	ItemsGetName(iD, sName, sizeof(sName));

	// Return on success
	return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the cost of the extra item.
 *
 * native int ZP_GetExtraItemCost(iD);
 **/
public int API_GetExtraItemCost(Handle isPlugin, int iNumParams)
{
	// Get item index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ItemsGetCost(iD);
}

/**
 * Gets the team of the extra item.
 *
 * native int ZP_GetExtraItemTeam(iD);
 **/
public int API_GetExtraItemTeam(Handle isPlugin, int iNumParams)
{
	// Get item index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ItemsGetTeam(iD);
}

/**
 * Gets the level of the extra item.
 *
 * native int ZP_GetExtraItemLevel(iD);
 **/
public int API_GetExtraItemLevel(Handle isPlugin, int iNumParams)
{
	// Get item index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ItemsGetLevel(iD);
}

/**
 * Gets the online of the extra item.
 *
 * native int ZP_GetExtraItemOnline(iD);
 **/
public int API_GetExtraItemOnline(Handle isPlugin, int iNumParams)
{
	// Get item index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ItemsGetOnline(iD);
}

/**
 * Gets the limit of the extra item.
 *
 * native int ZP_GetExtraItemLimit(iD);
 **/
public int API_GetExtraItemLimit(Handle isPlugin, int iNumParams)
{
	// Get item index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ItemsGetLimit(iD);
}

/**
 * Print the info about the extra item.
 *
 * native void ZP_PrintExtraItemInfo(clientIndex, iD);
 **/
public int API_PrintExtraItemInfo(Handle isPlugin, int iNumParams)
{
	// If help messages disable, then stop 
	if(!GetConVarBool(gCvarList[CVAR_MESSAGES_HELP]))
	{
		return -1;
	}
	
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));
	
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Player doens't exist (%d)", cBasePlayer->Index);
		return -1;
	}
	
	// Get item index from native cell
	int iD = GetNativeCell(2);
	
	// Validate index
	if(iD >= GetArraySize(arrayExtraItems))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	// Get extra item name
	static char sItemName[BIG_LINE_LENGTH];
	ItemsGetName(iD, sItemName, sizeof(sItemName));
	
	// Remove translation symbol, ifit exist
	ReplaceString(sItemName, sizeof(sItemName), "@", "");
	
	// Get client name
	static char sClientName[NORMAL_LINE_LENGTH];
	GetClientName(cBasePlayer->Index, sClientName, sizeof(sClientName));
	
	// Show message of successful buying
	TranslationPrintToChatAll("Buy extraitem", sClientName, sItemName);
	
	// Return on success
	return sizeof(sClientName);
}

/*
 * Extra items data reading API.
 */

/**
 * Gets the name of a item at a given index.
 *
 * @param iD				The item index.
 * @param sName				The string to return name in.
 * @param iMaxLen			The max length of the string.
 **/
stock void ItemsGetName(int iD, char[] sName, int iMaxLen)
{
	// Get array handle of extra item at given index
	Handle arrayExtraItem = GetArrayCell(arrayExtraItems, iD);

	// Get extra item name
	GetArrayString(arrayExtraItem, EXTRAITEMS_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the price of ammo for the item.
 *
 * @param iD				The item index.
 * @return					The ammo price.	
 **/
stock int ItemsGetCost(int iD)
{
	// Get array handle of extra item at given index
	Handle arrayExtraItem = GetArrayCell(arrayExtraItems, iD);

	// Get extra item cost
	return GetArrayCell(arrayExtraItem, EXTRAITEMS_DATA_COST);
}

/**
 * Gets the team for the item.
 *
 * @param iD				The item index.
 * @return					The team index.	
 **/
stock int ItemsGetTeam(int iD)
{
	// Get array handle of extra item at given index
	Handle arrayExtraItem = GetArrayCell(arrayExtraItems, iD);

	// Get extra item team
	return GetArrayCell(arrayExtraItem, EXTRAITEMS_DATA_TEAM);
}

/**
 * Gets the level for the item.
 *
 * @param iD				The item index.
 * @return					The level value.	
 **/
stock int ItemsGetLevel(int iD)
{
	// Get array handle of extra item at given index
	Handle arrayExtraItem = GetArrayCell(arrayExtraItems, iD);

	// Get extra item level
	return GetArrayCell(arrayExtraItem, EXTRAITEMS_DATA_LEVEL);
}

/**
 * Gets the online for the item.
 *
 * @param iD       	 		The item index.
 * @return          		The online value.	
 **/
stock int ItemsGetOnline(int iD)
{
	// Get array handle of extra item at given index
	Handle arrayExtraItem = GetArrayCell(arrayExtraItems, iD);

	// Get extra item online
	return GetArrayCell(arrayExtraItem, EXTRAITEMS_DATA_ONLINE);
}

/**
 * Gets the limit for the item.
 * @param iD				The item index.
 * @return          		The limit value.	
 **/
stock int ItemsGetLimit(int iD)
{
	// Get array handle of extra item at given index
	Handle arrayExtraItem = GetArrayCell(arrayExtraItems, iD);

	// Get extra item limit
	return GetArrayCell(arrayExtraItem, EXTRAITEMS_DATA_LIMIT);
}

/**
 * Remove the buy limit of the all player's items.
 *
 * @param clientIndex		The player index.
 **/
stock void ItemsRemoveLimits(int clientIndex)
{
	// Remove all extraitems limit
	for(int i = 0; i < GetArraySize(arrayExtraItems); i++)
	{
		gExtraBuyLimit[clientIndex][i] = 0;
	}
}

/**
 * Sets the buy limit of the current player's item.
 *
 * @param clientIndex		The player index.
 * @param iD				The item index.
 * @param nLimit			The limit value.	
 **/
stock void ItemsSetLimits(int clientIndex, int iD, int nLimit)
{
	// Set buy limit for the player
	gExtraBuyLimit[clientIndex][iD] = nLimit;
}

/**
 * Gets the buy limit of the current player's item.
 *
 * @param clientIndex		The player index.
 * @param iD				The item index.
 **/
stock int ItemsGetLimits(int clientIndex, int iD)
{
	// Get buy limit for the player
	return gExtraBuyLimit[clientIndex][iD];
}