/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          weapons.sp
 *  Type:          Manager
 *  Description:   API for all weapon-related functions.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
	WEAPONS_DATA_TYPES,
	WEAPONS_DATA_LEVEL,
	WEAPONS_DATA_ONLINE,
	WEAPONS_DATA_DAMAGE,
	WEAPONS_DATA_KNOCKBACK,
	WEAPONS_DATA_SPEED,
	WEAPONS_DATA_JUMP,
	WEAPONS_DATA_CLIP,
	WEAPONS_DATA_AMMO,
	WEAPONS_DATA_AMMUNITION,
	WEAPONS_DATA_DROP,
	WEAPONS_DATA_SHOOT,
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
	WEAPONS_DATA_MODEL_BODY = 26,
	WEAPONS_DATA_MODEL_SKIN = 30,
	WEAPONS_DATA_MODEL_MUZZLE = 34,
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
#include "zp/weapons/weaponmod.sp"
#include "zp/weapons/weaponhdr.sp"
#include "zp/weapons/weaponattach.sp"

/**
 * @brief Weapons module init function.
 **/
void WeaponsOnInit()
{
	HookEvent("weapon_fire",     WeaponsOnFire,    EventHookMode_Pre);
	HookEvent("bullet_impact",   WeaponsOnBullet,  EventHookMode_Post);
	HookEvent("hostage_follows", WeaponsOnHostage, EventHookMode_Post);
	
	AddTempEntHook("Shotgun Shot", WeaponsOnShoot);
	
	WeaponMODOnInit();
}

/**
 * @brief Prepare all weapon data.
 **/
void WeaponsOnLoad()
{
	ConfigRegisterConfig(File_Weapons, Structure_KeyValue, CONFIG_FILE_ALIAS_WEAPONS);

	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_WEAPONS, sBuffer, sizeof(sBuffer));

	if (!bExists)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Missing weapons config file: \"%s\"", sBuffer);
		return;
	}

	ConfigSetConfigPath(File_Weapons, sBuffer);

	bool bSuccess = ConfigLoadConfig(File_Weapons, gServerData.Weapons);
	
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error encountered loading: \"%s\"", sBuffer);
		return;
	}

	WeaponsOnCacheData();

	ConfigSetConfigLoaded(File_Weapons, true);
	ConfigSetConfigReloadFunc(File_Weapons, GetFunctionByName(GetMyHandle(), "WeaponsOnConfigReload"));
	ConfigSetConfigHandle(File_Weapons, gServerData.Weapons);
	
	WeaponMODOnLoad();
}

/**
 * @brief Caches weapon data from file into arrays.
 **/
void WeaponsOnCacheData()
{
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Weapons, sBuffer, sizeof(sBuffer));

	KeyValues kvWeapons;
	bool bSuccess = ConfigOpenConfigFile(File_Weapons, kvWeapons);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error caching data from weapons config file: \"%s\"", sBuffer);
		return;
	}
	
	if (gServerData.Entities == null)
	{
		gServerData.Entities = new StringMap();
	}
	else
	{
		gServerData.Entities.Clear();
	}
	
	int iSize = gServerData.Weapons.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "No usable data found in weapons config file: \"%s\"", sBuffer);
		return;
	}

	for (int i = 0; i < iSize; i++)
	{
		WeaponsGetName(i, sBuffer, sizeof(sBuffer)); // Index: 0
		kvWeapons.Rewind();
		if (!kvWeapons.JumpToKey(sBuffer))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon data for: \"%s\" (check weapons config)", sBuffer);
			continue;
		}
		
		if (!TranslationIsPhraseExists(sBuffer))
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon name: \"%s\" (check translation file)", sBuffer);
			continue;
		}
		
		ArrayList arrayWeapon = gServerData.Weapons.Get(i); 
 
		kvWeapons.GetString("info", sBuffer, sizeof(sBuffer), "");
		if (hasLength(sBuffer) && !TranslationIsPhraseExists(sBuffer))
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon info: \"%s\" (check translation file)", sBuffer);
		}
		arrayWeapon.PushString(sBuffer);                                  // Index: 1
		kvWeapons.GetString("entity", sBuffer, sizeof(sBuffer), "");
		gServerData.Entities.SetValue(sBuffer, i, false);  /// Unique entity catched
		int iItem = WeaponsGetItemDefIndex(sBuffer);
		if (iItem == 0)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon entity: \"%s\" (check weapons config)", sBuffer);
		}
		arrayWeapon.Push(iItem);                                          // Index: 2
		kvWeapons.GetString("group", sBuffer, sizeof(sBuffer), "");       
		arrayWeapon.PushString(sBuffer);                                  // Index: 3
		kvWeapons.GetString("types", sBuffer, sizeof(sBuffer), "human");  
		arrayWeapon.Push(ClassTypeToIndex(sBuffer));                      // Index: 4
		arrayWeapon.Push(kvWeapons.GetNum("level", 0));                   // Index: 5
		arrayWeapon.Push(kvWeapons.GetNum("online", 0));                  // Index: 6
		arrayWeapon.Push(kvWeapons.GetFloat("damage", 1.0));              // Index: 7
		arrayWeapon.Push(kvWeapons.GetFloat("knockback", 1.0));           // Index: 8
		arrayWeapon.Push(kvWeapons.GetFloat("speed", 0.0));               // Index: 9
		arrayWeapon.Push(kvWeapons.GetFloat("jump", 0.0));                // Index: 10
		arrayWeapon.Push(kvWeapons.GetNum("clip", 0));                    // Index: 11
		arrayWeapon.Push(kvWeapons.GetNum("ammo", 0));                    // Index: 12
		arrayWeapon.Push(kvWeapons.GetNum("ammunition", 0));              // Index: 13
		arrayWeapon.Push(ConfigKvGetStringBool(kvWeapons, "drop", "on")); // Index: 14
		arrayWeapon.Push(kvWeapons.GetFloat("shoot", 0.0));               // Index: 15
		arrayWeapon.Push(kvWeapons.GetFloat("reload", 0.0));              // Index: 16
		arrayWeapon.Push(kvWeapons.GetFloat("deploy", 0.0));              // Index: 17
		kvWeapons.GetString("sound", sBuffer, sizeof(sBuffer), "");       
		arrayWeapon.Push(SoundsKeyToIndex(sBuffer));                      // Index: 18
		kvWeapons.GetString("icon", sBuffer, sizeof(sBuffer), "");        
		arrayWeapon.PushString(sBuffer);                                  // Index: 19
		if (hasLength(sBuffer))
		{
			Format(sBuffer, sizeof(sBuffer), "materials/panorama/images/icons/equipment/%s.svg", sBuffer);
			if (FileExists(sBuffer)) AddFileToDownloadsTable(sBuffer); 
		}
		kvWeapons.GetString("view", sBuffer, sizeof(sBuffer), "");
		arrayWeapon.PushString(sBuffer);                                  // Index: 20    
		arrayWeapon.Push(DecryptPrecacheWeapon(sBuffer));                 // Index: 21
		kvWeapons.GetString("world", sBuffer, sizeof(sBuffer), "");       
		arrayWeapon.PushString(sBuffer);                                  // Index: 22
		arrayWeapon.Push(DecryptPrecacheModel(sBuffer));                  // Index: 23
		kvWeapons.GetString("dropped", sBuffer, sizeof(sBuffer), "");     
		arrayWeapon.PushString(sBuffer);                                  // Index: 24
		arrayWeapon.Push(DecryptPrecacheModel(sBuffer));                  // Index: 25
		int iBody[4]; kvWeapons.GetColor4("body", iBody);                 
		for (int x = 0; x < 4; x++)
		{
			arrayWeapon.Push(iBody[x]);                                   // Index: 26+x
		}
		int iSkin[4]; kvWeapons.GetColor4("skin", iSkin);
		for (int x = 0; x < 4; x++)
		{
			arrayWeapon.Push(iSkin[x]);                                   // Index: 30+x
		}
		kvWeapons.GetString("muzzle", sBuffer, sizeof(sBuffer), "");
		arrayWeapon.PushString(sBuffer);                                  // Index: 34
		kvWeapons.GetString("shell", sBuffer, sizeof(sBuffer), "");       
		arrayWeapon.PushString(sBuffer);                                  // Index: 35
		arrayWeapon.Push(kvWeapons.GetFloat("heat", 0.5));                // Index: 36
		arrayWeapon.Push(-1);                                             // Index: 37
		for (int x = 0; x < WEAPONS_SEQUENCE_MAX; x++)
		{
			arrayWeapon.Push(-1);                                         // Index: 38+x
		}                      
	}

	delete kvWeapons;
}

