/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          hitgroup.sp
 *  Type:          Manager 
 *  Description:   API for loading hitgroup specific settings.
 *
 *  Copyright (C) 2015-2023 Greyscale, Richard Helgeby
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
	HITGROUPS_DATA_SHIELD,
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
	if (gServerData.MapLoaded)
	{
		// i = client index
		for (int i = 1; i <= MaxClients; i++)
		{
			// Validate client
			if (IsPlayerExist(i, false))
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
	ConfigRegisterConfig(File_HitGroups, Structure_KeyValue, CONFIG_FILE_ALIAS_HITGROUPS);

	// If hitgroups is disabled, then stop
	if (!gCvarList.HITGROUP.BoolValue)
	{
		return;
	}

	// Gets hitgroups config path
	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_HITGROUPS, sBuffer, sizeof(sBuffer));

	// If file doesn't exist, then log and stop
	if (!bExists)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Missing hitgroups config file: %s", sBuffer);
		return;
	}

	// Sets path to the config file
	ConfigSetConfigPath(File_HitGroups, sBuffer);

	// Load config from file and create array structure
	bool bSuccess = ConfigLoadConfig(File_HitGroups, gServerData.HitGroups);

	// Unexpected error, stop plugin
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Unexpected error encountered loading: %s", sBuffer);
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
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_HitGroups, sBuffer, sizeof(sBuffer)); 
	
	// Opens config
	KeyValues kvHitGroups;
	bool bSuccess = ConfigOpenConfigFile(File_HitGroups, kvHitGroups);
	
	// Validate config
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Unexpected error caching data from hitgroups config file: %s", sBuffer);
		return;
	}
	
	// Validate size
	int iSize = gServerData.HitGroups.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "No usable data found in hitgroups config file: %s", sBuffer);
		return;
	}

	// i = array index
	for (int i = 0; i < iSize; i++)
	{
		// General
		HitGroupsGetName(i, sBuffer, sizeof(sBuffer)); // Index: 0
		kvHitGroups.Rewind();
		if (!kvHitGroups.JumpToKey(sBuffer))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Couldn't cache hitgroup data for: %s (check hitgroup config)", sBuffer);
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
		arrayHitGroup.Push(kvHitGroups.GetFloat("shield", 0.5));                  // Index: 7
		arrayHitGroup.Push(ConfigKvGetStringBool(kvHitGroups, "protect", "yes")); // Index: 8
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
	gCvarList.HITGROUP                  = FindConVar("zp_hitgroup"); 
	gCvarList.HITGROUP_KNOCKBACK        = FindConVar("zp_knockback"); 
	gCvarList.HITGROUP_KNOCKBACK_AIR    = FindConVar("zp_knockback_air"); 
	gCvarList.HITGROUP_KNOCKBACK_CROUCH = FindConVar("zp_knockback_crouch"); 
	gCvarList.HITGROUP_FRIENDLY_FIRE    = FindConVar("mp_friendlyfire");
	gCvarList.HITGROUP_FRIENDLY_GRENADE = FindConVar("ff_damage_reduction_grenade");
	gCvarList.HITGROUP_FRIENDLY_BULLETS = FindConVar("ff_damage_reduction_bullets");
	gCvarList.HITGROUP_FRIENDLY_OTHER   = FindConVar("ff_damage_reduction_other");
	gCvarList.HITGROUP_FRIENDLY_SELF    = FindConVar("ff_damage_reduction_grenade_self");
	
	// Sets locked cvars to their locked value
	gCvarList.HITGROUP_FRIENDLY_FIRE.IntValue          = 0;
	CvarsOnCheatSet(gCvarList.HITGROUP_FRIENDLY_GRENADE, 0);
	CvarsOnCheatSet(gCvarList.HITGROUP_FRIENDLY_BULLETS, 0);
	CvarsOnCheatSet(gCvarList.HITGROUP_FRIENDLY_OTHER,   0);
	CvarsOnCheatSet(gCvarList.HITGROUP_FRIENDLY_SELF,    0);

	// Hook locked cvars to prevent it from changing
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_FIRE,    CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_GRENADE, CvarsLockOnCvarHook2);
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_BULLETS, CvarsLockOnCvarHook2);
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_OTHER,   CvarsLockOnCvarHook2);
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_SELF,    CvarsLockOnCvarHook2);
	
	// Hook cvars
	HookConVarChange(gCvarList.HITGROUP, HitGroupsOnCvarHook);
	HookConVarChange(gCvarList.GAMEMODE, HitGroupsOnCvarHook);
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void HitGroupsOnClientInit(int client)
{
	// If gamemodes is disabled, then unhook
	int iDamage = gCvarList.GAMEMODE.IntValue;
	if (!iDamage)
	{
		// Unhook entity callbacks
		SDKUnhook(client, SDKHook_TraceAttack,  HitGroupsOnTraceAttack);
		SDKUnhook(client, SDKHook_OnTakeDamage, HitGroupsOnTakeDamage);
		return;
	}
	
	// Hook entity callbacks
	SDKHook(client, SDKHook_TraceAttack,  HitGroupsOnTraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, HitGroupsOnTakeDamage); 
}

