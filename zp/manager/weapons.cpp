/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          weapons.cpp
 *  Type:          Manager
 *  Description:   API for all weapon-related functions.
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
 * Number of max valid sequences.
 **/
#define WEAPONS_SEQUENCE_MAX 32
 
/**
 * Array handle to store weapon config data.
 **/
ArrayList arrayWeapons;

/**
 * @section Weapon config data indexes.
 **/
enum
{
    WEAPONS_DATA_NAME,
    WEAPONS_DATA_INFO,
    WEAPONS_DATA_ENTITY,
    WEAPONS_DATA_GROUP,
    WEAPONS_DATA_COST,
    WEAPONS_DATA_SLOT,
    WEAPONS_DATA_LEVEL,
    WEAPONS_DATA_ONLINE,
    WEAPONS_DATA_DAMAGE,
    WEAPONS_DATA_KNOCKBACK,
    WEAPONS_DATA_CLIP,
    WEAPONS_DATA_AMMO,
    WEAPONS_DATA_AMMUNITION,
    WEAPONS_DATA_SPEED,
    WEAPONS_DATA_RELOAD,
    WEAPONS_DATA_DEPLOY,
    WEAPONS_DATA_SOUND,
    WEAPONS_DATA_CLASS,
    WEAPONS_DATA_MODEL_VIEW,
    WEAPONS_DATA_MODEL_VIEW_,
    WEAPONS_DATA_MODEL_WORLD,
    WEAPONS_DATA_MODEL_WORLD_,
    WEAPONS_DATA_MODEL_DROP,
    WEAPONS_DATA_MODEL_DROP_,
    WEAPONS_DATA_MODEL_BODY,
    WEAPONS_DATA_MODEL_SKIN,
    WEAPONS_DATA_MODEL_MUZZLE,
    WEAPONS_DATA_MODEL_HEAT,
    WEAPONS_DATA_SEQUENCE_COUNT,
    WEAPONS_DATA_SEQUENCE_SWAP
}
/**
 * @endsection
 **/
 
/*
 * Load other weapons modules
 */
#include "zp/manager/weapons/weaponsdk.cpp"
#include "zp/manager/weapons/weaponhdr.cpp"
#include "zp/manager/weapons/weaponattach.cpp"
#include "zp/manager/weapons/zmarket.cpp"

/**
 * Weapons module init function.
 **/