/**
 * @brief Purge weapon SDK data.
 **/
void WeaponsOnUnload()
{
	WeaponAttachOnUnload();
	WeaponMODOnUnload();
}

/**
 * @brief Called when config is being reloaded.
 **/
public void WeaponsOnConfigReload()
{
	WeaponsOnLoad();
}

/**
 * @brief Creates commands for weapons module.
 **/
void WeaponsOnCommandInit()
{
	WeaponMODOnCommandInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void WeaponsOnClientInit(int client)
{
	WeaponMODOnClientInit(client);
}

/**
 * @brief Hook weapons cvar changes.
 **/
void WeaponsOnCvarInit()
{
	gCvarList.WEAPONS_GIVE_TASER           = FindConVar("mp_weapons_allow_zeus");
	gCvarList.WEAPONS_GIVE_BOMB            = FindConVar("mp_give_player_c4");
	gCvarList.WEAPONS_DROP_GRENADE         = FindConVar("mp_drop_grenade_enable");
	gCvarList.WEAPONS_DROP_KNIFE           = FindConVar("mp_drop_knife_enable");
	gCvarList.WEAPONS_DROP_BREACH          = FindConVar("mp_death_drop_breachcharge");
	gCvarList.WEAPONS_CT_DEFAULT_GRENADES  = FindConVar("mp_ct_default_grenades");
	gCvarList.WEAPONS_CT_DEFAULT_MELEE     = FindConVar("mp_ct_default_melee");
	gCvarList.WEAPONS_CT_DEFAULT_SECONDARY = FindConVar("mp_ct_default_secondary");
	gCvarList.WEAPONS_CT_DEFAULT_PRIMARY   = FindConVar("mp_ct_default_primary");
	gCvarList.WEAPONS_T_DEFAULT_GRENADES   = FindConVar("mp_t_default_grenades");
	gCvarList.WEAPONS_T_DEFAULT_MELEE      = FindConVar("mp_t_default_melee");
	gCvarList.WEAPONS_T_DEFAULT_SECONDARY  = FindConVar("mp_t_default_secondary");
	gCvarList.WEAPONS_T_DEFAULT_PRIMARY    = FindConVar("mp_t_default_primary");

	gCvarList.WEAPONS_GIVE_TASER.IntValue   = 1;
	gCvarList.WEAPONS_GIVE_BOMB.IntValue    = 0;
	gCvarList.WEAPONS_DROP_GRENADE.IntValue = 1;
	gCvarList.WEAPONS_DROP_BREACH.IntValue  = 1;
	gCvarList.WEAPONS_DROP_KNIFE.IntValue   = 0;
	gCvarList.WEAPONS_CT_DEFAULT_GRENADES.SetString("");
	gCvarList.WEAPONS_CT_DEFAULT_MELEE.SetString("");
	gCvarList.WEAPONS_CT_DEFAULT_SECONDARY.SetString("");
	gCvarList.WEAPONS_CT_DEFAULT_PRIMARY.SetString("");
	gCvarList.WEAPONS_T_DEFAULT_GRENADES.SetString("");
	gCvarList.WEAPONS_T_DEFAULT_MELEE.SetString("");
	gCvarList.WEAPONS_T_DEFAULT_SECONDARY.SetString("");
	gCvarList.WEAPONS_T_DEFAULT_PRIMARY.SetString("");
	
	HookConVarChange(gCvarList.WEAPONS_GIVE_TASER,           CvarsUnlockOnCvarHook);
	HookConVarChange(gCvarList.WEAPONS_GIVE_BOMB,            CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.WEAPONS_DROP_GRENADE,         CvarsUnlockOnCvarHook);
	HookConVarChange(gCvarList.WEAPONS_DROP_BREACH,          CvarsUnlockOnCvarHook);
	HookConVarChange(gCvarList.WEAPONS_DROP_KNIFE,           CvarsLockOnCvarHook);  
	HookConVarChange(gCvarList.WEAPONS_CT_DEFAULT_GRENADES,  CvarsLockOnCvarHook3);
	HookConVarChange(gCvarList.WEAPONS_CT_DEFAULT_MELEE,     CvarsLockOnCvarHook3);
	HookConVarChange(gCvarList.WEAPONS_CT_DEFAULT_SECONDARY, CvarsLockOnCvarHook3);
	HookConVarChange(gCvarList.WEAPONS_CT_DEFAULT_PRIMARY,   CvarsLockOnCvarHook3);
	HookConVarChange(gCvarList.WEAPONS_T_DEFAULT_GRENADES,   CvarsLockOnCvarHook3);
	HookConVarChange(gCvarList.WEAPONS_T_DEFAULT_MELEE,      CvarsLockOnCvarHook3);
	HookConVarChange(gCvarList.WEAPONS_T_DEFAULT_SECONDARY,  CvarsLockOnCvarHook3);
	HookConVarChange(gCvarList.WEAPONS_T_DEFAULT_PRIMARY,    CvarsLockOnCvarHook3);

	WeaponMODOnCvarInit();
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
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsPlayerExist(client))
	{
		return Plugin_Continue;
	}

	int weapon = ToolsGetActiveWeapon(client);
	
	if (weapon == -1)
	{
		return Plugin_Continue;
	}
	
	
	WeaponMODOnFire(client, weapon);
	
	return Plugin_Continue;
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
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsPlayerExist(client))
	{
		return Plugin_Continue;
	}

	int weapon = ToolsGetActiveWeapon(client);
	
	if (weapon == -1)
	{
		return Plugin_Continue;
	}
	
	static float vBullet[3];

	vBullet[0] = hEvent.GetFloat("x");
	vBullet[1] = hEvent.GetFloat("y");
	vBullet[2] = hEvent.GetFloat("z");
	
	WeaponMODOnBullet(client, vBullet, weapon);
	
	return Plugin_Continue;
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
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsPlayerExist(client))
	{
		return Plugin_Continue;
	}
	
	WeaponMODOnHostage(client);
	
	return Plugin_Continue;
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
	int client = TE_ReadNum("m_iPlayer") + 1;

	if (!IsPlayerExist(client))
	{
		return Plugin_Continue;
	}
	
	int weapon = ToolsGetActiveWeapon(client);
	
	if (weapon == -1)
	{
		return Plugin_Continue;
	}
	
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
	if (iButtons & IN_USE)
	{
		if (!(iLastButtons & IN_USE))
		{
			WeaponMODOnUse(client);
		}
	}
	
	static int weapon; weapon = ToolsGetActiveWeapon(client);

	if (weapon == -1 || !gClientData[client].RunCmd)
	{
		return Plugin_Continue;
	}

	return WeaponMODOnRunCmd(client, iButtons, iLastButtons, weapon);
}

