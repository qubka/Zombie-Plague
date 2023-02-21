/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          weaponmod.sp
 *  Type:          Module
 *  Description:   Weapon MOD functions.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov). Regards to Andersso
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
 * @section Number of valid slots.
 **/
enum /*SlotIndex*/
{ 
	SlotIndex_Invalid = -1,       /** Used as return value when a slot doens't exist. */
	
	SlotIndex_Primary,            /** Primary slot */
	SlotIndex_Secondary,          /** Secondary slot */
	SlotIndex_Melee,              /** Melee slot */
	SlotIndex_Equipment,          /** Equipment slot */  
	SlotIndex_C4,                 /** C4 slot */ 

	SlotIndex_Max = 16			  /** Used as validation value to check that offset is broken. */	
};
/**
 * @endsection
 **/

/**
 * @section Number of valid models.
 **/
enum ModelType
{
	ModelType_Invalid = -1,       /** Used as return value when a model doens't exist. */
	
	ModelType_View,               /** View model */
	ModelType_World,              /** World model */
	ModelType_Drop,               /** Dropped model */
	ModelType_Projectile          /** Projectile model */
};
/**
 * @endsection
 **/
 

/**
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallGetItemSchema;
Handle hSDKCallGetItemDefinitionByName;
Handle hSDKCallSpawnItem;
Handle hSDKCallWeaponSwitch;
//Handle hSDKCallGetDrawActivity;
Handle hSDKCallGetSlot;

/**
 * Variables to store virtual SDK adresses.
 **/
Address pItemSchema;

/**
 * Variables to store dynamic SDK offsets.
 **/
int Player_hViewModel;
int ItemDef_Index;

/**
 * Variables to store DHook calls handlers.
 **/
Handle hDHookPrecacheModel;
Handle hDHookWeaponCanUse;
Handle hDHookWeaponHolster;
Handle hDHookGetMaxClip;
Handle hDHookGetReserveAmmoMax;
Handle hDHookGetPlayerMaxSpeed;

/**
 * Variables to store dynamic DHook offsets.
 **/
int DHook_Precache;
int DHook_WeaponCanUse;
int DHook_WeaponHolster;
int DHook_GetMaxClip1;
int DHook_GetReserveAmmoMax;
int DHook_GetPlayerMaxSpeed;

/**
 * @brief Initialize the main virtual/dynamic offsets for the weapon SDK/DHook system.
 **/
void WeaponMODOnInit()
{
	{
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(gServerData.CStrike, SDKConf_Signature, "GetItemSchema");
		
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
		
		if ((hSDKCallGetItemSchema = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"GetItemSchema\". Update \"SourceMod\"");
			return;
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/

	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(gServerData.CStrike, SDKConf_Virtual, /*CEconItemSchema::*/"GetItemDefintionByName");
		
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		
		if ((hSDKCallGetItemDefinitionByName = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CEconItemSchema::GetItemDefinitionByName\". Update \"SourceMod\"");
			return;
		}
	}

	/*_________________________________________________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CItemGeneration::SpawnItem");
		
		if (gServerData.Platform != OS_Windows)
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		}
		
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		
		if ((hSDKCallSpawnItem = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CItemGeneration::SpawnItem\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gServerData.SDKHooks, SDKConf_Virtual, /*CCSPlayer::*/"Weapon_Switch");
		
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

		if ((hSDKCallWeaponSwitch = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CCSPlayer::Weapon_Switch\". Update \"SourceMod\"");
		}
	}

	/*_________________________________________________________________________________________________________________________________________*/
	
	/*{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "CBaseCombatWeapon::GetDrawActivity");
		
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		
		if ((hSDKCallGetDrawActivity = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseCombatWeapon::GetDrawActivity\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		}
	}*/
		
	/*_________________________________________________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "CBaseCombatWeapon::GetSlot");
		
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		
		if ((hSDKCallGetSlot = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseCombatWeapon::GetSlot\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/

	pItemSchema = (gServerData.Platform == OS_Linux) ? view_as<Address>(SDKCall(hSDKCallGetItemSchema)) : view_as<Address>(SDKCall(hSDKCallGetItemSchema) + 4);

	fnInitGameConfOffset(gServerData.Config, ItemDef_Index, "CEconItemDefinition::GetDefinitionIndex");
	fnInitSendPropOffset(Player_hViewModel, "CBasePlayer", "m_hViewModel");
	
	fnInitGameConfOffset(gServerData.SDKHooks, DHook_WeaponCanUse, /*CCSPlayer::*/"Weapon_CanUse");
	fnInitGameConfOffset(gServerData.Config, DHook_WeaponHolster, "CBaseCombatWeapon::Holster");
	fnInitGameConfOffset(gServerData.Config, DHook_GetMaxClip1, "CBaseCombatWeapon::GetMaxClip1");
	fnInitGameConfOffset(gServerData.Config, DHook_GetReserveAmmoMax, "CBaseCombatWeapon::GetReserveAmmoMax");
	fnInitGameConfOffset(gServerData.Config, DHook_GetPlayerMaxSpeed, "CCSPlayer::GetPlayerMaxSpeed");
	fnInitGameConfOffset(gServerData.Config, DHook_Precache, "CBaseEntity::PrecacheModel");
   	
	/*_________________________________________________________________________________________________________________________________________*/
	
	hDHookWeaponCanUse = DHookCreate(DHook_WeaponCanUse, HookType_Entity, ReturnType_Bool, ThisPointer_Ignore, WeaponDHookOnCanUse);
	DHookAddParam(hDHookWeaponCanUse, HookParamType_CBaseEntity);
	
	if (hDHookWeaponCanUse == null)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"Weapon_CanUse\". Update \"SourceMod\"");
	}

   	/*_________________________________________________________________________________________________________________________________________*/
   
	hDHookWeaponHolster = DHookCreate(DHook_WeaponHolster, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, WeaponDHookOnHolster);
	DHookAddParam(hDHookWeaponHolster, HookParamType_CBaseEntity);
	
	if (hDHookWeaponHolster == null)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"CBaseCombatWeapon::Holster\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}   
	
   	/*_________________________________________________________________________________________________________________________________________*/
   
	hDHookGetMaxClip = DHookCreate(DHook_GetMaxClip1, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, WeaponDHookOnGetMaxClip1);
	
	if (hDHookGetMaxClip == null)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"CBaseCombatWeapon::GetMaxClip1\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	hDHookGetReserveAmmoMax = DHookCreate(DHook_GetReserveAmmoMax, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, WeaponDHookOnGetReverseMax);
	DHookAddParam(hDHookGetReserveAmmoMax, HookParamType_Unknown);
	
	if (hDHookGetReserveAmmoMax == null)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"CBaseCombatWeapon::GetReserveAmmoMax\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	hDHookGetPlayerMaxSpeed = DHookCreate(DHook_GetPlayerMaxSpeed, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, WeaponDHookGetPlayerMaxSpeed);
	
	if (hDHookGetPlayerMaxSpeed == null)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"CCSPlayer::GetPlayerMaxSpeed\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}

	/*_________________________________________________________________________________________________________________________________________*/
	
	hDHookPrecacheModel = DHookCreate(DHook_Precache, HookType_Raw, ReturnType_Int, ThisPointer_Ignore, WeaponDHookOnPrecacheModel);
	DHookAddParam(hDHookPrecacheModel, HookParamType_CharPtr);
	DHookAddParam(hDHookPrecacheModel, HookParamType_Bool);

	if (hDHookPrecacheModel == null)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"CBaseEntity::PrecacheModel\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
	else
	{
		DHookRaw(hDHookPrecacheModel, false, gServerData.Engine);
	}
}

