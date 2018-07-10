/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          weapons.cpp
 *  Type:          Manager
 *  Description:   Weapons generator.
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
 * Array handle to store weapon config data.
 **/
ArrayList arrayWeapons;

/**
 * Weapon config data indexes.
 **/
enum
{
    WEAPONS_DATA_NAME,
    WEAPONS_DATA_ENTITY,
    WEAPONS_DATA_INDEX,
    WEAPONS_DATA_COST,
    WEAPONS_DATA_SLOT,
    WEAPONS_DATA_LEVEL,
    WEAPONS_DATA_ONLINE,
    WEAPONS_DATA_DAMAGE,
    WEAPONS_DATA_KNOCKBACK,
    WEAPONS_DATA_CLIP,
    WEAPONS_DATA_AMMO,
    WEAPONS_DATA_CLASS,
    WEAPONS_DATA_MODEL_VIEW,
    WEAPONS_DATA_MODEL_VIEW_ID,
    WEAPONS_DATA_MODEL_WORLD,
    WEAPONS_DATA_MODEL_WORLD_ID,
    WEAPONS_DATA_MODEL_BODY,
    WEAPONS_DATA_MODEL_SKIN,
    WEAPONS_DATA_MODEL_HEAT,
    WEAPONS_DATA_SEQUENCE_COUNT,
    WEAPONS_DATA_SEQUENCE_SWAP
}

/*
 * Load other weapons modules
 */
#include "zp/manager/weapons/weaponhdr.cpp"
#include "zp/manager/weapons/weaponsdk.cpp"
#include "zp/manager/weapons/weaponattach.cpp"
#include "zp/manager/weapons/zmarket.cpp"

/**
 * Weapons module init function.
 **/
void WeaponsInit(/*void*/)
{
    // Forward event to sub-modules
    WeaponSDKInit();
    WeaponHDRInit();
}

/**
 * Prepare all weapon data.
 **/
void WeaponsLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Weapons, Structure_Keyvalue, CONFIG_FILE_ALIAS_WEAPONS);

    // Gets weapons config path
    static char sPathWeapons[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetCvarFilePath(CVAR_CONFIG_PATH_WEAPONS, sPathWeapons);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Missing weapons config file: \"%s\"", sPathWeapons);
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_Weapons, sPathWeapons);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Weapons, arrayWeapons);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathWeapons);
    }

    // Validate weapons config
    int iSize = GetArraySize(arrayWeapons);
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "No usable data found in weapons config file: \"%s\"", sPathWeapons);
    }

    // Now copy data to array structure
    WeaponsCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Weapons, true);
    ConfigSetConfigReloadFunc(File_Weapons, GetFunctionByName(GetMyHandle(), "WeaponsOnConfigReload"));
    ConfigSetConfigHandle(File_Weapons, arrayWeapons);
}

