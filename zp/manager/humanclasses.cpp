/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          humanclasses.cpp
 *  Type:          Manager 
 *  Description:   Human classes generator.
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
 * Array handle to store human class native data.
 **/
ArrayList arrayHumanClasses;

/**
 * Human native data indexes.
 **/
enum
{
    HUMANCLASSES_DATA_NAME,
    HUMANCLASSES_DATA_INFO,
    HUMANCLASSES_DATA_MODEL,
    HUMANCLASSES_DATA_ARM,
    HUMANCLASSES_DATA_BODY,
    HUMANCLASSES_DATA_SKIN,
    HUMANCLASSES_DATA_HEALTH,
    HUMANCLASSES_DATA_SPEED,
    HUMANCLASSES_DATA_GRAVITY,
    HUMANCLASSES_DATA_ARMOR,
    HUMANCLASSES_DATA_LEVEL,
    HUMANCLASSES_DATA_GROUP,
    HUMANCLASSES_DATA_DURATION,
    HUMANCLASSES_DATA_COUNTDOWN,
    HUMANCLASSES_DATA_SOUNDDEATH,
    HUMANCLASSES_DATA_SOUNDHURT,
    HUMANCLASSES_DATA_SOUNDINFECT
}

/**
 * Prepare all humanclass data.
 **/
void HumanClassesLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_HumanClasses, Structure_Keyvalue, CONFIG_FILE_ALIAS_HUMANCLASSES);

    // Gets humanclasses config path
    static char sHumanClassPath[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_HUMANCLASSES, sHumanClassPath);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HumanClasses, "Config Validation", "Missing humanclasses config file: \"%s\"", sHumanClassPath);
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_HumanClasses, sHumanClassPath);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_HumanClasses, arrayHumanClasses);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HumanClasses, "Config Validation", "Unexpected error encountered loading: \"%s\"", sHumanClassPath);
    }

    // Validate humanclasses config
    int iSize = arrayHumanClasses.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HumanClasses, "Config Validation", "No usable data found in humanclasses config file: \"%s\"", sHumanClassPath);
    }

    // Now copy data to array structure
    HumanClassesCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_HumanClasses, true);
    ConfigSetConfigReloadFunc(File_HumanClasses, GetFunctionByName(GetMyHandle(), "HumanClassesOnConfigReload"));
    ConfigSetConfigHandle(File_HumanClasses, arrayHumanClasses);
}

