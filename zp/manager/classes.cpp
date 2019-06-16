/**
 * ============================================================================
 *
 *  Zombie Plague
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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @section Class config data indexes.
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
    CLASSES_DATA_SKILLBAR,
    CLASSES_DATA_HEALTHSPRITE,
    CLASSES_DATA_REGENHEALTH,
    CLASSES_DATA_REGENINTERVAL,
    CLASSES_DATA_FALL,
    CLASSES_DATA_SPOTTED,
    CLASSES_DATA_FOV,
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
    CLASSES_DATA_SOUNDREGEN,
    CLASSES_DATA_SOUNDJUMP
};
/**
 * @endsection
 **/
 
/**
 * @section Number of valid bonuses.
 **/
enum /*BonusType*/
{
    BonusType_Invalid = -1,       /** Used as return value when a bonus doens't exist. */
    
    BonusType_Kill,               /** Kill bonus */
    BonusType_Damage,             /** Damage bonus */
    BonusType_Infect,             /** Infect or humanize bonus */  
    BonusType_Win,                /** Win bonus */ 
    BonusType_Lose,               /** Lose bonus */    
    BonusType_Draw                /** Draw bonus */ 
};
/**
 * @endsection
 **/
 
/**
 * @section Number of valid animations.
 **/ 
enum AnimType
{
    AnimType_Invalid = -1,        /** Used as return value when an event doens't exist. */
    
    AnimType_FirePrimary,
    AnimType_FireSecondary,
    AnimType_MeleeSlash,
    AnimType_MeleeStab,
    AnimType_FireSilent,
    AnimType_SwitchSilent,
    AnimType_ThrowStart,
    AnimType_ThrowFinish,
    AnimType_Jump,
    AnimType_Reload,
    AnimType_ReloadStart,
    AnimType_ReloadLoop,
    AnimType_ReloadEnd,
    AnimType_BombAbort,
    AnimType_SwitchWeapon,
    AnimType_ThrowAbort = 17,
    AnimType_SwitchAbort
};
/**
 * @endsection
 **/
 
/*
 * Load other classes modules
 */
#include "zp/manager/playerclasses/jumpboost.cpp"
#include "zp/manager/playerclasses/skillsystem.cpp"
#include "zp/manager/playerclasses/levelsystem.cpp"
#include "zp/manager/playerclasses/runcmd.cpp"
#include "zp/manager/playerclasses/antistick.cpp"
#include "zp/manager/playerclasses/account.cpp"
#include "zp/manager/playerclasses/spawn.cpp"
#include "zp/manager/playerclasses/death.cpp"
#include "zp/manager/playerclasses/apply.cpp"
#include "zp/manager/playerclasses/classmenus.cpp"
#include "zp/manager/playerclasses/classcommands.cpp"
#include "zp/manager/playerclasses/tools.cpp" /// player helpers

/**
 * @brief Classes module init function.
 **/
void ClassesOnInit(/*void*/)
{
    // Forward event to sub-modules
    ToolsOnInit();
    SpawnOnInit();
    DeathOnInit();
    JumpBoostOnInit();
    AccountOnInit();
    LevelSystemOnInit();
}

/**
 * @brief Classes module purge function.
 **/
void ClassesOnPurge(/*void*/)
{
    // Forward event to sub-modules
    ToolsOnPurge();
}

/**
 * @brief Prepare all class data.
 **/
void ClassesOnLoad(/*void*/)
{
    // Forward event to sub-modules
    SpawnOnLoad();
    DeathOnLoad();
    
    // Register config file
    ConfigRegisterConfig(File_Classes, Structure_Keyvalue, CONFIG_FILE_ALIAS_CLASSES);

    // Gets classes config path
    static char sPathClasses[PLATFORM_LINE_LENGTH];
    bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_CLASSES, sPathClasses, sizeof(sPathClasses));

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Missing classes config file: \"%s\"", sPathClasses);
        return;
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_Classes, sPathClasses);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Classes, gServerData.Classes);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathClasses);
        return;
    }

    // Now copy data to array structure
    ClassesOnCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Classes, true);
    ConfigSetConfigReloadFunc(File_Classes, GetFunctionByName(GetMyHandle(), "ClassesOnConfigReload"));
    ConfigSetConfigHandle(File_Classes, gServerData.Classes);
}

/**
 * @brief Caches class data from file into arrays.
 **/
