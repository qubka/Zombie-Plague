/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          costumes.sp
 *  Type:          Manager 
 *  Description:   API for loading costumes specific variables.
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
 * @section Costumes config data indexes.
 **/
enum
{
	COSTUMES_DATA_NAME = 0,
	COSTUMES_DATA_MODEL,
	COSTUMES_DATA_BODY,
	COSTUMES_DATA_SKIN,
	COSTUMES_DATA_ATTACH,
	COSTUMES_DATA_POSITION,
	COSTUMES_DATA_ANGLE,
	COSTUMES_DATA_GROUP,
	COSTUMES_DATA_GROUP_FLAGS,
	COSTUMES_DATA_HIDE,
	COSTUMES_DATA_MERGE,
	COSTUMES_DATA_LEVEL
};
/**
 * @endsection
 **/

/**
 * Variables to store DHook calls handlers.
 **/
Handle hDHookSetEntityModel;

/**
 * Variables to store dynamic DHook offsets.
 **/
int DHook_SetEntityModel;

/*
 * Load other costumes modules
 */
#include "zp/playerclasses/costumesmenu.sp"

/**
 * @brief Costumes module init function.
 **/
void CostumesOnInit()
{
	if (!gCvarList.COSTUMES.BoolValue)
	{
		if (gServerData.MapLoaded)
		{
			if (gServerData.Costumes != null)
			{
				CostumesOnUnload();
			}
		}
		return;
	}
	
	if (gServerData.MapLoaded)
	{
		if (gServerData.Costumes == null)
		{
			gCvarList.COSTUMES.BoolValue = false;
		
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "You can't enable costume module after map start!");
			return;
		}
	}

	fnInitGameConfOffset(gServerData.SDKTools, DHook_SetEntityModel, /*CCSPlayer::*/"SetEntityModel");

	hDHookSetEntityModel = DHookCreate(DHook_SetEntityModel, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CostumesDhookOnSetEntityModel);
	DHookAddParam(hDHookSetEntityModel, HookParamType_CharPtr);
	
	if (hDHookSetEntityModel == null)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Costumes, "GameData Validation", "Failed to create DHook for \"CCSPlayer::SetEntityModel\". Update \"SourceMod\"");
	}
}

/**
 * @brief Loads costumes data from file.
 **/ 
void CostumesOnLoad()
{
	ConfigRegisterConfig(File_Costumes, Structure_KeyValue, CONFIG_FILE_ALIAS_COSTUMES);

	if (!gCvarList.COSTUMES.BoolValue)
	{
		return;
	}
	
	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_COSTUMES, sBuffer, sizeof(sBuffer));

	if (!bExists)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Missing costumes config file: %s", sBuffer);
		return;
	}

	ConfigSetConfigPath(File_Costumes, sBuffer);

	bool bSuccess = ConfigLoadConfig(File_Costumes, gServerData.Costumes, PLATFORM_LINE_LENGTH);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Unexpected error encountered loading: %s", sBuffer);
		return;
	}

	CostumesOnCacheData();

	ConfigSetConfigLoaded(File_Costumes, true);
	ConfigSetConfigReloadFunc(File_Costumes, GetFunctionByName(GetMyHandle(), "CostumesOnConfigReload"));
	ConfigSetConfigHandle(File_Costumes, gServerData.Costumes);
}

/**
 * @brief Caches costumes data from file into arrays.
 **/
