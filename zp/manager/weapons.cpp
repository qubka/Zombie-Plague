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
 * Validation of the knife weapon.
 **/
#define	WeaponsValidateKnife(%0) (%0 == CSWeapon_KNIFE || %0 == CSWeapon_KNIFE_GG)
 
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
	WEAPONS_DATA_MODEL_CLASS,
	WEAPONS_DATA_MODEL_VIEW,
	WEAPONS_DATA_MODEL_VIEW_ID,
	WEAPONS_DATA_MODEL_WORLD,
	WEAPONS_DATA_MODEL_WORLD_ID,
}

/**
 * Number of valid player slots.
 **/
enum
{ 
	WEAPON_SLOT_INVALID = -1, 		/** Used as return value when an weapon doens't exist. */
	
	WEAPON_SLOT_PRIMARY, 			/** Primary slot */
	WEAPON_SLOT_SECONDARY, 			/** Secondary slot */
	WEAPON_SLOT_MELEE, 				/** Melee slot */
	WEAPON_SLOT_EQUEPMENT			/** Equepment slot */
};

/**
 * Client is joining the server.
 * 
 * @param client    The client index.  
 */
void WeaponsClientInit(int clientIndex)
{
	// Hook weapon callbacks
	SDKHook(clientIndex, SDKHook_WeaponCanUse,     WeaponsOnCanUse);
	SDKHook(clientIndex, SDKHook_WeaponSwitchPost, WeaponsOnDeployPost);
	SDKHook(clientIndex, SDKHook_WeaponDropPost,   WeaponsOnDropPost);
	SDKHook(clientIndex, SDKHook_PostThinkPost,    WeaponsOnAnimationFix);
}

/**
 * Prepare all weapon data.
 **/
void WeaponsLoad(/*void*/)
{
	// Register config file
	ConfigRegisterConfig(File_Weapons, Structure_Keyvalue, CONFIG_FILE_ALIAS_WEAPONS);

	// Get weapons config path
	static char sPathWeapons[PLATFORM_MAX_PATH];
	bool bExists = ConfigGetCvarFilePath(CVAR_CONFIG_PATH_WEAPONS, sPathWeapons);

	// If file doesn't exist, then log and stop
	if(!bExists)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Missing weapons config file: %s", sPathWeapons);

		return;
	}

	// Set the path to the config file
	ConfigSetConfigPath(File_Weapons, sPathWeapons);

	// Load config from file and create array structure
	bool bSuccess = ConfigLoadConfig(File_Weapons, arrayWeapons);

	// Unexpected error, stop plugin
	if(!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error encountered loading: %s", sPathWeapons);
	}

	// Validate weapons config
	int iSize = GetArraySize(arrayWeapons);
	if(!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "No usable data found in weapons config file: %s", sPathWeapons);
	}

	// Now copy data to array structure
	WeaponsCacheData();

	// Set config data
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
	// Get config's file path.
	static char sPathWeapons[PLATFORM_MAX_PATH];
	ConfigGetConfigPath(File_Weapons, sPathWeapons, sizeof(sPathWeapons));

	Handle kvWeapons;
	bool bSuccess = ConfigOpenConfigFile(File_Weapons, kvWeapons);

	if(!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Unexpected error caching data from weapons config file: %s", sPathWeapons);
	}

	static char sWeaponName[SMALL_LINE_LENGTH];

	// i = array index
	int iSize = GetArraySize(arrayWeapons);
	for (int i = 0; i < iSize; i++)
	{
		WeaponsGetName(i, sWeaponName, sizeof(sWeaponName));
		KvRewind(kvWeapons);
		if(!KvJumpToKey(kvWeapons, sWeaponName))
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Couldn't cache weapon data for: %s (check weapons config)", sWeaponName);
			continue;
		}

		// Get config data
		static char sWeaponEntity[CONFIG_MAX_LENGTH];
		static char sWeaponModelClass[CONFIG_MAX_LENGTH];
		static char sWeaponModelView[PLATFORM_MAX_PATH];
		static char sWeaponModelWorld[PLATFORM_MAX_PATH];
		
		// General
		KvGetString(kvWeapons, "weaponentity", sWeaponEntity,     sizeof(sWeaponEntity));
		KvGetString(kvWeapons, "weaponclass",  sWeaponModelClass, sizeof(sWeaponModelClass));
		KvGetString(kvWeapons, "weaponview",   sWeaponModelView,  sizeof(sWeaponModelView));
		KvGetString(kvWeapons, "weaponworld",  sWeaponModelWorld, sizeof(sWeaponModelWorld));
		
		// Get array size
		Handle arrayWeapon = GetArrayCell(arrayWeapons, i);

		// Push data into array
		PushArrayString(arrayWeapon, sWeaponEntity);         						// Index: 1
		PushArrayCell(arrayWeapon, 	 KvGetNum(kvWeapons,   "weaponindex",  0));		// Index: 2
		PushArrayCell(arrayWeapon, 	 KvGetNum(kvWeapons,   "weaponcost",   0));     // Index: 3
		PushArrayCell(arrayWeapon,   KvGetNum(kvWeapons,   "weaponslot",   0));   	// Index: 4
		PushArrayCell(arrayWeapon,   KvGetNum(kvWeapons,   "weaponlvl",    0));   	// Index: 5
		PushArrayCell(arrayWeapon,   KvGetNum(kvWeapons,   "weapononline", 0));   	// Index: 6
		PushArrayCell(arrayWeapon,   KvGetFloat(kvWeapons, "weapondamage", 1.0));   // Index: 7
		PushArrayCell(arrayWeapon,   KvGetFloat(kvWeapons, "weaponknock",  1.0));   // Index: 8
		PushArrayString(arrayWeapon, sWeaponModelClass);    						// Index: 9
		PushArrayString(arrayWeapon, sWeaponModelView);								// Index: 10	
		PushArrayCell(arrayWeapon,   ModelsViewPrecache(sWeaponModelView));     	// Index: 11
		PushArrayString(arrayWeapon, sWeaponModelWorld);							// Index: 12
		PushArrayCell(arrayWeapon,   ModelsViewPrecache(sWeaponModelWorld));    	// Index: 13

		// Gets a alias from a weapon entity
		ReplaceString(sWeaponEntity, sizeof(sWeaponEntity), "weapon_", "");

		// Convert weapon alias to ID
		CSWeaponID weaponID = CS_AliasToWeaponID(sWeaponEntity);

		// If weapon alias invalid, then remove, log, and stop
		if(!CS_IsValidWeaponID(weaponID))
		{
			// Remove weapon from array
			RemoveFromArray(arrayWeapons, i);

			// Subtract one from count
			iSize--;

			// Backtrack one index, because we deleted it out from under the loop
			i--;

			// Log error
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Invalid weapon alias \"%s\"", sWeaponEntity);
			continue;
		}
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

