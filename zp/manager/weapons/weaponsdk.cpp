/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          weaponsdk.cpp
 *  Type:          Module
 *  Description:   Weapon SDK functions.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin). Regards to Andersso
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
 * @section Number of valid slots.
 **/
enum SlotType
{ 
    SlotType_Invalid = -1,        /** Used as return value when a slot doens't exist. */
    
    SlotType_Primary,             /** Primary slot */
    SlotType_Secondary,           /** Secondary slot */
    SlotType_Melee,               /** Melee slot */
    SlotType_Equipment,           /** Equipment slot */  
    SlotType_C4,                  /** C4 slot */  
};
/**
 * @endsection
 **/
 
/**
 * @section Number of valid menus.
 **/
enum MenuType
{
     MenuType_Invisible,          /**  Used as return value when a menu doens't exist. */
     
     MenuType_Pistols,            /**  Pistol menu */
     MenuType_Shotguns,           /**  Shotgun menu */
     MenuType_Rifles,             /**  Rifle menu */
     MenuType_Snipers,            /**  Sniper menu */
     MenuType_Machineguns,        /**  Machineguns menu */
     MenuType_Knifes,             /**  Knife menu */
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
Handle hSDKCallRemoveAllItems;
Handle hSDKCallWeaponSwitch;
Handle hSDKCallGetMaxClip1;
Handle hSDKCallGetReserveAmmoMax;

#if defined USE_DHOOKS
/**
 * Variables to store DHook calls handlers.
 **/
Handle hDHookGetMaxClip;
Handle hDHookGetReserveAmmoMax;

/**
 * Variables to store dynamic DHook offsets.
 **/
int DHook_GetMaxClip1;
int DHook_GetReserveAmmoMax;
#endif

/**
 * @brief Initialize the main virtual/dynamic offsets for the weapon SDK/DHook system.
 **/
void WeaponSDKOnInit(/*void*/) /// @link https://www.unknowncheats.me/forum/counterstrike-global-offensive/152722-dumping-datamap_t.html
{                             // C_BaseFlex -> C_EconEntity -> C_BaseCombatWeapon -> C_WeaponCSBase -> C_BaseCSGrenade
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "Weapon_RemoveAllItems");

    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    
    // Validate call
    if(!(hSDKCallRemoveAllItems = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBasePlayer::RemoveAllItems\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/

    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gServerData.SDKHooks, SDKConf_Virtual, "Weapon_Switch");
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if(!(hSDKCallWeaponSwitch = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBasePlayer::Weapon_Switch\". Update \"SourceMod\"");
        return;
    }

    /*_________________________________________________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "Weapon_GetMaxClip1");
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue); 
    
    // Validate call
    if(!(hSDKCallGetMaxClip1 = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseCombatWeapon::GetMaxClip1\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "Weapon_GetReserveAmmoMax");
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue); 
    
    // Validate call
    if(!(hSDKCallGetReserveAmmoMax = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseCombatWeapon::GetReserveAmmoMax\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/

    // Load weapon offsets
    fnInitSendPropOffset(g_iOffset_WeaponOwner, "CBaseCombatWeapon", "m_hOwner");
    fnInitSendPropOffset(g_iOffset_WeaponWorldModel, "CBaseCombatWeapon", "m_hWeaponWorldModel");
    fnInitSendPropOffset(g_iOffset_WeaponBody, "CBaseCombatWeapon", "m_nBody");
    fnInitSendPropOffset(g_iOffset_WeaponSkin, "CBaseCombatWeapon", "m_nSkin");
    fnInitSendPropOffset(g_iOffset_WeaponAmmoType, "CBaseCombatWeapon", "m_iPrimaryAmmoType");
    fnInitSendPropOffset(g_iOffset_WeaponClip1, "CBaseCombatWeapon", "m_iClip1");
    fnInitSendPropOffset(g_iOffset_WeaponReserve1, "CBaseCombatWeapon", "m_iPrimaryReserveAmmoCount");
    fnInitSendPropOffset(g_iOffset_WeaponReserve2, "CBaseCombatWeapon", "m_iSecondaryReserveAmmoCount");
    fnInitSendPropOffset(g_iOffset_WeaponPrimaryAttack, "CBaseCombatWeapon", "m_flNextPrimaryAttack");
    fnInitSendPropOffset(g_iOffset_WeaponSecondaryAttack, "CBaseCombatWeapon", "m_flNextSecondaryAttack");
    fnInitSendPropOffset(g_iOffset_WeaponIdle, "CBaseCombatWeapon", "m_flTimeWeaponIdle");
    fnInitSendPropOffset(g_iOffset_CharacterWeapons, "CBaseCombatCharacter", "m_hMyWeapons");
    fnInitSendPropOffset(g_iOffset_GrenadeThrower, "CBaseGrenade", "m_hThrower");
    fnInitSendPropOffset(g_iOffset_PlayerViewModel, "CBasePlayer", "m_hViewModel");
    fnInitSendPropOffset(g_iOffset_ViewModelOwner, "CBaseViewModel", "m_hOwner");
    fnInitSendPropOffset(g_iOffset_ViewModelWeapon, "CBaseViewModel", "m_hWeapon");
    fnInitSendPropOffset(g_iOffset_ViewModelSequence, "CBaseViewModel", "m_nSequence");
    fnInitSendPropOffset(g_iOffset_ViewModelPlaybackRate, "CBaseViewModel", "m_flPlaybackRate");
    fnInitSendPropOffset(g_iOffset_ViewModelIndex, "CBaseViewModel", "m_nViewModelIndex");
    fnInitSendPropOffset(g_iOffset_ViewModelIgnoreOffsAcc, "CBaseViewModel", "m_bShouldIgnoreOffsetAndAccuracy");
    fnInitSendPropOffset(g_iOffset_EconItemDefinitionIndex, "CEconEntity", "m_iItemDefinitionIndex");
    fnInitSendPropOffset(g_iOffset_NewSequenceParity, "CBaseAnimating", "m_nNewSequenceParity");
    fnInitSendPropOffset(g_iOffset_LastShotTime, "CWeaponCSBase", "m_fLastShotTime");

    /*_________________________________________________________________________________________________________________________________________*/
    
    #if defined USE_DHOOKS
    // Load other offsets
    fnInitGameConfOffset(gServerData.Config, DHook_GetMaxClip1, "Weapon_GetMaxClip1");
    fnInitGameConfOffset(gServerData.Config, DHook_GetReserveAmmoMax, "Weapon_GetReserveAmmoMax");

    /// CBaseCombatWeapon::GetMaxClip1(CBaseCombatWeapon *this)
    hDHookGetMaxClip = DHookCreate(DHook_GetMaxClip1, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, WeaponDHookOnGetMaxClip1);
    
    /// CBaseCombatWeapon::GetReserveAmmoMax(AmmoPosition_t)
    hDHookGetReserveAmmoMax = DHookCreate(DHook_GetReserveAmmoMax, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, WeaponDHookOnGetReverseMax);
    DHookAddParam(hDHookGetReserveAmmoMax, HookParamType_Unknown);
    #endif
}

/**
 * @brief Restore weapon models during the unloading.
 **/
void WeaponSDKOnUnload(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i))
        {
            // Validate weapon
            if(gClientData[i].CustomWeapon != INVALID_ENT_REFERENCE)
            {
                // Gets entity index from the reference
                int viewModel1 = EntRefToEntIndex(gClientData[i].ViewModels[0]);
                int viewModel2 = EntRefToEntIndex(gClientData[i].ViewModels[1]);

                // Validate fist viewmodel
                if(viewModel1 != INVALID_ENT_REFERENCE)
                {
                    // Make the first viewmodel visible
                    WeaponHDRSetEntityVisibility(viewModel1, true);
                    ToolsUpdateTransmitState(viewModel1);
                }

                // Validate secondary viewmodel
                if(viewModel2 != INVALID_ENT_REFERENCE)
                {
                    // Make the second viewmodel visible
                    WeaponHDRSetEntityVisibility(viewModel2, false);
                    ToolsUpdateTransmitState(viewModel2);
                }
            }
        }
    }
}