/**
 * @brief Called when a entity is created.
 *
 * @param entity            The entity index.
 * @param sClassname        The string with returned name.
 **/
void HitGroupsOnEntityCreated(int entity, const char[] sClassname)
{
	// Validate entity
	if (entity > -1 && !strcmp(sClassname[6], "hurt", false))
	{
		// Hook entity callbacks
		SDKHook(entity, SDKHook_SpawnPost, HitGroupsOnHurtSpawn);
	}
}

/**
 * Cvar hook callback (zp_hitgroup, zp_gamemode)
 * @brief Hit groups module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void HitGroupsOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	// Forward event to modules
	HitGroupsOnInit();
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void HitGroupsOnClientUpdate(int client)
{
	// Resets damage counters
	gClientData[client].AppliedDamage[0] = 0;
	gClientData[client].AppliedDamage[1] = 0;
}

/*
 * Hit groups main functions.
 */

/**
 * Hook: OnTraceAttack
 * @brief Called right before the bullet enters a client.
 * 
 * @param client            The victim index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The type of damage inflicted.
 * @param iAmmo             The ammo type of the attacker weapon.
 * @param iHitBox           The hitbox index.  
 * @param iHitGroup         The hitgroup index.  
 **/
public Action HitGroupsOnTraceAttack(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &iAmmo, int iHitBox, int iHitGroup)
{
	// If mode doesn't started yet, then stop
	if (!gServerData.RoundStart)
	{
		// Stop trace
		return Plugin_Handled;
	}
	
	// Validate victim/attacker
	if (IsPlayerAlive(client) && IsPlayerExist(attacker))
	{
		// Validate team
		if (ToolsGetTeam(client) == ToolsGetTeam(attacker))
		{
			// Stop trace
			return Plugin_Handled;
		}
	}

	// If custom hitgroups enabled, then apply multipliers
	if (gCvarList.HITGROUP.BoolValue)
	{
		// Validate hitgroup index
		int iHitIndex = HitGroupToIndex(iHitGroup);
		if (iHitIndex != -1)
		{
			// Validate damage
			if (!HitGroupsIsDamage(iHitIndex))
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
 * @param client            The victim index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The type of damage inflicted.
 * @param weapon            The weapon index or -1 for unspecified.
 * @param damageForce       The velocity of damage force.
 * @param damagePosition    The origin of damage.
 **/
public Action HitGroupsOnTakeDamage(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &weapon, float damageForce[3], float damagePosition[3]/*, int damagecustom*/)
{
	// Initialize name char
	static char sClassname[SMALL_LINE_LENGTH]; sClassname[0] = NULL_STRING[0];
	
	// Validate inflicter
	if (IsValidEdict(inflictor))
	{
		// Gets classname of the inflicter
		GetEdictClassname(inflictor, sClassname, sizeof(sClassname));

		// If entity is a trigger, then allow damage, because map is damaging client
		if (!strncmp(sClassname, "trigger", 7, false))
		{
			// Allow damage
			return Plugin_Continue;
		}
	}

	// If mode doesn't started yet, then stop
	if (!gServerData.RoundStart)
	{
		// Block damage
		return Plugin_Handled;
	}

	// Validate damage
	if (!HitGroupsOnCalculateDamage(client, attacker, inflictor, flDamage, iBits, weapon, sClassname))
	{
		// Block damage
		return Plugin_Handled;
	}

	// Allow damage
	return Plugin_Changed;
}

/**
 * Hook: HurtSpawnPost
 * @brief Entity is spawned.
 *
 * @param entity            The entity index.
 **/
public void HitGroupsOnHurtSpawn(int entity)
{
	// Resets the weapon id
	ToolsSetCustomID(entity, -1);
}    
 
/**
 * @brief Calculate the real damage and knockback amount.
 *
 * @link https://github.com/s1lentq/ReGameDLL_CS/blob/7c9d59101b67525a35b0b3a31e17159ab5d42fbd/regamedll/dlls/player.sp#L984
 * 
 * @param client            The victim index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The type of damage inflicted.
 * @param weapon            The weapon index or -1 for unspecified.
 * @param sClassname        The classname string.
 * @return                  True to allow real damage or false to block real damage.
 **/
bool HitGroupsOnCalculateDamage(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &weapon, char[] sClassname)
{
	// Validate victim
	if (!IsPlayerAlive(client))
	{
		// Block damage
		return false;
	}
	
	// Initialize variables
	bool bInfectProtect = true; bool bSelfDamage = (client == attacker); bool bHasShield = (WeaponsFindByName(client, "weapon_shield") != -1); bool bHasHeavySuit = ToolsHasHeavySuit(client);
	float flDamageRatio = 1.0; float flArmorRatio = 0.5; float flBonusRatio = 0.5; float flKnockRatio = ClassGetKnockBack(gClientData[client].Class); 

	// Gets hitgroup index
	int iHitGroup = ToolsGetHitGroup(client);

	// Validate bit
	if (!HitGroupsHasBits(client, iBits, iHitGroup))
	{
		// Block damage
		return false;
	}

	/*_________________________________________________________________________________________________________________________________________*/
	
	// If custom hitgroups enabled, then apply multipliers
	if (gCvarList.HITGROUP.BoolValue)
	{
		// Validate hitgroup index
		int iHitIndex = HitGroupToIndex(iHitGroup);
		if (iHitIndex != -1)
		{
			// Resets new multipliers
			flArmorRatio = HitGroupsGetArmor(iHitIndex);
			flBonusRatio = HitGroupsGetBonus(iHitIndex);
			
			// Gets protect value
			bInfectProtect = HitGroupsIsProtect(iHitIndex);

			// Add multiplier
			flKnockRatio *= HitGroupsGetKnockBack(iHitIndex);

			// Validate heavysuit
			if (bHasHeavySuit)
			{
				// Add multiplier
				flDamageRatio *= HitGroupsGetHeavy(iHitIndex);
			}
			
			// Validate shield
			if (bHasShield)
			{
				// Add multiplier
				flDamageRatio *= HitGroupsGetShield(iHitIndex);
			}
			
			// Validate damage
			if (!HitGroupsIsDamage(iHitIndex))
			{
				// Block damage
				return false;
			}
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	// Validate point_hurt
	if (!strcmp(sClassname[6], "hurt", false))
	{
		/// Restore attacker
		attacker = ToolsGetActivator(inflictor);
		if (client == attacker)
		{
			// Block damage
			return false;
		}
	}
	
	// Call forward
	gForwardData._OnClientValidateDamage(client, attacker, inflictor, flDamage, iBits, weapon);

	// Validate result
	if (flDamage < 0.0)
	{
		// Block damage
		return false;
	}

	/*_________________________________________________________________________________________________________________________________________*/

	// Validate attacker
	if (IsPlayerExist(attacker, false))
	{
		// Validate team
		if (!bSelfDamage && ToolsGetTeam(client) == ToolsGetTeam(attacker))
		{
			// Block damage
			return false;
		}

		// If level system enabled, then apply multiplier
		if (gCvarList.LEVEL_SYSTEM.BoolValue)
		{
			// Add multiplier
			flDamageRatio *= float(gClientData[attacker].Level) * gCvarList.LEVEL_DAMAGE_RATIO.FloatValue + 1.0;
		}

		/// Validate entity which is inflict damage
		int dealer = IsValidEdict(weapon) ? weapon : HitGroupsHasInfclictor(sClassname) ? inflictor : -1;
		if (dealer != -1)
		{
			// Validate custom index
			int iD = ToolsGetCustomID(dealer);
			if (iD != -1)
			{
				// Add multipliers
				flDamageRatio *= WeaponsGetDamage(iD); 
				flKnockRatio  *= WeaponsGetKnockBack(iD);
				
				// Store the weapon id for an icon 
				gClientData[client].LastID = iD;
			}
		}
	}
	else
	{
		/// Avoid validation in high hierarchical functions
		attacker = 0; 
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	// Apply total multiplier
	flDamage *= flDamageRatio;
	
	// Armor doesn't protect against fall or drown damage!
	int iArmor = ToolsGetArmor(client); 
	if (iArmor > 0 && !(iBits & (DMG_DROWN | DMG_FALL)) && HitGroupsHasArmor(client, iHitGroup))
	{
		// Calculate reduced amount
		float flReduce = flDamage * flArmorRatio;
		int iHit = RoundToNearest((flDamage - flReduce) * flBonusRatio);

		// Does this use more armor than we have?
		if (iHit > iArmor)
		{
			flReduce = flDamage - iArmor;
			iHit = iArmor;
		}
		else
		{   
			// Validate high reduce
			if (iHit < 0)
			{
				iHit = 1;
			}
		}
		
		// Sets reduced amount
		flDamage = flReduce;

		// Sets a new armor amount
		iArmor -= iHit;
		ToolsSetArmor(client, iArmor);
	}
	
	// Validate heavy armor
	if (bHasHeavySuit && !iArmor)
	{
		// Removes a heavy suit for returning movement speed
		ToolsSetHeavySuit(client, false);
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	// Converts the damage amount
	int iDamage = RoundToNearest(flDamage);
	
	// Counts the applied damage
	int iHealth = ToolsGetHealth(client) - iDamage;
	
	// Validate attacker
	if (attacker > 0 && !bSelfDamage)
	{
		// Skip if damage too small
		if (iDamage > 0) 
		{
			// Give rewards for applied damage
			HitGroupsGiveMoney(attacker, iDamage);
			HitGroupsGiveExp(attacker, iDamage);
		}
		
		// If help messages enabled, then show info
		if (gCvarList.MESSAGES_DAMAGE.BoolValue) TranslationPrintHintText(attacker, (iArmor > 0) ? "info damage full" : "info damage", (iHealth > 0) ? iHealth : 0, iArmor);

		// Client was damaged by 'bullet' or 'knife'
		if (iBits & DMG_NEVERGIB)
		{
			// Apply knock
			HitGroupsApplyKnock(client, attacker, flKnockRatio);

			// Validate zombie
			if (gClientData[attacker].Zombie)
			{
				// If victim is zombie, then stop
				if (gClientData[client].Zombie)
				{
					// Block damage
					return false;
				}

				// If the gamemode allow infection, then apply it
				if (ModesIsInfection(gServerData.RoundMode))
				{
					// Validate lethal damage
					if (iHealth <= 0 || (!bHasShield && !iArmor)) /// Checks for shield protection
					{
						// Infect victim
						ApplyOnClientUpdate(client, attacker, ModesGetZombieType(gServerData.RoundMode));
						return false;
					}
					
					// Validate infection protect
					if (bInfectProtect && !bHasShield) 
					{
						// Block damage
						return false;
					}
				}
			}
		}
	}

	// Forward event to modules
	SoundsOnClientHurt(client, iBits);
	VEffectsOnClientHurt(client, attacker, iHealth);
	
	// Call forward
	gForwardData._OnClientDamaged(client, attacker, inflictor, flDamage, iBits, weapon, iHealth, iArmor);
	
	// Validate health
	if (iHealth > 0)
	{
		// Sets applied damage
		ToolsSetHealth(client, iHealth);
		
		// Block damage
		return false;
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
	CreateNative("ZP_GetHitGroupShield",    API_GetHitGroupShield);
	CreateNative("ZP_IsHitGroupProtect",    API_IsHitGroupProtect);
}

/**
 * @brief Applies fake damage to a player.
 *
 * @note native bool ZP_TakeDamage(client, attacker, inflictor, flDamage, iBits, weapon);
 **/
public int API_TakeDamage(Handle hPlugin, const int iNumParams)
{
	// Gets data from native cells
	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	int inflictor = GetNativeCell(3);
	float flDamage = GetNativeCell(4);
	int iBits = GetNativeCell(5);
	int weapon = GetNativeCell(6);

	// Call fake hook
	Action hResult = HitGroupsOnTakeDamage(client, attacker, inflictor, flDamage, iBits, weapon, NULL_VECTOR, NULL_VECTOR);
	
	// Validate damage 
	if (hResult == Plugin_Changed)
	{
		// If inflictor doesn't exist, then make a self damage
		if (!IsValidEdict(inflictor)) inflictor = client;

		// If attacker doesn't exist, then make a self damage
		if (!IsPlayerExist(attacker, false)) attacker = client;

		// Create the damage to kill
		SDKHooks_TakeDamage(client, inflictor, attacker, flDamage);
	}
	
	// Return result
	return (hResult != Plugin_Continue) ? true : false;
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
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Can't find hitgroup with an empty name");
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
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
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
 * @brief Gets the real hitgroup index of the hitgroup.
 *
 * @note native int ZP_GetHitGroupIndex(iD);
 **/
public int API_GetHitGroupIndex(Handle hPlugin, int iNumParams)
{    
	// Gets hitgroup index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
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
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
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
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
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
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
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
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
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
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	// Return the value (Float fix)
	return view_as<int>(HitGroupsGetHeavy(iD));
}

/**
 * @brief Gets the shield value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupShield(iD);
 **/
public int API_GetHitGroupShield(Handle hPlugin, int iNumParams)
{
	// Gets hitgroup index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	// Return the value (Float fix)
	return view_as<int>(HitGroupsGetShield(iD));
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
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
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
 * @return                  The generic knockback multiplier.
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
 * @return                  The armor damage multiplier.
 **/
float HitGroupsGetArmor(int iD)
{
	// Gets array handle of hitgroup at given index
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
	// Return the multiplier for the hitgroup
	return arrayHitGroup.Get(HITGROUPS_DATA_ARMOR);
}

/**
 * @brief Gets hitgroup bonus value.
 * 
 * @param iD                The array index.
 * @return                  The bonus damage multiplier.
 **/
float HitGroupsGetBonus(int iD)
{
	// Gets array handle of hitgroup at given index
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
	// Return the multiplier for the hitgroup
	return arrayHitGroup.Get(HITGROUPS_DATA_BONUS);
}

/**
 * @brief Gets hitgroup heavy value.
 * 
 * @param iD                The array index.
 * @return                  The heavy damage multiplier.
 **/
float HitGroupsGetHeavy(int iD)
{
	// Gets array handle of hitgroup at given index
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
	// Return the multiplier for the hitgroup
	return arrayHitGroup.Get(HITGROUPS_DATA_HEAVY);
}

/**
 * @brief Gets hitgroup shield value.
 * 
 * @param iD                The array index.
 * @return                  The shield damage multiplier.
 **/
float HitGroupsGetShield(int iD)
{
	// Gets array handle of hitgroup at given index
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
	// Return the multiplier for the hitgroup
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
	for (int i = 0; i < iSize; i++)
	{
		// Gets hitbox name 
		HitGroupsGetName(i, sHitGroupName, sizeof(sHitGroupName));
		
		// If names match, then return index
		if (!strcmp(sName, sHitGroupName, false))
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
	for (int i = 0; i < iSize; i++)
	{
		// Gets hitgroup index at this array index
		int iIndex = HitGroupsGetIndex(i);
		
		// If hitgroup indexes match, then return array index
		if (iHitGroup == iIndex)
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
 * @param client            The client index.
 * @param iBits             The type of damage inflicted.
 * @param iHitGroup         The hitgroup index output.
 * @return                  True or false.
 **/
bool HitGroupsHasBits(int client, int iBits, int &iHitGroup)
{
	// Validate bits
	if (iBits & (DMG_BURN | DMG_DIRECT))
	{
		iHitGroup = HITGROUP_CHEST;
	}
	else if (iBits & DMG_FALL)
	{
		if (!ClassIsFall(gClientData[client].Class)) return false;
		iHitGroup = GetRandomInt(HITGROUP_LEFTLEG, HITGROUP_RIGHTLEG); 
	}
	else if (iBits & DMG_BLAST)
	{
		iHitGroup = HITGROUP_GENERIC; 
	}
	else if (iBits & (DMG_NERVEGAS | DMG_DROWN))
	{
		iHitGroup = HITGROUP_HEAD;
	}
	
	// Return on success
	return true;
/*
	else if (iBits & DMG_GENERIC)    
	else if (iBits & DMG_CRUSH)
	else if (iBits & DMG_BULLET)
	else if (iBits & DMG_SLASH)    
	else if (iBits & DMG_CLUB)
	else if (iBits & DMG_SHOCK)
	else if (iBits & DMG_SONIC)
	else if (iBits & DMG_ENERGYBEAM)
	else if (iBits & DMG_PREVENT_PHYSICS_FORCE)
	else if (iBits & DMG_NEVERGIB)
	else if (iBits & DMG_ALWAYSGIB)
	else if (iBits & DMG_PARALYZE)
	else if (iBits & DMG_VEHICLE)
	else if (iBits & DMG_POISON)
	else if (iBits & DMG_RADIATION)
	else if (iBits & DMG_DROWNRECOVER)
	else if (iBits & DMG_ACID)
	else if (iBits & DMG_SLOWBURN)
	else if (iBits & DMG_REMOVENORAGDOLL)
	else if (iBits & DMG_PHYSGUN)
	else if (iBits & DMG_PLASMA)
	else if (iBits & DMG_AIRBOAT)
	else if (iBits & DMG_DISSOLVE)
	else if (iBits & DMG_BLAST_SURFACE)
	else if (iBits & DMG_BUCKSHOT)
*/
}

/**
 * @brief Returns true if the player has an armor at the hitgroup, false if not.
 * 
 * @param client            The client index.
 * @param iHitGroup         The hitgroup index.
 * @return                  True or false.
 **/
bool HitGroupsHasArmor(int client, int iHitGroup)
{
	// Initialize bool
	bool bApplyArmor;

	// Gets hitbox
	switch (iHitGroup)
	{
		case HITGROUP_HEAD :
		{
			bApplyArmor = ToolsHasHelmet(client);
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
 * @brief Returns true if the entity is a projectile, false if not.
 *
 * @param inflictor         The inflictor index.
 * @return                  True or false.    
 **/
bool HitGroupsHasInfclictor(char[] sClassname)
{
	// Gets string length
	int iLen = strlen(sClassname) - 11;
	
	// Validate length
	if (iLen > 0)
	{
		// Validate grenade
		return (!strncmp(sClassname[iLen], "_proj", 5, false));
	}

	// Return on unsuccess
	return (!strcmp(sClassname[6], "hurt", false) || !strncmp(sClassname, "infe", 4, false));
}

/** 
 * @brief Sets velocity knock for the applied damage.
 *
 * @param client            The client index.
 * @param attacker          The attacker index.
 * @param flForce           The push force.
 **/
void HitGroupsApplyKnock(int client, int attacker, float flForce)
{
	// Validate amount
	if (flForce <= 0.0)
	{
		return;
	}

	// Apply multiplier if client on air
	if (!HitGroupsIsOnGround(client)) flForce *= gCvarList.HITGROUP_KNOCKBACK_AIR.FloatValue;
	// Apply multiplier if client crouching
	else if (HitGroupsIsDucking(client)) flForce *= gCvarList.HITGROUP_KNOCKBACK_CROUCH.FloatValue;
	
	// If knockback system is enabled, then apply
	if (gCvarList.HITGROUP_KNOCKBACK.BoolValue) 
	{
		// Initialize vectors
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEndPosition[3];

		// Gets attacker position
		GetClientEyeAngles(attacker, vAngle);
		GetClientEyePosition(attacker, vPosition);

		// Create the infinite trace
		TR_TraceRayFilter(vPosition, vAngle, MASK_ALL, RayType_Infinite, HitGroupsFilter, attacker);

		// Gets hit point
		TR_GetEndPosition(vEndPosition);

		// Gets vector from the given starting and ending points
		MakeVectorFromPoints(vPosition, vEndPosition, vVelocity);

		// Normalize the vector (equal magnitude at varying distances)
		NormalizeVector(vVelocity, vVelocity);

		// Apply the magnitude by scaling the vector
		ScaleVector(vVelocity, flForce);

		// Adds the given vector to the client current velocity
		ToolsSetVelocity(client, vVelocity);
	}
	else
	{
		// Validate max
		if (flForce > 100.0) flForce = 100.0;
		else if (flForce <= 0.0) return;
		
		// Apply the stamina-based slowdown
		SetEntPropFloat(client, Prop_Send, "m_flStamina", flForce); 
	}
}

/**
 * @brief Reward money for the applied damage.
 *
 * @param client            The client index.
 * @param iDamage           The damage amount.
 **/
void HitGroupsGiveMoney(int client, int iDamage)
{
	// Gets class money bonuses
	static int iMoney[6];
	ClassGetMoney(gClientData[client].Class, iMoney, sizeof(iMoney));  
	
	// Validate limit
	int iLimit = iMoney[BonusType_Damage];
	if (!iLimit)
	{
		return;
	}

	// Increment total damage
	gClientData[client].AppliedDamage[0] += iDamage;

	// Validate bonus
	int iBonus = gClientData[client].AppliedDamage[0] / iLimit;
	if (!iBonus) 
	{
		return;
	}
	
	// Give money for the attacker
	AccountSetClientCash(client, gClientData[client].Money + iBonus);
	
	// Reduce damage value
	gClientData[client].AppliedDamage[0] -= iBonus * iLimit;
}

/**
 * @brief Reward experience for the applied damage.
 *
 * @param client            The client index.
 * @param iDamage           The damage amount.
 **/
void HitGroupsGiveExp(int client, int iDamage)
{
	// If level system disabled, then stop
	if (!gCvarList.LEVEL_SYSTEM.BoolValue)
	{
		return;
	}

	// Gets class exp bonuses
	static int iExp[6];
	ClassGetExp(gClientData[client].Class, iExp, sizeof(iExp));
	
	// Validate limit
	int iLimit = iExp[BonusType_Damage];
	if (!iLimit)
	{
		return;
	}
	
	// Increment total damage
	gClientData[client].AppliedDamage[1] += iDamage;
	
	// Validate bonus
	int iBonus = gClientData[client].AppliedDamage[1] / iLimit;
	if (!iBonus) 
	{
		return;
	}
	
	// Give experience for the attacker
	LevelSystemOnSetExp(client, gClientData[client].Exp + iBonus);
	
	// Reduce damage value
	gClientData[client].AppliedDamage[1] -= iBonus * iLimit;
}

/**
 * @brief Gets the ground state on a client.
 *
 * @param client            The client index.
 * @return                  True or false.
 **/
bool HitGroupsIsOnGround(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1;
}

/**
 * @brief Gets the ducking state on a client.
 *
 * @param client            The client index.
 * @return                  True or false.
 **/
bool HitGroupsIsDucking(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bDucking"));
}

/**
 * @brief Trace filter.
 *  
 * @param entity            The entity index.
 * @param contentsMask      The contents mask.
 * @param client            The client index.
 * @return                  True or false.
 **/
public bool HitGroupsFilter(int entity, int contentsMask, int client)
{
	return (entity != client);
}