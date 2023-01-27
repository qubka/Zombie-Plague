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
enum SlotType
{ 
	SlotType_Invalid = -1,        /** Used as return value when a slot doens't exist. */
	
	SlotType_Primary,             /** Primary slot */
	SlotType_Secondary,           /** Secondary slot */
	SlotType_Melee,               /** Melee slot */
	SlotType_Equipment,           /** Equipment slot */  
	SlotType_C4                   /** C4 slot */  
};
/**
 * @endsection
 **/
 
/**
 * @section Number of valid menus.
 **/
enum MenuType
{
	MenuType_Invalid = -1,        /** Used as return value when a menu doens't exist. */
	
	MenuType_Pistols,             /** Pistol menu */
	MenuType_Shotguns,            /** Shotgun menu */
	MenuType_Rifles,              /** Rifle menu */
	MenuType_Snipers,             /** Sniper menu */
	MenuType_Machineguns,         /** Machineguns menu */
	MenuType_Knifes,              /** Knife menu */
	MenuType_Equipments,          /** Equipment menu */
	
	/* Rebuy system */
	MenuType_Rebuy,               /** Rebuy menu */  
	MenuType_Option,              /** Option menu */  
	MenuType_Add                  /** Add menu */
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
Handle hSDKCallSpawnItem;
Handle hSDKCallWeaponSwitch;
Handle hSDKCallGetSlot;
Handle hSDKCallGetItemDefinitionByName;

/**
 * Variables to store virtual SDK adresses.
 **/
int Player_ViewModel;
int ItemDef_Index;

/**
 * Variables to store DHook calls handlers.
 **/
Handle hDHookPrecacheModel;
Handle hDHookGetMaxClip;
Handle hDHookGetReserveAmmoMax;
Handle hDHookWeaponCanUse;

/**
 * Variables to store dynamic DHook offsets.
 **/
int DHook_Precache;
int DHook_GetMaxClip1;
int DHook_GetReserveAmmoMax;
int DHook_WeaponCanUse;

/**
 * @brief Initialize the main virtual/dynamic offsets for the weapon SDK/DHook system.
 **/
void WeaponMODOnInit(/*void*/) /// @link https://www.unknowncheats.me/forum/counterstrike-global-offensive/152722-dumping-datamap_t.html
{                                               /// @version C_BaseFlex -> C_EconEntity -> C_BaseCombatWeapon -> C_WeaponCSBase -> C_BaseCSGrenade
	
	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gServerData.CStrike, SDKConf_Signature, "GetItemSchema");
	
	// Adds a parameter to the calling convention. This should be called in normal ascending order
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	// Validate call
	if ((hSDKCallGetItemSchema = EndPrepSDKCall()) == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"GetItemSchema\". Update \"SourceMod\"");
		return;
	}

	/*_________________________________________________________________________________________________________________________________________*/
	
	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CItemGeneration::SpawnItem");
	
	// Validate linux
	if (gServerData.Platform != OS_Windows)
	{
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	}
	
	// Adds a parameter to the calling convention. This should be called in normal ascending order
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	// Validate call
	if ((hSDKCallSpawnItem = EndPrepSDKCall()) == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CItemGeneration::SpawnItem\". Update signature in \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gServerData.SDKHooks, SDKConf_Virtual, /*CBasePlayer::*/"Weapon_Switch");
	
	// Adds a parameter to the calling convention. This should be called in normal ascending order
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

	// Validate call
	if ((hSDKCallWeaponSwitch = EndPrepSDKCall()) == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBasePlayer::Weapon_Switch\". Update \"SourceMod\"");
		return;
	}

	/*_________________________________________________________________________________________________________________________________________*/

	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "CBaseCombatWeapon::GetSlot");
	
	// Adds a parameter to the calling convention. This should be called in normal ascending order
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	// Validate call
	if ((hSDKCallGetSlot = EndPrepSDKCall()) == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseCombatWeapon::GetSlot\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	/*_________________________________________________________________________________________________________________________________________*/

	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gServerData.CStrike, SDKConf_Virtual, /*CEconItemSchema::*/"GetItemDefintionByName");
	
	// Adds a parameter to the calling convention. This should be called in normal ascending order
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	// Validate call
	if ((hSDKCallGetItemDefinitionByName = EndPrepSDKCall()) == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CEconItemSchema::GetItemDefinitionByName\". Update \"SourceMod\"");
		return;
	}
	
	/*_________________________________________________________________________________________________________________________________________*/

	// Load weapon offsets
	fnInitSendPropOffset(Player_ViewModel, "CBasePlayer", "m_hViewModel");
	fnInitGameConfOffset(gServerData.Config, ItemDef_Index, "CEconItemDefinition::GetDefinitionIndex");
	
	// Load other offsets
	fnInitGameConfOffset(gServerData.Config, DHook_GetMaxClip1, "CBaseCombatWeapon::GetMaxClip1");
	fnInitGameConfOffset(gServerData.Config, DHook_GetReserveAmmoMax, "CBaseCombatWeapon::GetReserveAmmoMax");
	fnInitGameConfOffset(gServerData.Config, DHook_Precache, "CBaseEntity::PrecacheModel");
	fnInitGameConfOffset(gServerData.SDKHooks, DHook_WeaponCanUse, /*CBasePlayer::*/"Weapon_CanUse");
   
	/// CBaseCombatWeapon::GetMaxClip1(CBaseCombatWeapon *this)
	hDHookGetMaxClip = DHookCreate(DHook_GetMaxClip1, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, WeaponDHookOnGetMaxClip1);
	
	// Validate hook
	if (hDHookGetMaxClip == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"CBaseCombatWeapon::GetMaxClip1\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	/// CBaseCombatWeapon::GetReserveAmmoMax(CBaseCombatWeapon *this, AmmoPosition_t)
	hDHookGetReserveAmmoMax = DHookCreate(DHook_GetReserveAmmoMax, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, WeaponDHookOnGetReverseMax);
	DHookAddParam(hDHookGetReserveAmmoMax, HookParamType_Unknown);
	
	// Validate hook
	if (hDHookGetReserveAmmoMax == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"CBaseCombatWeapon::GetReserveAmmoMax\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	/// CBasePlayer::Weapon_CanUse(CBaseCombatWeapon *this)
	hDHookWeaponCanUse = DHookCreate(DHook_WeaponCanUse, HookType_Entity, ReturnType_Bool, ThisPointer_Ignore, WeaponDHookOnCanUse);
	DHookAddParam(hDHookWeaponCanUse, HookParamType_CBaseEntity);
	
	// Validate hook
	if (hDHookWeaponCanUse == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"Weapon_CanUse\". Update \"SourceMod\"");
		return;
	}
	
	/// CBaseEntity::PrecacheModel(char const*, bool)
	hDHookPrecacheModel = DHookCreate(DHook_Precache, HookType_Raw, ReturnType_Int, ThisPointer_Ignore, WeaponDHookOnPrecacheModel);
	DHookAddParam(hDHookPrecacheModel, HookParamType_CharPtr);
	DHookAddParam(hDHookPrecacheModel, HookParamType_Bool);
	DHookRaw(hDHookPrecacheModel, false, gServerData.Engine);

	// Validate hook
	if (hDHookPrecacheModel == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to create DHook for \"CBaseEntity::PrecacheModel\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		return;
	}
}