/**
 * Caches weapon data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void WeaponsCacheData(/*void*/)
{
    // Gets config's file path.
    static char sPathWeapons[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Weapons, sPathWeapons, sizeof(sPathWeapons));

    KeyValues kvWeapons;
    bool bSuccess = ConfigOpenConfigFile(File_Weapons, kvWeapons);

    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error caching data from weapons config file: \"%s\"", sPathWeapons);
    }

    static char sWeaponName[SMALL_LINE_LENGTH];

    // i = array index
    int iSize = GetArraySize(arrayWeapons);
    for(int i = 0; i < iSize; i++)
    {
        WeaponsGetName(i, sWeaponName, sizeof(sWeaponName));        // Index: 0
        kvWeapons.Rewind();
        if(!kvWeapons.JumpToKey(sWeaponName))
        {
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon data for: \"%s\" (check weapons config)", sWeaponName);
            continue;
        }

        // Gets config data
        static char sWeaponEntity[CONFIG_MAX_LENGTH];
        static char sWeaponModelView[PLATFORM_MAX_PATH];
        static char sWeaponModelWorld[PLATFORM_MAX_PATH];
        
        // General                                                                           
        kvWeapons.GetString("weaponentity", sWeaponEntity, sizeof(sWeaponEntity));       
        kvWeapons.GetString("weaponview", sWeaponModelView, sizeof(sWeaponModelView));  
        kvWeapons.GetString("weaponworld", sWeaponModelWorld, sizeof(sWeaponModelWorld)); 
        
        // Gets array size
        ArrayList arrayWeapon = arrayWeapons.Get(i); int swapSequences[WeaponsSequencesMax];
 
        // Push data into array
        arrayWeapon.PushString(sWeaponEntity);                      // Index: 1
        arrayWeapon.Push(kvWeapons.GetNum("weaponindex", 0));       // Index: 2
        arrayWeapon.Push(kvWeapons.GetNum("weaponcost", 0));        // Index: 3
        arrayWeapon.Push(kvWeapons.GetNum("weaponslot", 0));        // Index: 4
        arrayWeapon.Push(kvWeapons.GetNum("weaponlevel", 0));       // Index: 5
        arrayWeapon.Push(kvWeapons.GetNum("weapononline", 0));      // Index: 6
        arrayWeapon.Push(kvWeapons.GetFloat("weapondamage", 1.0));  // Index: 7
        arrayWeapon.Push(kvWeapons.GetFloat("weaponknock", 1.0));   // Index: 8
        arrayWeapon.Push(kvWeapons.GetNum("weaponclip", 0));        // Index: 9
        arrayWeapon.Push(kvWeapons.GetNum("weaponammo", 0));        // Index: 10
        arrayWeapon.Push(kvWeapons.GetNum("weaponclass", 0));       // Index: 11
        arrayWeapon.PushString(sWeaponModelView);                   // Index: 12    
        arrayWeapon.Push(ModelsViewPrecache(sWeaponModelView));     // Index: 13
        arrayWeapon.PushString(sWeaponModelWorld);                  // Index: 14
        arrayWeapon.Push(ModelsViewPrecache(sWeaponModelWorld));    // Index: 15
        arrayWeapon.Push(kvWeapons.GetNum("weaponbody", 0));        // Index: 16
        arrayWeapon.Push(kvWeapons.GetNum("weaponskin", 0));        // Index: 17
        arrayWeapon.Push(kvWeapons.GetFloat("weaponheat", 0.5));    // Index: 18
        arrayWeapon.Push(-1);                                       // Index: 19
        arrayWeapon.PushArray(swapSequences);                       // Index: 20
    }

    // We're done with this file now, so we can close it
    delete kvWeapons;
}

/**
 * Called when config is being reloaded.
 **/
public void WeaponsOnConfigReload(/*void*/)
{
    // Reload weapons config
    WeaponsLoad();
}

/**
 * Purge weapon SDK data.
 **/
void WeaponsUnload(/*void*/)
{
    // Forward event to sub-modules
    WeaponSDKUnload();
    WeaponAttachUnload();
}

/**
 * Creates commands for weapons module. Called when commands are created.
 **/
void WeaponsOnCommandsCreate(/*void*/)
{
    // Forward event to sub-modules
    ZMarketOnCommandsCreate();
}

/**
 * Client is joining the server.
 * 
 * @param clientIndex       The client index.  
 **/
void WeaponsClientInit(int clientIndex)
{
    // Forward event to sub-modules
    WeaponSDKClientInit(clientIndex);
}

/**
 * Client has been fired.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
void WeaponsOnFire(int clientIndex, int weaponIndex) 
{
    // Forward event to sub-modules
    WeaponSDKOnFire(clientIndex, weaponIndex);
}

/**
 * Client has been carried hostage.
 *
 * @param clientIndex       The client index.
 **/
void WeaponsOnHostage(int clientIndex) 
{
    // Forward event to sub-modules
    WeaponSDKOnHostage(clientIndex);
}

/**
 * Client has been changed class state. (Post)
 *
 * @param userID            The user id.
 **/
public void WeaponsOnClientUpdate(int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Forward event to sub-modules
        WeaponSDKOnClientUpdate(clientIndex);
        ZMarketOnClientUpdate(clientIndex);
    }
}

/**
 * Client has been killed.
 *
 * @param clientIndex       The client index.
 **/
public void WeaponsOnClientDeath(int clientIndex)
{
    // Forward event to sub-modules
    WeaponSDKOnClientDeath(clientIndex);
}

/**
 * Called, when an entity is created.
 *
 * @param entityIndex       The entity index.
 * @param sClassname        The string with returned name.
 **/