/**
 * @brief Client has been changed class state. *(Post)
 *
 * @param userID            The user id.
 **/
public void WeaponsOnClientUpdate(int userID)
{
	int client = GetClientOfUserId(userID);
	
	if (client)
	{
		WeaponAttachOnClientUpdate(client);
		WeaponMODOnClientUpdate(client);
	}
}

/**
 * @brief Fake client has been think.
 *
 * @param client            The client index.
 **/
void WeaponsOnFakeClientThink(int client)
{
	WeaponMODOnFakeClientThink(client);
}

/**
 * @brief Client has been spawned.
 *
 * @param client            The client index.
 **/
void WeaponsOnClientSpawn(int client)
{
	WeaponAttachOnClientSpawn(client);
}

/**
 * @brief Client has been killed.
 *
 * @param client            The client index.
 **/
void WeaponsOnClientDeath(int client)
{
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
	if (weapon > -1)
	{
		WeaponMODOnEntityCreated(weapon, sClassname);
	}
}

/*
 * Weapons natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void WeaponsOnNativeInit() 
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
	CreateNative("ZP_GetWeaponTypes",        API_GetWeaponTypes);
	CreateNative("ZP_GetWeaponLevel",        API_GetWeaponLevel);
	CreateNative("ZP_GetWeaponOnline",       API_GetWeaponOnline);
	CreateNative("ZP_GetWeaponDamage",       API_GetWeaponDamage);
	CreateNative("ZP_GetWeaponKnockBack",    API_GetWeaponKnockBack);
	CreateNative("ZP_GetWeaponSpeed",        API_GetWeaponSpeed);
	CreateNative("ZP_GetWeaponJump",         API_GetWeaponJump);
	CreateNative("ZP_GetWeaponClip",         API_GetWeaponClip);
	CreateNative("ZP_GetWeaponAmmo",         API_GetWeaponAmmo);
	CreateNative("ZP_GetWeaponAmmunition",   API_GetWeaponAmmunition);
	CreateNative("ZP_IsWeaponDrop",          API_IsWeaponDrop);
	CreateNative("ZP_GetWeaponShoot",        API_GetWeaponShoot);
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
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	static float vPosition[3]; static float vAngle[3];

	GetNativeArray(2, vPosition, sizeof(vPosition));
	GetNativeArray(3, vAngle, sizeof(vAngle));
	
	return WeaponsCreate(iD, vPosition, vAngle);
}

/**
 * @brief Gives the weapon by a given id.
 *
 * @note native int ZP_GiveClientWeapon(client, id, switch);
 **/
