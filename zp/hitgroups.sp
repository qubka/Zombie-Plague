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
void HitGroupsOnInit()
{
	if (gServerData.MapLoaded)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsPlayerExist(i, false))
			{
				HitGroupsOnClientInit(i);
			}
		}
	} 
	
	HitGroupsOnLoad();
}

/**
 * @brief Prepare all hitgroup data.
 **/
void HitGroupsOnLoad()
{
	ConfigRegisterConfig(File_HitGroups, Structure_KeyValue, CONFIG_FILE_ALIAS_HITGROUPS);

	if (!gCvarList.HITGROUP.BoolValue)
	{
		return;
	}

	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_HITGROUPS, sBuffer, sizeof(sBuffer));

	if (!bExists)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Missing hitgroups config file: %s", sBuffer);
		return;
	}

	ConfigSetConfigPath(File_HitGroups, sBuffer);

	bool bSuccess = ConfigLoadConfig(File_HitGroups, gServerData.HitGroups);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Unexpected error encountered loading: %s", sBuffer);
		return;
	}
	
	HitGroupsOnCacheData();

	ConfigSetConfigLoaded(File_HitGroups, true);
	ConfigSetConfigReloadFunc(File_HitGroups, GetFunctionByName(GetMyHandle(), "HitGroupsOnConfigReload"));
	ConfigSetConfigHandle(File_HitGroups, gServerData.HitGroups);
}

/**
 * @brief Caches hitgroup data from file into arrays.
 **/
void HitGroupsOnCacheData()
{
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_HitGroups, sBuffer, sizeof(sBuffer)); 
	
	KeyValues kvHitGroups;
	bool bSuccess = ConfigOpenConfigFile(File_HitGroups, kvHitGroups);
	
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Unexpected error caching data from hitgroups config file: %s", sBuffer);
		return;
	}
	
	int iSize = gServerData.HitGroups.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "No usable data found in hitgroups config file: %s", sBuffer);
		return;
	}

	for (int i = 0; i < iSize; i++)
	{
		HitGroupsGetName(i, sBuffer, sizeof(sBuffer)); // Index: 0
		kvHitGroups.Rewind();
		if (!kvHitGroups.JumpToKey(sBuffer))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_HitGroups, "Config Validation", "Couldn't cache hitgroup data for: %s (check hitgroup config)", sBuffer);
			continue;
		}

		ArrayList arrayHitGroup = gServerData.HitGroups.Get(i);
		
		arrayHitGroup.Push(kvHitGroups.GetNum("index", -1));                      // Index: 1
		arrayHitGroup.Push(ConfigKvGetStringBool(kvHitGroups, "damage", "on"));   // Index: 2
		arrayHitGroup.Push(kvHitGroups.GetFloat("knockback", 1.0));               // Index: 3
		arrayHitGroup.Push(kvHitGroups.GetFloat("armor", 0.5));                   // Index: 4
		arrayHitGroup.Push(kvHitGroups.GetFloat("bonus", 0.5));                   // Index: 5
		arrayHitGroup.Push(kvHitGroups.GetFloat("heavy", 0.5));                   // Index: 6
		arrayHitGroup.Push(kvHitGroups.GetFloat("shield", 0.5));                  // Index: 7
		arrayHitGroup.Push(ConfigKvGetStringBool(kvHitGroups, "protect", "yes")); // Index: 8
	}
	
	delete kvHitGroups;
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void HitGroupsOnConfigReload()
{
	HitGroupsOnLoad();
}

/**
 * @brief Hook hitgroups cvar changes.
 **/
