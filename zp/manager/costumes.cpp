/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          costumes.cpp
 *  Type:          Manager 
 *  Description:   API for loading costumes specific variables.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
    COSTUMES_DATA_HIDE,
    COSTUMES_DATA_MERGE,
    COSTUMES_DATA_LEVEL
};
/**
 * @endsection
 **/
 
#if defined USE_DHOOKS
/**
 * Variables to store DHook calls handlers.
 **/
Handle hDHookSetEntityModel;

/**
 * Variables to store dynamic DHook offsets.
 **/
int DHook_SetEntityModel;
#endif

/**
 * Сostumes module init function.
 **/
void CostumesOnInit(/*void*/)
{
    // If module is disabled, then stop
    if(!gCvarList[CVAR_COSTUMES].BoolValue)
    {
        // Validate loaded map
        if(gServerData.MapLoaded)
        {
            // Is costumes was load
            if(gServerData.Costumes != null)
            {
                // Destroy costumes
                CostumesOnUnload();
            }
        }
        return;
    }
    
    // Validate loaded map
    if(gServerData.MapLoaded)
    {
        // No costumes?
        if(gServerData.Costumes == null)
        {
            // Reset value
            gCvarList[CVAR_COSTUMES].BoolValue = false;
        
            // Log failure
            LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Costumes, "Config Validation", "You can't enable costume module after map start!");
            return;
        }
    }
    
    #if defined USE_DHOOKS
    // Load offsets
    fnInitGameConfOffset(gServerData.SDKTools, DHook_SetEntityModel, /*CBasePlayer::*/"SetEntityModel");

    /// CBasePlayer::SetModel(CBasePlayer *this, char const*)
    hDHookSetEntityModel = DHookCreate(DHook_SetEntityModel, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CostumesDhookOnSetEntityModel);
    DHookAddParam(hDHookSetEntityModel, HookParamType_CharPtr);
    
    // Validate hook
    if(hDHookSetEntityModel == null)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Costumes, "GameData Validation", "Failed to create DHook for \"CBasePlayer::SetEntityModel\". Update \"SourceMod\"");
        return;
    }
    #endif
}

/**
 * @brief Loads costumes data from file.
 **/ 
void CostumesOnLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Costumes, Structure_Keyvalue, CONFIG_FILE_ALIAS_COSTUMES);

    // If costumes is disabled, then stop
    if(!gCvarList[CVAR_COSTUMES].BoolValue)
    {
        return;
    }
    
    // Gets costumes config path
    static char sPathCostumes[PLATFORM_LINE_LENGTH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_COSTUMES, sPathCostumes);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Costumes, "Config Validation", "Missing costumes config file: %s", sPathCostumes);
        return;
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_Costumes, sPathCostumes);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Costumes, gServerData.Costumes);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Costumes, "Config Validation", "Unexpected error encountered loading: %s", sPathCostumes);
        return;
    }

    // Now copy data to array structure
    CostumesOnCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Costumes, true);
    ConfigSetConfigReloadFunc(File_Costumes, GetFunctionByName(GetMyHandle(), "CostumesOnConfigReload"));
    ConfigSetConfigHandle(File_Costumes, gServerData.Costumes);
}

/**
 * @brief Caches costumes data from file into arrays.
 **/
