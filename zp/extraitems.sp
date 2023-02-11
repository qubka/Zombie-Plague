/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          extraitems.sp
 *  Type:          Manager 
 *  Description:   API for loading extraitems specific variables.
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
 * @section Item native data indexes.
 **/
enum
{
	EXTRAITEMS_DATA_SECTION,
	EXTRAITEMS_DATA_NAME,
	EXTRAITEMS_DATA_INFO,
	EXTRAITEMS_DATA_WEAPON,
	EXTRAITEMS_DATA_COST,
	EXTRAITEMS_DATA_LEVEL,
	EXTRAITEMS_DATA_ONLINE,
	EXTRAITEMS_DATA_LIMIT,
	EXTRAITEMS_DATA_FLAGS,
	EXTRAITEMS_DATA_GROUP,
	EXTRAITEMS_DATA_TYPES
};
/**
 * @endsection
 **/

/**
 * @brief Extraitem module init function.
 **/
void ExtraItemsOnInit()
{
	gServerData.ItemLimit = new StringMap(); 
} 
 
/**
 * @brief Extraitems module unload function.
 **/
void ExtraItemsOnUnload()
{
	ClearTrieList(gServerData.ItemLimit);
}

/**
 * @brief Prepare all extraitem data.
 **/
void ExtraItemsOnLoad()
{
	ConfigRegisterConfig(File_ExtraItems, Structure_KeyValue, CONFIG_FILE_ALIAS_EXTRAITEMS);

	if (!gCvarList.EXTRAITEMS.BoolValue)
	{
		return;
	}

	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_EXTRAITEMS, sBuffer, sizeof(sBuffer));

	if (!bExists)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_ExtraItems, "Config Validation", "Missing extraitems config file: \"%s\"", sBuffer);
		return;
	}

	ConfigSetConfigPath(File_ExtraItems, sBuffer);

	bool bSuccess = ConfigLoadConfig(File_ExtraItems, gServerData.ExtraItems);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_ExtraItems, "Config Validation", "Unexpected error encountered loading: \"%s\"", sBuffer);
		return;
	}

	ExtraItemsOnCacheData();

	ConfigSetConfigLoaded(File_ExtraItems, true);
	ConfigSetConfigReloadFunc(File_ExtraItems, GetFunctionByName(GetMyHandle(), "ExtraItemsOnConfigReload"));
	ConfigSetConfigHandle(File_ExtraItems, gServerData.ExtraItems);
}

/**
 * @brief Caches extraitem data from file into arrays.
 **/
