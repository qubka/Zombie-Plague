/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          hitgroup.cpp
 *  Type:          Manager 
 *  Description:   API for loading hitgroup specific settings.
 *
 *  Copyright (C) 2015-2019 Greyscale, Richard Helgeby
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
 * @section Player hitgroup values.
 **/
#define HITGROUP_GENERIC    0
#define HITGROUP_HEAD       1
#define HITGROUP_CHEST      2
#define HITGROUP_STOMACH    3
#define HITGROUP_LEFTARM    4
#define HITGROUP_RIGHTARM   5
#define HITGROUP_LEFTLEG    6
#define HITGROUP_RIGHTLEG   7
#define HITGROUP_GEAR       8
/**
 * @endsection
 **/

/**
 * @section Group config data indexes.
 **/
enum
{
    HITGROUPS_DATA_NAME = 0,
    HITGROUPS_DATA_INDEX,
    HITGROUPS_DATA_DAMAGE,
    HITGROUPS_DATA_KNOCKBACK,
    HITGROUPS_DATA_ARMOR,
    HITGROUPS_DATA_BONUS,
    HITGROUPS_DATA_HEAVY,
    HITGROUPS_DATA_PROTECT
};
/**
 * @endsection
 **/
 
/**
 * @brief Hit groups module init function.
 **/ 
void HitGroupsOnInit(/*void*/)
{
    // Validate loaded map
    if(gServerData.MapLoaded)
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i, false))
            {
                // Update the client data
                HitGroupsOnClientInit(i);
            }
        }
    } 
    
    // Prepare all hitgroup data
    HitGroupsOnLoad();
}

/**
 * @brief Prepare all hitgroup data.
 **/
void HitGroupsOnLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_HitGroups, Structure_Keyvalue, CONFIG_FILE_ALIAS_HITGROUPS);

    // If hitgroups is disabled, then stop
    if(!gCvarList[CVAR_HITGROUP].BoolValue)
    {
        return;
    }

    // Gets hitgroups config path
    static char sPathGroups[PLATFORM_LINE_LENGTH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_HITGROUPS, sPathGroups);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_HitGroups, "Config Validation", "Missing hitgroups config file: %s", sPathGroups);
        return;
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_HitGroups, sPathGroups);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_HitGroups, gServerData.HitGroups);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_HitGroups, "Config Validation", "Unexpected error encountered loading: %s", sPathGroups);
        return;
    }
    
    // Now copy data to array structure
    HitGroupsOnCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_HitGroups, true);
    ConfigSetConfigReloadFunc(File_HitGroups, GetFunctionByName(GetMyHandle(), "HitGroupsOnConfigReload"));
    ConfigSetConfigHandle(File_HitGroups, gServerData.HitGroups);
}

/**
 * @brief Caches hitgroup data from file into arrays.
 **/
void HitGroupsOnCacheData(/*void*/)
{
    // Gets config file path
    static char sPathGroups[PLATFORM_LINE_LENGTH];
    ConfigGetConfigPath(File_HitGroups, sPathGroups, sizeof(sPathGroups)); 
    
    // Opens config
    KeyValues kvHitGroups;
    bool bSuccess = ConfigOpenConfigFile(File_HitGroups, kvHitGroups);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_HitGroups, "Config Validation", "Unexpected error caching data from hitgroups config file: %s", sPathGroups);
        return;
    }
    
    // Validate size
    int iSize = gServerData.HitGroups.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_HitGroups, "Config Validation", "No usable data found in hitgroups config file: %s", sPathGroups);
        return;
    }

    // i = array index
    for(int i = 0; i < iSize; i++)
    {
        // General
        HitGroupsGetName(i, sPathGroups, sizeof(sPathGroups)); // Index: 0
        kvHitGroups.Rewind();
        if(!kvHitGroups.JumpToKey(sPathGroups))
        {
            LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_HitGroups, "Config Validation", "Couldn't cache hitgroup data for: %s (check hitgroup config)", sPathGroups);
            continue;
        }

        // Gets array size
        ArrayList arrayHitGroup = gServerData.HitGroups.Get(i);
        
        // Push data into array
        arrayHitGroup.Push(kvHitGroups.GetNum("index", -1));                      // Index: 1
        arrayHitGroup.Push(ConfigKvGetStringBool(kvHitGroups, "damage", "on"));   // Index: 2
        arrayHitGroup.Push(kvHitGroups.GetFloat("knockback", 1.0));               // Index: 3
        arrayHitGroup.Push(kvHitGroups.GetFloat("armor", 0.5));                   // Index: 4
        arrayHitGroup.Push(kvHitGroups.GetFloat("bonus", 0.5));                   // Index: 5
        arrayHitGroup.Push(kvHitGroups.GetFloat("heavy", 0.5));                   // Index: 6
        arrayHitGroup.Push(ConfigKvGetStringBool(kvHitGroups, "protect", "yes")); // Index: 7
    }
    
    // We're done with this file now, so we can close it
    delete kvHitGroups;
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void HitGroupsOnConfigReload(/*void*/)
{
    // Reloads hitgroups config
    HitGroupsOnLoad();
}

