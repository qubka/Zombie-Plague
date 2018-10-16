/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          zombieclases.cpp
 *  Type:          Manager 
 *  Description:   Zombie classes generator.
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
 * Number of max valid zombie classes.
 **/
#define ZombieClassMax 64
 
/**
 * Array handle to store zombie class native data.
 **/
ArrayList arrayZombieClasses;

/**
 * Zombie native data indexes.
 **/
enum
{
    ZOMBIECLASSES_DATA_NAME,
    ZOMBIECLASSES_DATA_INFO,
    ZOMBIECLASSES_DATA_MODEL,
    ZOMBIECLASSES_DATA_CLAW,
    ZOMBIECLASSES_DATA_GRENADE,
    ZOMBIECLASSES_DATA_HEALTH,
    ZOMBIECLASSES_DATA_SPEED,
    ZOMBIECLASSES_DATA_GRAVITY,
    ZOMBIECLASSES_DATA_KNOCKBACK,
    ZOMBIECLASSES_DATA_LEVEL,
    ZOMBIECLASSES_DATA_GROUP,
    ZOMBIECLASSES_DATA_DURATION,
    ZOMBIECLASSES_DATA_COUNTDOWN,
    ZOMBIECLASSES_DATA_REGENHEALTH,
    ZOMBIECLASSES_DATA_REGENINTERVAL,
    ZOMBIECLASSES_DATA_CLAW_ID,
    ZOMBIECLASSES_DATA_GRENADE_ID,
    ZOMBIECLASSES_DATA_SOUNDDEATH,
    ZOMBIECLASSES_DATA_SOUNDHURT,
    ZOMBIECLASSES_DATA_SOUNDIDLE,
    ZOMBIECLASSES_DATA_SOUNDRESPAWN,
    ZOMBIECLASSES_DATA_SOUNDBURN,
    ZOMBIECLASSES_DATA_SOUNDATTACK,
    ZOMBIECLASSES_DATA_SOUNDFOOTSTEP,
    ZOMBIECLASSES_DATA_SOUNDREGEN,
    ZOMBIECLASSES_DATA_SOUNDDEATH_ID,
    ZOMBIECLASSES_DATA_SOUNDHURT_ID,
    ZOMBIECLASSES_DATA_SOUNDIDLE_ID,
    ZOMBIECLASSES_DATA_SOUNDRESPAWN_ID,
    ZOMBIECLASSES_DATA_SOUNDBURN_ID,
    ZOMBIECLASSES_DATA_SOUNDATTACK_ID,
    ZOMBIECLASSES_DATA_SOUNDFOOTSTEP_ID,
    ZOMBIECLASSES_DATA_SOUNDREGEN_ID
}

/**
 * Initialization of zombie classes. 
 **/
void ZombieClassesLoad(/*void*/)
{
    // No zombie classes?
    if(arrayZombieClasses == INVALID_HANDLE)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Zombie Class Validation", "No zombie classes loaded");
    }

    // Initialize variable
    static char sBuffer[PLATFORM_MAX_PATH];

    // Precache of the zombie classes
    int iSize = arrayZombieClasses.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Validate player model
        ZombieGetModel(i, sBuffer, sizeof(sBuffer));
        if(!ModelsPrecacheStatic(sBuffer))
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Model Validation", "Invalid model path. File not found: \"%s\"", sBuffer);
        }

        // Validate claw model
        ZombieGetClawModel(i, sBuffer, sizeof(sBuffer));
        ZombieSetClawID(i, ModelsPrecacheWeapon(sBuffer));
        
        // Validate grenade model
        ZombieGetGrenadeModel(i, sBuffer, sizeof(sBuffer));
        ZombieSetGrenadeID(i, ModelsPrecacheWeapon(sBuffer));

        // Load death sounds
        ZombieGetSoundDeath(i, sBuffer, sizeof(sBuffer));
        ZombieSetSoundDeathID(i, SoundsKeyToIndex(sBuffer));

        // Load hurt sounds
        ZombieGetSoundHurt(i, sBuffer, sizeof(sBuffer));
        ZombieSetSoundHurtID(i, SoundsKeyToIndex(sBuffer));

        // Load idle sounds
        ZombieGetSoundIdle(i, sBuffer, sizeof(sBuffer));
        ZombieSetSoundIdleID(i, SoundsKeyToIndex(sBuffer));

        // Load respawn sounds
        ZombieGetSoundRespawn(i, sBuffer, sizeof(sBuffer));
        ZombieSetSoundRespawnID(i, SoundsKeyToIndex(sBuffer));

        // Load burn sounds
        ZombieGetSoundBurn(i, sBuffer, sizeof(sBuffer));
        ZombieSetSoundBurnID(i, SoundsKeyToIndex(sBuffer));

        // Load attack sounds    
        ZombieGetSoundAttack(i, sBuffer, sizeof(sBuffer));
        ZombieSetSoundAttackID(i, SoundsKeyToIndex(sBuffer));

        // Load footstep sounds
        ZombieGetSoundFoot(i, sBuffer, sizeof(sBuffer));
        ZombieSetSoundFootID(i, SoundsKeyToIndex(sBuffer));

        // Load regen sounds
        ZombieGetSoundRegen(i, sBuffer, sizeof(sBuffer));
        ZombieSetSoundRegenID(i, SoundsKeyToIndex(sBuffer));
    }
}