public void OnEntityCreated(int entityIndex, const char[] sClassname)
{
    // Validate entity
    if(entityIndex > INVALID_ENT_REFERENCE) /// Avoid the invalid index for array
    {
        // Forward event to sub-modules
        WeaponSDKOnCreated(entityIndex, sClassname);
    }
}

/*
 * Weapons natives API.
 */

/**
 * Gives the weapon by a given name.
 *
 * native int ZP_GiveClientWeapon(client, name);
 **/
public int API_GiveClientWeapon(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return -1;
    }

    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(2, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Can't find weapon with an empty name");
        return -1;
    }

    // Gets native data
    char sName[SMALL_LINE_LENGTH];

    // General                                            
    GetNativeString(2, sName, sizeof(sName));

    // Give weapon
    return WeaponsGive(clientIndex, sName);
}

/**
 * Gets the custom weapon id from a given weapon.
 *
 * native int ZP_GetWeaponID(weaponIndex);
 **/
public int API_GetWeaponID(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell 
    int weaponIndex = GetNativeCell(1);

    // Validate weapon
    if(weaponIndex <= INVALID_ENT_REFERENCE)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", weaponIndex);
        return -1;
    }
    
    // Return the value
    return gWeaponData[weaponIndex];
}

/**
 * Gets the custom weapon id from a given name.
 *
 * native int ZP_GetWeaponNameID(name);
 **/
public int API_GetWeaponNameID(Handle isPlugin, int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Can't find weapon with an empty name");
        return -1;
    }

    // Gets native data
    char sName[SMALL_LINE_LENGTH];

    // General                                            
    GetNativeString(1, sName, sizeof(sName));
    
    // Return the value
    return WeaponsNameToIndex(sName);
}

/**
 * Gets the amount of all weapons.
 *
 * native int ZP_GetNumberWeapon();
 **/
public int API_GetNumberWeapon(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return GetArraySize(arrayWeapons);
}

/**
 * Gets the name of a weapon at a given id.
 *
 * native void ZP_GetWeaponName(iD, name, maxlen);
 **/
public int API_GetWeaponName(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    WeaponsGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the entity of a weapon at a given id.
 *
 * native void ZP_GetWeaponEntity(iD, entity, maxlen);
 **/
public int API_GetWeaponEntity(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize entity char
    static char sEntity[SMALL_LINE_LENGTH];
    WeaponsGetEntity(iD, sEntity, sizeof(sEntity));

    // Return on success
    return SetNativeString(2, sEntity, maxLen);
}

/**
 * Gets the definition index of the weapon.
 *
 * native int ZP_GetWeaponIndex(iD);
 **/
public int API_GetWeaponIndex(Handle isPlugin, int iNumParams)
{    
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetIndex(iD);
}

/**
 * Gets the cost of the weapon.
 *
 * native int ZP_GetWeaponCost(iD);
 **/
public int API_GetWeaponCost(Handle isPlugin, int iNumParams)
{    
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetCost(iD);
}

/**
 * Gets the slot of the weapon.
 *
 * native int ZP_GetWeaponSlot(iD);
 **/
public int API_GetWeaponSlot(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetSlot(iD);
}

/**
 * Gets the level of the weapon.
 *
 * native int ZP_GetWeaponLevel(iD);
 **/
public int API_GetWeaponLevel(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetLevel(iD);
}

/**
 * Gets the online of the weapon.
 *
 * native int ZP_GetWeaponOnline(iD);
 **/
public int API_GetWeaponOnline(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetOnline(iD);
}

/**
 * Gets the damage of the weapon.
 *
 * native float ZP_GetWeaponDamage(iD);
 **/
public int API_GetWeaponDamage(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetDamage(iD));
}

/**
 * Gets the knockback of the weapon.
 *
 * native float ZP_GetWeaponKnockBack(iD);
 **/
public int API_GetWeaponKnockBack(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetKnockBack(iD));
}

/**
 * Gets the clip ammo of the weapon.
 *
 * native int ZP_GetWeaponClip(iD);
 **/
public int API_GetWeaponClip(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetClip(iD);
}

/**
 * Gets the reserve ammo of the weapon.
 *
 * native int ZP_GetWeaponAmmo(iD);
 **/
public int API_GetWeaponAmmo(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetAmmo(iD);
}

/**
 * Gets the class access of the weapon.
 *
 * native int ZP_GetWeaponClass(iD);
 **/
