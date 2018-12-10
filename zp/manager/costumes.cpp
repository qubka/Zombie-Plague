/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          costumes.cpp
 *  Type:          Manager 
 *  Description:   Costumes table generator.
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
 * Array handle to store costumes data.
 **/
ArrayList arrayCostumes;

/**
 * Costumes config data indexes.
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
}

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
 * Client is joining the server.
 * 
 * @param clientIndex       The client index.  
 **/
void CostumesClientInit(const int clientIndex)
{
    #if defined USE_DHOOKS    
    // Hook entity callbacks
    DHookEntity(hDHookSetEntityModel, true, clientIndex);
    #else
        #pragma unused clientIndex
    #endif
}

/**
 * Creates commands for costumes module. Called when commands are created.
 **/
void CostumesOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zhatmenu", CostumesCommandCatched, "Open the costumes menu.");
}

/**
 * Handles the <!zhatmenu> command. Open the costumes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action CostumesCommandCatched(const int clientIndex, const int iArguments)
{
    // Open the costumes menu
    CostumesMenu(clientIndex);
    return Plugin_Handled;
}

/**
 * Сostumes module init function.
 **/
void CostumesInit(/*void*/)
{
    #if defined USE_DHOOKS
    // Load offsets
    fnInitGameConfOffset(gServerData[Server_GameConfig][Game_SDKTools], DHook_SetEntityModel, "SetEntityModel");

    /// CCSPlayer::SetModel(char const*)
    hDHookSetEntityModel = DHookCreate(DHook_SetEntityModel, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CostumesDhookOnSetEntityModel);
    DHookAddParam(hDHookSetEntityModel, HookParamType_CharPtr);
    #endif
}

/**
 * Loads costumes data from file.
 **/ 
void CostumesLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Costumes, Structure_Keyvalue, CONFIG_FILE_ALIAS_COSTUMES);

    // If module is disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_COSTUMES].BoolValue)
    {
        return;
    }

    // Gets costumes config path
    char sCostumePath[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetCvarFilePath(CVAR_CONFIG_PATH_COSTUMES, sCostumePath);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Missing costumes config file: %s", sCostumePath);
        return;
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_Costumes, sCostumePath);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Costumes, arrayCostumes);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        ///LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Unexpected error encountered loading: %s", sCostumePath);
        return;
    }

    // Validate costumes config
    int iSize = arrayCostumes.Length;
    if(!iSize)
    {
        ///LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "No usable data found in costumes config file: %s", sCostumePath);
        return;
    }

    // Now copy data to array structure
    CostumesCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Costumes, true);
    ConfigSetConfigReloadFunc(File_Costumes, GetFunctionByName(GetMyHandle(), "CostumesOnConfigReload"));
    ConfigSetConfigHandle(File_Costumes, arrayCostumes);
}

