/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          tools.sp
 *  Type:          Module 
 *  Description:   Find offsets and signatures.
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
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallLookupPoseParameter; 
Handle hSDKCallLookupSequence; 
Handle hSDKCallLookupAttachment;
Handle hSDKCallGetAttachment;
Handle hSDKCallResetSequence; 
Handle hSDKCallGetSequenceActivity;
Handle hSDKCallUpdateTransmitState;
Handle hSDKCallIsBSPModel;
Handle hSDKCallFireBullets;

/**
 * Variables to store virtual SDK adresses.
 **/
Address pSendTableCRC;
Address pArmorValue; 
Address pAccount; 
Address pHealth; 
Address pClip;
Address pPrimary;
Address pSecondary;
Address pFireBullets;
int Player_Spotted;
int Player_SpottedByMask;
int Player_ProgressBarStartTime; 
int Player_ProgressBarDuration;
int Player_BlockingUseActionInProgress;
int Entity_SimulationTime;
int SendProp_iBits; 
int Animating_StudioHdr;
int StudioHdrStruct_SequenceCount;
int VirtualModelStruct_SequenceVector_Size;

/**
 * @brief FX_FireBullets translator.
 * @link http://shell-storm.org/online/Online-Assembler-and-Disassembler/
 * 
 * @code 58                pop eax
 *       59                pop ecx
 *       5A                pop edx
 *       50                push eax
 *       B8 00 00 00 00    mov eax, 0x0 ; in 0x0, write the address of the "FX_FireBullets" function
 *       FF E0             jmp eax
 **/
char ASMTRAMPOLINE[NORMAL_LINE_LENGTH] = "\x58\x59\x5a\x50\xb8\x00\x00\x00\x00\xff\xe0";

/**
 * @section StudioHdr structure.
 * @link https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/public/studio.h#L2371
 **/ 
enum StudioHdrClass
{
	StudioHdrClass_StudioHdrStruct = 0,
	StudioHdrClass_VirualModelStruct = 4
};
/**
 * @endsection
 **/
 
/**
 * @section StudioAnim structure.
 * @link https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/public/studio.h#L690
 **/ 
enum StudioAnimDesc
{
	StudioAnimDesc_Fps = 8,
	StudioAnimDesc_NumFrames = 16,
	StudioAnimDesc_NumMovements = 20
};
/**
 * @endsection
 **/

// Tools Functions
#include "zp/playerclasses/toolsfunctions.sp"

/**
 * @brief Tools module init function.
 **/
