/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          tools.cpp
 *  Type:          Module 
 *  Description:   Find offsets and signatures.
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
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallLookupPoseParameter; 
Handle hSDKCallLookupSequence; 
Handle hSDKCallLookupAttachment;
Handle hSDKCallGetAttachment;

/**
 * Variables to store virtual SDK adresses.
 **/
Address sendTableCRC;
Address offsetArmorValue; 
Address offsetAccount; 
Address offsetHealth; 
Address offsetClip;
Address offsetPrimary;
Address offsetSecondary;
int SendProp_iBits; 
int Player_CanBeSpotted;

// Tools Functions (header)
#include "zp/manager/playerclasses/tools_functions.cpp"

/**
 * @brief Tools module init function.
 **/
void ToolsOnInit(/*void*/)
{
    // Load player offsets
    fnInitSendPropOffset(g_iOffset_PlayerLMV, "CBasePlayer", "m_flLaggedMovementValue");
    fnInitSendPropOffset(g_iOffset_PlayerRender, "CBasePlayer", "m_clrRender");
    fnInitSendPropOffset(g_iOffset_PlayerNightVisionOn, "CCSPlayer", "m_bNightVisionOn");
    fnInitSendPropOffset(g_iOffset_PlayerHasNightVision, "CCSPlayer", "m_bHasNightVision");
    fnInitSendPropOffset(g_iOffset_PlayerHasDefuser, "CCSPlayer", "m_bHasDefuser");
    fnInitSendPropOffset(g_iOffset_PlayerSpotted, "CBasePlayer", "m_bSpotted");
    fnInitSendPropOffset(g_iOffset_PlayerSpottedByMask, "CBasePlayer", "m_bSpottedByMask");
    fnInitSendPropOffset(g_iOffset_PlayerDetected, "CCSPlayer", "m_flDetectedByEnemySensorTime");
    fnInitSendPropOffset(g_iOffset_PlayerHUD, "CBasePlayer", "m_iHideHUD");
    fnInitSendPropOffset(g_iOffset_PlayerHitGroup, "CBasePlayer", "m_LastHitGroup");
    fnInitSendPropOffset(g_iOffset_PlayerFov, "CCSPlayer", "m_iFOV");
    fnInitSendPropOffset(g_iOffset_PlayerDefaultFOV, "CCSPlayer", "m_iDefaultFOV");
    fnInitSendPropOffset(g_iOffset_PlayerArmor, "CCSPlayer", "m_ArmorValue");
    fnInitSendPropOffset(g_iOffset_PlayerHasHeavyArmor, "CCSPlayer", "m_bHasHeavyArmor");
    fnInitSendPropOffset(g_iOffset_PlayerHasHelmet, "CCSPlayer", "m_bHasHelmet"); 
    fnInitSendPropOffset(g_iOffset_PlayerHealth, "CBasePlayer", "m_iHealth");
    fnInitSendPropOffset(g_iOffset_PlayerCollision, "CCSPlayer", "m_CollisionGroup");
    fnInitSendPropOffset(g_iOffset_PlayerRagdoll, "CCSPlayer", "m_hRagdoll");
    fnInitSendPropOffset(g_iOffset_PlayerAccount, "CCSPlayer", "m_iAccount");
    fnInitSendPropOffset(g_iOffset_PlayerActiveWeapon, "CBasePlayer", "m_hActiveWeapon");
    fnInitSendPropOffset(g_iOffset_PlayerLastWeapon, "CBasePlayer", "m_hLastWeapon");
    fnInitSendPropOffset(g_iOffset_PlayerObserverMode, "CBasePlayer", "m_iObserverMode");
    fnInitSendPropOffset(g_iOffset_PlayerObserverTarget, "CBasePlayer", "m_hObserverTarget");
    fnInitSendPropOffset(g_iOffset_PlayerAttack, "CBasePlayer", "m_flNextAttack");
    fnInitSendPropOffset(g_iOffset_PlayerArms, "CCSPlayer", "m_szArmsModel");
    fnInitSendPropOffset(g_iOffset_PlayerAddonBits, "CCSPlayer", "m_iAddonBits");

    // Load entity offsets
    fnInitSendPropOffset(g_iOffset_EntityEffects, "CBaseEntity", "m_fEffects");
    fnInitSendPropOffset(g_iOffset_EntityModelIndex, "CBaseEntity", "m_nModelIndex");
    fnInitSendPropOffset(g_iOffset_EntityOwnerEntity, "CBaseEntity", "m_hOwnerEntity");
    fnInitSendPropOffset(g_iOffset_EntityTeam, "CBaseEntity", "m_iTeamNum");
    fnInitSendPropOffset(g_iOffset_EntityOrigin, "CBaseEntity", "m_vecOrigin");

    // Load other offsets
    fnInitGameConfOffset(gServerData.Config, Player_CanBeSpotted, "CBasePlayer::CanBeSpotted");
    g_iOffset_PlayerCanBeSpotted = g_iOffset_PlayerSpotted - Player_CanBeSpotted;
    fnInitGameConfOffset(gServerData.Config, SendProp_iBits, "CSendProp::m_nBits");
    fnInitGameConfAddress(gServerData.Config, sendTableCRC, "g_SendTableCRC");
    fnInitGameConfAddress(gServerData.Config, offsetArmorValue, "m_ArmorValue");
    fnInitGameConfAddress(gServerData.Config, offsetAccount, "m_iAccount");
    fnInitGameConfAddress(gServerData.Config, offsetHealth, "m_iHealth");
    fnInitGameConfAddress(gServerData.Config, offsetClip, "m_iClip1");
    fnInitGameConfAddress(gServerData.Config, offsetPrimary, "m_iPrimaryReserveAmmoCount");
    fnInitGameConfAddress(gServerData.Config, offsetSecondary, "m_iSecondaryReserveAmmoCount");

    // Memory patching
    StoreToAddress(offsetArmorValue + view_as<Address>(SendProp_iBits), 32, NumberType_Int32);
    StoreToAddress(offsetAccount + view_as<Address>(SendProp_iBits), 32, NumberType_Int32);
    StoreToAddress(offsetHealth + view_as<Address>(SendProp_iBits), 32, NumberType_Int32);
    StoreToAddress(offsetClip + view_as<Address>(SendProp_iBits), 32, NumberType_Int32);
    StoreToAddress(offsetPrimary + view_as<Address>(SendProp_iBits), 32, NumberType_Int32);
    StoreToAddress(offsetSecondary  + view_as<Address>(SendProp_iBits), 32, NumberType_Int32);

    /// 1337 -> it just a random and an invalid CRC32 byte
    StoreToAddress(sendTableCRC, 1337, NumberType_Int32);
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::LookupAttachment");

    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if((hSDKCallLookupAttachment = EndPrepSDKCall()) == null)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::LookupAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::GetAttachment");

    // Validate windows
    if(gServerData.Platform == OS_Windows)
    {
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    }
    else
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    }
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
    PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
    
    // Validate call
    if((hSDKCallGetAttachment = EndPrepSDKCall()) == null)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::GetAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity); 
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::LookupPoseParameter"); 
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);  
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); 
    
    // Validate call
    if((hSDKCallLookupPoseParameter = EndPrepSDKCall()) == null) 
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::LookupPoseParameter\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*__________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(gServerData.Platform == OS_Windows ? SDKCall_Entity : SDKCall_Raw); 
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::LookupSequence");
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);  
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); 

    // Validate call
    if((hSDKCallLookupSequence = EndPrepSDKCall()) == null) 
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::LookupSequence\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }
}