void ExtraItemsOnCacheData()
{
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_ExtraItems, sBuffer, sizeof(sBuffer));

	KeyValues kvExtraItems;
	bool bSuccess = ConfigOpenConfigFile(File_ExtraItems, kvExtraItems);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_ExtraItems, "Config Validation", "Unexpected error caching data from extraitems config file: \"%s\"", sBuffer);
		return;
	}
	
	if (gServerData.Sections == null)
	{
		gServerData.Sections = new ArrayList(SMALL_LINE_LENGTH);
	}
	else
	{
		gServerData.Sections.Clear();
	}
	
	int iSize = gServerData.ExtraItems.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_ExtraItems, "Config Validation", "No usable data found in extraitems config file: \"%s\"", sBuffer);
		return;
	}
	
	for (int i = 0; i < iSize; i++)
	{
		ArrayList arrayExtraItem = gServerData.ExtraItems.Get(i);
		arrayExtraItem.GetString(EXTRAITEMS_DATA_SECTION, sBuffer, sizeof(sBuffer));

		gServerData.Sections.PushString(sBuffer);
	}

	gServerData.ExtraItems.Clear(); /// we flattening everything

	iSize = gServerData.Sections.Length;
	for (int i = 0; i < iSize; i++)
	{
		gServerData.Sections.GetString(i, sBuffer, sizeof(sBuffer));
		kvExtraItems.Rewind();
		if (!kvExtraItems.JumpToKey(sBuffer))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_ExtraItems, "Config Validation", "Couldn't cache extraitem data for: \"%s\" (check extraitems config)", sBuffer);
			continue;
		}

		if (!TranslationIsPhraseExists(sBuffer))
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_ExtraItems, "Config Validation", "Couldn't cache extraitem section: \"%s\" (check translation file)", sBuffer);
			continue;
		}

		if (kvExtraItems.GotoFirstSubKey())
		{
			do
			{
				kvExtraItems.GetSectionName(sBuffer, sizeof(sBuffer));
			
				if (!TranslationIsPhraseExists(sBuffer))
				{
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_ExtraItems, "Config Validation", "Couldn't cache extraitem name: \"%s\" (check translation file)", sBuffer);
					continue;
				}
				
								
				ArrayList arrayExtraItem = new ArrayList(NORMAL_LINE_LENGTH);

				arrayExtraItem.Push(i);                                // Index: 0
				arrayExtraItem.PushString(sBuffer);                    // Index: 1
				kvExtraItems.GetString("info", sBuffer, sizeof(sBuffer), "");
				if (hasLength(sBuffer) && !TranslationIsPhraseExists(sBuffer))
				{
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_ExtraItems, "Config Validation", "Couldn't cache extraitem info: \"%s\" (check translation file)", sBuffer);
				}
				arrayExtraItem.PushString(sBuffer);                    // Index: 2
				kvExtraItems.GetString("weapon", sBuffer, sizeof(sBuffer), ""); 
				arrayExtraItem.Push(WeaponsNameToIndex(sBuffer));      // Index: 3
				arrayExtraItem.Push(kvExtraItems.GetNum("cost", 0));   // Index: 4
				arrayExtraItem.Push(kvExtraItems.GetNum("level", 0));  // Index: 5
				arrayExtraItem.Push(kvExtraItems.GetNum("online", 0)); // Index: 6
				arrayExtraItem.Push(kvExtraItems.GetNum("limit", 0));  // Index: 7
				kvExtraItems.GetString("flags", sBuffer, sizeof(sBuffer), ""); 
				arrayExtraItem.Push(ReadFlagString(sBuffer));          // Index: 8
				kvExtraItems.GetString("group", sBuffer, sizeof(sBuffer), ""); 
				arrayExtraItem.PushString(sBuffer);                    // Index: 9
				kvExtraItems.GetString("types", sBuffer, sizeof(sBuffer), ""); 
				arrayExtraItem.Push(ClassTypeToIndex(sBuffer));        // Index: 10
				
				gServerData.ExtraItems.Push(arrayExtraItem);
			}
			while (kvExtraItems.GotoNextKey());
		}
	}

	delete kvExtraItems;
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void ExtraItemsOnConfigReload()
{
	ExtraItemsOnLoad();
}

/**
 * @brief Hook extra items cvar changes.
 **/
void ExtraItemsOnCvarInit()
{
	gCvarList.EXTRAITEMS = FindConVar("zp_extraitems");
}

/*
 * Extra items natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void ExtraItemsOnNativeInit()
{
	CreateNative("ZP_GiveClientExtraItem",     API_GiveClientExtraItem); 
	CreateNative("ZP_SetClientExtraItemLimit", API_SetClientExtraItemLimit); 
	CreateNative("ZP_GetClientExtraItemLimit", API_GetClientExtraItemLimit); 
	CreateNative("ZP_GetNumberExtraItem",      API_GetNumberExtraItem); 
	CreateNative("ZP_GetExtraItemSectionID",   API_GetExtraItemSectionID);
	CreateNative("ZP_GetExtraItemNameID",      API_GetExtraItemNameID);
	CreateNative("ZP_GetExtraItemName",        API_GetExtraItemName); 
	CreateNative("ZP_GetExtraItemInfo",        API_GetExtraItemInfo); 
	CreateNative("ZP_GetExtraItemWeaponID",    API_GetExtraItemWeaponID); 
	CreateNative("ZP_GetExtraItemCost",        API_GetExtraItemCost); 
	CreateNative("ZP_GetExtraItemLevel",       API_GetExtraItemLevel); 
	CreateNative("ZP_GetExtraItemOnline",      API_GetExtraItemOnline); 
	CreateNative("ZP_GetExtraItemLimit",       API_GetExtraItemLimit); 
	CreateNative("ZP_GetExtraItemFlags",       API_GetExtraItemFlags); 
	CreateNative("ZP_GetExtraItemGroup",       API_GetExtraItemGroup); 
	CreateNative("ZP_GetExtraItemTypes",       API_GetExtraItemTypes);
}

/**
 * @brief Give the extra item to the client.
 *
 * @note native bool ZP_GiveClientExtraItem(client, iD);
 **/