/**
 * @brief Initialize default weapons during the loading.
 **/
void WeaponMODOnLoad(/*void*/)
{
	// Gets weapon name
	static char sWeapon[SMALL_LINE_LENGTH];
	gCvarList.WEAPON_DEFAULT_MELEE.GetString(sWeapon, sizeof(sWeapon));
	
	// Store index
	gServerData.Melee = WeaponsNameToIndex(sWeapon);
}

/**
 * @brief Restore weapon models during the unloading.
 **/
void WeaponMODOnUnload(/*void*/)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if (IsPlayerExist(i))
		{
			// Validate weapon
			if (gClientData[i].CustomWeapon != -1)
			{
				// Gets entity index from the reference
				int view1 = EntRefToEntIndex(gClientData[i].ViewModels[0]);
				int view2 = EntRefToEntIndex(gClientData[i].ViewModels[1]);

				// Validate fist viewmodel
				if (view1 != -1)
				{
					// Make the first viewmodel visible
					WeaponHDRSetWeaponVisibility(view1, true);
					ToolsUpdateTransmitState(view1);
				}

				// Validate secondary viewmodel
				if (view2 != -1)
				{
					// Make the second viewmodel visible
					WeaponHDRSetWeaponVisibility(view2, false);
					ToolsUpdateTransmitState(view2);
				}
			}
		}
	}
}

/**
 * @brief Creates commands for sdk module.
 **/