/**
 * @brief Initialize default weapons during the loading.
 **/
void WeaponMODOnLoad()
{
	static char sWeapon[SMALL_LINE_LENGTH];
	gCvarList.WEAPONS_DEFAULT_MELEE.GetString(sWeapon, sizeof(sWeapon));
	
	gServerData.Melee = WeaponsNameToIndex(sWeapon);
}

/**
 * @brief Restore weapon models during the unloading.
 **/
void WeaponMODOnUnload()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerExist(i))
		{
			if (gClientData[i].CustomWeapon != -1)
			{
				int view1 = EntRefToEntIndex(gClientData[i].ViewModels[0]);
				int view2 = EntRefToEntIndex(gClientData[i].ViewModels[1]);

				if (view1 != -1)
				{
					AcceptEntityInput(view1, "EnableDraw"); 
				}

				if (view2 != -1)
				{
					AcceptEntityInput(view2, "DisableDraw"); 
				}
			}
		}
	}
}

/**
 * @brief Creates commands for sdk module.
 **/
void WeaponMODOnCommandInit()
{
	AddCommandListener(WeaponMODOnCommandListenedDrop, "drop");
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void WeaponMODOnClientInit(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse,     WeaponMODOnCanUse);
	SDKHook(client, SDKHook_WeaponSwitch,     WeaponMODOnSwitch);
	SDKHook(client, SDKHook_WeaponSwitchPost, WeaponMODOnSwitchPost);
	SDKHook(client, SDKHook_WeaponEquipPost,  WeaponMODOnEquipPost);
	SDKHook(client, SDKHook_PostThinkPost,    WeaponMODOnPostThinkPost);


	if (hDHookWeaponCanUse)
	{
		DHookEntity(hDHookWeaponCanUse, true, client);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "DHook Validation", "Failed to attach DHook to \"Weapon_CanUse\". Update \"SourceMod\"");
	}
	
	if (hDHookGetPlayerMaxSpeed)
	{
		DHookEntity(hDHookGetPlayerMaxSpeed, true, client);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "DHook Validation", "Failed to attach DHook to \"CCSPlayer::GetPlayerMaxSpeed\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
}

/**
 * @brief Hook weapons cvar changes.
 **/
void WeaponMODOnCvarInit()
{
	gCvarList.WEAPONS_BUYAMMO        = FindConVar("zp_weapons_buyammo");
	gCvarList.WEAPONS_REMOVE_DROPPED = FindConVar("zp_weapons_remove_dropped");
	gCvarList.WEAPONS_PICKUP_RANGE   = FindConVar("zp_weapons_pickup_range");
	gCvarList.WEAPONS_PICKUP_LEVEL   = FindConVar("zp_weapons_pickup_level");
	gCvarList.WEAPONS_PICKUP_ONLINE  = FindConVar("zp_weapons_pickup_online");
	gCvarList.WEAPONS_PICKUP_GROUP   = FindConVar("zp_weapons_pickup_group");
	gCvarList.WEAPONS_DEFAULT_MELEE  = FindConVar("zp_weapons_default_melee");

	HookConVarChange(gCvarList.WEAPONS_BUYAMMO,       WeaponMODOnCvarHookAmmo);
	HookConVarChange(gCvarList.WEAPONS_DEFAULT_MELEE, WeaponMODOnCvarHookDefault);
	
	WeaponMODOnCvarLoad();
}

