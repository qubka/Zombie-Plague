/**
 * ============================================================================
 *
 *   Plague
 *
 *  File:          clases.cpp
 *  Type:          Manager 
 *  Description:   API for loading classes specific variables.
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
 * Number of max valid weapons.
 **/
#define CLASSES_WEAPON_MAX 16
 
/**
 * Array handle to store class native data.
 **/
ArrayList arrayClasses;

/**
 * @section  native data indexes.
 **/
enum
{
    CLASSES_DATA_NAME,
    CLASSES_DATA_INFO,
    CLASSES_DATA_TYPE,
    CLASSES_DATA_ZOMBIE,
    CLASSES_DATA_MODEL,
    CLASSES_DATA_CLAW,
    CLASSES_DATA_CLAW_,
    CLASSES_DATA_GRENADE,
    CLASSES_DATA_GRENADE_,
    CLASSES_DATA_ARM,
    CLASSES_DATA_BODY,
    CLASSES_DATA_SKIN,
    CLASSES_DATA_HEALTH,
    CLASSES_DATA_SPEED,
    CLASSES_DATA_GRAVITY,
    CLASSES_DATA_KNOCKBACK,
    CLASSES_DATA_ARMOR,
    CLASSES_DATA_LEVEL,
    CLASSES_DATA_GROUP,
    CLASSES_DATA_SKILLDURATION,
    CLASSES_DATA_SKILLCOUNTDOWN,
    CLASSES_DATA_REGENHEALTH,
    CLASSES_DATA_REGENINTERVAL,
    CLASSES_DATA_FOV,
    CLASSES_DATA_NOFALL,
    CLASSES_DATA_CROSSHAIR,
    CLASSES_DATA_NVGS,
    CLASSES_DATA_OVERLAY,
    CLASSES_DATA_WEAPON,
    CLASSES_DATA_MONEY,
    CLASSES_DATA_EXP,
    CLASSES_DATA_LIFESTEAL,
    CLASSES_DATA_AMMUNITION,
    CLASSES_DATA_LEAPJUMP,
    CLASSES_DATA_LEAPFORCE,
    CLASSES_DATA_LEAPCOUNTDOWN,
    CLASSES_DATA_EFFECTNAME,
    CLASSES_DATA_EFFECTATTACH,
    CLASSES_DATA_EFFECTTIME,
    CLASSES_DATA_SOUNDDEATH,
    CLASSES_DATA_SOUNDHURT,
    CLASSES_DATA_SOUNDIDLE,
    CLASSES_DATA_SOUNDINFECT,
    CLASSES_DATA_SOUNDRESPAWN,
    CLASSES_DATA_SOUNDBURN,
    CLASSES_DATA_SOUNDATTACK,
    CLASSES_DATA_SOUNDFOOTSTEP,
    CLASSES_DATA_SOUNDREGEN
}
/**
 * @endsection
 **/
 
 /*
 * Load other classes modules
 */
#include "zp/manager/playerclasses/apply.cpp"
#include "zp/manager/playerclasses/classmenus.cpp"
#include "zp/manager/playerclasses/classcomands.cpp"

/**
 * Prepare all class data.
 **/
void ClassesLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Classes, Structure_Keyvalue, CONFIG_FILE_ALIAS_CLASSES);

    // Gets classes config path
    static char sPathClasses[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_CLASSES, sPathClasses);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Missing classes config file: \"%s\"", sPathClasses);
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_Classes, sPathClasses);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Classes, arrayClasses);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathClasses);
    }

    // Validate classes config
    int iSize = arrayClasses.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "No usable data found in classes config file: \"%s\"", sPathClasses);
    }

    // Now copy data to array structure
    ClassesCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Classes, true);
    ConfigSetConfigReloadFunc(File_Classes, GetFunctionByName(GetMyHandle(), "ClassesOnConfigReload"));
    ConfigSetConfigHandle(File_Classes, arrayClasses);
}