void WeaponMODOnCommandInit(/*void*/)
{
	// Hook listeners
	AddCommandListener(WeaponMODOnCommandListened, "buyammo1");
	AddCommandListener(WeaponMODOnCommandListened, "buyammo2");
	AddCommandListener(WeaponMODOnCommandListened, "drop");
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void WeaponMODOnClientInit(int client)
{
	// Hook entity callbacks
	SDKHook(client, SDKHook_WeaponCanUse,     WeaponMODOnCanUse);
	SDKHook(client, SDKHook_WeaponSwitch,     WeaponMODOnDeploy);
	SDKHook(client, SDKHook_WeaponSwitchPost, WeaponMODOnDeployPost);
	SDKHook(client, SDKHook_WeaponEquipPost,  WeaponMODOnEquipPost);
	SDKHook(client, SDKHook_PostThinkPost,    WeaponMODOnAnimationFix);

	// Hook entity callbacks
	DHookEntity(hDHookWeaponCanUse, false, client);
}

/*
 * Weapons main functions.
 */

/**
 * @brief Called when a weapon is created.
 *
 * @param weapon            The weapon index.
 * @param sClassname        The weapon entity.
 **/
void WeaponMODOnEntityCreated(int weapon, const char[] sClassname)
{
	// Validate weapon
	if (sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_') // weapon_
	{
		// Hook weapon callbacks
		SDKHook(weapon, SDKHook_SpawnPost, WeaponMODOnWeaponSpawn);
	}
	// Validate item
	else if (sClassname[0] == 'i' && sClassname[1] == 't') // item_
	{
		// Hook item callbacks
		SDKHook(weapon, SDKHook_SpawnPost, WeaponMODOnItemSpawn);
	}
	// Validate inferno
	else if (sClassname[0] == 'i' && sClassname[1] == 'n' && sClassname[4] == 'r') // inferno
	{
		// Hook weapon callbacks
		SDKHook(weapon, SDKHook_SpawnPost, WeaponMODOnInfernoSpawn);
	}
	else
	{
		// Gets string length
		int iLen = strlen(sClassname) - 11;
		
		// Validate length
		if (iLen > 0)
		{
			// Validate grenade
			if (!strncmp(sClassname[iLen], "_proj", 5, false))
			{
				// Hook grenade callbacks
				SDKHook(weapon, SDKHook_SpawnPost, WeaponMODOnGrenadeSpawn);
			}
		}
	}
}

/**
 * Hook: ItemSpawnPost
 * @brief Item is spawned.
 *
 * @param item              The item index.
 **/
public void WeaponMODOnItemSpawn(int item)
{
	// Resets the weapon id
	WeaponsSetCustomID(item, -1);
}

/**
 * Hook: WeaponSpawnPost
 * @brief Weapon is spawned.
 *
 * @param weapon            The weapon index.
 **/
public void WeaponMODOnWeaponSpawn(int weapon)
{
	// Resets the weapon id
	WeaponsSetCustomID(weapon, -1);
	
	// Hook weapon callbacks
	SDKHook(weapon, SDKHook_ReloadPost, WeaponMODOnWeaponReload);
	
	// Apply fake spawn hook on the next frame
	_exec.WeaponMODOnWeaponSpawnPost(weapon);
}

/**
 * Hook: WeaponSpawnPost
 * @brief Weapon is spawned. *(Post)
 *
 * @param refID             The reference index.
 **/
public void WeaponMODOnWeaponSpawnPost(int refID) 
{
	// Gets weapon index from the reference
	int weapon = EntRefToEntIndex(refID);

	// Validate weapon
	if (weapon != -1)
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Gets weapon clip
			int iClip = WeaponsGetClip(iD);
			if (iClip)
			{/// Sets clip here, because of creating dhook on the next frame after spawn
				SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 
				SetEntProp(weapon, Prop_Send, "m_iClip2", iClip); 
				DHookEntity(hDHookGetMaxClip, false, weapon);
			}

			// Gets weapon ammo
			int iAmmo = WeaponsGetAmmo(iD);
			if (iAmmo)
			{/// Sets ammo here, because of creating dhook on the next frame after spawn
				SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo); 
				SetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount", iAmmo);
				DHookEntity(hDHookGetReserveAmmoMax, false, weapon);
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
	// Gets inferno owner
	int client = ToolsGetOwner(entity);
	
	// Validate owner
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	// Sets weapon id
	WeaponsSetCustomID(entity, gClientData[client].LastGrenade);
}

/**
 * Hook: WeaponSpawnPost
 * @brief Grenade is spawned.
 *
 * @param grenade           The grenade index.
 **/
public void WeaponMODOnGrenadeSpawn(int grenade)
{
	// Resets the grenade id
	WeaponsSetCustomID(grenade, -1);
	
	// Apply fake throw hook on the next frame
	_exec.WeaponMODOnGrenadeSpawnPost(grenade);
}

/**
 * Hook: WeaponSpawnPost
 * @brief Grenade is spawned. *(Post)
 *
 * @param refID             The reference index.
 **/
public void WeaponMODOnGrenadeSpawnPost(int refID) 
{
	// Gets grenade index from the reference
	int grenade = EntRefToEntIndex(refID);

	// Validate grenade
	if (grenade != -1)
	{
		// Gets grenade thrower
		int client = GetEntPropEnt(grenade, Prop_Data, "m_hThrower");
		
		// Validate thrower
		if (!IsPlayerExist(client)) 
		{
			return;
		}
		
		// Sets team index
		SetEntProp(grenade, Prop_Data, "m_iTeamNum", gClientData[client].Zombie ? TEAM_ZOMBIE : TEAM_HUMAN);
		SetEntProp(grenade, Prop_Data, "m_iInitialTeamNum", ToolsGetTeam(client));
		
		// Gets active weapon index from the client
		int weapon = ToolsGetActiveWeapon(client);
		
		// Validate weapon
		if (weapon == -1)
		{
			return;
		}

		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Duplicate index to the projectile for future use
			WeaponsSetCustomID(grenade, iD);

			// Gets weapon def index
			ItemDef iItem = WeaponsGetDefIndex(iD);
			if (IsGrenade(iItem))
			{
				// Apply projectile model
				WeaponHDRSetDroppedModel(grenade, iD, ModelType_Projectile);
			}
			
			// Store the last grenade index
			gClientData[client].LastGrenade = IsFireble(iItem) ? iD : -1;
			
			// Call forward
			gForwardData._OnGrenadeCreated(client, grenade, iD);
		}
	}
}

/**
 * @brief Timer callback, grenade was thrown.
 *
 * @param hTimer            The timer handle.
 * @param hPack             The pack handle.
 **/
/*public Action WeaponMODOnGrenadeThrown(Handle hTimer, DataPack hPack)
{
	/// Extract data from pack and delete it
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	int iD = hPack.ReadCell();
	int iCount = hPack.ReadCell();
	static char sClassname[SMALL_LINE_LENGTH];
	hPack.ReadString(sClassname, sizeof(sClassname));
	///delete hPack; -> TIMER_DATA_HNDL_CLOSE

	// Validate grenade
	int grenade = WeaponsFindByName(client, sClassname);
	if (grenade == -1)
	{
		// Give same weapon
		grenade = WeaponsGive(client, iD);
		if (grenade != -1) 
		{
			// Reduce grenade amount for a new one if they are available
			SetEntProp(grenade, Prop_Send, "m_iPrimaryReserveAmmoCount", iCount); 
			SetEntProp(grenade, Prop_Send, "m_iSecondaryReserveAmmoCount", iCount);
		}
	}
	
	// Destroy timer
	return Plugin_Stop;
}*/

/**
 * Hook: WeaponReloadPost
 * @brief Weapon is reloaded.
 *
 * @param weapon            The weapon index.
 **/
public Action WeaponMODOnWeaponReload(int weapon) 
{
	// Apply fake reload hook on the next frame
	_exec.WeaponMODOnWeaponReloadPost(weapon);
	
	// Allow event
	return Plugin_Continue;
}

/**
 * Hook: WeaponReloadPost
 * @brief Weapon is reloaded. *(Post)
 *
 * @param refID             The reference index.
 **/
public void WeaponMODOnWeaponReloadPost(int refID) 
{
	// Gets weapon index from the reference
	int weapon = EntRefToEntIndex(refID);

	// Validate weapon
	if (weapon != -1)
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Gets weapon owner
			int client = WeaponsGetOwner(weapon);
			
			// Validate owner
			if (!IsPlayerExist(client)) 
			{
				return;
			}
	
			// If custom reload speed exist, then apply it
			float flReload = WeaponsGetReload(iD);
			if (flReload)
			{
				// Resets the instant value 
				if (flReload < 0.0) flReload = 0.0;
			
				// Adds the game time based on the game tick
				flReload += GetGameTime();
		
				// Sets weapon reload time
				WeaponsSetAnimating(weapon, flReload);
				
				// Sets client reload time
				ToolsSetAttack(client, flReload);
			}
			
			// Call forward
			gForwardData._OnWeaponReload(client, weapon, iD);
		}
	}
}

