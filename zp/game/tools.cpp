/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          tools.cpp
 *  Type:          Game 
 *  Description:   Find offsets and signatures.
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
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallEntityUpdateTransmitState; // UpdateTransmitState will stop the viewmodel from transmitting if EF_NODRAW flag is present
Handle hSDKCallTerminateRound;
Handle hSDKCallSwitchTeam;
Handle hSDKCallRoundRespawn;
Handle hSDKCallLookupAttachment;
Handle hSDKCallGetAttachment_Linux;
Handle hSDKCallGetAttachment_Windows;

// Tools Functions (core)
#include "zp/game/tools_functions.cpp"

/**
 * Tools module init function.
 **/
void ToolsInit(/*void*/)
{
    // Find offsets
    ToolsFindOffsets();

    // Setup SDKTools
    ToolsSetupGameData();
}

/**
 * Tools module purge function.
 **/
void ToolsPurge(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge player timers
        ToolsPurgeTimers(i); /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * Finds all offset values for the plugin.
 **/
void ToolsFindOffsets(/*void*/) //IClientUnknown, IClientRenderable, IClientNetworkable, IClientThinkable -> IClientEntity -> C_BaseEntity -> C_BaseAnimating -> C_BaseAnimatingOverlay -> C_BaseFlex -> C_BaseCombatCharacter -> C_BasePlayer -> C_CSPlayer
{
    // Load offsets here
    fnInitSendPropOffset(g_iOffset_PlayerVelocity, "CBasePlayer", "m_vecVelocity[0]");
    fnInitSendPropOffset(g_iOffset_PlayerLMV, "CBasePlayer", "m_flLaggedMovementValue");
    fnInitSendPropOffset(g_iOffset_PlayerNightVisionOn, "CCSPlayer", "m_bNightVisionOn");
    fnInitSendPropOffset(g_iOffset_PlayerHasNightVision, "CCSPlayer", "m_bHasNightVision");
    fnInitSendPropOffset(g_iOffset_PlayerHasDefuser, "CCSPlayer", "m_bHasDefuser");
    fnInitSendPropOffset(g_iOffset_PlayerSpotted, "CBasePlayer", "m_bSpotted");
    fnInitSendPropOffset(g_iOffset_PlayerDetected, "CCSPlayer", "m_flDetectedByEnemySensorTime");
    fnInitSendPropOffset(g_iOffset_PlayerHUD, "CBasePlayer", "m_iHideHUD");
    fnInitSendPropOffset(g_iOffset_PlayerHitGroup, "CBasePlayer", "m_LastHitGroup");
    fnInitSendPropOffset(g_iOffset_PlayerFlashLight, "CBasePlayer", "m_fEffects");
    fnInitSendPropOffset(g_iOffset_PlayerDefaultFOV, "CBasePlayer", "m_iDefaultFOV");
    fnInitSendPropOffset(g_iOffset_PlayerArmor, "CCSPlayer", "m_ArmorValue");
    fnInitSendPropOffset(g_iOffset_PlayerHealth, "CBasePlayer", "m_iHealth");
    fnInitSendPropOffset(g_iOffset_PlayerCollision, "CCSPlayer", "m_CollisionGroup");
    fnInitSendPropOffset(g_iOffset_PlayerRagdool, "CCSPlayer", "m_hRagdoll");
}

/**
 * Sets up gamedata for the plugin.
 **/
void ToolsSetupGameData(/*void*/)
{
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData[Server_GameConfig][Game_Zombie], SDKConf_Virtual, "Entity_UpdateTransmitState");

    // Validate call
    if(!(hSDKCallEntityUpdateTransmitState = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseCombatWeapon::UpdateTransmitState\". Update offset in \"%s\"", PLUGIN_CONFIG);
    }
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_GameRules);
    PrepSDKCall_SetFromConf(gServerData[Server_GameConfig][Game_CStrike], SDKConf_Signature, "TerminateRound");

    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if(!(hSDKCallTerminateRound = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CGameRules::TerminateRound\". Update \"SourceMod\"");
    }

    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gServerData[Server_GameConfig][Game_CStrike], SDKConf_Signature, "SwitchTeam");

    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if(!(hSDKCallSwitchTeam = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBasePlayer::SwitchTeam\". Update \"SourceMod\"");
    }

    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gServerData[Server_GameConfig][Game_CStrike], SDKConf_Signature, "RoundRespawn");

    //  Validate call
    if(!(hSDKCallRoundRespawn = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBasePlayer::RoundRespawn\". Update \"SourceMod\"");
    }
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData[Server_GameConfig][Game_Zombie], SDKConf_Signature, "Animating_LookupAttachment");

    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);

    //  Validate call
    if(!(hSDKCallLookupAttachment = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::LookupAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
    }
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData[Server_GameConfig][Game_Zombie], SDKConf_Signature, "Animating_GetAttachment");
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
    PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
    
    // Validate call
    if(!(hSDKCallGetAttachment_Linux = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::GetAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
    }
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData[Server_GameConfig][Game_Zombie], SDKConf_Signature, "Animating_GetAttachment");
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
    PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
    
    // Validate call
    if(!(hSDKCallGetAttachment_Windows = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::GetAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
    }
}

/*
 * Tools natives API.
 */

/**
 * Set a round termination.
 *
 * native void ZP_TerminateRound(reason);
 **/
public int API_TerminateRound(Handle isPlugin, const int iNumParams)
{
    // Terminate round
    ToolsTerminateRound(GetNativeCell(1));
}

/**
 * Update a entity transmit state.
 *
 * native void ZP_UpdateTransmitState(entityIndex);
 **/
public int API_UpdateTransmitState(Handle isPlugin, const int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }
    
    // Update state
    ToolsUpdateTransmitState(entityIndex);
    
    // Return on the success
    return 1;
}

/**
 * Validate the attachment on the entity.
 *
 * native bool ZP_LookupAttachment(entityIndex, attach);
 **/
public int API_LookupAttachment(Handle isPlugin, const int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(2);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize variables
    static char sAttach[SMALL_LINE_LENGTH];

    // General
    GetNativeString(2, sAttach, sizeof(sAttach));
    
    // Return on the success
    return ToolsLookupAttachment(entityIndex, sAttach);
}

/**
 * Gets the attachment of the entity.
 *
 * native void ZP_GetAttachment(entityIndex, attach, origin, angles);
 **/
public int API_GetAttachment(Handle isPlugin, const int iNumParams)
{
    // Gets entity index from native cell 
    int entityIndex = GetNativeCell(1);
    
    // Validate entity
    if(!IsValidEdict(entityIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entityIndex);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(2);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize variables
    static char sAttach[SMALL_LINE_LENGTH]; static float vOrigin[3]; static float vAngle[3];

    // General
    GetNativeString(2, sAttach, sizeof(sAttach));
    
    // Extract data
    ToolsGetAttachment(entityIndex, sAttach, vOrigin, vAngle);
    
    // Return on the success
    SetNativeArray(3, vOrigin, sizeof(vOrigin)); return SetNativeArray(4, vAngle, sizeof(vAngle));
}