/**
 * @brief Creates commands for sdk module.
 **/
void WeaponSDKOnCommandInit(/*void*/)
{
    // Hook listeners
    AddCommandListener(WeaponSDKOnCommandListened, "buyammo1");
    AddCommandListener(WeaponSDKOnCommandListened, "buyammo2");
}

/**
 * @brief Client is joining the server.
 * 
 * @param clientIndex       The client index.  
 **/
void WeaponSDKOnClientInit(const int clientIndex)
{
    // Hook entity callbacks
    SDKHook(clientIndex, SDKHook_WeaponCanUse,      WeaponSDKOnCanUse);
    SDKHook(clientIndex, SDKHook_WeaponSwitch,      WeaponSDKOnDeploy);
    SDKHook(clientIndex, SDKHook_WeaponSwitchPost,  WeaponSDKOnDeployPost);
    SDKHook(clientIndex, SDKHook_PostThinkPost,     WeaponSDKOnAnimationFix);
}

/*
 * Weapons main functions.
 */

/**
 * @brief Called when a weapon is created.
 *
 * @param weaponIndex       The weapon index.
 * @param sClassname        The weapon entity.
 **/
void WeaponSDKOnEntityCreated(const int weaponIndex, const char[] sClassname)
{
    // Validate weapon
    if(sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_')
    {
        // Hook weapon callbacks
        SDKHook(weaponIndex, SDKHook_ReloadPost, WeaponSDKOnWeaponReload);
        SDKHook(weaponIndex, SDKHook_SpawnPost,  WeaponSDKOnWeaponSpawn);
    }
    // Validate item
    else if(sClassname[0] == 'i' && sClassname[1] == 't')
    {
        // Hook item callbacks
        SDKHook(weaponIndex, SDKHook_SpawnPost, WeaponSDKOnItemSpawn);
    }
    else
    {
        // Gets string length
        int iLen = strlen(sClassname) - 11;
        
        // Validate length
        if(iLen > 0)
        {
            // Validate grenade
            if(!strncmp(sClassname[iLen], "_proj", 5, false))
            {
                // Hook grenade callbacks
                SDKHook(weaponIndex, SDKHook_SpawnPost, WeaponSDKOnGrenadeSpawn);
            }
        }
    }
}

/**
 * Hook: WeaponReloadPost
 * @brief Weapon is reloaded.
 *
 * @param weaponIndex       The weapon index.
 **/
public Action WeaponSDKOnWeaponReload(const int weaponIndex) 
{
    // Apply fake reload hook on the next frame
    RequestFrame(view_as<RequestFrameCallback>(WeaponSDKOnWeaponReloadPost), EntIndexToEntRef(weaponIndex));
}

/**
 * Hook: WeaponReloadPost
 * @brief Weapon is reloaded. *(Post)
 *
 * @param referenceIndex    The reference index.
 **/
public void WeaponSDKOnWeaponReloadPost(const int referenceIndex) 
{
    // Gets the weapon index from the reference
    int weaponIndex = EntRefToEntIndex(referenceIndex);

    // Validate weapon
    if(weaponIndex != INVALID_ENT_REFERENCE)
    {
        // Validate custom index
        int iD = WeaponsGetCustomID(weaponIndex);
        if(iD != INVALID_ENT_REFERENCE)
        {
            // Gets weapon owner
            int clientIndex = WeaponsGetOwner(weaponIndex);
            
            // Validate owner
            if(!IsPlayerExist(clientIndex)) 
            {
                return;
            }
    
            // If custom reload speed exist, then apply it
            float flReload = WeaponsGetReload(iD);
            if(flReload)
            {
                // Adds the game time based on the game tick
                flReload += GetGameTime();
        
                // Sets reload time
                WeaponsSetAnimating(weaponIndex, flReload);
            }
            
            // Call forward
            gForwardData._OnWeaponReload(clientIndex, weaponIndex, iD);
        }
    }
}

/**
 * Hook: ItemSpawnPost
 * @brief Item is spawned.
 *
 * @param itemIndex         The item index.
 **/
public void WeaponSDKOnItemSpawn(const int itemIndex)
{
    // Validate item
    if(IsValidEdict(itemIndex)) 
    {
        // Reset the weapon id
        WeaponsSetCustomID(itemIndex, INVALID_ENT_REFERENCE);
    }
}

/**
 * Hook: WeaponSpawnPost
 * @brief Weapon is spawned.
 *
 * @param weaponIndex       The weapon index.
 **/
public void WeaponSDKOnWeaponSpawn(const int weaponIndex)
{
    // Validate weapon
    if(IsValidEdict(weaponIndex)) 
    {
        // Reset the weapon id
        WeaponsSetCustomID(weaponIndex, INVALID_ENT_REFERENCE);
    }
    
    #if defined USE_DHOOKS
        // Apply fake spawn hook on the next frame
        RequestFrame(view_as<RequestFrameCallback>(WeaponSDKOnWeaponSpawnPost), EntIndexToEntRef(weaponIndex));
    #endif
}

/**
 * Hook: WeaponSpawnPost
 * @brief Weapon is spawned. *(Post)
 *
 * @param referenceIndex    The reference index.
 **/
#if defined USE_DHOOKS
public void WeaponSDKOnWeaponSpawnPost(const int referenceIndex) 
{
    // Gets the weapon index from the reference
    int weaponIndex = EntRefToEntIndex(referenceIndex);

    // Validate weapon
    if(weaponIndex != INVALID_ENT_REFERENCE)
    {
        // Validate custom index
        int iD = WeaponsGetCustomID(weaponIndex);
        if(iD != INVALID_ENT_REFERENCE)
        {
            // Gets weapon clip
            int iClip = WeaponsGetClip(iD);
            if(iClip)
            {/// Set clip here, because of creating dhook on the next frame after spawn
                SetEntData(weaponIndex, g_iOffset_WeaponClip1, iClip, _, true); 
                DHookEntity(hDHookGetMaxClip, false, weaponIndex);
            }

            // Gets weapon ammo
            int iAmmo = WeaponsGetAmmo(iD);
            if(iAmmo)
            {/// Set ammo here, because of creating dhook on the next frame after spawn
                SetEntData(weaponIndex, g_iOffset_WeaponReserve1, iAmmo, _, true); 
                DHookEntity(hDHookGetReserveAmmoMax, false, weaponIndex);
            }
        }
    }
}
#endif

/**
 * Hook: WeaponSpawnPost
 * @brief Grenade is spawned.
 *
 * @param grenadeIndex      The grenade index.
 **/
public void WeaponSDKOnGrenadeSpawn(const int grenadeIndex)
{
    // Validate grenade
    if(IsValidEdict(grenadeIndex)) 
    {
        // Reset the grenade id
        WeaponsSetCustomID(grenadeIndex, INVALID_ENT_REFERENCE);
    }
    
    // Apply fake throw hook on the next frame
    RequestFrame(view_as<RequestFrameCallback>(WeaponSDKOnGrenadeSpawnPost), EntIndexToEntRef(grenadeIndex));
}

/**
 * Hook: WeaponSpawnPost
 * @brief Grenade is spawned. *(Post)
 *
 * @param referenceIndex    The reference index.
 **/
public void WeaponSDKOnGrenadeSpawnPost(const int referenceIndex) 
{
    // Gets the grenade index from the reference
    int grenadeIndex = EntRefToEntIndex(referenceIndex);

    // Validate grenade for the prop
    if(grenadeIndex != INVALID_ENT_REFERENCE)
    {
        // Gets grenade thrower
        int clientIndex = GetEntDataEnt2(grenadeIndex, g_iOffset_GrenadeThrower);
        
        // Validate thrower
        if(!IsPlayerExist(clientIndex)) 
        {
            return;
        }
        
        // Sets team index
        ToolsSetEntityTeam(grenadeIndex, GetClientTeam(clientIndex));
        
        // Gets active weapon index from the client
        int weaponIndex = ToolsGetClientActiveWeapon(clientIndex);
        
        // Validate weapon
        if(!IsValidEdict(weaponIndex))
        {
            return;
        }

        // Validate grenade
        if(!WeaponsValidateGrenade(weaponIndex))
        {
            return;
        }

        // Validate custom index
        int iD = WeaponsGetCustomID(weaponIndex);
        if(iD != INVALID_ENT_REFERENCE)
        {
            // Duplicate index to the projectile for future use
            WeaponsSetCustomID(grenadeIndex, iD);

            // If dropmodel exist, then apply it
            if(WeaponsGetModelDropID(iD))
            {
                // Gets weapon dropmodel
                static char sModel[PLATFORM_LINE_LENGTH];
                WeaponsGetModelDrop(iD, sModel, sizeof(sModel));

                // Sets model entity for the grenade
                SetEntityModel(grenadeIndex, sModel);
                
                // Sets body/skin index for the grenade
                WeaponHDRSetTextures(grenadeIndex, WeaponsGetModelBody(iD, ModelType_Projectile),  WeaponsGetModelSkin(iD, ModelType_Projectile));
            }
            
            // Call forward
            gForwardData._OnGrenadeCreated(clientIndex, grenadeIndex, iD);
        }
    }
}

/**
 * Hook: WeaponDrop
 * @brief Player drop any weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
public Action CS_OnCSWeaponDrop(int clientIndex, int weaponIndex)
{
    // Validate weapon
    if(IsValidEdict(weaponIndex))
    {
        // Validate custom index
        int iD = WeaponsGetCustomID(weaponIndex);
        if(iD != INVALID_ENT_REFERENCE)
        {
            // Block drop, if not available
            if(!WeaponsIsDrop(iD)) 
            {
                return Plugin_Handled;
            }
        }

        // Apply dropped model on the next frame
        RequestFrame(view_as<RequestFrameCallback>(WeaponHDRSetDroppedModel), EntIndexToEntRef(weaponIndex));
    }
    
    // Allow drop
    return Plugin_Continue;
}

/**
 * Hook: WeaponCanUse
 * @brief Player pick-up any weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
public Action WeaponSDKOnCanUse(const int clientIndex, const int weaponIndex)
{
    // Validate weapon
    if(IsValidEdict(weaponIndex))
    {
        // Validate custom index
        int iD = WeaponsGetCustomID(weaponIndex);
        if(iD != INVALID_ENT_REFERENCE)
        {
            // Block pickup it, if not available
            if(!WeaponsValidateClass(clientIndex, iD)) 
            {
                return Plugin_Handled;
            }

            /** Comment bellow, if you want to check the client level/online access **/
            
            // Block pickup it, if online too low
            if(fnGetPlaying() < WeaponsGetOnline(iD))
            {
                return Plugin_Handled;
            }

            // Block pickup it, if level too low
            if(gClientData[clientIndex].Level < WeaponsGetLevel(iD))
            {
                return Plugin_Handled;
            }
            
            // Validate knife
            if(WeaponsValidateKnife(weaponIndex))
            {
                // If the slot is empty, then pick up
                WeaponsPickUp(clientIndex, weaponIndex, iD, SlotType_Melee);
            }
            // Validate bomb
            else if(WeaponsValidateBomb(weaponIndex))
            {
                // If the slot is empty, then pick up
                WeaponsPickUp(clientIndex, weaponIndex, iD, SlotType_C4);
            }
        }
    }
    
    // Allow pickup
    return Plugin_Continue;
}