public int API_GiveClientWeapon(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	if (!IsPlayerExist(client))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", client);
		return -1;
	}
	
	int iD = GetNativeCell(2);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}

	return WeaponsGive(client, iD, GetNativeCell(3));
}

/**
 * @brief Switches to the weapon by an index.
 *
 * @note native bool ZP_SwitchClientWeapon(client, weapon);
 **/
public int API_SwitchClientWeapon(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	if (!IsPlayerExist(client))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", client);
		return false;
	}
	
	int weapon = GetNativeCell(2);
	
	if (!IsValidEdict(weapon))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", weapon);
		return false;
	}
	
	WeaponsSwitch(client, weapon);
	return true;
}

/**
 * @brief Gets the client viewmodel.
 *
 * @note native int ZP_GetClientViewModel(client, custom);
 **/
public int API_GetClientViewModel(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	if (!IsPlayerExist(client))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", client);
		return -1;
	}
	
	return EntRefToEntIndex(gClientData[client].ViewModels[GetNativeCell(2)]);
}

/**
 * @brief Gets the client attachmodel.
 *
 * @note native int ZP_GetClientAttachModel(client, bit);
 **/
public int API_GetClientAttachModel(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	if (!IsPlayerExist(client))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the client index (%d)", client);
		return -1;
	}
	
	BitType mBits = GetNativeCell(2);
	if (mBits == BitType_Invalid)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the bit index (%d)", mBits);
		return -1;
	}
	
	return EntRefToEntIndex(gClientData[client].AttachmentAddons[mBits]);
}

/**
 * @brief Gets the custom weapon id from a given name.
 *
 * @note native int ZP_GetWeaponNameID(name);
 **/
public int API_GetWeaponNameID(Handle hPlugin, int iNumParams)
{
	int maxLen;
	GetNativeStringLength(1, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Can't find weapon with an empty name");
		return -1;
	}

	static char sName[SMALL_LINE_LENGTH];                                         
	GetNativeString(1, sName, sizeof(sName));
	
	return WeaponsNameToIndex(sName);
}

/**
 * @brief Gets the amount of all weapons.
 *
 * @note native int ZP_GetNumberWeapon();
 **/
public int API_GetNumberWeapon(Handle hPlugin, int iNumParams)
{
	return gServerData.Weapons.Length;
}

/**
 * @brief Gets the name of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponName(iD, name, maxlen);
 **/
public int API_GetWeaponName(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sName[SMALL_LINE_LENGTH];
	WeaponsGetName(iD, sName, sizeof(sName));

	return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the info of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponInfo(iD, info, maxlen);
 **/
public int API_GetWeaponInfo(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sInfo[SMALL_LINE_LENGTH];
	WeaponsGetInfo(iD, sInfo, sizeof(sInfo));

	return SetNativeString(2, sInfo, maxLen);
}

/**
 * @brief Gets the group of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponGroup(iD, group, maxlen);
 **/
public int API_GetWeaponGroup(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sGroup[SMALL_LINE_LENGTH];
	WeaponsGetGroup(iD, sGroup, sizeof(sGroup));

	return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the types of the weapon.
 *
 * @note native int ZP_GetWeaponTypes(iD);
 **/
public int API_GetWeaponTypes(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetTypes(iD);
}

/**
 * @brief Gets the defenition index of the weapon.
 *
 * @note native ItemDef ZP_GetWeaponDefIndex(iD);
 **/
public int API_GetWeaponDefIndex(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(WeaponsGetDefIndex(iD));
}

/**
 * @brief Gets the level of the weapon.
 *
 * @note native int ZP_GetWeaponLevel(iD);
 **/
public int API_GetWeaponLevel(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetLevel(iD);
}

/**
 * @brief Gets the online of the weapon.
 *
 * @note native int ZP_GetWeaponOnline(iD);
 **/
public int API_GetWeaponOnline(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetOnline(iD);
}

/**
 * @brief Gets the damage of the weapon.
 *
 * @note native float ZP_GetWeaponDamage(iD);
 **/
public int API_GetWeaponDamage(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(WeaponsGetDamage(iD));
}

/**
 * @brief Gets the knockback of the weapon.
 *
 * @note native float ZP_GetWeaponKnockBack(iD);
 **/
public int API_GetWeaponKnockBack(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(WeaponsGetKnockBack(iD));
}

/**
 * @brief Gets the moving speed of the weapon.
 *
 * @note native float ZP_GetWeaponSpeed(iD);
 **/
public int API_GetWeaponSpeed(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(WeaponsGetSpeed(iD));
}

/**
 * @brief Gets the jump power of the weapon.
 *
 * @note native float ZP_GetWeaponJump(iD);
 **/
public int API_GetWeaponJump(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(WeaponsGetJump(iD));
}

/**
 * @brief Gets the clip ammo of the weapon.
 *
 * @note native int ZP_GetWeaponClip(iD);
 **/
public int API_GetWeaponClip(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetClip(iD);
}

/**
 * @brief Gets the reserve ammo of the weapon.
 *
 * @note native int ZP_GetWeaponAmmo(iD);
 **/
public int API_GetWeaponAmmo(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetAmmo(iD);
}

/**
 * @brief Gets the ammunition cost of the weapon.
 *
 * @note native int ZP_GetWeaponAmmunition(iD);
 **/
public int API_GetWeaponAmmunition(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetAmmunition(iD);
}

/**
 * @brief Checks the drop value of the weapon.
 *
 * @note native bool ZP_IsWeaponDrop(iD);
 **/
public int API_IsWeaponDrop(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsIsDrop(iD);
}

/**
 * @brief Gets the shoot delay of the weapon.
 *
 * @note native float ZP_GetWeaponShoot(iD);
 **/
public int API_GetWeaponShoot(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(WeaponsGetShoot(iD));
}

/**
 * @brief Gets the reload duration of the weapon.
 *
 * @note native float ZP_GetWeaponReload(iD);
 **/
public int API_GetWeaponReload(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(WeaponsGetReload(iD));
}

/**
 * @brief Gets the deploy duration of the weapon.
 *
 * @note native float ZP_GetWeaponDeploy(iD);
 **/
public int API_GetWeaponDeploy(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(WeaponsGetDeploy(iD));
}

/**
 * @brief Gets the sound key of the weapon.
 *
 * @note native int ZP_GetWeaponSoundID(iD);
 **/
public int API_GetWeaponSoundID(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}

	return WeaponsGetSoundID(iD);
}

/**
 * @brief Gets the icon of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponIcon(iD, info, maxlen);
 **/
public int API_GetWeaponIcon(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sIcon[SMALL_LINE_LENGTH];
	WeaponsGetIcon(iD, sIcon, sizeof(sIcon));

	return SetNativeString(2, sIcon, maxLen);
}

/**
 * @brief Gets the viewmodel path of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelView(iD, model, maxlen);
 **/
public int API_GetWeaponModelView(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sModel[PLATFORM_LINE_LENGTH];
	WeaponsGetModelView(iD, sModel, sizeof(sModel));

	return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the index of the weapon viewmodel.
 *
 * @note native int ZP_GetWeaponModelViewID(iD);
 **/
public int API_GetWeaponModelViewID(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetModelViewID(iD);
}

/**
 * @brief Gets the worldmodel path of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelWorld(iD, model, maxlen);
 **/
public int API_GetWeaponModelWorld(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sModel[PLATFORM_LINE_LENGTH];
	WeaponsGetModelWorld(iD, sModel, sizeof(sModel));

	return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the index of the weapon worldmodel.
 *
 * @note native int ZP_GetWeaponModelWorldID(iD);
 **/
public int API_GetWeaponModelWorldID(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetModelWorldID(iD);
}

/**
 * @brief Gets the dropmodel path of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelDrop(iD, model, maxlen);
 **/
public int API_GetWeaponModelDrop(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sModel[PLATFORM_LINE_LENGTH];
	WeaponsGetModelDrop(iD, sModel, sizeof(sModel));

	return SetNativeString(2, sModel, maxLen);
}

/**
 * @brief Gets the index of the weapon dropmodel.
 *
 * @note native int ZP_GetWeaponModelDropID(iD);
 **/
public int API_GetWeaponModelDropID(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	return WeaponsGetModelDropID(iD);
}

/**
 * @brief Gets the body index of the weapon model.
 *
 * @note native int ZP_GetWeaponModelBody(iD, model);
 **/
public int API_GetWeaponModelBody(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	ModelType nModel = GetNativeCell(2);
	if (nModel == ModelType_Invalid)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the model index (%d)", nModel);
		return -1;
	}
	
	return WeaponsGetModelBody(iD, nModel);
}

/**
 * @brief Gets the skin index of the weapon model.
 *
 * @note native int ZP_GetWeaponModelSkin(iD, model);
 **/
public int API_GetWeaponModelSkin(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}

	ModelType nModel = GetNativeCell(2);
	if (nModel == ModelType_Invalid)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the model index (%d)", nModel);
		return -1;
	}
	
	return WeaponsGetModelSkin(iD, nModel);
}