/**
 * Caches humanclass data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void HumanClassesCacheData(/*void*/)
{
    // Gets config file path
    static char sPathHumans[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_HumanClasses, sPathHumans, sizeof(sPathHumans));

    // Open config
    KeyValues kvHumanClasses;
    bool bSuccess = ConfigOpenConfigFile(File_HumanClasses, kvHumanClasses);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HumanClasses, "Config Validation", "Unexpected error caching data from humanclasses config file: \"%s\"", sPathHumans);
    }

    // i = array index
    int iSize = arrayHumanClasses.Length;
    for(int i = 0; i < iSize; i++)
    {
        // General
        HumanGetName(i, sPathHumans, sizeof(sPathHumans)); // Index: 0
        kvHumanClasses.Rewind();
        if(!kvHumanClasses.JumpToKey(sPathHumans))
        {
            // Log humanclass fatal
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HumanClasses, "Config Validation", "Couldn't cache humanclass data for: \"%s\" (check humanclasses config)", sPathHumans);
            continue;
        }
        
        // Validate translation
        if(!TranslationPhraseExists(sPathHumans))
        {
            // Log humanclass error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_HumanClasses, "Config Validation", "Couldn't cache humanclass name: \"%s\" (check translation file)", sPathHumans);
        }

        // Initialize array block
        ArrayList arrayHumanClass = arrayHumanClasses.Get(i);

        // Push data into array
        kvHumanClasses.GetString("info", sPathHumans, sizeof(sPathHumans), "");
        if(!TranslationPhraseExists(sPathHumans) && hasLength(sPathHumans))
        {
            // Log humanclass error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Couldn't cache humanclass info: \"%s\" (check translation file)", sPathHumans);
        }
        arrayHumanClass.PushString(sPathHumans);                                  // Index: 1
        kvHumanClasses.GetString("model", sPathHumans, sizeof(sPathHumans), "");
        arrayHumanClass.PushString(sPathHumans);                                  // Index: 2
        ModelsPrecacheStatic(sPathHumans);
        kvHumanClasses.GetString("arm_model", sPathHumans, sizeof(sPathHumans), "");
        arrayHumanClass.PushString(sPathHumans);                                  // Index: 3
        ModelsPrecacheStatic(sPathHumans);
        arrayHumanClass.Push(kvHumanClasses.GetNum("body", -1));                  // Index: 4
        arrayHumanClass.Push(kvHumanClasses.GetNum("skin", -1));                  // Index: 5
        arrayHumanClass.Push(kvHumanClasses.GetNum("health", 0));                 // Index: 6
        arrayHumanClass.Push(kvHumanClasses.GetFloat("speed", 0.0));              // Index: 7
        arrayHumanClass.Push(kvHumanClasses.GetFloat("gravity", 0.0));            // Index: 8
        arrayHumanClass.Push(kvHumanClasses.GetNum("armor", 0));                  // Index: 9
        arrayHumanClass.Push(kvHumanClasses.GetNum("level", 0));                  // Index: 10
        kvHumanClasses.GetString("group", sPathHumans, sizeof(sPathHumans), "");
        arrayHumanClass.PushString(sPathHumans);                                  // Index: 11  
        arrayHumanClass.Push(kvHumanClasses.GetFloat("duration", 0.0));           // Index: 12
        arrayHumanClass.Push(kvHumanClasses.GetFloat("countdown", 0.0));          // Index: 13
        kvHumanClasses.GetString("death", sPathHumans, sizeof(sPathHumans), "");
        arrayHumanClass.Push(SoundsKeyToIndex(sPathHumans));                      // Index: 14
        kvHumanClasses.GetString("hurt", sPathHumans, sizeof(sPathHumans), "");
        arrayHumanClass.Push(SoundsKeyToIndex(sPathHumans));                      // Index: 15
        kvHumanClasses.GetString("infect", sPathHumans, sizeof(sPathHumans), "");
        arrayHumanClass.Push(SoundsKeyToIndex(sPathHumans));                      // Index: 16
    }

    // We're done with this file now, so we can close it
    delete kvHumanClasses;
}

/**
 * Called when configs are being reloaded.
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void HumanClassesOnConfigReload(ConfigFile iConfig)
{
    // Reload humanclass config
    HumanClassesLoad();
}

/**
 * Creates commands for human classes module.
 **/
void HumanOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zp_human_menu",  HumanCommandCatched, "Open the human classes menu.");
}

/**
 * Handles the <!zp_human_menu> command. Open the human classes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action HumanCommandCatched(const int clientIndex, const int iArguments)
{
    HumanMenu(clientIndex);
    return Plugin_Handled;
}

/*
 * Human classes natives API.
 */
 
/**
 * Sets up natives for library.
 **/