/*
 * Weapons natives API.
 */
 
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
 * Gets the name of a weapon at a given index.
 *
 * native void ZP_GetWeaponName(iD, name, maxlen);
 **/
public int API_GetWeaponName(Handle isPlugin, int iNumParams)
{
	// Get weapon index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayWeapons))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize name char
	static char sName[NORMAL_LINE_LENGTH];
	WeaponsGetName(iD, sName, sizeof(sName));

	// Return on success
	return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the entity of a weapon at a given index.
 *
 * native void ZP_GetWeaponEntity(iD, entity, maxlen);
 **/
public int API_GetWeaponEntity(Handle isPlugin, int iNumParams)
{
	// Get weapon index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayWeapons))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize entity char
	static char sEntity[NORMAL_LINE_LENGTH];
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
	// Get weapon index from native cell
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
	// Get weapon index from native cell
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
	// Get weapon index from native cell
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
	// Get weapon index from native cell
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
	// Get weapon index from native cell
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
	// Get weapon index from native cell
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
	// Get weapon index from native cell
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
 * Gets the models' class access of a weapon at a given index.
 *
 * native void ZP_GetWeaponModelClass(iD, class, maxlen);
 **/
public int API_GetWeaponModelClass(Handle isPlugin, int iNumParams)
{
	// Get weapon index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayWeapons))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize name char
	static char sClass[NORMAL_LINE_LENGTH];
	WeaponsGetModelClass(iD, sClass, sizeof(sClass));

	// Return on success
	return SetNativeString(2, sClass, maxLen);
}

/**
 * Gets the view model path a weapon at a given index.
 *
 * native void ZP_GetWeaponModelView(iD, model, maxlen);
 **/
public int API_GetWeaponModelView(Handle isPlugin, int iNumParams)
{
	// Get weapon index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayWeapons))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize model char
	static char sEntity[NORMAL_LINE_LENGTH];
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
	// Get weapon index from native cell
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
 * Gets the world model path a weapon at a given index.
 *
 * native void ZP_GetWeaponModelWorld(iD, model, maxlen);
 **/
public int API_GetWeaponModelWorld(Handle isPlugin, int iNumParams)
{
	// Get weapon index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayWeapons))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Invalid the weapon index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize model char
	static char sEntity[NORMAL_LINE_LENGTH];
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
	// Get weapon index from native cell
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

/*
 * Weapons data reading API.
 */

/**
 * Gets the name of a weapon at a given index.
 *
 * @param iD				The weapon index.
 * @param sClassname		The string to return name in.
 * @param iMaxLen			The max length of the string.
 **/
stock void WeaponsGetName(int iD, char[] sClassname, int iMaxLen)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon name
    GetArrayString(arrayWeapon, WEAPONS_DATA_NAME, sClassname, iMaxLen);
}

/**
 * Gets the entity of a weapon at a given index.
 *
 * @param iD				The weapon index.
 * @param sType				The string to return entity in.
 * @param iMaxLen			The max length of the string.
 **/
stock void WeaponsGetEntity(int iD, char[] sType, int iMaxLen)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon type
    GetArrayString(arrayWeapon, WEAPONS_DATA_ENTITY, sType, iMaxLen);
}

/**
 * Gets the definition index of the weapon.
 *
 * @param iD				The weapon index.
 * @return					The definition index. (m_iItemDefinitionIndex)
 **/
stock int WeaponsGetIndex(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon definition index
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_INDEX);
}

/**
 * Gets the cost of the weapon.
 *
 * @param iD				The weapon index.
 * @return					The cost amount.
 **/
stock int WeaponsGetCost(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon cost
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_COST);
}