/**
 * Caches class data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void ClassesCacheData(/*void*/)
{
    // Gets config file path
    static char sPathClasses[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Classes, sPathClasses, sizeof(sPathClasses));

    // Open config
    KeyValues kvClasses;
    bool bSuccess = ConfigOpenConfigFile(File_Classes, kvClasses);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Unexpected error caching data from classes config file: \"%s\"", sPathClasses);
    }

    // i = array index
    int iSize = arrayClasses.Length;
    for(int i = 0; i < iSize; i++)
    {
        // General
        ClassGetName(i, sPathClasses, sizeof(sPathClasses)); // Index: 0
        kvClasses.Rewind();
        if(!kvClasses.JumpToKey(sPathClasses))
        {
            // Log class fatal
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class data for: \"%s\" (check classes config)", sPathClasses);
            continue;
        }
        
        // Validate translation
        if(!TranslationPhraseExists(sPathClasses))
        {
            // Log class error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class name: \"%s\" (check translation file)", sPathClasses);
        }

        // Initialize array block
        ArrayList arrayClass = arrayClasses.Get(i);

        // Push data into array
        kvClasses.GetString("info", sPathClasses, sizeof(sPathClasses), "");
        if(!TranslationPhraseExists(sPathClasses) && hasLength(sPathClasses))
        {
            // Log class error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Couldn't cache class info: \"%s\" (check translation file)", sPathClasses);
        }
        arrayClass.PushString(sPathClasses);                                    // Index: 1
        kvClasses.GetString("type", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 2
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "zombie", "no"));      // Index: 3
        kvClasses.GetString("model", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 4
        ModelsPrecacheStatic(sPathClasses);
        kvClasses.GetString("claw_model", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 5
        arrayClass.Push(ModelsPrecacheWeapon(sPathClasses));                    // Index: 7
        kvClasses.GetString("gren_model", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 7
        kvClasses.GetString("arm_model", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 8
        arrayClass.Push(ModelsPrecacheWeapon(sPathClasses));                    // Index: 9
        arrayClass.Push(kvClasses.GetNum("body", -1));                          // Index: 10 
        arrayClass.Push(kvClasses.GetNum("skin", -1));                          // Index: 11 
        arrayClass.Push(kvClasses.GetNum("health", 0));                         // Index: 12 
        arrayClass.Push(kvClasses.GetFloat("speed", 0.0));                      // Index: 13
        arrayClass.Push(kvClasses.GetFloat("gravity", 0.0));                    // Index: 14
        arrayClass.Push(kvClasses.GetFloat("knockback", 0.0));                  // Index: 15
        arrayClass.Push(kvClasses.GetNum("armor", 0));                          // Index: 16
        arrayClass.Push(kvClasses.GetNum("level", 0));                          // Index: 18
        kvClasses.GetString("group", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 18
        arrayClass.Push(kvClasses.GetFloat("duration", 0.0));                   // Index: 19
        arrayClass.Push(kvClasses.GetFloat("countdown", 0.0));                  // Index: 20
        arrayClass.Push(kvClasses.GetNum("regenerate", 0));                     // Index: 21
        arrayClass.Push(kvClasses.GetFloat("interval", 0.0));                   // Index: 22
        arrayClass.Push(kvClasses.GetNum("fov", 90));                           // Index: 23
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "no_fall", "off"));    // Index: 24
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "crosshair", "yes"));  // Index: 25
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "nvgs", "no"));        // Index: 26
        kvClasses.GetString("overlay", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 27
        kvClasses.GetString("weapon", sPathClasses, sizeof(sPathClasses), "");
        static char sWeapon[CLASSES_WEAPON_MAX][SMALL_LINE_LENGTH]; int iWeapon[CLASSES_WEAPON_MAX] = { -1, ... };
        int nWeapons = ExplodeString(sPathClasses, ",", sWeapon, sizeof(sWeapon), sizeof(sWeapon[]));
        for(int x = 0; x < nWeapons; x++)
        {
            iWeapon[x] = WeaponsNameToIndex(sWeapon[x]);
        } 
        arrayClass.PushArray(iWeapon, sizeof(iWeapon));                         // Index: 28
        kvClasses.GetString("money", sPathClasses, sizeof(sPathClasses), "");
        static char sMoney[3][SMALL_LINE_LENGTH]; int iMoney[3];
        int nMoney = ExplodeString(sPathClasses, " ", sMoney, sizeof(sMoney), sizeof(sMoney[]));
        for(int x = 0; x < nMoney; x++)
        {
            iMoney[x] = StringToInt(sMoney[x]);
        }
        arrayClass.PushArray(iMoney, sizeof(iMoney));                           // Index: 29
        kvClasses.GetString("experience", sPathClasses, sizeof(sPathClasses), "");
        static char sExp[3][SMALL_LINE_LENGTH]; int iExp[3];
        int nExp = ExplodeString(sPathClasses, " ", sExp, sizeof(sExp), sizeof(sExp[]));
        for(int x = 0; x < nExp; x++)
        {
            iExp[x] = StringToInt(sExp[x]);
        }
        arrayClass.PushArray(iExp, sizeof(iExp));                               // Index: 30
        arrayClass.Push(kvClasses.GetNum("lifesteal", 0));                      // Index: 31
        arrayClass.Push(kvClasses.GetNum("ammunition", 0));                     // Index: 32
        arrayClass.Push(kvClasses.GetNum("leap", 0));                           // Index: 33
        arrayClass.Push(kvClasses.GetFloat("force", 0.0));                      // Index: 34
        arrayClass.Push(kvClasses.GetFloat("cooldown", 0.0));                   // Index: 35
        kvClasses.GetString("effect", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 36
        kvClasses.GetString("attachment", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 37
        arrayClass.Push(kvClasses.GetFloat("time", 1.0));                       // Index: 38
        kvClasses.GetString("death", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 39
        kvClasses.GetString("hurt", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 40
        kvClasses.GetString("idle", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 41
        kvClasses.GetString("infect", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 42
        kvClasses.GetString("respawn", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 43
        kvClasses.GetString("burn", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 44
        kvClasses.GetString("attack", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 45
        kvClasses.GetString("footstep", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 46
        kvClasses.GetString("regen", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 47
    }

    // We're done with this file now, so we can close it
    delete kvClasses;
}

/**
 * Called when configs are being reloaded.
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void ClassesOnConfigReload(ConfigFile iConfig)
{
    // Reload class config
    ClassesLoad();
}

/**
 * Creates commands for classes module.
 **/
void ClassesOnCommandsCreate(/*void*/)
{
    // Forward event to sub-modules
    ClassMenusOnCommandsCreate();
    ClassComandsOnCommandsCreate();
}

/**
 * Hook classes cvar changes.
 **/
void ClassesOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_GAME_CUSTOM_HUMAN_MENU]  = FindConVar("zp_game_custom_human_menu");
    gCvarList[CVAR_GAME_CUSTOM_ZOMBIE_MENU] = FindConVar("zp_game_custom_zombie_menu");
}

/*
 * Classes natives API.
 */

/**
 * Sets up natives for library.
 **/
void ClassesAPI(/*void*/)
{
    CreateNative("ZP_GetNumberClass",           API_GetNumberClass);
    CreateNative("ZP_GetClientClass",           API_GetClientClass);
    CreateNative("ZP_GetClientHumanClassNext",  API_GetClientHumanClassNext);
    CreateNative("ZP_GetClientZombieClassNext", API_GetClientZombieClassNext);
    CreateNative("ZP_SetClientHumanClassNext",  API_SetClientHumanClassNext);
    CreateNative("ZP_SetClientZombieClassNext", API_SetClientZombieClassNext);
    CreateNative("ZP_GetClassNameID",           API_GetClassNameID);
    CreateNative("ZP_GetClassName",             API_GetClassName);
    CreateNative("ZP_GetClassInfo",             API_GetClassInfo);
    CreateNative("ZP_GetClassType",             API_GetClassType);
    CreateNative("ZP_IsClassZombie",            API_IsClassZombie);
    CreateNative("ZP_GetClassModel",            API_GetClassModel);
    CreateNative("ZP_GetClassClaw",             API_GetClassClaw);
    CreateNative("ZP_GetClassGrenade",          API_GetClassGrenade);
    CreateNative("ZP_GetClassArm",              API_GetClassArm);
    CreateNative("ZP_GetClassBody",             API_GetClassBody);
    CreateNative("ZP_GetClassSkin",             API_GetClassSkin);
    CreateNative("ZP_GetClassHealth",           API_GetClassHealth);
    CreateNative("ZP_GetClassSpeed",            API_GetClassSpeed);
    CreateNative("ZP_GetClassGravity",          API_GetClassGravity);
    CreateNative("ZP_GetClassKnockBack",        API_GetClassKnockBack);
    CreateNative("ZP_GetClassArmor",            API_GetClassArmor);
    CreateNative("ZP_GetClassLevel",            API_GetClassLevel);    
    CreateNative("ZP_GetClassGroup",            API_GetClassGroup);
    CreateNative("ZP_GetClassSkillDuration",    API_GetClassSkillDuration);
    CreateNative("ZP_GetClassSkillCountdown",   API_GetClassSkillCountdown);
    CreateNative("ZP_GetClassRegenHealth",      API_GetClassRegenHealth);
    CreateNative("ZP_GetClassRegenInterval",    API_GetClassRegenInterval);
    CreateNative("ZP_GetClassFov",              API_GetClassFov);
    CreateNative("ZP_IsClassNoFall",            API_IsClassNoFall);
    CreateNative("ZP_IsClassCross",             API_IsClassCross);
    CreateNative("ZP_IsClassNvgs",              API_IsClassNvgs); 
    CreateNative("ZP_GetClassOverlay",          API_GetClassOverlay);
    CreateNative("ZP_GetClassWeapon",           API_GetClassWeapon); 
    CreateNative("ZP_GetClassMoney",            API_GetClassMoney);
    CreateNative("ZP_GetClassExperience",       API_GetClassExperience);
    CreateNative("ZP_GetClassLifeSteal",        API_GetClassLifeSteal);
    CreateNative("ZP_GetClassAmmunition",       API_GetClassAmmunition);
    CreateNative("ZP_GetClassLeapJump",         API_GetClassLeapJump);
    CreateNative("ZP_GetClassLeapForce",        API_GetClassLeapForce);
    CreateNative("ZP_GetClassLeapCountdown",    API_GetClassLeapCountdown);
    CreateNative("ZP_GetClassEffectName",       API_GetClassEffectName);
    CreateNative("ZP_GetClassEffectAttach",     API_GetClassEffectAttach);
    CreateNative("ZP_GetClassEffectTime",       API_GetClassEffectTime);
    CreateNative("ZP_GetClassClawID",           API_GetClassClawID);
    CreateNative("ZP_GetClassGrenadeID",        API_GetClassGrenadeID);
    CreateNative("ZP_GetClassSoundDeathID",     API_GetClassSoundDeathID);
    CreateNative("ZP_GetClassSoundHurtID",      API_GetClassSoundHurtID);
    CreateNative("ZP_GetClassSoundIdleID",      API_GetClassSoundIdleID);
    CreateNative("ZP_GetClassSoundInfectID",    API_GetClassSoundInfectID);
    CreateNative("ZP_GetClassSoundRespawnID",   API_GetClassSoundRespawnID);
    CreateNative("ZP_GetClassSoundBurnID",      API_GetClassSoundBurnID);
    CreateNative("ZP_GetClassSoundAttackID",    API_GetClassSoundAttackID);
    CreateNative("ZP_GetClassSoundFootID",      API_GetClassSoundFootID);
    CreateNative("ZP_GetClassSoundRegenID",     API_GetClassSoundRegenID);
    CreateNative("ZP_PrintClassInfo",           API_PrintClassInfo);
}
 
/**
 * Gets the amount of all classes.
 *
 * native int ZP_GetNumberClass();
 **/
public int API_GetNumberClass(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return arrayClasses.Length;
}

/**
 * Gets the current class index of the client.
 *
 * native int ZP_GetClientClass(clientIndex);
 **/
public int API_GetClientClass(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_Class];
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
 * Gets the zombie next class index of the client.
 *
 * native int ZP_GetClientZombieClassNext(clientIndex);
 **/
public int API_GetClientZombieClassNext(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_ZombieClassNext];
}

/**
 * Sets the human next class index to the client.
 *
 * native void ZP_SetClientHumanClassNext(clientIndex, iD);
 **/
public int API_SetClientHumanClassNext(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Call forward
    Action resultHandle = API_OnClientValidateHumanClass(clientIndex, iD);

    // Validate handle
    if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
    {
        // Sets next human class to the client
        gClientData[clientIndex][Client_HumanClassNext] = iD;
    }

    // Return on success
    return iD;
}

/**
 * Sets the zombie next class index to the client.
 *
 * native void ZP_SetClientZombieClassNext(clientIndex, iD);
 **/
public int API_SetClientZombieClassNext(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Call forward
    Action resultHandle = API_OnClientValidateZombieClass(clientIndex, iD);

    // Validate handle
    if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
    {
        // Sets next zombie class to the client
        gClientData[clientIndex][Client_ZombieClassNext] = iD;
    }

    // Return on success
    return iD;
}

/**
 * Gets the index of a class at a given name.
 *
 * native int ZP_GetClassNameID(name);
 **/
public int API_GetClassNameID(Handle hPlugin, const int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Can't find class with an empty name");
        return -1;
    }
    
    // Gets native data
    static char sName[SMALL_LINE_LENGTH];

    // General
    GetNativeString(1, sName, sizeof(sName));
    
    // Return the value
    return ClassNameToIndex(sName); 
}

/**
 * Gets the name of a class at a given index.
 *
 * native void ZP_GetClassName(iD, name, maxlen);
 **/
public int API_GetClassName(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    ClassGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the info of a class at a given index.
 *
 * native void ZP_GetClassInfo(iD, info, maxlen);
 **/
public int API_GetClassInfo(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize info char
    static char sInfo[BIG_LINE_LENGTH];
    ClassGetInfo(iD, sInfo, sizeof(sInfo));

    // Return on success
    return SetNativeString(2, sInfo, maxLen);
}

/**
 * Gets the type of a class at a given index.
 *
 * native void ZP_GetClassType(iD, type, maxlen);
 **/
public int API_GetClassType(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize type char
    static char sType[SMALL_LINE_LENGTH];
    ClassGetType(iD, sType, sizeof(sType));

    // Return on success
    return SetNativeString(2, sType, maxLen);
}

/**
 * Checks the zombie type of the class.
 *
 * native bool ZP_IsClassZombie(iD);
 **/
public int API_IsClassZombie(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsZombie(iD);
}

/**
 * Gets the player model of a class at a given index.
 *
 * native void ZP_GetClassModel(iD, model, maxlen);
 **/
public int API_GetClassModel(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    ClassGetModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the knife model of a class at a given index.
 *
 * native void ZP_GetClassClaw(iD, model, maxlen);
 **/
public int API_GetClassClaw(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    ClassGetClawModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the grenade model of a class at a given index.
 *
 * native void ZP_GetClassGrenade(iD, model, maxlen);
 **/
public int API_GetClassGrenade(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    ClassGetGrenadeModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the arm model of a class at a given index.
 *
 * native void ZP_GetClassArm(iD, model, maxlen);
 **/
public int API_GetClassArm(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    ClassGetArmModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the body of the class.
 *
 * native int ZP_GetClassBody(iD);
 **/
public int API_GetClassBody(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetBody(iD);
}

/**
 * Gets the skin of the class.
 *
 * native int ZP_GetClassSkin(iD);
 **/
public int API_GetClassSkin(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetSkin(iD);
}

/**
 * Gets the health of the class.
 *
 * native int ZP_GetClassHealth(iD);
 **/
public int API_GetClassHealth(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetHealth(iD);
}

/**
 * Gets the speed of the class.
 *
 * native float ZP_GetClassSpeed(iD);
 **/
public int API_GetClassSpeed(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ClassGetSpeed(iD));
}

/**
 * Gets the gravity of the class.
 *
 * native float ZP_GetClassGravity(iD);
 **/
public int API_GetClassGravity(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ClassGetGravity(iD));
}

/**
 * Gets the knockback of the class.
 *
 * native float ZP_GetClassKnockBack(iD);
 **/
public int API_GetClassKnockBack(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ClassGetKnockBack(iD));
}

/**
 * Gets the armor of the class.
 *
 * native int ZP_GetClassArmor(iD);
 **/
public int API_GetClassArmor(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetArmor(iD);
}

/**
 * Gets the level of the class.
 *
 * native int ZP_GetClassLevel(iD);
 **/
public int API_GetClassLevel(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetLevel(iD);
}

/**
 * Gets the group of a class at a given index.
 *
 * native void ZP_GetClassGroup(iD, group, maxlen);
 **/
public int API_GetClassGroup(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    ClassGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * Gets the skill duration of the class.
 *
 * native float ZP_GetClassSkillDuration(iD);
 **/
public int API_GetClassSkillDuration(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetSkillDuration(iD));
}

/**
 * Gets the skill countdown of the class.
 *
 * native float ZP_GetClassSkillCountdown(iD);
 **/
public int API_GetClassSkillCountdown(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetSkillCountDown(iD));
}

/**
 * Gets the regen health of the class.
 *
 * native int ZP_GetClassRegenHealth(iD);
 **/
public int API_GetClassRegenHealth(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetRegenHealth(iD);
}

/**
 * Gets the regen interval of the class.
 *
 * native float ZP_GetClassRegenInterval(iD);
 **/
public int API_GetClassRegenInterval(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ClassGetRegenInterval(iD));
}

/**
 * Gets the fov of the class.
 *
 * native int ZP_GetClassFov(iD);
 **/
public int API_GetClassFov(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetFov(iD);
}

/**
 * Checks the no fall of the class.
 *
 * native bool ZP_IsClassNoFall(iD);
 **/
public int API_IsClassNoFall(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsNoFall(iD);
}

/**
 * Checks the crosshair of the class.
 *
 * native bool ZP_IsClassCross(iD);
 **/
public int API_IsClassCross(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsCross(iD);
}

/**
 * Checks the nightvision of the class.
 *
 * native bool ZP_IsClassNvgs(iD);
 **/
public int API_IsClassNvgs(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsNvgs(iD);
}

/**
 * Gets the overlay of a class at a given index.
 *
 * native void ZP_GetClassOverlay(iD, overlay, maxlen);
 **/
public int API_GetClassOverlay(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize overlay char
    static char sOverlay[PLATFORM_MAX_PATH];
    ClassGetOverlay(iD, sOverlay, sizeof(sOverlay));

    // Return on success
    return SetNativeString(2, sOverlay, maxLen);
}

/**
 * Gets the weapon of a class at a given index.
 *
 * native void ZP_GetClassWeapon(iD, weapon, maxlen);
 **/
public int API_GetClassWeapon(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize weapon array
    static int iWeapon[CLASSES_WEAPON_MAX];
    ClassGetWeapon(iD, iWeapon, sizeof(iWeapon));

    // Return on success
    return SetNativeArray(2, iWeapon, maxLen);
}

/**
 * Gets the money of a class at a given index.
 *
 * native void ZP_GetClassMoney(iD, money, maxlen);
 **/
public int API_GetClassMoney(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize money array
    static int iMoney[3];
    ClassGetMoney(iD, iMoney, sizeof(iMoney));

    // Return on success
    return SetNativeArray(2, iMoney, maxLen);
}

/**
 * Gets the experience of a class at a given index.
 *
 * native void ZP_GetClassExperience(iD, experience, maxlen);
 **/
public int API_GetClassExperience(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize experience array
    static int iExp[3];
    ClassGetExp(iD, iExp, sizeof(iExp));

    // Return on success
    return SetNativeArray(2, iExp, maxLen);
}

/**
 * Gets the lifesteal of the class.
 *
 * native int ZP_GetClassLifeSteal(iD);
 **/
public int API_GetClassLifeSteal(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetLifeSteal(iD);
}

/**
 * Gets the ammunition of the class.
 *
 * native int ZP_GetClassLifeAmmunition(iD);
 **/
public int API_GetClassAmmunition(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetAmmunition(iD);
}

/**
 * Gets the leap jump of the class.
 *
 * native int ZP_GetClassLeapJump(iD);
 **/
public int API_GetClassLeapJump(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetLeapJump(iD);
}

/**
 * Gets the leap force of the class.
 *
 * native float ZP_GetClassLeapForce(iD);
 **/
public int API_GetClassLeapForce(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetLeapForce(iD));
}

/**
 * Gets the leap countdown of the class.
 *
 * native float ZP_GetClassLeapCountdown(iD);
 **/
public int API_GetClassLeapCountdown(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetLeapCountdown(iD));
}

/**
 * Gets the effect name of a class at a given index.
 *
 * native void ZP_GetClassEffectName(iD, name, maxlen);
 **/
public int API_GetClassEffectName(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    ClassGetEffectName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the effect attachment of a class at a given index.
 *
 * native void ZP_GetClassEffectAttach(iD, attach, maxlen);
 **/
public int API_GetClassEffectAttach(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize attachment char
    static char sAttach[SMALL_LINE_LENGTH];
    ClassGetEffectAttach(iD, sAttach, sizeof(sAttach));

    // Return on success
    return SetNativeString(2, sAttach, maxLen);
}

/**
 * Gets the effect time of the class.
 *
 * native float ZP_GetClassEffectTime(iD);
 **/
public int API_GetClassEffectTime(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetEffectTime(iD));
}

/**
 * Gets the index of the class.
 *
 * native int ZP_GetClassClawID(iD);
 **/
public int API_GetClassClawID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetClawID(iD);
}

/**
 * Gets the index of the class grenade model.
 *
 * native int ZP_GetClassGrenadeID(iD);
 **/
public int API_GetClassGrenadeID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetGrenadeID(iD);
}

/**
 * Gets the death sound key of the class.
 *
 * native void ZP_GetClassSoundDeathID(iD);
 **/
public int API_GetClassSoundDeathID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundDeathID(iD);
}

/**
 * Gets the hurt sound key of the class.
 *
 * native void ZP_GetClassSoundHurtID(iD);
 **/
public int API_GetClassSoundHurtID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundHurtID(iD);
}

