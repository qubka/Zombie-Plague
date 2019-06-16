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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * Number of max valid sequences.
 **/
#define WEAPONS_SEQUENCE_MAX 32

/**
 * @section Weapon config data indexes.
 **/
enum
{
    WEAPONS_DATA_NAME,
    WEAPONS_DATA_INFO,
    WEAPONS_DATA_DEFINDEX,
    WEAPONS_DATA_GROUP,
    WEAPONS_DATA_CLASS,
    WEAPONS_DATA_COST,
    WEAPONS_DATA_SLOT,
    WEAPONS_DATA_LEVEL,
    WEAPONS_DATA_ONLINE,
    WEAPONS_DATA_LIMIT,
    WEAPONS_DATA_DAMAGE,
    WEAPONS_DATA_KNOCKBACK,
    WEAPONS_DATA_CLIP,
    WEAPONS_DATA_AMMO,
    WEAPONS_DATA_AMMUNITION,
    WEAPONS_DATA_DROP,
    WEAPONS_DATA_SPEED,
    WEAPONS_DATA_RELOAD,
    WEAPONS_DATA_DEPLOY,
    WEAPONS_DATA_SOUND,
    WEAPONS_DATA_ICON,
    WEAPONS_DATA_MODEL_VIEW,
    WEAPONS_DATA_MODEL_VIEW_,
    WEAPONS_DATA_MODEL_WORLD,
    WEAPONS_DATA_MODEL_WORLD_,
    WEAPONS_DATA_MODEL_DROP,
    WEAPONS_DATA_MODEL_DROP_,
    WEAPONS_DATA_MODEL_BODY,
    WEAPONS_DATA_MODEL_SKIN,
    WEAPONS_DATA_MODEL_MUZZLE,
    WEAPONS_DATA_MODEL_SHELL,
    WEAPONS_DATA_MODEL_HEAT,
    WEAPONS_DATA_SEQUENCE_COUNT,
    WEAPONS_DATA_SEQUENCE_SWAP
};
/**
 * @endsection
 **/

/*
 * Load other weapons modules
 */
#include "zp/manager/weapons/weaponmod.cpp"
#include "zp/manager/weapons/weaponhdr.cpp"
#include "zp/manager/weapons/weaponattach.cpp"
#include "zp/manager/weapons/zmarket.cpp"

/**
 * @brief Weapons module init function.
 **/
void WeaponsOnInit(/*void*/)
{
    // Hook player events
    HookEvent("weapon_fire",     WeaponsOnFire,    EventHookMode_Pre);
    HookEvent("bullet_impact",   WeaponsOnBullet,  EventHookMode_Post);
    HookEvent("hostage_follows", WeaponsOnHostage, EventHookMode_Post);
    
    // Hook temp events
    AddTempEntHook("Shotgun Shot", WeaponsOnShoot);
    
    // Forward event to sub-modules
    WeaponMODOnInit();
    ZMarketOnInit();
}

/**
 * @brief Prepare all weapon data.
 **/
void WeaponsOnLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Weapons, Structure_Keyvalue, CONFIG_FILE_ALIAS_WEAPONS);

    // Gets weapons config path
    static char sPathWeapons[PLATFORM_LINE_LENGTH];
    bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_WEAPONS, sPathWeapons, sizeof(sPathWeapons));

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "Missing weapons config file: \"%s\"", sPathWeapons);
        return;
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_Weapons, sPathWeapons);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Weapons, gServerData.Weapons);
    
    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathWeapons);
        return;
    }

    // Now copy data to array structure
    WeaponsOnCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Weapons, true);
    ConfigSetConfigReloadFunc(File_Weapons, GetFunctionByName(GetMyHandle(), "WeaponsOnConfigReload"));
    ConfigSetConfigHandle(File_Weapons, gServerData.Weapons);
    
    // Forward event to sub-modules
    WeaponMODOnLoad();
}

/**
 * @brief Caches weapon data from file into arrays.
 **/