void ToolsOnInit()
{
	fnInitSendPropOffset(Player_Spotted, "CBasePlayer", "m_bSpotted");
	fnInitSendPropOffset(Player_SpottedByMask, "CBasePlayer", "m_bSpottedByMask");
	fnInitSendPropOffset(Player_ProgressBarStartTime, "CCSPlayer", "m_flProgressBarStartTime");
	fnInitSendPropOffset(Player_ProgressBarDuration, "CCSPlayer", "m_iProgressBarDuration");
	fnInitSendPropOffset(Player_BlockingUseActionInProgress, "CCSPlayer", "m_iBlockingUseActionInProgress");
	fnInitSendPropOffset(Entity_SimulationTime, "CBaseEntity", "m_flSimulationTime");

	fnInitGameConfAddress(gServerData.Config, pSendTableCRC, "g_SendTableCRC", false);
	
	if (pSendTableCRC != Address_Null)
	{
		StoreToAddress(pSendTableCRC, 1337, NumberType_Int32);

		fnInitGameConfOffset(gServerData.Config, SendProp_iBits, "CSendProp::m_nBits");

		ToolsPatchSendTable(gServerData.Config, pArmorValue, "m_ArmorValue", SendProp_iBits);
		ToolsPatchSendTable(gServerData.Config, pAccount, "m_iAccount", SendProp_iBits);
		ToolsPatchSendTable(gServerData.Config, pHealth, "m_iHealth", SendProp_iBits);
		ToolsPatchSendTable(gServerData.Config, pClip, "m_iClip1", SendProp_iBits);
		ToolsPatchSendTable(gServerData.Config, pPrimary, "m_iPrimaryReserveAmmoCount", SendProp_iBits);
		ToolsPatchSendTable(gServerData.Config, pSecondary, "m_iSecondaryReserveAmmoCount", SendProp_iBits);
		ToolsPatchSendTable(gServerData.Config, pArmorValue, "m_ArmorValue", SendProp_iBits);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "SendTableCRC Patch", "Not able to patch \"g_SendTableCRC\" with invalid address");
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::LookupAttachment");

		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

		if ((hSDKCallLookupAttachment = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::LookupAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::GetAttachment");

		if (gServerData.Platform == OS_Windows)
		{
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		}
		
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
		
		if ((hSDKCallGetAttachment = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::GetAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Entity); 
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::LookupPoseParameter"); 
		
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);  
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); 
		
		if ((hSDKCallLookupPoseParameter = EndPrepSDKCall()) == null) 
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::LookupPoseParameter\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*__________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(gServerData.Platform == OS_Windows ? SDKCall_Entity : SDKCall_Raw); 
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::LookupSequence");
		
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);  
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); 

		if ((hSDKCallLookupSequence = EndPrepSDKCall()) == null) 
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::LookupSequence\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*__________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Entity); 
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::ResetSequence");
		
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);  
		
		if ((hSDKCallResetSequence = EndPrepSDKCall()) == null) 
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::ResetSequence\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*__________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::GetSequenceActivity");

		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

		if ((hSDKCallGetSequenceActivity = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::GetSequenceActivity\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "CBaseEntity::UpdateTransmitState");

		if ((hSDKCallUpdateTransmitState = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseEntity::UpdateTransmitState\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*__________________________________________________________________________________________________*/

	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseEntity::IsBSPModel");
		
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		
		if ((hSDKCallIsBSPModel = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"CBaseEntity::IsBSPModel\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	/*__________________________________________________________________________________________________*/
	
	{
		if (gServerData.Platform == OS_Windows)
		{
			Address pSignature;
			fnInitGameConfAddress(gServerData.Config, pSignature, "FX_FireBullets");
			
			pFireBullets = fnCreateMemoryForSDKCall();
		   
			StartPrepSDKCall(SDKCall_Static);
			PrepSDKCall_SetAddress(pFireBullets);
			
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

			if ((hSDKCallFireBullets = EndPrepSDKCall()) == null)
			{
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"FX_FireBullets\". Update signature in \"%s\"", PLUGIN_CONFIG);
			}
			else
			{
				writeDWORD(ASMTRAMPOLINE, pSignature, 5);
			}
		}
		else
		{
			StartPrepSDKCall(SDKCall_Static);
			PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "FX_FireBullets");
			
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			
			if ((hSDKCallFireBullets = EndPrepSDKCall()) == null)
			{
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "GameData Validation", "Failed to load SDK call \"FX_FireBullets\". Update signature in \"%s\"", PLUGIN_CONFIG);
			}
		}
	}
	
	/*__________________________________________________________________________________________________*/

	/** ~ Retrieving the offsets from game-binary (Linux)
	 *
	 * Animating_StudioHdr:
	 *  1. StudioHdr offset can be retrieved from CBaseAnimating::GetModelPtr()
	 *  2. m_hLightingOrigin offset can be retrieved on runtime using the SM API, or
	 *     in ServerClassInit<DT_BaseAnimating::ignored>() and check the param stack on the SendProp init of m_hLightingOrigin
	 *  3. And lastly: offset = m_pStudioHdr - m_hLightingOrigin
	 *
	 *  One last thing, GetModelPtr() returns a CStudioHdr object, which actually acts like a kind of wrapper of the studiohdr_t object.
	 *  What we actually want is the pointer of the studiohdr_t object. And lucky we are, it located as the first member of the
	 *  CStudioHdr class. This means that we don't need any extra offset to get the pointer from memory.
	 *  
	 * Some useful references:
	 * CStudioHdr: https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/public/studio.h#L2351
	 * studiohdr_t: https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/public/studio.h#L2062
	 * 
	 * StudioHdrStruct_SequenceCount:
	 *  I believe this struct is ancient, and is never expected to change.
	 **/
	
	fnInitGameConfOffset(gServerData.Config, Animating_StudioHdr, "CBaseAnimating::StudioHdr");
	fnInitGameConfOffset(gServerData.Config, StudioHdrStruct_SequenceCount, "StudioHdrStruct::SequenceCount");
	fnInitGameConfOffset(gServerData.Config, VirtualModelStruct_SequenceVector_Size, "VirtualModelStruct::SequenceVectorSize"); 

	int iOffset_LightingOrigin;
	fnInitSendPropOffset(iOffset_LightingOrigin, "CBaseAnimating", "m_hLightingOrigin");
	Animating_StudioHdr += iOffset_LightingOrigin;
}

/**
 * @brief Called once a client successfully connects.
 *
 * @param client            The client index.
 **/
void ToolsOnClientConnect(int client)
{
	gClientData[client].ResetVars();
	gClientData[client].ResetTimers();
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param client            The client index.
 **/
void ToolsOnClientDisconnectPost(int client)
{
	gClientData[client].ResetVars();
	gClientData[client].ResetTimers();
}

/**
 * Hook: SetTransmit
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entity            The entity index.
 * @param client            The client index.
 **/
public Action ToolsOnEntityTransmit(int entity, int client)
{
	int owner = ToolsGetOwner(entity);

	if (owner == client || (ToolsGetObserverMode(client) == SPECMODE_FIRSTPERSON && owner == ToolsGetObserverTarget(client)))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/*
 * Tools natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void ToolsOnNativeInit()
{
	CreateNative("ZP_LookupAttachment",     API_LookupAttachment);
	CreateNative("ZP_GetAttachment",        API_GetAttachment);
	CreateNative("ZP_LookupSequence",       API_LookupSequence);
	CreateNative("ZP_LookupPoseParameter",  API_LookupPoseParameter);
	CreateNative("ZP_ResetSequence",        API_ResetSequence);
	CreateNative("ZP_GetSequenceActivity",  API_GetSequenceActivity);
	CreateNative("ZP_GetSequenceCount",     API_GetSequenceCount);
	CreateNative("ZP_IsBSPModel",           API_IsBSPModel);
	CreateNative("ZP_FireBullets",          API_FireBullets);
	CreateNative("ZP_UpdateTransmitState",  API_UpdateTransmitState);
	CreateNative("ZP_RespawnPlayer",        API_RespawnPlayer);
	CreateNative("ZP_FindPlayerInSphere",   API_FindPlayerInSphere);
	CreateNative("ZP_SetProgressBarTime",   API_SetProgressBarTime);
}

/**
 * @brief Validate the attachment on the entity.
 *
 * @note native bool ZP_LookupAttachment(entity, attach);
 **/
public int API_LookupAttachment(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return -1;
	}

	int maxLen;
	GetNativeStringLength(2, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sAttach[SMALL_LINE_LENGTH];
	GetNativeString(2, sAttach, sizeof(sAttach));
	
	return ToolsLookupAttachment(entity, sAttach);
}

/**
 * @brief Gets the attachment of the entity.
 *
 * @note native void ZP_GetAttachment(entity, attach, origin, angles);
 **/
public int API_GetAttachment(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return -1;
	}
	
	int maxLen;
	GetNativeStringLength(2, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sAttach[SMALL_LINE_LENGTH]; static float vPosition[3]; static float vAngle[3];

	GetNativeString(2, sAttach, sizeof(sAttach));
	
	ToolsGetAttachment(entity, sAttach, vPosition, vAngle);
	
	SetNativeArray(3, vPosition, sizeof(vPosition)); return SetNativeArray(4, vAngle, sizeof(vAngle));
}

/**
 * @brief Gets the sequence of the entity.
 *
 * @note native int ZP_LookupSequence(entity, anim);
 **/
public int API_LookupSequence(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return -1;
	}
	
	int maxLen;
	GetNativeStringLength(2, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sAnim[SMALL_LINE_LENGTH];
	GetNativeString(2, sAnim, sizeof(sAnim));
	
	return ToolsLookupSequence(entity, sAnim);
}

/**
 * @brief Gets the pose of the entity.
 *
 * @note native int ZP_LookupPoseParameter(entity, pose);
 **/
public int API_LookupPoseParameter(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return -1;
	}
	
	int maxLen;
	GetNativeStringLength(2, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sPose[SMALL_LINE_LENGTH];
	GetNativeString(2, sPose, sizeof(sPose));
	
	return ToolsLookupPoseParameter(entity, sPose);
} 

/**
 * @brief Resets the sequence of the entity.
 *
 * @note native int ZP_ResetSequence(entity, name);
 **/
public int API_ResetSequence(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return -1;
	}
	
	int maxLen;
	GetNativeStringLength(2, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sAnim[SMALL_LINE_LENGTH];
	GetNativeString(2, sAnim, sizeof(sAnim));
	
	ToolsResetSequence(entity, sAnim);
	
	return 1;
}

/**
 * @brief Gets the total sequence amount.
 *
 * @note native int ZP_GetSequenceCount(entity);
 **/
public int API_GetSequenceCount(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return -1;
	}
	
	return ToolsGetSequenceCount(entity);
}

/**
 * @brief Gets the activity of a sequence.
 *
 * @note native int ZP_GetSequenceActivity(entity, sequence);
 **/
public int API_GetSequenceActivity(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return -1;
	}

	return ToolsGetSequenceActivity(entity, GetNativeCell(2));
}

/**
 * @brief Checks that the entity is a brush.
 *
 * @note native bool ZP_IsBSPModel(entity);
 **/
public int API_IsBSPModel(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return false;
	}
	
	return ToolsIsBSPModel(entity);
}