/**
 * Gets the slot of the weapon.
 *
 * @param iD				The weapon index.
 * @return					The weapon slot.	
 **/
stock int WeaponsGetSlot(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon slot
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_SLOT);
}

/**
 * Gets the level of the weapon.
 *
 * @param iD				The weapon index.
 * @return					The level amount.	
 **/
stock int WeaponsGetLevel(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon level
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_LEVEL);
}

/**
 * Gets the online of the weapon.
 *
 * @param iD				The weapon index.
 * @return					The online amount.
 **/
stock int WeaponsGetOnline(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon online
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_ONLINE);
}

/**
 * Gets the damage of the weapon.
 *
 * @param iD				The weapon index.
 * @return					The damage amount.	
 **/
stock float WeaponsGetDamage(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon damage
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_DAMAGE);
}

/**
 * Gets the knockback of the weapon.
 *
 * @param iD				The weapon index.
 * @return					The knockback amount.	
 **/
stock float WeaponsGetKnockBack(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon knockback
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_KNOCKBACK);
}

/**
 * Gets the models' class access of a weapon at a given index.
 *
 * @param iD				The weapon index.
 * @param sType				The string to return entity in.
 * @param iMaxLen			The max length of the string.
 **/
stock void WeaponsGetModelClass(int iD, char[] sType, int iMaxLen)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon class's access
    GetArrayString(arrayWeapon, WEAPONS_DATA_MODEL_CLASS, sType, iMaxLen);
}

/**
 * Gets the path of a weapon view model at a given index.
 *
 * @param iD				The weapon index.
 * @param sModel			The string to return model in.
 * @param iMaxLen			The max length of the string.
 **/
stock void WeaponsGetModelView(int iD, char[] sModel, int iMaxLen)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon type
    GetArrayString(arrayWeapon, WEAPONS_DATA_MODEL_VIEW, sModel, iMaxLen);
}

/**
 * Gets the index of the weapon view model.
 *
 * @param iD				The weapon index.
 * @return					The model index.
 **/
stock int WeaponsGetModelViewID(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon view model
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_MODEL_VIEW_ID);
}

/**
 * Gets the path of a weapon world model at a given index.
 *
 * @param iD				The weapon index.
 * @param sModel			The string to return model in.
 * @param iMaxLen			The max length of the string.
 **/
stock void WeaponsGetModelWorld(int iD, char[] sModel, int iMaxLen)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon type
    GetArrayString(arrayWeapon, WEAPONS_DATA_MODEL_WORLD, sModel, iMaxLen);
}