void ClassesOnCacheData(/*void*/)
{
    // Gets config file path
    static char sPathClasses[PLATFORM_LINE_LENGTH];
    ConfigGetConfigPath(File_Classes, sPathClasses, sizeof(sPathClasses));

    // Opens config
    KeyValues kvClasses;
    bool bSuccess = ConfigOpenConfigFile(File_Classes, kvClasses);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Unexpected error caching data from classes config file: \"%s\"", sPathClasses);
        return;
    }
    
    // If array hasn't been created, then create
    if(gServerData.Types == null)
    {
        // Initialize a type list array
        gServerData.Types = new ArrayList(SMALL_LINE_LENGTH);
    }
    else
    {
        // Clear out the array of all data
        gServerData.Types.Clear();
    }
    
    // Validate size
    int iSize = gServerData.Classes.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "No usable data found in classes config file: \"%s\"", sPathClasses);
        return;
    }
    
    // i = array index
    for(int i = 0; i < iSize; i++)
    {
        // General
        ClassGetName(i, sPathClasses, sizeof(sPathClasses)); // Index: 0
        kvClasses.Rewind();
        if(!kvClasses.JumpToKey(sPathClasses))
        {
            // Log class fatal
            LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class data for: \"%s\" (check classes config)", sPathClasses);
            continue;
        }
        
        // Validate translation
        StringToLower(sPathClasses);
        if(!TranslationPhraseExists(sPathClasses))
        {
            // Log class error
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class name: \"%s\" (check translation file)", sPathClasses);
            continue;
        }

        // Initialize array block
        ArrayList arrayClass = gServerData.Classes.Get(i);

        // Push data into array
        kvClasses.GetString("info", sPathClasses, sizeof(sPathClasses), ""); StringToLower(sPathClasses);
        if(!TranslationPhraseExists(sPathClasses) && hasLength(sPathClasses))
        {
            // Log class error
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class info: \"%s\" (check translation file)", sPathClasses);
        }
        arrayClass.PushString(sPathClasses);                                    // Index: 1
        kvClasses.GetString("type", sPathClasses, sizeof(sPathClasses), ""); StringToLower(sPathClasses);
        if(!TranslationPhraseExists(sPathClasses) && hasLength(sPathClasses))
        {
            // Log class error
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class type: \"%s\" (check translation file)", sPathClasses);
        }
        arrayClass.PushString(sPathClasses);                                    // Index: 2
        if(gServerData.Types.FindString(sPathClasses) == -1)
        {
            gServerData.Types.PushString(sPathClasses); /// Unique type catched
        }
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "zombie", "no"));      // Index: 3
        kvClasses.GetString("model", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 4
        DecryptPrecacheModel(sPathClasses);
        kvClasses.GetString("claw_model", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 5
        arrayClass.Push(DecryptPrecacheWeapon(sPathClasses));                   // Index: 6
        kvClasses.GetString("gren_model", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 7
        arrayClass.Push(DecryptPrecacheWeapon(sPathClasses));                   // Index: 8
        kvClasses.GetString("arm_model", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 9
        DecryptPrecacheModel(sPathClasses);
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
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "bar", "off"));        // Index: 21
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "sprite", "off"));     // Index: 22
        arrayClass.Push(kvClasses.GetNum("regenerate", 0));                     // Index: 23
        arrayClass.Push(kvClasses.GetFloat("interval", 0.0));                   // Index: 24
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "fall", "on"));        // Index: 25
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "spotted", "on"));     // Index: 26
        arrayClass.Push(kvClasses.GetNum("fov", 90));                           // Index: 27
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "crosshair", "yes"));  // Index: 28
        arrayClass.Push(ConfigKvGetStringBool(kvClasses, "nvgs", "no"));        // Index: 29
        kvClasses.GetString("overlay", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 30
        if(hasLength(sPathClasses)) 
        {
            // Precache material
            Format(sPathClasses, sizeof(sPathClasses), "materials/%s", sPathClasses);
            DecryptPrecacheTextures(sPathClasses);
        }
        kvClasses.GetString("weapon", sPathClasses, sizeof(sPathClasses), "");
        static char sWeapon[SMALL_LINE_LENGTH][SMALL_LINE_LENGTH]; int iWeapon[SMALL_LINE_LENGTH] = { -1, ... };
        int nWeapon = ExplodeString(sPathClasses, ",", sWeapon, sizeof(sWeapon), sizeof(sWeapon[]));
        for(int x = 0; x < nWeapon; x++)
        {
            // Trim string
            TrimString(sWeapon[x]);

            // Push data into array
            iWeapon[x] = WeaponsNameToIndex(sWeapon[x]);
        } 
        arrayClass.PushArray(iWeapon, sizeof(iWeapon));                         // Index: 31
        kvClasses.GetString("money", sPathClasses, sizeof(sPathClasses), "");
        static char sMoney[6][SMALL_LINE_LENGTH]; int iMoney[6];
        int nMoney = ExplodeString(sPathClasses, ",", sMoney, sizeof(sMoney), sizeof(sMoney[]));
        for(int x = 0; x < nMoney; x++)
        {
            // Trim string
            TrimString(sWeapon[x]);

            // Push data into array
            iMoney[x] = StringToInt(sMoney[x]);
        }
        arrayClass.PushArray(iMoney, sizeof(iMoney));                           // Index: 32
        kvClasses.GetString("experience", sPathClasses, sizeof(sPathClasses), "");
        static char sExp[6][SMALL_LINE_LENGTH]; int iExp[6];
        int nExp = ExplodeString(sPathClasses, ",", sExp, sizeof(sExp), sizeof(sExp[]));
        for(int x = 0; x < nExp; x++)
        {
            // Trim string
            TrimString(sWeapon[x]);

            // Push data into array
            iExp[x] = StringToInt(sExp[x]);
        }
        arrayClass.PushArray(iExp, sizeof(iExp));                               // Index: 33
        arrayClass.Push(kvClasses.GetNum("lifesteal", 0));                      // Index: 34
        arrayClass.Push(kvClasses.GetNum("ammunition", 0));                     // Index: 35
        arrayClass.Push(kvClasses.GetNum("leap", 0));                           // Index: 36
        arrayClass.Push(kvClasses.GetFloat("force", 0.0));                      // Index: 37
        arrayClass.Push(kvClasses.GetFloat("cooldown", 0.0));                   // Index: 38
        kvClasses.GetString("effect", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 39
        kvClasses.GetString("attachment", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.PushString(sPathClasses);                                    // Index: 40
        arrayClass.Push(kvClasses.GetFloat("time", 1.0));                       // Index: 41
        kvClasses.GetString("death", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 42
        kvClasses.GetString("hurt", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 43
        kvClasses.GetString("idle", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 44
        kvClasses.GetString("infect", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 45
        kvClasses.GetString("respawn", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 46
        kvClasses.GetString("burn", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 47
        kvClasses.GetString("attack", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 48
        kvClasses.GetString("footstep", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 49
        kvClasses.GetString("regen", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 50
        kvClasses.GetString("jump", sPathClasses, sizeof(sPathClasses), "");
        arrayClass.Push(SoundsKeyToIndex(sPathClasses));                        // Index: 51
    }

    // We're done with this file now, so we can close it
    delete kvClasses;
}

/**
 * @brief Called when configs are being reloaded.
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void ClassesOnConfigReload(ConfigFile iConfig)
{
    // Reloads class config
    ClassesOnLoad();
}

/**
 * @brief Creates commands for classes module.
 **/
void ClassesOnCommandInit(/*void*/)
{
    // Forward event to sub-modules
    AccountOnCommandInit();
    AntiStickOnCommandInit();
    ClassMenusOnCommandInit();
    LevelSystemOnCommandInit();
    ClassCommandsOnCommandInit();
}

/**
 * @brief Hook classes cvar changes.
 **/
void ClassesOnCvarInit(/*void*/)
{
    // Forward event to sub-modules
    JumpBoostOnCvarInit();
    LevelSystemOnCvarInit();
    AccountOnCvarInit();
    SkillSystemOnCvarInit();
    ToolsOnCvarInit();
    DeathOnCvarInit();
    AntiStickOnCvarInit();
    
    // Creates cvars
    gCvarList[CVAR_HUMAN_MENU]  = FindConVar("zp_human_menu");
    gCvarList[CVAR_ZOMBIE_MENU] = FindConVar("zp_zombie_menu");
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.
 **/
void ClassesOnClientInit(int client)
{
    // Forward event to sub-modules
    DeathOnClientInit(client);
    AntiStickOnClientInit(client);
    JumpBoostOnClientInit(client);
}

/**
 * @brief Called once a client successfully connects.
 *
 * @param client            The client index.
 **/
void ClassesOnClientConnect(int client)
{
    // Forward event to sub-modules
    ToolsOnClientConnect(client);
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param client            The client index.
 **/
void ClassesOnClientDisconnectPost(int client)
{
    // Forward event to sub-modules
    ToolsOnClientDisconnectPost(client);
    GameModesOnClientDisconnectPost(client);
}

/*
 * Classes natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void ClassesOnNativeInit(/*void*/)
{
    CreateNative("ZP_ChangeClient",             API_ChangeClient); 
    CreateNative("ZP_GetNumberClass",           API_GetNumberClass);
    CreateNative("ZP_GetClientClass",           API_GetClientClass);
    CreateNative("ZP_GetClientHumanClassNext",  API_GetClientHumanClassNext);
    CreateNative("ZP_GetClientZombieClassNext", API_GetClientZombieClassNext);
    CreateNative("ZP_SetClientHumanClassNext",  API_SetClientHumanClassNext);
    CreateNative("ZP_SetClientZombieClassNext", API_SetClientZombieClassNext);
    CreateNative("ZP_GetClassNameID",           API_GetClassNameID);
    CreateNative("ZP_GetClassName",             API_GetClassName);
    CreateNative("ZP_GetClassInfo",             API_GetClassInfo);
    CreateNative("ZP_GetClassTypeID",           API_GetClassTypeID);
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
    CreateNative("ZP_IsClassSkillBar",          API_IsClassSkillBar);
    CreateNative("ZP_IsClassHealthSprite",      API_IsClassHealthSprite);
    CreateNative("ZP_GetClassRegenHealth",      API_GetClassRegenHealth);
    CreateNative("ZP_GetClassRegenInterval",    API_GetClassRegenInterval);
    CreateNative("ZP_IsClassFall",              API_IsClassFall);
    CreateNative("ZP_IsClassSpot",              API_IsClassSpot);
    CreateNative("ZP_GetClassFov",              API_GetClassFov);
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
    CreateNative("ZP_GetClassSoundJumpID",      API_GetClassSoundJumpID);
    
    // Forward event to sub-modules
    SkillSystemOnNativeInit();
    LevelSystemOnNativeInit();
    AccountOnNativeInit();
}

/**
 * @brief Infect/humanize a player.
 *
 * @note native bool ZP_ChangeClient(client, attacker, type);
 **/
public int API_ChangeClient(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(client))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the client index (%d)", client);
        return false;
    }
    
    // Gets real player index from native cell 
    int attacker = GetNativeCell(2);

    // Validate attacker
    if(attacker > 0 && !IsPlayerExist(attacker, false))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the attacker index (%d)", attacker);
        return false;
    }
    
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(3, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Can't find class with an empty name");
        return false;
    }
    
    // Gets native data
    static char sType[SMALL_LINE_LENGTH];

    // General
    GetNativeString(3, sType, sizeof(sType));
    
    // Force client to update
    return ApplyOnClientUpdate(client, attacker, sType);
}
 
/**
 * @brief Gets the amount of all classes.
 *
 * @note native int ZP_GetNumberClass();
 **/
public int API_GetNumberClass(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return gServerData.Classes.Length;
}

/**
 * @brief Gets the current class index of the client.
 *
 * @note native int ZP_GetClientClass(client);
 **/
public int API_GetClientClass(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Return the value 
    return gClientData[client].Class;
}

/**
 * @brief Gets the human next class index of the client.
 *
 * @note native int ZP_GetClientHumanClassNext(client);
 **/
public int API_GetClientHumanClassNext(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Return the value 
    return gClientData[client].HumanClassNext;
}

/**
 * @brief Gets the zombie next class index of the client.
 *
 * @note native int ZP_GetClientZombieClassNext(client);
 **/
public int API_GetClientZombieClassNext(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Return the value 
    return gClientData[client].ZombieClassNext;
}

/**
 * @brief Sets the human next class index to the client.
 *
 * @note native void ZP_SetClientHumanClassNext(client, iD);
 **/
public int API_SetClientHumanClassNext(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Call forward
    Action hResult;
    gForwardData._OnClientValidateClass(client, iD, hResult);

    // Validate handle
    if(hResult == Plugin_Continue || hResult == Plugin_Changed)
    {
        // Sets next human class to the client
        gClientData[client].HumanClassNext = iD;
    }

    // Return on success
    return iD;
}

/**
 * @brief Sets the zombie next class index to the client.
 *
 * @note native void ZP_SetClientZombieClassNext(client, iD);
 **/
public int API_SetClientZombieClassNext(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Call forward
    Action hResult;
    gForwardData._OnClientValidateClass(client, iD, hResult);

    // Validate handle
    if(hResult == Plugin_Continue || hResult == Plugin_Changed)
    {
        // Sets next zombie class to the client
        gClientData[client].ZombieClassNext = iD;
    }

    // Return on success
    return iD;
}

/**
 * @brief Gets the index of a class at a given name.
 *
 * @note native int ZP_GetClassNameID(name);
 **/
public int API_GetClassNameID(Handle hPlugin, int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Can't find class with an empty name");
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
 * @brief Gets the name of a class at a given index.
 *
 * @note native void ZP_GetClassName(iD, name, maxlen);
 **/
public int API_GetClassName(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    ClassGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the info of a class at a given index.
 *
 * @note native void ZP_GetClassInfo(iD, info, maxlen);
 **/
public int API_GetClassInfo(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize info char
    static char sInfo[BIG_LINE_LENGTH];
    ClassGetInfo(iD, sInfo, sizeof(sInfo));

    // Return on success
    return SetNativeString(2, sInfo, maxLen);
}

/**
 * @brief Gets the index of a class at a given type.
 *
 * @note native int ZP_GetClassTypeID(type);
 **/
public int API_GetClassTypeID(Handle hPlugin, int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Can't find class with an empty type");
        return -1;
    }
    
    // Gets native data
    static char sType[SMALL_LINE_LENGTH];

    // General
    GetNativeString(1, sType, sizeof(sType));
    
    // Return the value
    return ClassTypeToIndex(sType); 
}

/**
 * @brief Gets the type of a class at a given index.
 *
 * @note native void ZP_GetClassType(iD, type, maxlen);
 **/
public int API_GetClassType(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize type char
    static char sType[SMALL_LINE_LENGTH];
    ClassGetType(iD, sType, sizeof(sType));

    // Return on success
    return SetNativeString(2, sType, maxLen);
}

/**
 * @brief Checks the zombie type of the class.
 *
 * @note native bool ZP_IsClassZombie(iD);
 **/
public int API_IsClassZombie(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsZombie(iD);
}

/**
 * @brief Gets the player model of a class at a given index.
 *
 * @note native void ZP_GetClassModel(iD, model, maxlen);
 **/
public int API_GetClassModel(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    ClassGetModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the knife model of a class at a given index.
 *
 * @note native void ZP_GetClassClaw(iD, model, maxlen);
 **/
public int API_GetClassClaw(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    ClassGetClawModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the grenade model of a class at a given index.
 *
 * @note native void ZP_GetClassGrenade(iD, model, maxlen);
 **/
public int API_GetClassGrenade(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    ClassGetGrenadeModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the arm model of a class at a given index.
 *
 * @note native void ZP_GetClassArm(iD, model, maxlen);
 **/
public int API_GetClassArm(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    ClassGetArmModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the body of the class.
 *
 * @note native int ZP_GetClassBody(iD);
 **/
public int API_GetClassBody(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetBody(iD);
}

/**
 * @brief Gets the skin of the class.
 *
 * @note native int ZP_GetClassSkin(iD);
 **/
public int API_GetClassSkin(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetSkin(iD);
}

/**
 * @brief Gets the health of the class.
 *
 * @note native int ZP_GetClassHealth(iD);
 **/
public int API_GetClassHealth(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetHealth(iD);
}

/**
 * @brief Gets the speed of the class.
 *
 * @note native float ZP_GetClassSpeed(iD);
 **/
public int API_GetClassSpeed(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ClassGetSpeed(iD));
}

/**
 * @brief Gets the gravity of the class.
 *
 * @note native float ZP_GetClassGravity(iD);
 **/
public int API_GetClassGravity(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ClassGetGravity(iD));
}

/**
 * @brief Gets the knockback of the class.
 *
 * @note native float ZP_GetClassKnockBack(iD);
 **/
public int API_GetClassKnockBack(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ClassGetKnockBack(iD));
}

/**
 * @brief Gets the armor of the class.
 *
 * @note native int ZP_GetClassArmor(iD);
 **/
public int API_GetClassArmor(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetArmor(iD);
}

/**
 * @brief Gets the level of the class.
 *
 * @note native int ZP_GetClassLevel(iD);
 **/
public int API_GetClassLevel(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetLevel(iD);
}

/**
 * @brief Gets the group of a class at a given index.
 *
 * @note native void ZP_GetClassGroup(iD, group, maxlen);
 **/
public int API_GetClassGroup(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    ClassGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the skill duration of the class.
 *
 * @note native float ZP_GetClassSkillDuration(iD);
 **/
public int API_GetClassSkillDuration(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetSkillDuration(iD));
}

/**
 * @brief Gets the skill countdown of the class.
 *
 * @note native float ZP_GetClassSkillCountdown(iD);
 **/
public int API_GetClassSkillCountdown(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetSkillCountdown(iD));
}

/**
 * @brief Checks the skill bar of the class.
 *
 * @note native bool ZP_IsClassSkillBar(iD);
 **/
public int API_IsClassSkillBar(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsSkillBar(iD);
}

/**
 * @brief Checks the health sprite of the class.
 *
 * @note native bool ZP_IsClassHealthSprite(iD);
 **/
public int API_IsClassHealthSprite(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsHealthSprite(iD);
}

/**
 * @brief Gets the regen health of the class.
 *
 * @note native int ZP_GetClassRegenHealth(iD);
 **/
public int API_GetClassRegenHealth(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetRegenHealth(iD);
}

/**
 * @brief Gets the regen interval of the class.
 *
 * @note native float ZP_GetClassRegenInterval(iD);
 **/
public int API_GetClassRegenInterval(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ClassGetRegenInterval(iD));
}

/**
 * @brief Checks the fall state of the class.
 *
 * @note native bool ZP_IsClassFall(iD);
 **/
public int API_IsClassFall(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsFall(iD);
}

/**
 * @brief Checks the spot state of the class.
 *
 * @note native bool ZP_IsClassSpot(iD);
 **/
public int API_IsClassSpot(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsSpot(iD);
}

/**
 * @brief Gets the fov of the class.
 *
 * @note native int ZP_GetClassFov(iD);
 **/
public int API_GetClassFov(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetFov(iD);
}

/**
 * @brief Checks the crosshair of the class.
 *
 * @note native bool ZP_IsClassCross(iD);
 **/
public int API_IsClassCross(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsCross(iD);
}

/**
 * @brief Checks the nightvision of the class.
 *
 * @note native bool ZP_IsClassNvgs(iD);
 **/
public int API_IsClassNvgs(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassIsNvgs(iD);
}

/**
 * @brief Gets the overlay of a class at a given index.
 *
 * @note native void ZP_GetClassOverlay(iD, overlay, maxlen);
 **/
public int API_GetClassOverlay(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize overlay char
    static char sOverlay[PLATFORM_LINE_LENGTH];
    ClassGetOverlay(iD, sOverlay, sizeof(sOverlay));

    // Return on success
    return SetNativeString(2, sOverlay, maxLen);
}

/**
 * @brief Gets the weapon of a class at a given index.
 *
 * @note native void ZP_GetClassWeapon(iD, weapon, maxlen);
 **/
public int API_GetClassWeapon(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize weapon array
    static int iWeapon[SMALL_LINE_LENGTH];
    ClassGetWeapon(iD, iWeapon, sizeof(iWeapon));

    // Return on success
    return SetNativeArray(2, iWeapon, maxLen);
}

/**
 * @brief Gets the money of a class at a given index.
 *
 * @note native void ZP_GetClassMoney(iD, money, maxlen);
 **/
public int API_GetClassMoney(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize money array
    static int iMoney[6];
    ClassGetMoney(iD, iMoney, sizeof(iMoney));

    // Return on success
    return SetNativeArray(2, iMoney, maxLen);
}

/**
 * @brief Gets the experience of a class at a given index.
 *
 * @note native void ZP_GetClassExperience(iD, experience, maxlen);
 **/
public int API_GetClassExperience(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize experience array
    static int iExp[6];
    ClassGetExp(iD, iExp, sizeof(iExp));

    // Return on success
    return SetNativeArray(2, iExp, maxLen);
}

/**
 * @brief Gets the lifesteal of the class.
 *
 * @note native int ZP_GetClassLifeSteal(iD);
 **/
public int API_GetClassLifeSteal(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetLifeSteal(iD);
}

/**
 * @brief Gets the ammunition of the class.
 *
 * @note native int ZP_GetClassLifeAmmunition(iD);
 **/
public int API_GetClassAmmunition(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetAmmunition(iD);
}

/**
 * @brief Gets the leap jump of the class.
 *
 * @note native int ZP_GetClassLeapJump(iD);
 **/
public int API_GetClassLeapJump(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetLeapJump(iD);
}

/**
 * @brief Gets the leap force of the class.
 *
 * @note native float ZP_GetClassLeapForce(iD);
 **/
public int API_GetClassLeapForce(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetLeapForce(iD));
}

/**
 * @brief Gets the leap countdown of the class.
 *
 * @note native float ZP_GetClassLeapCountdown(iD);
 **/
public int API_GetClassLeapCountdown(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetLeapCountdown(iD));
}

/**
 * @brief Gets the effect name of a class at a given index.
 *
 * @note native void ZP_GetClassEffectName(iD, name, maxlen);
 **/
public int API_GetClassEffectName(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    ClassGetEffectName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the effect attachment of a class at a given index.
 *
 * @note native void ZP_GetClassEffectAttach(iD, attach, maxlen);
 **/
public int API_GetClassEffectAttach(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize attachment char
    static char sAttach[SMALL_LINE_LENGTH];
    ClassGetEffectAttach(iD, sAttach, sizeof(sAttach));

    // Return on success
    return SetNativeString(2, sAttach, maxLen);
}

/**
 * @brief Gets the effect time of the class.
 *
 * @note native float ZP_GetClassEffectTime(iD);
 **/
public int API_GetClassEffectTime(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ClassGetEffectTime(iD));
}

/**
 * @brief Gets the index of the class.
 *
 * @note native int ZP_GetClassClawID(iD);
 **/
public int API_GetClassClawID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetClawID(iD);
}

/**
 * @brief Gets the index of the class grenade model.
 *
 * @note native int ZP_GetClassGrenadeID(iD);
 **/
public int API_GetClassGrenadeID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ClassGetGrenadeID(iD);
}

/**
 * @brief Gets the death sound key of the class.
 *
 * @note native void ZP_GetClassSoundDeathID(iD);
 **/
public int API_GetClassSoundDeathID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundDeathID(iD);
}

/**
 * @brief Gets the hurt sound key of the class.
 *
 * @note native void ZP_GetClassSoundHurtID(iD);
 **/
public int API_GetClassSoundHurtID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundHurtID(iD);
}

/**
 * @brief Gets the idle sound key of the class.
 *
 * @note native void ZP_GetClassSoundIdleID(iD);
 **/
public int API_GetClassSoundIdleID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundIdleID(iD);
}

/**
 * @brief Gets the infect sound key of the class.
 *
 * @note native void ZP_GetClassSoundInfectID(iD);
 **/
public int API_GetClassSoundInfectID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundInfectID(iD);
}