/**
 * @brief Hook hitgroups cvar changes.
 **/
void HitGroupsOnCvarInit(/*void*/)
{
    // Creates cvars
    gCvarList[CVAR_HITGROUP]                  = FindConVar("zp_hitgroup"); 
    gCvarList[CVAR_HITGROUP_FRIENDLY_FIRE]    = FindConVar("mp_friendlyfire");
    gCvarList[CVAR_HITGROUP_FRIENDLY_GRENADE] = FindConVar("ff_damage_reduction_grenade");
    gCvarList[CVAR_HITGROUP_FRIENDLY_BULLETS] = FindConVar("ff_damage_reduction_bullets");
    gCvarList[CVAR_HITGROUP_FRIENDLY_OTHER]   = FindConVar("ff_damage_reduction_other");
    gCvarList[CVAR_HITGROUP_FRIENDLY_SELF]    = FindConVar("ff_damage_reduction_grenade_self");
    
    // Sets locked cvars to their locked value
    gCvarList[CVAR_HITGROUP_FRIENDLY_FIRE].IntValue          = 0;
    CvarsOnCheatSet(gCvarList[CVAR_HITGROUP_FRIENDLY_GRENADE], 0);
    CvarsOnCheatSet(gCvarList[CVAR_HITGROUP_FRIENDLY_BULLETS], 0);
    CvarsOnCheatSet(gCvarList[CVAR_HITGROUP_FRIENDLY_OTHER],   0);
    CvarsOnCheatSet(gCvarList[CVAR_HITGROUP_FRIENDLY_SELF],    0);

    // Hook locked cvars to prevent it from changing
    HookConVarChange(gCvarList[CVAR_HITGROUP_FRIENDLY_FIRE],    CvarsLockOnCvarHook);
    HookConVarChange(gCvarList[CVAR_HITGROUP_FRIENDLY_GRENADE], CvarsLockOnCvarHook2);
    HookConVarChange(gCvarList[CVAR_HITGROUP_FRIENDLY_BULLETS], CvarsLockOnCvarHook2);
    HookConVarChange(gCvarList[CVAR_HITGROUP_FRIENDLY_OTHER],   CvarsLockOnCvarHook2);
    HookConVarChange(gCvarList[CVAR_HITGROUP_FRIENDLY_SELF],    CvarsLockOnCvarHook2);
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_HITGROUP], HitGroupsOnCvarHook);
}

/**
 * @brief Client has been joined.
 * 
 * @param clientIndex       The client index.  
 **/
void HitGroupsOnClientInit(int clientIndex)
{
    // If gamemodes is disabled, then unhook
    int iDamage = gCvarList[CVAR_GAMEMODE].IntValue;
    if(!iDamage)
    {
        // Unhook entity callbacks
        SDKUnhook(clientIndex, SDKHook_TraceAttack,  HitGroupsOnTraceAttack);
        SDKUnhook(clientIndex, SDKHook_OnTakeDamage, HitGroupsOnTakeDamage);
        return;
    }
    
    // Hook entity callbacks
    SDKHook(clientIndex, SDKHook_TraceAttack,  HitGroupsOnTraceAttack);
    SDKHook(clientIndex, SDKHook_OnTakeDamage, HitGroupsOnTakeDamage); 
}

/**
 * Cvar hook callback (zp_game_custom_hitgroups)
 * @brief Hit groups module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void HitGroupsOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    HitGroupsOnInit();
}

/*
 * Hit groups main functions.
 */

/**
 * Hook: OnTraceAttack
 * @brief Called right before the bullet enters a client.
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflicter index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The type of damage inflicted.
 * @param iAmmo             The ammo type of the attacker weapon.
 * @param iHitBox           The hitbox index.  
 * @param iHitGroup         The hitgroup index.  
 **/