/**
 * Hook: WeaponDrop
 * @brief Player drop any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	// Validate weapon
	if (IsValidEdict(weapon))
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Block drop, if not available
			/*if (!WeaponsIsDrop(iD)) 
			{
				// Validate melee, then remove on force drop
				ItemDef iItem = WeaponsGetDefIndex(iD);
				if (IsMelee(iItem))
				{
					// Forces a player to remove weapon
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "Kill"); /// Destroy
				}
				
				// Block drop
				return Plugin_Handled;
			}*/

			// Apply fake drop hook on the next frame
			_exec.WeaponMODOnWeaponDropPost(weapon);
		}
	}
	
	// Allow drop
	return Plugin_Continue;
}

/**
 * Hook: WeaponDropPost
 * @brief Weapon is dropped. *(Post)
 *
 * @param refID             The reference index.
 **/
public void WeaponMODOnWeaponDropPost(int refID) 
{
	// Gets weapon index from the reference
	int weapon = EntRefToEntIndex(refID);
	
	// Validate weapon
	if (weapon != -1)
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Apply dropped model
			WeaponHDRSetDroppedModel(weapon, iD, ModelType_Drop);

			// Call forward
			gForwardData._OnWeaponDrop(weapon, iD);
		}
	}
}

/**
 * Hook: WeaponCanUse
 * @brief Player pick-up any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public Action WeaponMODOnCanUse(int client, int weapon)
{
	// Validate weapon
	if (IsValidEdict(weapon))
	{
		// Validate access
		if (!WeaponsValidateAccess(client, weapon))
		{
			// Block pickup
			return Plugin_Handled;
		}
	}
	
	// Allow pickup
	return Plugin_Continue;
}

/**
 * @brief Client has been changed class state. *(Post)
 *
 * @param client            The client index.
 **/
void WeaponMODOnClientUpdate(int client)
{
	// Client has swapped to a regular weapon
	gClientData[client].CustomWeapon = -1;
	gClientData[client].IndexWeapon  = -1; /// Only viewmodel identification

	// Gets player viewmodel indexes
	int view1 = WeaponHDRGetPlayerViewModel(client, 0);
	int view2 = WeaponHDRGetPlayerViewModel(client, 1);

	// If a secondary viewmodel doesn't exist, create one
	if (view1 != -1 && view2 == -1)
	{
		// Validate entity
		if ((view2 = CreateEntityByName("predicted_viewmodel")) == -1)
		{
			// Unexpected error, log it
			LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Weapons, "Weapons HDR", "Failed to create secondary viewmodel");
			return;
		}

		// Sets owner to the entity
		SetEntPropEnt(view2, Prop_Send, "m_hOwner", client);
		SetEntProp(view2, Prop_Send, "m_nViewModelIndex", 1);

		// Remove accuracity
		SetEntProp(view2, Prop_Send, "m_bShouldIgnoreOffsetAndAccuracy", true);

		// Spawn the entity into the world
		DispatchSpawn(view2);

		// Sets viewmodel to the owner
		WeaponHDRSetPlayerViewModel(client, 1, view2);
	}

	// Sets entity index to the reference
	gClientData[client].ViewModels[0] = EntIndexToEntRef(view1);
	gClientData[client].ViewModels[1] = EntIndexToEntRef(view2);

	// Gets active weapon index from the client
	int weapon = ToolsGetActiveWeapon(client);

	// Validate weapon
	if (weapon != -1)
	{
		// Switch weapon
		WeaponsSwitch(client, weapon);
	}
}

/**
 * @brief Client has been killed.
 *
 * @param client            The client index.
 **/
void WeaponMODOnClientDeath(int client)
{
	// Gets entity index from the reference
	int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);

	// Validate secondary viewmodel
	if (view2 != -1)
	{
		// Hide the custom viewmodel if the player dies
		WeaponHDRSetWeaponVisibility(view2, false);
		ToolsUpdateTransmitState(view2);
	}

	// Client has swapped to a regular weapon
	gClientData[client].ViewModels[0] = -1;
	gClientData[client].ViewModels[1] = -1;
	gClientData[client].CustomWeapon  = -1;
	gClientData[client].IndexWeapon   = -1; /// Only viewmodel identification
}

