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
Handle hSDKCallLookupAttachment;
Handle hSDKCallGetAttachment;

/**
 * Variables to store virtual SDK adresses.
 **/
int Player_CanBeSpotted;

// Tools Functions (header)
#include "zp/manager/playerclasses/tools_functions.cpp"

/**
 * @brief Tools module init function.
 **/
void ToolsOnInit(/*void*/)
{
    // Load player offsets
    fnInitSendPropOffset(g_iOffset_PlayerVelocity, "CBasePlayer", "m_vecVelocity[0]");
    fnInitSendPropOffset(g_iOffset_PlayerLMV, "CBasePlayer", "m_flLaggedMovementValue");
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
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::LookupAttachment");

    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if(!(hSDKCallLookupAttachment = EndPrepSDKCall()))
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
    if(!(hSDKCallGetAttachment = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::GetAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
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
void ToolsOnClientConnect(const int clientIndex)
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
void ToolsOnClientDisconnectPost(const int clientIndex)
{
    // Forward event to modules
    gClientData[clientIndex].ResetVars();
    gClientData[clientIndex].ResetTimers();
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
    CreateNative("ZP_RespawnClient",        API_RespawnClient);
}

/**
 * @brief Validate the attachment on the entity.
 *
 * @note native bool ZP_LookupAttachment(entityIndex, attach);
 **/
public int API_LookupAttachment(const Handle hPlugin, const int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(2);

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
public int API_GetAttachment(const Handle hPlugin, const int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(2);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize variables
    static char sAttach[SMALL_LINE_LENGTH]; static float vOrigin[3]; static float vAngle[3];

    // General
    GetNativeString(2, sAttach, sizeof(sAttach));
    
    // Extract data
    ToolsGetAttachment(entityIndex, sAttach, vOrigin, vAngle);
    
    // Return on success
    SetNativeArray(3, vOrigin, sizeof(vOrigin)); return SetNativeArray(4, vAngle, sizeof(vAngle));
}

/**
 * @brief Respawn a player.
 *
 * @note native bool ZP_RespawnClient(clientIndex);
 **/
public int API_RespawnClient(const Handle hPlugin, const int iNumParams)
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