public Action HitGroupsOnTraceAttack(int clientIndex, int &attackerIndex, int &inflicterIndex, float &flDamage, int &iBits, int &iAmmo, int iHitBox, int iHitGroup)
{
    // If mode doesn't started yet, then stop
    if(!gServerData.RoundStart)
    {
        // Stop trace
        return Plugin_Handled;
    }
    
    // Validate victim/attacker
    if(IsPlayerAlive(clientIndex) && IsPlayerExist(attackerIndex))
    {
        // Validate team
        if(GetClientTeam(clientIndex) == GetClientTeam(attackerIndex))
        {
            // Stop trace
            return Plugin_Handled;
        }
    }

    // If custom hitgroups enabled, then apply multipliers
    if(gCvarList[CVAR_HITGROUP].BoolValue)
    {
        // Validate hitgroup index
        int iHitIndex = HitGroupToIndex(iHitGroup);
        if(iHitIndex != -1)
        {
            // Validate damage
            if(!HitGroupsIsDamage(iHitIndex))
            {
                // Stop trace
                return Plugin_Handled;
            }
        }
    }

    // Allow trace
    return Plugin_Continue;
}

/**
 * Hook: OnTakeDamage
 * @brief Called right before damage is done.
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflicter index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The type of damage inflicted.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 * @param damageForce       The velocity of damage force.
 * @param damagePosition    The origin of damage.
 **/
public Action HitGroupsOnTakeDamage(int clientIndex, int &attackerIndex, int &inflicterIndex, float &flDamage, int &iBits, int &weaponIndex, float damageForce[3], float damagePosition[3]/*, int damagecustom*/)
{
    // Validate inflicter
    if(IsValidEdict(inflicterIndex))
    {
        // Gets classname of the inflicter
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(inflicterIndex, sClassname, sizeof(sClassname));

        // If entity is a trigger, then allow damage (Map is damaging client)
        if(StrContains(sClassname, "trigger", false) > -1)
        {
            // Allow damage
            return Plugin_Continue;
        }
    }

    // If mode doesn't started yet, then stop
    if(!gServerData.RoundStart)
    {
        // Block damage
        return Plugin_Handled;
    }

    // Validate damage
    if(!HitGroupsOnCalculateDamage(clientIndex, attackerIndex, inflicterIndex, flDamage, iBits, weaponIndex))
    {
        // Block damage
        return Plugin_Handled;
    }

    // Allow damage
    return Plugin_Changed;
}
 
/**
 * @brief Calculate the real damage and knockback amount.
 *
 * @link https://github.com/s1lentq/ReGameDLL_CS/blob/7c9d59101b67525a35b0b3a31e17159ab5d42fbd/regamedll/dlls/player.cpp#L984
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflicter index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The type of damage inflicted.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 * @return                  True to allow real damage or false to block real damage.
 **/