/**
 * @brief Client has been changed class state. *(Post)
 *
 * @param clientIndex       The client index.
 **/
void WeaponSDKOnClientUpdate(const int clientIndex)
{
    // Client has swapped to a regular weapon
    gClientData[clientIndex].CustomWeapon = INVALID_ENT_REFERENCE;
    gClientData[clientIndex].IndexWeapon  = INVALID_ENT_REFERENCE; /// Only viewmodel identification

    // Remove current addons
    WeaponAttachRemoveAddons(clientIndex);
    
    // Gets player viewmodel indexes
    int viewModel1 = WeaponHDRGetPlayerViewModel(clientIndex, 0);
    int viewModel2 = WeaponHDRGetPlayerViewModel(clientIndex, 1);

    // If a secondary viewmodel doesn't exist, create one
    if(!IsValidEdict(viewModel2))
    {
        // Validate entity
        if((viewModel2 = CreateEntityByName("predicted_viewmodel")) == INVALID_ENT_REFERENCE)
        {
            // Unexpected error, log it
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Weapons, "Weapons HDR", "Failed to create secondary viewmodel");
            return;
        }

        // Sets owner to the entity
        SetEntDataEnt2(viewModel2, g_iOffset_ViewModelOwner, clientIndex, true);
        SetEntData(viewModel2, g_iOffset_ViewModelIndex, 1, _, true);

        // Remove accuracity
        SetEntData(viewModel2, g_iOffset_ViewModelIgnoreOffsAcc, true, 1, true);

        // Spawn the entity into the world
        DispatchSpawn(viewModel2);

        // Sets viewmodel to the owner
        WeaponHDRSetPlayerViewModel(clientIndex, 1, viewModel2);
    }

    // Sets entity index to the reference
    gClientData[clientIndex].ViewModels[0] = EntIndexToEntRef(viewModel1);
    gClientData[clientIndex].ViewModels[1] = EntIndexToEntRef(viewModel2);

    // Gets active weapon index from the client
    int weaponIndex = ToolsGetClientActiveWeapon(clientIndex);

    // Validate weapon
    if(IsValidEdict(weaponIndex))
    {
        // Gets weapon classname
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));

        // Update the weapon
        FakeClientCommand(clientIndex, "use %s", sClassname);
        ToolsSetClientActiveWeapon(clientIndex, weaponIndex);
        SDKCall(hSDKCallWeaponSwitch, clientIndex, weaponIndex, 0);
    }
}