/**
 * @brief Load weapons listeners changes.
 **/
void WeaponMODOnCvarLoad()
{
	if (gCvarList.WEAPONS_BUYAMMO.BoolValue)
	{
		AddCommandListener(WeaponMODOnCommandListenedBuy, "buyammo1");
		AddCommandListener(WeaponMODOnCommandListenedBuy, "buyammo2");
	}
	else
	{
		RemoveCommandListener2(WeaponMODOnCommandListenedBuy, "buyammo1");
		RemoveCommandListener2(WeaponMODOnCommandListenedBuy, "buyammo2");
	}
}

/*
 * Weapons main functions.
 */
 
/**
 * Cvar hook callback (zp_buyammo)
 * @brief Buyammo button hooks initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void WeaponMODOnCvarHookAmmo(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	WeaponMODOnCvarLoad();
}
 
/**
 * Cvar hook callback (zp_default_melee)
 * @brief Weapons default initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void WeaponMODOnCvarHookDefault(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	gServerData.Melee = WeaponsNameToIndex(newValue); //WeaponMODOnLoad();
}

/**
 * @brief Called when a weapon is created.
 *
 * @param weapon            The weapon index.
 * @param sClassname        The weapon entity.
 **/
void WeaponMODOnEntityCreated(int weapon, const char[] sClassname)
{
	if (sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_') // weapon_
	{
		SDKHook(weapon, SDKHook_SpawnPost, WeaponMODOnWeaponSpawn);
	}
	else if (sClassname[0] == 'i' && sClassname[1] == 't') // item_
	{
		SDKHook(weapon, SDKHook_SpawnPost, WeaponMODOnItemSpawn);
	}
	else if (sClassname[0] == 'i' && sClassname[1] == 'n' && sClassname[4] == 'r') // inferno
	{
		SDKHook(weapon, SDKHook_SpawnPost, WeaponMODOnInfernoSpawn);
	}
	else
	{
		int iLen = strlen(sClassname) - 11;
		
		if (iLen > 0)
		{
			if (!strncmp(sClassname[iLen], "_proj", 5, false))
			{
				SDKHook(weapon, SDKHook_SpawnPost, WeaponMODOnGrenadeSpawn);
			}
		}
	}
}

/*
 * Weapons spawn functions.
 */

/**
 * Hook: ItemSpawnPost
 * @brief Item is spawned.
 *
 * @param item              The item index.
 **/
public void WeaponMODOnItemSpawn(int item)
{
	ToolsSetCustomID(item, -1);
}

/**
 * Hook: WeaponSpawnPost
 * @brief Weapon is spawned.
 *
 * @param weapon            The weapon index.
 **/
public void WeaponMODOnWeaponSpawn(int weapon)
{
	ToolsSetCustomID(weapon, -1);

	if (hDHookWeaponHolster) 
	{
		DHookEntity(hDHookWeaponHolster, true, weapon);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "DHook Validation", "Failed to attach DHook to \"CBaseCombatWeapon::Holster\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}

	if (WeaponsGetAmmoType(weapon) != -1)
	{
		SDKHook(weapon, SDKHook_ReloadPost, WeaponMODOnWeaponReload);

		_exec.WeaponMODOnWeaponSpawnPost(weapon);
	}
}

/**
 * Hook: WeaponSpawnPost
 * @brief Weapon is spawned. *(Next frame)
 *
 * @param refID             The reference index.
 **/
public void WeaponMODOnWeaponSpawnPost(int refID) 
{
	int weapon = EntRefToEntIndex(refID);

	if (weapon != -1)
	{
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{
			int iClip = WeaponsGetClip(iD);
			if (iClip)
			{
				WeaponsSetClipAmmo(weapon, iClip); 
				WeaponsSetMaxClipAmmo(weapon, iClip);
				
				if (hDHookGetMaxClip) 
				{
					DHookEntity(hDHookGetMaxClip, true, weapon);
				}
				else
				{
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "DHook Validation", "Failed to attach DHook to \"CBaseCombatWeapon::GetMaxClip1\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
				}
			}

			int iAmmo = WeaponsGetAmmo(iD);
			if (iAmmo)
			{
				WeaponsSetReserveAmmo(weapon, iAmmo); 
				WeaponsSetMaxReserveAmmo(weapon, iAmmo);
				
				if (hDHookGetReserveAmmoMax)
				{
					DHookEntity(hDHookGetReserveAmmoMax, true, weapon);
				}
				else
				{
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "DHook Validation", "Failed to attach DHook to \"CBaseCombatWeapon::GetReserveAmmoMax\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
				}
			}
		}
	}
}

/**
 * Hook: InfernoSpawnPost
 * @brief Inferno is spawned.
 *
 * @param entity            The entity index.
 **/
public void WeaponMODOnInfernoSpawn(int entity)
{
	int client = ToolsGetOwner(entity);
	
	int iD = -1;
	
	if (IsPlayerExist(client, false))
	{
		iD = gClientData[client].LastGrenade;
		gClientData[client].LastGrenade = -1;
	}
	
	ToolsSetCustomID(entity, iD);
}

/**
 * Hook: WeaponSpawnPost
 * @brief Grenade is spawned.
 *
 * @param grenade           The grenade index.
 **/
public void WeaponMODOnGrenadeSpawn(int grenade)
{
	if (GetEntProp(grenade, Prop_Data, "m_nNextThinkTick") == -1)
	{
		return;
	}

	int client = ToolsGetOwner(grenade);
	
	if (IsPlayerExist(client, false)) 
	{
		int weapon = ToolsGetActiveWeapon(client);
	
		if (weapon != -1)
		{
			int iD = ToolsGetCustomID(weapon);
			if (iD != -1)
			{
				ToolsSetCustomID(grenade, iD);

				ItemDef iItem = WeaponsGetDefIndex(iD);
				if (IsFireble(iItem))
				{
					gClientData[client].LastGrenade = iD;
				}
				
				gForwardData._OnGrenadeCreated(client, grenade, iD);
				
				_exec.WeaponMODOnGrenadeSpawnPost(grenade);
				
				return;
			}
		}
	}
	
	ToolsSetCustomID(grenade, -1);
}

/**
 * Hook: WeaponSpawnPost
 * @brief Grenade is spawned. *(Next frame)
 *
 * @param refID             The reference index.
 **/
public void WeaponMODOnGrenadeSpawnPost(int refID) 
{
	int grenade = EntRefToEntIndex(refID);

	if (grenade != -1)
	{
		int iD = ToolsGetCustomID(grenade);
		if (iD != -1)
		{
			WeaponHDRSetDroppedModel(grenade, iD, ModelType_Projectile);
		}
	}
}

/*
 * Weapons reload functions.
 */
 
/**
 * Hook: WeaponReloadPost
 * @brief Weapon is reloaded.
 *
 * @param weapon            The weapon index.
 **/
public Action WeaponMODOnWeaponReload(int weapon) 
{
	_exec.WeaponMODOnWeaponReloadPost(weapon);
	
	return Plugin_Continue;
}

/**
 * Hook: WeaponReloadPost
 * @brief Weapon is reloaded. *(Next frame)
 *
 * @param refID             The reference index.
 **/
public void WeaponMODOnWeaponReloadPost(int refID) 
{
	int weapon = EntRefToEntIndex(refID);

	if (weapon != -1)
	{
		int client = WeaponsGetOwner(weapon);
		
		if (!IsPlayerExist(client)) 
		{
			return;
		}
		
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{
			float flCurrentTime = GetGameTime();
			
			float flReload = WeaponsGetReload(iD);
			if (flReload)
			{
				if (flReload < 0.0) flReload = 0.0;
			
				flReload += flCurrentTime;
		
				WeaponsSetAnimating(weapon, flReload);
				
				ToolsSetAttack(client, flReload);
			}
			
			gForwardData._OnWeaponReload(client, weapon, iD);
		}
	}
}

/*
 * Weapons use functions.
 */

/**
 * Hook: WeaponCanUse
 * @brief Player pick-up any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public Action WeaponMODOnCanUse(int client, int weapon)
{
	if (IsValidEdict(weapon))
	{
		if (!WeaponsCanUse(client, weapon))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/**
 * @brief Weapon has been used.
 *
 * @param client            The client index.
 **/
void WeaponMODOnUse(int client)
{
	int entity = GetClientAimTarget(client, false);
	
	if (entity != -1)
	{
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(entity, sClassname, sizeof(sClassname));

		if (sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_' && // weapon_
		  (sClassname[7] == 'k' || // knife
		  (sClassname[7] == 'm' && sClassname[8] == 'e') ||  // melee
		  (sClassname[7] == 'f' && sClassname[9] == 's'))) // fists
		{
			if (!WeaponsCanUse(client, entity))
			{
				return;
			}
			
			if (UTIL_GetDistanceBetween(client, entity) > gCvarList.WEAPONS_PICKUP_RANGE.FloatValue) 
			{
				return;
			}
			
			WeaponsEquip(client, entity, -1); /// id not used
		}
	}
}

/*
 * Weapons update functions.
 */

/**
 * @brief Client has been changed class state. *(Next frame)
 *
 * @param client            The client index.
 **/
void WeaponMODOnClientUpdate(int client)
{
	gClientData[client].CustomWeapon = -1;

	int view1 = WeaponHDRGetPlayerViewModel(client, 0);
	int view2 = WeaponHDRGetPlayerViewModel(client, 1);
	
	if (view1 == -1)
	{
		return;
	}
	
	if (view2 == -1)
	{
		view2 = WeaponHDRCreateViewModel(client);
	}

	AcceptEntityInput(view2, "DisableDraw");

	gClientData[client].ViewModels[0] = EntIndexToEntRef(view1);
	gClientData[client].ViewModels[1] = EntIndexToEntRef(view2);

	int weapon = ToolsGetActiveWeapon(client);
	
	if (weapon != -1)
	{
		WeaponsSwitch(client, weapon);
	}
}

/**
 * @brief Fake client has been think.
 *
 * @param client            The client index.
 **/
void WeaponMODOnFakeClientThink(int client)
{
	if (gCvarList.WEAPONS_BUYAMMO.BoolValue)
	{
		int iAmount = GetRandomInt(4, 6);
		for (int i = 0; i < iAmount; i++)
		{
			WeaponMODOnClientBuyammo(client);
		}
	}
}

/**
 * @brief Client has been killed.
 *
 * @param client            The client index.
 **/
void WeaponMODOnClientDeath(int client)
{
	int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);

	if (view2 != -1)
	{
		AcceptEntityInput(view2, "DisableDraw"); 
	}

	gClientData[client].ViewModels[0] = -1;
	gClientData[client].ViewModels[1] = -1;
	gClientData[client].CustomWeapon = -1; 
}

/*
 * Weapons drop functions.
 */
 
/**
 * Hook: WeaponDrop
 * @brief Player drop any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if (IsValidEdict(weapon))
	{
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{
			if (!WeaponsIsDrop(iD)) 
			{
				ItemDef iItem = WeaponsGetDefIndex(iD);
				if (IsMelee(iItem))
				{
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "Kill"); /// Destroy
				}
				
				return Plugin_Handled;
			}
			
			gForwardData._OnWeaponDrop(weapon, iD);

			_exec.WeaponMODOnWeaponDropPost(weapon);
		}
		
		float flRemoval = gCvarList.WEAPONS_REMOVE_DROPPED.FloatValue;
		if (flRemoval > 0.0)
		{
			CreateTimer(flRemoval, WeaponMODOnWeaponRemove, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}

/**
 * Hook: WeaponDropPost
 * @brief Weapon is dropped. *(Next frame)
 *
 * @param refID             The reference index.
 **/
public void WeaponMODOnWeaponDropPost(int refID) 
{
	int weapon = EntRefToEntIndex(refID);
	
	if (weapon != -1)
	{
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{	
			WeaponHDRSetDroppedModel(weapon, iD, ModelType_Drop);
		}
	}
}

/**
 * @brief Timer callback, removed a weapon.
 * 
 * @param hTimer            The timer handle.
 * @param refID             The reference index.                    
 **/
public Action WeaponMODOnWeaponRemove(Handle hTimer, int refID)
{
	int weapon = EntRefToEntIndex(refID);

	if (weapon != -1)
	{
		int client = WeaponsGetOwner(weapon);
		
		if (!IsPlayerExist(client)) 
		{
			AcceptEntityInput(weapon, "Kill"); /// Destroy
		}
	}
	
	return Plugin_Stop;
}

/*
 * Weapons switch functions.
 */

/**
 * Hook: WeaponSwitch
 * @brief Player deploying any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public void WeaponMODOnSwitch(int client, int weapon) 
{
	gClientData[client].RunCmd = false;
	gClientData[client].CustomWeapon = -1;

	int view1 = EntRefToEntIndex(gClientData[client].ViewModels[0]);
	int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);

	if (view1 == -1 || view2 == -1)
	{
		return;
	}

	AcceptEntityInput(view2, "DisableDraw");

	int iD = ToolsGetCustomID(weapon);
	if (iD != -1)
	{
		float flCurrentTime = GetGameTime();
		
		float flDeploy = WeaponsGetDeploy(iD);
		if (flDeploy)
		{
			if (flDeploy < 0.0) flDeploy = 0.0;
	
			flDeploy += flCurrentTime;
	
			WeaponsSetAnimating(weapon, flDeploy);
			
			ToolsSetAttack(client, flDeploy);
		}
		
		ItemDef iItem = WeaponsGetDefIndex(iD);
		if (WeaponsGetModelViewID(iD) || (ClassGetClawID(gClientData[client].Class) && IsMelee(iItem)) || (ClassGetGrenadeID(gClientData[client].Class) && IsGrenade(iItem)))
		{
			gClientData[client].CustomWeapon = weapon;
			//SEffectsClientWeapon(client, iItem, false);
		}

		if (WeaponsGetModelWorldID(iD) || (gClientData[client].Zombie && IsMelee(iItem)))
		{
			WeaponHDRSetPlayerWorldModel(weapon, iD, ModelType_World);
		}
	}
	
	static char sArm[PLATFORM_LINE_LENGTH];
	ClassGetArmModel(gClientData[client].Class, sArm, sizeof(sArm));
	
	if (hasLength(sArm)) ToolsSetArm(client, sArm);
}

/**
 * Hook: WeaponSwitchPost
 * @brief Player deployed any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public void WeaponMODOnSwitchPost(int client, int weapon) 
{
	int view1 = EntRefToEntIndex(gClientData[client].ViewModels[0]);
	int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);

	if (view1 == -1 || view2 == -1)
	{
		return;
	}

	if (IsValidEdict(weapon))
	{
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{
			ItemDef iItem = WeaponsGetDefIndex(iD);

			if (weapon == gClientData[client].CustomWeapon)
			{
				WeaponHDRSwapViewModel(client, weapon, view1, view2, iD);
				
				AcceptEntityInput(view1, "DisableDraw"); 
				AcceptEntityInput(view2, "EnableDraw"); 

				//WeaponHDRSetSequence(view2, WeaponHDRFindDrawSequence(weapon)); 
			}

			if (WeaponsGetModelWorldID(iD) || (gClientData[client].Zombie && IsMelee(iItem)))
			{
				WeaponHDRSetPlayerWorldModel(weapon, iD, ModelType_World);
			}
			
			if (IsPlayerExist(client))
			{
				gForwardData._OnWeaponDeploy(client, weapon, iD);
			}
		}
	}
	
	gClientData[client].RunCmd = true;
}

/*
 * Weapons think functions.
 */

/**
 * Hook: PostThinkPost
 * @brief Player hold any weapon.
 *
 * @param client            The client index.
 **/
public void WeaponMODOnPostThinkPost(int client) 
{
	WeaponAttachSetAddons(client); /// Back weapon models
	
	int weapon = gClientData[client].CustomWeapon;
	
	if (weapon == -1)
	{
		return;
	}

	int view1 = EntRefToEntIndex(gClientData[client].ViewModels[0]);
	int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);

	if (view1 == -1 || view2 == -1)
	{
		return;
	}

	int iSequence = WeaponHDRGetSequence(view1);

	int sequenceParity = WeaponHDRGetSequenceParity(view1);

	if (iSequence == WeaponHDRGetLastSequence(view1))
	{
		int lastSequenceParity = WeaponHDRGetLastSequenceParity(view1);
		if (lastSequenceParity != -1)
		{
			if (sequenceParity == lastSequenceParity)
			{
				return;
			}
			
			int iD = ToolsGetCustomID(weapon);

			int swapSequence = WeaponsGetSequenceSwap(iD, iSequence);
			if (swapSequence != -1)
			{
				WeaponHDRSetSequence(view1, swapSequence);
				WeaponHDRSetSequence(view2, swapSequence);
				
				WeaponHDRSetLastSequence(view1, swapSequence);
			}
			else
			{
				if (ToolsGetSequenceActivity(view1, iSequence) != WEAPONS_ACT_VM_IDLE)
				{
					WeaponHDRToggleViewModel(client, view2, iD);
				}
			}
		}
	}
	else
	{
		WeaponHDRSetSequence(view2, iSequence);
		WeaponHDRSetLastSequence(view1, iSequence);
	}
	
	WeaponHDRSetLastSequenceParity(view1, sequenceParity);
}