/**
 * Caches costumes data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void CostumesCacheData(/*void*/)
{
    // Gets config file path
    char sCostumesPath[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Costumes, sCostumesPath, sizeof(sCostumesPath)); 
    
    KeyValues kvCostumes;
    bool bSuccess = ConfigOpenConfigFile(File_Costumes, kvCostumes);

    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Unexpected error caching data from costumes config file: %s", sCostumesPath);
    }

    // i = array index
    int iSize = arrayCostumes.Length;
    for(int i = 0; i < iSize; i++)
    {
        // General
        CostumesGetName(i, sCostumesPath, sizeof(sCostumesPath)); // Index: 0
        kvCostumes.Rewind();
        if(!kvCostumes.JumpToKey(sCostumesPath))
        {
            // Log costume fatal
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Couldn't cache costume data for: %s (check costume config)", sCostumesPath);
            continue;
        }
        
        // Validate translation
        if(!TranslationPhraseExists(sCostumesPath))
        {
            // Log costume error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Costumes, "Config Validation", "Couldn't cache costume name: \"%s\" (check translation file)", sCostumesPath);
        }

        // Gets array size
        ArrayList arrayCostume = arrayCostumes.Get(i);
        
        // Push data into array
        kvCostumes.GetString("model", sCostumesPath, sizeof(sCostumesPath), ""); 
        arrayCostume.PushString(sCostumesPath);                              // Index: 1
        ModelsPrecacheStatic(sCostumesPath);
        arrayCostume.Push(kvCostumes.GetNum("body", 0));                     // Index: 2
        arrayCostume.Push(kvCostumes.GetNum("skin", 0));                     // Index: 3
        kvCostumes.GetString("attachment", sCostumesPath, sizeof(sCostumesPath), "facemask");  
        arrayCostume.PushString(sCostumesPath);                              // Index: 4
        float vPosition[3]; kvCostumes.GetVector("position", vPosition);   
        arrayCostume.PushArray(vPosition);                                   // Index: 5        
        float vAngle[3]; kvCostumes.GetVector("angle", vAngle);
        arrayCostume.PushArray(vAngle);                                      // Index: 6
        kvCostumes.GetString("group", sCostumesPath, sizeof(sCostumesPath), "");  
        arrayCostume.PushString(sCostumesPath);                              // Index: 7
        arrayCostume.Push(ConfigKvGetStringBool(kvCostumes, "hide", "no"));  // Index: 8
        arrayCostume.Push(ConfigKvGetStringBool(kvCostumes, "merge", "no")); // Index: 9
        arrayCostume.Push(kvCostumes.GetNum("level", 0));                    // Index: 10
    }
    
    // We're done with this file now, so we can close it
    delete kvCostumes;
}

/**
 * Called when configs are being reloaded.
 **/
public void CostumesOnConfigReload(/*void*/)
{
    // Reload costumes config
    CostumesLoad();
}

/*
 * Costumes natives API.
 */

/**
 * Gets the amount of all costumes.
 *
 * native int ZP_GetNumberCostumes();
 **/
public int API_GetNumberCostumes(Handle isPlugin, const int iNumParams)
{
    // Return the value 
    return arrayCostumes.Length;
}

/**
 * Gets the costume index of the client.
 *
 * native int ZP_GetClientCostume(clientIndex);
 **/
public int API_GetClientCostume(Handle isPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_Costume];
}

/**
 * Sets the costume index to the client.
 *
 * native void ZP_SetClientCostume(clientIndex, iD);
 **/
public int API_SetClientCostume(Handle isPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Call forward
    Action resultHandle = API_OnClientValidateCostume(clientIndex, iD);

    // Validate handle
    if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
    {
        // Sets costume to the client
        gClientData[clientIndex][Client_Costume] = iD;
    }

    // Return on success
    return iD;
}

/**
 * Gets the name of a costume at a given id.
 *
 * native void ZP_GetCostumeName(iD, name, maxlen);
 **/