bool HitGroupsOnCalculateDamage(int clientIndex, int &attackerIndex, int &inflicterIndex, float &flDamage, int &iBits, int &weaponIndex)
{
    // Validate victim
    if(!IsPlayerAlive(clientIndex))
    {
        // Block damage
        return false;
    }
    
    // Initialize variables
    int iIndex = -1; bool bInfectProtect = true; float flDamageRatio = 1.0; float flArmorRatio = 0.5; float flBonusRatio = 0.5; float flKnockRatio = ClassGetKnockBack(gClientData[clientIndex].Class); 

    // Gets the hitgroup index
    int iHitGroup = ToolsGetClientHitGroup(clientIndex);

    // Validate bit
    if(!HitGroupsValidateBits(clientIndex, iBits, iHitGroup))
    {
        // Block damage
        return false;
    }

    /*_________________________________________________________________________________________________________________________________________*/
    
    // If custom hitgroups enabled, then apply multipliers
    if(gCvarList[CVAR_HITGROUP].BoolValue)
    {
        // Validate hitgroup index
        int iHitIndex = HitGroupToIndex(iHitGroup);
        if(iHitIndex != -1)
        {
            // Reset new multipliers
            flArmorRatio = HitGroupsGetArmor(iHitIndex);
            flBonusRatio = HitGroupsGetBonus(iHitIndex);
            
            // Gets the protect value
            bInfectProtect = HitGroupsIsProtect(iHitIndex);

            // Add multiplier
            flKnockRatio *= HitGroupsGetKnockBack(iHitIndex);

            // Validate heavy
            bool bHeavySuit = ToolsGetClientHeavySuit(clientIndex);
            if(bHeavySuit)
            {
                // Add multiplier
                flDamageRatio *= HitGroupsGetHeavy(iHitIndex);
            }
            
            // Validate damage
            if(!HitGroupsIsDamage(iHitIndex))
            {
                // Block damage
                return false;
            }
        }
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Call forward
    gForwardData._OnClientDamaged(clientIndex, attackerIndex, inflicterIndex, flDamage, iBits, weaponIndex);

    // Validate damage
    if(flDamage < 0.0)
    {
        // Block damage
        return false;
    }

    /*_________________________________________________________________________________________________________________________________________*/
    
    // Validate attacker
    if(IsPlayerExist(attackerIndex, false))
    {
        // Validate team
        if(clientIndex != attackerIndex && GetClientTeam(clientIndex) == GetClientTeam(attackerIndex))
        {
            // Block damage
            return false;
        }

        // If level system enabled, then apply multiplier
        if(gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
        {
            // Add multiplier
            flDamageRatio *= float(gClientData[attackerIndex].Level) * gCvarList[CVAR_LEVEL_DAMAGE_RATIO].FloatValue + 1.0;
        }

        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // Validate custom index
            int iD = WeaponsGetCustomID(weaponIndex);
            if(iD != -1)
            {
                // Add multipliers
                flDamageRatio *= WeaponsGetDamage(iD); 
                flKnockRatio  *= WeaponsGetKnockBack(iD);
                
                // Store the weapon id for an icon 
                iIndex = iD;
            }
        }
    }
    else
    {
        /// Avoid validation in high hierarchical functions
        attackerIndex = 0; 
    }
    
    // Validate grenade
    if(IsValidEdict(inflicterIndex) && WeaponsValidateProjectile(inflicterIndex))
    {
        // Validate custom index
        int iD = WeaponsGetCustomID(inflicterIndex);
        if(iD != -1)
        {
            // Store the weapon id for an icon 
            iIndex = iD;
        }
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Apply total multiplier
    flDamage *= flDamageRatio;
    
    // Armor doesn't protect against fall or drown damage!
    int iArmor = GetClientArmor(clientIndex); 
    if(iArmor > 0 && !(iBits & (DMG_DROWN | DMG_FALL)) && HitGroupsValidateArmor(clientIndex, iHitGroup))
    {
        // Calculate reduced amount
        float flReduce = flDamage * flArmorRatio;
        int iHit = RoundToNearest((flDamage - flReduce) * flBonusRatio);

        // Does this use more armor than we have?
        if(iHit > iArmor)
        {
            flReduce = flDamage - iArmor;
            iHit = iArmor;
        }
        else
        {   
            // Validate high reduce
            if(iHit < 0)
            {
                iHit = 1;
            }
        }
        
        // Set reduced amount
        flDamage = flReduce;

        // Sets a new armor amount
        iArmor -= iHit;
        ToolsSetClientArmor(clientIndex, iArmor);
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Converts the damage amount
    int iDamage = RoundToNearest(flDamage);
    
    // Counts the applied damage
    int iHealth = GetClientHealth(clientIndex) - iDamage;
    
    // Validate attacker
    if(attackerIndex > 0 && clientIndex != attackerIndex)
    {
        // Give rewards for applied damage
        HitGroupsGiveMoney(attackerIndex, iDamage);
        HitGroupsGiveExp(attackerIndex, iDamage);
        
        // If help messages enabled, then show info
        if(gCvarList[CVAR_MESSAGES_HELP].BoolValue) TranslationPrintHintText(attackerIndex, "damage info", (iHealth > 0) ? iHealth : 0);

        // Client was damaged by 'bullet' or 'knife'
        if(iBits & DMG_NEVERGIB)
        {
            // Apply knockback
            HitGroupsApplyKnockBack(clientIndex, attackerIndex, flDamage * flKnockRatio); /// Calculate knockback based on the damage amount and knockback multiplier
            
            // Validate zombie
            if(gClientData[attackerIndex].Zombie)
            {
                // If victim is zombie, then stop
                if(gClientData[clientIndex].Zombie)
                {
                    // Block damage
                    return false;
                }

                // If the gamemode allow infection, then apply it
                if(ModesIsInfection(gServerData.RoundMode))
                {
                    // Gets 
                    static char sType[SMALL_LINE_LENGTH];
                    ModesGetZombieClass(gServerData.RoundMode, sType, sizeof(sType));
        
                    // Validate lethal damage
                    if(iHealth <= 0 || !iArmor) 
                    {
                        // Infect victim
                        ApplyOnClientUpdate(clientIndex, attackerIndex, sType);
                        return false;
                    }
                    
                    // Validate infection protect
                    if(bInfectProtect) 
                    {
                        // Block damage
                        return false;
                    }
                }
            }
        }
    }
    
    // Forward event to modules
    SoundsOnClientHurt(clientIndex, iBits);
    
    // Validate health
    if(iHealth > 0)
    {
        // Sets applied damage
        ToolsSetClientHealth(clientIndex, iHealth);
        
        // Block damage
        return false;
    }
    
    // Validate attacker
    if(attackerIndex > 0 && iIndex != -1)
    {
        // Gets death icon
        static char sIcon[SMALL_LINE_LENGTH];
        WeaponsGetIcon(iIndex, sIcon, sizeof(sIcon));
        if(!hasLength(sIcon)) /// Use default name
        {
            WeaponsGetEntity(iIndex, sIcon, sizeof(sIcon));
            strcopy(sIcon, sizeof(sIcon), sIcon[7]);
        }
        
        // Create a fake death event
        DeathOnClientHUD(clientIndex, attackerIndex, sIcon, (iHitGroup == HITGROUP_HEAD));
    }

    // Allow damage
    return true;
}

/*
 * Hit groups natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void HitGroupsOnNativeInit(/*void*/) 
{
    CreateNative("ZP_TakeDamage",           API_TakeDamage);
    CreateNative("ZP_GetNumberHitGroup",    API_GetNumberHitGroup);
    CreateNative("ZP_GetHitGroupID",        API_GetHitGroupID);
    CreateNative("ZP_GetHitGroupNameID",    API_GetHitGroupNameID);
    CreateNative("ZP_GetHitGroupName",      API_GetHitGroupName);
    CreateNative("ZP_GetHitGroupIndex",     API_GetHitGroupIndex);
    CreateNative("ZP_IsHitGroupDamage",     API_IsHitGroupDamage);
    CreateNative("ZP_GetHitGroupKnockBack", API_GetHitGroupKnockBack);
    CreateNative("ZP_GetHitGroupArmor",     API_GetHitGroupArmor);
    CreateNative("ZP_GetHitGroupBonus",     API_GetHitGroupBonus);
    CreateNative("ZP_GetHitGroupHeavy",     API_GetHitGroupHeavy);
    CreateNative("ZP_IsHitGroupProtect",    API_IsHitGroupProtect);
}
 
/**
 * @brief Applies fake damage to a player.
 *
 * @note native bool ZP_TakeDamage(clientIndex, attackerIndex, inflicterIndex, flDamage, iBits, weaponIndex);
 **/
public int API_TakeDamage(Handle hPlugin, int iNumParams)
{
    // Gets data from native cells
    int clientIndex = GetNativeCell(1);
    int attackerIndex = GetNativeCell(2);
    int inflicterIndex = GetNativeCell(3);
    float flDamage = GetNativeCell(4);
    int iBits = GetNativeCell(5);
    int weaponIndex = GetNativeCell(6);

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return -1;
    }
    
    // Call fake hook
    Action resultHandle = HitGroupsOnTakeDamage(clientIndex, attackerIndex, inflicterIndex, flDamage, iBits, weaponIndex, NULL_VECTOR, NULL_VECTOR);
    
    // Validate damage 
    if(resultHandle == Plugin_Changed)
    {
        // If attacker/inflicter doens't exist, then make a self damage
        if(!IsPlayerExist(attackerIndex, false)) attackerIndex = clientIndex;
        if(!IsValidEdict(inflicterIndex)) inflicterIndex = clientIndex;

        // Create the damage to kill
        SDKHooks_TakeDamage(clientIndex, inflicterIndex, attackerIndex, flDamage);
        return false;
    }
    
    // Return on success
    return true;
}
 
/**
 * @brief Gets the amount of all hitgrups.
 *
 * @note native int ZP_GetNumberHitGroup();
 **/
public int API_GetNumberHitGroup(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return gServerData.HitGroups.Length;
}

/**
 * @brief Gets the array index at which the hitgroup index is at.
 *
 * @note native int ZP_GetHitGroupID(hitgroup);
 **/
public int API_GetHitGroupID(Handle hPlugin, int iNumParams)
{
    // Return the value
    return HitGroupToIndex(GetNativeCell(1));
}

/**
 * @brief Gets the index of a higroup at a given name.
 *
 * @note native int ZP_GetHitGroupNameID(name);
 **/
public int API_GetHitGroupNameID(Handle hPlugin, int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Can't find hitgroup with an empty name");
        return -1;
    }
    
    // Gets native data
    static char sName[SMALL_LINE_LENGTH];

    // General
    GetNativeString(1, sName, sizeof(sName));

    // Return the value
    return HitGroupsNameToIndex(sName);  
}