/**
 * Hook: WeaponSwitch
 * @brief Player deploy any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public void WeaponMODOnDeploy(int client, int weapon) 
{
	// Block button hook
	gClientData[client].RunCmd = false; /// HACK~HACK
	
	// Gets entity index from the reference
	int view1 = EntRefToEntIndex(gClientData[client].ViewModels[0]);
	int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);

	// Validate viewmodels
	if (view1 == -1 || view2 == -1)
	{
		return;
	}
	
	// Make the first viewmodel invisible
	WeaponHDRSetWeaponVisibility(view1, false);
	ToolsUpdateTransmitState(view1);
	
	// Make the second viewmodel invisible
	WeaponHDRSetWeaponVisibility(view2, false);
	ToolsUpdateTransmitState(view2);

	// Validate weapon
	if (IsValidEdict(weapon))
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Gets last weapon index from the client
			int last = EntRefToEntIndex(gClientData[client].LastWeapon);

			// Validate last weapon
			if (last != -1)
			{
				// Validate last index
				int iL = WeaponsGetCustomID(last);
				if (iL != -1 && iD != iL)
				{
					// Call forward
					gForwardData._OnWeaponHolster(client, last, iL);
				}
			}
			
			// Sets new weapon index to the client
			gClientData[client].LastWeapon = EntIndexToEntRef(weapon);
			
			// If custom deploy speed exist, then apply it
			float flDeploy = WeaponsGetDeploy(iD);
			if (flDeploy)
			{
				// Resets the instant value 
				if (flDeploy < 0.0) flDeploy = 0.0;
		
				// Adds the game time based on the game tick
				flDeploy += GetGameTime();
		
				// Sets weapon deploy time
				WeaponsSetAnimating(weapon, flDeploy);
				
				// Sets client deploy time
				ToolsSetAttack(client, flDeploy);
			}
			
			// Gets weapon def index
			ItemDef iItem = WeaponsGetDefIndex(iD);

			// If view/world model exist, then set them
			if (WeaponsGetModelViewID(iD) || WeaponsGetModelWorldID(iD) || ((IsMelee(iItem) || IsGrenade(iItem)) && gClientData[client].Zombie))
			{
				// Client has swapped to a custom weapon
				gClientData[client].SwapWeapon   = -1;
				gClientData[client].CustomWeapon = weapon;
				gClientData[client].IndexWeapon  = iD; /// Only viewmodel identification
				return;
			}
		}
	}

	// Client has swapped to a regular weapon
	gClientData[client].CustomWeapon = -1;
	gClientData[client].IndexWeapon  = -1; /// Only viewmodel identification
	
	// Gets class arm model
	static char sArm[PLATFORM_LINE_LENGTH];
	ClassGetArmModel(gClientData[client].Class, sArm, sizeof(sArm));
	
	// Apply arm model
	if (hasLength(sArm)) ToolsSetArm(client, sArm);
}

/**
 * Hook: WeaponSwitchPost
 * @brief Player deploy any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public void WeaponMODOnDeployPost(int client, int weapon) 
{
	// Gets entity index from the reference
	int view1 = EntRefToEntIndex(gClientData[client].ViewModels[0]);
	int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);

	// Validate viewmodels
	if (view1 == -1 || view2 == -1)
	{
		return;
	}
	
	// Validate weapon
	if (!IsValidEdict(weapon))
	{
		return;
	}

	// Weapon has not changed since last pre hook
	if (weapon == gClientData[client].CustomWeapon)
	{
		// Initialize variables
		int iModel; static char sModel[PLATFORM_LINE_LENGTH]; sModel[0] = NULL_STRING[0];

		// Gets weapon id from the reference
		int iD = gClientData[client].IndexWeapon; /// Only viewmodel identification
		
		// Gets weapon def index
		ItemDef iItem = WeaponsGetDefIndex(iD);
		
		// Validate melee
		if (IsMelee(iItem))
		{
			// Gets claw model
			ClassGetClawModel(gClientData[client].Class, sModel, sizeof(sModel));
			
			// Update model index
			iModel = ClassGetClawID(gClientData[client].Class);
		}
		// Validate grenade
		else if (IsGrenade(iItem))
		{
			// Gets grenade model
			ClassGetGrenadeModel(gClientData[client].Class, sModel, sizeof(sModel));
			
			// Update model index
			iModel = ClassGetGrenadeID(gClientData[client].Class);
		}

		 // Gets model index
		if (!iModel) iModel = WeaponsGetModelViewID(iD);
		
		// Gets weapon viewmodel
		if (!hasLength(sModel)) WeaponsGetModelView(iD, sModel, sizeof(sModel));      

		// If viewmodel exist, then apply it
		if (iModel)
		{
			// Make the first viewmodel invisible
			WeaponHDRSetWeaponVisibility(view1, false);
			ToolsUpdateTransmitState(view1);
			
			// Make the second viewmodel visible
			WeaponHDRSetWeaponVisibility(view2, true);
			ToolsUpdateTransmitState(view2);

			// If the sequence for the weapon didn't build yet
			if (WeaponsGetSequenceCount(iD) == -1)
			{
				// Gets sequence amount from a weapon entity
				int iSequenceCount = ToolsGetSequenceCount(weapon);

				// Validate count
				if (iSequenceCount)
				{
					// Initialize the sequence array
					int iSequences[WEAPONS_SEQUENCE_MAX];

					// Validate amount
					if (iSequenceCount < WEAPONS_SEQUENCE_MAX)
					{
						// Build the sequence array
						WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon);
						
						// Update the sequence array
						WeaponsSetSequenceCount(iD, iSequenceCount);
						WeaponsSetSequenceSwap(iD, iSequences, sizeof(iSequences));
					}
					else
					{
						// Unexpected error, log it
						LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Weapons, "Weapons HDR", "View model \"%s\" is having too many sequences! (Max %d, is %d) - Increase value of WEAPONS_SEQUENCE_MAX in plugin", sModel, WEAPONS_SEQUENCE_MAX, iSequenceCount);
					}
				}
				else
				{
					// Remove swapped weapon
					WeaponsClearSequenceSwap(iD);
					
					// Unexpected error, log it
					LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Weapons, "Weapons HDR", "Failed to get sequence count for weapon using model \"%s\" - Animations may not work as expected", sModel);
				}
			}
			
			// Gets body/skin index of a class
			int iBody = ClassGetBody(gClientData[client].Class);
			int iSkin = ClassGetSkin(gClientData[client].Class);

			// Sets model/body/skin index for viewmodel
			ToolsSetModelIndex(view2, iModel);
			ToolsSetTextures(view2, (iBody != -1) ? iBody : WeaponsGetModelBody(iD, ModelType_View), (iSkin != -1) ? iSkin : WeaponsGetModelSkin(iD, ModelType_View));
			
			// Update the animation interval delay for second viewmodel 
			SetEntPropFloat(view2, Prop_Send, "m_flPlaybackRate", GetEntPropFloat(view1, Prop_Send, "m_flPlaybackRate"));

			// Creates a toggle model
			WeaponHDRToggleViewModel(client, view2, iD);
			
			// Resets the sequence parity
			gClientData[client].LastSequenceParity = -1;
		}
	
		// If worldmodel exist, then apply it
		if (WeaponsGetModelWorldID(iD) || (gClientData[client].Zombie && IsMelee(iItem)))
		{
			WeaponHDRSetPlayerWorldModel(weapon, iD, ModelType_World);
		}
		
		// Validate client
		if (IsPlayerExist(client))
		{
			// Call forward
			gForwardData._OnWeaponDeploy(client, weapon, iD);
		}

		// Allow button hook
		gClientData[client].RunCmd = true; /// HACK~HACK
		
		// If model was found, then stop
		if (iModel && hasLength(sModel))
		{
			return;
		}
	}

	// Make the first viewmodel visible
	WeaponHDRSetWeaponVisibility(view1, true);
	ToolsUpdateTransmitState(view1);

	// Make the second viewmodel invisible
	WeaponHDRSetWeaponVisibility(view2, false);
	ToolsUpdateTransmitState(view2);

	// Client has swapped to a regular weapon
	gClientData[client].CustomWeapon = -1;
	gClientData[client].IndexWeapon  = -1; /// Only viewmodel identification

	// Allow button hook
	gClientData[client].RunCmd = true; // In case when viewmodel wasn't detected
}

/**
 * Hook: WeaponEquipPost
 * @brief Player equiped by any weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
public void WeaponMODOnEquipPost(int client, int weapon) 
{
	// Validate weapon
	if (IsValidEdict(weapon))
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)    
		{
			// Validate knife
			ItemDef iItem = WeaponsGetDefIndex(iD);
			if (IsKnife(iItem))
			{
				// Store the client cache
				gClientData[client].LastKnife = EntIndexToEntRef(weapon);
			}
		}
	}
}

/**
 * Hook: PostThinkPost
 * @brief Player hold any weapon.
 *
 * @param client            The client index.
 **/