/**
 * @brief Emulate bullet_shot on the server and does the damage calculations.
 *
 * @note native bool ZP_FireBullets(clientIndex, weaponIndex, origin, angle, mode, seed, inaccuracy, spread, sound);
 **/
public int API_FireBullets(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	if (!IsPlayerExist(client))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the client index (%d)", client);
		return false;
	}
	
	int weapon = GetNativeCell(2);
	
	if (!IsValidEdict(weapon))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the weapon index (%d)", weapon);
		return false;
	}
	
	static float vPosition[3];
	GetNativeArray(3, vPosition, sizeof(vPosition));
	
	static float vAngle[3];
	GetNativeArray(4, vAngle, sizeof(vAngle));
	
	ToolsFireBullets(client, weapon, vPosition, vAngle, GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8), GetNativeCell(9), GetNativeCell(10), GetNativeCell(11));
	return true;
}

/**
 * @brief Update a entity transmit state.
 *
 * @note native bool ZP_UpdateTransmitState(entity);
 **/
public int API_UpdateTransmitState(Handle hPlugin, int iNumParams)
{
	int entity = GetNativeCell(1);
	
	if (!IsValidEdict(entity))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the entity index (%d)", entity);
		return false;
	}
	
	ToolsUpdateTransmitState(entity);
	return true;
}