void WeaponsInit(/*void*/)
{
    // Hook player events
    HookEvent("weapon_fire",       WeaponsOnFire,    EventHookMode_Pre);
    HookEvent("bullet_impact",     WeaponsOnBullet,  EventHookMode_Post);
    HookEvent("hostage_follows",   WeaponsOnHostage, EventHookMode_Post);
    
    // Hook temp events
    AddTempEntHook("Shotgun Shot", WeaponsOnShoot);
    
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
    bool bExists = ConfigGetFullPath(CONFIG_PATH_WEAPONS, sPathWeapons);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Missing weapons config file: \"%s\"", sPathWeapons);
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_Weapons, sPathWeapons);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Weapons, arrayWeapons);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathWeapons);
    }

    // Validate weapons config
    int iSize = arrayWeapons.Length;
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
    // Gets config file path
    static char sPathWeapons[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Weapons, sPathWeapons, sizeof(sPathWeapons));

    // Open config
    KeyValues kvWeapons;
    bool bSuccess = ConfigOpenConfigFile(File_Weapons, kvWeapons);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error caching data from weapons config file: \"%s\"", sPathWeapons);
    }

    // i = array index
    int iSize = arrayWeapons.Length;
    for(int i = 0; i < iSize; i++)
    {
        // General
        WeaponsGetName(i, sPathWeapons, sizeof(sPathWeapons)); // Index: 0
        kvWeapons.Rewind();
        if(!kvWeapons.JumpToKey(sPathWeapons))
        {
            // Log weapon fatal
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon data for: \"%s\" (check weapons config)", sPathWeapons);
            continue;
        }
        
        // Validate translation
        if(!TranslationPhraseExists(sPathWeapons))
        {
            // Log weapon error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon name: \"%s\" (check translation file)", sPathWeapons);
        }
        
        // Gets array size
        ArrayList arrayWeapon = arrayWeapons.Get(i); 
 
        // Push data into array
        kvWeapons.GetString("info", sPathWeapons, sizeof(sPathWeapons), "");
        if(!TranslationPhraseExists(sPathWeapons) && hasLength(sPathWeapons))
        {
            // Log weapon error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon info: \"%s\" (check translation file)", sPathWeapons);
        }
        arrayWeapon.PushString(sPathWeapons);                   // Index: 1
        kvWeapons.GetString("entity", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                   // Index: 2
        kvWeapons.GetString("group", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                   // Index: 3
        arrayWeapon.Push(kvWeapons.GetNum("cost", 0));          // Index: 4
        arrayWeapon.Push(kvWeapons.GetNum("slot", 0));          // Index: 5
        arrayWeapon.Push(kvWeapons.GetNum("level", 0));         // Index: 6
        arrayWeapon.Push(kvWeapons.GetNum("online", 0));        // Index: 7
        arrayWeapon.Push(kvWeapons.GetFloat("damage", 1.0));    // Index: 8
        arrayWeapon.Push(kvWeapons.GetFloat("knockback", 1.0)); // Index: 9
        arrayWeapon.Push(kvWeapons.GetNum("clip", 0));          // Index: 10
        arrayWeapon.Push(kvWeapons.GetNum("ammo", 0));          // Index: 11
        arrayWeapon.Push(kvWeapons.GetNum("ammunition", 0));    // Index: 12
        arrayWeapon.Push(kvWeapons.GetFloat("speed", 0.0));     // Index: 13
        arrayWeapon.Push(kvWeapons.GetFloat("reload", 0.0));    // Index: 14
        arrayWeapon.Push(kvWeapons.GetFloat("deploy", 0.0));    // Index: 15
        kvWeapons.GetString("sound", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.Push(SoundsKeyToIndex(sPathWeapons));       // Index: 16
        kvWeapons.GetString("class", sPathWeapons, sizeof(sPathWeapons), "human");
        arrayWeapon.PushString(sPathWeapons);                   // Index: 17
        kvWeapons.GetString("view", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                   // Index: 18    
        arrayWeapon.Push(ModelsPrecacheWeapon(sPathWeapons));   // Index: 19
        kvWeapons.GetString("world", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                   // Index: 20
        arrayWeapon.Push(ModelsPrecacheStatic(sPathWeapons));   // Index: 21
        kvWeapons.GetString("dropped", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                   // Index: 22
        arrayWeapon.Push(ModelsPrecacheStatic(sPathWeapons));   // Index: 23
        int iBody[4]; kvWeapons.GetColor4("body", iBody);
        arrayWeapon.PushArray(iBody, sizeof(iBody));            // Index: 24
        int iSkin[4]; kvWeapons.GetColor4("skin", iSkin);
        arrayWeapon.PushArray(iSkin, sizeof(iSkin));            // Index: 25
        kvWeapons.GetString("muzzle", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                   // Index: 26
        arrayWeapon.Push(kvWeapons.GetFloat("heat", 0.5));      // Index: 27
        arrayWeapon.Push(-1); int iSeq[WEAPONS_SEQUENCE_MAX];   // Index: 28
        arrayWeapon.PushArray(iSeq, sizeof(iSeq));              // Index: 29
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
 * Creates commands for weapons module.
 **/
void WeaponsOnCommandsCreate(/*void*/)
{
    // Forward event to sub-modules
    ZMarketOnCommandsCreate();
    WeaponSDKOnCommandsCreate();
}

/**
 * Purge weapon SDK data.
 **/
void WeaponsUnload(/*void*/)
{
    // Forward event to sub-modules
    WeaponAttachUnload();
    WeaponSDKUnload();
}

/**
 * Client is joining the server.
 * 
 * @param clientIndex       The client index.  
 **/
void WeaponsClientInit(const int clientIndex)
{
    // Forward event to sub-modules
    WeaponSDKClientInit(clientIndex);
}

/**
 * Hook weapons cvar changes.
 **/
void WeaponsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_SERVER_GIVE_WEAPON] = FindConVar("mp_weapons_allow_map_placed");
    gCvarList[CVAR_SERVER_GIVE_TASER]  = FindConVar("mp_weapons_allow_zeus");
    gCvarList[CVAR_SERVER_GIVE_BOMB]   = FindConVar("mp_give_player_c4");
    
    // Sets locked cvars to their locked value
    gCvarList[CVAR_SERVER_GIVE_WEAPON].IntValue = 0;
    gCvarList[CVAR_SERVER_GIVE_TASER].IntValue  = 1;
    gCvarList[CVAR_SERVER_GIVE_BOMB].IntValue   = 1;
    
    // Hook locked cvars to prevent it from changing
    HookConVarChange(gCvarList[CVAR_SERVER_GIVE_WEAPON], CvarsHookLocked);    
    HookConVarChange(gCvarList[CVAR_SERVER_GIVE_TASER],  CvarsHookUnlocked);
    HookConVarChange(gCvarList[CVAR_SERVER_GIVE_BOMB],   CvarsHookUnlocked);
}

/**
 * Event callback (weapon_fire)
 * Client has been shooted.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponsOnFire(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Gets active weapon index from the client
    int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon);
    
    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        return;
    }
    
    // Forward event to sub-modules
    WeaponSDKOnFire(clientIndex, weaponIndex);
}

/**
 * Event callback (bullet_impact)
 * The bullet hits something.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponsOnBullet(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Gets active weapon index from the client
    int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon);
    
    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        return;
    }
    
    // Initialize vector
    static float vBulletPosition[3];

    // Gets bullet position
    vBulletPosition[0] = hEvent.GetFloat("x");
    vBulletPosition[1] = hEvent.GetFloat("y");
    vBulletPosition[2] = hEvent.GetFloat("z");
    
    // Forward event to sub-modules
    WeaponSDKOnBullet(clientIndex, vBulletPosition, weaponIndex);
}

/**
 * Event callback (hostage_follows)
 * Client has been carried hostage.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponsOnHostage(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // Forward event to sub-modules
    WeaponSDKOnHostage(clientIndex);
}

/**
 * Event callback (Shotgun Shot)
 * The bullet was been created.
 * 
 * @param sTEName           The temp name.
 * @param iPlayers          Array containing target player indexes.
 * @param numClients        Number of players in the array.
 * @param flDelay           Delay in seconds to send the TE.
 **/ 
public Action WeaponsOnShoot(const char[] sTEName, const int[] iPlayers, int numClients, float flDelay) 
{ 
    // Gets all required event info
    int clientIndex = TE_ReadNum("m_iPlayer") + 1;

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Continue;
    }
    
    // Gets active weapon index from the client
    int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon);
    
    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        return Plugin_Continue;
    }
    
    // Forward event to sub-modules
    return WeaponSDKOnShoot(clientIndex, weaponIndex);
}

/**
 * Called on each frame of a weapon holding.
 * 
 * @param clientIndex       The client index.
 * @param iButtons          The button buffer.
 * @param iLastButtons      The last button buffer.
 **/
Action WeaponsOnRunCmd(const int clientIndex, int &iButtons, const int iLastButtons)
{
    // Gets active weapon index from the client
    static int weaponIndex; weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon);

    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        return Plugin_Continue;
    }
    
    // Forward event to sub-modules
    return WeaponSDKOnRunCmd(clientIndex, iButtons, iLastButtons, weaponIndex);
}