/**
 * @brief Gets the muzzle name of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelMuzzle(iD, muzzle, maxlen);
 **/
public int API_GetWeaponModelMuzzle(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sMuzzle[NORMAL_LINE_LENGTH];
	WeaponsGetModelMuzzle(iD, sMuzzle, sizeof(sMuzzle));

	return SetNativeString(2, sMuzzle, maxLen);
}

/**
 * @brief Gets the shell name of a weapon at a given id.
 *
 * @note native void ZP_GetWeaponModelShell(iD, shell, maxlen);
 **/
public int API_GetWeaponModelShell(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sShell[NORMAL_LINE_LENGTH];
	WeaponsGetModelShell(iD, sShell, sizeof(sShell));

	return SetNativeString(2, sShell, maxLen);
}

/**
 * @brief Gets the heat amount of the weapon viewmodel.
 *
 * @note native float ZP_GetWeaponModelHeat(iD);
 **/
public int API_GetWeaponModelHeat(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.Weapons.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	arrayWeapon.GetString(WEAPONS_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * @brief Gets the types of a weapon.
 *
 * @param iD                The weapon id.
 * @return                  The types bits.
 **/
int WeaponsGetTypes(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_TYPES);
}

/**
 * @brief Gets the defenition index of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The def index.
 **/
ItemDef WeaponsGetDefIndex(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_DEFINDEX);
}

/**
 * @brief Gets the level of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The level amount.    
 **/
int WeaponsGetLevel(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_ONLINE);
}

/**
 * @brief Gets the damage of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The damage amount.    
 **/
float WeaponsGetDamage(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_KNOCKBACK);
}

/**
 * @brief Gets the moving speed of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The speed amount.
 **/
float WeaponsGetSpeed(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_SPEED);
}

/**
 * @brief Gets the jump power of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The speed amount.
 **/
float WeaponsGetJump(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_JUMP);
}

/**
 * @brief Gets the clip ammo of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The clip ammo amount.
 **/
int WeaponsGetClip(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_DROP);
}

/**
 * @brief Gets the shoot delay of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The delay amount.
 **/
float WeaponsGetShoot(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_SHOOT);
}

/**
 * @brief Gets the reload duration of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The duration amount.
 **/
float WeaponsGetReload(int iD)
{
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);

	return arrayWeapon.Get(WEAPONS_DATA_MODEL_BODY + view_as<int>(nModel));
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);

	return arrayWeapon.Get(WEAPONS_DATA_MODEL_SKIN + view_as<int>(nModel));
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	return arrayWeapon.Get(WEAPONS_DATA_SEQUENCE_COUNT);
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);

	return arrayWeapon.Get(WEAPONS_DATA_SEQUENCE_SWAP + iSequence);
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
	ArrayList arrayWeapon = gServerData.Weapons.Get(iD);
	
	for (int i = 0; i < iMaxLen; i++)
	{
		arrayWeapon.Set(WEAPONS_DATA_SEQUENCE_SWAP + i, iSeq[i]);
	}
}