public int API_GetCostumeName(Handle isPlugin, const int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    CostumesGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the model of a costume at a given id.
 *
 * native void ZP_GetCostumeModel(iD, model, maxlen);
 **/
public int API_GetCostumeModel(Handle isPlugin, const int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    CostumesGetModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the body index of the costume.
 *
 * native int ZP_GetCostumeBody(iD);
 **/
public int API_GetCostumeBody(Handle isPlugin, const int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return CostumesGetBody(iD);
}

/**
 * Gets the skin index of the costume.
 *
 * native int ZP_GetCostumeSkin(iD);
 **/
public int API_GetCostumeSkin(Handle isPlugin, const int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return CostumesGetSkin(iD);
}

/**
 * Gets the attachment of a costume at a given id.
 *
 * native void ZP_GetCostumeAttach(iD, attach, maxlen);
 **/
public int API_GetCostumeAttach(Handle isPlugin, const int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    CostumesGetAttach(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the position of a costume at a given id.
 *
 * native void ZP_GetCostumePosition(iD, position);
 **/
public int API_GetCostumePosition(Handle isPlugin, const int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Initialize position vector
    static float vPosition[3];
    CostumesGetPosition(iD, vPosition);

    // Return on success
    return SetNativeArray(2, vPosition, sizeof(vPosition));
}

/**
 * Gets the angle of a costume at a given id.
 *
 * native void ZP_GetCostumeAngle(iD, angle);
 **/
public int API_GetCostumeAngle(Handle isPlugin, const int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Initialize angle vector
    static float vAngle[3];
    CostumesGetAngle(iD, vAngle);

    // Return on success
    return SetNativeArray(2, vAngle, sizeof(vAngle));
}

/**
 * Gets the group of a costume at a given id.
 *
 * native void ZP_GetCostumeGroup(iD, group, maxlen);
 **/
public int API_GetCostumeGroup(Handle isPlugin, const int iNumParams)
{
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    CostumesGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * Gets the hide value of the costume.
 *
 * native bool ZP_IsCostumeHide(iD);
 **/
public int API_IsCostumeHide(Handle isPlugin, const int iNumParams)
{    
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return CostumesIsHide(iD);
}

/**
 * Gets the merge value of the costume.
 *
 * native bool ZP_IsCostumeMerge(iD);
 **/
public int API_IsCostumeMerge(Handle isPlugin, const int iNumParams)
{    
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return CostumesIsMerge(iD);
}

/**
 * Gets the level of the costume.
 *
 * native int ZP_GetCostumeLevel(iD);
 **/
public int API_GetCostumeLevel(Handle isPlugin, const int iNumParams)
{    
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayCostumes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Costumes, "Native Validation", "Invalid the costume index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return CostumesGetLevel(iD);
}

/*
 * Costumes data reading API.
 */

/**
 * Gets the name of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void CostumesGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume name
    arrayCostume.GetString(COSTUMES_DATA_NAME, sName, iMaxLen);
} 

/**
 * Gets the model of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void CostumesGetModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume model
    arrayCostume.GetString(COSTUMES_DATA_MODEL, sModel, iMaxLen);
} 

/**
 * Gets the body index of the costume.
 *
 * @param iD                The costume index.
 * @return                  The body index. 
 **/
stock bool CostumesGetBody(const int iD)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume body index
    return arrayCostume.Get(COSTUMES_DATA_BODY);
}

/**
 * Gets the skin index of the costume.
 *
 * @param iD                The costume index.
 * @return                  The skin index. 
 **/
stock bool CostumesGetSkin(const int iD)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume skin index
    return arrayCostume.Get(COSTUMES_DATA_SKIN);
}

/**
 * Gets the attachment of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sAttach           The string to return attachment in.
 * @param iMaxLen           The max length of the string.
 **/
stock void CostumesGetAttach(const int iD, char[] sAttach, const int iMaxLen)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume attachment
    arrayCostume.GetString(COSTUMES_DATA_ATTACH, sAttach, iMaxLen);
}

/**
 * Gets the position of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param vPosition         The vector to return position in.
 **/
stock void CostumesGetPosition(const int iD, float vPosition[3])
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume position
    arrayCostume.GetArray(COSTUMES_DATA_POSITION, vPosition, sizeof(vPosition));
}

/**
 * Gets the anlge of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param vAngle            The vector to return angle in.
 **/
stock void CostumesGetAngle(const int iD, float vAngle[3])
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume angle
    arrayCostume.GetArray(COSTUMES_DATA_ANGLE, vAngle, sizeof(vAngle));
}

/**
 * Gets the access group of a costume at a given index.
 *
 * @param iD                The costume index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The max length of the string.
 **/
stock void CostumesGetGroup(const int iD, char[] sGroup, const int iMaxLen)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume group
    arrayCostume.GetString(COSTUMES_DATA_GROUP, sGroup, iMaxLen);
} 

/**
 * Retrieve costume hide value.
 * 
 * @param iD                The costume index.
 * @return                  True if costume is hided, false if not.
 **/
stock bool CostumesIsHide(const int iD)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Return true if costume is hide, false if not
    return arrayCostume.Get(COSTUMES_DATA_HIDE);
}

/**
 * Retrieve costume merge value.
 * 
 * @param iD                The costume index.
 * @return                  True if costume is merged, false if not.
 **/
stock bool CostumesIsMerge(const int iD)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Return true if costume is merged, false if not
    return arrayCostume.Get(COSTUMES_DATA_MERGE);
}

/**
 * Gets the level of the costume.
 * 
 * @param iD                The costume index.
 * @return                  The level amount.    
 **/