/**
 * Gets the idle sound key of the class.
 *
 * native void ZP_GetClassSoundIdleID(iD);
 **/
public int API_GetClassSoundIdleID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundIdleID(iD);
}

/**
 * Gets the infect sound key of the class.
 *
 * native void ZP_GetClassSoundInfectID(iD);
 **/
public int API_GetClassSoundInfectID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundInfectID(iD);
}

/**
 * Gets the respawn sound key of the class.
 *
 * native void ZP_GetClassSoundRespawnID(iD);
 **/
public int API_GetClassSoundRespawnID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundRespawnID(iD);
}

/**
 * Gets the burn sound key of the class.
 *
 * native void ZP_GetClassSoundBurnID(iD);
 **/
public int API_GetClassSoundBurnID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundBurnID(iD);
}

/**
 * Gets the attack sound key of the class.
 *
 * native void ZP_GetClassSoundAttackID(iD);
 **/
public int API_GetClassSoundAttackID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundAttackID(iD);
}

/**
 * Gets the footstep sound key of the class.
 *
 * native void ZP_GetClassSoundFootID(iD);
 **/
public int API_GetClassSoundFootID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundFootID(iD);
}

/**
 * Gets the regeneration sound key of the class.
 *
 * native void ZP_GetClassSoundRegenID(iD);
 **/