void CostumesOnCacheData(/*void*/)
{
    // Gets config file path
    static char sPathCostumes[PLATFORM_LINE_LENGTH];
    ConfigGetConfigPath(File_Costumes, sPathCostumes, sizeof(sPathCostumes)); 
    
    // Opens config
    KeyValues kvCostumes;
    bool bSuccess = ConfigOpenConfigFile(File_Costumes, kvCostumes);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Costumes, "Config Validation", "Unexpected error caching data from costumes config file: %s", sPathCostumes);
        return;
    }

    // Validate size
    int iSize = gServerData.Costumes.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Costumes, "Config Validation", "No usable data found in costumes config file: %s", sPathCostumes);
        return;
    }
    
    // i = array index
    for(int i = 0; i < iSize; i++)
    {
        // General
        CostumesGetName(i, sPathCostumes, sizeof(sPathCostumes)); // Index: 0
        kvCostumes.Rewind();
        if(!kvCostumes.JumpToKey(sPathCostumes))
        {
            // Log costume fatal
            LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Costumes, "Config Validation", "Couldn't cache costume data for: %s (check costume config)", sPathCostumes);
            continue;
        }
        
        // Validate translation
        StringToLower(sPathCostumes);
        if(!TranslationPhraseExists(sPathCostumes))
        {
            // Log costume error
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Costumes, "Config Validation", "Couldn't cache costume name: \"%s\" (check translation file)", sPathCostumes);
            continue;
        }

        // Gets array size
        ArrayList arrayCostume = gServerData.Costumes.Get(i);
        
        // Push data into array
        kvCostumes.GetString("model", sPathCostumes, sizeof(sPathCostumes), ""); 
        arrayCostume.PushString(sPathCostumes);                               // Index: 1
        DecryptPrecacheModel(sPathCostumes); 
        arrayCostume.Push(kvCostumes.GetNum("body", 0));                      // Index: 2
        arrayCostume.Push(kvCostumes.GetNum("skin", 0));                      // Index: 3
        kvCostumes.GetString("attachment", sPathCostumes, sizeof(sPathCostumes), "facemask");  
        arrayCostume.PushString(sPathCostumes);                               // Index: 4
        float vPosition[3]; kvCostumes.GetVector("position", vPosition);   
        arrayCostume.PushArray(vPosition, sizeof(vPosition));                 // Index: 5        
        float vAngle[3]; kvCostumes.GetVector("angle", vAngle);
        arrayCostume.PushArray(vAngle, sizeof(vAngle));                       // Index: 6
        kvCostumes.GetString("group", sPathCostumes, sizeof(sPathCostumes), "");  
        arrayCostume.PushString(sPathCostumes);                               // Index: 7
        arrayCostume.Push(ConfigKvGetStringBool(kvCostumes, "hide", "no"));   // Index: 8
        arrayCostume.Push(ConfigKvGetStringBool(kvCostumes, "merge", "off")); // Index: 9
        arrayCostume.Push(kvCostumes.GetNum("level", 0));                     // Index: 10
    }
    
    // We're done with this file now, so we can close it
    delete kvCostumes;
}

/**
 * @brief Costumes module unload function.
 **/
void CostumesOnUnload(/*void*/) 
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++) 
    {
        // Validate client
        if(IsPlayerExist(i, false)) 
        {
            // Remove current costume
            CostumesRemove(i);
        }
    }
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void CostumesOnConfigReload(/*void*/)
{
    // Reloads costumes config
    CostumesOnLoad();
}

/**
 * @brief Creates commands for costumes module.
 **/
void CostumesOnCommandInit(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zp_costume_menu", CostumesOnCommandCatched, "Opens the costumes menu.");
}

/**
 * @brief Hook costumes cvar changes.
 **/
void CostumesOnCvarInit(/*void*/)
{
    // Creates cvars
    gCvarList[CVAR_COSTUMES] = FindConVar("zp_costume");
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_COSTUMES], CostumesOnCvarHook);
}

/**
 * @brief Client has been joined.
 * 
 * @param clientIndex       The client index.  
 **/
void CostumesOnClientInit(int clientIndex)
{
    #if defined USE_DHOOKS
    // Initialize id
    static int iD[MAXPLAYERS+1] = {-1, ...};
    
    // If module is disabled, then stop
    if(!gCvarList[CVAR_COSTUMES].BoolValue)
    {
        // Validate hook
        if(iD[clientIndex] != -1) 
        {
            // Unhook entity callbacks
            DHookRemoveHookID(iD[clientIndex]); 
            iD[clientIndex] = -1;
        }
        return;
    }
    
    // Hook entity callbacks
    iD[clientIndex] = DHookEntity(hDHookSetEntityModel, true, clientIndex);
    #else
        #pragma unused clientIndex
    #endif
}