public int API_GetWeaponClass(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return view_as<int>(WeaponsGetClass(iD));
}

/**
 * Gets the view model path a weapon at a given id.
 *
 * native void ZP_GetWeaponModelView(iD, model, maxlen);
 **/
public int API_GetWeaponModelView(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sEntity[PLATFORM_MAX_PATH];
    WeaponsGetModelView(iD, sEntity, sizeof(sEntity));

    // Return on success
    return SetNativeString(2, sEntity, maxLen);
}

/**
 * Gets the index of the weapon view model.
 *
 * native int ZP_GetWeaponModelViewID(iD);
 **/
public int API_GetWeaponModelViewID(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelViewID(iD);
}

/**
 * Gets the world model path a weapon at a given id.
 *
 * native void ZP_GetWeaponModelWorld(iD, model, maxlen);
 **/
public int API_GetWeaponModelWorld(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sEntity[PLATFORM_MAX_PATH];
    WeaponsGetModelWorld(iD, sEntity, sizeof(sEntity));

    // Return on success
    return SetNativeString(2, sEntity, maxLen);
}

/**
 * Gets the index of the weapon world model.
 *
 * native int ZP_GetWeaponModelWorldID(iD);
 **/
public int API_GetWeaponModelWorldID(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelWorldID(iD);
}

/**
 * Gets the body index of the weapon view model.
 *
 * native int ZP_GetWeaponModelViewBody(iD);
 **/
public int API_GetWeaponModelViewBody(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelViewBody(iD);
}

/**
 * Gets the skin index of the weapon view model.
 *
 * native int ZP_GetWeaponModelViewSkin(iD);
 **/
public int API_GetWeaponModelViewSkin(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelViewSkin(iD);
}

/**
 * Gets the skin index of the weapon view model.
 *
 * native float ZP_GetWeaponModelViewHeat(iD);
 **/
public int API_GetWeaponModelViewHeat(Handle isPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayWeapons))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetModelViewHeat(iD));
}

/*
 * Weapons data reading API.
 */

/**
 * Gets the name of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sClassname        The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetName(int iD, char[] sClassname, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon name
    arrayWeapon.GetString(WEAPONS_DATA_NAME, sClassname, iMaxLen);
}

/**
 * Gets the entity of a weapon at a given id.
 *
 * @param iD                The weapon id.
 * @param sType             The string to return entity in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetEntity(int iD, char[] sType, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon type
    arrayWeapon.GetString(WEAPONS_DATA_ENTITY, sType, iMaxLen);
}

/**
 * Gets the definition index of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The definition index. (m_iItemDefinitionIndex)
 **/
stock int WeaponsGetIndex(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon definition index
    return arrayWeapon.Get(WEAPONS_DATA_INDEX);
}

/**
 * Gets the cost of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The cost amount.
 **/
stock int WeaponsGetCost(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon cost
    return arrayWeapon.Get(WEAPONS_DATA_COST);
}

/**
 * Gets the slot of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The weapon slot.    
 **/
stock int WeaponsGetSlot(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon slot
    return arrayWeapon.Get(WEAPONS_DATA_SLOT);
}

/**
 * Gets the level of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The level amount.    
 **/
stock int WeaponsGetLevel(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon level
    return arrayWeapon.Get(WEAPONS_DATA_LEVEL);
}

/**
 * Gets the online of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The online amount.
 **/
stock int WeaponsGetOnline(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon online
    return arrayWeapon.Get(WEAPONS_DATA_ONLINE);
}

/**
 * Gets the damage of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The damage amount.    
 **/
stock float WeaponsGetDamage(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon damage
    return arrayWeapon.Get(WEAPONS_DATA_DAMAGE);
}

/**
 * Gets the knockback of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The knockback amount.    
 **/
stock float WeaponsGetKnockBack(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon knockback
    return arrayWeapon.Get(WEAPONS_DATA_KNOCKBACK);
}

/**
 * Gets the clip ammo of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The clip ammo amount.
 **/
stock int WeaponsGetClip(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon clip ammo
    return arrayWeapon.Get(WEAPONS_DATA_CLIP);
}

/**
 * Gets the reserve ammo of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The reserve ammo amount.
 **/
stock int WeaponsGetAmmo(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon reserve ammo
    return arrayWeapon.Get(WEAPONS_DATA_AMMO);
}