public int API_GetClassSoundRegenID(Handle hPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundRegenID(iD);
}

/**
 * Print the info about the class.
 *
 * native void ZP_PrintClassInfo(clientIndex, iD);
 **/
public int API_PrintClassInfo(Handle hPlugin, const int iNumParams)
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
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Player doens't exist (%d)", clientIndex);
        return -1;
    }
    
    // Gets class index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= arrayClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Gets  name
    static char sName[SMALL_LINE_LENGTH];
    ClassGetName(iD, sName, sizeof(sName));

    // If help messages enabled, show info
    TranslationPrintToChat(clientIndex, " info", sName, ClassGetHealth(iD), ClassGetSpeed(iD), ClassGetGravity(iD));
    
    // Return on success
    return sizeof(sName);
}

/*
 * Classes data reading API.
 */

/**
 * Gets the name of a class at a given index.
 *
 * @param iD                The class index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class name
    arrayClass.GetString(CLASSES_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the info of a class at a given index.
 *
 * @param iD                The class index.
 * @param sInfo             The string to return info in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetInfo(const int iD, char[] sInfo, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class info
    arrayClass.GetString(CLASSES_DATA_INFO, sInfo, iMaxLen);
}

/**
 * Gets the type of a class at a given index.
 *
 * @param iD                The class index.
 * @param sType             The string to return type in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetType(const int iD, char[] sType, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class type
    arrayClass.GetString(CLASSES_DATA_TYPE, sType, iMaxLen);
}

/**
 * Checks the zombie type of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
stock bool ClassIsZombie(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class zombie type
    return arrayClass.Get(CLASSES_DATA_ZOMBIE);
}

/**
 * Gets the player model of a class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class model
    arrayClass.GetString(CLASSES_DATA_MODEL, sModel, iMaxLen);
}

/**
 * Gets the knife model of a class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetClawModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class claw model
    arrayClass.GetString(CLASSES_DATA_CLAW, sModel, iMaxLen);
}

/**
 * Gets the grenade model of a class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetGrenadeModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class grenade model
    arrayClass.GetString(CLASSES_DATA_GRENADE, sModel, iMaxLen);
}

/**
 * Gets the arm model of a class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetArmModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class arm model
    arrayClass.GetString(CLASSES_DATA_ARM, sModel, iMaxLen);
}

/**
 * Gets the body of the class.
 *
 * @param iD                The class index.
 * @return                  The body index.    
 **/