/**
 * @brief Gets the respawn sound key of the class.
 *
 * @note native void ZP_GetClassSoundRespawnID(iD);
 **/
public int API_GetClassSoundRespawnID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundRespawnID(iD);
}

/**
 * @brief Gets the burn sound key of the class.
 *
 * @note native void ZP_GetClassSoundBurnID(iD);
 **/
public int API_GetClassSoundBurnID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundBurnID(iD);
}

/**
 * @brief Gets the attack sound key of the class.
 *
 * @note native void ZP_GetClassSoundAttackID(iD);
 **/
public int API_GetClassSoundAttackID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundAttackID(iD);
}

/**
 * @brief Gets the footstep sound key of the class.
 *
 * @note native void ZP_GetClassSoundFootID(iD);
 **/
public int API_GetClassSoundFootID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundFootID(iD);
}

/**
 * @brief Gets the regeneration sound key of the class.
 *
 * @note native void ZP_GetClassSoundRegenID(iD);
 **/
public int API_GetClassSoundRegenID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundRegenID(iD);
}

/**
 * @brief Gets the leap jump sound key of the class.
 *
 * @note native void ZP_GetClassSoundJumpID(iD);
 **/
public int API_GetClassSoundJumpID(Handle hPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= gServerData.Classes.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Classes, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ClassGetSoundJumpID(iD);
}