/**
 * Client has been changed class state. (Post)
 *
 * @param userID            The user id.
 **/
public void WeaponsOnClientUpdate(const int userID)
{
    // Gets client index from the user ID
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
void WeaponsOnClientDeath(const int clientIndex)
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
    if(entityIndex > INVALID_ENT_REFERENCE) /// Bugfix for some sm builds
    {
        // Forward event to sub-modules
        WeaponSDKOnCreated(entityIndex, sClassname);
    }
}

/*
 * Weapons natives API.
 */

/**
 * Sets up natives for library.
 **/
void WeaponsAPI(/*void*/) 
{
    CreateNative("ZP_GiveClientWeapon",      API_GiveClientWeapon);
    CreateNative("ZP_GetClientViewModel",    API_GetClientViewModel);
    CreateNative("ZP_GetClientAttachModel",  API_GetClientAttachModel);
    CreateNative("ZP_GetWeaponNameID",       API_GetWeaponNameID);
    CreateNative("ZP_GetWeaponID",           API_GetWeaponID);
    CreateNative("ZP_GetNumberWeapon",       API_GetNumberWeapon);
    CreateNative("ZP_GetWeaponName",         API_GetWeaponName);
    CreateNative("ZP_GetWeaponInfo",         API_GetWeaponInfo);
    CreateNative("ZP_GetWeaponEntity",       API_GetWeaponEntity);
    CreateNative("ZP_GetWeaponGroup",        API_GetWeaponGroup);
    CreateNative("ZP_GetWeaponCost",         API_GetWeaponCost);
    CreateNative("ZP_GetWeaponSlot",         API_GetWeaponSlot);
    CreateNative("ZP_GetWeaponLevel",        API_GetWeaponLevel);
    CreateNative("ZP_GetWeaponOnline",       API_GetWeaponOnline);
    CreateNative("ZP_GetWeaponDamage",       API_GetWeaponDamage);
    CreateNative("ZP_GetWeaponKnockBack",    API_GetWeaponKnockBack);
    CreateNative("ZP_GetWeaponClip",         API_GetWeaponClip);
    CreateNative("ZP_GetWeaponAmmo",         API_GetWeaponAmmo);
    CreateNative("ZP_GetWeaponAmmunition",   API_GetWeaponAmmunition);
    CreateNative("ZP_GetWeaponSpeed",        API_GetWeaponSpeed);
    CreateNative("ZP_GetWeaponReload",       API_GetWeaponReload);
    CreateNative("ZP_GetWeaponDeploy",       API_GetWeaponDeploy);
    CreateNative("ZP_GetWeaponSoundID",      API_GetWeaponSoundID);
    CreateNative("ZP_GetWeaponClass",        API_GetWeaponClass);
    CreateNative("ZP_GetWeaponModelView",    API_GetWeaponModelView);
    CreateNative("ZP_GetWeaponModelViewID",  API_GetWeaponModelViewID);
    CreateNative("ZP_GetWeaponModelWorld",   API_GetWeaponModelWorld);    
    CreateNative("ZP_GetWeaponModelWorldID", API_GetWeaponModelWorldID); 
    CreateNative("ZP_GetWeaponModelDrop",    API_GetWeaponModelDrop);    
    CreateNative("ZP_GetWeaponModelDropID",  API_GetWeaponModelDropID); 
    CreateNative("ZP_GetWeaponModelBody",    API_GetWeaponModelBody); 
    CreateNative("ZP_GetWeaponModelSkin",    API_GetWeaponModelSkin); 
    CreateNative("ZP_GetWeaponModelMuzzle",  API_GetWeaponModelMuzzle);
    CreateNative("ZP_GetWeaponModelHeat",    API_GetWeaponModelHeat); 
}
 
/**
 * Gives the weapon by a given id.
 *
 * native int ZP_GiveClientWeapon(client, id, slot, remove);
 **/
public int API_GiveClientWeapon(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return -1;
    }

    // Validate slot
    SlotType slotType = GetNativeCell(3);
    if(slotType != SlotType_Invalid)
    {
        // Drop weapon
        WeaponsDrop(clientIndex, GetPlayerWeaponSlot(clientIndex, view_as<int>(slotType)), GetNativeCell(4));
    }
    
    // Give weapon
    return WeaponsGive(clientIndex, GetNativeCell(2));
}