stock int ClassGetBody(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class body
    return arrayClass.Get(CLASSES_DATA_BODY);
}

/**
 * Gets the skin of the class.
 *
 * @param iD                The class index.
 * @return                  The skin index.    
 **/
stock int ClassGetSkin(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class skin
    return arrayClass.Get(CLASSES_DATA_SKIN);
}

/**
 * Gets the health of the class.
 *
 * @param iD                The class index.
 * @return                  The health amount.    
 **/
stock int ClassGetHealth(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class health
    return arrayClass.Get(CLASSES_DATA_HEALTH);
}

/**
 * Gets the speed of the class.
 *
 * @param iD                The class index.
 * @return                  The speed amount.    
 **/
stock float ClassGetSpeed(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class speed 
    return arrayClass.Get(CLASSES_DATA_SPEED);
}

/**
 * Gets the gravity of the class.
 *
 * @param iD                The class index.
 * @return                  The gravity amount.    
 **/
stock float ClassGetGravity(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class speed 
    return arrayClass.Get(CLASSES_DATA_GRAVITY);
}

/**
 * Gets the knockback of the class.
 *
 * @param iD                The class index.
 * @return                  The knockback amount.    
 **/
stock float ClassGetKnockBack(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class knockback 
    return arrayClass.Get(CLASSES_DATA_KNOCKBACK);
}