/*
 * Generic weapons API.
 */
 
/**
 * @brief Gets the map weapon state.
 *
 * @param weapon            The weapon index.
 * @return                  True or false.    
 **/
bool WeaponsIsSpawnedByMap(int weapon)
{
	return view_as<bool>(GetEntProp(weapon, Prop_Data, "m_bIsAutoaimTarget"));
}

/**
 * @brief Controls the map weapon state.
 *
 * @param weapon            The weapon index.
 * @param bSet              Enable or disable an aspect of map state.
 **/
void WeaponsSetSpawnedByMap(int weapon, bool bSet)
{
	SetEntProp(weapon, Prop_Data, "m_bIsAutoaimTarget", bSet);
}

/**
 * @brief Gets the weapon owner.
 *
 * @param weapon            The weapon index.
 * @return                  The owner index.    
 **/
int WeaponsGetOwner(int weapon)
{
	return GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
}

/**
 * @brief Sets the weapon owner.
 *
 * @param weapon            The weapon index.
 * @param owner             The owner index.  
 **/
void WeaponsSetOwner(int weapon, int owner)
{
	SetEntPropEnt(weapon, Prop_Send, "m_hOwner", owner);
}

/**
 * @brief Gets the ammo type.
 *
 * @param weapon            The weapon index.
 * @return                  The ammo type.    
 **/
int WeaponsGetAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
} 

/**
 * @brief Gets the current reserve ammo.
 *
 * @param weapon            The weapon index.
 * @return                  The ammo count.    
 **/
int WeaponsGetReserveAmmo(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
}

/**
 * @brief Sets the current reserve ammo.
 *
 * @param weapon            The weapon index.
 * @param iAmmo             The ammo count.  
 **/
void WeaponsSetReserveAmmo(int weapon, int iAmmo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo);
}

/**
 * @brief Gets the max reserve ammo.
 *
 * @param weapon            The weapon index.
 * @return                  The max ammo count.    
 **/
int WeaponsGetMaxReserveAmmo(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount");
}

/**
 * @brief Sets the max reserve ammo.
 *
 * @param weapon            The weapon index.
 * @param iMaxAmmo          The max ammo count.  
 **/
void WeaponsSetMaxReserveAmmo(int weapon, int iMaxAmmo)
{
	SetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount", iMaxAmmo);
}

/**
 * @brief Gets the current clip ammo.
 *
 * @param weapon            The weapon index.
 * @return                  The ammo count.    
 **/
/*int WeaponsGetClipAmmo(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iClip1");
}*/

/**
 * @brief Sets the current clip ammo.
 *
 * @param weapon            The weapon index.
 * @param iAmmo             The ammo count.  
 **/
void WeaponsSetClipAmmo(int weapon, int iAmmo)
{
	SetEntProp(weapon, Prop_Send, "m_iClip1", iAmmo);
}

/**
 * @brief Gets the max clip ammo.
 *
 * @param weapon            The weapon index.
 * @return                  The max ammo count.    
 **/
int WeaponsGetMaxClipAmmo(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iClip2");
}

/**
 * @brief Sets the max clip ammo.
 *
 * @param weapon            The weapon index.
 * @param iMaxAmmo          The max ammo count.  
 **/
void WeaponsSetMaxClipAmmo(int weapon, int iMaxAmmo)
{
	SetEntProp(weapon, Prop_Send, "m_iClip2", iMaxAmmo);
}

/**
 * @brief Sets the animation delay.
 *
 * @param weapon            The weapon index.
 * @param flDelay           The delay duration.  
 **/
void WeaponsSetAnimating(int weapon, float flDelay)
{
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
	static char sWeaponName[SMALL_LINE_LENGTH];
	
	int iSize = gServerData.Weapons.Length;
	for (int i = 0; i < iSize; i++)
	{
		WeaponsGetName(i, sWeaponName, sizeof(sWeaponName));

		if (!strcmp(sName, sWeaponName, false))
		{
			return i;
		}
	}
	
	return -1;
}

/**
 * @brief Remove (drop) all weapons.
 *
 * @param client            The client index.
 * @param bDrop             (Optional) True to drop weapons, false to destroy.
 * @return                  True on success, false if client has access. 
 **/
bool WeaponsRemoveAll(int client, bool bDrop = false)
{
	int iAmount; bool bRemove;
	
	int iSize = ToolsGetMyWeapons(client); 
	for (int i = 0; i < iSize; i++)
	{
		int weapon = ToolsGetWeapon(client, i);
		
		if (weapon != -1)
		{
			iAmount++;
	
			int iD = ToolsGetCustomID(weapon);
			if (iD != -1)
			{
				if (!WeaponsHasAccessByType(client, iD)) 
				{
					if (bDrop && WeaponsIsDrop(iD))
					{
						WeaponsDrop(client, weapon, false);
					}
					else
					{
						RemovePlayerItem(client, weapon);
						AcceptEntityInput(weapon, "Kill"); /// Destroy
					}

					bRemove = true;
				}
			}
		}
	}
	
	if (bRemove)
	{
		ToolsSetHelmet(client, false);
		ToolsSetArmor(client, 0);
		ToolsSetHeavySuit(client, false);
		ToolsSetDefuser(client, false);
		ToolsSetCustomID(client, -1);
	}

	return (bRemove || !iAmount);
}

/**
 * @brief Drop/remove a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param bMsg              (Optional) True to show the info, false otherwise.
 **/