/**
 * Gets the client viewmodel.
 *
 * native int ZP_GetClientViewModel(clientIndex, custom);
 **/
public int API_GetClientViewModel(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return -1;
    }
    
    // Gets viewmodel
    return EntRefToEntIndex(gClientData[clientIndex][Client_ViewModels][GetNativeCell(2)]);
}

/**
 * Gets the client attachmodel.
 *
 * native int ZP_GetClientAttachModel(clientIndex, bit);
 **/
public int API_GetClientAttachModel(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return -1;
    }
    
    // Validate bit
    BitType bitType = GetNativeCell(2);
    if(bitType == BitType_Invalid)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the bit index (%d)", bitType);
        return -1;
    }
    
    // Gets attachmodel
    return EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][bitType]);
}

/**
 * Gets the custom weapon id from a given weapon.
 *
 * native int ZP_GetWeaponID(weaponIndex);
 **/
public int API_GetWeaponID(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell 
    int weaponIndex = GetNativeCell(1);

    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", weaponIndex);
        return -1;
    }
    
    // Return the value
    return WeaponsGetCustomID(weaponIndex);
}

/**
 * Gets the custom weapon id from a given name.
 *
 * native int ZP_GetWeaponNameID(name);
 **/
public int API_GetWeaponNameID(Handle hPlugin, const int iNumParams)
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
public int API_GetNumberWeapon(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return arrayWeapons.Length;
}

/**
 * Gets the name of a weapon at a given id.
 *
 * native void ZP_GetWeaponName(iD, name, maxlen);
 **/