/**
 * Creates commands for zombie classes module. Called when commands are created.
 **/
void ZombieOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zzombieclassmenu", ZombieCommandCatched, "Open the zombie classes menu.");
}

/**
 * Handles the <!zzombieclassmenu> command. Open the zombie classes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZombieCommandCatched(const int clientIndex, const int iArguments)
{
    // Open the zombie classes menu
    ZombieMenu(clientIndex);
    return Plugin_Handled;
}

/*
 * Zombie classes natives API.
 */

/**
 * Gets the amount of all zombie classes.
 *
 * native int ZP_GetNumberZombieClass();
 **/
public int API_GetNumberZombieClass(Handle isPlugin, const int iNumParams)
{
    // Return the value 
    return arrayZombieClasses.Length;
}

/**
 * Gets the zombie class index of the client.
 *
 * native int ZP_GetClientZombieClass(clientIndex);
 **/
public int API_GetClientZombieClass(Handle isPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_ZombieClass];
}

/**
 * Gets the zombie next class index of the client.
 *
 * native int ZP_GetClientZombieClassNext(clientIndex);
 **/
public int API_GetClientZombieClassNext(Handle isPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_ZombieClassNext];
}

/**
 * Sets the zombie class index to the client.
 *
 * native void ZP_SetClientZombieClass(clientIndex, iD);
 **/
public int API_SetClientZombieClass(Handle isPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Call forward
    Action resultHandle = API_OnClientValidateZombieClass(clientIndex, iD);

    // Validate handle
    if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
    {
        // Sets next class to the client
        gClientData[clientIndex][Client_ZombieClassNext] = iD;
    }

    // Return on success
    return iD;
}

/**
 * Load zombie class from other plugin.
 *
 * native int ZP_RegisterZombieClass(name, model, claw_model, gren_model, health, speed, gravity, vip, duration, countdown, death, hurt, idle, respawn, burn, attack, foot, regen)
 **/