/**
 * Event: PlayerDeath
 * @brief Update a weapon model when player died.
 *
 * @param clientIndex       The client index.
 **/
void WeaponSDKOnClientDeath(const int clientIndex)
{
    // Gets entity index from the reference
    int viewModel2 = EntRefToEntIndex(gClientData[clientIndex].ViewModels[1]);

    // Validate secondary viewmodel
    if(viewModel2 != INVALID_ENT_REFERENCE)
    {
        // Hide the custom viewmodel if the player dies
        WeaponHDRSetEntityVisibility(viewModel2, false);
        ToolsUpdateTransmitState(viewModel2);
    }

    // Client has swapped to a regular weapon
    gClientData[clientIndex].ViewModels[0] = INVALID_ENT_REFERENCE;
    gClientData[clientIndex].ViewModels[1] = INVALID_ENT_REFERENCE;
    gClientData[clientIndex].CustomWeapon  = INVALID_ENT_REFERENCE;
    gClientData[clientIndex].IndexWeapon   = INVALID_ENT_REFERENCE; /// Only viewmodel identification
}

/**
 * Hook: WeaponSwitch
 * @brief Player deploy any weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
public void WeaponSDKOnDeploy(const int clientIndex, const int weaponIndex) 
{
    // Gets entity index from the reference
    int viewModel1 = EntRefToEntIndex(gClientData[clientIndex].ViewModels[0]);
    int viewModel2 = EntRefToEntIndex(gClientData[clientIndex].ViewModels[1]);

    // Validate viewmodels
    if(viewModel1 == INVALID_ENT_REFERENCE || viewModel2 == INVALID_ENT_REFERENCE)
    {
        return;
    }
    
    // Make the first viewmodel invisible
    WeaponHDRSetEntityVisibility(viewModel1, false);
    ToolsUpdateTransmitState(viewModel1);
    
    // Make the second viewmodel invisible
    WeaponHDRSetEntityVisibility(viewModel2, false);
    ToolsUpdateTransmitState(viewModel2);

    // Validate weapon
    if(IsValidEdict(weaponIndex))
    {
        // Validate custom index
        int iD = WeaponsGetCustomID(weaponIndex);
        if(iD != INVALID_ENT_REFERENCE)
        {
            //Gets the last weapon index from the client
            int itemIndex = ToolsGetClientLastWeapon(clientIndex);
        
            // Validate last weapon
            if(IsValidEdict(itemIndex))
            {
                // Validate last index
                int iL = WeaponsGetCustomID(itemIndex);
                if(iL != INVALID_ENT_REFERENCE && iD != iL)
                {
                    // Call forward
                    gForwardData._OnWeaponHolster(clientIndex, itemIndex, iL);
                }
            }
            
            // If custom deploy speed exist, then apply it
            float flDeploy = WeaponsGetReload(iD);
            if(flDeploy)
            {
                // Adds the game time based on the game tick
                flDeploy += GetGameTime();
        
                // Sets deploy time
                WeaponsSetAnimating(weaponIndex, flDeploy);
            }
    
            // If view/world model exist, then set them
            if(WeaponsGetModelViewID(iD) || WeaponsGetModelWorldID(iD) || ((WeaponsValidateKnife(weaponIndex) || WeaponsValidateGrenade(weaponIndex)) && gClientData[clientIndex].Zombie))
            {
                // Client has swapped to a custom weapon
                gClientData[clientIndex].SwapWeapon   = INVALID_ENT_REFERENCE;
                gClientData[clientIndex].CustomWeapon = weaponIndex;
                gClientData[clientIndex].IndexWeapon  = iD; /// Only viewmodel identification
                return;
            }
        }
    }

    // Client has swapped to a regular weapon
    gClientData[clientIndex].CustomWeapon = INVALID_ENT_REFERENCE;
    gClientData[clientIndex].IndexWeapon  = INVALID_ENT_REFERENCE; /// Only viewmodel identification
    
    // Gets class arm model
    static char sArm[PLATFORM_LINE_LENGTH];
    ClassGetArmModel(gClientData[clientIndex].Class, sArm, sizeof(sArm));
    
    // Apply arm model
    if(hasLength(sArm)) ToolsSetClientArm(clientIndex, sArm, sizeof(sArm));
}

/**
 * Hook: WeaponSwitchPost
 * @brief Player deploy any weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
public void WeaponSDKOnDeployPost(const int clientIndex, const int weaponIndex) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Gets entity index from the reference
    int viewModel1 = EntRefToEntIndex(gClientData[clientIndex].ViewModels[0]);
    int viewModel2 = EntRefToEntIndex(gClientData[clientIndex].ViewModels[1]);

    // Validate viewmodels
    if(viewModel1 == INVALID_ENT_REFERENCE || viewModel2 == INVALID_ENT_REFERENCE)
    {
        return;
    }
    
    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        return;
    }
    
    // Sets last weapon index to the client
    ToolsSetClientLastWeapon(clientIndex, weaponIndex); /// Bugfix for holster

    // Weapon has not changed since last pre hook
    if(weaponIndex == gClientData[clientIndex].CustomWeapon)
    {
        // Initialize variables
        int iModel; static char sModel[PLATFORM_LINE_LENGTH]; sModel[0] = '\0';

        // Gets weapon id from the reference
        int iD = gClientData[clientIndex].IndexWeapon; /// Only viewmodel identification
        
        // Validate knife
        if(WeaponsValidateKnife(weaponIndex))
        {
            // Gets claw model
            ClassGetClawModel(gClientData[clientIndex].Class, sModel, sizeof(sModel));
            
            // Update model index
            iModel = ClassGetClawID(gClientData[clientIndex].Class);
        }
        // Validate grenade
        else if(WeaponsValidateGrenade(weaponIndex))
        {
            // Gets grenade model
            ClassGetGrenadeModel(gClientData[clientIndex].Class, sModel, sizeof(sModel));
            
            // Update model index
            iModel = ClassGetGrenadeID(gClientData[clientIndex].Class);
        }

         // Gets model index
        if(!iModel) iModel = WeaponsGetModelViewID(iD);
        
        // Gets weapon viewmodel
        if(!hasLength(sModel)) WeaponsGetModelView(iD, sModel, sizeof(sModel));      

        // If viewmodel exist, then apply it
        if(iModel)
        {
            // Make the first viewmodel invisible
            WeaponHDRSetEntityVisibility(viewModel1, false);
            ToolsUpdateTransmitState(viewModel1);
            
            // Make the second viewmodel visible
            WeaponHDRSetEntityVisibility(viewModel2, true);
            ///ToolsUpdateTransmitState(viewModel2); //-> transport a bit below
            
            // Remove the muzzle on the switch
            VEffectRemoveMuzzle(clientIndex, viewModel2);

            // Gets draw animation sequence
            gClientData[clientIndex].DrawSequence = GetEntData(viewModel1, g_iOffset_ViewModelSequence);
            
            // Switch to an invalid sequence to prevent it from playing sounds before UpdateTransmitStateTime() is called
            SetEntData(viewModel1, g_iOffset_ViewModelSequence, -1, _, true);
            ToolsUpdateTransmitState(viewModel2);
            
            // Sets model entity for the weapon
            SetEntityModel(weaponIndex, sModel);

            // If the sequence for the weapon didn't build yet
            if(WeaponsGetSequenceCount(iD) == -1)
            {
                // Gets sequence amount from a weapon entity
                int iSequenceCount = Animating_GetSequenceCount(weaponIndex);

                // Validate count
                if(iSequenceCount)
                {
                    // Initialize the sequence array
                    int iSequences[WEAPONS_SEQUENCE_MAX];

                    // Validate amount
                    if(iSequenceCount < WEAPONS_SEQUENCE_MAX)
                    {
                        // Build the sequence array
                        WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weaponIndex);
                        
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
            int iBody = ClassGetBody(gClientData[clientIndex].Class);
            int iSkin = ClassGetSkin(gClientData[clientIndex].Class);

            // Sets model/body/skin index for viewmodel
            ToolsSetEntityModelIndex(viewModel2, iModel);
            WeaponHDRSetTextures(viewModel2, (iBody != -1) ? iBody : WeaponsGetModelBody(iD, ModelType_View), (iSkin != -1) ? iSkin : WeaponsGetModelSkin(iD, ModelType_View));
            
            //  Update the animation interval delay for second viewmodel 
            SetEntDataFloat(viewModel2, g_iOffset_ViewModelPlaybackRate, GetEntDataFloat(viewModel1, g_iOffset_ViewModelPlaybackRate), true);

            // Creates a toggle model
            WeaponHDRToggleViewModel(clientIndex, viewModel2, iD);
            
            // Resets the sequence parity
            gClientData[clientIndex].LastSequenceParity = -1;
        }
    
        // If worldmodel exist, then apply it
        if(WeaponsGetModelWorldID(iD))
        {
            WeaponHDRSetPlayerWorldModel(weaponIndex, WeaponsGetModelWorldID(iD), WeaponsGetModelBody(iD, ModelType_World), WeaponsGetModelSkin(iD, ModelType_World));
        }
        // If it don't exist, then hide it
        else
        {
            // Verify that the client is zombie
            if(gClientData[clientIndex].Zombie)
            {
                // Validate a knife
                if(WeaponsValidateKnife(weaponIndex)) WeaponHDRSetPlayerWorldModel(weaponIndex);
            }
        }
        
        // Call forward
        gForwardData._OnWeaponDeploy(clientIndex, weaponIndex, iD);
        
        // If model was found, then stop
        if(iModel && hasLength(sModel))
        {
            return;
        }
    }

    // Make the first viewmodel visible
    WeaponHDRSetEntityVisibility(viewModel1, true);
    ToolsUpdateTransmitState(viewModel1);

    // Make the second viewmodel invisible
    WeaponHDRSetEntityVisibility(viewModel2, false);
    ToolsUpdateTransmitState(viewModel2);

    // Client has swapped to a regular weapon
    gClientData[clientIndex].CustomWeapon = INVALID_ENT_REFERENCE;
    gClientData[clientIndex].IndexWeapon  = INVALID_ENT_REFERENCE; /// Only viewmodel identification
}

/**
 * Hook: PostThinkPost
 * @brief Player hold any weapon.
 *
 * @param clientIndex       The client index.
 **/