/*
 * Classes data reading API.
 */

/**
 * @brief Gets the name of a class at a given index.
 *
 * @param iD                The class index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetName(int iD, char[] sName, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class name
    arrayClass.GetString(CLASSES_DATA_NAME, sName, iMaxLen);
}

/**
 * @brief Gets the info of a class at a given index.
 *
 * @param iD                The class index.
 * @param sInfo             The string to return info in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetInfo(int iD, char[] sInfo, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class info
    arrayClass.GetString(CLASSES_DATA_INFO, sInfo, iMaxLen);
}

/**
 * @brief Gets the type of a class at a given index.
 *
 * @param iD                The class index.
 * @param sType             The string to return type in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetType(int iD, char[] sType, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class type
    arrayClass.GetString(CLASSES_DATA_TYPE, sType, iMaxLen);
}

/**
 * @brief Checks the zombie type of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
bool ClassIsZombie(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class zombie type
    return arrayClass.Get(CLASSES_DATA_ZOMBIE);
}

/**
 * @brief Gets the player model of a class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetModel(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class model
    arrayClass.GetString(CLASSES_DATA_MODEL, sModel, iMaxLen);
}

/**
 * @brief Gets the knife model of a class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetClawModel(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class claw model
    arrayClass.GetString(CLASSES_DATA_CLAW, sModel, iMaxLen);
}

/**
 * @brief Gets the grenade model of a class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetGrenadeModel(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class grenade model
    arrayClass.GetString(CLASSES_DATA_GRENADE, sModel, iMaxLen);
}

/**
 * @brief Gets the arm model of a class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetArmModel(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class arm model
    arrayClass.GetString(CLASSES_DATA_ARM, sModel, iMaxLen);
}

/**
 * @brief Gets the body of the class.
 *
 * @param iD                The class index.
 * @return                  The body index.    
 **/