/**
 * @brief Tools module purge function.
 **/
void ToolsOnPurge(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge player timers
        gClientData[i].PurgeTimers();
    }
}

/**
 * @brief Called once a client successfully connects.
 *
 * @param clientIndex       The client index.
 **/
void ToolsOnClientConnect(int clientIndex)
{
    // Forward event to modules
    gClientData[clientIndex].ResetVars();
    gClientData[clientIndex].ResetTimers();
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param clientIndex       The client index.
 **/
void ToolsOnClientDisconnectPost(int clientIndex)
{
    // Forward event to modules
    gClientData[clientIndex].ResetVars();
    gClientData[clientIndex].ResetTimers();
}

/**
 * Hook: SetTransmit
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public Action ToolsOnEntityTransmit(int entityIndex, int clientIndex)
{
    // Gets the owner of the entity
    int ownerIndex = ToolsGetEntityOwner(entityIndex);

    // Validate observer mode
    if(ownerIndex == clientIndex || (ToolsGetClientObserverMode(clientIndex) == SPECMODE_FIRSTPERSON && ownerIndex == ToolsGetClientObserverTarget(clientIndex)))
    {
        // Block transmitting
        return Plugin_Handled;
    }

    // Allow transmitting
    return Plugin_Continue;
}

/*
 * Tools natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void ToolsOnNativeInit(/*void*/)
{
    CreateNative("ZP_LookupAttachment",     API_LookupAttachment);
    CreateNative("ZP_GetAttachment",        API_GetAttachment);
    CreateNative("ZP_LookupSequence",       API_LookupSequence);
    CreateNative("ZP_LookupPoseParameter",  API_LookupPoseParameter);
    CreateNative("ZP_RespawnClient",        API_RespawnClient);
    CreateNative("ZP_FindPlayerInSphere",   API_FindPlayerInSphere);
}