/**
 * Gets the index of the weapon world model.
 *
 * @param iD				The weapon index.
 * @return					The model index.
 **/
stock int WeaponsGetModelWorldID(int iD)
{
    // Get array handle of weapon at given index
    Handle arrayWeapon = GetArrayCell(arrayWeapons, iD);
    
    // Get weapon world model
    return GetArrayCell(arrayWeapon, WEAPONS_DATA_MODEL_WORLD_ID);
}

/*
 * Main weapons hooks
 */

/**
 * Called, when an entity is created
 *
 * @param entityIndex	 	The entity index.
 * @param sClassname    	The string with returned name.
 **/
public void OnEntityCreated(int entityIndex, const char[] sClassname)
{
	// Validate classname
	if(StrContains(sClassname, "projectile") != -1)
	{
		// Hook weapon callbacks
		SDKHook(entityIndex, SDKHook_SpawnPost, WeaponsOnSpawnPost);
	}
}

/**
 * Hook: WeaponSpawnPost
 * Weapon is spawn.
 *
 * @param weaponIndex    	The weapon index.
 **/
public void WeaponsOnSpawnPost(int weaponIndex) 
{
	// Apply drop hook on the next frame
	RequestFrame(view_as<RequestFrameCallback>(WeaponsOnFakeDropPost), weaponIndex);
}

/**
 * Hook: WeaponFakeDropPost
 * Player throw any grenade.
 *
 * @param weaponIndex    	The weapon index.
 **/
public void WeaponsOnFakeDropPost(any weaponIndex) 
{
	//*********************************************************************
	//*                     VALIDATION OF THE WEAPON           		  	  *
	//*********************************************************************
	
	// If weapon isn't valid, then stop
	if(!IsValidEdict(weaponIndex))
	{
		return;
	}
	
	// Call the fake drop hook 
	WeaponsOnDropPost(GetEntPropEnt(weaponIndex, Prop_Data, "m_hThrower"), weaponIndex);
}

/**
 * Hook: WeaponSwitchPost
 * Player deploy any weapon.
 *
 * @param clientIndex	 	The client index.
 * @param weaponIndex    	The weapon index.
 **/
public void WeaponsOnDeployPost(int clientIndex, int weaponIndex) 
{
	//*********************************************************************
	//*                     VALIDATION OF THE WEAPON           		  	  *
	//*********************************************************************
	
	// If custom weapons models disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_GAME_CUSTOM_MODELS]))
	{
		return;
	}
	
	// Convert weapon index to ID
	CSWeaponID weaponID = WeaponsGetID(weaponIndex);
	
	// If weapon isn't valid, then stop
	if(!CS_IsValidWeaponID(weaponID))
	{
		return;
	}
	
	//*********************************************************************
	//*                     VALIDATION OF THE PLAYER           		  	  *
	//*********************************************************************
	
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return;
	}
	
	//*********************************************************************
	//*                APPLYMENTATION OF THE WEAPON MODELS           	  *
	//*********************************************************************
	
	// Apply weapon models by active weapon
	int iIndex = WeaponsGetWeaponIndex(weaponIndex);
	if(iIndex != -1)
	{
		// Initialize class list
		static char sClassList[SMALL_LINE_LENGTH];
		WeaponsGetModelClass(iIndex, sClassList, sizeof(sClassList));
		
		// Validate player's class access to the weapon's models
		if(WeaponsValidateClass(cBasePlayer->Index, sClassList))
		{
			// If view model exist, then apply it
			if(WeaponsGetModelViewID(iIndex)) 
			{
				WeaponsSetClientViewModel(cBasePlayer->Index, weaponIndex, (cBasePlayer->m_bZombie && !cBasePlayer->m_bNemesis && WeaponsValidateKnife(weaponID)) ? ZombieGetClawIndex(cBasePlayer->m_nZombieClass) : WeaponsGetModelViewID(iIndex));
			}
		
			// If world model exist, then apply it
			if(WeaponsGetModelWorldID(iIndex))
			{
				WeaponsSetClientWorldModel(weaponIndex, WeaponsGetModelWorldID(iIndex));
			}
			
			// Verify that the client is human
			if(!cBasePlayer->m_bZombie)
			{
				// Get human's arm model
				static char sArm[PLATFORM_MAX_PATH];
				HumanGetArmModel(cBasePlayer->m_nHumanClass, sArm, sizeof(sArm));
				
				// Apply arm model
				cBasePlayer->m_ModelName(_, sArm);
			}
		}
	}
} 