int ClassGetBody(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class body
    return arrayClass.Get(CLASSES_DATA_BODY);
}

/**
 * @brief Gets the skin of the class.
 *
 * @param iD                The class index.
 * @return                  The skin index.    
 **/
int ClassGetSkin(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class skin
    return arrayClass.Get(CLASSES_DATA_SKIN);
}

/**
 * @brief Gets the health of the class.
 *
 * @param iD                The class index.
 * @return                  The health amount.    
 **/
int ClassGetHealth(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class health
    return arrayClass.Get(CLASSES_DATA_HEALTH);
}

/**
 * @brief Gets the speed of the class.
 *
 * @param iD                The class index.
 * @return                  The speed amount.    
 **/
float ClassGetSpeed(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class speed 
    return arrayClass.Get(CLASSES_DATA_SPEED);
}

/**
 * @brief Gets the gravity of the class.
 *
 * @param iD                The class index.
 * @return                  The gravity amount.    
 **/
float ClassGetGravity(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class speed 
    return arrayClass.Get(CLASSES_DATA_GRAVITY);
}

/**
 * @brief Gets the knockback of the class.
 *
 * @param iD                The class index.
 * @return                  The knockback amount.    
 **/
float ClassGetKnockBack(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class knockback 
    return arrayClass.Get(CLASSES_DATA_KNOCKBACK);
}