/**
 * Gets the armor of the class.
 *
 * @param iD                The class index.
 * @return                  The armor amount.    
 **/
stock int ClassGetArmor(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class armor 
    return arrayClass.Get(CLASSES_DATA_ARMOR);
}

/**
 * Gets the level of the class.
 *
 * @param iD                The class index.
 * @return                  The level amount.    
 **/
stock int ClassGetLevel(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class level 
    return arrayClass.Get(CLASSES_DATA_LEVEL);
}

/**
 * Gets the access group of a class at a given index.
 *
 * @param iD                The class index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetGroup(const int iD, char[] sGroup, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class group
    arrayClass.GetString(CLASSES_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * Gets the skill duration of the class.
 *
 * @param iD                The class index.
 * @return                  The duration amount.    
 **/
stock float ClassGetSkillDuration(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class skill duration 
    return arrayClass.Get(CLASSES_DATA_SKILLDURATION);
}

/**
 * Gets the skill countdown of the class.
 *
 * @param iD                The class index.
 * @return                  The countdown amount.    
 **/
stock float ClassGetSkillCountDown(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class skill countdown  
    return arrayClass.Get(CLASSES_DATA_SKILLCOUNTDOWN);
}

/**
 * Gets the regen health of the class.
 *
 * @param iD                The class index.
 * @return                  The health amount.    
 **/