public int API_RegisterZombieClass(Handle isPlugin, const int iNumParams)
{
    // If array hasn't been created, then create
    if(arrayZombieClasses == INVALID_HANDLE)
    {
        // Create array in handle
        arrayZombieClasses = CreateArray(ZombieClassMax);
    }

    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);
    
    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Can't register zombie class with an empty name");
        return -1;
    }
    
    // Gets zombie classes amount
    int iCount = arrayZombieClasses.Length;
    
    // Maximum amout reached ?
    if(iCount >= ZombieClassMax)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Maximum number of zombie classes reached (%d). Skipping other classes.", ZombieClassMax);
        return -1;
    }

    // Initialize variables
    char sZombieBuffer[PLATFORM_MAX_PATH];
    char sZombieName[SMALL_LINE_LENGTH];

    // General
    GetNativeString(1, sZombieBuffer, sizeof(sZombieBuffer)); 
    
    // i = zombie class number
    for(int i = 0; i < iCount; i++)
    {
        // Gets the name of a zombie class at a given index
        ZombieGetName(i, sZombieName, sizeof(sZombieName));
    
        // If names match, then stop
        if(!strcmp(sZombieBuffer, sZombieName, false))
        {
            return i;
        }
    }
    
    // Validate translation
    if(!TranslationPhraseExists(sZombieBuffer))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Couldn't cache zombie class name: \"%s\" (check translation file)", sZombieBuffer);
        return -1;
    }
    
    // Initialize array block
    ArrayList arrayZombieClass = CreateArray(ZombieClassMax);
    
    // Push native data into array
    arrayZombieClass.PushString(sZombieBuffer); // Index: 0
    GetNativeString(2, sZombieBuffer, sizeof(sZombieBuffer));
    if(!TranslationPhraseExists(sZombieBuffer) && strlen(sZombieBuffer))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Couldn't cache zombie class info: \"%s\" (check translation file)", sZombieBuffer);
        return -1;
    }
    arrayZombieClass.PushString(sZombieBuffer); // Index: 1
    GetNativeString(3, sZombieBuffer, sizeof(sZombieBuffer));  
    arrayZombieClass.PushString(sZombieBuffer); // Index: 2
    GetNativeString(4, sZombieBuffer, sizeof(sZombieBuffer));   
    arrayZombieClass.PushString(sZombieBuffer); // Index: 3
    GetNativeString(5, sZombieBuffer, sizeof(sZombieBuffer)); 
    arrayZombieClass.PushString(sZombieBuffer); // Index: 4
    arrayZombieClass.Push(GetNativeCell(6));    // Index: 5
    arrayZombieClass.Push(GetNativeCell(7));    // Index: 6
    arrayZombieClass.Push(GetNativeCell(8));    // Index: 7
    arrayZombieClass.Push(GetNativeCell(9));    // Index: 8
    arrayZombieClass.Push(GetNativeCell(10));   // Index: 9
    GetNativeString(11, sZombieBuffer, sizeof(sZombieBuffer));   
    arrayZombieClass.PushString(sZombieBuffer); // Index: 10
    arrayZombieClass.Push(GetNativeCell(12));   // Index: 11
    arrayZombieClass.Push(GetNativeCell(13));   // Index: 12
    arrayZombieClass.Push(GetNativeCell(14));   // Index: 13
    arrayZombieClass.Push(GetNativeCell(15));   // Index: 14
    arrayZombieClass.Push(0);                   // Index: 15
    arrayZombieClass.Push(0);                   // Index: 16
    GetNativeString(16, sZombieBuffer, sizeof(sZombieBuffer));   
    arrayZombieClass.PushString(sZombieBuffer); // Index: 17
    GetNativeString(17, sZombieBuffer, sizeof(sZombieBuffer)); 
    arrayZombieClass.PushString(sZombieBuffer); // Index: 18
    GetNativeString(18, sZombieBuffer, sizeof(sZombieBuffer)); 
    arrayZombieClass.PushString(sZombieBuffer); // Index: 19
    GetNativeString(19, sZombieBuffer, sizeof(sZombieBuffer));
    arrayZombieClass.PushString(sZombieBuffer); // Index: 20
    GetNativeString(20, sZombieBuffer, sizeof(sZombieBuffer)); 
    arrayZombieClass.PushString(sZombieBuffer); // Index: 21
    GetNativeString(21, sZombieBuffer, sizeof(sZombieBuffer));  
    arrayZombieClass.PushString(sZombieBuffer); // Index: 22
    GetNativeString(22, sZombieBuffer, sizeof(sZombieBuffer)); 
    arrayZombieClass.PushString(sZombieBuffer); // Index: 23
    GetNativeString(23, sZombieBuffer, sizeof(sZombieBuffer));   
    arrayZombieClass.PushString(sZombieBuffer); // Index: 24
    arrayZombieClass.Push(-1);                  // Index: 25
    arrayZombieClass.Push(-1);                  // Index: 26
    arrayZombieClass.Push(-1);                  // Index: 27
    arrayZombieClass.Push(-1);                  // Index: 28
    arrayZombieClass.Push(-1);                  // Index: 29
    arrayZombieClass.Push(-1);                  // Index: 30
    arrayZombieClass.Push(-1);                  // Index: 31
    arrayZombieClass.Push(-1);                  // Index: 32

    // Store this handle in the main array
    arrayZombieClasses.Push(arrayZombieClass);

    // Return id under which we registered the class
    return arrayZombieClasses.Length-1;
}