/**
 * Hook: WeaponCanUse
 * Player deploy or pick-up any weapon.
 *
 * @param clientIndex	 	The client index.
 * @param weaponIndex    	The weapon index.
 **/
public Action WeaponsOnCanUse(int clientIndex, int weaponIndex)
{
	//*********************************************************************
	//*                     VALIDATION OF THE WEAPON           		  	  *
	//*********************************************************************
	
	// Convert weapon index to ID
	CSWeaponID weaponID = WeaponsGetID(weaponIndex);
	
	// If weapon isn't valid, then stop
	if(!CS_IsValidWeaponID(weaponID))
	{
		return ACTION_HANDLED;
	}
	
	// If weapon is accessable, then allow
	if(WeaponsValidateAccess(weaponID))
	{
		return ACTION_CONTINUE;
	}
	
	//*********************************************************************
	//*                     VALIDATION OF THE PLAYER           		  	  *
	//*********************************************************************
	
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return ACTION_HANDLED;
	}

	// Block pickup anything, ifyou a zombie
	if(cBasePlayer->m_bZombie)
	{
		return ACTION_HANDLED;
	}
	
	//*********************************************************************
	//*                     VALIDATION OF THE LEVEL           		  	  *
	//*********************************************************************
	
	// Apply client access and knockback multiplier by active weapon
	int iIndex = WeaponsGetWeaponIndex(weaponIndex);
	if(iIndex != -1)
	{
		// Block pickup it, iflevel too low
		if(!cBasePlayer->m_bSurvivor && cBasePlayer->m_iLevel < WeaponsGetLevel(iIndex))
		{
			return ACTION_HANDLED;
		}
	}
	
	// Allow pickup
	return ACTION_CONTINUE;
}

/**
 * Hook: WeaponDropPost
 * Player drop any weapon.
 *
 * @param clientIndex	 	The client index.
 * @param weaponIndex    	The weapon index.
 **/
public Action WeaponsOnDropPost(int clientIndex, int weaponIndex) 
{
	//*********************************************************************
	//*                     VALIDATION OF THE WEAPON           		  	  *
	//*********************************************************************
	
	// If weapon isn't valid, then stop
	if(!IsValidEdict(weaponIndex))
	{
		return ACTION_HANDLED;
	}
	
	//*********************************************************************
	//*                     VALIDATION OF THE PLAYER           		  	  *
	//*********************************************************************
	
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return ACTION_HANDLED;
	}
	
	//*********************************************************************
	//*                APPLYMENTATION OF THE WEAPON MODELS           	  *
	//*********************************************************************
	
	// Apply weapon models by dropped weapon
	int iIndex = WeaponsGetWeaponIndex(weaponIndex);
	if(iIndex != -1)
	{
		// Initialize class list
		static char sClassList[SMALL_LINE_LENGTH];
		WeaponsGetModelClass(iIndex, sClassList, sizeof(sClassList));
		
		// Validate player's class access to the weapon's models
		if(WeaponsValidateClass(cBasePlayer->Index, sClassList))
		{
			// If world model exist, then apply it
			if(WeaponsGetModelWorldID(iIndex))
			{
				// Get weapon's world model
				static char sModel[PLATFORM_MAX_PATH];
				WeaponsGetModelWorld(iIndex, sModel, sizeof(sModel));

				// Send data to the next frame
				DataPack hPack = CreateDataPack();
				WritePackString(hPack, sModel);
				WritePackCell(hPack, weaponIndex);
				
				// Apply dropped model on the next frame
				RequestFrame(view_as<RequestFrameCallback>(WeaponsSetWorldModel), hPack);
			}
		}
	}
	
	// Allow drop
	return ACTION_CONTINUE;
}

/**
 * Hook: PostThinkPost
 * Player hold any weapon.
 *
 * @param clientIndex	 	The client index.
 **/