void CostumesOnCacheData()
{
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Costumes, sBuffer, sizeof(sBuffer)); 
	
	KeyValues kvCostumes;
	bool bSuccess = ConfigOpenConfigFile(File_Costumes, kvCostumes);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Unexpected error caching data from costumes config file: %s", sBuffer);
		return;
	}

	int iSize = gServerData.Costumes.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "No usable data found in costumes config file: %s", sBuffer);
		return;
	}
	
	for (int i = 0; i < iSize; i++)
	{
		CostumesGetName(i, sBuffer, sizeof(sBuffer)); // Index: 0
		kvCostumes.Rewind();
		if (!kvCostumes.JumpToKey(sBuffer))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Couldn't cache costume data for: %s (check costume config)", sBuffer);
			continue;
		}
		
		if (!TranslationIsPhraseExists(sBuffer))
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Couldn't cache costume name: \"%s\" (check translation file)", sBuffer);
			continue;
		}

		ArrayList arrayCostume = gServerData.Costumes.Get(i);
		
		kvCostumes.GetString("model", sBuffer, sizeof(sBuffer), ""); 
		arrayCostume.PushString(sBuffer);                                     // Index: 1
		DecryptPrecacheModel(sBuffer); 
		arrayCostume.Push(kvCostumes.GetNum("body", 0));                      // Index: 2
		arrayCostume.Push(kvCostumes.GetNum("skin", 0));                      // Index: 3
		kvCostumes.GetString("attachment", sBuffer, sizeof(sBuffer), "facemask");  
		arrayCostume.PushString(sBuffer);                                     // Index: 4
		float vPosition[3]; kvCostumes.GetVector("position", vPosition);   
		arrayCostume.PushArray(vPosition, sizeof(vPosition));                 // Index: 5        
		float vAngle[3]; kvCostumes.GetVector("angle", vAngle);
		arrayCostume.PushArray(vAngle, sizeof(vAngle));                       // Index: 6
		kvCostumes.GetString("group", sBuffer, sizeof(sBuffer), "");  
		arrayCostume.PushString(sBuffer);                                     // Index: 7
		arrayCostume.Push(ConfigGetAdmFlags(sBuffer));                        // Index: 8
		arrayCostume.Push(ConfigKvGetStringBool(kvCostumes, "hide", "no"));   // Index: 9
		arrayCostume.Push(ConfigKvGetStringBool(kvCostumes, "merge", "off")); // Index: 10
		arrayCostume.Push(kvCostumes.GetNum("level", 0));                     // Index: 11
	}
	
	delete kvCostumes;
}

/**
 * @brief Costumes module unload function.
 **/
void CostumesOnUnload() 
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientValid(i, false)) 
		{
			CostumesRemove(i);
		}
	}
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void CostumesOnConfigReload()
{
	CostumesOnLoad();
}

/**
 * @brief Hook costumes cvar changes.
 **/
void CostumesOnCvarInit()
{
	gCvarList.COSTUMES = FindConVar("zp_costume");
	
	HookConVarChange(gCvarList.COSTUMES, CostumesOnCvarHook);
}

/**
 * @brief Creates commands for costumes module.
 **/
void CostumesOnCommandInit()
{
	CostumesMenuOnCommandInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void CostumesOnClientInit(int client)
{
	static int iD[MAXPLAYERS+1] = {-1, ...};
	
	if (!gCvarList.COSTUMES.BoolValue)
	{
		if (iD[client] != -1) 
		{
			DHookRemoveHookID(iD[client]); 
			iD[client] = -1;
		}
		return;
	}
	
	
	if (hDHookSetEntityModel)
	{
		iD[client] = DHookEntity(hDHookSetEntityModel, true, client);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Costumes, "DHook Validation", "Failed to attach DHook to \"CCSPlayer::SetEntityModel\". Update \"SourceMod\"");
	}
}

/**
 * @brief Fake client has been think.
 *
 * @param client            The client index.
 **/