/**
 * @brief Gets the armor of the class.
 *
 * @param iD                The class index.
 * @return                  The armor amount.    
 **/
int ClassGetArmor(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class armor 
    return arrayClass.Get(CLASSES_DATA_ARMOR);
}

/**
 * @brief Gets the level of the class.
 *
 * @param iD                The class index.
 * @return                  The level amount.    
 **/
int ClassGetLevel(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class level 
    return arrayClass.Get(CLASSES_DATA_LEVEL);
}

/**
 * @brief Gets the access group of a class at a given index.
 *
 * @param iD                The class index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetGroup(int iD, char[] sGroup, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class group
    arrayClass.GetString(CLASSES_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * @brief Gets the skill duration of the class.
 *
 * @param iD                The class index.
 * @return                  The duration amount.    
 **/
float ClassGetSkillDuration(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class skill duration 
    return arrayClass.Get(CLASSES_DATA_SKILLDURATION);
}

/**
 * @brief Gets the skill countdown of the class.
 *
 * @param iD                The class index.
 * @return                  The countdown amount.    
 **/
float ClassGetSkillCountdown(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class skill countdown  
    return arrayClass.Get(CLASSES_DATA_SKILLCOUNTDOWN);
}

/**
 * @brief Gets the skill bar of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.
 **/