/**
 * Console command callback (zp_costume_menu)
 * @brief Opens the costumes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action CostumesOnCommandCatched(int clientIndex, int iArguments)
{
    CostumesMenu(clientIndex);
    return Plugin_Handled;
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
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    CostumesOnInit();
}

/**
 * Hook: SetTransmit
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public Action CostumesOnTransmit(int entityIndex, int clientIndex)
{
    // Validate addons
    if(EntRefToEntIndex(gClientData[clientIndex].AttachmentCostume) == entityIndex)
    {
        // Validate observer mode
        if(ToolsGetClientObserverMode(clientIndex))
        {
            // Allow transmitting    
            return Plugin_Continue;
        }

        // Block transmitting
        return Plugin_Handled;
    }
    
    // Gets the owner of the entity
    int ownerIndex = ToolsGetEntityOwner(entityIndex);

    // Validate dead owner
    if(!IsPlayerAlive(ownerIndex))
    {
        // Block transmitting
        return Plugin_Handled;
    }
    
    // Validate observer mode
    if(ToolsGetClientObserverMode(clientIndex) == SPECMODE_FIRSTPERSON && ownerIndex == ToolsGetClientObserverTarget(clientIndex))
    {
        // Block transmitting
        return Plugin_Handled;
    }

    // Allow transmitting
    return Plugin_Continue;
}

/*
 * Costumes natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void CostumesOnNativeInit(/*void*/) 
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
    // Return the value 
    return gServerData.Costumes.Length;
}

/**
 * @brief Gets the costume index of the client.
 *
 * @note native int ZP_GetClientCostume(clientIndex);
 **/
public int API_GetClientCostume(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex].Costume;
}

/**
 * @brief Sets the costume index to the client.
 *
 * @note native void ZP_SetClientCostume(clientIndex, iD);
 **/
public int API_SetClientCostume(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Call forward
    Action resultHandle;
    gForwardData._OnClientValidateCostume(clientIndex, iD, resultHandle);

    // Validate handle
    if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
    {
        // Sets costume to the client
        gClientData[clientIndex].Costume = iD;
    }

    // Return on success
    return iD;
}

/**
 * @brief Gets the index of a costume at a given name.
 *
 * @note native int ZP_GetCostumeNameID(name);
 **/
public int API_GetCostumeNameID(Handle hPlugin, int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Can't find costume with an empty name");
        return -1;
    }
    
    // Gets native data
    static char sName[SMALL_LINE_LENGTH];

    // General
    GetNativeString(1, sName, sizeof(sName));

    // Return the value
    return CostumesNameToIndex(sName);  
}

/**
 * @brief Gets the name of a costume at a given id.
 *
 * @note native void ZP_GetCostumeName(iD, name, maxlen);
 **/