void WeaponsDrop(int client, int weapon, bool bMsg = true)
{
	if (IsValidEdict(weapon)) 
	{
		int owner = ToolsGetOwner(weapon);

		if (owner != client)
		{
			ToolsSetOwner(weapon, client);
		}

		CS_DropWeapon(client, weapon, false, false);
		
		if (bMsg && gCvarList.MESSAGES_WEAPON_DROP.BoolValue && gCvarList.GAMEMODE_WEAPONS_REMOVE.BoolValue && gServerData.RoundNew)
		{
			TranslationPrintToChat(client, "info drop");
		}
	}
}

/**
 * @brief Switch a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
void WeaponsSwitch(int client, int weapon) 
{
	int weapon2 = ToolsGetActiveWeapon(client);
	
	if (hSDKCallWeaponSwitch && (weapon2 == -1 || WeaponsGetSlotType(weapon) == WeaponsGetSlotType(weapon2)))
	{
		SDKCall(hSDKCallWeaponSwitch, client, weapon, 1);
	}
	else
	{
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));

		FakeClientCommand(client, "use %s", sClassname);
	}
}

/**
 * @brief Equip a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param iD                The weapon id.
 * @param bSwitch           (Optional) True to switch, false to just equip.
 **/
void WeaponsEquip(int client, int weapon, int iD, bool bSwitch = true)
{
	static char sClassname[SMALL_LINE_LENGTH]; int weapon2 = -1;

	SlotType mSlot = WeaponsGetSlotType(weapon);
	switch (mSlot)
	{
		case SlotType_Equipment :
		{
			GetEdictClassname(weapon, sClassname, sizeof(sClassname));
			
			weapon2 = WeaponsFindByName(client, sClassname);
			
			if (weapon2 != -1 && ToolsGetCustomID(weapon2) == iD)
			{
				weapon2 = -1;
			}
		}
	
		case SlotType_C4 :
		{
			GetEdictClassname(weapon, sClassname, sizeof(sClassname));
			
			weapon2 = WeaponsFindByName(client, sClassname);
		}

		default : 
		{
			weapon2 = GetPlayerWeaponSlot(client, view_as<int>(mSlot));
		}
	}
	
	if (weapon2 != -1)
	{
		WeaponsDrop(client, weapon2);
	}
	
	EquipPlayerWeapon(client, weapon); 
	
	if (bSwitch)
	{
		WeaponsSwitch(client, weapon);
	}
}

/**
 * @brief Give weapon from a id.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 * @param bSwitch           (Optional) True to switch, false to just equip.
 * @return                  The weapon index.
 **/
int WeaponsGive(int client, int iD, bool bSwitch = true)
{
	if (iD != -1)   
	{
		if (!WeaponsHasAccessByType(client, iD)) 
		{
			return -1;
		}

		ItemDef iItem = WeaponsGetDefIndex(iD);
		switch (iItem)
		{
			case ItemDef_Defuser, ItemDef_Cutters : 
			{
				ToolsSetCustomID(client, iD); /// used for attachment model
				
				ToolsSetDefuser(client, true);
				
				return 0;
			}
			
			case ItemDef_HeavySuit :
			{
				ToolsSetHelmet(client, true);
				ToolsSetArmor(client, WeaponsGetClip(iD));
				ToolsSetHeavySuit(client, true);
				
				return 0;
			}
			
			 /// item_nvgs
			case ItemDef_NGVs :
			{
				ToolsSetNightVision(client, true, true);
				ToolsSetNightVision(client, true);
				
				return 0;
			}
					
			case ItemDef_Kevlar :
			{
				ToolsSetHelmet(client, false);
				ToolsSetArmor(client, WeaponsGetClip(iD));
				ToolsSetHeavySuit(client, false);
				
				return 0;
			}
				
			case ItemDef_KevlarHelmet :
			{
				ToolsSetHelmet(client, true);
				ToolsSetArmor(client, WeaponsGetClip(iD));
				ToolsSetHeavySuit(client, false);
				
				return 0;
			}

			default :
			{
				int weapon = -1; int iAmount = 1;

				if (IsGrenade(iItem))
				{
					iAmount = WeaponsGetAmmo(iD);
					if (!iAmount) iAmount++; /// If amount doens't exist, then increment it
				}

				for (int i = 0; i < iAmount; i++)
				{
					weapon = WeaponsCreate(iD);
					
					if (weapon != -1) 
					{
						WeaponsEquip(client, weapon, iD, bSwitch);
					}
				}

				return weapon;
			}
		}
	}

	return -1;
}

/**
 * @brief Create a custom weapon.
 *
 * @param iD                The weapon id.
 * @param vPosition         (Optional) The origin of the spawn.
 * @param vAngle            (Optional) The angle of the spawn.
 * @return                  The weapon index.
 **/
int WeaponsCreate(int iD, float vPosition[3] = {0.0, 0.0, 0.0}, float vAngle[3] = {0.0, 0.0, 0.0})
{
	int weapon = WeaponsSpawn(view_as<int>(WeaponsGetDefIndex(iD)), vPosition, vAngle);
	
	if (weapon != -1)
	{
		ToolsSetCustomID(weapon, iD);
		
		WeaponsSetSpawnedByMap(weapon, false);

		WeaponHDRSetDroppedModel(weapon, iD, ModelType_Drop);
		
		gForwardData._OnWeaponCreated(weapon, iD);
	}
	
	return weapon;
}

/**
 * @brief Spawn a weapon by a defindex.
 *
 * @param iItem             The def index.
 * @param vPosition         (Optional) The origin of the spawn.
 * @param vAngle            (Optional) The angle of the spawn.
 * @return                  The weapon index on success, or -1 on failure.
 **/