public void WeaponSDKOnAnimationFix(const int clientIndex) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Sets current addons
    WeaponAttachSetAddons(clientIndex); /// Back weapon models
    
    // Validate weapon
    if(gClientData[clientIndex].CustomWeapon == INVALID_ENT_REFERENCE) /// Optimization for frame check
    {
        return;
    }

    // Gets entity index from the reference
    int viewModel1 = EntRefToEntIndex(gClientData[clientIndex].ViewModels[0]);
    int viewModel2 = EntRefToEntIndex(gClientData[clientIndex].ViewModels[1]);

    // Validate viewmodels
    if(viewModel1 == INVALID_ENT_REFERENCE || viewModel2 == INVALID_ENT_REFERENCE)
    {
        return;
    }

    // Gets sequence number and it draw animation sequence
    int iSequence = GetEntData(viewModel1, g_iOffset_ViewModelSequence);
    int drawSequence = gClientData[clientIndex].DrawSequence;
    
    // Validate sequence
    if(iSequence == -1)
    {
        iSequence = drawSequence; /// Play the draw animation
    }
    
    // Gets sequence parity index
    int sequenceParity = GetEntData(viewModel1, g_iOffset_NewSequenceParity);

    // Sequence has not changed since last post hook
    if(iSequence == gClientData[clientIndex].LastSequence)
    {
        // Skip on weapon switch
        if(gClientData[clientIndex].LastSequenceParity != -1)
        {
            // Skip if sequence hasn't finished
            if(sequenceParity == gClientData[clientIndex].LastSequenceParity)
            {
                return;
            }

            // Gets weapon id from the reference
            int iD = gClientData[clientIndex].IndexWeapon; /// Only viewmodel identification
            int swapSequence = WeaponsGetSequenceSwap(iD, iSequence);
            
            // Validate swap sequence
            if(swapSequence != -1)
            {
                // Play the swaped sequence
                SetEntData(viewModel1, g_iOffset_ViewModelSequence, swapSequence, _, true);
                SetEntData(viewModel2, g_iOffset_ViewModelSequence, swapSequence, _, true);

                // Update the sequence for next check
                gClientData[clientIndex].LastSequence = swapSequence;
            }
            else
            {
                // Creates a toggle model
                WeaponHDRToggleViewModel(clientIndex, viewModel2, iD);
            }
        }
    }
    else
    {
        // Validate sequence
        if(drawSequence != -1 && iSequence != drawSequence)
        {
            ToolsUpdateTransmitState(viewModel1); /// Update!
            gClientData[clientIndex].DrawSequence = -1;
        }
        
        // Sets new sequence
        SetEntData(viewModel2, g_iOffset_ViewModelSequence, iSequence, _, true);
        gClientData[clientIndex].LastSequence = iSequence;
    }
    
    // Update the sequence parity for next check
    gClientData[clientIndex].LastSequenceParity = sequenceParity;
}