public int API_GetWeaponName(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
 * Gets the info of a weapon at a given id.
 *
 * native void ZP_GetWeaponInfo(iD, info, maxlen);
 **/
public int API_GetWeaponInfo(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
    
    // Initialize info char
    static char sInfo[BIG_LINE_LENGTH];
    WeaponsGetInfo(iD, sInfo, sizeof(sInfo));

    // Return on success
    return SetNativeString(2, sInfo, maxLen);
}

/**
 * Gets the group of a weapon at a given id.
 *
 * native void ZP_GetWeaponGroup(iD, group, maxlen);
 **/
public int API_GetWeaponGroup(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
    
    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    WeaponsGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * Gets the entity of a weapon at a given id.
 *
 * native void ZP_GetWeaponEntity(iD, entity, maxlen);
 **/
public int API_GetWeaponEntity(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
    
    // Initialize weapon classname
    static char sEntity[SMALL_LINE_LENGTH];
    WeaponsGetEntity(iD, sEntity, sizeof(sEntity));

    // Return on success
    return SetNativeString(2, sEntity, maxLen);
}

/**
 * Gets the cost of the weapon.
 *
 * native int ZP_GetWeaponCost(iD);
 **/
public int API_GetWeaponCost(Handle hPlugin, const int iNumParams)
{    
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
public int API_GetWeaponSlot(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return view_as<int>(WeaponsGetSlot(iD));
}

/**
 * Gets the level of the weapon.
 *
 * native int ZP_GetWeaponLevel(iD);
 **/
public int API_GetWeaponLevel(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
public int API_GetWeaponOnline(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
public int API_GetWeaponDamage(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
public int API_GetWeaponKnockBack(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
public int API_GetWeaponClip(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
public int API_GetWeaponAmmo(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetAmmo(iD);
}

/**
 * Gets the ammunition cost of the weapon.
 *
 * native int ZP_GetWeaponAmmunition(iD);
 **/
public int API_GetWeaponAmmunition(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetAmmunition(iD);
}

/**
 * Gets the shoot delay of the weapon.
 *
 * native float ZP_GetWeaponSpeed(iD);
 **/
public int API_GetWeaponSpeed(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetSpeed(iD));
}

/**
 * Gets the reload duration of the weapon.
 *
 * native float ZP_GetWeaponReload(iD);
 **/
public int API_GetWeaponReload(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetReload(iD));
}

/**
 * Gets the deploy duration of the weapon.
 *
 * native float ZP_GetWeaponDeploy(iD);
 **/
public int API_GetWeaponDeploy(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetDeploy(iD));
}

/**
 * Gets the sound key of the weapon.
 *
 * native int ZP_GetWeaponSoundID(iD);
 **/
public int API_GetWeaponSoundID(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }

    // Return on success
    return WeaponsGetSoundID(iD);
}

/**
 * Gets the class of a weapon at a given id.
 *
 * native void ZP_GetWeaponClass(iD, class, maxlen);
 **/
public int API_GetWeaponClass(Handle hPlugin, const int iNumParams)
{ 
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
    
    // Initialize class char
    static char sClass[SMALL_LINE_LENGTH];
    WeaponsGetClass(iD, sClass, sizeof(sClass));

    // Return on success
    return SetNativeString(2, sClass, maxLen);
}

/**
 * Gets the viewmodel path a weapon at a given id.
 *
 * native void ZP_GetWeaponModelView(iD, model, maxlen);
 **/
public int API_GetWeaponModelView(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
    static char sModel[PLATFORM_MAX_PATH];
    WeaponsGetModelView(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the index of the weapon viewmodel.
 *
 * native int ZP_GetWeaponModelViewID(iD);
 **/
public int API_GetWeaponModelViewID(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelViewID(iD);
}

/**
 * Gets the worldmodel path a weapon at a given id.
 *
 * native void ZP_GetWeaponModelWorld(iD, model, maxlen);
 **/
public int API_GetWeaponModelWorld(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate s
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    WeaponsGetModelWorld(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the index of the weapon worldmodel.
 *
 * native int ZP_GetWeaponModelWorldID(iD);
 **/
public int API_GetWeaponModelWorldID(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelWorldID(iD);
}

/**
 * Gets the dropmodel path a weapon at a given id.
 *
 * native void ZP_GetWeaponModelDrop(iD, model, maxlen);
 **/
public int API_GetWeaponModelDrop(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate s
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    WeaponsGetModelDrop(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the index of the weapon dropmodel.
 *
 * native int ZP_GetWeaponModelDropID(iD);
 **/
public int API_GetWeaponModelDropID(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelDropID(iD);
}

/**
 * Gets the body index of the weapon model.
 *
 * native int ZP_GetWeaponModelBody(iD, model);
 **/
public int API_GetWeaponModelBody(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Validate type
    ModelType modelType = GetNativeCell(2);
    if(modelType == ModelType_Invalid)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the model index (%d)", modelType);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelBody(iD, modelType);
}

/**
 * Gets the skin index of the weapon model.
 *
 * native int ZP_GetWeaponModelSkin(iD, model);
 **/
public int API_GetWeaponModelSkin(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }

    // Validate type
    ModelType modelType = GetNativeCell(2);
    if(modelType == ModelType_Invalid)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the model index (%d)", modelType);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelSkin(iD, modelType);
}

/**
 * Gets the muzzle name of a weapon at a given id.
 *
 * native void ZP_GetWeaponModelMuzzle(iD, muzzle, maxlen);
 **/
public int API_GetWeaponModelMuzzle(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
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
    
    // Initialize muzzle char
    static char sMuzzle[SMALL_LINE_LENGTH];
    WeaponsGetModelMuzzle(iD, sMuzzle, sizeof(sMuzzle));

    // Return on success
    return SetNativeString(2, sMuzzle, maxLen);
}

/**
 * Gets the heat amount of the weapon viewmodel.
 *
 * native float ZP_GetWeaponModelHeat(iD);
 **/
public int API_GetWeaponModelHeat(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayWeapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetModelHeat(iD));
}

/*
 * Weapons data reading API.
 */

/**
 * Gets the name of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon name
    arrayWeapon.GetString(WEAPONS_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the info of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sInfo             The string to return info in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetInfo(const int iD, char[] sInfo, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon info
    arrayWeapon.GetString(WEAPONS_DATA_INFO, sInfo, iMaxLen);
}

/**
 * Gets the access group of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetGroup(const int iD, char[] sGroup, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon group
    arrayWeapon.GetString(WEAPONS_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * Gets the entity of a weapon at a given id.
 *
 * @param iD                The weapon id.
 * @param sType             The string to return entity in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetEntity(const int iD, char[] sType, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon type
    arrayWeapon.GetString(WEAPONS_DATA_ENTITY, sType, iMaxLen);
}

/**
 * Gets the cost of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The cost amount.
 **/
stock int WeaponsGetCost(const int iD)
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
stock MenuType WeaponsGetSlot(const int iD)
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
stock int WeaponsGetLevel(const int iD)
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
stock int WeaponsGetOnline(const int iD)
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
stock float WeaponsGetDamage(const int iD)
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
stock float WeaponsGetKnockBack(const int iD)
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
stock int WeaponsGetClip(const int iD)
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
stock int WeaponsGetAmmo(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon reserve ammo
    return arrayWeapon.Get(WEAPONS_DATA_AMMO);
}

/**
 * Gets the ammunition cost of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The ammunition cost.
 **/
stock int WeaponsGetAmmunition(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon ammunition cost
    return arrayWeapon.Get(WEAPONS_DATA_AMMUNITION);
}

/**
 * Gets the shoot delay of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The delay amount.
 **/
stock float WeaponsGetSpeed(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon shoot delay
    return arrayWeapon.Get(WEAPONS_DATA_SPEED);
}

/**
 * Gets the reload duration of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The duration amount.
 **/
stock float WeaponsGetReload(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon reload duration
    return arrayWeapon.Get(WEAPONS_DATA_RELOAD);
}

/**
 * Gets the deploy duration of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The duration amount.
 **/
stock float WeaponsGetDeploy(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon deploy duration
    return arrayWeapon.Get(WEAPONS_DATA_DEPLOY);
}

/**
 *  Gets the sound key of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The key index.
 **/
stock int WeaponsGetSoundID(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon sound key
    return arrayWeapon.Get(WEAPONS_DATA_SOUND);
}

/**
 * Gets the class of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sClass            The string to return class in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetClass(const int iD, char[] sClass, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon class
    arrayWeapon.GetString(WEAPONS_DATA_CLASS, sClass, iMaxLen);
}

/**
 * Gets the path of a weapon viewmodel at a given id.
 *
 * @param iD                The weapon id.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetModelView(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon viewmodel
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_VIEW, sModel, iMaxLen);
}

/**
 * Gets the index of the weapon viewmodel.
 *
 * @param iD                The weapon id.
 * @return                  The model index.
 **/
stock int WeaponsGetModelViewID(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon viewmodel index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_VIEW_);
}

/**
 * Gets the path of a weapon worldmodel at a given id.
 *
 * @param iD                The weapon id.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetModelWorld(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon worldmodel
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_WORLD, sModel, iMaxLen);
}

/**
 * Gets the index of the weapon worldmodel.
 *
 * @param iD                The weapon id.
 * @return                  The model index.
 **/
stock int WeaponsGetModelWorldID(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon worldmodel index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_WORLD_);
}

/**
 * Gets the path of a weapon dropmodel at a given id.
 *
 * @param iD                The weapon id.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetModelDrop(const int iD, char[] sModel, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon dropmodel
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_DROP, sModel, iMaxLen);
}

/**
 * Gets the index of the weapon dropmodel.
 *
 * @param iD                The weapon id.
 * @return                  The model index.
 **/
stock int WeaponsGetModelDropID(const int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon dropmodel index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_DROP_);
}

/**
 * Gets the body index of the weapon model.
 *
 * @param iD                The weapon id.
 * @param nModel            The position index.
 * @return                  The body index.
 **/
stock int WeaponsGetModelBody(const int iD, const ModelType nModel)
{
    // Create a array
    static int iBody[4];

    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);

    // Gets weapon body array
    arrayWeapon.GetArray(WEAPONS_DATA_MODEL_BODY, iBody, sizeof(iBody));

    // Gets weapon body index
    return iBody[nModel];
}

/**
 * Gets the skin index of the weapon model.
 *
 * @param iD                The weapon id.
 * @param nModel            The position index.
 * @return                  The skin index.
 **/
stock int WeaponsGetModelSkin(const int iD, const ModelType nModel)
{
    // Create a array
    static int iSkin[4];

    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);

    // Gets weapon body array
    arrayWeapon.GetArray(WEAPONS_DATA_MODEL_SKIN, iSkin, sizeof(iSkin));

    // Gets weapon body index
    return iSkin[nModel];
}

/**
 * Gets the muzzle of a weapon at a given id.
 *
 * @param iD                The weapon id.
 * @param sMuzzle           The string to return muzzle in.
 * @param iMaxLen           The max length of the string.
 **/
stock void WeaponsGetModelMuzzle(const int iD, char[] sMuzzle, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Gets weapon muzzle name
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_MUZZLE, sMuzzle, iMaxLen);
}

/**
 * Gets the heat amount of the weapon model. (For muzzleflash)
 *
 * @param iD                The weapon id.
 * @return                  The heat amount.    
 **/
stock float WeaponsGetModelHeat(const int iD)
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
stock void WeaponsSetSequenceCount(const int iD, const int nSequence)
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
stock int WeaponsGetSequenceCount(const int iD)
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
 * @param iSeq              The array to return sequences in.
 * @param iMaxLen           The max length of the array.
 **/
stock void WeaponsSetSequenceSwap(const int iD, int[] iSeq, const int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);
    
    // Sets weapon sequences swap
    arrayWeapon.SetArray(WEAPONS_DATA_SEQUENCE_SWAP, iSeq, iMaxLen);
}

/**
 * Gets the swap of the weapon sequences. (at index)
 *
 * @param iD                The weapon id.
 * @param nSequence         The position index.
 * @return                  The sequences index.
 **/
stock int WeaponsGetSequenceSwap(const int iD, const int nSequence)
{
    // Create a array
    static int iSeq[WEAPONS_SEQUENCE_MAX];

    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = arrayWeapons.Get(iD);

    // Gets weapon sequences swap at index
    arrayWeapon.GetArray(WEAPONS_DATA_SEQUENCE_SWAP, iSeq, sizeof(iSeq));

    // Gets weapon sequence
    return iSeq[nSequence];
}

/**
 * Clears the swap of the weapon sequences.
 *
 * @param iD                The weapon id.
 **/
stock void WeaponsClearSequenceSwap(const int iD)
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
 * Gets the custom weapon ID.
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  The weapon id.    
 **/
stock int WeaponsGetCustomID(const int weaponIndex)
{
    // Find the datamap
    if(!g_iOffset_WeaponID)
    {
        g_iOffset_WeaponID = FindDataMapInfo(weaponIndex, "m_iHammerID");
    }
    
    // Sets custom id for the weapon
    return GetEntData(weaponIndex, g_iOffset_WeaponID);
}

/**
 * Sets the custom weapon ID.
 *
 * @param weaponIndex       The weapon index.
 * @param iD                The weapon id.
 **/
stock void WeaponsSetCustomID(const int weaponIndex, const int iD)
{
    // Find the datamap
    if(!g_iOffset_WeaponID)
    {
        g_iOffset_WeaponID = FindDataMapInfo(weaponIndex, "m_iHammerID");
    }

    // Sets custom id for the weapon
    SetEntData(weaponIndex, g_iOffset_WeaponID, iD, _, true);
}

/**
 * Find the index at which the weapon name is at.
 * 
 * @param sName             The weapon name.
 * @param iMaxLen           (Only if 'overwritename' is true) The max length of the weapon name. 
 * @param bOverWriteName    (Optional) If true, the weapon given will be overwritten with the name from the config.
 * @return                  The array index containing the given weapon name.
 **/
stock int WeaponsNameToIndex(char[] sName, const int iMaxLen = 0, const bool bOverWriteName = false)
{
    // Initialize name char
    static char sWeaponName[SMALL_LINE_LENGTH];
    
    // i = weapon index
    int iSize = arrayWeapons.Length;
    for (int i = 0; i < iSize; i++)
    {
        // Gets weapon name 
        WeaponsGetName(i, sWeaponName, sizeof(sWeaponName));
        
        // If names match, then return index
        if(!strcmp(sName, sWeaponName, false))
        {
            // If 'overwrite' name is true, then overwrite the old string with new
            if(bOverWriteName)
            {
                // Copy config name to return string
                strcopy(sName, iMaxLen, sWeaponName);
            }
            
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return INVALID_ENT_REFERENCE;
}
 
/**
 * Drop/remove a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param bRemove           True to delete weapon or false to just drop weapon.
 **/
stock void WeaponsDrop(const int clientIndex, const int weaponIndex, const bool bRemove = false)
{
    // Validate weapon
    if(IsValidEdict(weaponIndex)) 
    {
        // Get the owner of the weapon
        int ownerIndex = GetEntDataEnt2(weaponIndex, g_iOffset_EntityOwnerEntity);

        // If owner index is different, so set it again
        if(ownerIndex != clientIndex)
        {
            SetEntDataEnt2(weaponIndex, g_iOffset_EntityOwnerEntity, clientIndex, true);
        }

        // Validate delete
        if(bRemove)
        {
            // Forces a player to remove weapon
            RemovePlayerItem(clientIndex, weaponIndex);
            AcceptEntityInput(weaponIndex, "Kill"); //! Destroy
        }
        else
        {
            // Forces a player to drop weapon
            CS_DropWeapon(clientIndex, weaponIndex, false, false);
        }
    }
}

/**
 * Pick up a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param iD                The weapon id.
 * @param CSlot             The slot index.
 **/
stock void WeaponsPickUp(const int clientIndex, const int weaponIndex, const int iD, const SlotType CSlot)
{
    // Gets weapon index
    int weaponIndex2 = GetPlayerWeaponSlot(clientIndex, view_as<int>(CSlot));
    
    // Validate weapon
    if(!IsValidEdict(weaponIndex2))
    {
        // Give the new weapon
        AcceptEntityInput(weaponIndex, "Kill"); //! Destroy
        WeaponsGive(clientIndex, iD);
    }
}

/**
 * Returns index if the player has a weapon.
 *
 * @param clientIndex       The client index.
 * @param sType             The weapon entity.
 *
 * @return                  The weapon index.
 **/
stock int WeaponsGetIndex(const int clientIndex, const char[] sType)
{
    // Initialize classname char
    static char sClassname[SMALL_LINE_LENGTH];

    // i = weapon number
    static int iSize; if(!iSize) iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_CharacterWeapons + (i * 4));

        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // Gets weapon classname
            GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));

            // If weapon find, then return
            if(!strcmp(sClassname[7], sType[7], false))
            {
                return weaponIndex;
            }
        }

        // Go to next weapon
        continue;
    }

    // Weapon doesn't exist
    return INVALID_ENT_REFERENCE;
}