public int API_GiveClientExtraItem(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	
	if (!IsPlayerExist(client, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Player doens't exist (%d)", client);
		return -1;
	}
	
	int iD = GetNativeCell(2);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}

	Action hResult;
	gForwardData._OnClientValidateExtraItem(client, iD, hResult);

	if (hResult == Plugin_Continue || hResult == Plugin_Changed)
	{
		gForwardData._OnClientBuyExtraItem(client, iD); /// Buy item
		return true;
	}
	
	return false;
}

/**
 * @brief Sets the buy limit of the current player item.
 *
 * @note native void ZP_SetClientExtraItemLimit(client, iD, limit);
 **/
public int API_SetClientExtraItemLimit(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	
	if (!IsPlayerExist(client, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Player doens't exist (%d)", client);
		return -1;
	}
	
	int iD = GetNativeCell(2);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	ItemsSetLimits(client, iD, GetNativeCell(3));
	
	return iD;
}

/**
 * @brief Gets the buy limit of the current player item.
 *
 * @note native int ZP_GetClientExtraItemLimit(client, iD);
 **/
public int API_GetClientExtraItemLimit(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	
	if (!IsPlayerExist(client, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Player doens't exist (%d)", client);
		return -1;
	}
	
	int iD = GetNativeCell(2);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetLimits(client, iD);
}

/**
 * @brief Gets the amount of all extra items.
 *
 * @note native int ZP_GetNumberExtraItem();
 **/
public int API_GetNumberExtraItem(Handle hPlugin, int iNumParams)
{
	return gServerData.ExtraItems.Length;
}

/**
 * @brief Gets the index of a extra item at a given name.
 *
 * @note native int ZP_GetExtraItemNameID(name);
 **/
public int API_GetExtraItemNameID(Handle hPlugin, int iNumParams)
{
	int maxLen;
	GetNativeStringLength(1, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Can't find item with an empty name");
		return -1;
	}
	
	static char sName[SMALL_LINE_LENGTH];

	GetNativeString(1, sName, sizeof(sName));

	return ItemsNameToIndex(sName); 
}

/**
 * @brief Gets the section id of a extra item at a given name.
 *
 * @note native int ZP_GetExtraItemSectionID(iD);
 **/
public int API_GetExtraItemSectionID(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);

	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetSectionID(iD);
}

/**
 * @brief Gets the name of a extra item at a given index.
 *
 * @note native void ZP_GetExtraItemName(iD, name, maxlen);
 **/
public int API_GetExtraItemName(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);

	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sName[SMALL_LINE_LENGTH];
	ItemsGetName(iD, sName, sizeof(sName));

	return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the info of a extra item at a given index.
 *
 * @note native void ZP_GetExtraItemInfo(iD, info, maxlen);
 **/
public int API_GetExtraItemInfo(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);

	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sInfo[SMALL_LINE_LENGTH];
	ItemsGetInfo(iD, sInfo, sizeof(sInfo));

	return SetNativeString(2, sInfo, maxLen);
}

/**
 * @brief Gets the weapon of a extra item at a given name.
 *
 * @note native int ZP_GetExtraItemWeaponID(iD);
 **/
public int API_GetExtraItemWeaponID(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);

	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetWeaponID(iD);
}

/**
 * @brief Gets the cost of the extra item.
 *
 * @note native int ZP_GetExtraItemCost(iD);
 **/
public int API_GetExtraItemCost(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetCost(iD);
}