void HumanClassesAPI(/*void*/)
{
    CreateNative("ZP_GetNumberHumanClass",            API_GetNumberHumanClass);
    CreateNative("ZP_GetClientHumanClass",            API_GetClientHumanClass);
    CreateNative("ZP_GetClientHumanClassNext",        API_GetClientHumanClassNext);
    CreateNative("ZP_SetClientHumanClass",            API_SetClientHumanClass);
    CreateNative("ZP_GetHumanClassNameID",            API_GetHumanClassNameID);
    CreateNative("ZP_GetHumanClassName",              API_GetHumanClassName);
    CreateNative("ZP_GetHumanClassInfo",              API_GetHumanClassInfo);
    CreateNative("ZP_GetHumanClassModel",             API_GetHumanClassModel);
    CreateNative("ZP_GetHumanClassArm",               API_GetHumanClassArm);
    CreateNative("ZP_GetHumanClassBody",              API_GetHumanClassBody);
    CreateNative("ZP_GetHumanClassSkin",              API_GetHumanClassSkin);
    CreateNative("ZP_GetHumanClassHealth",            API_GetHumanClassHealth);
    CreateNative("ZP_GetHumanClassSpeed",             API_GetHumanClassSpeed);
    CreateNative("ZP_GetHumanClassGravity",           API_GetHumanClassGravity);
    CreateNative("ZP_GetHumanClassArmor",             API_GetHumanClassArmor);
    CreateNative("ZP_GetHumanClassLevel",             API_GetHumanClassLevel);
    CreateNative("ZP_GetHumanClassGroup",             API_GetHumanClassGroup);
    CreateNative("ZP_GetHumanClassSkillDuration",     API_GetHumanClassSkillDuration);
    CreateNative("ZP_GetHumanClassSkillCountdown",    API_GetHumanClassSkillCountdown);
    CreateNative("ZP_GetHumanClassSoundDeathID",      API_GetHumanClassSoundDeathID);
    CreateNative("ZP_GetHumanClassSoundHurtID",       API_GetHumanClassSoundHurtID);
    CreateNative("ZP_GetHumanClassSoundInfectID",     API_GetHumanClassSoundInfectID);
    CreateNative("ZP_PrintHumanClassInfo",            API_PrintHumanClassInfo);
}

/**
 * Gets the amount of all human classes.
 *
 * native int ZP_GetNumberHumanClass();
 **/
public int API_GetNumberHumanClass(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return arrayHumanClasses.Length;
}

/**
 * Gets the human class index of the client.
 *
 * native int ZP_GetClientHumanClass(clientIndex);
 **/
public int API_GetClientHumanClass(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_HumanClass];
}

/**
 * Gets the human next class index of the client.
 *
 * native int ZP_GetClientHumanClassNext(clientIndex);
 **/
public int API_GetClientHumanClassNext(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_HumanClassNext];
}

/**
 * Sets the human class index to the client.
 *
 * native void ZP_SetClientHumanClass(clientIndex, iD);
 **/
public int API_SetClientHumanClass(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Call forward
    Action resultHandle = API_OnClientValidateHumanClass(clientIndex, iD);

    // Validate handle
    if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
    {
        // Sets next class to the client
        gClientData[clientIndex][Client_HumanClassNext] = iD;
    }

    // Return on success
    return iD;
}

/**
 * Gets the index of a human class at a given name.
 *
 * native int ZP_GetHumanClassNameID(name);
 **/
public int API_GetHumanClassNameID(Handle hPlugin, const int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Can't find class with an empty name");
        return -1;
    }
    
    // Gets native data
    static char sName[SMALL_LINE_LENGTH];

    // General
    GetNativeString(1, sName, sizeof(sName));

    // i = class number
    int iCount = arrayHumanClasses.Length;
    for(int i = 0; i < iCount; i++)
    {
        // Gets the name of a human class at a given index
        static char sHumanName[SMALL_LINE_LENGTH];
        HumanGetName(i, sHumanName, sizeof(sHumanName));

        // If names match, then return index
        if(!strcmp(sName, sHumanName, false))
        {
            return i;
        }
    }

    // Return on the unsuccess
    return -1;
}

/**
 * Gets the name of a human class at a given index.
 *
 * native void ZP_GetHumanClassName(iD, name, maxlen);
 **/