stock int ClassGetRegenHealth(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class regen health
    return arrayClass.Get(CLASSES_DATA_REGENHEALTH);
}

/**
 * Gets the regen interval of the class.
 *
 * @param iD                The class index.
 * @return                  The interval amount.    
 **/
stock float ClassGetRegenInterval(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class regen interval
    return arrayClass.Get(CLASSES_DATA_REGENINTERVAL);
}

/**
 * Gets the fov of the class.
 *
 * @param iD                The class index.
 * @return                  The fov amount.    
 **/
stock int ClassGetFov(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class fov amount
    return arrayClass.Get(CLASSES_DATA_FOV);
}

/**
 * Checks the no fall of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
stock bool ClassIsNoFall(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class no fall state
    return arrayClass.Get(CLASSES_DATA_NOFALL);
}

/**
 * Checks the crosshair of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
stock bool ClassIsCross(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class crosshair state
    return arrayClass.Get(CLASSES_DATA_CROSSHAIR);
}

/**
 * Checks the nightvision of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
stock bool ClassIsNvgs(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class nightvision state
    return arrayClass.Get(CLASSES_DATA_NVGS);
}

/**
 * Gets the overlay of a class at a given index.
 *
 * @param iD                The class index.
 * @param sOverlay          The string to return overlay in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetOverlay(const int iD, char[] sOverlay, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class overlay
    arrayClass.GetString(CLASSES_DATA_OVERLAY, sOverlay, iMaxLen);
}

/**
 * Gets the weapon of a class at a given index.
 *
 * @param iD                The class index.
 * @param iWeapon           The array to return weapon in.
 * @param iMaxLen           The max length of the array.
 **/
stock void ClassGetWeapon(const int iD, int[] iWeapon, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class weapon
    arrayClass.GetArray(CLASSES_DATA_WEAPON, iWeapon, iMaxLen);
}

/**
 * Gets the money of a class at a given index.
 *
 * @param iD                The class index.
 * @param iMoney            The array to return money in.
 * @param iMaxLen           The max length of the array.
 **/
stock void ClassGetMoney(const int iD, int[] iMoney, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class money
    arrayClass.GetArray(CLASSES_DATA_MONEY, iMoney, iMaxLen);
}

/**
 * Gets the experience of a class at a given index.
 *
 * @param iD                The class index.
 * @param iExp              The array to return experience in.
 * @param iMaxLen           The max length of the array.
 **/
stock void ClassGetExp(const int iD, int[] iExp, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class experience
    arrayClass.GetArray(CLASSES_DATA_EXP, iExp, iMaxLen);
}

/**
 * Gets the lifesteal of the class.
 *
 * @param iD                The class index.
 * @return                  The steal amount.    
 **/
stock int ClassGetLifeSteal(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class lifesteal amount
    return arrayClass.Get(CLASSES_DATA_LIFESTEAL);
}

/**
 * Gets the ammunition of the class.
 *
 * @param iD                The class index.
 * @return                  The ammunition type.    
 **/
