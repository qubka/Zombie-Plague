/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          hitgroup.cpp
 *  Type:          Manager 
 *  Description:   HitGroups table generator.
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
#define HITGROUP_GEAR       10
/**
 * @endsection
 **/

/**
 * Array handle to store hitgroups data.
 **/
ArrayList arrayHitGroups;

/**
 * HitGroup config data indexes.
 **/
enum
{
    HITGROUPS_DATA_NAME = 0,
    HITGROUPS_DATA_INDEX,
    HITGROUPS_DATA_DAMAGE,
    HITGROUPS_DATA_KNOCKBACK,
}

/**
 * Hitgroups module init function.
 **/ 
void HitGroupsInit(/*void*/)
{
    // Prepare all hitgroup data
    HitGroupsLoad();
}

/**
 * Prepare all hitgroup data.
 **/
void HitGroupsLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_HitGroups, Structure_Keyvalue, CONFIG_FILE_ALIAS_HITGROUPS);

    // If module is disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_HITGROUPS].BoolValue)
    {
        return;
    }

    // Gets hitgroups config path
    char sPathGroups[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_HITGROUPS, sPathGroups);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Missing hitgroups config file: %s", sPathGroups);

        return;
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_HitGroups, sPathGroups);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_HitGroups, arrayHitGroups);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Unexpected error encountered loading: %s", sPathGroups);

        return;
    }

    // Validate hitgroups config
    int iSize = arrayHitGroups.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "No usable data found in hitgroups config file: %s", sPathGroups);
    }

    // Now copy data to array structure
    HitGroupsCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_HitGroups, true);
    ConfigSetConfigReloadFunc(File_HitGroups, GetFunctionByName(GetMyHandle(), "HitGroupsOnConfigReload"));
    ConfigSetConfigHandle(File_HitGroups, arrayHitGroups);
}

/**
 * Caches hitgroup data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void HitGroupsCacheData(/*void*/)
{
    // Gets config file path
    char sPathGroups[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_HitGroups, sPathGroups, sizeof(sPathGroups)); 
    
    // Open config
    KeyValues kvHitGroups;
    bool bSuccess = ConfigOpenConfigFile(File_HitGroups, kvHitGroups);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Unexpected error caching data from hitgroups config file: %s", sPathGroups);
    }

    // i = array index
    int iSize = arrayHitGroups.Length;
    for(int i = 0; i < iSize; i++)
    {
        HitGroupsGetName(i, sPathGroups, sizeof(sPathGroups));             // Index: 0
        kvHitGroups.Rewind();
        if(!kvHitGroups.JumpToKey(sPathGroups))
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Couldn't cache hitgroup data for: %s (check hitgroup config)", sPathGroups);
            continue;
        }

        // Gets array size
        ArrayList arrayHitGroup = arrayHitGroups.Get(i);
        
        // Push data into array
        arrayHitGroup.Push(kvHitGroups.GetNum("index", -1));                     // Index: 1
        arrayHitGroup.Push(ConfigKvGetStringBool(kvHitGroups, "damage", "yes")); // Index: 2
        arrayHitGroup.Push(kvHitGroups.GetFloat("knockback", 1.0));              // Index: 3
    }
    
    // We're done with this file now, so we can close it
    delete kvHitGroups;
}

/**
 * Called when configs are being reloaded.
 **/
public void HitGroupsOnConfigReload(/*void*/)
{
    // Reload hitgroups config
    HitGroupsLoad();
}

/**
 * Hook hitgroups cvar changes.
 **/
void HitGroupsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_GAME_CUSTOM_HITGROUPS]       = FindConVar("zp_game_custom_hitgroups"); 
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_GAME_CUSTOM_HITGROUPS],       HitGroupsCvarsHookEnable);
}

/**
 * Cvar hook callback (zp_game_custom_hitgroups)
 * Hitgroups module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void HitGroupsCvarsHookEnable(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    HitGroupsInit();
}

/**
 * Find the index at which the hitgroup name is at.
 * 
 * @param sHitGroup         The higroup name.
 * @param iMaxLen           (Only if 'overwritename' is true) The max length of the hitgroup name. 
 * @param bOverWriteName    (Optional) If true, the hitgroup given will be overwritten with the name from the config.
 * @return                  The array index containing the given hitgroup name.
 **/
stock int HitGroupsNameToIndex(char[] sHitGroup, const int iMaxLen = 0, const bool bOverWriteName = false)
{
    // Initialize variable
    static char sHitGroupName[SMALL_LINE_LENGTH];
    
    // i = box index
    int iSize = arrayHitGroups.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets hitbox name 
        HitGroupsGetName(i, sHitGroupName, sizeof(sHitGroupName));
        
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
stock int HitGroupToIndex(const int iHitGroup)
{
    // i = box index
    int iSize = arrayHitGroups.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets hitgroup index at this array index
        int iIndex = HitGroupsGetIndex(i);
        
        // If hitgroup indexes match, then return array index
        if(iHitGroup == iIndex)
        {
            return i;
        }
    }
    
    // HitGroup index doesn't exist
    return -1;
}

/*
 * Weapons natives API.
 */

/**
 * Sets up natives for library.
 **/