/**
 * Gets the name of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassName(iD, name, maxlen);
 **/
public int API_GetZombieClassName(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    ZombieGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the info of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassInfo(iD, info, maxlen);
 **/
public int API_GetZombieClassInfo(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize info char
    static char sInfo[BIG_LINE_LENGTH];
    ZombieGetInfo(iD, sInfo, sizeof(sInfo));

    // Return on success
    return SetNativeString(2, sInfo, maxLen);
}

/**
 * Gets the player model of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassModel(iD, model, maxlen);
 **/
public int API_GetZombieClassModel(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    ZombieGetModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the knife model of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassClaw(iD, model, maxlen);
 **/
public int API_GetZombieClassClaw(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    ZombieGetClawModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the grenade model of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassGrenade(iD, model, maxlen);
 **/
public int API_GetZombieClassGrenade(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    ZombieGetGrenadeModel(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the health of the zombie class.
 *
 * native int ZP_GetZombieClassHealth(iD);
 **/
public int API_GetZombieClassHealth(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ZombieGetHealth(iD);
}

/**
 * Gets the speed of the zombie class.
 *
 * native float ZP_GetZombieClassSpeed(iD);
 **/
public int API_GetZombieClassSpeed(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ZombieGetSpeed(iD));
}

/**
 * Gets the gravity of the zombie class.
 *
 * native float ZP_GetZombieClassGravity(iD);
 **/
public int API_GetZombieClassGravity(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ZombieGetGravity(iD));
}

/**
 * Gets the knockback of the zombie class.
 *
 * native float ZP_GetZombieClassKnockBack(iD);
 **/
public int API_GetZombieClassKnockBack(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ZombieGetKnockBack(iD));
}

/**
 * Gets the level of the zombie class.
 *
 * native int ZP_GetZombieClassLevel(iD);
 **/
public int API_GetZombieClassLevel(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ZombieGetLevel(iD);
}

/**
 * Gets the group of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassGroup(iD, group, maxlen);
 **/
public int API_GetZombieClassGroup(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize group char
    static char sGroup[PLATFORM_MAX_PATH];
    ZombieGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * Gets the skill duration of the zombie class.
 *
 * native float ZP_GetZombieClassSkillDuration(iD);
 **/
public int API_GetZombieClassSkillDuration(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ZombieGetSkillDuration(iD));
}

/**
 * Gets the skill countdown of the zombie class.
 *
 * native float ZP_GetZombieClassSkillCountdown(iD);
 **/
public int API_GetZombieClassSkillCountdown(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ZombieGetSkillCountDown(iD));
}

/**
 * Gets the regen of the zombie class.
 *
 * native int ZP_GetZombieClassRegen(iD);
 **/
public int API_GetZombieClassRegen(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ZombieGetRegenHealth(iD);
}

/**
 * Gets the regen interval of the zombie class.
 *
 * native float ZP_GetZombieClassRegenInterval(iD);
 **/
public int API_GetZombieClassRegenInterval(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(ZombieGetRegenInterval(iD));
}

/**
 * Gets the index of the zombie class claw model.
 *
 * native int ZP_GetZombieClassClawID(iD);
 **/
public int API_GetZombieClassClawID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ZombieGetClawID(iD);
}

/**
 * Gets the index of the zombie class grenade model.
 *
 * native int ZP_GetZombieClassGrenadeID(iD);
 **/
public int API_GetZombieClassGrenadeID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ZombieGetGrenadeID(iD);
}