stock int ClassGetAmmunition(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class ammunition type
    return arrayClass.Get(CLASSES_DATA_AMMUNITION);
}

/**
 * Gets the leap jump of the class.
 *
 * @param iD                The class index.
 * @return                  The leap jump.    
 **/
stock int ClassGetLeapJump(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class leap jump
    return arrayClass.Get(CLASSES_DATA_LEAPJUMP);
}

/**
 * Gets the leap force of the class.
 *
 * @param iD                The class index.
 * @return                  The leap force.    
 **/
stock float ClassGetLeapForce(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class leap force
    return arrayClass.Get(CLASSES_DATA_LEAPFORCE);
}

/**
 * Gets the leap countdown of the class.
 *
 * @param iD                The class index.
 * @return                  The leap countdown.    
 **/
stock float ClassGetLeapCountdown(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class leap countdown
    return arrayClass.Get(CLASSES_DATA_LEAPCOUNTDOWN);
}

/**
 * Gets the effect name of a class at a given index.
 *
 * @param iD                The class index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetEffectName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class effect name
    arrayClass.GetString(CLASSES_DATA_EFFECTNAME, sName, iMaxLen);
}

/**
 * Gets the effect attachment of a class at a given index.
 *
 * @param iD                The class index.
 * @param sAttach           The string to return attach in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ClassGetEffectAttach(const int iD, char[] sAttach, const int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class effect attach
    arrayClass.GetString(CLASSES_DATA_EFFECTATTACH, sAttach, iMaxLen);
}

/**
 * Gets the effect time of the class.
 *
 * @param iD                The class index.
 * @return                  The effect time.    
 **/
stock float ClassGetEffectTime(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class effect time
    return arrayClass.Get(CLASSES_DATA_EFFECTTIME);
}

/**
 * Gets the index of the class claw model.
 *
 * @param iD                The class index.
 * @return                  The model index.    
 **/
stock int ClassGetClawID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class claw model index
    return arrayClass.Get(CLASSES_DATA_CLAW_);
}

/**
 * Gets the index of the class grenade model.
 *
 * @param iD                The class index.
 * @return                  The model index.    
 **/
stock int ClassGetGrenadeID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class grenade model index
    return arrayClass.Get(CLASSES_DATA_GRENADE_);
}

/**
 * Gets the death sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundDeathID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class death sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDDEATH);
}

/**
 * Gets the hurt sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundHurtID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class hurt sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDHURT);
}

/**
 * Gets the idle sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundIdleID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class idle sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDIDLE);
}

/**
 * Gets the infect sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundInfectID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class infect sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDINFECT);
}

/**
 * Gets the respawn sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundRespawnID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class respawn sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDRESPAWN);
}

/**
 * Gets the burn sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundBurnID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class idle sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDBURN);
}

/**
 * Gets the attack sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundAttackID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class idle sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDATTACK);
}

/**
 * Gets the footstep sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundFootID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class footstep sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDFOOTSTEP);
}

/**
 * Gets the regeneration sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ClassGetSoundRegenID(const int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = arrayClasses.Get(iD);

    // Gets class regeneration sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDREGEN);
}

/*
 * Stocks classes API.
 */

/**
 * Find the index at which the class name is at.
 * 
 * @param sName             The class name.
 * @param iMaxLen           (Only if 'overwritename' is true) The max length of the class name. 
 * @param bOverWriteName    (Optional) If true, the class given will be overwritten with the name from the config.
 * @return                  The array index containing the given class name.
 **/
stock int ClassNameToIndex(char[] sName, const int iMaxLen = 0, const bool bOverWriteName = false)
{
    // Initialize name char
    static char sClassName[SMALL_LINE_LENGTH];
    
    // i = class index
    int iSize = arrayClasses.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets class name 
        ClassGetName(i, sClassName, sizeof(sClassName));
        
        // If names match, then return index
        if(!strcmp(sName, sClassName, false))
        {
            // If 'overwrite' name is true, then overwrite the old string with new
            if(bOverWriteName)
            {
                // Copy config name to return string
                strcopy(sName, iMaxLen, sClassName);
            }
            
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return -1;
}

/**
 * Dump class data into a string. String buffer length should be at about 2048 cells.
 *
 * @param iD                The class index.
 * @param sBuffer           The string to return buffer in.
 * @param iMaxLen           The max length of the string.
 * @return                  The number of cells written.
 */
/*void ClassDumpData(const int iD, char[] sBuffer, const int iMaxLen)
{
    int iCellCount;
    static char sAttribute[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH];
    static char sFormat[PLATFORM_MAX_PATH];

    if(!iMaxLen)
    {
        return 0;
    }

    FormatEx(sFormat, sizeof(sFormat), "Class data at index %d:\n", index);
    iCellCount += StrCat(sBuffer, iMaxLen, sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, "-------------------------------------------------------------------------------\n");

    FormatEx(sAttribute, sizeof(sAttribute), "enabled:             \"%d\"\n", ClassIsEnabled(index));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetGroup(iD, format_buffer, sizeof(format_buffer));
    Format(sAttribute, sizeof(sAttribute), "group:                 \"%s\"\n", format_buffer);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);

    return iCellCount;
}*/