/**
 * Returns true if the player has a weapon, false if not.
 *
 * @param clientIndex       The client index.
 * @param iD                The weapon id.
 *
 * @return                  True or false.
 **/
stock bool WeaponsIsExist(const int clientIndex, const int iD)
{
    // i = weapon number
    static int iSize; if(!iSize) iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_CharacterWeapons + (i * 4));
        
        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // If weapon find, then return
            if(WeaponsGetCustomID(weaponIndex) == iD)
            {
                return true;
            }
        }
        
        // Go to next weapon
        continue;
    }

    // Index doesn't exist
    return false;
}

/**
 * Remove all weapons and give default weapon.
 *
 * @param clientIndex       The client index.
 * @return                  True on success, false if client has access. 
 **/
stock bool WeaponsRemoveAll(const int clientIndex)
{
    // i = weapon number
    static int iSize; if(!iSize) iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_CharacterWeapons + (i * 4));
        
        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // Validate custom index
            int iD = WeaponsGetCustomID(weaponIndex);
            if(iD != INVALID_ENT_REFERENCE)
            {
                // Validate access
                if(WeaponsValidateClass(clientIndex, iD)) 
                {
                    // Stop here!
                    return false;
                }
            }
        }
    }
    
    // Return on success
    return SDKCall(hSDKCallRemoveAllItems, clientIndex);
}