public int API_GetCostumeName(Handle hPlugin, int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    CostumesGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the model of a costume at a given id.
 *
 * @note native void ZP_GetCostumeModel(iD, model, maxlen);
 **/
public int API_GetCostumeModel(Handle hPlugin, int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    CostumesGetModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the body index of the costume.
 *
 * @note native int ZP_GetCostumeBody(iD);
 **/
public int API_GetCostumeBody(Handle hPlugin, int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return CostumesGetBody(iD);
}

/**
 * @brief Gets the skin index of the costume.
 *
 * @note native int ZP_GetCostumeSkin(iD);
 **/
public int API_GetCostumeSkin(Handle hPlugin, int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return CostumesGetSkin(iD);
}

/**
 * @brief Gets the attachment of a costume at a given id.
 *
 * @note native void ZP_GetCostumeAttach(iD, attach, maxlen);
 **/
public int API_GetCostumeAttach(Handle hPlugin, int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize attachment char
    static char sAttach[SMALL_LINE_LENGTH];
    CostumesGetAttach(iD, sAttach, sizeof(sAttach));

    // Return on success
    return SetNativeString(2, sAttach, maxLen);
}

/**
 * @brief Gets the position of a costume at a given id.
 *
 * @note native void ZP_GetCostumePosition(iD, position);
 **/
public int API_GetCostumePosition(Handle hPlugin, int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Initialize position vector
    static float vPosition[3];
    CostumesGetPosition(iD, vPosition);

    // Return on success
    return SetNativeArray(2, vPosition, sizeof(vPosition));
}

/**
 * @brief Gets the angle of a costume at a given id.
 *
 * @note native void ZP_GetCostumeAngle(iD, angle);
 **/
public int API_GetCostumeAngle(Handle hPlugin, int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Initialize angle vector
    static float vAngle[3];
    CostumesGetAngle(iD, vAngle);

    // Return on success
    return SetNativeArray(2, vAngle, sizeof(vAngle));
}

/**
 * @brief Gets the group of a costume at a given id.
 *
 * @note native void ZP_GetCostumeGroup(iD, group, maxlen);
 **/
public int API_GetCostumeGroup(Handle hPlugin, int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    CostumesGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the hide value of the costume.
 *
 * @note native bool ZP_IsCostumeHide(iD);
 **/
public int API_IsCostumeHide(Handle hPlugin, int iNumParams)
{    
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return CostumesIsHide(iD);
}

/**
 * @brief Gets the merge value of the costume.
 *
 * @note native bool ZP_IsCostumeMerge(iD);
 **/
public int API_IsCostumeMerge(Handle hPlugin, int iNumParams)
{    
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return CostumesIsMerge(iD);
}

/**
 * @brief Gets the level of the costume.
 *
 * @note native int ZP_GetCostumeLevel(iD);
 **/
public int API_GetCostumeLevel(Handle hPlugin, int iNumParams)
{    
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Costumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value 
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume name
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume model
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume body index
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume skin index
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume attachment
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume position
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume angle
    arrayCostume.GetArray(COSTUMES_DATA_ANGLE, vAngle, sizeof(vAngle));
}

/**
 * @brief Gets the access group of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The lenght of string.
 **/
void CostumesGetGroup(int iD, char[] sGroup, int iMaxLen)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume group
    arrayCostume.GetString(COSTUMES_DATA_GROUP, sGroup, iMaxLen);
} 

/**
 * @brief Retrieve costume hide value.
 * 
 * @param iD                The costume index.
 * @return                  True if costume is hided, false if not.
 **/
bool CostumesIsHide(int iD)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Return true if costume is hide, false if not
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Return true if costume is merged, false if not
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
    // Gets array handle of costume at given index
    ArrayList arrayCostume = gServerData.Costumes.Get(iD);
    
    // Gets costume level 
    return arrayCostume.Get(COSTUMES_DATA_LEVEL);
}
 
/*
 * Stocks costumes API.
 */
 
/**
 * @brief Find the index at which the costume name is at.
 * 
 * @param sName             The costume name.
 * @return                  The array index containing the given costume name.
 **/
int CostumesNameToIndex(char[] sName)
{
    // Initialize name char
    static char sCostumeName[SMALL_LINE_LENGTH];
    
    // i = costume index
    int iSize = gServerData.Costumes.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets costume name 
        CostumesGetName(i, sCostumeName, sizeof(sCostumeName));
        
        // If names match, then return index
        if(!strcmp(sName, sCostumeName, false))
        {
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return -1;
}
 
/**
 * @brief Creates a costume menu.
 *
 * @param clientIndex       The client index.
 **/
void CostumesMenu(int clientIndex)
{
    // If module is disabled, then stop
    if(!gCvarList[CVAR_COSTUMES].BoolValue)
    {
        return;
    }
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Initialize variables
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sName[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];
    static char sLevel[SMALL_LINE_LENGTH];
    static char sGroup[SMALL_LINE_LENGTH];
    
    // Creates menu handle
    Menu hMenu = CreateMenu(CostumesMenuSlots);
    
    // Sets language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "costumes menu");
    
    // Initialize forward
    Action resultHandle;
    
    // i = array index
    int iSize = gServerData.Costumes.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Call forward
        gForwardData._OnClientValidateCostume(clientIndex, i, resultHandle);
        
        // Skip, if class is disabled
        if(resultHandle == Plugin_Stop)
        {
            continue;
        }
        
        // Gets costume data
        CostumesGetName(i, sName, sizeof(sName));
        CostumesGetGroup(i, sGroup, sizeof(sGroup));
        
        // Format some chars for showing in menu
        FormatEx(sLevel, sizeof(sLevel), "%t", "level", CostumesGetLevel(i));
        FormatEx(sBuffer, sizeof(sBuffer), "%t  %s", sName, (hasLength(sGroup) && !IsPlayerInGroup(clientIndex, sGroup)) ? sGroup : (gClientData[clientIndex].Level < CostumesGetLevel(i)) ? sLevel : "");

        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(resultHandle == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(clientIndex, sGroup)) || gClientData[clientIndex].Level < CostumesGetLevel(i) || gClientData[clientIndex].Costume == i) ? false : true);
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iSize)
    {
        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
        hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
    }

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the main menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int CostumesMenuSlots(Menu hMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            delete hMenu;
        }

        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Opens menu back
                int iD[2]; iD = MenusCommandToArray("zp_costume_menu");
                if(iD[0] != -1) SubMenu(clientIndex, iD[0]);
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Validate client
            if(!IsPlayerExist(clientIndex, false))
            {
                return;
            }
            
            // Initialize key char
            static char sKey[SMALL_LINE_LENGTH];

            // Gets menu info
            hMenu.GetItem(mSlot, sKey, sizeof(sKey));
            int iD = StringToInt(sKey);
            
            // Call forward
            Action resultHandle;
            gForwardData._OnClientValidateCostume(clientIndex, iD, resultHandle);
            
            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Sets costume to the client
                gClientData[clientIndex].Costume = iD;
                
                // Update costume in the database
                DataBaseOnClientUpdate(clientIndex, ColumnType_Costume);
                
                // Sets costume
                CostumesCreateEntity(clientIndex);
            }
        }
    }
}