void CostumesOnFakeClientThink(int client)
{
	if (!gCvarList.COSTUMES.BoolValue)
	{
		return;
	}
	
	if (GetRandomInt(0, 10))
	{
		return
	} 
	
	int iD = GetRandomInt(0, gServerData.Costumes.Length - 1);

	Action hResult;
	gForwardData._OnClientValidateCostume(client, iD, hResult);

	if (hResult == Plugin_Stop || hResult == Plugin_Handled)
	{
		return;
	}

	gClientData[client].Costume = iD;

	CostumesCreateEntity(client);
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void CostumesOnClientDeath(int client)
{
	CostumesRemove(client);
}

/**
 * Cvar hook callback (zp_costume)
 * @brief Costumes module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CostumesOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	CostumesOnInit();
}

/*
 * Costumes natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void CostumesOnNativeInit() 
{
	CreateNative("ZP_GetNumberCostumes",    API_GetNumberCostumes);
	CreateNative("ZP_GetClientCostume",     API_GetClientCostume);
	CreateNative("ZP_SetClientCostume",     API_SetClientCostume);
	CreateNative("ZP_GetCostumeNameID",     API_GetCostumeNameID);
	CreateNative("ZP_GetCostumeName",       API_GetCostumeName);
	CreateNative("ZP_GetCostumeModel",      API_GetCostumeModel);
	CreateNative("ZP_GetCostumeBody",       API_GetCostumeBody);
	CreateNative("ZP_GetCostumeSkin",       API_GetCostumeSkin);
	CreateNative("ZP_GetCostumeAttach",     API_GetCostumeAttach);
	CreateNative("ZP_GetCostumePosition",   API_GetCostumePosition);
	CreateNative("ZP_GetCostumeAngle",      API_GetCostumeAngle);
	CreateNative("ZP_GetCostumeGroup",      API_GetCostumeGroup);
	CreateNative("ZP_GetCostumeGroupFlags", API_GetCostumeGroupFlags);
	CreateNative("ZP_IsCostumeHide",        API_IsCostumeHide);
	CreateNative("ZP_IsCostumeMerge",       API_IsCostumeMerge);
	CreateNative("ZP_GetCostumeLevel",      API_GetCostumeLevel);
}
 
/**
 * @brief Gets the amount of all costumes.
 *
 * @note native int ZP_GetNumberCostumes();
 **/
public int API_GetNumberCostumes(Handle hPlugin, int iNumParams)
{
	return gServerData.Costumes.Length;
}

/**
 * @brief Gets the costume index of the client.
 *
 * @note native int ZP_GetClientCostume(client);
 **/
public int API_GetClientCostume(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	return gClientData[client].Costume;
}

/**
 * @brief Sets the costume index to the client.
 *
 * @note native void ZP_SetClientCostume(client, iD);
 **/
public int API_SetClientCostume(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	int iD = GetNativeCell(2);

	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	Action hResult;
	gForwardData._OnClientValidateCostume(client, iD, hResult);

	if (hResult == Plugin_Continue || hResult == Plugin_Changed)
	{
		gClientData[client].Costume = iD;
	}

	return iD;
}

/**
 * @brief Gets the index of a costume at a given name.
 *
 * @note native int ZP_GetCostumeNameID(name);
 **/
public int API_GetCostumeNameID(Handle hPlugin, int iNumParams)
{
	int maxLen;
	GetNativeStringLength(1, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Can't find costume with an empty name");
		return -1;
	}
	
	static char sName[SMALL_LINE_LENGTH];

	GetNativeString(1, sName, sizeof(sName));

	return CostumesNameToIndex(sName);  
}

/**
 * @brief Gets the name of a costume at a given id.
 *
 * @note native void ZP_GetCostumeName(iD, name, maxlen);
 **/
public int API_GetCostumeName(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sName[SMALL_LINE_LENGTH];
	CostumesGetName(iD, sName, sizeof(sName));

	return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the model of a costume at a given id.
 *
 * @note native void ZP_GetCostumeModel(iD, model, maxlen);
 **/
public int API_GetCostumeModel(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sModel[PLATFORM_LINE_LENGTH];
	CostumesGetModel(iD, sModel, sizeof(sModel));

	return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the body index of the costume.
 *
 * @note native int ZP_GetCostumeBody(iD);
 **/
public int API_GetCostumeBody(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	return CostumesGetBody(iD);
}

/**
 * @brief Gets the skin index of the costume.
 *
 * @note native int ZP_GetCostumeSkin(iD);
 **/
public int API_GetCostumeSkin(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	return CostumesGetSkin(iD);
}

/**
 * @brief Gets the attachment of a costume at a given id.
 *
 * @note native void ZP_GetCostumeAttach(iD, attach, maxlen);
 **/
public int API_GetCostumeAttach(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sAttach[SMALL_LINE_LENGTH];
	CostumesGetAttach(iD, sAttach, sizeof(sAttach));

	return SetNativeString(2, sAttach, maxLen);
}

/**
 * @brief Gets the position of a costume at a given id.
 *
 * @note native void ZP_GetCostumePosition(iD, position);
 **/
public int API_GetCostumePosition(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	static float vPosition[3];
	CostumesGetPosition(iD, vPosition);

	return SetNativeArray(2, vPosition, sizeof(vPosition));
}

/**
 * @brief Gets the angle of a costume at a given id.
 *
 * @note native void ZP_GetCostumeAngle(iD, angle);
 **/
public int API_GetCostumeAngle(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	static float vAngle[3];
	CostumesGetAngle(iD, vAngle);

	return SetNativeArray(2, vAngle, sizeof(vAngle));
}

/**
 * @brief Gets the group of a costume at a given id.
 *
 * @note native void ZP_GetCostumeGroup(iD, group, maxlen);
 **/
public int API_GetCostumeGroup(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sGroup[SMALL_LINE_LENGTH];
	CostumesGetGroup(iD, sGroup, sizeof(sGroup));

	return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the group flags of the costume.
 *
 * @note native int ZP_GetCostumeGroupFlags(iD);
 **/
public int API_GetCostumeGroupFlags(Handle hPlugin, int iNumParams)
{    
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	return CostumesGetGroupFlags(iD);
}

/**
 * @brief Gets the hide value of the costume.
 *
 * @note native bool ZP_IsCostumeHide(iD);
 **/
public int API_IsCostumeHide(Handle hPlugin, int iNumParams)
{    
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	return CostumesIsHide(iD);
}

/**
 * @brief Gets the merge value of the costume.
 *
 * @note native bool ZP_IsCostumeMerge(iD);
 **/
public int API_IsCostumeMerge(Handle hPlugin, int iNumParams)
{    
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	return CostumesIsMerge(iD);
}

/**
 * @brief Gets the level of the costume.
 *
 * @note native int ZP_GetCostumeLevel(iD);
 **/
public int API_GetCostumeLevel(Handle hPlugin, int iNumParams)
{    
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Costumes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
		return -1;
	}
	
	return CostumesGetLevel(iD);
}

/*
 * Costumes data reading API.
 */

/**
 * @brief Gets the name of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The lenght of string.
 **/
void CostumesGetName(int iD, char[] sName, int iMaxLen)
{
	if (iD == -1)
	{
		strcopy(sName, iMaxLen, "");
		return;
	}
	
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	arrayCostume.GetString(COSTUMES_DATA_NAME, sName, iMaxLen);
} 

/**
 * @brief Gets the model of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The lenght of string.
 **/
void CostumesGetModel(int iD, char[] sModel, int iMaxLen)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	arrayCostume.GetString(COSTUMES_DATA_MODEL, sModel, iMaxLen);
} 

/**
 * @brief Gets the body index of the costume.
 *
 * @param iD                The costume index.
 * @return                  The body index. 
 **/
bool CostumesGetBody(int iD)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	return arrayCostume.Get(COSTUMES_DATA_BODY);
}

/**
 * @brief Gets the skin index of the costume.
 *
 * @param iD                The costume index.
 * @return                  The skin index. 
 **/
bool CostumesGetSkin(int iD)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	return arrayCostume.Get(COSTUMES_DATA_SKIN);
}