/**
 * @brief Gets the level of the extra item.
 *
 * @note native int ZP_GetExtraItemLevel(iD);
 **/
public int API_GetExtraItemLevel(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetLevel(iD);
}

/**
 * @brief Gets the online of the extra item.
 *
 * @note native int ZP_GetExtraItemOnline(iD);
 **/
public int API_GetExtraItemOnline(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetOnline(iD);
}

/**
 * @brief Gets the limit of the extra item.
 *
 * @note native int ZP_GetExtraItemLimit(iD);
 **/
public int API_GetExtraItemLimit(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetLimit(iD);
}

/**
 * @brief Gets the flags of the extra item.
 *
 * @note native int ZP_GetExtraItemFlags(iD);
 **/
public int API_GetExtraItemFlags(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetFlags(iD);
}

/**
 * @brief Gets the group of a extra item at a given index.
 *
 * @note native void ZP_GetExtraItemGroup(iD, group, maxlen);
 **/
public int API_GetExtraItemGroup(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);

	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sGroup[SMALL_LINE_LENGTH];
	ItemsGetGroup(iD, sGroup, sizeof(sGroup));

	return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the types of the extra item.
 *
 * @note native int ZP_GetExtraItemTypes(iD);
 **/
public int API_GetExtraItemTypes(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.ExtraItems.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_ExtraItems, "Native Validation", "Invalid the item index (%d)", iD);
		return -1;
	}
	
	return ItemsGetTypes(iD);
}

/*
 * Extra items data reading API.
 */
 
/**
 * @brief Gets the section id for the item.
 *
 * @param iD                The item index.
 * @return                  The section id.    
 **/
int ItemsGetSectionID(int iD)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	return arrayExtraItem.Get(EXTRAITEMS_DATA_SECTION);
}

/**
 * @brief Gets the name of a item at a given index.
 *
 * @param iD                The item index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The lenght of string.
 **/
void ItemsGetName(int iD, char[] sName, int iMaxLen)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	arrayExtraItem.GetString(EXTRAITEMS_DATA_NAME, sName, iMaxLen);
}

/**
 * @brief Gets the info of a item at a given index.
 *
 * @param iD                The item index.
 * @param sInfo             The string to return info in.
 * @param iMaxLen           The lenght of string.
 **/
void ItemsGetInfo(int iD, char[] sInfo, int iMaxLen)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	arrayExtraItem.GetString(EXTRAITEMS_DATA_INFO, sInfo, iMaxLen);
}

/**
 * @brief Gets the weapon for the item.
 *
 * @param iD                The item index.
 * @return                  The weapon id.    
 **/
int ItemsGetWeaponID(int iD)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	return arrayExtraItem.Get(EXTRAITEMS_DATA_WEAPON);
}

/**
 * @brief Gets the cost for the item.
 *
 * @param iD                The item index.
 * @return                  The cost amount.    
 **/
int ItemsGetCost(int iD)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	return arrayExtraItem.Get(EXTRAITEMS_DATA_COST);
}

/**
 * @brief Gets the level for the item.
 *
 * @param iD                The item index.
 * @return                  The level value.    
 **/
int ItemsGetLevel(int iD)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	return arrayExtraItem.Get(EXTRAITEMS_DATA_LEVEL);
}

/**
 * @brief Gets the online for the item.
 *
 * @param iD                The item index.
 * @return                  The online value.    
 **/
int ItemsGetOnline(int iD)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	return arrayExtraItem.Get(EXTRAITEMS_DATA_ONLINE);
}

/**
 * @brief Gets the limit for the item.
 *
 * @param iD                The item index.
 * @return                  The limit value.    
 **/
int ItemsGetLimit(int iD)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	return arrayExtraItem.Get(EXTRAITEMS_DATA_LIMIT);
}

/**
 * @brief Remove the buy limit of the all client items.
 *
 * @param client            The client index.
 **/
void ItemsRemoveLimits(int client)
{
	if (gClientData[client].ItemLimit != null)
	{
		gClientData[client].ItemLimit.Clear();
	}
}