/**
 * @brief Gets the name of a hitgroup at a given index.
 *
 * @note native void ZP_GetHitGroupName(iD, name, maxlen);
 **/
public int API_GetHitGroupName(Handle hPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.HitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    HitGroupsGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the real hitgroup index of the hitgroup.
 *
 * @note native int ZP_GetHitGroupIndex(iD);
 **/
public int API_GetHitGroupIndex(Handle hPlugin, int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.HitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return HitGroupsGetIndex(iD);
}

/**
 * @brief Checks the damage value of the hitgroup.
 *
 * @note native bool ZP_IsHitGroupDamage(iD);
 **/
public int API_IsHitGroupDamage(Handle hPlugin, int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.HitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return HitGroupsIsDamage(iD);
}

/**
 * @brief Gets the knockback value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupKnockBack(iD);
 **/
public int API_GetHitGroupKnockBack(Handle hPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.HitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(HitGroupsGetKnockBack(iD));
}

/**
 * @brief Gets the armor value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupArmor(iD);
 **/
public int API_GetHitGroupArmor(Handle hPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.HitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(HitGroupsGetArmor(iD));
}

/**
 * @brief Gets the bonus value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupBonus(iD);
 **/
public int API_GetHitGroupBonus(Handle hPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.HitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(HitGroupsGetBonus(iD));
}

/**
 * @brief Gets the heavy value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupHeavy(iD);
 **/
public int API_GetHitGroupHeavy(Handle hPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.HitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(HitGroupsGetHeavy(iD));
}

/**
 * @brief Checks the protect value of the hitgroup.
 *
 * @note native bool ZP_IsHitGroupProtect(iD);
 **/
public int API_IsHitGroupProtect(Handle hPlugin, int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.HitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return HitGroupsIsProtect(iD);
}

/*
 * Hit groups data reading API.
 */

/**
 * @brief Gets the name of a hitgroup at a given index.
 *
 * @param iD                The hitgroup index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The lenght of string.
 **/
void HitGroupsGetName(int iD, char[] sName, int iMaxLen)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
    
    // Gets hitgroup name
    arrayHitGroup.GetString(HITGROUPS_DATA_NAME, sName, iMaxLen);
}