/*
 * Weapons equip functions.
 */

/**
 * Hook: WeaponEquipPost
 * @brief Player equiped by any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public void WeaponMODOnEquipPost(int client, int weapon) 
{
	if (IsValidEdict(weapon))
	{
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)    
		{
			ItemDef iItem = WeaponsGetDefIndex(iD);
			if (IsKnife(iItem))
			{
				gClientData[client].LastKnife = EntIndexToEntRef(weapon);
			}
		}

		int dropped = WeaponHDRGetSwappedWeapon(weapon);
		
		if (dropped != -1)
		{
			AcceptEntityInput(dropped, "Kill"); /// Destroy
		}
	}
}

/*
 * Weapons attack functions.
 */

/**
 * @brief Weapon has been fired.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
void WeaponMODOnFire(int client, int weapon) 
{
	int iD = ToolsGetCustomID(weapon);
	if (iD != -1)    
	{
		float flCurrentTime = GetGameTime();

		float flShoot = WeaponsGetShoot(iD);
		if (flShoot)
		{
			if (flShoot < 0.0) flShoot = 0.0;
				
			flShoot += flCurrentTime;
	
			WeaponsSetAnimating(weapon, flShoot);
			
			ToolsSetAttack(client, flShoot);
		}
		
		if (WeaponsGetAmmoType(weapon) != -1) 
		{
			if (WeaponsGetModelViewID(iD))
			{
				int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);
				
				if (view2 == -1/* || world == -1*/)
				{
					return;
				}

				static char sName[NORMAL_LINE_LENGTH];
				WeaponsGetModelMuzzle(iD, sName, sizeof(sName));
				if (hasLength(sName)) ParticlesCreate(view2, "1", sName, 0.1);
				WeaponsGetModelShell(iD, sName, sizeof(sName));
				if (hasLength(sName)) ParticlesCreate(view2, "2", sName, 0.1);
				
				float flDelay = WeaponsGetModelHeat(iD);
				if (flDelay)
				{
					static float flHeatDelay[MAXPLAYERS+1]; static float flSmoke[MAXPLAYERS+1];

					float flHeat = ((flCurrentTime - GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime")) * -0.5) + flHeatDelay[client];

					flHeat += flDelay;
					
					if (flHeat < 0.0) flHeat = 0.0;

					if (flHeat > 1.0)
					{
						if (flCurrentTime - flSmoke[client] > 1.0)
						{
							ParticlesCreate(view2, "1", "weapon_muzzle_smoke", 4.5); /// Max duration 
							flSmoke[client] = flCurrentTime; /// 'DestroyImmediately/'Kill' not work for smoke!
						}
						
						flHeat = 0.0;
					}

					flHeatDelay[client] = flHeat;
				}
			}
		}

		gForwardData._OnWeaponFire(client, weapon, iD);
	}
}