/**
 * Event: WeaponOnFire
 * @brief Weapon has been fired.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
void WeaponSDKOnFire(const int clientIndex, const int weaponIndex) 
{ 
    // Validate custom index
    int iD = WeaponsGetCustomID(weaponIndex);
    if(iD != INVALID_ENT_REFERENCE)    
    {
        // Gets game time based on the game tick
        float flCurrentTime = GetGameTime();

        // If custom fire speed exist, then apply it
        float flSpeed = WeaponsGetSpeed(iD);
        if(flSpeed)
        {
            // Adds the game time based on the game tick
            flSpeed += flCurrentTime;
    
            // Sets next attack time
            WeaponsSetAnimating(weaponIndex, flSpeed);
            
            // Block client attack
            ToolsSetClientAttack(clientIndex, flSpeed);
        }

        // If viewmodel exist, then create muzzle smoke
        if(WeaponsGetModelViewID(iD))
        {
            // Gets entity index from the reference
            int viewModel2 = EntRefToEntIndex(gClientData[clientIndex].ViewModels[1]);

            // Validate secondary viewmodel
            if(viewModel2 == INVALID_ENT_REFERENCE)
            {
                return;
            }

            // If weapon without any type of ammo, then stop
            if(GetEntData(weaponIndex, g_iOffset_WeaponAmmoType) == -1)
            {
                return;
            }
            
            // Gets weapon muzzle
            static char sMuzzle[SMALL_LINE_LENGTH];
            WeaponsGetModelMuzzle(iD, sMuzzle, sizeof(sMuzzle));

            // Creates a muzzle
            if(hasLength(sMuzzle)) VEffectSpawnMuzzle(clientIndex, viewModel2, sMuzzle);

            // Validate weapon heat delay
            float flDelay = WeaponsGetModelHeat(iD);
            if(flDelay)
            {
                // Initialize variables
                static float flHeatDelay[MAXPLAYERS+1]; static float flSmoke[MAXPLAYERS+1];

                // Calculate the expected heat amount
                float flHeat = ((flCurrentTime - GetEntDataFloat(weaponIndex, g_iOffset_LastShotTime)) * -0.5) + flHeatDelay[clientIndex];

                // This value is set specifically for each weapon
                flHeat += flDelay;
                
                // Reset the delay
                if(flHeat < 0.0) flHeat = 0.0;

                // Validate delay
                if(flHeat > 1.0)
                {
                    // Validate heat
                    if(flCurrentTime - flSmoke[clientIndex] > 1.0)
                    {
                        // Creates a muzzle smoke
                        VEffectSpawnMuzzleSmoke(clientIndex, viewModel2);
                        flSmoke[clientIndex] = flCurrentTime;
                    }
                    
                    // Resets delay
                    flHeat = 0.0;
                }

                // Update the heat delay
                flHeatDelay[clientIndex] = flHeat;
            }
        }
        
        // Call forward
        gForwardData._OnWeaponFire(clientIndex, weaponIndex, iD);
    }
    
    // Validate a non-knife
    if(!WeaponsValidateKnife(weaponIndex) && !WeaponsValidateTaser(weaponIndex)) 
    {
        // Validate class ammunition mode
        switch(ClassGetAmmunition(gClientData[clientIndex].Class))
        {
            case 0 : return;
            case 1 : { SetEntData(weaponIndex, g_iOffset_WeaponReserve1, GetEntData(weaponIndex, g_iOffset_WeaponReserve2), _, true); }
            case 2 : { SetEntData(weaponIndex, g_iOffset_WeaponClip1, GetEntData(weaponIndex, g_iOffset_WeaponClip1) + 1, _, true); } 
        }
    }
}

/**
 * Event: WeaponOnBullet
 * @brief The bullet hits something.
 *
 * @param clientIndex       The client index.
 * @param vBulletPosition   The position of a bullet hit.
 * @param weaponIndex       The weapon index.
 **/