public void WeaponMODOnAnimationFix(int client) 
{
	// Sets current addons
	WeaponAttachSetAddons(client); /// Back weapon models
	
	// Validate weapon
	if (gClientData[client].CustomWeapon == -1) /// Optimization for frame check
	{
		return;
	}

	// Gets entity index from the reference
	int view1 = EntRefToEntIndex(gClientData[client].ViewModels[0]);
	int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);

	// Validate viewmodels
	if (view1 == -1 || view2 == -1)
	{
		return;
	}

	// Gets sequence index
	int iSequence = GetEntProp(view1, Prop_Send, "m_nSequence");

	// Gets sequence parity index
	int sequenceParity = GetEntProp(view1, Prop_Send, "m_nNewSequenceParity");

	// Sequence has not changed since last post hook
	if (iSequence == gClientData[client].LastSequence)
	{
		// Skip on weapon switch
		if (gClientData[client].LastSequenceParity != -1)
		{
			// Skip if sequence hasn't finished
			if (sequenceParity == gClientData[client].LastSequenceParity)
			{
				return;
			}

			// Gets weapon id from the reference
			int iD = gClientData[client].IndexWeapon; /// Only viewmodel identification
			int swapSequence = WeaponsGetSequenceSwap(iD, iSequence);
			
			// Validate swap sequence
			if (swapSequence != -1)
			{
				// Play the swaped sequence
				SetEntProp(view1, Prop_Send, "m_nSequence", swapSequence);
				SetEntProp(view2, Prop_Send, "m_nSequence", swapSequence);

				// Update the sequence for next check
				gClientData[client].LastSequence = swapSequence;
			}
			else
			{
				#define ACT_VM_IDLE 185
		
				// Stop toggling during the idle animation
				if (ToolsGetSequenceActivity(view1, iSequence) != ACT_VM_IDLE)
				{
					// Creates a toggle model
					WeaponHDRToggleViewModel(client, view2, iD);
				}
			}
		}
	}
	else
	{
		// Sets new sequence
		SetEntProp(view2, Prop_Send, "m_nSequence", iSequence);
		gClientData[client].LastSequence = iSequence;
	}
	
	// Update the sequence parity for next check
	gClientData[client].LastSequenceParity = sequenceParity;
}