/**
 * Give weapon from a id.
 *
 * @param clientIndex       The client index.
 * @param iD                The weapon id.
 * @return                  The weapon index.
 **/
stock int WeaponsGive(const int clientIndex, const int iD)
{
    // Initialize index
    int weaponIndex = INVALID_ENT_REFERENCE;

    // Validate weapon index
    if(iD != INVALID_ENT_REFERENCE)   
    {
        // Validate access
        if(!WeaponsValidateClass(clientIndex, iD)) 
        {
            return weaponIndex;
        }
        
        // Initialize name char
        static char sWeaponName[BIG_LINE_LENGTH];

        // Gets weapon classname
        WeaponsGetEntity(iD, sWeaponName, SMALL_LINE_LENGTH);

        // Gets weapon index
        weaponIndex = WeaponsGetIndex(clientIndex, sWeaponName);
        
        // Validate index
        if(weaponIndex != INVALID_ENT_REFERENCE) 
        {
            // Drop weapon
            WeaponsDrop(clientIndex, weaponIndex);
        }

        // Validate exceptions
        if(!strcmp(sWeaponName[7], "c4", false) || !strcmp(sWeaponName[7], "knife_t", false) || !strcmp(sWeaponName[7], "fists", false) || !strcmp(sWeaponName[7], "knife_ghost", false) || !strcmp(sWeaponName[7], "axe", false) || !strcmp(sWeaponName[7], "hammer", false) || !strcmp(sWeaponName[7], "spanner", false))
        {
            // Create a weapon entity
            weaponIndex = CreateEntityByName(sWeaponName);

            // Validate index
            if(weaponIndex != INVALID_ENT_REFERENCE) 
            {
                // Spawn the entity 
                DispatchSpawn(weaponIndex);

                // Give weapon
                EquipPlayerWeapon(clientIndex, weaponIndex);
            }
        }
        else
        {
            if(!strcmp(sWeaponName[5], "defuser", false))
            {
                // Sets item id
                WeaponsSetCustomID(clientIndex, iD);
                
                // Sets defuser
                ToolsSetClientDefuser(clientIndex, true);
            }
            else if(!strcmp(sWeaponName[5], "nvgs", false))  
            {
                // Sets nightvision
                ToolsSetClientNightVision(clientIndex, true, true);
                ToolsSetClientNightVision(clientIndex, true);
            }
            else 
            {
                // Give weapon
                weaponIndex = GivePlayerItem(clientIndex, sWeaponName);
            }
        }
        
        // Validate index
        if(weaponIndex != INVALID_ENT_REFERENCE) 
        {
            // Validate weapons
            if(!!strncmp(sWeaponName, "item_", 5, false))
            {
                // Sets weapon id
                WeaponsSetCustomID(weaponIndex, iD);
        
                // Sets max ammo only for standart weapons
                SetEntData(weaponIndex, g_iOffset_WeaponReserve2, GetEntData(weaponIndex, g_iOffset_WeaponReserve1), _, true); /// GetReserveAmmoMax not work for standart weapons

                // Switch the weapon
                FakeClientCommand(clientIndex, "use %s", sWeaponName);
                SetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon, weaponIndex, true);
                SDKCall(hSDKCallWeaponSwitch, clientIndex, weaponIndex, 0);
                
                // Call forward
                API_OnWeaponCreated(clientIndex, weaponIndex, iD);
            }
        }
    }

    // Return this index
    return weaponIndex;
}