/**
 * Gets the class access of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The class access index.
 **/
stock WeaponSDKClassType WeaponsGetClass(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon reserve ammo
    return arrayWeapon.Get(WEAPONS_DATA_CLASS);
}

/**
 * Gets the path of a weapon view model at a given id.
 *
 * @param iD                The weapon id.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetModelView(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
     // Gets weapon view model
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_VIEW, sModel, iMaxLen);
}

/**
 * Gets the index of the weapon view model.
 *
 * @param iD                The weapon id.
 * @return                  The model index.
 **/
stock int WeaponsGetModelViewID(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon view model index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_VIEW_ID);
}

/**
 * Gets the path of a weapon world model at a given id.
 *
 * @param iD                The weapon id.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetModelWorld(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon world model
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_WORLD, sModel, iMaxLen);
}

/**
 * Gets the index of the weapon world model.
 *
 * @param iD                The weapon id.
 * @return                  The model index.
 **/
stock int WeaponsGetModelWorldID(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon world model index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_WORLD_ID);
}

/**
 * Gets the body index of the weapon view model.
 *
 * @param iD                The weapon id.
 * @return                  The body index.
 **/
stock int WeaponsGetModelViewBody(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon view model body index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_BODY);
}

/**
 * Gets the skin index of the weapon view model.
 *
 * @param iD                The weapon id.
 * @return                  The body index.
 **/
stock int WeaponsGetModelViewSkin(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon view model skin index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_SKIN);
}

/**
 * Gets the heat amount of the weapon view model. (For muzzleflash)
 *
 * @param iD                The weapon id.
 * @return                  The heat amount.    
 **/
stock float WeaponsGetModelViewHeat(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets heat amount
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_HEAT);
}

/**
 * Sets the amount of the weapon sequences.
 *
 * @param iD                The weapon id.
 * @param nSequence         The sequences amount.
 **/
stock void WeaponsSetSequenceCount(int iD, int nSequence)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Sets weapon sequences amount
    arrayWeapon.Set(WEAPONS_DATA_SEQUENCE_COUNT, nSequence);
}

/**
 * Gets the amount of the weapon sequences.
 *
 * @param iD                The weapon id.
 * @return                  The sequences amount.
 **/
stock int WeaponsGetSequenceCount(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon sequences amount
    return arrayWeapon.Get(WEAPONS_DATA_SEQUENCE_COUNT);
}

/**
 * Sets the swap of the weapon sequences.
 *
 * @param iD                The weapon id.
 * @param iSequences        The array to return sequences in.
 * @param iMaxLen           The max length of the array.
 **/
stock void WeaponsSetSequenceSwap(int iD, int[] iSequences, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Sets weapon sequences swap
    arrayWeapon.SetArray(WEAPONS_DATA_SEQUENCE_SWAP, iSequences, iMaxLen);
}

/**
 * Gets the swap of the weapon sequences. (at index)
 *
 * @param iD                The weapon id.
 * @param nSequence         The position index.
 * @return                  The sequences index.
 **/
stock int WeaponsGetSequenceSwap(int iD, int nSequence)
{
    // Create a array
    int iSequences[WeaponsSequencesMax];

    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);

    // Gets weapon sequences swap at index
    arrayWeapon.GetArray(WEAPONS_DATA_SEQUENCE_SWAP, iSequences, sizeof(iSequences));

    // Gets weapon sequence
    return iSequences[nSequence];
}

/**
 * Clears the swap of the weapon sequences.
 *
 * @param iD                The weapon id.
 **/
stock void WeaponsClearSequenceSwap(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Clear weapon sequences swap
    arrayWeapon.Erase(WEAPONS_DATA_SEQUENCE_SWAP);
}

/*
 * Stocks weapons API.
 */

/**
 * Find the index at which the weapon's name is at.
 * 
 * @param sWeapon           The weapon name.
 * @param iMaxLen           (Only if 'overwritename' is true) The max length of the weapon name. 
 * @param bOverWriteName    (Optional) If true, the hitgroup given will be overwritten with the name from the config.
 * @return                  The array index containing the given weapon name.
 **/