/**
 * @brief Gets the attachment of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sAttach           The string to return attachment in.
 * @param iMaxLen           The lenght of string.
 **/
void CostumesGetAttach(int iD, char[] sAttach, int iMaxLen)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	arrayCostume.GetString(COSTUMES_DATA_ATTACH, sAttach, iMaxLen);
}

/**
 * @brief Gets the position of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param vPosition         The position output.
 **/
void CostumesGetPosition(int iD, float vPosition[3])
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	arrayCostume.GetArray(COSTUMES_DATA_POSITION, vPosition, sizeof(vPosition));
}

/**
 * @brief Gets the anlge of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param vAngle            The angle output.
 **/
void CostumesGetAngle(int iD, float vAngle[3])
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	arrayCostume.GetArray(COSTUMES_DATA_ANGLE, vAngle, sizeof(vAngle));
}

/**
 * @brief Gets the group of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The lenght of string.
 **/
void CostumesGetGroup(int iD, char[] sGroup, int iMaxLen)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	arrayCostume.GetString(COSTUMES_DATA_GROUP, sGroup, iMaxLen);
} 

/**
 * @brief Gets the group flags of the costume.
 * 
 * @param iD                The costume index.
 * @return                  The flags bits.     
 **/
int CostumesGetGroupFlags(int iD)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	return arrayCostume.Get(COSTUMES_DATA_GROUP_FLAGS);
}
 
/**
 * @brief Retrieve costume hide value.
 * 
 * @param iD                The costume index.
 * @return                  True if costume is hided, false if not.
 **/
bool CostumesIsHide(int iD)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	return arrayCostume.Get(COSTUMES_DATA_HIDE);
}

/**
 * @brief Retrieve costume merge value.
 * 
 * @param iD                The costume index.
 * @return                  True if costume is merged, false if not.
 **/
bool CostumesIsMerge(int iD)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	return arrayCostume.Get(COSTUMES_DATA_MERGE);
}

/**
 * @brief Gets the level of the costume.
 * 
 * @param iD                The costume index.
 * @return                  The level amount.    
 **/
int CostumesGetLevel(int iD)
{
	ArrayList arrayCostume = gServerData.Costumes.Get(iD);
	
	return arrayCostume.Get(COSTUMES_DATA_LEVEL);
}
 
/*
 * Stocks costumes API.
 */
 
/**
 * @brief Find the index at which the costume name is at.
 * 
 * @param sName             The costume name.
 * @return                  The costume index.
 **/