stock int CostumesGetLevel(const int iD)
{
    // Gets array handle of costume at given index
    ArrayList arrayCostume = arrayCostumes.Get(iD);
    
    // Gets costume level 
    return arrayCostume.Get(COSTUMES_DATA_LEVEL);
}
 
/*
 * Stocks costumes API.
 */
 
/**
 * Create a costume menu.
 *
 * @param clientIndex       The client index.
 **/
void CostumesMenu(const int clientIndex)
{
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
    
    // Create menu handle
    Menu hMenu = CreateMenu(CostumesMenuSlots);
    
    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "costumes menu");
    
    // Initialize forward
    static Action resultHandle;
    
    // i = array index
    int iSize = arrayCostumes.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Call forward
        resultHandle = API_OnClientValidateCostume(clientIndex, i);
        
        // Skip, if class is disabled
        if(resultHandle == Plugin_Stop)
        {
            continue;
        }
        
        // Gets costume data
        CostumesGetName(i, sName, sizeof(sName));
        CostumesGetGroup(i, sGroup, sizeof(sGroup));
        
        // Format some chars for showing in menu
        Format(sLevel, sizeof(sLevel), "%t", "level", CostumesGetLevel(i));
        Format(sBuffer, sizeof(sBuffer), "%t\t%s", sName, (!IsPlayerInGroup(clientIndex, sGroup) && strlen(sGroup)) ? sGroup : (gClientData[clientIndex][Client_Level] < CostumesGetLevel(i)) ? sLevel : "");

        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(resultHandle == Plugin_Handled || (!IsPlayerInGroup(clientIndex, sGroup) && strlen(sGroup)) || gClientData[clientIndex][Client_Level] < CostumesGetLevel(i) || gClientData[clientIndex][Client_Costume] == i) ? false : true);
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iSize)
    {
        static char sEmpty[SMALL_LINE_LENGTH];
        Format(sEmpty, sizeof(sEmpty), "%t", "empty");

        hMenu.AddItem("empty", sEmpty, ITEMDRAW_DISABLED);
    }

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the main menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int CostumesMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
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
                // Open main menu back
                MenuMain(clientIndex);
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
            
            // Initialize variable
            static char sInfo[SMALL_LINE_LENGTH];

            // Gets ID of costume
            hMenu.GetItem(mSlot, sInfo, sizeof(sInfo));
            int iD = StringToInt(sInfo);
            
            // Call forward
            Action resultHandle = API_OnClientValidateCostume(clientIndex, iD);
            
            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Sets costume to the client
                gClientData[clientIndex][Client_Costume] = iD;
                
                // Sets costume
                CostumesCreateEntity(clientIndex);
            }
        }
    }
}

#if defined USE_DHOOKS
/**
 * DHook: Sets the model to a given entity.
 * void CCSPlayer::SetModel(char const*)
 *
 * @param clientIndex       The client index.
 **/
public MRESReturn CostumesDhookOnSetEntityModel(const int clientIndex)
{
    // Update costume
    CostumesCreateEntity(clientIndex);
}
#endif

/**
 * Create an attachment costume entity for the client.
 *
 * @param clientIndex       The client index.
 **/