void HitGroupsAPI(/*void*/) 
{
    CreateNative("ZP_GetNumberHitGroup",              API_GetNumberHitGroup);
    CreateNative("ZP_GetHitGroupID",                  API_GetHitGroupID);
    CreateNative("ZP_GetHitGroupName",                API_GetHitGroupName);
    CreateNative("ZP_GetHitGroupIndex",               API_GetHitGroupIndex);
    CreateNative("ZP_IsHitGroupDamage",               API_IsHitGroupDamage);
    CreateNative("ZP_SetHitGroupDamage",              API_SetHitGroupDamage);
    CreateNative("ZP_GetHitGroupKnockback",           API_GetHitGroupKnockback);
    CreateNative("ZP_SetHitGroupKnockback",           API_SetHitGroupKnockback);
}
 
/**
 * Gets the amount of all hitgrups.
 *
 * native int ZP_GetNumberHitGroup();
 **/
public int API_GetNumberHitGroup(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return arrayHitGroups.Length;
}

/**
 * Gets the array index at which the hitgroup index is at.
 *
 * native int ZP_GetHitGroupID(hitgroup);
 **/
public int API_GetHitGroupID(Handle hPlugin, const int iNumParams)
{
    // Return the value
    return HitGroupToIndex(GetNativeCell(1));
}

/**
 * Gets the name of a hitgroup at a given index.
 *
 * native void ZP_GetHitGroupName(iD, name, maxlen);
 **/
public int API_GetHitGroupName(Handle hPlugin, const int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    HitGroupsGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the real hitgroup index of the hitgroup.
 *
 * native int ZP_GetHitGroupIndex(iD);
 **/
public int API_GetHitGroupIndex(Handle hPlugin, const int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return HitGroupsGetIndex(iD);
}

/**
 * Gets the damage value of the hitgroup.
 *
 * native bool ZP_IsHitGroupDamage(iD);
 **/
public int API_IsHitGroupDamage(Handle hPlugin, const int iNumParams)
{    
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return HitGroupsCanDamage(iD);
}

/**
 * Sets the damage value of the hitgroup.
 *
 * native void ZP_SetHitGroupDamage(iD, damage);
 **/
public int API_SetHitGroupDamage(Handle hPlugin, const int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return;
    }
    
    // Sets the value 
    HitGroupsSetDamage(iD, GetNativeCell(2));
}

/**
 * Gets the knockback value of the hitgroup.
 *
 * native float ZP_GetHitGroupKnockback(iD);
 **/
public int API_GetHitGroupKnockback(Handle hPlugin, const int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(HitGroupsGetKnockback(iD));
}

/**
 * Sets the knockback value of the hitgroup.
 *
 * native void ZP_SetHitGroupKnockback(iD, knockback);
 **/
public int API_SetHitGroupKnockback(Handle hPlugin, const int iNumParams)
{
    // Gets hitgroup index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayHitGroups.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
        return;
    }
    
    // Sets the value 
    HitGroupsSetKnockback(iD, GetNativeCell(2));
}

/*
 * HitGroups data reading API.
 */

/**
 * Gets the name of a hitgroup at a given index.
 *
 * @param iD                The hitgroup index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HitGroupsGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = arrayHitGroups.Get(iD);
    
    // Gets hitgroup name
    arrayHitGroup.GetString(HITGROUPS_DATA_NAME, sName, iMaxLen);
}

/**
 * Retrieve hitgroup index.
 * 
 * @param iD                The hitgroup index.
 * @return                  The real hitgroup index.
 **/
stock int HitGroupsGetIndex(const int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = arrayHitGroups.Get(iD);
    
    // Return hitgroup index of the hitgroup
    return arrayHitGroup.Get(HITGROUPS_DATA_INDEX);
}

/**
 * Set hitgroup damage value.
 * 
 * @param iD                The hitgroup index.
 * @param bCanDamage        True to allow damage to hitgroup, false to block damage.
 **/
stock void HitGroupsSetDamage(const int iD, const bool bCanDamage)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = arrayHitGroups.Get(iD);
    
    // Sets true if hitgroup can be damaged, false if not
    arrayHitGroup.Set(HITGROUPS_DATA_DAMAGE, bCanDamage);
}

/**
 * Retrieve hitgroup damage value.
 * 
 * @param iD                The hitgroup index.
 * @return                  True if hitgroup can be damaged, false if not.
 **/
stock bool HitGroupsCanDamage(const int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = arrayHitGroups.Get(iD);
    
    // Return true if hitgroup can be damaged, false if not
    return arrayHitGroup.Get(HITGROUPS_DATA_DAMAGE);
}

/**
 * Set hitgroup knockback value.
 * 
 * @param iD                The hitgroup index.
 * @param flKnockback       The knockback multiplier for the hitgroup.
 **/
stock void HitGroupsSetKnockback(const int iD, const float flKnockback)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = arrayHitGroups.Get(iD);
    
    // Return the knockback multiplier for the hitgroup
    arrayHitGroup.Set(HITGROUPS_DATA_KNOCKBACK, flKnockback);
}

/**
 * Retrieve hitgroup knockback value.
 * 
 * @param iD                The array index.
 * @return                  The knockback multiplier of the hitgroup.
 **/
stock float HitGroupsGetKnockback(const int iD)
{
    // Gets array handle of hitgroup at given index
    ArrayList arrayHitGroup = arrayHitGroups.Get(iD);
    
    // Return the knockback multiplier for the hitgroup
    return arrayHitGroup.Get(HITGROUPS_DATA_KNOCKBACK);
}