public int API_GetHumanClassName(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    HumanGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the info of a human class at a given index.
 *
 * native void ZP_GetHumanClassInfo(iD, info, maxlen);
 **/
public int API_GetHumanClassInfo(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize info char
    static char sInfo[SMALL_LINE_LENGTH];
    HumanGetInfo(iD, sInfo, sizeof(sInfo));

    // Return on success
    return SetNativeString(2, sInfo, maxLen);
}

/**
 * Gets the player model of a human class at a given index.
 *
 * native void ZP_GetHumanClassModel(iD, model, maxlen);
 **/
public int API_GetHumanClassModel(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    HumanGetModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the arm model of a human class at a given index.
 *
 * native void ZP_GetHumanClassArm(iD, model, maxlen);
 **/
public int API_GetHumanClassArm(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    HumanGetArmModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the body index of the human class.
 *
 * native int ZP_GetHumanClassBody(iD, view);
 **/
public int API_GetHumanClassBody(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return the value
    return HumanGetBody(iD);
}

/**
 * Gets the skin index of the human class.
 *
 * native int ZP_GetHumanClassSkin(iD, view);
 **/
public int API_GetHumanClassSkin(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return the value
    return HumanGetSkin(iD);
}

/**
 * Gets the health of the human class.
 *
 * native int ZP_GetHumanClassHealth(iD);
 **/
public int API_GetHumanClassHealth(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return HumanGetHealth(iD);
}

/**
 * Gets the speed of the human class.
 *
 * native float ZP_GetHumanClassSpeed(iD);
 **/
public int API_GetHumanClassSpeed(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(HumanGetSpeed(iD));
}

/**
 * Gets the gravity of the human class.
 *
 * native float ZP_GetHumanClassGravity(iD);
 **/
public int API_GetHumanClassGravity(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return the value (Float fix)
    return view_as<int>(HumanGetGravity(iD));
}

/**
 * Gets the armor of the human class.
 *
 * native int ZP_GetHumanClassArmor(iD);
 **/
public int API_GetHumanClassArmor(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return HumanGetArmor(iD);
}

/**
 * Gets the level of the human class.
 *
 * native int ZP_GetHumanClassLevel(iD);
 **/
public int API_GetHumanClassLevel(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return HumanGetLevel(iD);
}

/**
 * Gets the group of a human class at a given index.
 *
 * native void ZP_GetHumanClassGroup(iD, group, maxlen);
 **/
public int API_GetHumanClassGroup(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize group char
    static char sGroup[PLATFORM_MAX_PATH];
    HumanGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * Gets the skill duration of the human class.
 *
 * native float ZP_GetHumanClassSkillDuration(iD);
 **/
public int API_GetHumanClassSkillDuration(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(HumanGetSkillDuration(iD));
}

/**
 * Gets the skill countdown of the human class.
 *
 * native float ZP_GetHumanClassSkillCountdown(iD);
 **/
public int API_GetHumanClassSkillCountdown(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(HumanGetSkillCountDown(iD));
}

/**
 * Gets the death sound key of the human class.
 *
 * native int ZP_GetHumanClassSoundDeathID(iD);
 **/
public int API_GetHumanClassSoundDeathID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return HumanGetSoundDeathID(iD);
}

/**
 * Gets the hurt sound key of the human class.
 *
 * native int ZP_GetHumanClassSoundHurtID(iD);
 **/
public int API_GetHumanClassSoundHurtID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return HumanGetSoundHurtID(iD);
}

/**
 * Gets the infect sound key of the human class.
 *
 * native int ZP_GetHumanClassSoundInfectID(iD);
 **/
public int API_GetHumanClassSoundInfectID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
   
    // Return value
    return HumanGetSoundInfectID(iD);
}

/**
 * Print the info about the human class.
 *
 * native void ZP_PrintHumanClassInfo(clientIndex, iD);
 **/
public int API_PrintHumanClassInfo(Handle hPlugin, const int iNumParams)
{
    // If help messages disable, then stop 
    if(!gCvarList[CVAR_MESSAGES_HELP].BoolValue)
    {
        return -1;
    }
    
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Player doens't exist (%d)", clientIndex);
        return -1;
    }
    
    // Gets class index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= arrayHumanClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HumanClasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Gets human name
    static char sHumanName[SMALL_LINE_LENGTH];
    HumanGetName(iD, sHumanName, sizeof(sHumanName));

    // If help messages enabled, show info
    TranslationPrintToChat(clientIndex, "human info", sHumanName, HumanGetHealth(iD), HumanGetSpeed(iD), HumanGetGravity(iD));
    
    // Return on success
    return sizeof(sHumanName);
}

/*
 * Human classes data reading API.
 */