/**
 * @brief Gets hitgroup index.
 * 
 * @param iD                The hitgroup index.
 * @return                  The real hitgroup index.
 **/
int HitGroupsGetIndex(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
    
    // Return hitgroup index of the hitgroup
    return arrayHitGroup.Get(HITGROUPS_DATA_INDEX);
}

/**
 * @brief Checks hitgroup damage value.
 * 
 * @param iD                The hitgroup index.
 * @return                  True if hitgroup can be damaged, false if not.
 **/
bool HitGroupsIsDamage(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
    
    // Return true if hitgroup can be damaged, false if not
    return arrayHitGroup.Get(HITGROUPS_DATA_DAMAGE);
}

/**
 * @brief Gets hitgroup knockback value.
 * 
 * @param iD                The array index.
 * @return                  The knockback multiplier of the hitgroup.
 **/
float HitGroupsGetKnockBack(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
    
    // Return the knockback multiplier for the hitgroup
    return arrayHitGroup.Get(HITGROUPS_DATA_KNOCKBACK);
}

/**
 * @brief Gets hitgroup armor value.
 * 
 * @param iD                The array index.
 * @return                  The knockback armor of the hitgroup.
 **/
float HitGroupsGetArmor(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
    
    // Return the knockback armor for the hitgroup
    return arrayHitGroup.Get(HITGROUPS_DATA_ARMOR);
}

/**
 * @brief Gets hitgroup bonus value.
 * 
 * @param iD                The array index.
 * @return                  The knockback bonus of the hitgroup.
 **/
float HitGroupsGetBonus(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
    
    // Return the knockback bonus for the hitgroup
    return arrayHitGroup.Get(HITGROUPS_DATA_BONUS);
}

/**
 * @brief Gets hitgroup heavy value.
 * 
 * @param iD                The array index.
 * @return                  The knockback heavy of the hitgroup.
 **/
float HitGroupsGetHeavy(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
    
    // Return the knockback heavy for the hitgroup
    return arrayHitGroup.Get(HITGROUPS_DATA_HEAVY);
}

/**
 * @brief Checks hitgroup protect value.
 * 
 * @param iD                The hitgroup index.
 * @return                  True if hitgroup can be protected, false if not.
 **/
