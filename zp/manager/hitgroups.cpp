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
 * Array handle to store hitgroups data.
 **/
ArrayList arrayHitgroups;

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
    int iSize = arrayHitgroups.Length;
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
    // Gets config file path
    char sHitGroupsPath[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Hitgroups, sHitGroupsPath, sizeof(sHitGroupsPath)); 
    
    KeyValues kvHitgroups;
    bool bSuccess = ConfigOpenConfigFile(File_Hitgroups, kvHitgroups);

    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Hitgroups, "Config Validation", "Unexpected error caching data from hitgroups config file: %s", sHitGroupsPath);
    }

    // i = array index
    int iSize = arrayHitgroups.Length;
    for(int i = 0; i < iSize; i++)
    {
        HitgroupsGetName(i, sHitGroupsPath, sizeof(sHitGroupsPath));             // Index: 0
        kvHitgroups.Rewind();
        if(!kvHitgroups.JumpToKey(sHitGroupsPath))
        {
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Hitgroups, "Config Validation", "Couldn't cache hitgroup data for: %s (check hitgroup config)", sHitGroupsPath);
            continue;
        }

        // Gets array size
        ArrayList arrayHitgroup = arrayHitgroups.Get(i);
        
        // Push data into array
        arrayHitgroup.Push(kvHitgroups.GetNum("index", -1));                     // Index: 1
        arrayHitgroup.Push(ConfigKvGetStringBool(kvHitgroups, "damage", "yes")); // Index: 2
        arrayHitgroup.Push(kvHitgroups.GetFloat("knockback", 1.0));              // Index: 3
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
 * Find the index at which the hitgroup name is at.
 * 
 * @param sHitGroup         The higroup name.
 * @param iMaxLen           (Only if 'overwritename' is true) The max length of the hitgroup name. 
 * @param bOverWriteName    (Optional) If true, the hitgroup given will be overwritten with the name from the config.
 * @return                  The array index containing the given hitgroup name.
 **/
stock int HitgroupsNameToIndex(char[] sHitGroup, const int iMaxLen = 0, const bool bOverWriteName = false)
{
    // Initialize variable
    static char sHitGroupName[SMALL_LINE_LENGTH];
    
    // i = box index
    int iSize = arrayHitgroups.Length;
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
                StrExtract(sHitGroup, sHitGroupName, 0, iMaxLen);
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
stock int HitgroupToIndex(const int iHitGroup)
{
    // i = box index
    int iSize = arrayHitgroups.Length;
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
public int API_GetNumberHitgroup(Handle isPlugin, const int iNumParams)
{
    // Return the value 
    return arrayHitgroups.Length;
}

/**
 * Gets the array index at which the hitgroup index is at.
 *
 * native int ZP_GetHitgroupID(hitgroup);
 **/
public int API_GetHitgroupID(Handle isPlugin, const int iNumParams)
{
    // Return the value
    return HitgroupToIndex(GetNativeCell(1));
}

/**
 * Gets the name of a hitgroup at a given index.
 *
 * native void ZP_GetHitgroupName(iD, name, maxlen);
 **/
public int API_GetHitgroupName(Handle isPlugin, const int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitgroups.Length)
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
public int API_GetHitgroupIndex(Handle isPlugin, const int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitgroups.Length)
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
public int API_IsHitgroupDamage(Handle isPlugin, const int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitgroups.Length)
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
public int API_SetHitgroupDamage(Handle isPlugin, const int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitgroups.Length)
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
public int API_GetHitgroupKnockback(Handle isPlugin, const int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitgroups.Length)
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
public int API_SetHitgroupKnockback(Handle isPlugin, const int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitgroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Hitgroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return;
    }
    
    // Sets the value 
    HitgroupsSetKnockback(iD, GetNativeCell(2));
}

/*
 * Hitgroups data reading API.
 */

/**
 * Gets the name of a hitgroup at a given index.
 *
 * @param iD                The hitgroup index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HitgroupsGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Gets hitgroup name
    arrayHitgroup.GetString(HITGROUPS_DATA_NAME, sName, iMaxLen);
}

/**
 * Retrieve hitgroup index.
 * 
 * @param iD                The hitgroup index.
 * @return                  The real hitgroup index.
 **/
stock int HitgroupsGetIndex(const int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Return hitgroup index of the hitgroup
    return arrayHitgroup.Get(HITGROUPS_DATA_INDEX);
}

/**
 * Set hitgroup damage value.
 * 
 * @param iD                The hitgroup index.
 * @param bCanDamage        True to allow damage to hitgroup, false to block damage.
 **/
stock void HitgroupsSetDamage(const int iD, const bool bCanDamage)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Sets true if hitgroup can be damaged, false if not
    arrayHitgroup.Set(HITGROUPS_DATA_DAMAGE, bCanDamage);
}

/**
 * Retrieve hitgroup damage value.
 * 
 * @param iD                The hitgroup index.
 * @return                  True if hitgroup can be damaged, false if not.
 **/
stock bool HitgroupsCanDamage(const int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Return true if hitgroup can be damaged, false if not
    return arrayHitgroup.Get(HITGROUPS_DATA_DAMAGE);
}

/**
 * Set hitgroup knockback value.
 * 
 * @param iD                The hitgroup index.
 * @param flKnockback       The knockback multiplier for the hitgroup.
 **/
stock void HitgroupsSetKnockback(const int iD, const float flKnockback)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Return the knockback multiplier for the hitgroup
    arrayHitgroup.Set(HITGROUPS_DATA_KNOCKBACK, flKnockback);
}

/**
 * Retrieve hitgroup knockback value.
 * 
 * @param iD                The array index.
 * @return                  The knockback multiplier of the hitgroup.
 **/
stock float HitgroupsGetKnockback(const int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitgroup = arrayHitgroups.Get(iD);
    
    // Return the knockback multiplier for the hitgroup
    return arrayHitgroup.Get(HITGROUPS_DATA_KNOCKBACK);
}