/**
 * @brief Weapon has been fired.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
void WeaponMODOnFire(int client, int weapon) 
{
	// Validate custom index
	int iD = WeaponsGetCustomID(weapon);
	if (iD != -1)    
	{
		// Gets game time based on the game tick
		float flCurrentTime = GetGameTime();

		// If custom fire speed exist, then apply it
		float flSpeed = WeaponsGetSpeed(iD);
		if (flSpeed)
		{
			// Resets the instant value
			if (flSpeed < 0.0) flSpeed = 0.0;
				
			// Adds the game time based on the game tick
			flSpeed += flCurrentTime;
	
			// Sets weapon attack time
			WeaponsSetAnimating(weapon, flSpeed);
			
			// Sets client attack time
			ToolsSetAttack(client, flSpeed);
		}

		// If viewmodel exist, then create muzzle smoke
		if (WeaponsGetModelViewID(iD))
		{
			// Gets entity index from the reference
			int view2 = EntRefToEntIndex(gClientData[client].ViewModels[1]);
			///int world = WeaponHDRGetPlayerWorldModel(weapon);
			
			// Validate models
			if (view2 == -1/* || world == -1*/)
			{
				return;
			}

			// If weapon without any type of ammo, then stop
			if (GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") == -1)
			{
				return;
			}

			// Create muzzle and shell effect
			static char sName[NORMAL_LINE_LENGTH];
			WeaponsGetModelMuzzle(iD, sName, sizeof(sName));
			if (hasLength(sName)) ParticlesCreate(view2, "1", sName, 0.1);
			WeaponsGetModelShell(iD, sName, sizeof(sName));
			if (hasLength(sName)) ParticlesCreate(view2, "2", sName, 0.1);
			
			// Validate weapon heat delay
			float flDelay = WeaponsGetModelHeat(iD);
			if (flDelay)
			{
				// Initialize variables
				static float flHeatDelay[MAXPLAYERS+1]; static float flSmoke[MAXPLAYERS+1];

				// Calculate the expected heat amount
				float flHeat = ((flCurrentTime - GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime")) * -0.5) + flHeatDelay[client];

				// This value is set specifically for each weapon
				flHeat += flDelay;
				
				// Resets the delay
				if (flHeat < 0.0) flHeat = 0.0;

				// Validate delay
				if (flHeat > 1.0)
				{
					// Validate heat
					if (flCurrentTime - flSmoke[client] > 1.0)
					{
						// Creates a smoke effect
						ParticlesCreate(view2, "1", "weapon_muzzle_smoke", 4.5); /// Max duration 
						flSmoke[client] = flCurrentTime; /// 'DestroyImmediately/'Kill' not work for smoke!
					}
					
					// Resets delay
					flHeat = 0.0;
				}

				// Update the heat delay
				flHeatDelay[client] = flHeat;
			}
		}
		
		// If weapon without any type of ammo, then stop
		int iType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		if (iType != -1) 
		{
			// Validate grenade
			ItemDef iItem = WeaponsGetDefIndex(iD);
			/*if (IsGrenade(iItem))
			{
				// Validate count
				int iCount = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount") - 1;
				if (iCount > 0)
				{
					// Gets entity classname
					static char sClassname[SMALL_LINE_LENGTH];
					GetEdictClassname(weapon, sClassname, sizeof(sClassname));
			
					// For giving the next grenade
					DataPack hPack = new DataPack();
					/// Initialize pack
					hPack.WriteCell(GetClientUserId(client));
					hPack.WriteCell(iD);
					hPack.WriteCell(iCount);
					hPack.WriteString(sClassname);
		
					// Create timer for a grenade throw hook
					CreateTimer(2.0, WeaponMODOnGrenadeThrown, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
				}
			}
			// Validate weapon
			else*/
			if (iItem != ItemDef_Taser)
			{
				// Validate class ammunition mode
				switch (ClassGetAmmunition(gClientData[client].Class))
				{
					case 0 : return;
					case 1 : { SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", GetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount")); }
					case 2 : { SetEntProp(weapon, Prop_Send, "m_iClip1", GetEntProp(weapon, Prop_Send, "m_iClip1") + 1); } 
				}
			}
		}
		
		// Call forward
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
	// Validate custom index
	int iD = WeaponsGetCustomID(weapon);
	if (iD != -1)    
	{
		// Call forward
		gForwardData._OnWeaponBullet(client, vBullet, weapon, iD);
	}
}
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
	// Validate custom index
	static int iD; iD = WeaponsGetCustomID(weapon); /** static for runcmd **/
	if (iD != -1)    
	{
		// Call forward
		Action hResult;
		gForwardData._OnWeaponRunCmd(client, iButtons, iLastButtons, weapon, iD, hResult);
		return hResult;
	}
	
	// Return on the unsuccess
	return Plugin_Continue;
}

/**
 * @brief Weapon has been shoot.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
Action WeaponMODOnShoot(int client, int weapon) 
{ 
	// Validate custom index
	int iD = WeaponsGetCustomID(weapon);
	if (iD != -1)    
	{
		// Validate broadcast
		Action hResult = SoundsOnClientShoot(client, iD);

		// Call forward
		gForwardData._OnWeaponShoot(client, weapon, iD);

		// Block broadcast
		return hResult;
	}
	
	// Allow broadcast
	return Plugin_Continue;
}

/**
 * @brief Weapon has been used.
 *
 * @param client            The client index.
 **/
void WeaponMODOnUse(int client)
{
	// Find the entity a client is aiming at
	int entity = GetClientAimTarget(client, false);
	
	// Validate entity
	if (entity != -1)
	{
		// Gets entity classname
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(entity, sClassname, sizeof(sClassname));

		// Validate melee
		if (sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_' && // weapon_
		  (sClassname[7] == 'k' || // knife
		  (sClassname[7] == 'm' && sClassname[8] == 'e') ||  // melee
		  (sClassname[7] == 'f' && sClassname[9] == 's'))) // fists
		{
			// If not available, then stop
			if (!WeaponsValidateAccess(client, entity))
			{
				return;
			}
			
			// If too far, then stop
			if (UTIL_GetDistanceBetween(client, entity) > gCvarList.WEAPON_PICKUP_RANGE.FloatValue) 
			{
				return;
			}
			
			// Replace weapon
			WeaponsEquip(client, entity, -1); /// id not used
		}
	}
}

/**
 * @brief Weapon has been switch by hostage.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 **/
void WeaponMODOnHostage(int client) 
{
	// Prevent the viewmodel from being removed
	WeaponHDRSetPlayerViewModel(client, 1, -1);

	// Apply fake hostage follow hook on the next frame
	_call.WeaponMODOnHostagePost(client);
}
	
/**
 * @brief Weapon has been switch by hostage. *(Post)
 *
 * @param userID            The user id.
 **/
public void WeaponMODOnHostagePost(int userID) 
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Validate client
	if (client)
	{
		// Gets weapon id from the reference
		int iD = gClientData[client].IndexWeapon; /// Only viewmodel identification

		// Validate id
		if (iD != -1)
		{
			// Gets second viewmodel
			int view2 = WeaponHDRGetPlayerViewModel(client, 1);

			// Remove the viewmodel created by the game
			if (view2 != -1)
			{
				AcceptEntityInput(view2, "Kill"); /// Destroy
			}

			// Resets the viewmodel
			WeaponHDRSetPlayerViewModel(client, 1, EntRefToEntIndex(gClientData[client].ViewModels[1]));
		}
	}
}