void WeaponsOnCacheData(/*void*/)
{
    // Gets config file path
    static char sPathWeapons[PLATFORM_LINE_LENGTH];
    ConfigGetConfigPath(File_Weapons, sPathWeapons, sizeof(sPathWeapons));

    // Opens config
    KeyValues kvWeapons;
    bool bSuccess = ConfigOpenConfigFile(File_Weapons, kvWeapons);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error caching data from weapons config file: \"%s\"", sPathWeapons);
        return;
    }
    
    // Validate size
    int iSize = gServerData.Weapons.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "No usable data found in weapons config file: \"%s\"", sPathWeapons);
        return;
    }

    // i = array index
    for(int i = 0; i < iSize; i++)
    {
        // General
        WeaponsGetName(i, sPathWeapons, sizeof(sPathWeapons)); // Index: 0
        kvWeapons.Rewind();
        if(!kvWeapons.JumpToKey(sPathWeapons))
        {
            // Log weapon fatal
            LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon data for: \"%s\" (check weapons config)", sPathWeapons);
            continue;
        }
        
        // Validate translation
        StringToLower(sPathWeapons);
        if(!TranslationPhraseExists(sPathWeapons))
        {
            // Log weapon error
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon name: \"%s\" (check translation file)", sPathWeapons);
            continue;
        }
        
        // Gets array size
        ArrayList arrayWeapon = gServerData.Weapons.Get(i); 
 
        // Push data into array
        kvWeapons.GetString("info", sPathWeapons, sizeof(sPathWeapons), ""); StringToLower(sPathWeapons);
        if(!TranslationPhraseExists(sPathWeapons) && hasLength(sPathWeapons))
        {
            // Log weapon error
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon info: \"%s\" (check translation file)", sPathWeapons);
        }
        arrayWeapon.PushString(sPathWeapons);                             // Index: 1
        kvWeapons.GetString("entity", sPathWeapons, sizeof(sPathWeapons), "");
        CEconItemDefinition pItemDefinition = PTaH_GetItemDefinitionByName(sPathWeapons);
        if(!pItemDefinition)
        {
            // Log weapon error
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon entity: \"%s\" (check weapons config)", sPathWeapons);
        }    
        arrayWeapon.Push(pItemDefinition.GetDefinitionIndex());           // Index: 2
        kvWeapons.GetString("group", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                             // Index: 3
        kvWeapons.GetString("class", sPathWeapons, sizeof(sPathWeapons), "human");
        arrayWeapon.PushString(sPathWeapons);                             // Index: 4
        arrayWeapon.Push(kvWeapons.GetNum("cost", 0));                    // Index: 5
        kvWeapons.GetString("slot", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.Push(ZMarketNameToIndex(sPathWeapons));               // Index: 6
        arrayWeapon.Push(kvWeapons.GetNum("level", 0));                   // Index: 7
        arrayWeapon.Push(kvWeapons.GetNum("online", 0));                  // Index: 8
        arrayWeapon.Push(kvWeapons.GetNum("limit", 0));                   // Index: 9
        arrayWeapon.Push(kvWeapons.GetFloat("damage", 1.0));              // Index: 10
        arrayWeapon.Push(kvWeapons.GetFloat("knockback", 1.0));           // Index: 11
        arrayWeapon.Push(kvWeapons.GetNum("clip", 0));                    // Index: 12
        arrayWeapon.Push(kvWeapons.GetNum("ammo", 0));                    // Index: 13
        arrayWeapon.Push(kvWeapons.GetNum("ammunition", 0));              // Index: 14
        arrayWeapon.Push(ConfigKvGetStringBool(kvWeapons, "drop", "on")); // Index: 15
        arrayWeapon.Push(kvWeapons.GetFloat("speed", 0.0));               // Index: 16
        arrayWeapon.Push(kvWeapons.GetFloat("reload", 0.0));              // Index: 17
        arrayWeapon.Push(kvWeapons.GetFloat("deploy", 0.0));              // Index: 18
        kvWeapons.GetString("sound", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.Push(SoundsKeyToIndex(sPathWeapons));                 // Index: 19
        kvWeapons.GetString("icon", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                             // Index: 20
        if(hasLength(sPathWeapons))
        {
            // Precache custom icon
            Format(sPathWeapons, sizeof(sPathWeapons), "materials/panorama/images/icons/equipment/%s.svg", sPathWeapons);
            if(FileExists(sPathWeapons)) AddFileToDownloadsTable(sPathWeapons); 
        }
        kvWeapons.GetString("view", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                             // Index: 21    
        arrayWeapon.Push(DecryptPrecacheWeapon(sPathWeapons));            // Index: 22
        kvWeapons.GetString("world", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                             // Index: 23
        arrayWeapon.Push(DecryptPrecacheModel(sPathWeapons));             // Index: 24
        kvWeapons.GetString("dropped", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                             // Index: 25
        arrayWeapon.Push(DecryptPrecacheModel(sPathWeapons));             // Index: 26
        int iBody[4]; kvWeapons.GetColor4("body", iBody);
        arrayWeapon.PushArray(iBody, sizeof(iBody));                      // Index: 27
        int iSkin[4]; kvWeapons.GetColor4("skin", iSkin);
        arrayWeapon.PushArray(iSkin, sizeof(iSkin));                      // Index: 28
        kvWeapons.GetString("muzzle", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                             // Index: 29
        kvWeapons.GetString("shell", sPathWeapons, sizeof(sPathWeapons), "");
        arrayWeapon.PushString(sPathWeapons);                             // Index: 30
        arrayWeapon.Push(kvWeapons.GetFloat("heat", 0.5));                // Index: 31
        arrayWeapon.Push(-1); int iSeq[WEAPONS_SEQUENCE_MAX];             // Index: 32
        arrayWeapon.PushArray(iSeq, sizeof(iSeq));                        // Index: 33
    }

    // We're done with this file now, so we can close it
    delete kvWeapons;
}

/**
 * @brief Purge weapon SDK data.
 **/
void WeaponsOnUnload(/*void*/)
{
    // Forward event to sub-modules
    WeaponAttachOnUnload();
    WeaponMODOnUnload();
}

/**
 * @brief Called when config is being reloaded.
 **/
public void WeaponsOnConfigReload(/*void*/)
{
    // Reloads weapons config
    WeaponsOnLoad();
}

/**
 * @brief Creates commands for weapons module.
 **/
void WeaponsOnCommandInit(/*void*/)
{
    // Forward event to sub-modules
    ZMarketOnCommandInit();
    WeaponMODOnCommandInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void WeaponsOnClientInit(int client)
{
    // Forward event to sub-modules
    WeaponMODOnClientInit(client);
}

/**
 * @brief Hook weapons cvar changes.
 **/
void WeaponsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_WEAPON_GIVE_TASER]           = FindConVar("mp_weapons_allow_zeus");
    gCvarList[CVAR_WEAPON_GIVE_BOMB]            = FindConVar("mp_give_player_c4");
    gCvarList[CVAR_WEAPON_DROP_GRENADE]         = FindConVar("mp_drop_grenade_enable");
    gCvarList[CVAR_WEAPON_DROP_KNIFE]           = FindConVar("mp_drop_knife_enable");
    gCvarList[CVAR_WEAPON_DROP_BREACH]          = FindConVar("mp_death_drop_breachcharge");
    gCvarList[CVAR_WEAPON_ALLOW_MAP]            = FindConVar("mp_weapons_allow_map_placed");
    gCvarList[CVAR_WEAPON_CT_DEFAULT_GRENADES]  = FindConVar("mp_ct_default_grenades");
    gCvarList[CVAR_WEAPON_CT_DEFAULT_MELEE]     = FindConVar("mp_ct_default_melee");
    gCvarList[CVAR_WEAPON_CT_DEFAULT_SECONDARY] = FindConVar("mp_ct_default_secondary");
    gCvarList[CVAR_WEAPON_CT_DEFAULT_PRIMARY]   = FindConVar("mp_ct_default_primary");
    gCvarList[CVAR_WEAPON_T_DEFAULT_GRENADES]   = FindConVar("mp_t_default_grenades");
    gCvarList[CVAR_WEAPON_T_DEFAULT_MELEE]      = FindConVar("mp_t_default_melee");
    gCvarList[CVAR_WEAPON_T_DEFAULT_SECONDARY]  = FindConVar("mp_t_default_secondary");
    gCvarList[CVAR_WEAPON_T_DEFAULT_PRIMARY]    = FindConVar("mp_t_default_primary");
    gCvarList[CVAR_WEAPON_PICKUP_RANGE]         = FindConVar("zp_pickup_range");
    gCvarList[CVAR_WEAPON_DEFAULT_MELEE]        = FindConVar("zp_default_melee");

    // Sets locked cvars to their locked value
    gCvarList[CVAR_WEAPON_GIVE_TASER].IntValue   = 1;
    gCvarList[CVAR_WEAPON_GIVE_BOMB].IntValue    = 0;
    gCvarList[CVAR_WEAPON_DROP_GRENADE].IntValue = 1;
    gCvarList[CVAR_WEAPON_DROP_BREACH].IntValue  = 1;
    gCvarList[CVAR_WEAPON_DROP_KNIFE].IntValue   = 0;
    gCvarList[CVAR_WEAPON_ALLOW_MAP].IntValue    = 0;
    gCvarList[CVAR_WEAPON_CT_DEFAULT_GRENADES].SetString("");
    gCvarList[CVAR_WEAPON_CT_DEFAULT_MELEE].SetString("");
    gCvarList[CVAR_WEAPON_CT_DEFAULT_SECONDARY].SetString("");
    gCvarList[CVAR_WEAPON_CT_DEFAULT_PRIMARY].SetString("");
    gCvarList[CVAR_WEAPON_T_DEFAULT_GRENADES].SetString("");
    gCvarList[CVAR_WEAPON_T_DEFAULT_MELEE].SetString("");
    gCvarList[CVAR_WEAPON_T_DEFAULT_SECONDARY].SetString("");
    gCvarList[CVAR_WEAPON_T_DEFAULT_PRIMARY].SetString("");
    
    // Hook locked cvars to prevent it from changing
    HookConVarChange(gCvarList[CVAR_WEAPON_GIVE_TASER],           CvarsUnlockOnCvarHook);
    HookConVarChange(gCvarList[CVAR_WEAPON_GIVE_BOMB],            CvarsLockOnCvarHook);
    HookConVarChange(gCvarList[CVAR_WEAPON_DROP_GRENADE],         CvarsUnlockOnCvarHook);
    HookConVarChange(gCvarList[CVAR_WEAPON_DROP_BREACH],          CvarsUnlockOnCvarHook);
    HookConVarChange(gCvarList[CVAR_WEAPON_DROP_KNIFE],           CvarsLockOnCvarHook); 
    HookConVarChange(gCvarList[CVAR_WEAPON_ALLOW_MAP],            CvarsLockOnCvarHook);   
    HookConVarChange(gCvarList[CVAR_WEAPON_CT_DEFAULT_GRENADES],  CvarsLockOnCvarHook3);
    HookConVarChange(gCvarList[CVAR_WEAPON_CT_DEFAULT_MELEE],     CvarsLockOnCvarHook3);
    HookConVarChange(gCvarList[CVAR_WEAPON_CT_DEFAULT_SECONDARY], CvarsLockOnCvarHook3);
    HookConVarChange(gCvarList[CVAR_WEAPON_CT_DEFAULT_PRIMARY],   CvarsLockOnCvarHook3);
    HookConVarChange(gCvarList[CVAR_WEAPON_T_DEFAULT_GRENADES],   CvarsLockOnCvarHook3);
    HookConVarChange(gCvarList[CVAR_WEAPON_T_DEFAULT_MELEE],      CvarsLockOnCvarHook3);
    HookConVarChange(gCvarList[CVAR_WEAPON_T_DEFAULT_SECONDARY],  CvarsLockOnCvarHook3);
    HookConVarChange(gCvarList[CVAR_WEAPON_T_DEFAULT_PRIMARY],    CvarsLockOnCvarHook3);
    
    // Forward event to sub-modules
    ZMarketOnCvarInit();
}

/*
 * Weapons main functions.
 */

/**
 * Event callback (weapon_fire)
 * @brief Client has been shooted.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponsOnFire(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(client))
    {
        return;
    }

    // Gets active weapon index from the client
    int weapon = ToolsGetActiveWeapon(client);
    
    // Validate weapon
    if(weapon == -1)
    {
        return;
    }
    
    // Forward event to sub-modules
    WeaponMODOnFire(client, weapon);
}

/**
 * Event callback (bullet_impact)
 * @brief The bullet hits something.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponsOnBullet(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(client))
    {
        return;
    }

    // Gets active weapon index from the client
    int weapon = ToolsGetActiveWeapon(client);
    
    // Validate weapon
    if(weapon == -1)
    {
        return;
    }
    
    // Initialize vector
    static float vBullet[3];

    // Gets bullet position
    vBullet[0] = hEvent.GetFloat("x");
    vBullet[1] = hEvent.GetFloat("y");
    vBullet[2] = hEvent.GetFloat("z");
    
    // Forward event to sub-modules
    WeaponMODOnBullet(client, vBullet, weapon);
}

/**
 * Event callback (hostage_follows)
 * @brief Client has been carried hostage.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponsOnHostage(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(client))
    {
        return;
    }
    
    // Forward event to sub-modules
    WeaponMODOnHostage(client);
}

/**
 * Event callback (Shotgun Shot)
 * @brief The bullet was been created.
 * 
 * @param sTEName           The temp name.
 * @param iPlayers          Array containing target player indexes.
 * @param numClients        Number of players in the array.
 * @param flDelay           Delay in seconds to send the TE.
 **/ 
public Action WeaponsOnShoot(char[] sTEName, int[] iPlayers, int numClients, float flDelay) 
{ 
    // Gets all required event info
    int client = TE_ReadNum("m_iPlayer") + 1;

    // Validate client
    if(!IsPlayerExist(client))
    {
        return Plugin_Continue;
    }
    
    // Gets active weapon index from the client
    int weapon = ToolsGetActiveWeapon(client);
    
    // Validate weapon
    if(weapon == -1)
    {
        return Plugin_Continue;
    }
    
    // Forward event to sub-modules
    return WeaponMODOnShoot(client, weapon);
}

/**
 * @brief Called on each frame of a weapon holding.
 * 
 * @param client            The client index.
 * @param iButtons          The button buffer.
 * @param iLastButtons      The last button buffer.
 **/
Action WeaponsOnRunCmd(int client, int &iButtons, int iLastButtons)
{
    // Validate use hook
    if(iButtons & IN_USE)
    {
        // Validate overtransmitting
        if(!(iLastButtons & IN_USE))
        {
            // Forward event to sub-modules
            WeaponMODOnUse(client);
        }
    }
    
    // Gets active weapon index from the client
    static int weapon; weapon = ToolsGetActiveWeapon(client);

    // Validate weapon and access to hook
    if(weapon == -1 || !gClientData[client].RunCmd)
    {
        return Plugin_Continue;
    }

    // Forward event to sub-modules
    return WeaponMODOnRunCmd(client, iButtons, iLastButtons, weapon);
}

/**
 * @brief Client has been changed class state. *(Post)
 *
 * @param userID            The user id.
 **/
public void WeaponsOnClientUpdate(int userID)
{
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID);
    
    // Validate client
    if(client)
    {
        // Forward event to sub-modules
        WeaponAttachOnClientUpdate(client);
        WeaponMODOnClientUpdate(client);
        ZMarketOnClientUpdate(client);
    }
}

/**
 * @brief Client has been spawned.
 *
 * @param client            The client index.
 **/
void WeaponsOnClientSpawn(int client)
{
    // Forward event to sub-modules
    WeaponAttachOnClientSpawn(client);
}

/**
 * @brief Client has been killed.
 *
 * @param client            The client index.
 **/
void WeaponsOnClientDeath(int client)
{
    // Forward event to sub-modules
    WeaponAttachOnClientDeath(client);
    WeaponMODOnClientDeath(client);
}

/**
 * @brief Called when a weapon is created.
 *
 * @param weapon            The weapon index.
 * @param sClassname        The string with returned name.
 **/
void WeaponOnEntityCreated(int weapon, const char[] sClassname)
{
    // Validate entity
    if(weapon > -1)
    {
        // Forward event to sub-modules
        WeaponMODOnEntityCreated(weapon, sClassname);
    }
}

/*
 * Weapons natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void WeaponsOnNativeInit(/*void*/) 
{
    CreateNative("ZP_CreateWeapon",          API_CreateWeapon);
    CreateNative("ZP_GiveClientWeapon",      API_GiveClientWeapon);
    CreateNative("ZP_SwitchClientWeapon",    API_SwitchClientWeapon);
    CreateNative("ZP_GetClientViewModel",    API_GetClientViewModel);
    CreateNative("ZP_GetClientAttachModel",  API_GetClientAttachModel);
    CreateNative("ZP_GetWeaponNameID",       API_GetWeaponNameID);
    CreateNative("ZP_GetNumberWeapon",       API_GetNumberWeapon);
    CreateNative("ZP_GetWeaponName",         API_GetWeaponName);
    CreateNative("ZP_GetWeaponInfo",         API_GetWeaponInfo);
    CreateNative("ZP_GetWeaponDefIndex",     API_GetWeaponDefIndex);
    CreateNative("ZP_GetWeaponGroup",        API_GetWeaponGroup);
    CreateNative("ZP_GetWeaponClass",        API_GetWeaponClass);
    CreateNative("ZP_GetWeaponCost",         API_GetWeaponCost);
    CreateNative("ZP_GetWeaponSlot",         API_GetWeaponSlot);
    CreateNative("ZP_GetWeaponLevel",        API_GetWeaponLevel);
    CreateNative("ZP_GetWeaponOnline",       API_GetWeaponOnline);
    CreateNative("ZP_GetWeaponLimit",        API_GetWeaponLimit);
    CreateNative("ZP_GetWeaponDamage",       API_GetWeaponDamage);
    CreateNative("ZP_GetWeaponKnockBack",    API_GetWeaponKnockBack);
    CreateNative("ZP_GetWeaponClip",         API_GetWeaponClip);
    CreateNative("ZP_GetWeaponAmmo",         API_GetWeaponAmmo);
    CreateNative("ZP_GetWeaponAmmunition",   API_GetWeaponAmmunition);
    CreateNative("ZP_IsWeaponDrop",          API_IsWeaponDrop);
    CreateNative("ZP_GetWeaponSpeed",        API_GetWeaponSpeed);
    CreateNative("ZP_GetWeaponReload",       API_GetWeaponReload);
    CreateNative("ZP_GetWeaponDeploy",       API_GetWeaponDeploy);
    CreateNative("ZP_GetWeaponSoundID",      API_GetWeaponSoundID);
    CreateNative("ZP_GetWeaponIcon",         API_GetWeaponIcon);
    CreateNative("ZP_GetWeaponModelView",    API_GetWeaponModelView);
    CreateNative("ZP_GetWeaponModelViewID",  API_GetWeaponModelViewID);
    CreateNative("ZP_GetWeaponModelWorld",   API_GetWeaponModelWorld);    
    CreateNative("ZP_GetWeaponModelWorldID", API_GetWeaponModelWorldID); 
    CreateNative("ZP_GetWeaponModelDrop",    API_GetWeaponModelDrop);    
    CreateNative("ZP_GetWeaponModelDropID",  API_GetWeaponModelDropID); 
    CreateNative("ZP_GetWeaponModelBody",    API_GetWeaponModelBody); 
    CreateNative("ZP_GetWeaponModelSkin",    API_GetWeaponModelSkin); 
    CreateNative("ZP_GetWeaponModelMuzzle",  API_GetWeaponModelMuzzle);
    CreateNative("ZP_GetWeaponModelShell",   API_GetWeaponModelShell);
    CreateNative("ZP_GetWeaponModelHeat",    API_GetWeaponModelHeat); 
}

/**
 * @brief Creates the weapon by a given id.
 *
 * @note native int ZP_CreateWeapon(id, origin, angle);
 **/
public int API_CreateWeapon(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Initialize variables
    static float vPosition[3]; static float vAngle[3];

    // General
    GetNativeArray(2, vPosition, sizeof(vPosition));
    GetNativeArray(3, vAngle, sizeof(vAngle));
    
    // Spawn weapon
    return WeaponsCreate(iD, vPosition, vAngle);
}

/**
 * @brief Gives the weapon by a given id.
 *
 * @note native int ZP_GiveClientWeapon(client, id, slot);
 **/
public int API_GiveClientWeapon(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(client))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", client);
        return -1;
    }
    
    // Gets weapon index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }

    // Validate slot
    int mSlot = GetNativeCell(3);
    if(mSlot != SlotType_Invalid)
    {
        // Drop weapon
        WeaponsDrop(client, GetPlayerWeaponSlot(client, mSlot));
    }
    
    // Call forward
    Action hResult;
    gForwardData._OnClientValidateWeapon(client, iD, hResult);

    // Validate handle
    if(hResult == Plugin_Continue || hResult == Plugin_Changed)
    {
        // Give weapon
        return WeaponsGive(client, iD);
    }
    
    // Return on unsuccess
    return -1;
}

/**
 * @brief Switches to the weapon by an index.
 *
 * @note native void ZP_SwitchClientWeapon(client, weapon);
 **/
public int API_SwitchClientWeapon(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(client))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", client);
        return;
    }
    
    // Gets weapon index from native cell 
    int weapon = GetNativeCell(2);
    
    // Validate weapon
    if(!IsValidEdict(weapon))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", weapon);
        return;
    }
    
    // Switch weapon
    WeaponsSwitch(client, weapon);
}