/**
 * Gets the death sound key of the zombie class.
 *
 * native void ZP_GetZombieClassSoundDeathID(iD);
 **/
public int API_GetZombieClassSoundDeathID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ZombieGetSoundDeathID(iD);
}

/**
 * Gets the hurt sound key of the zombie class.
 *
 * native void ZP_GetZombieClassSoundHurtID(iD);
 **/
public int API_GetZombieClassSoundHurtID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ZombieGetSoundHurtID(iD);
}

/**
 * Gets the idle sound key of the zombie class.
 *
 * native void ZP_GetZombieClassSoundIdleID(iD);
 **/
public int API_GetZombieClassSoundIdleID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ZombieGetSoundIdleID(iD);
}

/**
 * Gets the respawn sound key of the zombie class.
 *
 * native void ZP_GetZombieClassSoundRespawnID(iD);
 **/
public int API_GetZombieClassSoundRespawnID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ZombieGetSoundRespawnID(iD);
}

/**
 * Gets the burn sound key of the zombie class.
 *
 * native void ZP_GetZombieClassSoundBurnID(iD);
 **/
public int API_GetZombieClassSoundBurnID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ZombieGetSoundBurnID(iD);
}

/**
 * Gets the attack sound key of the zombie class.
 *
 * native void ZP_GetZombieClassSoundAttackID(iD);
 **/
public int API_GetZombieClassSoundAttackID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ZombieGetSoundAttackID(iD);
}

/**
 * Gets the footstep sound key of the zombie class.
 *
 * native void ZP_GetZombieClassSoundFootID(iD);
 **/
public int API_GetZombieClassSoundFootID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ZombieGetSoundFootID(iD);
}

/**
 * Gets the regeneration sound key of the zombie class.
 *
 * native void ZP_GetZombieClassSoundRegenID(iD);
 **/
public int API_GetZombieClassSoundRegenID(Handle isPlugin, const int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Return value
    return ZombieGetSoundRegenID(iD);
}

/**
 * Print the info about the zombie class.
 *
 * native void ZP_PrintZombieClassInfo(clientIndex, iD);
 **/
public int API_PrintZombieClassInfo(Handle isPlugin, const int iNumParams)
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
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Player doens't exist (%d)", clientIndex);
        return -1;
    }
    
    // Gets class index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= arrayZombieClasses.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Gets zombie name
    static char sZombieName[SMALL_LINE_LENGTH];
    ZombieGetName(iD, sZombieName, sizeof(sZombieName));

    // If help messages enabled, show info
    TranslationPrintToChat(clientIndex, "zombie info", sZombieName, ZombieGetHealth(iD), ZombieGetSpeed(iD), ZombieGetGravity(iD));
    
    // Return on success
    return sizeof(sZombieName);
}

/*
 * Zombie classes data reading API.
 */

/**
 * Gets the name of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class name
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the info of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sInfo             The string to return info in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetInfo(const int iD, char[] sInfo, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class info
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_INFO, sInfo, iMaxLen);
}

/**
 * Gets the player model of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class model
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_MODEL, sModel, iMaxLen);
}

/**
 * Gets the knife model of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetClawModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class claw model
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_CLAW, sModel, iMaxLen);
}

/**
 * Gets the grenade model of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetGrenadeModel(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class grenade model
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_GRENADE, sModel, iMaxLen);
}

/**
 * Gets the health of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The health amount.    
 **/
stock int ZombieGetHealth(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class health
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_HEALTH);
}

/**
 * Gets the speed of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The speed amount.    
 **/
stock float ZombieGetSpeed(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class speed 
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SPEED);
}

/**
 * Gets the gravity of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The gravity amount.    
 **/
stock float ZombieGetGravity(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class speed 
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_GRAVITY);
}

/**
 * Gets the knockback of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The knockback amount.    
 **/
stock float ZombieGetKnockBack(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class knockback 
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_KNOCKBACK);
}

/**
 * Gets the level of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The level amount.    
 **/
stock int ZombieGetLevel(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class level 
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_LEVEL);
}