/**
 * Gets the name of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class name
    arrayHumanClass.GetString(HUMANCLASSES_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the info of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sInfo             The string to return info in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetInfo(const int iD, char[] sInfo, const int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class info
    arrayHumanClass.GetString(HUMANCLASSES_DATA_INFO, sInfo, iMaxLen);
}

/**
 * Gets the player model of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class model
    arrayHumanClass.GetString(HUMANCLASSES_DATA_MODEL, sModel, iMaxLen);
}

/**
 * Gets the knife model of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetArmModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class arm model
    arrayHumanClass.GetString(HUMANCLASSES_DATA_ARM, sModel, iMaxLen);
}

/**
 * Gets the body index of the human class.
 *
 * @param iD                The class index.
 * @return                  The body index.   
 **/
stock int HumanGetBody(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human skin index
    return arrayHumanClass.Get(HUMANCLASSES_DATA_BODY);
}

/**
 * Gets the skin index of the human class.
 *
 * @param iD                The class index.
 * @return                  The skin index.   
 **/
stock int HumanGetSkin(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human skin index
    return arrayHumanClass.Get(HUMANCLASSES_DATA_SKIN);
}

/**
 * Gets the health of the human class.
 *
 * @param iD                The class index.
 * @return                  The health amount.    
 **/
stock int HumanGetHealth(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class health
    return arrayHumanClass.Get(HUMANCLASSES_DATA_HEALTH);
}

/**
 * Gets the speed of the human class.
 *
 * @param iD                The class index.
 * @return                  The speed amount.    
 **/
stock float HumanGetSpeed(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class speed
    return arrayHumanClass.Get(HUMANCLASSES_DATA_SPEED);
}

/**
 * Gets the gravity of the human class.
 *
 * @param iD                The class index.
 * @return                  The gravity amount.    
 **/
stock float HumanGetGravity(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class gravity
    return arrayHumanClass.Get(HUMANCLASSES_DATA_GRAVITY);
}

/**
 * Gets the armor of the human class.
 *
 * @param iD                The class index.
 * @return                  The armor amount.    
 **/
stock int HumanGetArmor(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class armor
    return arrayHumanClass.Get(HUMANCLASSES_DATA_ARMOR);
}

/**
 * Gets the level of the human class.
 *
 * @param iD                The class index.
 * @return                  The level amount.    
 **/
stock int HumanGetLevel(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class level
    return arrayHumanClass.Get(HUMANCLASSES_DATA_LEVEL);
}

/**
 * Gets the access group of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetGroup(const int iD, char[] sGroup, const int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class group
    arrayHumanClass.GetString(HUMANCLASSES_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * Gets the skill duration of the human class.
 *
 * @param iD                The class index.
 * @return                  The duration amount.    
 **/
stock float HumanGetSkillDuration(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class skill duration 
    return arrayHumanClass.Get(HUMANCLASSES_DATA_DURATION);
}

/**
 * Gets the skill countdown of the human class.
 *
 * @param iD                The class index.
 * @return                  The countdown amount.    
 **/
stock float HumanGetSkillCountDown(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class skill countdown  
    return arrayHumanClass.Get(HUMANCLASSES_DATA_COUNTDOWN);
}

/**
 * Gets the death sound key of the human class. 
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int HumanGetSoundDeathID(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class death sound key
    return arrayHumanClass.Get(HUMANCLASSES_DATA_SOUNDDEATH);
}

/**
 * Gets the hurt sound key of the human class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int HumanGetSoundHurtID(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class hurt sound key
    return arrayHumanClass.Get(HUMANCLASSES_DATA_SOUNDHURT);
}

/**
 * Gets the infect sound key of the human class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int HumanGetSoundInfectID(const int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class infect sound key
    return arrayHumanClass.Get(HUMANCLASSES_DATA_SOUNDINFECT);
}

/*
 * Stocks human classes API.
 */

/**
 * Validate human class for client availability.
 *
 * @param clientIndex       The client index.
 **/