stock int WeaponsNameToIndex(char[] sWeapon, int iMaxLen = 0, bool bOverWriteName = false)
{
    // Initialize char
    static char sWeaponName[SMALL_LINE_LENGTH];
    
    // i = weapon index
    int iSize = GetArraySize(arrayWeapons);
    for (int i = 0; i < iSize; i++)
    {
        // Gets weapon name 
        WeaponsGetName(i, sWeaponName, sizeof(sWeaponName));
        
        // If names match, then return index
        if (!strcmp(sWeapon, sWeaponName, false))
        {
            // If 'overwrite' name is true, then overwrite the old string with new
            if (bOverWriteName)
            {
                // Copy config name to return string
                strcopy(sWeapon, iMaxLen, sWeaponName);
            }
            
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return INVALID_ENT_REFERENCE;
}
 
/**
 * Drop weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param bNormalDrop       True to drop client's weapon, false to remove it.
 **/
stock void WeaponsDrop(int clientIndex, int weaponIndex, bool bNormalDrop = true)
{
    // Validate weapon
    if(IsValidEdict(weaponIndex)) 
    {
        // Validate normal dropping
        if(bNormalDrop)
        {
            // Get the owner of the weapon
            int ownerIndex = GetEntDataEnt2(weaponIndex, g_iOffset_EntityOwnerEntity);

            // If owner index is different, so set it again
            if(ownerIndex != clientIndex)
            {
                SetEntDataEnt2(weaponIndex, g_iOffset_EntityOwnerEntity, clientIndex, true);
            }

            // Forces a player to drop weapon
            SDKCall(hSDKCallCSWeaponDrop, clientIndex, weaponIndex, true, false);
        }
        // Remove otherwise
        else
        {
            // Forces a player to remove weapon
            RemovePlayerItem(clientIndex, weaponIndex);
            AcceptEntityInput(weaponIndex, "Kill");
        }
    }
}

/**
 * Returns true if the player has a weapon, false if not.
 *
 * @param clientIndex       The client index.
 * @param iD                The weapon id.
 *
 * @return                  True or false.
 **/
stock bool WeaponsIsExist(int clientIndex, int iD)
{
    // i = weapon number
    int iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_CharacterWeapons + (i * 4));
        
        // Validate weapon
        if(weaponIndex > INVALID_ENT_REFERENCE)
        {
            // If weapon find, then return
            if(gWeaponData[weaponIndex] == iD)
            {
                return true;
            }
        }
        
        // Go to next weapon
        continue;
    }

    // If wasn't found
    return false;
}

/**
 * Remove all weapons and give default weapon.
 *
 * @param clientIndex       The client index.
 * @param hConVar           The cvar handler.
 * @return                  True on success, false if weapon already exist. 
 **/
stock bool WeaponsRemoveAll(int clientIndex, ConVar hConVar)
{
    // i = weapon number
    int iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_CharacterWeapons + (i * 4));
        
        // Validate weapon
        if(weaponIndex > INVALID_ENT_REFERENCE)
        {
            // Validate custom index
            int iD = gWeaponData[weaponIndex];
            if(iD != -1)
            {
                // Switch class access
                switch(WeaponsGetClass(iD))
                {
                    // Validate human class
                    case ClassType_Human : if(!gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Survivor])   return false;
                    
                    // Validate survivor class
                    case ClassType_Survivor : if(!gClientData[clientIndex][Client_Zombie] && gClientData[clientIndex][Client_Survivor]) return false;
                    
                    // Validate zombie class
                    case ClassType_Zombie : if(gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Nemesis])    return false;
                    
                    // Validate nemesis class
                    case ClassType_Nemesis : if(gClientData[clientIndex][Client_Zombie] && gClientData[clientIndex][Client_Nemesis])    return false;
                }
            }
        }
    }
    
    // Create SDK call to the remove weapons
    SDKCall(hSDKCallRemoveAllItems, clientIndex);

    // Gets weapon's name from a convar handler
    static char sName[SMALL_LINE_LENGTH];
    hConVar.GetString(sName, sizeof(sName));
    
    // Give weapon
    return (WeaponsGive(clientIndex, sName) != INVALID_ENT_REFERENCE) ? true : false;
}

/**
 * Give weapons.
 *
 * @param clientIndex       The client index.
 * @param hConVar           The cvar handler.
 **/