/**
 * Returns true if the player has an access to the weapon id, false if not.
 *
 * @param clientIndex       The client index.
 * @param iD                The weapon id.
 *
 * @return                  True or false.    
 **/
stock bool WeaponsValidateClass(const int clientIndex, const int iD)
{
    // Gets weapon class
    static char sClass[SMALL_LINE_LENGTH];
    WeaponsGetClass(iD, sClass, sizeof(sClass));
    
    // Validate length
    if(hasLength(sClass))
    {
        // Gets class type 
        static char sType[SMALL_LINE_LENGTH];
        ClassGetType(gClientData[clientIndex][Client_Class], sType, sizeof(sType));
        
        // Validate equality
        if(!!strcmp(sClass, sType, false))
        {
            // Types doesn't equal
            return false;
        }
    }
    
    // Return on success
    return true;
}

/**
 * Returns true if the player has a knife, false if not.
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  True or false.    
 **/
stock bool WeaponsValidateKnife(const int weaponIndex)
{
    // Gets weapon classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));

    // Return on success
    return (!strncmp(sClassname[7], "knife", 5, false) || !strcmp(sClassname[7], "bayonet") || !strcmp(sClassname[7], "melee"));
}

/**
 * Returns true if the player has a taser, false if not.
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  True or false.    
 **/
stock bool WeaponsValidateTaser(const int weaponIndex)
{
    // Gets weapon classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));

    // Return on success
    return (!strcmp(sClassname[7], "taser", false));
}

/**
 * Returns true if the player has a c4, false if not.
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  True or false.    
 **/
stock bool WeaponsValidateBomb(const int weaponIndex)
{
    // Gets weapon classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));

    // Return on success
    return (!strcmp(sClassname[7], "c4", false));
}

/**
 * Returns true if the player has a grenade, false if not.
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  True or false.    
 **/
stock bool WeaponsValidateGrenade(const int weaponIndex)
{
    // Gets weapon classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));

    // Return on success
    return (!strcmp(sClassname[7], "hegrenade", false) || !strcmp(sClassname[7], "decoy", false) || !strcmp(sClassname[7], "flashbang", false) || !strcmp(sClassname[7], "incgrenade", false) || !strcmp(sClassname[7], "molotov", false) || !strcmp(sClassname[7], "smokegrenade", false) || !strcmp(sClassname[7], "tagrenade", false));
}