int CostumesNameToIndex(const char[] sName)
{
	static char sCostumeName[SMALL_LINE_LENGTH];
	
	int iSize = gServerData.Costumes.Length;
	for (int i = 0; i < iSize; i++)
	{
		CostumesGetName(i, sCostumeName, sizeof(sCostumeName));
		
		if (!strcmp(sName, sCostumeName, false))
		{
			return i;
		}
	}
	
	return -1;
}
 
/**
 * DHook: Sets the model to a given player.
 * @note void CCSPlayer::SetModel(char const*)
 *
 * @param client            The client index.
 **/
public MRESReturn CostumesDhookOnSetEntityModel(int client)
{
	CostumesCreateEntity(client);
	
	return MRES_Handled;
}

/**
 * @brief Creates an attachment costume entity for the client.
 *
 * @param client            The client index.
 **/
void CostumesCreateEntity(int client)
{
	if (IsClientValid(client))
	{
		CostumesRemove(client);

		if (gClientData[client].Zombie)
		{
			return;
		}
		
		int iSize = gServerData.Costumes.Length;

		if (gClientData[client].Costume == -1 || iSize <= gClientData[client].Costume)
		{
			gClientData[client].Costume = -1;
			return;
		}

		int iGroup = CostumesGetGroupFlags(gClientData[client].Costume);
		if (iGroup && !(iGroup & GetUserFlagBits(client)))
		{
			gClientData[client].Costume = -1;
			return;
		}

		static char sModel[PLATFORM_LINE_LENGTH];
		CostumesGetModel(gClientData[client].Costume, sModel, sizeof(sModel));
		
		int entity = UTIL_CreateDynamic("costume", NULL_VECTOR, NULL_VECTOR, sModel);
		
		if (entity != -1)
		{
			ToolsSetTextures(entity, CostumesGetBody(gClientData[client].Costume), CostumesGetSkin(gClientData[client].Costume)); 

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client, entity);
			ToolsSetOwner(entity, client);

			static char sAttach[SMALL_LINE_LENGTH];
			CostumesGetAttach(gClientData[client].Costume, sAttach, sizeof(sAttach)); 

			if (LookupEntityAttachment(client, sAttach))
			{
				SetVariantString(sAttach);
				AcceptEntityInput(entity, "SetParentAttachment", client, entity);
			}
			else
			{
				static float vPosition[3]; static float vAngle[3]; static float vEntOrigin[3]; static float vEntAngle[3]; static float vForward[3]; static float vRight[3];  static float vVertical[3]; 

				ToolsGetAbsOrigin(client, vPosition); 
				ToolsGetAbsAngles(client, vAngle);
				
				CostumesGetPosition(gClientData[client].Costume, vEntOrigin);
				CostumesGetAngle(gClientData[client].Costume, vEntAngle);
				
				AddVectors(vAngle, vEntAngle, vAngle);
				
				GetAngleVectors(vAngle, vForward, vRight, vVertical);
				
				vPosition[0] += (vForward[0] * vEntOrigin[0]) + (vRight[0] * vEntOrigin[1]) + (vVertical[0] * vEntOrigin[2]);
				vPosition[1] += (vForward[1] * vEntOrigin[0]) + (vRight[1] * vEntOrigin[1]) + (vVertical[1] * vEntOrigin[2]);
				vPosition[2] += (vForward[2] * vEntOrigin[0]) + (vRight[2] * vEntOrigin[1]) + (vVertical[2] * vEntOrigin[2]);

				TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);
			}
		
			if (CostumesIsMerge(gClientData[client].Costume)) CostumesBoneMerge(entity);

			if (CostumesIsHide(gClientData[client].Costume)) SDKHook(entity, SDKHook_SetTransmit, ToolsOnEntityTransmit);
			
			gClientData[client].AttachmentCostume = EntIndexToEntRef(entity);
		}
	}
}

/**
 * @brief Performs a bone merge on the client side.
 *
 * @param entity            The entity index.
 **/
void CostumesBoneMerge(int entity)
{
	int iEffects = ToolsGetEffect(entity); 

	iEffects &= ~EF_NODRAW;
	iEffects |= EF_BONEMERGE;
	iEffects |= EF_BONEMERGE_FASTCULL;

	ToolsSetEffect(entity, iEffects); 
}

/**
 * @brief Remove a costume entities from the client.
 *
 * @param client            The client index.
 **/
void CostumesRemove(int client)
{
	int entity = EntRefToEntIndex(gClientData[client].AttachmentCostume);

	if (entity != -1) 
	{
		AcceptEntityInput(entity, "Kill"); /// Destroy
	}
}