/**
 * @brief Validate the attachment on the entity.
 *
 * @note native bool ZP_LookupAttachment(entityIndex, attach);
 **/
public int API_LookupAttachment(Handle hPlugin, int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }

    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(2, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize attach char
    static char sAttach[SMALL_LINE_LENGTH];
    GetNativeString(2, sAttach, sizeof(sAttach));
    
    // Return on success
    return ToolsLookupAttachment(entityIndex, sAttach);
}

/**
 * @brief Gets the attachment of the entity.
 *
 * @note native void ZP_GetAttachment(entityIndex, attach, origin, angles);
 **/
public int API_GetAttachment(Handle hPlugin, int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }
    
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(2, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize variables
    static char sAttach[SMALL_LINE_LENGTH]; static float vPosition[3]; static float vAngle[3];

    // General
    GetNativeString(2, sAttach, sizeof(sAttach));
    
    // Extract data
    ToolsGetAttachment(entityIndex, sAttach, vPosition, vAngle);
    
    // Return on success
    SetNativeArray(3, vPosition, sizeof(vPosition)); return SetNativeArray(4, vAngle, sizeof(vAngle));
}

/**
 * @brief Gets the sequence of the entity.
 *
 * @note native int ZP_LookupSequence(entityIndex, anim);
 **/
public int API_LookupSequence(Handle hPlugin, int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }
    
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(2, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize anim char
    static char sAnim[SMALL_LINE_LENGTH];
    GetNativeString(2, sAnim, sizeof(sAnim));
    
    // Return on success
    return ToolsLookupSequence(entityIndex, sAnim);
}

/**
 * @brief Gets the pose of the entity.
 *
 * @note native int ZP_LookupPoseParameter(entityIndex, name);
 **/
public int API_LookupPoseParameter(Handle hPlugin, int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }
    
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(2, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    GetNativeString(2, sName, sizeof(sName));
    
    // Return on success
    return ToolsLookupPoseParameter(entityIndex, sName);
} 

/**
 * @brief Respawn a player.
 *
 * @note native bool ZP_RespawnClient(clientIndex);
 **/
public int API_RespawnClient(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return false;
    }
    
    // Force client to respawn
    return ToolsForceToRespawn(clientIndex);
}

/**
 * @brief Used to iterate all the clients collision within a sphere.
 *
 * @note native int ZP_FindPlayerInSphere(&it, center, radius);
 **/
public int API_FindPlayerInSphere(Handle hPlugin, int iNumParams)
{
    // Gets iterator from native cell 
    int it = GetNativeCellRef(1);
    
    // Gets origin vector
    static float vPosition[3];
    GetNativeArray(2, vPosition, sizeof(vPosition));

    // Gets the client index, which colliding with the solid sphere
    int clientIndex = AntiStickFindPlayerInSphere(it, vPosition, GetNativeCell(3));
    
    // Sets an iterator by reference
    SetNativeCellRef(1, it);
    
    // Return on the success
    return clientIndex;
}