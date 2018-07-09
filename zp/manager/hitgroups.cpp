/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          hitgroup.cpp
 *  Type:          Manager 
 *  Description:   Hitgroups table generator.
 *
 *  Copyright (C) 2015-2018 Greyscale, Richard Helgeby
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
#define HITGROUP_GEAR       10
/**
 * @endsection
 **/

/**
 * Hitgroup config data indexes.
 **/
enum
{
    HITGROUPS_DATA_NAME = 0,
    HITGROUPS_DATA_INDEX,
    HITGROUPS_DATA_DAMAGE,
    HITGROUPS_DATA_KNOCKBACK,
}

/**
 * Array handle to store hitgroups data.
 **/
ArrayList arrayHitgroups;

/**
 * Loads hitgroup data from file.
 **/ 
void HitgroupsLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Hitgroups, Structure_Keyvalue, CONFIG_FILE_ALIAS_HITGROUPS);

    // If module is disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_HITGROUPS].BoolValue)
    {
        return;
    }

    // Gets hitgroups config path
    char sHitgroupPath[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetCvarFilePath(CVAR_CONFIG_PATH_HITGROUPS, sHitgroupPath);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Hitgroups, "Config Validation", "Missing hitgroups config file: %s", sHitgroupPath);

        return;
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_Hitgroups, sHitgroupPath);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Hitgroups, arrayHitgroups);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Hitgroups, "Config Validation", "Unexpected error encountered loading: %s", sHitgroupPath);

        return;
    }

    // Validate hitgroups config
    int iSize = GetArraySize(arrayHitgroups);
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Hitgroups, "Config Validation", "No usable data found in hitgroups config file: %s", sHitgroupPath);
    }

    // Now copy data to array structure
    HitgroupsCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Hitgroups, true);
    ConfigSetConfigReloadFunc(File_Hitgroups, GetFunctionByName(GetMyHandle(), "HitgroupsOnConfigReload"));
    ConfigSetConfigHandle(File_Hitgroups, arrayHitgroups);
}

/**
 * Caches hitgroup data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void HitgroupsCacheData(/*void*/)
{
    // Gets config's file path
    char sHitGroupsPath[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Hitgroups, sHitGroupsPath, sizeof(sHitGroupsPath));
    
    KeyValues kvHitgroups;
    bool bSuccess = ConfigOpenConfigFile(File_Hitgroups, kvHitgroups);

    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Hitgroups, "Config Validation", "Unexpected error caching data from hitgroups config file: %s", sHitGroupsPath);
    }
    
    char sHitGroupName[SMALL_LINE_LENGTH];
    
    // i = array index
    int iSize = GetArraySize(arrayHitgroups);
    for(int i = 0; i < iSize; i++)
    {
        HitgroupsGetName(i, sHitGroupName, sizeof(sHitGroupName));
        kvHitgroups.Rewind();
        if(!kvHitgroups.JumpToKey(sHitGroupName))
        {
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Hitgroups, "Config Validation", "Couldn't cache hitgroup data for: %s (check hitgroup config)", sHitGroupName);
            continue;
        }
        
        // General
        int iIndex = kvHitgroups.GetNum("hitindex", -1);
        
        // Damage
        bool bDamage = ConfigKvGetStringBool(kvHitgroups, "hitdamage", "yes");
        
        // Knockback
        float flKnockback = kvHitgroups.GetFloat("hitknockback", 1.0);
        
        // Gets array size
        ArrayList arrayHitgroup = arrayHitgroups.Get(i);
        
        // Push data into array
        arrayHitgroup.Push(iIndex);        // Index: 1
        arrayHitgroup.Push(bDamage);       // Index: 2
        arrayHitgroup.Push(flKnockback);   // Index: 3
    }
    
    // We're done with this file now, so we can close it
    delete kvHitgroups;
}

/**
 * Called when configs are being reloaded.
 **/
public void HitgroupsOnConfigReload(/*void*/)
{
    // Reload hitgroups config
    HitgroupsLoad();
}

/**
 * Find the index at which the hitgroup's name is at.
 * 
 * @param sHitGroup         The higroup name.
 * @param iMaxLen           (Only if 'overwritename' is true) The max length of the hitgroup name. 
 * @param bOverWriteName    (Optional) If true, the hitgroup given will be overwritten with the name from the config.
 * @return                  The array index containing the given hitgroup name.
 **/