/**
 * @brief The bullet hits something.
 *
 * @param client            The client index.
 * @param vBullet           The position of a bullet hit.
 * @param weapon            The weapon index.
 **/
void WeaponMODOnBullet(int client, float vBullet[3], int weapon) 
{ 
	int iD = ToolsGetCustomID(weapon);
	if (iD != -1)    
	{
		gForwardData._OnWeaponBullet(client, vBullet, weapon, iD);
	}
}

/**
 * @brief Weapon has been shoot.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
Action WeaponMODOnShoot(int client, int weapon) 
{ 
	int iD = ToolsGetCustomID(weapon);
	if (iD != -1)    
	{
		Action hResult = SoundsOnClientShoot(client, iD);
		gForwardData._OnWeaponShoot(client, weapon, iD);
		return hResult;
	}
	
	return Plugin_Continue;
}

/*
 * Weapons cmd functions.
 */

/**
 * @brief Weapon is holding.
 *
 * @param client            The client index.
 * @param iButtons          The button buffer.
 * @param iLastButtons      The last button buffer.
 * @param weapon            The weapon index.
 **/
Action WeaponMODOnRunCmd(int client, int &iButtons, int iLastButtons, int weapon)
{
	static int iD; iD = ToolsGetCustomID(weapon); /** static for runcmd **/
	if (iD != -1)    
	{
		if (iButtons & IN_ATTACK || iButtons & IN_ATTACK2)
		{
			static int iAmmo; iAmmo = ClassGetAmmunition(gClientData[client].Class);
			if (iAmmo && WeaponsGetAmmoType(weapon) != -1) /// If weapon without any type of ammo, then skip
			{
				ItemDef iItem = WeaponsGetDefIndex(iD);
				if (iItem != ItemDef_Taser)
				{
					switch (iAmmo)
					{
						case 1 : { WeaponsSetReserveAmmo(weapon, WeaponsGetMaxReserveAmmo(weapon)); }
						case 2 : { WeaponsSetClipAmmo(weapon, WeaponsGetMaxClipAmmo(weapon)); } 
						default : { /* < empty statement > */ }
					}
				}
			}
		}
	
		Action hResult;
		gForwardData._OnWeaponRunCmd(client, iButtons, iLastButtons, weapon, iD, hResult);
		return hResult;
	}
	
	return Plugin_Continue;
}