public Action WeaponsOnAnimationFix(int clientIndex) 
{
	//*********************************************************************
	//*                     VALIDATION OF THE PLAYER           		  	  *
	//*********************************************************************
	
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return;
	}
	
	//*********************************************************************
	//*                     VALIDATION OF THE WEAPON           		  	  *
	//*********************************************************************

	// Convert weapon index to ID
	CSWeaponID weaponID = WeaponsGetID(cBasePlayer->m_iActiveWeapon);
	
	// If weapon isn't valid, then stop
	if(!CS_IsValidWeaponID(weaponID))
	{
		return;
	}
	
	//*********************************************************************
	//*                APPLYMENTATION OF THE ANIMATIONS           	  	  *
	//*********************************************************************
	
	// Get view index
	int viewIndex = GetEntPropEnt(cBasePlayer->Index, Prop_Send, "m_hViewModel");
	
	// If weapon isn't valid, then stop
	if(IsValidEdict(viewIndex))
	{
		// Initialize variable
		static int nOldSequence[MAXPLAYERS+1]; static float flOldCycle[MAXPLAYERS+1];
		
		// Get the sequence number and it's playing time
		int nSequence = GetEntProp(viewIndex, Prop_Send, "m_nSequence");
		float flCycle = GetEntPropFloat(viewIndex, Prop_Data, "m_flCycle");
		
		// Validate a knife
		if(WeaponsValidateKnife(weaponID))
		{
			// Validate animation delay
			if(nSequence == nOldSequence[cBasePlayer->Index] && flCycle < flOldCycle[cBasePlayer->Index])
			{
				switch (nSequence)
				{
					case 3 : SetEntProp(viewIndex, Prop_Send, "m_nSequence", 4);
					case 4 : SetEntProp(viewIndex, Prop_Send, "m_nSequence", 3);
					case 5 : SetEntProp(viewIndex, Prop_Send, "m_nSequence", 6);
					case 6 : SetEntProp(viewIndex, Prop_Send, "m_nSequence", 5);
					case 7 : SetEntProp(viewIndex, Prop_Send, "m_nSequence", 8);
					case 8 : SetEntProp(viewIndex, Prop_Send, "m_nSequence", 7);
					case 9 : SetEntProp(viewIndex, Prop_Send, "m_nSequence", 10);
					case 10: SetEntProp(viewIndex, Prop_Send, "m_nSequence", 11); 
					case 11: SetEntProp(viewIndex, Prop_Send, "m_nSequence", 10);
				}
			}
		}
		else
		{
			// Initialize variable
			static int nPrevSequence[MAXPLAYERS+1]; static float flDelay[MAXPLAYERS+1];

			// Returns the game time based on the game tick
			float flCurrentTime = GetEngineTime();
			
			// Play previous animation
			if(nPrevSequence[cBasePlayer->Index] != 0 && flDelay[cBasePlayer->Index] < flCurrentTime)
			{
				SetEntProp(viewIndex, Prop_Send, "m_nSequence", nPrevSequence[cBasePlayer->Index]);
				nPrevSequence[cBasePlayer->Index] = 0;
			}
			
			// Validate animation delay
			if(flCycle < flOldCycle[cBasePlayer->Index])
			{
				// Validate animation
				if(nSequence == nOldSequence[cBasePlayer->Index])
				{
					SetEntProp(viewIndex, Prop_Send, "m_nSequence", 0);
					nPrevSequence[cBasePlayer->Index] = nSequence;
					flDelay[cBasePlayer->Index] = flCurrentTime + 0.03;
				}
			}
		}
		
		// Update the animation interval delay
		nOldSequence[cBasePlayer->Index] = nSequence;
		flOldCycle[cBasePlayer->Index] = flCycle;
	}
}

/**
 * Hook: WeaponOnFire
 * Weapon has been fired.
 *
 * @param clientIndex	 	The client index.
 * @param weaponIndex    	The weapon index.
 **/