int WeaponsSpawn(int iItem, float vPosition[3] = {0.0, 0.0, 0.0}, float vAngle[3] = {0.0, 0.0, 0.0})
{
	int weapon = -1;
	
	if (hSDKCallSpawnItem)
	{
		weapon = (gServerData.Platform == OS_Windows) ? SDKCall(hSDKCallSpawnItem, iItem, vPosition, vAngle, 1, 4, 0) : SDKCall(hSDKCallSpawnItem, 0, iItem, vPosition, vAngle, 1, 4, 0);
		
		if (weapon == -1)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons", "Failed to create spawn item with def index (%d)", iItem);
		}
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "SDKCall Validation", "Failed to execute SDK call \"CItemGeneration::SpawnItem\". Update signature in \"%s\"", PLUGIN_CONFIG);


		CSWeaponID iD = CS_ItemDefIndexToID(iItem);
		if (iD != CSWeapon_NONE)
		{
			static char sClassname[SMALL_LINE_LENGTH];
			CS_WeaponIDToAlias(iD, sClassname, sizeof(sClassname));

			if ((weapon = CreateEntityByName(sClassname)) == -1)
			{
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons", "Failed to create \"%s\" entity with def index (%d)", sClassname, iItem);
				return weapon;
			}
			
			DispatchKeyValueVector(weapon, "origin", vPosition);
			DispatchKeyValueVector(weapon, "angles", vAngle);
			
			DispatchSpawn(weapon);
		}
		else
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons", "Failed to get weapon id from def index (%d)", iItem);
		}
	}
	
	return weapon;
}

/*
 * Stocks weapons API.
 */

/**
 * @brief Returns index if the player has a weapon.
 *
 * @param client            The client index.
 * @param sName             The weapon entity.
 * @return                  The weapon index.
 **/
int WeaponsFindByName(int client, char[] sName)
{
	static char sClassname[SMALL_LINE_LENGTH];

	int iSize = ToolsGetMyWeapons(client);
	for (int i = 0; i < iSize; i++)
	{
		int weapon = ToolsGetWeapon(client, i);

		if (weapon != -1)
		{
			GetEdictClassname(weapon, sClassname, sizeof(sClassname));

			if (!strcmp(sClassname[7], sName[7], false))
			{
				return weapon;
			}
		}
	}

	return -1;
}

/**
 * @brief Returns index if the player has a weapon.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 * @return                  The weapon index.
 **/
int WeaponsFindByID(int client, int iD)
{
	int iSize = ToolsGetMyWeapons(client);
	for (int i = 0; i < iSize; i++)
	{
		int weapon = ToolsGetWeapon(client, i);
		
		if (weapon != -1)
		{
			if (ToolsGetCustomID(weapon) == iD)
			{
				return weapon;
			}
		}
	}

	return -1;
}

/**
 * @brief Gets the slot type of a weapon.
 *
 * @param weapon            The weapon index.
 * @return                  The slot index.
 **/
SlotType WeaponsGetSlotType(int weapon)
{
	SlotType mSlot = hSDKCallGetSlot ? view_as<SlotType>(SDKCall(hSDKCallGetSlot, weapon)) : SlotType_Max;
	
	if (mSlot >= SlotType_Max)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "SDKCall Validation", "Failed to execute SDK call \"CBaseCombatWeapon::GetSlot\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		return SlotType_Primary;
	}
	
	return mSlot;
}

/**
 * @brief Gets the defenition index of a weapon.
 *
 * @param sClassname        The weapon entity.
 * @return                  The def index.
 **/
int WeaponsGetItemDefIndex(char[] sClassname)
{
	static Address pItemSchema;
	if (pItemSchema == Address_Null)
	{
		pItemSchema = (gServerData.Platform == OS_Linux) ? view_as<Address>(SDKCall(hSDKCallGetItemSchema)) : view_as<Address>(SDKCall(hSDKCallGetItemSchema) + 4);
	}
	
	if (!hasLength(sClassname))
	{
		return 0;
	}
	
	Address pItem = view_as<Address>(SDKCall(hSDKCallGetItemDefinitionByName, pItemSchema, sClassname));
	if (pItem == Address_Null)
	{
		return 0;
	}
	
	return LoadFromAddress(pItem + view_as<Address>(ItemDef_Index), NumberType_Int16);
}

/**
 * @brief Returns true if the player has an access by the class to the weapon id, false if not.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 * @return                  True or false.    
 **/
bool WeaponsHasAccessByType(int client, int iD)
{
	return ClassHasType(WeaponsGetTypes(iD), ClassGetType(gClientData[client].Class));
}

/**
 * @brief Returns true if the player has an access to use the weapon, false if not.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @return                  True or false.    
 **/
bool WeaponsCanUse(int client, int weapon)
{
	int iD = ToolsGetCustomID(weapon);
	if (iD != -1)
	{
		if (!WeaponsHasAccessByType(client, iD)) 
		{
			return false;
		}

		if (gCvarList.WEAPONS_PICKUP_LEVEL.BoolValue && gClientData[client].Level < WeaponsGetLevel(iD))
		{
			return false;
		}
		
		if (gCvarList.WEAPONS_PICKUP_ONLINE.BoolValue)
		{
			int iOnline = WeaponsGetOnline(iD);
			if (iOnline > 1 && fnGetPlaying() < iOnline)
			{
				return false;
			}
		}

		if (gCvarList.WEAPONS_PICKUP_GROUP.BoolValue)
		{
			static char sGroup[SMALL_LINE_LENGTH];
			WeaponsGetGroup(iD, sGroup, sizeof(sGroup))
		
			if (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup))
			{
				return false;
			}
		}
	}
	
	return true;
}

/**
 * @brief Returns true if the weapon has an access to spawn by a map, false if not.
 *
 * @param weapon            The weapon index.
 * @param sClassname        The weapon entity.
 * @return                  True or false.
 **/
bool WeaponsSpawnedByMap(int weapon, char[] sClassname)
{
	if (gServerData.Entities == null)
	{
		return false;
	}
	
	int iD = -1; gServerData.Entities.GetValue(sClassname, iD);
	if (iD == -1)
	{
		return false;
	}

	ToolsSetCustomID(weapon, iD);

	WeaponsSetSpawnedByMap(weapon, true);
	
	WeaponHDRSetDroppedModel(weapon, iD, ModelType_Drop);

	_exec.WeaponMODOnWeaponSpawnPost(weapon);
	
	return true; 
}