bool HitGroupsIsProtect(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
    
    // Return true if hitgroup can be protect, false if not
    return arrayHitGroup.Get(HITGROUPS_DATA_PROTECT);
}

/*
 * Stocks hit groups API.
 */

/**
 * @brief Find the index at which the hitgroup name is at.
 * 
 * @param sName             The hitgroup name.
 * @return                  The array index containing the given hitgroup name.
 **/
int HitGroupsNameToIndex(char[] sName)
{
    // Initialize name char
    static char sHitGroupName[SMALL_LINE_LENGTH];
    
    // i = box index
    int iSize = gServerData.HitGroups.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets hitbox name 
        HitGroupsGetName(i, sHitGroupName, sizeof(sHitGroupName));
        
        // If names match, then return index
        if(!strcmp(sName, sHitGroupName, false))
        {
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return -1;
}

/**
 * @brief Find the array index at which the hitgroup index is at.
 * 
 * @param iHitGroup         The hitgroup index to search for.
 * @return                  The array index that contains the given hitgroup index.
 **/
int HitGroupToIndex(int iHitGroup)
{
    // i = box index
    int iSize = gServerData.HitGroups.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets hitgroup index at this array index
        int iIndex = HitGroupsGetIndex(i);
        
        // If hitgroup indexes match, then return array index
        if(iHitGroup == iIndex)
        {
            // Return this index
            return i;
        }
    }
    
    // Hitgroup index doesn't exist
    return -1;
}

/**
 * @brief Returns true if the player has a damage at the hitgroup, false if not.
 * 
 * @param clientIndex       The client index.
 * @param iBits             The type of damage inflicted.
 * @param iHitGroup         The hitgroup index output.
 * @return                  True or false.
 **/
bool HitGroupsValidateBits(int clientIndex, int iBits, int &iHitGroup)
{
    // Validate bits
    if(iBits & (DMG_BURN | DMG_DIRECT))
    {
        iHitGroup = HITGROUP_CHEST;
    }
    else if(iBits & DMG_FALL)
    {
        if(!ClassIsFall(gClientData[clientIndex].Class)) return false;
        iHitGroup = GetRandomInt(HITGROUP_LEFTLEG, HITGROUP_RIGHTLEG); 
    }
    else if(iBits & DMG_BLAST)
    {
        iHitGroup = HITGROUP_GENERIC; 
    }
    else if(iBits & (DMG_NERVEGAS | DMG_DROWN))
    {
        iHitGroup = HITGROUP_HEAD;
    }
    
    // Return on success
    return true;
/*
    else if(iBits & DMG_GENERIC)    
    else if(iBits & DMG_CRUSH)
    else if(iBits & DMG_BULLET)
    else if(iBits & DMG_SLASH)    
    else if(iBits & DMG_CLUB)
    else if(iBits & DMG_SHOCK)
    else if(iBits & DMG_SONIC)
    else if(iBits & DMG_ENERGYBEAM)
    else if(iBits & DMG_PREVENT_PHYSICS_FORCE)
    else if(iBits & DMG_NEVERGIB)
    else if(iBits & DMG_ALWAYSGIB)
    else if(iBits & DMG_PARALYZE)
    else if(iBits & DMG_VEHICLE)
    else if(iBits & DMG_POISON)
    else if(iBits & DMG_RADIATION)
    else if(iBits & DMG_DROWNRECOVER)
    else if(iBits & DMG_ACID)
    else if(iBits & DMG_SLOWBURN)
    else if(iBits & DMG_REMOVENORAGDOLL)
    else if(iBits & DMG_PHYSGUN)
    else if(iBits & DMG_PLASMA)
    else if(iBits & DMG_AIRBOAT)
    else if(iBits & DMG_DISSOLVE)
    else if(iBits & DMG_BLAST_SURFACE)
    else if(iBits & DMG_BUCKSHOT)
*/
}

/**
 * @brief Returns true if the player has an armor at the hitgroup, false if not.
 * 
 * @param clientIndex       The client index.
 * @param iHitGroup         The hitgroup index.
 * @return                  True or false.
 **/
bool HitGroupsValidateArmor(int clientIndex, int iHitGroup)
{
    // Initialize bool
    bool bApplyArmor;

    // Gets hitbox
    switch(iHitGroup)
    {
        case HITGROUP_HEAD :
        {
            bApplyArmor = ToolsGetClientHelmet(clientIndex);
        }
        
        case HITGROUP_GENERIC, HITGROUP_CHEST, HITGROUP_STOMACH, HITGROUP_LEFTARM, HITGROUP_RIGHTARM :
        {
            bApplyArmor = true;
        }
    }
    
    // Return on success
    return bApplyArmor;
}