void WeaponSDKOnBullet(const int clientIndex, const float vBulletPosition[3], const int weaponIndex) 
{ 
    // Validate custom index
    int iD = WeaponsGetCustomID(weaponIndex);
    if(iD != INVALID_ENT_REFERENCE)    
    {
        // Call forward
        gForwardData._OnWeaponBullet(clientIndex, vBulletPosition, weaponIndex, iD);
    }
}
/**
 * Event: WeaponOnRunCmd
 * @brief Weapon is holding.
 *
 * @param clientIndex       The client index.
 * @param iButtons          The button buffer.
 * @param iLastButtons      The last button buffer.
 * @param weaponIndex       The weapon index.
 **/
Action WeaponSDKOnRunCmd(const int clientIndex, int &iButtons, const int iLastButtons, const int weaponIndex)
{
    // Validate custom index
    static int iD; iD = WeaponsGetCustomID(weaponIndex); /** static for runcmd **/
    if(iD != INVALID_ENT_REFERENCE)    
    {
        // Call forward
        static Action resultHandle;
        gForwardData._OnWeaponRunCmd(clientIndex, iButtons, iLastButtons, weaponIndex, iD, resultHandle);
        return resultHandle;
    }
    
    // Return on the unsuccess
    return Plugin_Continue;
}