/**
 * Gets the access group of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetGroup(const int iD, char[] sGroup, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class group
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * Gets the skill duration of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The duration amount.    
 **/
stock float ZombieGetSkillDuration(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class skill duration 
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_DURATION);
}

/**
 * Gets the skill countdown of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The countdown amount.    
 **/
stock float ZombieGetSkillCountDown(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class skill countdown  
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_COUNTDOWN);
}

/**
 * Gets the regen amount of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The health amount.    
 **/
stock int ZombieGetRegenHealth(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class regen health
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_REGENHEALTH);
}

/**
 * Gets the regen interval of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The interval amount.    
 **/
stock float ZombieGetRegenInterval(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class regen interval
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_REGENINTERVAL);
}

/**
 * Gets the index of the zombie class claw model.
 *
 * @param iD                The class index.
 * @return                  The model index.    
 **/
stock int ZombieGetClawID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class claw model index
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_CLAW_ID);
}

/**
 * Sets the index of the zombie class claw model.
 *
 * @param iD                The class index.
 * @param modelIndex        The model index.    
 **/
stock void ZombieSetClawID(const int iD, const int modelIndex)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets knife model index
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_CLAW_ID, modelIndex);
}

/**
 * Gets the index of the zombie class grenade model.
 *
 * @param iD                The class index.
 * @return                  The model index.    
 **/
stock int ZombieGetGrenadeID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class grenade model index
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_GRENADE_ID);
}

/**
 * Sets the index of the zombie class grenade model.
 *
 * @param iD                The class index.
 * @param modelIndex        The model index.    
 **/
stock void ZombieSetGrenadeID(const int iD, const int modelIndex)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets knife model index
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_GRENADE_ID, modelIndex);
}

/**
 * Gets the death sound of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetSoundDeath(const int iD, char[] sSound, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class death sound
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_SOUNDDEATH, sSound, iMaxLen);
}

/**
 * Gets the death sound key of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ZombieGetSoundDeathID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class death sound key
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SOUNDDEATH_ID);
}

/**
 * Sets the death sound key of the zombie class.
 *
 * @param iD                The class index.
 * @param iKey              The key index.
 **/
stock void ZombieSetSoundDeathID(const int iD, const int iKey)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets zombie class death sound key
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_SOUNDDEATH_ID, iKey);
}

/**
 * Gets the hurt sound of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetSoundHurt(const int iD, char[] sSound, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class hurt sound
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_SOUNDHURT, sSound, iMaxLen);
}

/**
 * Gets the hurt sound key of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ZombieGetSoundHurtID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class hurt sound key
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SOUNDHURT_ID);
}

/**
 * Sets the hurt sound key of the zombie class.
 *
 * @param iD                The class index.
 * @param iKey              The key index.
 **/
stock void ZombieSetSoundHurtID(const int iD, const int iKey)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets zombie class hurt sound key
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_SOUNDHURT_ID, iKey);
}

/**
 * Gets the idle sound of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetSoundIdle(const int iD, char[] sSound, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class idle sound
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_SOUNDIDLE, sSound, iMaxLen);
}

/**
 * Gets the idle sound key of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ZombieGetSoundIdleID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class idle sound key
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SOUNDIDLE_ID);
}

/**
 * Sets the idle sound key of the zombie class.
 *
 * @param iD                The class index.
 * @param iKey              The key index.
 **/
stock void ZombieSetSoundIdleID(const int iD, const int iKey)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets zombie class idle sound key
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_SOUNDIDLE_ID, iKey);
}

/**
 * Gets the respawn sound of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetSoundRespawn(const int iD, char[] sSound, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class respawn sound
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_SOUNDRESPAWN, sSound, iMaxLen);
}

/**
 * Gets the respawn sound key of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ZombieGetSoundRespawnID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class respawn sound key
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SOUNDRESPAWN_ID);
}

/**
 * Sets the respawn sound key of the zombie class.
 *
 * @param iD                The class index.
 * @param iKey              The key index.
 **/
stock void ZombieSetSoundRespawnID(const int iD, const int iKey)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets zombie class respawn sound key
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_SOUNDRESPAWN_ID, iKey);
}