/**
 * @brief Gets the client viewmodel.
 *
 * @note native int ZP_GetClientViewModel(client, custom);
 **/
public int API_GetClientViewModel(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(client))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", client);
        return -1;
    }
    
    // Gets viewmodel
    return EntRefToEntIndex(gClientData[client].ViewModels[GetNativeCell(2)]);
}

/**
 * @brief Gets the client attachmodel.
 *
 * @note native int ZP_GetClientAttachModel(client, bit);
 **/
public int API_GetClientAttachModel(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(client))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", client);
        return -1;
    }
    
    // Validate bit
    BitType mBits = GetNativeCell(2);
    if(mBits == BitType_Invalid)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the bit index (%d)", mBits);
        return -1;
    }
    
    // Gets attachmodel
    return EntRefToEntIndex(gClientData[client].AttachmentAddons[mBits]);
}

/**
 * @brief Gets the custom weapon id from a given name.
 *
 * @note native int ZP_GetWeaponNameID(name);
 **/
public int API_GetWeaponNameID(Handle hPlugin, int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Can't find weapon with an empty name");
        return -1;
    }

    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];                                         
    GetNativeString(1, sName, sizeof(sName));
    
    // Return the value
    return WeaponsNameToIndex(sName);
}

/**
 * @brief Gets the amount of all weapons.
 *
 * @note native int ZP_GetNumberWeapon();
 **/