bool ClassIsSkillBar(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class skill bar  
    return arrayClass.Get(CLASSES_DATA_SKILLBAR);
}

/**
 * @brief Gets the health sprite of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.
 **/
bool ClassIsHealthSprite(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class health sprite  
    return arrayClass.Get(CLASSES_DATA_HEALTHSPRITE);
}

/**
 * @brief Gets the regen health of the class.
 *
 * @param iD                The class index.
 * @return                  The health amount.    
 **/
int ClassGetRegenHealth(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class regen health
    return arrayClass.Get(CLASSES_DATA_REGENHEALTH);
}

/**
 * @brief Gets the regen interval of the class.
 *
 * @param iD                The class index.
 * @return                  The interval amount.    
 **/
float ClassGetRegenInterval(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class regen interval
    return arrayClass.Get(CLASSES_DATA_REGENINTERVAL);
}

/**
 * @brief Checks the fall state of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
bool ClassIsFall(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class fall state
    return arrayClass.Get(CLASSES_DATA_FALL);
}

/**
 * @brief Checks the spot state of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
bool ClassIsSpot(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class spot state
    return arrayClass.Get(CLASSES_DATA_SPOTTED);
}

/**
 * @brief Gets the fov of the class.
 *
 * @param iD                The class index.
 * @return                  The fov amount.    
 **/
int ClassGetFov(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class fov amount
    return arrayClass.Get(CLASSES_DATA_FOV);
}

/**
 * @brief Checks the crosshair of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
bool ClassIsCross(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class crosshair state
    return arrayClass.Get(CLASSES_DATA_CROSSHAIR);
}

/**
 * @brief Checks the nightvision of the class.
 *
 * @param iD                The class index.
 * @return                  True or false.    
 **/
bool ClassIsNvgs(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class nightvision state
    return arrayClass.Get(CLASSES_DATA_NVGS);
}

/**
 * @brief Gets the overlay of a class at a given index.
 *
 * @param iD                The class index.
 * @param sOverlay          The string to return overlay in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetOverlay(int iD, char[] sOverlay, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class overlay
    arrayClass.GetString(CLASSES_DATA_OVERLAY, sOverlay, iMaxLen);
}

/**
 * @brief Gets the weapon of a class at a given index.
 *
 * @param iD                The class index.
 * @param iWeapon           The array to return weapon in.
 * @param iMaxLen           The max length of the array.
 **/
void ClassGetWeapon(int iD, int[] iWeapon, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class weapon
    arrayClass.GetArray(CLASSES_DATA_WEAPON, iWeapon, iMaxLen);
}

/**
 * @brief Gets the money of a class at a given index.
 *
 * @param iD                The class index.
 * @param iMoney            The array to return money in.
 * @param iMaxLen           The max length of the array.
 **/
void ClassGetMoney(int iD, int[] iMoney, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class money
    arrayClass.GetArray(CLASSES_DATA_MONEY, iMoney, iMaxLen);
}

/**
 * @brief Gets the experience of a class at a given index.
 *
 * @param iD                The class index.
 * @param iExp              The array to return experience in.
 * @param iMaxLen           The max length of the array.
 **/
void ClassGetExp(int iD, int[] iExp, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class experience
    arrayClass.GetArray(CLASSES_DATA_EXP, iExp, iMaxLen);
}