/**
 * Gets the burn sound of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetSoundBurn(const int iD, char[] sSound, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class idle sound
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_SOUNDBURN, sSound, iMaxLen);
}

/**
 * Gets the burn sound key of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ZombieGetSoundBurnID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class idle sound key
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SOUNDBURN_ID);
}

/**
 * Sets the burn sound key of the zombie class.
 *
 * @param iD                The class index.
 * @param iKey              The key index.
 **/
stock void ZombieSetSoundBurnID(const int iD, const int iKey)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets zombie class idle sound key
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_SOUNDBURN_ID, iKey);
}

/**
 * Gets the attack sound of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetSoundAttack(const int iD, char[] sSound, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class idle sound
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_SOUNDATTACK, sSound, iMaxLen);
}

/**
 * Gets the attack sound key of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ZombieGetSoundAttackID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class idle sound key
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SOUNDATTACK_ID);
}

/**
 * Sets the attack sound key of the zombie class.
 *
 * @param iD                The class index.
 * @param iKey              The key index.
 **/
stock void ZombieSetSoundAttackID(const int iD, const int iKey)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets zombie class idle sound key
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_SOUNDATTACK_ID, iKey);
}

/**
 * Gets the footstep sound of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetSoundFoot(const int iD, char[] sSound, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class footstep sound
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_SOUNDFOOTSTEP, sSound, iMaxLen);
}

/**
 * Gets the footstep sound key of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ZombieGetSoundFootID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class footstep sound key
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SOUNDFOOTSTEP_ID);
}

/**
 * Sets the footstep sound key of the zombie class.
 *
 * @param iD                The class index.
 * @param iKey              The key index.
 **/
stock void ZombieSetSoundFootID(const int iD, const int iKey)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets zombie class footstep sound key
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_SOUNDFOOTSTEP_ID, iKey);
}

/**
 * Gets the regeneration sound of a zombie class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ZombieGetSoundRegen(const int iD, char[] sSound, const int iMaxLen)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class regeneration sound
    arrayZombieClass.GetString(ZOMBIECLASSES_DATA_SOUNDREGEN, sSound, iMaxLen);
}

/**
 * Gets the regeneration sound key of the zombie class.
 *
 * @param iD                The class index.
 * @return                  The key index.
 **/
stock int ZombieGetSoundRegenID(const int iD)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Gets zombie class regeneration sound key
    return arrayZombieClass.Get(ZOMBIECLASSES_DATA_SOUNDREGEN_ID);
}

/**
 * Sets the regeneration sound key of the zombie class.
 *
 * @param iD                The class index.
 * @param iKey              The key index.
 **/
stock void ZombieSetSoundRegenID(const int iD, const int iKey)
{
    // Gets array handle of zombie class at given index
    ArrayList arrayZombieClass = arrayZombieClasses.Get(iD);

    // Sets zombie class regeneration sound key
    arrayZombieClass.Set(ZOMBIECLASSES_DATA_SOUNDREGEN_ID, iKey);
}

/*
 * Stocks zombie classes API.
 */

/**
 * Validate zombie class for client availability.
 *
 * @param clientIndex       The client index.
 **/