/**
 * @brief Respawn a player.
 *
 * @note native bool ZP_RespawnPlayer(client);
 **/
public int API_RespawnPlayer(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	if (!IsPlayerExist(client))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the client index (%d)", client);
		return false;
	}
	
	return ToolsForceToRespawn(client);
}

/**
 * @brief Used to iterate all the clients collision within a sphere.
 *
 * @note native int ZP_FindPlayerInSphere(&it, center, radius);
 **/
public int API_FindPlayerInSphere(Handle hPlugin, int iNumParams)
{
	int it = GetNativeCellRef(1);
	
	static float vPosition[3];
	GetNativeArray(2, vPosition, sizeof(vPosition));

	int client = AntiStickFindPlayerInSphere(it, vPosition, GetNativeCell(3));
	
	SetNativeCellRef(1, it);
	
	return client;
}

/**
 * @brief Sets the player progress bar.
 *
 * @note native bool ZP_SetProgressBarTime(client, duration);
 **/
public int API_SetProgressBarTime(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	if (!IsPlayerExist(client))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Tools, "Native Validation", "Invalid the client index (%d)", client);
		return false;
	}
	
	ToolsSetProgressBarTime(client, GetNativeCell(2));
	return true;
}

/*
 * Stocks tools API.
 */

/**
 * @brief Returns an address value from a given config.
 *
 * @param gameConf          The game config handle.
 * @param pAddress          An address to patch, or null on failure.
 * @param sKey              Key to retrieve from the address section.
 * @param bFatal            (Optional) If true, invalid values will stop the plugin with the specified message.
 **/
void ToolsPatchSendTable(GameData gameConf, Address &pAddress, char[] sKey, int iBits)
{
	fnInitGameConfAddress(gameConf, pAddress, sKey, false);
	
	if (pAddress != Address_Null) 
	{
		StoreToAddress(pAddress + view_as<Address>(iBits), 32, NumberType_Int32);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "SendTableCRC Patch", "Not able to patch \"%s\" with invalid address", sKey);
	}
}