/**
 * @brief Sets the buy limit of the current client item.
 *
 * @param client            The client index.
 * @param iD                The item index.
 * @param iLimit            The limit value.    
 **/
void ItemsSetLimits(int client, int iD, int iLimit)
{
	if (gClientData[client].ItemLimit == null)
	{
		gClientData[client].ItemLimit = new StringMap();
	}

	static char sKey[SMALL_LINE_LENGTH];
	IntToString(iD, sKey, sizeof(sKey));
	
	gClientData[client].ItemLimit.SetValue(sKey, iLimit);
}

/**
 * @brief Gets the buy limit of the current client item.
 *
 * @param client            The client index.
 * @param iD                The item index.
 **/
int ItemsGetLimits(int client, int iD)
{
	if (gClientData[client].ItemLimit == null)
	{
		gClientData[client].ItemLimit = new StringMap();
	}
	
	static char sKey[SMALL_LINE_LENGTH];
	IntToString(iD, sKey, sizeof(sKey));
	
	int iLimit; gClientData[client].ItemLimit.GetValue(sKey, iLimit);
	return iLimit;
}

/**
 * @brief Sets the map buy limit of the current client item.
 *
 * @param client            The client index.
 * @param iD                The item index.
 * @param iLimit            The limit value.    
 **/
void ItemsSetMapLimits(int client, int iD)
{
	ArrayList hList;
	
	if (gServerData.ItemLimit.GetValue(gClientID[client], hList))
	{
		if (hList.FindValue(iD) == -1)
		{
			hList.Push(iD);
		}
	}
	else
	{
		hList = new ArrayList();
		
		hList.Push(iD);
		
		gServerData.ItemLimit.SetValue(gClientID[client], hList);
	}
}

/**
 * @brief Gets the map buy limit of the current client item.
 *
 * @param client            The client index.
 * @param iD                The item index.
 **/
bool ItemsGetMapLimits(int client, int iD)
{
	if (!gServerData.ItemLimit.ContainsKey(gClientID[client]))
	{
		return false;
	}
	
	ArrayList hList;
	gServerData.ItemLimit.GetValue(gClientID[client], hList);

	return hList.FindValue(iD) != -1;
}

/**
 * @brief Gets the flags for the item.
 *
 * @param iD                The item index.
 * @return                  The flags bits.   
 **/
int ItemsGetFlags(int iD)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	return arrayExtraItem.Get(EXTRAITEMS_DATA_FLAGS);
}

/**
 * @brief Gets the group of a item at a given index.
 *
 * @param iD                The item index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The lenght of string.
 **/
void ItemsGetGroup(int iD, char[] sGroup, int iMaxLen)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	arrayExtraItem.GetString(EXTRAITEMS_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * @brief Gets the types for the item.
 *
 * @param iD                The item index.
 * @return                  The types bits.   
 **/
int ItemsGetTypes(int iD)
{
	ArrayList arrayExtraItem = gServerData.ExtraItems.Get(iD);

	return arrayExtraItem.Get(EXTRAITEMS_DATA_TYPES);
}

/*
 * Stocks extra items API.
 */

/**
 * @brief Find the index at which the extraitem name is at.
 * 
 * @param sName             The item name.
 * @return                  The array index containing the given item name.
 **/
int ItemsNameToIndex(char[] sName)
{
	static char sItemName[SMALL_LINE_LENGTH];
	
	int iSize = gServerData.ExtraItems.Length;
	for (int i = 0; i < iSize; i++)
	{
		ItemsGetName(i, sItemName, sizeof(sItemName));
		
		if (!strcmp(sName, sItemName, false))
		{
			return i;
		}
	}
	
	return -1;
}

/**
 * @brief Returns true if the player has an access by the class to the item id, false if not.
 *
 * @param client            The client index.
 * @param iD                The item id.
 * @return                  True or false.    
 **/
bool ItemsHasAccessByType(int client, int iD)
{
	return ClassHasType(ItemsGetTypes(iD), ClassGetType(gClientData[client].Class));
}