void ZombieOnValidate(const int clientIndex)
{
    // Gets array size
    int iSize = arrayZombieClasses.Length;

    // Choose random zombie class for the client
    if(IsFakeClient(clientIndex) || iSize <= gClientData[clientIndex][Client_ZombieClass])
    {
        gClientData[clientIndex][Client_ZombieClass] = GetRandomInt(0, iSize-1);
    }
    
    // Gets class group
    static char sGroup[SMALL_LINE_LENGTH];
    ZombieGetGroup(gClientData[clientIndex][Client_ZombieClass], sGroup, sizeof(sGroup));
    
    // Validate that user does not have VIP flag to play it
    if(!IsPlayerInGroup(clientIndex, sGroup) && strlen(sGroup))
    {
        // Choose any accessable zombie class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable zombie classes
            ZombieGetGroup(i, sGroup, sizeof(sGroup));
            if(!IsPlayerInGroup(clientIndex, sGroup) && strlen(sGroup))
            {
                continue;
            }
            
            // Update zombie class
            gClientData[clientIndex][Client_ZombieClassNext]  = i;
            gClientData[clientIndex][Client_ZombieClass] = i;
            break;
        }
    }
    
    // Validate that user does not have level to play it
    if(ZombieGetLevel(gClientData[clientIndex][Client_ZombieClass]) > gClientData[clientIndex][Client_Level])
    {
        // Choose any accessable zombie class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable zombie classes
            if(ZombieGetLevel(i) > gClientData[clientIndex][Client_Level])
            {
                continue;
            }
            
            // Update zombie class
            gClientData[clientIndex][Client_ZombieClassNext]  = i;
            gClientData[clientIndex][Client_ZombieClass] = i;
            break;
        }
    }
}

/**
 * Create the zombie class menu.
 *
 * @param clientIndex       The client index.
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/
void ZombieMenu(const int clientIndex, const bool bInstant = false) 
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
    Menu hMenu = CreateMenu(bInstant ? ZombieMenuSlots2 : ZombieMenuSlots1);

    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "choose zombieclass");
    
    // Initialize forward
    static Action resultHandle;
    
    // i = Zombie class number
    int iCount = arrayZombieClasses.Length;
    for(int i = 0; i < iCount; i++)
    {
        // Call forward
        resultHandle = API_OnClientValidateZombieClass(clientIndex, i);
        
        // Skip, if class is disabled
        if(resultHandle == Plugin_Stop)
        {
            continue;
        }
        
        // Gets zombie class data
        ZombieGetName(i, sName, sizeof(sName));
        ZombieGetGroup(i, sGroup, sizeof(sGroup));

        // Format some chars for showing in menu
        Format(sLevel, sizeof(sLevel), "%t", "level", ZombieGetLevel(i));
        Format(sBuffer, sizeof(sBuffer), "%t\t%s", sName, (!IsPlayerInGroup(clientIndex, sGroup) && strlen(sGroup)) ? sGroup : (gClientData[clientIndex][Client_Level] < ZombieGetLevel(i)) ? sLevel : "");
        
        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(resultHandle == Plugin_Handled || ((!IsPlayerInGroup(clientIndex, sGroup) && strlen(sGroup)) || gClientData[clientIndex][Client_Level] < ZombieGetLevel(i) || gClientData[clientIndex][Client_ZombieClassNext] == i) ? false : true));
    }

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, bInstant ? MENU_TIME_INSTANT : MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZombieMenuSlots1(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   ZombieMenuSlots(hMenu, mAction, clientIndex, mSlot);
}

/**
 * Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZombieMenuSlots2(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   ZombieMenuSlots(hMenu, mAction, clientIndex, mSlot, true);
}

/**
 * Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/ 
void ZombieMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot, const bool bInstant = false)
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

            // Gets ID of zombie class
            hMenu.GetItem(mSlot, sInfo, sizeof(sInfo));
            int iD = StringToInt(sInfo);
            
            // Call forward
            Action resultHandle = API_OnClientValidateZombieClass(clientIndex, iD);

            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Validate instant change
                if(bInstant)
                {
                    // Validate zombie
                    if(!gClientData[clientIndex][Client_Zombie] || gClientData[clientIndex][Client_Nemesis])
                    {
                        return;
                    }
                    
                    // Force client to switch player class
                    ClassMakeZombie(clientIndex, _, _, true);
                }
                else
                {
                    // Sets next zombie class
                    gClientData[clientIndex][Client_ZombieClassNext] = iD;
                }
                
                // Gets zombie name
                ZombieGetName(iD, sInfo, sizeof(sInfo));

                // If help messages enabled, show info
                if(gCvarList[CVAR_MESSAGES_HELP].BoolValue) TranslationPrintToChat(clientIndex, "zombie info", sInfo, ZombieGetHealth(iD), ZombieGetSpeed(iD), ZombieGetGravity(iD));
            }
        }
    }
}