#if defined USE_DHOOKS
/**
 * DHook: Sets the model to a given player.
 * @note void CBasePlayer::SetModel(char const*)
 *
 * @param clientIndex       The client index.
 **/
public MRESReturn CostumesDhookOnSetEntityModel(int clientIndex)
{
    // Update costume
    CostumesCreateEntity(clientIndex);
}
#endif

/**
 * @brief Creates an attachment costume entity for the client.
 *
 * @param clientIndex       The client index.
 **/
void CostumesCreateEntity(int clientIndex)
{
    // Validate client
    if(IsPlayerExist(clientIndex))
    {
        // Remove current costume
        CostumesRemove(clientIndex);

        // Validate zombie
        if(gClientData[clientIndex].Zombie)
        {
            return;
        }
        
        // Gets array size
        int iSize = gServerData.Costumes.Length;

        // Validate costume
        if(gClientData[clientIndex].Costume == -1 || iSize <= gClientData[clientIndex].Costume)
        {
            gClientData[clientIndex].Costume = -1;
            return;
        }
        
        // Gets costume group
        static char sGroup[SMALL_LINE_LENGTH];
        CostumesGetGroup(gClientData[clientIndex].Costume, sGroup, sizeof(sGroup));
        
        // Validate access
        if(hasLength(sGroup) && !IsPlayerInGroup(clientIndex, sGroup))
        {
            gClientData[clientIndex].Costume = -1;
            return;
        }

        // Creates an attach addon entity 
        int entityIndex = CreateEntityByName("prop_dynamic_override");
        
        // If entity isn't valid, then skip
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Gets costume model
            static char sModel[PLATFORM_LINE_LENGTH];
            CostumesGetModel(gClientData[clientIndex].Costume, sModel, sizeof(sModel)); 

            // Dispatch main values of the entity
            DispatchKeyValue(entityIndex, "model", sModel);
            DispatchKeyValue(entityIndex, "spawnflags", "256"); /// Start with collision disabled
            DispatchKeyValue(entityIndex, "solid", "0");
           
            // Sets bodygroup of the entity
            SetVariantInt(CostumesGetBody(gClientData[clientIndex].Costume));
            AcceptEntityInput(entityIndex, "SetBodyGroup");
            
            // Sets skin of the entity
            SetVariantInt(CostumesGetSkin(gClientData[clientIndex].Costume));
            AcceptEntityInput(entityIndex, "ModelSkin");
            
            // Spawn the entity into the world
            DispatchSpawn(entityIndex);
            
            // Sets parent to the entity
            ToolsSetEntityOwner(entityIndex, clientIndex);
            
            // Sets parent to the client
            SetVariantString("!activator");
            AcceptEntityInput(entityIndex, "SetParent", clientIndex, entityIndex);

            // Gets costume attachment
            static char sAttach[SMALL_LINE_LENGTH];
            CostumesGetAttach(gClientData[clientIndex].Costume, sAttach, sizeof(sAttach)); 

            // Validate attachment
            if(ToolsLookupAttachment(clientIndex, sAttach))
            {
                // Sets attachment to the client
                SetVariantString(sAttach);
                AcceptEntityInput(entityIndex, "SetParentAttachment", clientIndex, entityIndex);
            }
            else
            {
                // Initialize vector variables
                static float vOrigin[3]; static float vAngle[3]; static float vEntOrigin[3]; static float vEntAngle[3]; static float vForward[3]; static float vRight[3];  static float vVertical[3]; 

                // Gets client position
                GetClientAbsOrigin(clientIndex, vOrigin); 
                GetClientAbsAngles(clientIndex, vAngle);
                
                // Gets costume position
                CostumesGetPosition(gClientData[clientIndex].Costume, vEntOrigin);
                CostumesGetAngle(gClientData[clientIndex].Costume, vEntAngle);
                
                // Gets location angles
                vAngle[0] += vEntAngle[0];
                vAngle[1] += vEntAngle[1];
                vAngle[2] += vEntAngle[2];
                
                // Returns vectors in the direction of an angle
                GetAngleVectors(vAngle, vForward, vRight, vVertical);
                
                // Calculate ends point by applying all vectors distances 
                vOrigin[0] += (vForward[0] * vEntOrigin[0]) + (vRight[0] * vEntOrigin[1]) + (vVertical[0] * vEntOrigin[2]);
                vOrigin[1] += (vForward[1] * vEntOrigin[0]) + (vRight[1] * vEntOrigin[1]) + (vVertical[1] * vEntOrigin[2]);
                vOrigin[2] += (vForward[2] * vEntOrigin[0]) + (vRight[2] * vEntOrigin[1]) + (vVertical[2] * vEntOrigin[2]);

                // Spawn the entity
                TeleportEntity(entityIndex, vOrigin, vAngle, NULL_VECTOR);
            }
        
            // Validate merging
            if(CostumesIsMerge(gClientData[clientIndex].Costume)) CostumesBoneMerge(entityIndex);

            // Hook entity callbacks
            if(CostumesIsHide(gClientData[clientIndex].Costume)) SDKHook(entityIndex, SDKHook_SetTransmit, CostumesOnTransmit);
            
            // Store the client cache
            gClientData[clientIndex].AttachmentCostume = EntIndexToEntRef(entityIndex);
        }
    }
}

/**
 * @brief Performs a bone merge on the client side.
 *
 * @param entityIndex       The entity index.
 **/
void CostumesBoneMerge(int entityIndex)
{
    // Gets current effects
    int iEffects = ToolsGetEntityEffect(entityIndex); 

    // Sets merging
    iEffects &= ~EF_NODRAW;
    iEffects |= EF_BONEMERGE;
    iEffects |= EF_BONEMERGE_FASTCULL;

    // Sets value on the entity
    ToolsSetEntityEffect(entityIndex, iEffects); 
}

/**
 * @brief Remove a costume entities from the client.
 *
 * @param clientIndex       The client index.
 **/
void CostumesRemove(int clientIndex)
{
    // Gets current costume from the client reference
    int entityIndex = EntRefToEntIndex(gClientData[clientIndex].AttachmentCostume);

    // Validate costume
    if(entityIndex != INVALID_ENT_REFERENCE) 
    {
        AcceptEntityInput(entityIndex, "Kill"); /// Destroy
    }
}