/**
 * Listener command callback (buyammo1, buyammo2, drop)
 * @brief Buying of the ammunition or for dropping any weapon.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action WeaponMODOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	// Validate client
	if (IsPlayerExist(client))
	{
		// Gets active weapon index from the client
		int weapon = ToolsGetActiveWeapon(client);

		// Validate weapon
		if (weapon != -1)
		{
			// Validate custom index
			int iD = WeaponsGetCustomID(weapon);
			if (iD != -1)
			{
				// Switches client commands
				switch (commandMsg[0])
				{
					// Buying ammunition
					case 'b' :
					{
						// Validate class ammunition mode
						switch (ClassGetAmmunition(gClientData[client].Class))
						{
							case 0  : { /* < empty statement > */ }
							default : return Plugin_Continue;
						}
				
						// If weapon without any type of ammo, then stop
						if (GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") == -1)
						{
							return Plugin_Continue;
						}

						// If cost is disabled, then stop
						int iCost = WeaponsGetAmmunition(iD);
						if (!iCost)
						{
							return Plugin_Continue;
						}
						
						// Validate ammunition cost
						if (gClientData[client].Money < iCost)
						{
							// Show block info
							TranslationPrintHintText(client, "buying ammunition block");
							
							// Emit error sound
							ClientCommand(client, "play buttons/button10.wav");    
							return Plugin_Continue;
						}
				
						// Gets current/max reverse ammo
						int iAmmo = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
						int iMaxAmmo = GetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount");
						
						// Validate amount
						if (iAmmo < iMaxAmmo)
						{
							// Generate amount
							iAmmo += GetEntProp(weapon, Prop_Send, "m_iClip2"); if (!iAmmo) /*~*/ iAmmo++;

							// Gives ammo of a certain type to a weapon
							SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", (iAmmo <= iMaxAmmo) ? iAmmo : iMaxAmmo);

							// Remove money
							AccountSetClientCash(client, gClientData[client].Money - iCost);

							// Forward event to modules
							SoundsOnClientAmmunition(client);
						}
					}
					
					// Dropping weapon        
					case 'd' :
					{
						// Block drop, if not available
						if (!WeaponsIsDrop(iD)) 
						{
							return Plugin_Handled;
						}

						// Validate knife
						ItemDef iItem = WeaponsGetDefIndex(iD);
						if (IsKnife(iItem))
						{
							// Drop weapon
							WeaponsDrop(client, weapon);

							// Validate id
							if (iD == gServerData.Melee)
							{
								return Plugin_Handled;
							}
							
							// Give default melee
							if (WeaponsGive(client, gServerData.Melee) == -1)
							{
								// Try switching to any available weapon
								int iPrimary = GetPlayerWeaponSlot(client, view_as<int>(SlotType_Primary));
								int iSecondary = GetPlayerWeaponSlot(client, view_as<int>(SlotType_Secondary));
								weapon = (iPrimary != -1) ? iPrimary : iSecondary;

								// Validate weapon
								if (weapon != -1) 
								{
									// Switch weapon
									WeaponsSwitch(client, weapon);
								}
							}
							
							// Block commands
							return Plugin_Handled;
						}
						// Validate shield
						else if (iItem == ItemDef_Shield)
						{
							// Drop weapon
							WeaponsDrop(client, weapon);

							// Block commands
							return Plugin_Handled;
						}
						else
						{
							// If help messages enabled, then show info
							if (gCvarList.MESSAGES_WEAPON_DROP.BoolValue && gCvarList.GAMEMODE_WEAPONS_REMOVE.BoolValue && gServerData.RoundNew)
							{
								// Show remove info
								TranslationPrintToChat(client, "drop info");
							}
						}
					}
				}
			}
		}
	}

	// Allow commands
	return Plugin_Continue;
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
	// Validate weapon
	if (IsValidEdict(weapon))
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Gets weapon clip
			int iClip = WeaponsGetClip(iD);
			if (iClip)
			{
				DHookSetReturn(hReturn, iClip);
				return MRES_Override;
			}
		}
	}

	// Skip the hook
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
	// Validate weapon
	if (IsValidEdict(weapon))
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Gets weapon ammo
			int iAmmo = WeaponsGetAmmo(iD);
			if (iAmmo)
			{
				DHookSetReturn(hReturn, iAmmo);
				return MRES_Override;
			}
		}
	}
	
	// Skip the hook
	return MRES_Ignored;
}

/**
 * DHook: Allow to pick-up some weapons.
 * @note bool CBasePlayer::Weapon_CanUse(CBaseCombatWeapon *)
 *
 * @param hReturn           Handle to return structure.
 * @param hParams           Handle with parameters.
 **/
public MRESReturn WeaponDHookOnCanUse(Handle hReturn, Handle hParams)
{
	// Gets real weapon index from parameters
	int weapon = DHookGetParam(hParams, 1);
	
	// Validate weapon
	if (IsValidEdict(weapon))
	{
		// Validate custom index
		int iD = WeaponsGetCustomID(weapon);
		if (iD != -1)
		{
			// Validate knife/c4
			ItemDef iItem = WeaponsGetDefIndex(iD);
			if (IsKnife(iItem) || iItem == ItemDef_C4)
			{
				DHookSetReturn(hReturn, true);
				return MRES_Override;
			}
		}
	}
	
	// Skip the hook
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
	// Gets model from parameters
	static char sPath[NORMAL_LINE_LENGTH];
	DHookGetParamString(hParams, 1, sPath, sizeof(sPath));
	
	// Block this model for be precached
	if (!strncmp(sPath, "models/weapons/v_models/arms/glove_hardknuckle/", 47, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	// Skip the hook
	return MRES_Ignored;
}