stock void WeaponsGiveAll(int clientIndex, ConVar hConVar)
{
    // Gets weapons' list name from a convar handler
    static char sList[BIG_LINE_LENGTH];
    hConVar.GetString(sList, sizeof(sList));

    // Validate length
    if(strlen(sList))
    {
        // Convert list string to pieces
        static char sName[6][SMALL_LINE_LENGTH];
        int iSize = ExplodeString(sList, " ", sName, sizeof(sName), sizeof(sName[]));

        // Loop throught pieces
        for(int i = 0; i < iSize; i++)
        {
            // Give weapon
            WeaponsGive(clientIndex, sName[i]);
        }
    }
}

/**
 * Give weapon from a name string.
 *
 * @param clientIndex       The client index.
 * @param sName             The weapon name.
 * @return                  The weapon index.
 **/
stock int WeaponsGive(int clientIndex, char[] sName)
{
    // Initialize index
    int weaponIndex = INVALID_ENT_REFERENCE;

    // Remove whitespaces
    TrimString(sName);

    /*
     * Currently the fastest approach is store an item's index into the global array,
     * because the game call some hooks really frequently and loop for find id can cost more.
     */
    
    // Validate length
    if(strlen(sName)) 
    {
        // Validate weapon index
        int iD = WeaponsNameToIndex(sName);
        if(iD != -1)        
        {
            // Switch class access
            switch(WeaponsGetClass(iD))
            {
                // Validate human class
                case ClassType_Human : if(!(!gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Survivor]))   return weaponIndex;
                
                // Validate survivor class
                case ClassType_Survivor : if(!(!gClientData[clientIndex][Client_Zombie] && gClientData[clientIndex][Client_Survivor])) return weaponIndex;
                
                // Validate zombie class
                case ClassType_Zombie : if(!(gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Nemesis]))    return weaponIndex;
                
                // Validate nemesis class
                case ClassType_Nemesis : if(!(gClientData[clientIndex][Client_Zombie] && gClientData[clientIndex][Client_Nemesis]))    return weaponIndex;
            }
    
            // Gets weapon classname
            WeaponsGetEntity(iD, sName, SMALL_LINE_LENGTH);

            // Give weapon
            weaponIndex = GivePlayerItem(clientIndex, sName);
            
            // Validate index
            if(weaponIndex != INVALID_ENT_REFERENCE) 
            {
                // Sets the weapon id
                gWeaponData[weaponIndex] = iD;
                
                // Switch the weapon
                SDKCall(hSDKCallWeaponSwitch, clientIndex, weaponIndex, 0);
                SetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon, weaponIndex, true);
            }
        }
    }

    // Return on unsuccess
    return weaponIndex;
}

/**
 * Returns true if the player has a knife, false if not.
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  True or false.    
 **/
stock bool WeaponsValidateKnife(int weaponIndex)
{
    // Validate weapon
    if(IsValidEdict(weaponIndex))
    {
        // Gets client weapon's classname
        static char sWeapon[SMALL_LINE_LENGTH];
        GetEdictClassname(weaponIndex, sWeapon, sizeof(sWeapon));

        // Return on success
        return (!strcmp(sWeapon[7], "knife", false));
    }
    
    // Stop
    return false;
}

/**
 * Returns true if the player has a taser, false if not.
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  True or false.    
 **/
stock bool WeaponsValidateTaser(int weaponIndex)
{
    // Gets client weapon's classname
    static char sWeapon[SMALL_LINE_LENGTH];
    GetEdictClassname(weaponIndex, sWeapon, sizeof(sWeapon));

    // Return on success
    return (!strcmp(sWeapon[7], "taser", false));
}

/**
 * Returns true if the player has a grenade, false if not.
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  True or false.    
 **/
stock bool WeaponsValidateGrenade(int weaponIndex)
{
    // Gets client weapon's classname
    static char sWeapon[SMALL_LINE_LENGTH];
    GetEdictClassname(weaponIndex, sWeapon, sizeof(sWeapon));

    // Return on success
    return (!strcmp(sWeapon[7], "hegrenade", false) || !strcmp(sWeapon[7], "decoy", false) || !strcmp(sWeapon[7], "flashbang", false) || !strcmp(sWeapon[7], "incgrenade", false) || !strcmp(sWeapon[7], "molotov", false) || !strcmp(sWeapon[7], "smokegrenade", false) || !strcmp(sWeapon[7], "tagrenade", false));
}