/**
 * Event: WeaponOnFire
 * @brief Weapon has been shoot.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
Action WeaponSDKOnShoot(const int clientIndex, const int weaponIndex) 
{ 
    // Validate custom index
    int iD = WeaponsGetCustomID(weaponIndex);
    if(iD != INVALID_ENT_REFERENCE)    
    {
        // Validate broadcast
        Action resultHandle = SoundsOnClientShoot(clientIndex, iD);

        // Call forward
        gForwardData._OnWeaponShoot(clientIndex, weaponIndex, iD);

        // Block broadcast
        return resultHandle;
    }
    
    // Allow broadcast
    return Plugin_Continue;
}

/**
 * Event: WeaponOnHostage
 * @brief Weapon has been switch by hostage.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
void WeaponSDKOnHostage(const int clientIndex) 
{
    // Prevent the viewmodel from being removed
    WeaponHDRSetPlayerViewModel(clientIndex, 1, INVALID_ENT_REFERENCE);

    // Apply fake hostage follow hook on the next frame
    RequestFrame(view_as<RequestFrameCallback>(WeaponSDKOnHostagePost), GetClientUserId(clientIndex));
}
    
/**
 * Event: WeaponOnHostagePost
 * @brief Weapon has been switch by hostage. *(Post)
 *
 * @param userID            The user id.
 **/
public void WeaponSDKOnHostagePost(const int userID) 
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Gets weapon id from the reference
        int iD = gClientData[clientIndex].IndexWeapon; /// Only viewmodel identification

        // Validate id
        if(iD != INVALID_ENT_REFERENCE)
        {
            // Gets second viewmodel
            int viewModel2 = WeaponHDRGetPlayerViewModel(clientIndex, 1);

            // Remove the viewmodel created by the game
            if(IsValidEdict(viewModel2))
            {
                AcceptEntityInput(viewModel2, "Kill"); /// Destroy
            }

            // Resets the viewmodel
            WeaponHDRSetPlayerViewModel(clientIndex, 1, EntRefToEntIndex(gClientData[clientIndex].ViewModels[1]));
        }
    }
}

/**
 * Listener command callback(buyammo1, buyammo2)
 * @brief Buying of the ammunition.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action WeaponSDKOnCommandListened(const int clientIndex, const char[] commandMsg, const int iArguments)
{
    // Validate client
    if(IsPlayerExist(clientIndex))
    {
        // Validate class ammunition mode
        switch(ClassGetAmmunition(gClientData[clientIndex].Class))
        {
            case 0  : { /* < empty statement > */ }
            default : return Plugin_Continue;
        }

        // Gets active weapon index from the client
        int weaponIndex = ToolsGetClientActiveWeapon(clientIndex);

        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // If weapon without any type of ammo, then stop
            if(GetEntData(weaponIndex, g_iOffset_WeaponAmmoType) == -1)
            {
                return Plugin_Continue;
            }
            
            // Validate custom index
            int iD = WeaponsGetCustomID(weaponIndex);
            if(iD != INVALID_ENT_REFERENCE)
            {
                // If cost is disabled, then stop
                int iCost = WeaponsGetAmmunition(iD);
                if(!iCost)
                {
                    return Plugin_Continue;
                }
                
                // Validate ammunition cost
                if(gClientData[clientIndex].Money < iCost)
                {
                    // Show block info
                    TranslationPrintHintText(clientIndex, "buying ammunition block");
                    
                    // Emit error sound
                    ClientCommand(clientIndex, "play buttons/button11.wav");    
                    return Plugin_Continue;
                }
        
                // Gets current/max reverse ammo
                int iAmmo = GetEntData(weaponIndex, g_iOffset_WeaponReserve1);
                int iMaxAmmo = SDKCall(hSDKCallGetReserveAmmoMax, weaponIndex);
                
                // Reset ammomax for standart weapons
                if(!iMaxAmmo) iMaxAmmo = GetEntData(weaponIndex, g_iOffset_WeaponReserve2); /// Bug fix for standart weapons
                
                // Validate amount
                if(iAmmo < iMaxAmmo)
                {
                    // Generate amount
                    iAmmo += SDKCall(hSDKCallGetMaxClip1, weaponIndex); if(!iAmmo) /*~*/ iAmmo++;

                    // Gives ammo of a certain type to a weapon
                    SetEntData(weaponIndex, g_iOffset_WeaponReserve1, (iAmmo <= iMaxAmmo) ? iAmmo : iMaxAmmo, _, true);

                    // Remove money
                    AccountSetClientCash(clientIndex, gClientData[clientIndex].Money - iCost);

                    // Forward event to modules
                    SoundsOnClientAmmunition(clientIndex);
                }
            }
        }
    }

    // Allow commands
    return Plugin_Continue;
}

#if defined USE_DHOOKS 
/**
 * DHook: Sets a weapon clip when its spawned, picked, dropped or reloaded.
 * @note int CBaseCombatWeapon::GetMaxClip1(void *)
 *
 * @param weaponIndex       The weapon index.
 * @param hReturn           Handle to return structure.
 **/
public MRESReturn WeaponDHookOnGetMaxClip1(const int weaponIndex, Handle hReturn)
{
    // Validate custom index
    int iD = WeaponsGetCustomID(weaponIndex);
    if(iD != INVALID_ENT_REFERENCE)
    {
        // Gets weapon clip
        int iClip = WeaponsGetClip(iD);
        if(iClip)
        {
            DHookSetReturn(hReturn, iClip);
            return MRES_Override;
        }
    }

    // Skip the hook
    return MRES_Ignored;
}

/**
 * DHook: Sets a weapon reserved ammunition when its spawned, picked, dropped or reloaded. 
 * @note    int CBaseCombatWeapon::GetReserveAmmoMax(AmmoPosition_t)
 *
 * @param weaponIndex       The weapon index.
 * @param hReturn           Handle to return structure.
 **/
public MRESReturn WeaponDHookOnGetReverseMax(const int weaponIndex, Handle hReturn)
{
    // Validate custom index
    int iD = WeaponsGetCustomID(weaponIndex);
    if(iD != INVALID_ENT_REFERENCE)
    {
        // Gets weapon ammo
        int iAmmo = WeaponsGetAmmo(iD);
        if(iAmmo)
        {
            DHookSetReturn(hReturn, iAmmo);
            return MRES_Override;
        }
    }
    
    // Skip the hook
    return MRES_Ignored;
}
#endif