/*
 * Weapons hostage functions.
 */

/**
 * @brief Weapon has been switch by hostage.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
void WeaponMODOnHostage(int client) 
{
	WeaponHDRSetPlayerViewModel(client, 1, -1);

	_call.WeaponMODOnHostagePost(client);
}
	
/**
 * @brief Weapon has been switch by hostage. *(Next frame)
 *
 * @param userID            The user id.
 **/
public void WeaponMODOnHostagePost(int userID) 
{
	int client = GetClientOfUserId(userID);

	if (client)
	{
		if (gClientData[client].CustomWeapon != -1)
		{
			int view2 = WeaponHDRGetPlayerViewModel(client, 1);

			if (view2 != -1)
			{
				AcceptEntityInput(view2, "Kill"); /// Destroy
			}

			WeaponHDRSetPlayerViewModel(client, 1, EntRefToEntIndex(gClientData[client].ViewModels[1]));
		}
	}
}

/*
 * Weapons command functions.
 */

/**
 * Listener command callback (buyammo1, buyammo2)
 * @brief Buying of the ammunition.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action WeaponMODOnCommandListenedBuy(int client, char[] commandMsg, int iArguments)
{
	if (IsPlayerExist(client))
	{
		WeaponMODOnClientBuyammo(client);
	}

	return Plugin_Continue;
}

/**
 * @brief Client has been buying ammunition.
 *
 * @param client            The client index.
 **/