void HitGroupsOnCvarInit()
{
	gCvarList.HITGROUP                  = FindConVar("zp_hitgroup"); 
	gCvarList.HITGROUP_KNOCKBACK        = FindConVar("zp_knockback"); 
	gCvarList.HITGROUP_KNOCKBACK_AIR    = FindConVar("zp_knockback_air"); 
	gCvarList.HITGROUP_KNOCKBACK_CROUCH = FindConVar("zp_knockback_crouch"); 
	gCvarList.HITGROUP_FRIENDLY_FIRE    = FindConVar("mp_friendlyfire");
	gCvarList.HITGROUP_FRIENDLY_GRENADE = FindConVar("ff_damage_reduction_grenade");
	gCvarList.HITGROUP_FRIENDLY_BULLETS = FindConVar("ff_damage_reduction_bullets");
	gCvarList.HITGROUP_FRIENDLY_OTHER   = FindConVar("ff_damage_reduction_other");
	gCvarList.HITGROUP_FRIENDLY_SELF    = FindConVar("ff_damage_reduction_grenade_self");
	
	gCvarList.HITGROUP_FRIENDLY_FIRE.IntValue          = 0;
	CvarsOnCheatSet(gCvarList.HITGROUP_FRIENDLY_GRENADE, 0);
	CvarsOnCheatSet(gCvarList.HITGROUP_FRIENDLY_BULLETS, 0);
	CvarsOnCheatSet(gCvarList.HITGROUP_FRIENDLY_OTHER,   0);
	CvarsOnCheatSet(gCvarList.HITGROUP_FRIENDLY_SELF,    0);

	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_FIRE,    CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_GRENADE, CvarsLockOnCvarHook2);
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_BULLETS, CvarsLockOnCvarHook2);
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_OTHER,   CvarsLockOnCvarHook2);
	HookConVarChange(gCvarList.HITGROUP_FRIENDLY_SELF,    CvarsLockOnCvarHook2);
	
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
	int iDamage = gCvarList.GAMEMODE.IntValue;
	if (!iDamage)
	{
		SDKUnhook(client, SDKHook_TraceAttack,  HitGroupsOnTraceAttack);
		SDKUnhook(client, SDKHook_OnTakeDamage, HitGroupsOnTakeDamage);
		return;
	}
	
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
	if (entity > -1 && !strcmp(sClassname[6], "hurt", false))
	{
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
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	HitGroupsOnInit();
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void HitGroupsOnClientUpdate(int client)
{
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
	if (!gServerData.RoundStart)
	{
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client) && IsPlayerExist(attacker))
	{
		if (ToolsGetTeam(client) == ToolsGetTeam(attacker))
		{
			return Plugin_Handled;
		}
	}

	if (gCvarList.HITGROUP.BoolValue)
	{
		int iHitIndex = HitGroupToIndex(iHitGroup);
		if (iHitIndex != -1)
		{
			if (!HitGroupsIsDamage(iHitIndex))
			{
				return Plugin_Handled;
			}
		}
	}

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
	static char sClassname[SMALL_LINE_LENGTH]; sClassname[0] = NULL_STRING[0];
	
	if (IsValidEdict(inflictor))
	{
		GetEdictClassname(inflictor, sClassname, sizeof(sClassname));

		if (!strncmp(sClassname, "trigger", 7, false))
		{
			return Plugin_Continue;
		}
	}

	if (!gServerData.RoundStart)
	{
		return Plugin_Handled;
	}

	if (!HitGroupsOnCalculateDamage(client, attacker, inflictor, flDamage, iBits, weapon, sClassname))
	{
		return Plugin_Handled;
	}

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
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	
	bool bInfectProtect = true; bool bSelfDamage = (client == attacker); bool bHasShield = (WeaponsFindByName(client, "weapon_shield") != -1); bool bHasHeavySuit = ToolsHasHeavySuit(client);
	float flDamageRatio = 1.0; float flArmorRatio = 0.5; float flBonusRatio = 0.5; float flKnockRatio = ClassGetKnockBack(gClientData[client].Class); 

	int iHitGroup = ToolsGetHitGroup(client);

	if (!HitGroupsHasBits(client, iBits, iHitGroup))
	{
		return false;
	}

	/*_________________________________________________________________________________________________________________________________________*/
	
	if (gCvarList.HITGROUP.BoolValue)
	{
		int iHitIndex = HitGroupToIndex(iHitGroup);
		if (iHitIndex != -1)
		{
			flArmorRatio = HitGroupsGetArmor(iHitIndex);
			flBonusRatio = HitGroupsGetBonus(iHitIndex);
			
			bInfectProtect = HitGroupsIsProtect(iHitIndex);

			flKnockRatio *= HitGroupsGetKnockBack(iHitIndex);

			if (bHasHeavySuit)
			{
				flDamageRatio *= HitGroupsGetHeavy(iHitIndex);
			}
			
			if (bHasShield)
			{
				flDamageRatio *= HitGroupsGetShield(iHitIndex);
			}
			
			if (!HitGroupsIsDamage(iHitIndex))
			{
				return false;
			}
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	if (!strcmp(sClassname[6], "hurt", false))
	{
		attacker = ToolsGetActivator(inflictor);
		if (client == attacker)
		{
			return false;
		}
	}
	
	gForwardData._OnClientValidateDamage(client, attacker, inflictor, flDamage, iBits, weapon);

	if (flDamage < 0.0)
	{
		return false;
	}

	/*_________________________________________________________________________________________________________________________________________*/

	if (IsPlayerExist(attacker, false))
	{
		if (!bSelfDamage && ToolsGetTeam(client) == ToolsGetTeam(attacker))
		{
			return false;
		}

		if (gCvarList.LEVEL_SYSTEM.BoolValue)
		{
			flDamageRatio *= float(gClientData[attacker].Level) * gCvarList.LEVEL_DAMAGE_RATIO.FloatValue + 1.0;
		}

		int dealer = IsValidEdict(weapon) ? weapon : HitGroupsHasInfclictor(sClassname) ? inflictor : -1;
		if (dealer != -1)
		{
			int iD = ToolsGetCustomID(dealer);
			if (iD != -1)
			{
				flDamageRatio *= WeaponsGetDamage(iD); 
				flKnockRatio  *= WeaponsGetKnockBack(iD);
				
				gClientData[client].LastID = iD;
			}
		}
	}
	else
	{
		attacker = 0; 
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	flDamage *= flDamageRatio;
	
	int iArmor = ToolsGetArmor(client); 
	if (iArmor > 0 && !(iBits & (DMG_DROWN | DMG_FALL)) && HitGroupsHasArmor(client, iHitGroup))
	{
		float flReduce = flDamage * flArmorRatio;
		int iHit = RoundToNearest((flDamage - flReduce) * flBonusRatio);

		if (iHit > iArmor)
		{
			flReduce = flDamage - iArmor;
			iHit = iArmor;
		}
		else
		{   
			if (iHit < 0)
			{
				iHit = 1;
			}
		}
		
		flDamage = flReduce;

		iArmor -= iHit;
		ToolsSetArmor(client, iArmor);
	}
	
	if (bHasHeavySuit && !iArmor)
	{
		ToolsSetHeavySuit(client, false);
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	int iDamage = RoundToNearest(flDamage);
	
	int iHealth = ToolsGetHealth(client) - iDamage;
	
	if (attacker > 0 && !bSelfDamage)
	{
		if (iDamage > 0) 
		{
			HitGroupsGiveMoney(attacker, iDamage);
			HitGroupsGiveExp(attacker, iDamage);
		}
		
		if (gCvarList.MESSAGES_DAMAGE.BoolValue) TranslationPrintHintText(attacker, (iArmor > 0) ? "info damage full" : "info damage", (iHealth > 0) ? iHealth : 0, iArmor);

		if (iBits & DMG_NEVERGIB)
		{
			HitGroupsApplyKnock(client, attacker, flKnockRatio);

			if (gClientData[attacker].Zombie)
			{
				if (gClientData[client].Zombie)
				{
					return false;
				}

				if (ModesIsInfection(gServerData.RoundMode))
				{
					if (iHealth <= 0 || (!bHasShield && !iArmor)) /// Checks for shield protection
					{
						ApplyOnClientUpdate(client, attacker, ModesGetZombieType(gServerData.RoundMode));
						return false;
					}
					
					if (bInfectProtect && !bHasShield) 
					{
						return false;
					}
				}
			}
		}
	}

	SoundsOnClientHurt(client, iBits);
	VEffectsOnClientHurt(client, attacker, iHealth);
	
	gForwardData._OnClientDamaged(client, attacker, inflictor, flDamage, iBits, weapon, iHealth, iArmor);
	
	if (iHealth > 0)
	{
		ToolsSetHealth(client, iHealth);
		
		return false;
	}

	return true;
}

/*
 * Hit groups natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void HitGroupsOnNativeInit() 
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
	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	int inflictor = GetNativeCell(3);
	float flDamage = GetNativeCell(4);
	int iBits = GetNativeCell(5);
	int weapon = GetNativeCell(6);

	Action hResult = HitGroupsOnTakeDamage(client, attacker, inflictor, flDamage, iBits, weapon, NULL_VECTOR, NULL_VECTOR);
	
	if (hResult == Plugin_Changed)
	{
		if (!IsValidEdict(inflictor)) inflictor = client;

		if (!IsPlayerExist(attacker, false)) attacker = client;

		SDKHooks_TakeDamage(client, inflictor, attacker, flDamage);
	}
	
	return (hResult != Plugin_Continue) ? true : false;
} 
 
/**
 * @brief Gets the amount of all hitgrups.
 *
 * @note native int ZP_GetNumberHitGroup();
 **/
public int API_GetNumberHitGroup(Handle hPlugin, int iNumParams)
{
	return gServerData.HitGroups.Length;
}

/**
 * @brief Gets the array index at which the hitgroup index is at.
 *
 * @note native int ZP_GetHitGroupID(hitgroup);
 **/
public int API_GetHitGroupID(Handle hPlugin, int iNumParams)
{
	return HitGroupToIndex(GetNativeCell(1));
}

/**
 * @brief Gets the index of a higroup at a given name.
 *
 * @note native int ZP_GetHitGroupNameID(name);
 **/
public int API_GetHitGroupNameID(Handle hPlugin, int iNumParams)
{
	int maxLen;
	GetNativeStringLength(1, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Can't find hitgroup with an empty name");
		return -1;
	}
	
	static char sName[SMALL_LINE_LENGTH];

	GetNativeString(1, sName, sizeof(sName));

	return HitGroupsNameToIndex(sName);  
}

/**
 * @brief Gets the name of a hitgroup at a given index.
 *
 * @note native void ZP_GetHitGroupName(iD, name, maxlen);
 **/
public int API_GetHitGroupName(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sName[SMALL_LINE_LENGTH];
	HitGroupsGetName(iD, sName, sizeof(sName));

	return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the real hitgroup index of the hitgroup.
 *
 * @note native int ZP_GetHitGroupIndex(iD);
 **/
public int API_GetHitGroupIndex(Handle hPlugin, int iNumParams)
{    
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	return HitGroupsGetIndex(iD);
}

/**
 * @brief Checks the damage value of the hitgroup.
 *
 * @note native bool ZP_IsHitGroupDamage(iD);
 **/
public int API_IsHitGroupDamage(Handle hPlugin, int iNumParams)
{    
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	return HitGroupsIsDamage(iD);
}

/**
 * @brief Gets the knockback value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupKnockBack(iD);
 **/
public int API_GetHitGroupKnockBack(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(HitGroupsGetKnockBack(iD));
}

/**
 * @brief Gets the armor value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupArmor(iD);
 **/
public int API_GetHitGroupArmor(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(HitGroupsGetArmor(iD));
}

/**
 * @brief Gets the bonus value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupBonus(iD);
 **/
public int API_GetHitGroupBonus(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(HitGroupsGetBonus(iD));
}

/**
 * @brief Gets the heavy value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupHeavy(iD);
 **/
public int API_GetHitGroupHeavy(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(HitGroupsGetHeavy(iD));
}

/**
 * @brief Gets the shield value of the hitgroup.
 *
 * @note native float ZP_GetHitGroupShield(iD);
 **/
public int API_GetHitGroupShield(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
	return view_as<int>(HitGroupsGetShield(iD));
}

/**
 * @brief Checks the protect value of the hitgroup.
 *
 * @note native bool ZP_IsHitGroupProtect(iD);
 **/
public int API_IsHitGroupProtect(Handle hPlugin, int iNumParams)
{    
	int iD = GetNativeCell(1);
	
	if (iD >= gServerData.HitGroups.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_HitGroups, "Native Validation", "Invalid the hitgroup index (%d)", iD);
		return -1;
	}
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	ArrayList arrayHitGroup = gServerData.HitGroups.Get(iD);
	
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
	static char sHitGroupName[SMALL_LINE_LENGTH];
	
	int iSize = gServerData.HitGroups.Length;
	for (int i = 0; i < iSize; i++)
	{
		HitGroupsGetName(i, sHitGroupName, sizeof(sHitGroupName));
		
		if (!strcmp(sName, sHitGroupName, false))
		{
			return i;
		}
	}
	
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
	int iSize = gServerData.HitGroups.Length;
	for (int i = 0; i < iSize; i++)
	{
		int iIndex = HitGroupsGetIndex(i);
		
		if (iHitGroup == iIndex)
		{
			return i;
		}
	}
	
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
	bool bApplyArmor;

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
	int iLen = strlen(sClassname) - 11;
	
	if (iLen > 0)
	{
		return (!strncmp(sClassname[iLen], "_proj", 5, false));
	}

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
	if (flForce <= 0.0)
	{
		return;
	}

	if (!HitGroupsIsOnGround(client)) flForce *= gCvarList.HITGROUP_KNOCKBACK_AIR.FloatValue;
	else if (HitGroupsIsDucking(client)) flForce *= gCvarList.HITGROUP_KNOCKBACK_CROUCH.FloatValue;
	
	if (gCvarList.HITGROUP_KNOCKBACK.BoolValue) 
	{
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEndPosition[3];

		GetClientEyeAngles(attacker, vAngle);
		GetClientEyePosition(attacker, vPosition);

		TR_TraceRayFilter(vPosition, vAngle, MASK_ALL, RayType_Infinite, HitGroupsFilter, attacker);

		TR_GetEndPosition(vEndPosition);

		MakeVectorFromPoints(vPosition, vEndPosition, vVelocity);

		NormalizeVector(vVelocity, vVelocity);

		ScaleVector(vVelocity, flForce);

		ToolsSetVelocity(client, vVelocity);
	}
	else
	{
		if (flForce > 100.0) flForce = 100.0;
		else if (flForce <= 0.0) return;
		
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
	int iLimit = ClassGetMoney(gClientData[client].Class, BonusType_Damage);
	if (!iLimit)
	{
		return;
	}

	gClientData[client].AppliedDamage[0] += iDamage;

	int iBonus = gClientData[client].AppliedDamage[0] / iLimit;
	if (!iBonus) 
	{
		return;
	}
	
	AccountSetClientCash(client, gClientData[client].Money + iBonus);
	
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
	if (!gCvarList.LEVEL_SYSTEM.BoolValue)
	{
		return;
	}

	int iLimit = ClassGetExp(gClientData[client].Class, BonusType_Damage);
	if (!iLimit)
	{
		return;
	}
	
	gClientData[client].AppliedDamage[1] += iDamage;
	
	int iBonus = gClientData[client].AppliedDamage[1] / iLimit;
	if (!iBonus) 
	{
		return;
	}
	
	LevelSystemOnSetExp(client, gClientData[client].Exp + iBonus);
	
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