public int API_GetNumberWeapon(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return gServerData.Weapons.Length;
}

/**
 * @brief Gets the name of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponName(iD, name, maxlen);
 **/
public int API_GetWeaponName(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    WeaponsGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the info of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponInfo(iD, info, maxlen);
 **/
public int API_GetWeaponInfo(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize info char
    static char sInfo[BIG_LINE_LENGTH];
    WeaponsGetInfo(iD, sInfo, sizeof(sInfo));

    // Return on success
    return SetNativeString(2, sInfo, maxLen);
}

/**
 * @brief Gets the group of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponGroup(iD, group, maxlen);
 **/
public int API_GetWeaponGroup(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    WeaponsGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the class of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponClass(iD, class, maxlen);
 **/
public int API_GetWeaponClass(Handle hPlugin, int iNumParams)
{ 
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize class char
    static char sClass[BIG_LINE_LENGTH];
    WeaponsGetClass(iD, sClass, sizeof(sClass));

    // Return on success
    return SetNativeString(2, sClass, maxLen);
}

/**
 * @brief Gets the defenition index of the weapon.
 *
 * @note native ItemDef ZP_GetWeaponDefIndex(iD);
 **/
public int API_GetWeaponDefIndex(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return view_as<int>(WeaponsGetDefIndex(iD));
}

/**
 * @brief Gets the cost of the weapon.
 *
 * @note native int ZP_GetWeaponCost(iD);
 **/
public int API_GetWeaponCost(Handle hPlugin, int iNumParams)
{    
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetCost(iD);
}

/**
 * @brief Gets the slot of the weapon.
 *
 * @note native int ZP_GetWeaponSlot(iD);
 **/
public int API_GetWeaponSlot(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return view_as<int>(WeaponsGetSlot(iD));
}

/**
 * @brief Gets the level of the weapon.
 *
 * @note native int ZP_GetWeaponLevel(iD);
 **/
public int API_GetWeaponLevel(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetLevel(iD);
}

/**
 * @brief Gets the online of the weapon.
 *
 * @note native int ZP_GetWeaponOnline(iD);
 **/
public int API_GetWeaponOnline(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetOnline(iD);
}

/**
 * @brief Gets the limit of the weapon.
 *
 * @note native int ZP_GetWeaponLimit(iD);
 **/
public int API_GetWeaponLimit(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetLimit(iD);
}

/**
 * @brief Gets the damage of the weapon.
 *
 * @note native float ZP_GetWeaponDamage(iD);
 **/
public int API_GetWeaponDamage(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetDamage(iD));
}

/**
 * @brief Gets the knockback of the weapon.
 *
 * @note native float ZP_GetWeaponKnockBack(iD);
 **/
public int API_GetWeaponKnockBack(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetKnockBack(iD));
}