void WeaponMODOnClientBuyammo(int client)
{
	if (ClassGetAmmunition(gClientData[client].Class))
	{
		return;
	}
	
	int weapon = ToolsGetActiveWeapon(client);

	if (weapon != -1)
	{
		if (WeaponsGetAmmoType(weapon) == -1)
		{
			return;
		}

		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{
			int iCost = WeaponsGetAmmunition(iD);
			if (!iCost)
			{
				return;
			}
			
			if (gClientData[client].Money < iCost)
			{
				TranslationPrintHintText(client, "block buying ammunition");
				
				EmitSoundToClient(client, SOUND_BUTTON_CMD_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_NORMAL);    
				return;
			}
	
			int iAmmo = WeaponsGetReserveAmmo(weapon);
			int iMaxAmmo = WeaponsGetMaxReserveAmmo(weapon);
			
			if (iAmmo < iMaxAmmo)
			{
				iAmmo += WeaponsGetMaxClipAmmo(weapon); if (!iAmmo) /*~*/ iAmmo++;

				WeaponsSetReserveAmmo(weapon, (iAmmo <= iMaxAmmo) ? iAmmo : iMaxAmmo);

				AccountSetClientCash(client, gClientData[client].Money - iCost);

				EmitSoundToClient(client, SOUND_AMMO, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
			}
		}
	}
}

/**
 * Listener command callback (drop)
 * @brief Dropping any weapon.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action WeaponMODOnCommandListenedDrop(int client, char[] commandMsg, int iArguments)
{
	if (IsPlayerExist(client))
	{
		int weapon = ToolsGetActiveWeapon(client);

		if (weapon != -1)
		{
			int iD = ToolsGetCustomID(weapon);
			if (iD != -1)
			{
				if (!WeaponsIsDrop(iD)) 
				{
					return Plugin_Handled;
				}

				ItemDef iItem = WeaponsGetDefIndex(iD);
				if (IsKnife(iItem))
				{
					WeaponsDrop(client, weapon);

					if (iD == gServerData.Melee)
					{
						return Plugin_Handled;
					}
					
					if (WeaponsGive(client, gServerData.Melee) == -1)
					{
						for (int i = SlotIndex_Primary; i <= SlotIndex_C4; i++)
						{
							weapon = GetPlayerWeaponSlot(client, i);
							
							if (weapon != -1) 
							{
								WeaponsSwitch(client, weapon);
								break;
							}
						}
					}
					
					return Plugin_Handled;
				}
				else if (iItem == ItemDef_Shield || iItem == ItemDef_RepulsorDevice)
				{
					WeaponsDrop(client, weapon);

					return Plugin_Handled;
				}
				else
				{
					if (gCvarList.MESSAGES_WEAPON_DROP.BoolValue && gCvarList.GAMEMODE_WEAPONS_REMOVE.BoolValue && gServerData.RoundNew)
					{
						TranslationPrintToChat(client, "info drop");
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

/*
 * Weapons dhooks functions.
 */

/**
 * DHook: Allow to pick-up some weapons.
 * @note bool CCSPlayer::Weapon_CanUse(CBaseCombatWeapon *)
 *
 * @param hReturn           Handle to return structure.
 * @param hParams           Handle with parameters.
 **/
public MRESReturn WeaponDHookOnCanUse(Handle hReturn, Handle hParams)
{
	int weapon = DHookGetParam(hParams, 1);
	
	if (IsValidEdict(weapon))
	{
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{
			ItemDef iItem = WeaponsGetDefIndex(iD);
			if (IsKnife(iItem) || iItem == ItemDef_C4)
			{
				DHookSetReturn(hReturn, true);
				return MRES_Override;
			}
		}
	}
	
	return MRES_Ignored;
}

/**
 * DHook: Hook weapon deploy.
 * @note bool CBaseCombatWeapon::Deploy(void *)
 *
 * @param weapon            The weapon index.
 * @param hReturn           Handle to return structure.
 **/
/*public MRESReturn WeaponDHookOnDeploy(int weapon, Handle hReturn)
{
	int iD = ToolsGetCustomID(weapon);
	if (iD != -1)
	{
		int client = WeaponsGetOwner(weapon);
		
		if (!IsPlayerExist(client)) 
		{
			return MRES_Ignored;
		}
		
		WeaponModOnDeploy(client, weapon);
		gForwardData._OnWeaponDeploy(client, weapon, iD);
	}
	
	return MRES_Ignored;
}*/

/**
 * DHook: Hook weapon holster.
 * @note bool CBaseCombatWeapon::Holster(CBaseCombatWeapon *)
 *
 * @param weapon            The weapon index.
 * @param hReturn           Handle to return structure.
 * @param hParams           Handle with parameters.
 **/
public MRESReturn WeaponDHookOnHolster(int weapon, Handle hReturn, Handle hParams)
{
	int iD = ToolsGetCustomID(weapon);
	if (iD != -1)
	{
		int client = WeaponsGetOwner(weapon);
		
		/*if (!IsPlayerExist(client)) 
		{
			return MRES_Ignored;
		}*/
		
		gForwardData._OnWeaponHolster(client, weapon, iD);
	}
	
	return MRES_Ignored;
} 

/**
 * DHook: Sets a weapon clip when its spawned, picked, dropped or reloaded.
 * @note int CBaseCombatWeapon::GetMaxClip1(void *)
 *
 * @param weapon            The weapon index.
 * @param hReturn           Handle to return structure.
 **/
public MRESReturn WeaponDHookOnGetMaxClip1(int weapon, Handle hReturn)
{
	if (IsValidEdict(weapon))
	{
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{
			int iClip = WeaponsGetClip(iD);
			if (iClip)
			{
				DHookSetReturn(hReturn, iClip);
				return MRES_Override;
			}
		}
	}

	return MRES_Ignored;
}

/**
 * DHook: Sets a weapon reserved ammunition when its spawned, picked, dropped or reloaded. 
 * @note int CBaseCombatWeapon::GetReserveAmmoMax(AmmoPosition_t *)
 *
 * @param weapon            The weapon index.
 * @param hReturn           Handle to return structure.
 * @param hParams           Handle with parameters.
 **/
public MRESReturn WeaponDHookOnGetReverseMax(int weapon, Handle hReturn, Handle hParams)
{
	if (IsValidEdict(weapon))
	{
		int iD = ToolsGetCustomID(weapon);
		if (iD != -1)
		{
			int iAmmo = WeaponsGetAmmo(iD);
			if (iAmmo)
			{
				DHookSetReturn(hReturn, iAmmo);
				return MRES_Override;
			}
		}
	}
	
	return MRES_Ignored;
}

/**
 * DHook: Sets a moving speed when holding a weapon. 
 * @note float CCSPlayer::GetPlayerMaxSpeed(void *)
 *
 * @param client            The client index.
 * @param hReturn           Handle to return structure.
 **/
public MRESReturn WeaponDHookGetPlayerMaxSpeed(int client, Handle hReturn)
{
	if (IsPlayerExist(client))
	{
		float flLMV = ToolsGetLMV(client) + (gCvarList.LEVEL_SYSTEM.BoolValue ? (gCvarList.LEVEL_SPEED_RATIO.FloatValue * float(gClientData[client].Level)) : 0.0);
		
		int weapon = ToolsGetActiveWeapon(client);

		if (weapon != -1)
		{
			int iD = ToolsGetCustomID(weapon);
			if (iD != -1)
			{
				float flSpeed = WeaponsGetSpeed(iD);
				if (flSpeed > 0.0)
				{
					DHookSetReturn(hReturn, flSpeed * flLMV);
					return MRES_Override;
				}
			}
		}

		DHookSetReturn(hReturn, ClassGetSpeed(gClientData[client].Class) * flLMV);
		return MRES_Override;
	}
	
	return MRES_Ignored;
}

/**
 * DHook: Block to precache some arms models.
 * @note int CBaseEntity::PrecacheModel(char const*, bool)
 *
 * @param hReturn           Handle to return structure.
 * @param hParams           Handle with parameters.
 **/
public MRESReturn WeaponDHookOnPrecacheModel(Handle hReturn, Handle hParams)
{
	static char sPath[NORMAL_LINE_LENGTH];
	DHookGetParamString(hParams, 1, sPath, sizeof(sPath));
	
	if (!strncmp(sPath, "models/weapons/v_models/arms/glove_hardknuckle/", 47, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}