/** 
 * @brief Sets velocity knockback for the applied damage.
 *
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param flKnockBack       The knockback amount.
 **/
void HitGroupsApplyKnockBack(int clientIndex, int attackerIndex, float flKnockBack)
{
    // If victim is not on the ground, then apply it
    if(!(GetEntityFlags(clientIndex) & FL_ONGROUND))
    {
        // Add multiplier
        flKnockBack *= gCvarList[CVAR_JUMPBOOST_KNOCKBACK].FloatValue;
    }
    
    // Validate amount
    if(flKnockBack <= 0.0)
    {
        // Stop knockback
        return;
    }

    // Initialize vectors
    static float vEntAngle[3]; static float vEntPosition[3]; static float vBulletPosition[3]; static float vVelocity[3]; 

    // Gets attacker position
    GetClientEyeAngles(attackerIndex, vEntAngle);
    GetClientEyePosition(attackerIndex, vEntPosition);

    // Create the infinite trace
    Handle hTrace = TR_TraceRayFilterEx(vEntPosition, vEntAngle, MASK_SHOT, RayType_Infinite, HitGroupsFilter, attackerIndex);

    // Validate trace
    if(!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == clientIndex)
    {
        // Gets hit point
        TR_GetEndPosition(vBulletPosition, hTrace);

        // Gets vector from the given starting and ending points
        MakeVectorFromPoints(vEntPosition, vBulletPosition, vVelocity);

        // Normalize the vector (equal magnitude at varying distances)
        NormalizeVector(vVelocity, vVelocity);

        // Apply the magnitude by scaling the vector
        ScaleVector(vVelocity, flKnockBack);

        // Adds the given vector to the client current velocity
        ToolsClientVelocity(clientIndex, vVelocity);
    }
    
    // Close the trace
    delete hTrace;
}

/**
 * @brief Reward money for the applied damage.
 *
 * @param clientIndex       The client index.
 * @param iDamage           The damage amount.
 **/
void HitGroupsGiveMoney(int clientIndex, int iDamage)
{
    // Initialize client applied damage
    static int iAppliedDamage[MAXPLAYERS+1];
    
    // Increment total damage
    iAppliedDamage[clientIndex] += iDamage;

    // Gets class money bonuses
    static int iMoney[6];
    ClassGetMoney(gClientData[clientIndex].Class, iMoney, sizeof(iMoney));  
    
    // Validate limit
    int iLimit = iMoney[BonusType_Damage];
    if(!iLimit)
    {
        return;
    }

    // Validate bonus
    int iBonus = iAppliedDamage[clientIndex] / iLimit;
    if(!iBonus) 
    {
        return;
    }
    
    // Give money for the attacker
    AccountSetClientCash(clientIndex, gClientData[clientIndex].Money + iBonus);
    
    // Resets damage filter
    iAppliedDamage[clientIndex] -= iBonus * iLimit;
}

/**
 * @brief Reward experience for the applied damage.
 *
 * @param clientIndex       The client index.
 * @param iDamage           The damage amount.
 **/
void HitGroupsGiveExp(int clientIndex, int iDamage)
{
    // If level system disabled, then stop
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }
    
    // Initialize client applied damage
    static int iAppliedDamage[MAXPLAYERS+1];
    
    // Increment total damage
    iAppliedDamage[clientIndex] += iDamage;
    
    // Gets class exp bonuses
    static int iExp[6];
    ClassGetExp(gClientData[clientIndex].Class, iExp, sizeof(iExp));
    
    // Validate limit
    int iLimit = iExp[BonusType_Damage];
    if(!iLimit)
    {
        return;
    }
    
    // Validate bonus
    int iBonus = iAppliedDamage[clientIndex] / iLimit;
    if(!iBonus) 
    {
        return;
    }
    
    // Give experience for the attacker
    LevelSystemOnSetExp(clientIndex, gClientData[clientIndex].Exp + iBonus);
    
    // Resets damage filter
    iAppliedDamage[clientIndex] -= iBonus * iLimit;
}

/**
 * @brief Trace filter.
 *  
 * @param entityIndex       The entity index.
 * @param contentsMask      The contents mask.
 * @param clientIndex       The client index.
 *
 * @return                  True or false.
 **/
public bool HitGroupsFilter(int entityIndex, int contentsMask, int clientIndex)
{
    return (entityIndex != clientIndex);
}