void WeaponsOnFire(int clientIndex, int weaponIndex) 
{ 
	// Get real player index from event key
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);
	
	// Convert weapon index to ID
	CSWeaponID weaponID = WeaponsGetID(weaponIndex);
	
	// If weapon isn't valid, then stop
	if(!CS_IsValidWeaponID(weaponID))
	{
		return;
	}

	// Verify that the client is zombie
	if(cBasePlayer->m_bZombie) 
	{
		// Emit a custom attack sound
		if(WeaponsValidateKnife(weaponID)) cBasePlayer->InputEmitAISound(SNDCHAN_VOICE, SNDLEVEL_LIBRARY, (ZombieIsFemale(cBasePlayer->m_nZombieClass)) ? "ZOMBIE_FEMALE_ATTACK_SOUNDS" : "ZOMBIE_ATTACK_SOUNDS");
	}
	else
	{
		// If weapon is taser, then stop
		if(weaponID == CSWeapon_TASER)
		{
			return;
		}
		
		// If weapon isn't valid, then stop
		if(!IsValidEdict(weaponIndex))
		{
			return;
		}
		
		// Validate current ammunition mode
		switch(cBasePlayer->m_bSurvivor ? GetConVarInt(gCvarList[CVAR_SURVIVOR_INF_AMMO]) : GetConVarInt(gCvarList[CVAR_HUMAN_INF_AMMO]))
		{
			case 0 : return;
			case 1 : SetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", 200);
			case 2 : SetEntProp(weaponIndex, Prop_Data, "m_iClip1", GetEntProp(weaponIndex, Prop_Data, "m_iClip1") + 1);
		}
	}
}  

/*
 * Stock weapons API.
 */
 
/**
 * Returns true ifthe player has a class access for a deployed weapon, false ifnot.
 *
 * @param clientIndex		The client index.
 * @param sClassList		The string with classes.
 *
 * @return					True or false.	
 **/
stock bool WeaponsValidateClass(int clientIndex, char[] sClassList)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);
	
	bool bSuccess = false;
	
	// Check iflist is empty, then skip
	if(strlen(sClassList))
	{
		// Convert list string to pieces
		static char sType[4][SMALL_LINE_LENGTH];
		int nPieces = ExplodeString(sClassList, ",", sType, sizeof(sType), sizeof(sType[]));
		
		// Loop throught pieces
		for(int i = 0; i < nPieces; i++)
		{
			// Trim string
			TrimString(sType[i]);
			
			// Switch type with the current class
			switch(sType[i][0])
			{
				case 'z' : if(cBasePlayer->m_bZombie)		bSuccess = true;	
				case 'n' : if(cBasePlayer->m_bNemesis)  	bSuccess = true;	
				case 's' : if(cBasePlayer->m_bSurvivor) 	bSuccess = true;	
				case 'h' : if(!cBasePlayer->m_bZombie)	 	bSuccess = true;					
			}	
		}
		
	}
	else bSuccess = true;
	
	// Return on success
	return bSuccess;
}

/**
 * Returns true ifthe player has access to the weapon, false ifnot.
 *
 * @param weaponID			The weapon id.
 *
 * @return					True or false.	
 **/
stock bool WeaponsValidateAccess(CSWeaponID weaponID)
{
	// Allow client to pickup a knife, then stop
	if(WeaponsValidateKnife(weaponID))
	{
		return true;
	}

	// Initialize grenade list
	static char sGrenadeList[NORMAL_LINE_LENGTH];
	GetConVarString(gCvarList[CVAR_ZOMBIE_GRENADES], sGrenadeList, sizeof(sGrenadeList));
	
	// Check ifstring is empty, then skip
	if(strlen(sGrenadeList))
	{
		// Convert list string to pieces
		static char sType[6][SMALL_LINE_LENGTH];
		int  nPieces = ExplodeString(sGrenadeList, ",", sType, sizeof(sType), sizeof(sType[]));
		
		// Loop throught pieces
		for(int i = 0; i < nPieces; i++)
		{
			// Trim string
			TrimString(sType[i]);
			
			// Switch type with the current weapon
			switch(sType[i][0])
			{
				case 'i' : if(weaponID == CSWeapon_INCGRENADE)		return true;
				case 'd' : if(weaponID == CSWeapon_DECOY)			return true;
				case 'm' : if(weaponID == CSWeapon_MOLOTOV)			return true;
				case 'f' : if(weaponID == CSWeapon_FLASHBANG)		return true;
				case 's' : if(weaponID == CSWeapon_SMOKEGRENADE)	return true;
				case 'h' : if(weaponID == CSWeapon_HEGRENADE)		return true;
			}	
		}
	}

	// If wasn't found, then stop
	return false;
}

/**
 * Find the weapon's array index.
 * 
 * @param weaponIndex		The weapon index. 
 *
 * @return					The array index containing the given weapon.
 **/