/**
 * @brief Gets the clip ammo of the weapon.
 *
 * @note native int ZP_GetWeaponClip(iD);
 **/
public int API_GetWeaponClip(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetClip(iD);
}

/**
 * @brief Gets the reserve ammo of the weapon.
 *
 * @note native int ZP_GetWeaponAmmo(iD);
 **/
public int API_GetWeaponAmmo(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetAmmo(iD);
}

/**
 * @brief Gets the ammunition cost of the weapon.
 *
 * @note native int ZP_GetWeaponAmmunition(iD);
 **/
public int API_GetWeaponAmmunition(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsGetAmmunition(iD);
}

/**
 * @brief Checks the drop value of the weapon.
 *
 * @note native bool ZP_IsWeaponDrop(iD);
 **/
public int API_IsWeaponDrop(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return WeaponsIsDrop(iD);
}

/**
 * @brief Gets the shoot delay of the weapon.
 *
 * @note native float ZP_GetWeaponSpeed(iD);
 **/
public int API_GetWeaponSpeed(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetSpeed(iD));
}

/**
 * @brief Gets the reload duration of the weapon.
 *
 * @note native float ZP_GetWeaponReload(iD);
 **/
public int API_GetWeaponReload(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetReload(iD));
}

/**
 * @brief Gets the deploy duration of the weapon.
 *
 * @note native float ZP_GetWeaponDeploy(iD);
 **/
public int API_GetWeaponDeploy(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetDeploy(iD));
}

/**
 * @brief Gets the sound key of the weapon.
 *
 * @note native int ZP_GetWeaponSoundID(iD);
 **/
public int API_GetWeaponSoundID(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }

    // Return on success
    return WeaponsGetSoundID(iD);
}

/**
 * @brief Gets the icon of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponIcon(iD, info, maxlen);
 **/
public int API_GetWeaponIcon(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize icon char
    static char sIcon[SMALL_LINE_LENGTH];
    WeaponsGetIcon(iD, sIcon, sizeof(sIcon));

    // Return on success
    return SetNativeString(2, sIcon, maxLen);
}

/**
 * @brief Gets the viewmodel path of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelView(iD, model, maxlen);
 **/