void HumanOnValidate(const int clientIndex)
{
    // Gets array size
    int iSize = arrayHumanClasses.Length;

    // Choose random human class for the client
    if(IsFakeClient(clientIndex) || iSize <= gClientData[clientIndex][Client_HumanClass])
    {
        gClientData[clientIndex][Client_HumanClass] = GetRandomInt(0, iSize-1);
    }

    // Gets class group
    static char sGroup[SMALL_LINE_LENGTH];
    HumanGetGroup(gClientData[clientIndex][Client_HumanClass], sGroup, sizeof(sGroup));

    // Validate that user does not have VIP flag to play it
    if(!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup))
    {
        // Choose any accessable human class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable human classes
            HumanGetGroup(i, sGroup, sizeof(sGroup));
            if(!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup))
            {
                continue;
            }
            
            // Update human class
            gClientData[clientIndex][Client_HumanClassNext] = i;
            gClientData[clientIndex][Client_HumanClass] = i;
            break;
        }
    }
    
    // Validate that user does not have level to play it
    if(HumanGetLevel(gClientData[clientIndex][Client_HumanClass]) > gClientData[clientIndex][Client_Level])
    {
        // Choose any accessable human class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable human classes
            if(HumanGetLevel(i) > gClientData[clientIndex][Client_Level])
            {
                continue;
            }
            
            // Update human class
            gClientData[clientIndex][Client_HumanClassNext] = i;
            gClientData[clientIndex][Client_HumanClass] = i;
            break;
        }
    }
}

/**
 * Create the human class menu.
 *
 * @param clientIndex       The client index.
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/
void HumanMenu(const int clientIndex, const bool bInstant = false) 
{
    #define MENU_TIME_INSTANT 10 /*< Menu time of the instant change >*/
    
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
    Menu hMenu = CreateMenu(bInstant ? HumanMenuSlots2 : HumanMenuSlots1);

    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "choose humanclass");
    
    // Initialize forward
    static Action resultHandle;
    
    // i = Human class number
    int iCount = arrayHumanClasses.Length;
    for(int i = 0; i < iCount; i++)
    {
        // Call forward
        resultHandle = API_OnClientValidateHumanClass(clientIndex, i);
        
        // Skip, if class is disabled
        if(resultHandle == Plugin_Stop)
        {
            continue;
        }
        
        // Gets human class data
        HumanGetName(i, sName, sizeof(sName));
        HumanGetGroup(i, sGroup, sizeof(sGroup));
        
        // Format some chars for showing in menu
        Format(sLevel, sizeof(sLevel), "%t", "level", HumanGetLevel(i));
        Format(sBuffer, sizeof(sBuffer), "%t\t%s", sName, (!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup)) ? sGroup : (gClientData[clientIndex][Client_Level] < HumanGetLevel(i)) ? sLevel : "");

        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(resultHandle == Plugin_Handled || ((!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup)) || gClientData[clientIndex][Client_Level] < HumanGetLevel(i) || gClientData[clientIndex][Client_HumanClassNext] == i) ? false : true));
    }

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, bInstant ? MENU_TIME_INSTANT : MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int HumanMenuSlots1(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   HumanMenuSlots(hMenu, mAction, clientIndex, mSlot);
}

/**
 * Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int HumanMenuSlots2(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   HumanMenuSlots(hMenu, mAction, clientIndex, mSlot, true);
}

/**
 * Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/ 
void HumanMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot, const bool bInstant = false)
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

            // Gets ID of human class
            hMenu.GetItem(mSlot, sInfo, sizeof(sInfo));
            int iD = StringToInt(sInfo);
            
            // Call forward
            Action resultHandle = API_OnClientValidateHumanClass(clientIndex, iD);

            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Validate instant change
                if(bInstant)
                {
                    // Validate human
                    if(gClientData[clientIndex][Client_Zombie] || gClientData[clientIndex][Client_Survivor])
                    {
                        return;
                    }
                    
                    // Force client to switch player class
                    ClassMakeHuman(clientIndex, _, true);
                }
                else
                {
                    // Sets next human class
                    gClientData[clientIndex][Client_HumanClassNext] = iD;
                }
                
                // Gets human name
                HumanGetName(iD, sInfo, sizeof(sInfo));
                
                // If help messages enabled, show info
                if(gCvarList[CVAR_MESSAGES_HELP].BoolValue) TranslationPrintToChat(clientIndex, "human info", sInfo, HumanGetHealth(iD), HumanGetSpeed(iD), HumanGetGravity(iD));
            }
        }
    }
}