stock int WeaponsGetWeaponIndex(int weaponIndex)
{
	// Check ifweapon is valid, then skip
	if(IsValidEdict(weaponIndex))
	{
		// Get client weapon's classname
		static char sWeapon[NORMAL_LINE_LENGTH];
		GetEntityClassname(weaponIndex, sWeapon, sizeof(sWeapon));

		// Initialize definition's index
		int itemIndex = -1;

		// If is projectile, then convert to the weapon's classname
		if(StrContains(sWeapon, "projectile") != -1)
		{
			Format(sWeapon, sizeof(sWeapon), "weapon_%s", sWeapon);
			ReplaceString(sWeapon, sizeof(sWeapon), "_projectile", "");
		}
		else
		{
			// Get weapon definition's index
			itemIndex = GetEntProp(weaponIndex, Prop_Send, "m_iItemDefinitionIndex");
		}
		
		// i = Array index
		int iSize = GetArraySize(arrayWeapons);
		for (int i = 0; i < iSize; i++)
		{
			// Validate classname validation
			if(!WeaponsGetIndex(i))
			{
				// Gets the entity of a weapon at a given index
				static char sClassname[SMALL_LINE_LENGTH];
				WeaponsGetEntity(i, sClassname, sizeof(sClassname));

				// If names match, then return index
				if(StrEqual(sWeapon, sClassname, false))
				{
					return i;
				}
			}
			
			// If definition index match, then return index
			else if(itemIndex == WeaponsGetIndex(i))
			{
				return i;
			}
		}
	}
	
	// Weapon doesn't exist, then stop
	return -1;
}

/**
 * Takes a weapon's entity index and returns weapon ID.
 *
 * @param weaponIndex		The weapon index.
 * 
 * @return					The weapon id.	
 **/
stock CSWeaponID WeaponsGetID(int weaponIndex)
{
	// If weapon isn't valid, then stop
	if(!IsValidEdict(weaponIndex))
	{
		return CSWeapon_NONE;
	}
	
	// Initialize char
	static char sClassname[SMALL_LINE_LENGTH];
	
	// Get weapon classname and convert it to alias
	GetEntityClassname(weaponIndex, sClassname, sizeof(sClassname));
	ReplaceString(sClassname, sizeof(sClassname), "weapon_", "");
	
	// Convert weapon alias to ID
	return CS_AliasToWeaponID(sClassname);
}

/**
 * Sets the view weapon's model.
 *
 * @param clientIndex		The client index.
 * @param weaponIndex		The weapon index.
 * @param modelIndex		The model index. (Must be precached)
 **/
stock void WeaponsSetClientViewModel(int clientIndex, int weaponIndex, int modelIndex)
{
	// Get view index
	int viewIndex = GetEntPropEnt(clientIndex, Prop_Send, "m_hViewModel");

	// Verify that the entity is valid
	if(IsValidEdict(viewIndex))
	{
		// Delete default model index
		SetEntProp(weaponIndex, Prop_Send, "m_nModelIndex", 0);
		
		// Set new view model index for the weapon
		SetEntProp(viewIndex, Prop_Send, "m_nModelIndex", modelIndex);
	}
}

/**
 * Sets the world (player) weapon's model.
 *
 * @param weaponIndex		The weapon index.
 * @param modelIndex		The model index. (Must be precached)
 **/
stock void WeaponsSetClientWorldModel(int weaponIndex, int modelIndex)
{
	// Get world index
	int worldIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");
	
	// Verify that the entity is valid
	if(IsValidEdict(worldIndex))
	{
		// Set model for the entity
		SetEntProp(worldIndex, Prop_Send, "m_nModelIndex", modelIndex);
	}
}

/**
 * Sets the world (dropped) weapon's model.
 *
 * @param hPack				The data pack.
 **/
public void WeaponsSetWorldModel(any hPack)
{
	// Resets the position in the datapack
	ResetPack(hPack);

	// Get the world model from the datapack
	static char sModel[PLATFORM_MAX_PATH];
	ReadPackString(hPack, sModel, sizeof(sModel));

	// Get the weapon index from the datapack
	int weaponIndex = ReadPackCell(hPack);
	
	// Verify that the entity is valid
	if(IsValidEdict(weaponIndex))
	{
		// Set dropped model for the entity
		SetEntityModel(weaponIndex, sModel);
	}
	
	// Close the datapack
	CloseHandle(hPack);
}