public int API_GetWeaponModelView(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    WeaponsGetModelView(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the index of the weapon viewmodel.
 *
 * @note native int ZP_GetWeaponModelViewID(iD);
 **/
public int API_GetWeaponModelViewID(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelViewID(iD);
}

/**
 * @brief Gets the worldmodel path of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelWorld(iD, model, maxlen);
 **/
public int API_GetWeaponModelWorld(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    WeaponsGetModelWorld(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the index of the weapon worldmodel.
 *
 * @note native int ZP_GetWeaponModelWorldID(iD);
 **/
public int API_GetWeaponModelWorldID(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelWorldID(iD);
}

/**
 * @brief Gets the dropmodel path of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelDrop(iD, model, maxlen);
 **/
public int API_GetWeaponModelDrop(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    WeaponsGetModelDrop(iD, sModel, sizeof(sModel));

    // Return on success
    return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the index of the weapon dropmodel.
 *
 * @note native int ZP_GetWeaponModelDropID(iD);
 **/
public int API_GetWeaponModelDropID(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelDropID(iD);
}

/**
 * @brief Gets the body index of the weapon model.
 *
 * @note native int ZP_GetWeaponModelBody(iD, model);
 **/
public int API_GetWeaponModelBody(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Validate type
    ModelType nModel = GetNativeCell(2);
    if(nModel == ModelType_Invalid)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the model index (%d)", nModel);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelBody(iD, nModel);
}

/**
 * @brief Gets the skin index of the weapon model.
 *
 * @note native int ZP_GetWeaponModelSkin(iD, model);
 **/
public int API_GetWeaponModelSkin(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }

    // Validate type
    ModelType nModel = GetNativeCell(2);
    if(nModel == ModelType_Invalid)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the model index (%d)", nModel);
        return -1;
    }
    
    // Return the value
    return WeaponsGetModelSkin(iD, nModel);
}

/**
 * @brief Gets the muzzle name of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelMuzzle(iD, muzzle, maxlen);
 **/
public int API_GetWeaponModelMuzzle(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize muzzle char
    static char sMuzzle[NORMAL_LINE_LENGTH];
    WeaponsGetModelMuzzle(iD, sMuzzle, sizeof(sMuzzle));

    // Return on success
    return SetNativeString(2, sMuzzle, maxLen);
}

/**
 * @brief Gets the shell name of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelShell(iD, shell, maxlen);
 **/
public int API_GetWeaponModelShell(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize shell char
    static char sShell[NORMAL_LINE_LENGTH];
    WeaponsGetModelShell(iD, sShell, sizeof(sShell));

    // Return on success
    return SetNativeString(2, sShell, maxLen);
}

/**
 * @brief Gets the heat amount of the weapon viewmodel.
 *
 * @note native float ZP_GetWeaponModelHeat(iD);
 **/
public int API_GetWeaponModelHeat(Handle hPlugin, int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= gServerData.Weapons.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
        return -1;
    }
    
    // Return the value (Float fix)
    return view_as<int>(WeaponsGetModelHeat(iD));
}

/*
 * Weapons data reading API.
 */

/**
 * @brief Gets the name of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetName(int iD, char[] sName, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon name
    arrayWeapon.GetString(WEAPONS_DATA_NAME, sName, iMaxLen);
}

/**
 * @brief Gets the info of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sInfo             The string to return info in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetInfo(int iD, char[] sInfo, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon info
    arrayWeapon.GetString(WEAPONS_DATA_INFO, sInfo, iMaxLen);
}

/**
 * @brief Gets the access group of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetGroup(int iD, char[] sGroup, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon group
    arrayWeapon.GetString(WEAPONS_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * @brief Gets the access class of a weapon at a given id.
 *
 * @param iD                The weapon index.
 * @param sClass            The string to return class in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetClass(int iD, char[] sClass, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon class
    arrayWeapon.GetString(WEAPONS_DATA_CLASS, sClass, iMaxLen);
}

/**
 * @brief Gets the defenition index of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The def index.
 **/
ItemDef WeaponsGetDefIndex(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets defenition index
    return arrayWeapon.Get(WEAPONS_DATA_DEFINDEX);
}

/**
 * @brief Gets the cost of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The cost amount.
 **/
int WeaponsGetCost(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon cost
    return arrayWeapon.Get(WEAPONS_DATA_COST);
}

/**
 * @brief Gets the slot of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The weapon slot.    
 **/
MenuType WeaponsGetSlot(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon slot
    return arrayWeapon.Get(WEAPONS_DATA_SLOT);
}

/**
 * @brief Gets the level of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The level amount.    
 **/
int WeaponsGetLevel(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon level
    return arrayWeapon.Get(WEAPONS_DATA_LEVEL);
}

/**
 * @brief Gets the online of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The online amount.
 **/
int WeaponsGetOnline(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon online
    return arrayWeapon.Get(WEAPONS_DATA_ONLINE);
}

/**
 * @brief Gets the limit of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The limit amount.
 **/
int WeaponsGetLimit(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon limit
    return arrayWeapon.Get(WEAPONS_DATA_LIMIT);
}

/**
 * @brief Remove the buy limit of the all client weapons.
 *
 * @param client            The client index.
 **/
void WeaponsRemoveLimits(int client)
{
    // If array hasn't been created, then create
    if(gClientData[client].WeaponLimit == null)
    {
        // Initialize a buy limit array
        gClientData[client].WeaponLimit = new StringMap();
    }

    // Clear out the array of all data
    gClientData[client].WeaponLimit.Clear();
}

/**
 * @brief Sets the buy limit of the current client weapon.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 * @param iLimit            The limit value.    
 **/
void WeaponsSetLimits(int client, int iD, int iLimit)
{
    // If array hasn't been created, then create
    if(gClientData[client].WeaponLimit == null)
    {
        // Initialize a buy limit array
        gClientData[client].WeaponLimit = new StringMap();
    }

    // Initialize key char
    static char sKey[SMALL_LINE_LENGTH];
    IntToString(iD, sKey, sizeof(sKey));
    
    // Sets buy limit for the client
    gClientData[client].WeaponLimit.SetValue(sKey, iLimit);
}

/**
 * @brief Gets the buy limit of the current client weapon.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 **/
int WeaponsGetLimits(int client, int iD)
{
    // If array hasn't been created, then create
    if(gClientData[client].WeaponLimit == null)
    {
        // Initialize a buy limit array
        gClientData[client].WeaponLimit = new StringMap();
    }
    
    // Initialize key char
    static char sKey[SMALL_LINE_LENGTH];
    IntToString(iD, sKey, sizeof(sKey));
    
    // Gets buy limit for the client
    int iLimit; gClientData[client].WeaponLimit.GetValue(sKey, iLimit);
    return iLimit;
}

/**
 * @brief Gets the damage of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The damage amount.    
 **/
float WeaponsGetDamage(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon damage
    return arrayWeapon.Get(WEAPONS_DATA_DAMAGE);
}

/**
 * @brief Gets the knockback of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The knockback amount.    
 **/
float WeaponsGetKnockBack(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon knockback
    return arrayWeapon.Get(WEAPONS_DATA_KNOCKBACK);
}

/**
 * @brief Gets the clip ammo of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The clip ammo amount.
 **/
int WeaponsGetClip(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon clip ammo
    return arrayWeapon.Get(WEAPONS_DATA_CLIP);
}

/**
 * @brief Gets the reserve ammo of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The reserve ammo amount.
 **/
int WeaponsGetAmmo(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon reserve ammo
    return arrayWeapon.Get(WEAPONS_DATA_AMMO);
}

/**
 * @brief Gets the ammunition cost of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The ammunition cost.
 **/
int WeaponsGetAmmunition(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon ammunition cost
    return arrayWeapon.Get(WEAPONS_DATA_AMMUNITION);
}

/**
 * @brief Checks weapon drop value.
 *
 * @param iD                The weapon id.
 * @return                  True or false.
 **/
int WeaponsIsDrop(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon drop state
    return arrayWeapon.Get(WEAPONS_DATA_DROP);
}

/**
 * @brief Gets the shoot delay of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The delay amount.
 **/
float WeaponsGetSpeed(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon shoot delay
    return arrayWeapon.Get(WEAPONS_DATA_SPEED);
}

/**
 * @brief Gets the reload duration of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The duration amount.
 **/
float WeaponsGetReload(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon reload duration
    return arrayWeapon.Get(WEAPONS_DATA_RELOAD);
}

/**
 * @brief Gets the deploy duration of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The duration amount.
 **/
float WeaponsGetDeploy(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon deploy duration
    return arrayWeapon.Get(WEAPONS_DATA_DEPLOY);
}

/**
 * @brief Gets the sound key of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The key index.
 **/
int WeaponsGetSoundID(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon sound key
    return arrayWeapon.Get(WEAPONS_DATA_SOUND);
}

/**
 * @brief Gets the icon of a weapon at a given id.
 *
 * @param iD                The weapon id.
 * @param sIcon             The string to return icon in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetIcon(int iD, char[] sIcon, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon icon
    arrayWeapon.GetString(WEAPONS_DATA_ICON, sIcon, iMaxLen);
}

/**
 * @brief Gets the path of a weapon viewmodel at a given id.
 *
 * @param iD                The weapon id.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetModelView(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon viewmodel
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_VIEW, sModel, iMaxLen);
}

/**
 * @brief Gets the index of the weapon viewmodel.
 *
 * @param iD                The weapon id.
 * @return                  The model index.
 **/
int WeaponsGetModelViewID(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon viewmodel index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_VIEW_);
}

/**
 * @brief Gets the path of a weapon worldmodel at a given id.
 *
 * @param iD                The weapon id.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetModelWorld(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon worldmodel
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_WORLD, sModel, iMaxLen);
}

/**
 * @brief Gets the index of the weapon worldmodel.
 *
 * @param iD                The weapon id.
 * @return                  The model index.
 **/
int WeaponsGetModelWorldID(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon worldmodel index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_WORLD_);
}

/**
 * @brief Gets the path of a weapon dropmodel at a given id.
 *
 * @param iD                The weapon id.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetModelDrop(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon dropmodel
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_DROP, sModel, iMaxLen);
}

/**
 * @brief Gets the index of the weapon dropmodel.
 *
 * @param iD                The weapon id.
 * @return                  The model index.
 **/
int WeaponsGetModelDropID(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon dropmodel index
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_DROP_);
}

/**
 * @brief Gets the body index of the weapon model.
 *
 * @param iD                The weapon id.
 * @param nModel            The position index.
 * @return                  The body index.
 **/
int WeaponsGetModelBody(int iD, ModelType nModel)
{
    // Create a array
    static int iBody[4];

    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);

    // Gets weapon body array
    arrayWeapon.GetArray(WEAPONS_DATA_MODEL_BODY, iBody, sizeof(iBody));

    // Gets weapon body index
    return iBody[nModel];
}

/**
 * @brief Gets the skin index of the weapon model.
 *
 * @param iD                The weapon id.
 * @param nModel            The position index.
 * @return                  The skin index.
 **/
int WeaponsGetModelSkin(int iD, ModelType nModel)
{
    // Create a array
    static int iSkin[4];

    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);

    // Gets weapon body array
    arrayWeapon.GetArray(WEAPONS_DATA_MODEL_SKIN, iSkin, sizeof(iSkin));

    // Gets weapon body index
    return iSkin[nModel];
}

/**
 * @brief Gets the muzzle of a weapon at a given id.
 *
 * @param iD                The weapon id.
 * @param sMuzzle           The string to return muzzle in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetModelMuzzle(int iD, char[] sMuzzle, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon muzzle name
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_MUZZLE, sMuzzle, iMaxLen);
}

/**
 * @brief Gets the shell of a weapon at a given id.
 *
 * @param iD                The weapon id.
 * @param sShell            The string to return shell in.
 * @param iMaxLen           The lenght of string.
 **/