stock int HitgroupsNameToIndex(char[] sHitGroup, int iMaxLen = 0, bool bOverWriteName = false)
{
    // Initialize char
    static char sHitGroupName[SMALL_LINE_LENGTH];
    
    // i = box index
    int iSize = GetArraySize(arrayHitgroups);
    for(int i = 0; i < iSize; i++)
    {
        // Gets hitbox name 
        HitgroupsGetName(i, sHitGroupName, sizeof(sHitGroupName));
        
        // If names match, then return index
        if(!strcmp(sHitGroup, sHitGroupName, false))
        {
            // If 'overwrite' name is true, then overwrite the old string with new
            if(bOverWriteName)
            {
                // Copy config name to return string
                strcopy(sHitGroup, iMaxLen, sHitGroupName);
            }
            
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return -1;
}

/**
 * Find the array index at which the hitgroup index is at.
 * 
 * @param iHitGroup         The hitgroup index to search for.
 * @return                  The array index that contains the given hitgroup index.
 **/
stock int HitgroupToIndex(int iHitGroup)
{
    // i = box index
    int iSize = GetArraySize(arrayHitgroups);
    for(int i = 0; i < iSize; i++)
    {
        // Gets hitgroup index at this array index
        int iIndex = HitgroupsGetIndex(i);
        
        // If hitgroup indexes match, then return array index
        if(iHitGroup == iIndex)
        {
            return i;
        }
    }
    
    // Hitgroup index doesn't exist
    return -1;
}

/*
 * Weapons natives API.
 */

/**
 * Gets the amount of all hitgrups.
 *
 * native int ZP_GetNumberHitgroup();
 **/
public int API_GetNumberHitgroup(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return GetArraySize(arrayHitgroups);
}

/**
 * Gets the array index at which the hitgroup index is at.
 *
 * native int ZP_GetHitgroupID(hitgroup);
 **/
public int API_GetHitgroupID(Handle isPlugin, int iNumParams)
{
    // Return the value
    return HitgroupToIndex(GetNativeCell(1));
}

/**
 * Gets the name of a hitgroup at a given index.
 *
 * native void ZP_GetHitgroupName(iD, name, maxlen);
 **/
public int API_GetHitgroupName(Handle isPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayHitgroups))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Hitgroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Hitgroups, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    HitgroupsGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the real hitgroup index of the hitgroup.
 *
 * native int ZP_GetHitgroupIndex(iD);
 **/
public int API_GetHitgroupIndex(Handle isPlugin, int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayHitgroups))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Hitgroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return HitgroupsGetIndex(iD);
}

/**
 * Gets the damage value of the hitgroup.
 *
 * native bool ZP_IsHitgroupDamage(iD);
 **/
public int API_IsHitgroupDamage(Handle isPlugin, int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayHitgroups))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Hitgroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return HitgroupsCanDamage(iD);
}

/**
 * Sets the damage value of the hitgroup.
 *
 * native void ZP_SetHitgroupDamage(iD, damage);
 **/
public int API_SetHitgroupDamage(Handle isPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayHitgroups))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Hitgroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return;
    }
    
    // Sets the value 
    HitgroupsSetDamage(iD, GetNativeCell(2));
}

/**
 * Gets the knockback value of the hitgroup.
 *
 * native float ZP_GetHitgroupKnockback(iD);
 **/
public int API_GetHitgroupKnockback(Handle isPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayHitgroups))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Hitgroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(HitgroupsGetKnockback(iD));
}

/**
 * Sets the knockback value of the hitgroup.
 *
 * native void ZP_SetHitgroupKnockback(iD, knockback);
 **/
public int API_SetHitgroupKnockback(Handle isPlugin, int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayHitgroups))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Hitgroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return;
    }
    
    // Sets the value 
    HitgroupsSetKnockback(iD, GetNativeCell(2));
}

/**
 * Gets the name of a hitgroup at a given index. (static)
 *
 * @param iD                The hitgroup index.
 * @param sHitGroup         The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HitgroupsGetName(int iD, char[] sHitGroup, int iMaxLen)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Gets hitgroup name
    arrayHitgroup.GetString(HITGROUPS_DATA_NAME, sHitGroup, iMaxLen);
}

/**
 * Retrieve hitgroup index. (static)
 * 
 * @param iD                The array index.
 * @return                  The hitgroup index.
 **/
stock int HitgroupsGetIndex(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Return hitgroup index of the hitgroup
    return arrayHitgroup.Get(HITGROUPS_DATA_INDEX);
}

/**
 * Set hitgroup damage value. (dynamic)
 * 
 * @param iD                The array index.
 * @param bCanDamage        True to allow damage to hitgroup, false to block damage.
 **/
stock void HitgroupsSetDamage(int iD, bool bCanDamage)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Sets true if hitgroup can be damaged, false if not
    arrayHitgroup.Set(HITGROUPS_DATA_DAMAGE, bCanDamage);
}

/**
 * Retrieve hitgroup damage value. (dynamic)
 * 
 * @param iD                The array index.
 * @return                  True if hitgroup can be damaged, false if not.
 **/
stock bool HitgroupsCanDamage(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Return true if hitgroup can be damaged, false if not
    return arrayHitgroup.Get(HITGROUPS_DATA_DAMAGE);
}

/**
 * Set hitgroup knockback value. (dynamic)
 * 
 * @param iD                The array index.
 * @param flKnockback       The knockback multiplier for the hitgroup.
 **/
stock void HitgroupsSetKnockback(int iD, float flKnockback)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Return the knockback multiplier for the hitgroup
    arrayHitgroup.Set(HITGROUPS_DATA_KNOCKBACK, flKnockback);
}

/**
 * Retrieve hitgroup knockback value. (dynamic)
 * 
 * @param iD                The array index.
 * @return                  The knockback multiplier of the hitgroup.
 **/
stock float HitgroupsGetKnockback(int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Return the knockback multiplier for the hitgroup
    return arrayHitgroup.Get(HITGROUPS_DATA_KNOCKBACK);
}