/**
 * @brief Gets the lifesteal of the class.
 *
 * @param iD                The class index.
 * @return                  The steal amount.    
 **/
int ClassGetLifeSteal(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class lifesteal amount
    return arrayClass.Get(CLASSES_DATA_LIFESTEAL);
}

/**
 * @brief Gets the ammunition of the class.
 *
 * @param iD                The class index.
 * @return                  The ammunition type.    
 **/
int ClassGetAmmunition(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class ammunition type
    return arrayClass.Get(CLASSES_DATA_AMMUNITION);
}

/**
 * @brief Gets the leap jump of the class.
 *
 * @param iD                The class index.
 * @return                  The leap jump.    
 **/
int ClassGetLeapJump(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class leap jump
    return arrayClass.Get(CLASSES_DATA_LEAPJUMP);
}

/**
 * @brief Gets the leap force of the class.
 *
 * @param iD                The class index.
 * @return                  The leap force.    
 **/
float ClassGetLeapForce(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class leap force
    return arrayClass.Get(CLASSES_DATA_LEAPFORCE);
}

/**
 * @brief Gets the leap countdown of the class.
 *
 * @param iD                The class index.
 * @return                  The leap countdown.    
 **/
float ClassGetLeapCountdown(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class leap countdown
    return arrayClass.Get(CLASSES_DATA_LEAPCOUNTDOWN);
}

/**
 * @brief Gets the effect name of a class at a given index.
 *
 * @param iD                The class index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetEffectName(int iD, char[] sName, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class effect name
    arrayClass.GetString(CLASSES_DATA_EFFECTNAME, sName, iMaxLen);
}

/**
 * @brief Gets the effect attachment of a class at a given index.
 *
 * @param iD                The class index.
 * @param sAttach           The string to return attach in.
 * @param iMaxLen           The lenght of string.
 **/
void ClassGetEffectAttach(int iD, char[] sAttach, int iMaxLen)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class effect attach
    arrayClass.GetString(CLASSES_DATA_EFFECTATTACH, sAttach, iMaxLen);
}

/**
 * @brief Gets the effect time of the class.
 *
 * @param iD                The class index.
 * @return                  The effect time.    
 **/
float ClassGetEffectTime(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class effect time
    return arrayClass.Get(CLASSES_DATA_EFFECTTIME);
}

/**
 * @brief Gets the index of the class claw model.
 *
 * @param iD                The class index.
 * @return                  The model index.    
 **/
int ClassGetClawID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class claw model index
    return arrayClass.Get(CLASSES_DATA_CLAW_);
}

/**
 * @brief Gets the index of the class grenade model.
 *
 * @param iD                The class index.
 * @return                  The model index.    
 **/
int ClassGetGrenadeID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class grenade model index
    return arrayClass.Get(CLASSES_DATA_GRENADE_);
}

/**
 * @brief Gets the death sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundDeathID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class death sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDDEATH);
}

/**
 * @brief Gets the hurt sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundHurtID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class hurt sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDHURT);
}

/**
 * @brief Gets the idle sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundIdleID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class idle sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDIDLE);
}

/**
 * @brief Gets the infect sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundInfectID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class infect sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDINFECT);
}

/**
 * @brief Gets the respawn sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundRespawnID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class respawn sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDRESPAWN);
}

/**
 * @brief Gets the burn sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundBurnID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class idle sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDBURN);
}

/**
 * @brief Gets the attack sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundAttackID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class idle sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDATTACK);
}

/**
 * @brief Gets the footstep sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundFootID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class footstep sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDFOOTSTEP);
}

/**
 * @brief Gets the regeneration sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundRegenID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class regeneration sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDREGEN);
}

/**
 * @brief Gets the leap jump sound key of the class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
int ClassGetSoundJumpID(int iD)
{
    // Gets array handle of class at given index
    ArrayList arrayClass = gServerData.Classes.Get(iD);

    // Gets class leap jump sound key
    return arrayClass.Get(CLASSES_DATA_SOUNDJUMP);
}

/*
 * Stocks classes API.
 */

/**
 * @brief Find the index at which the class name is at.
 * 
 * @param sName             The class name.
 * @return                  The array index containing the given class name.
 **/
int ClassNameToIndex(char[] sName)
{
    // Initialize name char
    static char sClassname[SMALL_LINE_LENGTH];
    
    // i = class index
    int iSize = gServerData.Classes.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets class name 
        ClassGetName(i, sClassname, sizeof(sClassname));
        
        // If names match, then return index
        if(!strcmp(sName, sClassname, false))
        {
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return -1;
}

/**
 * @brief Find the random index at which the class type is at.
 * 
 * @param sType             The class type.
 * @return                  The array index containing the given class type.
 **/
int ClassTypeToIndex(char[] sType)
{
    // Initialize type char
    static char sClassType[SMALL_LINE_LENGTH]; 
    
    // i = class index
    int iSize = gServerData.Classes.Length; int iRandom; static int class[MAXPLAYERS+1];
    for(int i = 0; i < iSize; i++)
    {
        // Gets class type 
        ClassGetType(i, sClassType, sizeof(sClassType));
        
        // If types match, then store index
        if(!strcmp(sClassType, sType, false))
        {
            // Increment amount
            class[iRandom++] = i;
        }
    }
    
    // Return index
    return (iRandom) ? class[GetRandomInt(0, iRandom-1)] : -1;
}