void WeaponsGetModelShell(int iD, char[] sShell, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon shell name
    arrayWeapon.GetString(WEAPONS_DATA_MODEL_SHELL, sShell, iMaxLen);
}

/**
 * @brief Gets the heat amount of the weapon model. (For muzzleflash)
 *
 * @param iD                The weapon id.
 * @return                  The heat amount.    
 **/
float WeaponsGetModelHeat(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets heat amount
    return arrayWeapon.Get(WEAPONS_DATA_MODEL_HEAT);
}

/**
 * @brief Sets the amount of the weapon sequences.
 *
 * @param iD                The weapon id.
 * @param iSequence         The sequences amount.
 **/
void WeaponsSetSequenceCount(int iD, int iSequence)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Sets weapon sequences amount
    arrayWeapon.Set(WEAPONS_DATA_SEQUENCE_COUNT, iSequence);
}

/**
 * @brief Gets the amount of the weapon sequences.
 *
 * @param iD                The weapon id.
 * @return                  The sequences amount.
 **/
int WeaponsGetSequenceCount(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Gets weapon sequences amount
    return arrayWeapon.Get(WEAPONS_DATA_SEQUENCE_COUNT);
}

/**
 * @brief Sets the swap of the weapon sequences.
 *
 * @param iD                The weapon id.
 * @param iSeq              The array to return sequences in.
 * @param iMaxLen           The max length of the array.
 **/
void WeaponsSetSequenceSwap(int iD, int[] iSeq, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Sets weapon sequences swap
    arrayWeapon.SetArray(WEAPONS_DATA_SEQUENCE_SWAP, iSeq, iMaxLen);
}

/**
 * @brief Gets the swap of the weapon sequences. (at index)
 *
 * @param iD                The weapon id.
 * @param iSequence         The position index.
 * @return                  The sequences index.
 **/
int WeaponsGetSequenceSwap(int iD, int iSequence)
{
    // Create a array
    static int iSeq[WEAPONS_SEQUENCE_MAX];

    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);

    // Gets weapon sequences swap at index
    arrayWeapon.GetArray(WEAPONS_DATA_SEQUENCE_SWAP, iSeq, sizeof(iSeq));

    // Gets weapon sequence
    return iSeq[iSequence];
}

/**
 * @brief Clears the swap of the weapon sequences.
 *
 * @param iD                The weapon id.
 **/
void WeaponsClearSequenceSwap(int iD)
{
    // Gets array handle of weapon at given index
    ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
    
    // Clear weapon sequences swap
    arrayWeapon.Erase(WEAPONS_DATA_SEQUENCE_SWAP);
}

/*
 * Generic weapons API.
 */
 
/**
 * @brief Gets the custom weapon ID.
 *
 * @param weapon            The weapon index.
 * @return                  The weapon id.    
 **/
int WeaponsGetCustomID(int weapon)
{
    // Gets value on the weapon
    return GetEntProp(weapon, Prop_Data, "m_iHammerID");
}

/**
 * @brief Sets the custom weapon ID.
 *
 * @param weapon            The weapon index.
 * @param iD                The weapon id.
 **/
void WeaponsSetCustomID(int weapon, int iD)
{
    // Sets value on the weapon
    SetEntProp(weapon, Prop_Data, "m_iHammerID", iD);
}

/**
 * @brief Gets the weapon owner.
 *
 * @param weapon            The weapon index.
 * @return                  The owner index.    
 **/
int WeaponsGetOwner(int weapon)
{
    // Gets value on the weapon
    return GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
}

/**
 * @brief Sets the custom weapon ID.
 *
 * @param weapon            The weapon index.
 * @param owner             The owner index.  
 **/
void WeaponsSetOwner(int weapon, int owner)
{
    // Sets value on the weapon
    SetEntPropEnt(weapon, Prop_Send, "m_hOwner", owner);
}

/**
 * @brief Sets the animation delay.
 *
 * @param weapon            The weapon index.
 * @param flDelay           The delay duration.  
 **/
void WeaponsSetAnimating(int weapon, float flDelay)
{
    // Sets value on the weapon
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flDelay);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flDelay);
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flDelay);
}

/**
 * @brief Find the index at which the weapon name is at.
 * 
 * @param sName             The weapon name.
 * @return                  The array index containing the given weapon name.
 **/
int WeaponsNameToIndex(char[] sName)
{
    // Initialize name char
    static char sWeaponName[SMALL_LINE_LENGTH];
    
    // i = weapon index
    int iSize = gServerData.Weapons.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon name 
        WeaponsGetName(i, sWeaponName, sizeof(sWeaponName));

        // If names match, then return index
        if(!strcmp(sName, sWeaponName, false))
        {
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return -1;
}

/**
 * @brief Drop/remove a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
void WeaponsDrop(int client, int weapon)
{
    // Validate weapon
    if(IsValidEdict(weapon)) 
    {
        // Gets owner of the weapon
        int owner = ToolsGetOwner(weapon);

        // If owner index is different, so set it again
        if(owner != client)
        {
            ToolsSetOwner(weapon, client);
        }

        // Forces a player to drop weapon
        CS_DropWeapon(client, weapon, false, false);
    }
}

/**
 * @brief Equip a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param bReplace          (Optional) True to replace a slot or false to skip.
 **/
void WeaponsEquip(int client, int weapon, bool bReplace = false)
{
    // Initialize weapon index
    int weapon2 = -1;
    
    // Validate replace mode
    if(bReplace)
    {
        // Gets weapon index
        weapon2 = GetPlayerWeaponSlot(client, SlotType_Melee);
    }
    else
    {
        // Gets weapon classname
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(weapon, sClassname, sizeof(sClassname));
        
        // Gets weapon index
        weapon2 = WeaponsFindByName(client, sClassname);
    }
    
    // Validate weapon
    if(weapon2 != -1)
    {
        // Drop weapon
        WeaponsDrop(client, weapon2);
    }
    
    // Give weapon
    EquipPlayerWeapon(client, weapon); 
    
    // Switch weapon
    WeaponsSwitch(client, weapon);
}

/**
 * @brief Switch a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
void WeaponsSwitch(int client, int weapon) 
{
    // Gets active weapon index from the client
    int weapon2 = ToolsGetActiveWeapon(client);
    
    // Validate switch to the same slot
    if(weapon2 == -1 || SDKCall(hSDKCallGetSlot, weapon) == SDKCall(hSDKCallGetSlot, weapon2))
    {
        // Create call to the switch weapons
        SDKCall(hSDKCallWeaponSwitch, client, weapon, 1);
    }
    else
    {
        // Gets weapon classname
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(weapon, sClassname, sizeof(sClassname));

        // Switch with a client command
        FakeClientCommand(client, "use %s", sClassname);
    }
}

/**
 * @brief Remove a weapon.
 *
 * @param client            The client index.
 * @return                  True on success, false if client has access. 
 **/
bool WeaponsRemove(int client)
{
    // Initialize variables
    int iAmount; int bRemove;
    
    // i = weapon number
    int iSize = ToolsGetMyWeapons(client); 
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weapon = ToolsGetWeapon(client, i);
        
        // Validate weapon
        if(weapon != -1)
        {
            // Increment amount
            iAmount++;
    
            // Validate custom index
            int iD = WeaponsGetCustomID(weapon);
            if(iD != -1)
            {
                // Validate access
                if(!WeaponsValidateClass(client, iD)) 
                {
                    // Forces a player to remove weapon
                    RemovePlayerItem(client, weapon);
                    AcceptEntityInput(weapon, "Kill"); /// Destroy
                    
                    // Sets for return
                    bRemove = true;
                }
            }
        }
    }
    
    // If something was removed
    if(bRemove)
    {
        // Resets all suits
        ToolsSetHelmet(client, false);
        ToolsSetArmor(client, 0);
        ToolsSetHeavySuit(client, false);
        ToolsSetDefuser(client, false);
    }

    // Return on success
    return (bRemove || !iAmount);
}