public void CostumesCreateEntity(const int clientIndex)
{
    // Validate client
    if(IsPlayerExist(clientIndex))
    {
        // Gets the current costume from the client reference
        int entityIndex = EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentCostume]);

        // Validate costume
        if(entityIndex != INVALID_ENT_REFERENCE) 
        {
            AcceptEntityInput(entityIndex, "Kill"); //! Destroy
        }

        // Validate zombie
        if(gClientData[clientIndex][Client_Zombie])
        {
            return;
        }
        
        // Gets array size
        int iSize = arrayCostumes.Length;

        // Validate costume
        if(gClientData[clientIndex][Client_Costume] == -1 || iSize <= gClientData[clientIndex][Client_Costume])
        {
            gClientData[clientIndex][Client_Costume] = -1;
            return;
        }
        
        // Gets costume group
        static char sGroup[SMALL_LINE_LENGTH];
        CostumesGetGroup(gClientData[clientIndex][Client_Costume], sGroup, sizeof(sGroup));
        
        // Validate access
        if(!IsPlayerInGroup(clientIndex, sGroup) && strlen(sGroup))
        {
            gClientData[clientIndex][Client_Costume] = -1;
            return;
        }

        // Create an attach addon entity 
        entityIndex = CreateEntityByName("prop_dynamic_override");
        
        // If entity isn't valid, then skip
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Gets costume model
            static char sModel[PLATFORM_MAX_PATH];
            CostumesGetModel(gClientData[clientIndex][Client_Costume], sModel, sizeof(sModel)); 

            // Dispatch main values of the entity
            DispatchKeyValue(entityIndex, "model", sModel);
            DispatchKeyValue(entityIndex, "spawnflags", "256"); /// Start with collision disabled
            DispatchKeyValue(entityIndex, "solid", "0");
           
            // Sets bodygroup of the entity
            SetVariantInt(CostumesGetBody(gClientData[clientIndex][Client_Costume]));
            AcceptEntityInput(entityIndex, "SetBodyGroup");
            
            // Sets skin of the entity
            SetVariantInt(CostumesGetSkin(gClientData[clientIndex][Client_Costume]));
            AcceptEntityInput(entityIndex, "ModelSkin");
            
            // Spawn the entity into the world
            DispatchSpawn(entityIndex);
            
            // Sets parent to the entity
            SetEntDataEnt2(entityIndex, g_iOffset_EntityOwnerEntity, clientIndex, true);
            
            // Sets parent to the client
            SetVariantString("!activator");
            AcceptEntityInput(entityIndex, "SetParent", clientIndex, entityIndex);

            // Gets costume attachment
            static char sAttach[SMALL_LINE_LENGTH];
            CostumesGetAttach(gClientData[clientIndex][Client_Costume], sAttach, sizeof(sAttach)); 

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
                CostumesGetPosition(gClientData[clientIndex][Client_Costume], vEntOrigin);
                CostumesGetAngle(gClientData[clientIndex][Client_Costume], vEntAngle);
                
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
            if(CostumesIsMerge(gClientData[clientIndex][Client_Costume])) CostumesBoneMerge(entityIndex);

            // Hook entity callbacks
            if(CostumesIsHide(gClientData[clientIndex][Client_Costume])) SDKHook(entityIndex, SDKHook_SetTransmit, CostumesOnTransmit);
            
            // Store the client cache
            gClientData[clientIndex][Client_AttachmentCostume] = EntIndexToEntRef(entityIndex);
        }
    }
}

/**
 * Hook: SetTransmit
 * Called right before the entity transmitting to other entities.
 *
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public Action CostumesOnTransmit(const int entityIndex, const int clientIndex)
{
    // Validate addons
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentCostume]) == entityIndex)
    {
        // Validate observer mode
        if(GetEntData(clientIndex, g_iOffset_PlayerObserverMode))
        {
            // Allow transmitting    
            return Plugin_Continue;
        }

        // Block transmitting
        return Plugin_Handled;
    }
    
    // Get the owner of the entity
    int ownerIndex = GetEntDataEnt2(entityIndex, g_iOffset_EntityOwnerEntity);

    // Validate dead owner
    if(!IsPlayerAlive(ownerIndex))
    {
        // Block transmitting
        return Plugin_Handled;
    }
    
    // Validate observer mode
    if(GetEntData(clientIndex, g_iOffset_PlayerObserverMode) == TEAM_OBSERVER && ownerIndex == GetEntDataEnt2(clientIndex, g_iOffset_PlayerObserverTarget))
    {
        // Block transmitting
        return Plugin_Handled;
    }

    // Allow transmitting
    return Plugin_Continue;
}

/**
 * Performs bone merge on the client side.
 *
 * @param entityIndex       The entity index.
 **/
void CostumesBoneMerge(const int entityIndex)
{
    // Gets the current effects
    int iEffects = GetEntData(entityIndex, g_iOffset_EntityEffects); 

    // Set merging
    iEffects &= ~EF_NODRAW;
    iEffects |= EF_BONEMERGE;
    iEffects |= EF_BONEMERGE_FASTCULL;

    // Sets value on the entity
    SetEntData(entityIndex, g_iOffset_EntityEffects, iEffects); 
}