/**
 * @brief Give weapon from a id.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 * @return                  The weapon index.
 **/
int WeaponsGive(int client, int iD)
{
    // Validate weapon index
    if(iD != -1)   
    {
        // Validate access
        if(!WeaponsValidateClass(client, iD)) 
        {
            return -1;
        }

        // Gets weapon def index
        ItemDef iItem = WeaponsGetDefIndex(iD);
        switch(iItem)
        {
            /// item_defuser, item_cutters
            case ItemDef_Defuser, ItemDef_Cutters : 
            {
                // Sets item id
                WeaponsSetCustomID(client, iD);
                
                // Sets defuser
                ToolsSetDefuser(client, true);
                
                // Return on success
                return 0;
            }
            
            /// item_heavyassaultsuit
            case ItemDef_HeavySuit :
            {
                // Sets heavy suit
                ToolsSetHelmet(client, true);
                ToolsSetArmor(client, WeaponsGetClip(iD));
                ToolsSetHeavySuit(client, true);
                
                // Return on success
                return 0;
            }
            
             /// item_nvgs
            case ItemDef_NGVs :
            {
                // Sets nightvision
                ToolsSetNightVision(client, true, true);
                ToolsSetNightVision(client, true);
                
                // Return on success
                return 0;
            }
                    
            /// item_kevlar
            case ItemDef_Kevlar :
            {
                // Sets armor
                ToolsSetHelmet(client, false);
                ToolsSetArmor(client, WeaponsGetClip(iD));
                ToolsSetHeavySuit(client, false);
                
                // Return on success
                return 0;
            }
                
            /// item_assaultsuit
            case ItemDef_KevlarHelmet :
            {
                // Sets kevlar
                ToolsSetHelmet(client, true);
                ToolsSetArmor(client, WeaponsGetClip(iD));
                ToolsSetHeavySuit(client, false);
                
                // Return on success
                return 0;
            }

            /// any weapon_*
            default :
            {
                // Create a weapon entity
                int weapon = WeaponsCreate(iD);
                
                // Validate weapon
                if(weapon != -1) 
                {
                    // Give weapon
                    WeaponsEquip(client, weapon);

                    // Call forward
                    gForwardData._OnWeaponCreated(client, weapon, iD);
                }
                
                // Return on success
                return weapon;  
            }
        }
    }

    // Return on success
    return -1;
}

/**
 * @brief Create a weapon.
 *
 * @param iD                The weapon id.
 * @param vPosition         (Optional) The origin of the spawn.
 * @param vAngle            (Optional) The angle of the spawn.
 * @return                  The weapon index.
 **/
int WeaponsCreate(int iD, float vPosition[3] = {0.0, 0.0, 0.0}, float vAngle[3] = {0.0, 0.0, 0.0})
{
    // Create weapon
    int weapon = PTaH_SpawnItemFromDefIndex(view_as<int>(WeaponsGetDefIndex(iD)), vPosition, vAngle);
    
    // Validate weapon
    if(weapon != -1)
    {
        // Sets weapon id
        WeaponsSetCustomID(weapon, iD);

        // Apply dropped model
        WeaponHDRSetDroppedModel(weapon, iD, ModelType_Drop);
    }
    
    // Return on success
    return weapon;
}

/*
 * Stocks weapons API.
 */

/**
 * @brief Returns index if the player has a weapon.
 *
 * @param client            The client index.
 * @param sType             The weapon entity.
 * @return                  The weapon index.
 **/
int WeaponsFindByName(int client, char[] sType)
{
    // Initialize classname char
    static char sClassname[SMALL_LINE_LENGTH];

    // i = weapon number
    int iSize = ToolsGetMyWeapons(client);
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weapon = ToolsGetWeapon(client, i);

        // Validate weapon
        if(weapon != -1)
        {
            // Gets weapon classname
            GetEdictClassname(weapon, sClassname, sizeof(sClassname));

            // If weapon find, then return
            if(!strcmp(sClassname[7], sType[7], false))
            {
                return weapon;
            }
        }
    }

    // Weapon doesn't exist
    return -1;
}

/**
 * @brief Returns true if the player has a weapon, false if not.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 * @return                  True or false.
 **/
bool WeaponsValidateByID(int client, int iD)
{
    // i = weapon number
    int iSize = ToolsGetMyWeapons(client);
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weapon = ToolsGetWeapon(client, i);
        
        // Validate weapon
        if(weapon != -1)
        {
            // If weapon find, then return
            if(WeaponsGetCustomID(weapon) == iD)
            {
                return true;
            }
        }
    }

    // Index doesn't exist
    return false;
}

/**
 * @brief Returns true if the class of the weapon id, false if not.
 *
 * @param iD                The weapon id.
 * @param sType             The class type.
 * @return                  True or false.    
 **/
bool WeaponsValidateByClass(int iD, char[] sType)
{
    // Gets weapon class
    static char sClass[BIG_LINE_LENGTH];
    WeaponsGetClass(iD, sClass, sizeof(sClass));
    
    // Validate length
    if(hasLength(sClass))
    {
        // If class find, then return
        return (hasLength(sType) && StrContain(sType, sClass, ','));
    }
    
    // Return on success
    return true;
}

/**
 * @brief Returns true if the player has an access by the class to the weapon id, false if not.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 * @return                  True or false.    
 **/
bool WeaponsValidateClass(int client, int iD)
{
    // Gets weapon class
    static char sClass[BIG_LINE_LENGTH];
    WeaponsGetClass(iD, sClass, sizeof(sClass));
    
    // Validate length
    if(hasLength(sClass))
    {
        // Gets class type 
        static char sType[SMALL_LINE_LENGTH];
        ClassGetType(gClientData[client].Class, sType, sizeof(sType));
        
        // If class find, then return
        return (hasLength(sType) && StrContain(sType, sClass, ','));
    }
    
    // Return on success
    return true;
}

/**
 * @brief Returns true if the player has an access to use the weapon, false if not.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @return                  True or false.    
 **/
bool WeaponsValidateAccess(int client, int weapon)
{
    // Validate custom index
    int iD = WeaponsGetCustomID(weapon);
    if(iD != -1)
    {
        // Block pickup it, if not available
        if(!WeaponsValidateClass(client, iD)) 
        {
            return false;
        }

        // Block pickup it, if online too low
        if(fnGetPlaying() < WeaponsGetOnline(iD))
        {
            return false;
        }

        // Block pickup it, if level too low
        if(gClientData[client].Level < WeaponsGetLevel(iD))
        {
            return false;
        }
    }
    
    // Return on success
    return true;
}