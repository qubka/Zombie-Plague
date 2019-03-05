/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          weaponhdr.cpp
 *  Type:          Module
 *  Description:   Weapon HDR models functions.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin), Andersso
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
 
/* ~ Retrieving the offsets from game-binary (Linux)
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
 */

/**
 * Sequence paired address.
 **/
#define SWAP_SEQ_PAIRED (1<<31)
 
/**
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallAnimatingGetSequenceActivity;
Handle hSDKCallViewUpdateTransmitState; // UpdateTransmitState will stop the viewmodel from transmitting if EF_NODRAW flag is present

/**
 * Variables to store virtual SDK adresses.
 **/
int Animating_StudioHdr;
int StudioHdrStruct_SequenceCount;
int VirtualModelStruct_SequenceVector_Size;
 
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
    StudioAnimDesc_NumMovements = 20,
};
/**
 * @endsection
 **/
 
/**
 * @brief Initialize the main virtual offsets for the weapon HDR system.
 **/
void WeaponHDROnInit(/*void*/)
{
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CBaseAnimating::GetSequenceActivity");

    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if(!(hSDKCallAnimatingGetSequenceActivity = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::GetSequenceActivity\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "CBaseViewModel::UpdateTransmitState");

    // Validate call
    if(!(hSDKCallViewUpdateTransmitState = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseViewModel::UpdateTransmitState\". Update offset in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Load other offsets
    fnInitGameConfOffset(gServerData.Config, Animating_StudioHdr, "CBaseAnimating::StudioHdr");
    fnInitGameConfOffset(gServerData.Config, StudioHdrStruct_SequenceCount, "StudioHdrStruct::SequenceCount");
    fnInitGameConfOffset(gServerData.Config, VirtualModelStruct_SequenceVector_Size, "VirtualModelStruct::SequenceVectorSize");
    
    /// Info bellow
    int lightingOriginOffset;
    fnInitSendPropOffset(lightingOriginOffset, "CBaseAnimating", "m_hLightingOrigin");
    
    // StudioHdr offset in gameconf is only relative to the offset of m_hLightingOrigin, in order to make the offset more resilient to game updates
    Animating_StudioHdr += lightingOriginOffset;
}

/**
 * @brief Creates the swapped (custom) weapon for the client.
 *
 * @param clientIndex       The cleint index.
 * @param viewIndex         The view index.
 * @param iD                The weapon id.
 **/
void WeaponHDRToggleViewModel(int clientIndex, int viewIndex, int iD)
{
    // Initialize index
    int weaponIndex;

    // Resets toggle
    if((gClientData[clientIndex].ToggleSequence = !gClientData[clientIndex].ToggleSequence))
    {
        // Gets swapped weapon index from the reference
        weaponIndex = EntRefToEntIndex(gClientData[clientIndex].SwapWeapon);

        // Validate no weapon, then create a swaped pair 
        if(weaponIndex == INVALID_ENT_REFERENCE)
        {
            weaponIndex = WeaponHDRCreateSwapWeapon(iD, clientIndex);
            gClientData[clientIndex].SwapWeapon = EntIndexToEntRef(weaponIndex);
        }
    }
    else
    {
        // Gets weapon index from the reference
        weaponIndex = gClientData[clientIndex].CustomWeapon;
    }

    // Sets a model for the weapon
    SetEntDataEnt2(viewIndex, g_iOffset_ViewModelWeapon, weaponIndex, true);
}

/**
 * @brief Gets the view (player) weapon model.
 *
 * @param clientIndex       The cleint index.
 * @param viewIndex         The view index.
 * @return                  The model index.
 **/
int WeaponHDRGetPlayerViewModel(int clientIndex, int viewIndex)
{
    // Gets viewmodel of the client
    return GetEntDataEnt2(clientIndex, g_iOffset_PlayerViewModel + (viewIndex * 4));
}

/**
 * @brief Sets the view (player) weapon model.
 *
 * @param clientIndex       The cleint index.
 * @param viewIndex         The view index.
 * @param iModel            The model index.
**/
void WeaponHDRSetPlayerViewModel(int clientIndex, int viewIndex, int iModel)
{
    // Sets viewmodel for the client
    SetEntDataEnt2(clientIndex, g_iOffset_PlayerViewModel + (viewIndex * 4), iModel, true);
}

/**
 * @brief Sets the world (player) weapon model.
 *
 * @param weaponIndex       The weapon index.
 * @param iModel            (Optional) The model index.
 * @param iBody             (Optional) The body index.
 * @param iSkin             (Optional) The skin index.
 **/
void WeaponHDRSetPlayerWorldModel(int weaponIndex, int iModel = 0, int iBody = 0, int iSkin = 0)
{ 
    // Gets worldmodel entity
    int worldIndex = GetEntDataEnt2(weaponIndex, g_iOffset_WeaponWorldModel);

    // Validate worldmodel
    if(worldIndex != INVALID_ENT_REFERENCE)
    {
        // Sets model index for the worldmodel
        ToolsSetEntityModelIndex(worldIndex, iModel);
        
        // Validate model
        if(iModel) 
        {
            // Find the datamap
            if(!g_iOffset_WeaponWorldSkin)
            {
                g_iOffset_WeaponWorldSkin = FindDataMapInfo(worldIndex, "m_nSkin"); /// Not work properly, but data offset exist in CBaseWeaponWorldModel
            }

            // Sets body/skin index for the worldmodel
            WeaponHDRSetTextures(worldIndex, iBody);
            SetEntData(worldIndex, g_iOffset_WeaponWorldSkin, iSkin, _, true); /// Not work 
        }
    }//                                                                                       Using CBaseWeaponWorldModel - weaponworldmodel instead                                                                  
    ///ToolsSetEntityModelIndex(weaponIndex, WeaponsGetModelWorldID(iD)); for m_iWorldModelIndex not support body/skin!                                                                                               
}

/**
 * @brief Sets the world (dropped) weapon model.
 *
 * @param referenceIndex    The reference index.
 **/
public void WeaponHDRSetDroppedModel(int referenceIndex)
{
    // Gets weapon index from the reference
    int weaponIndex = EntRefToEntIndex(referenceIndex);
    
    // Validate weapon
    if(weaponIndex != INVALID_ENT_REFERENCE)
    {
        // Validate custom index
        int iD = WeaponsGetCustomID(weaponIndex);
        if(iD != -1)
        {
            // If dropmodel exist, then apply it
            if(WeaponsGetModelDropID(iD))
            {
                // Gets weapon dropmodel
                static char sModel[PLATFORM_LINE_LENGTH];
                WeaponsGetModelDrop(iD, sModel, sizeof(sModel));
                
                // Sets dropped model for the weapon
                SetEntityModel(weaponIndex, sModel);
                
                // Sets body/skin index for the weapon
                WeaponHDRSetTextures(weaponIndex, WeaponsGetModelBody(iD, ModelType_Drop),  WeaponsGetModelSkin(iD, ModelType_Drop));
            }
        }
    }
}

/**
 * @brief Sets invisibily/visibility for the weapon.
 *
 * @param weaponIndex       The weapon index.
 * @param bInvisible        True or false.
 **/
void WeaponHDRSetEntityVisibility(int weaponIndex, bool bInvisible)
{
    int iFlags = ToolsGetEntityEffect(weaponIndex);
    ToolsSetEntityEffect(weaponIndex, bInvisible ? (iFlags & ~EF_NODRAW) : (iFlags | EF_NODRAW));
}

/**
 * @brief Sets body/skin for the weapon.
 *
 * @param weaponIndex       The weapon index.
 * @param iBody             (Optional) The body index.
 * @param iSkin             (Optional) The skin index.
 **/
void WeaponHDRSetTextures(int weaponIndex, int iBody = -1, int iSkin = -1)
{
    if(iBody != -1) SetEntData(weaponIndex, g_iOffset_WeaponBody, iBody, _, true);
    if(iSkin != -1) SetEntData(weaponIndex, g_iOffset_WeaponSkin, iSkin, _, true);
}

/**
 * @brief Sets a swap weapon to a player.
 *
 * @param iD                The weapon id.
 * @param clientIndex       The client index.
 * @return                  The weapon index
 **/
int WeaponHDRCreateSwapWeapon(int iD, int clientIndex)
{
    // Gets weapon index from the reference
    int weaponIndex1 = gClientData[clientIndex].CustomWeapon;

    // i = weapon number
    static int iSize; if(!iSize) iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex2 = GetEntDataEnt2(clientIndex, g_iOffset_CharacterWeapons + (i * 4));
        
        // Validate swapped weapon
        if(weaponIndex2 != INVALID_ENT_REFERENCE && weaponIndex1 != weaponIndex2)
        {
            return weaponIndex2;
        }
    }
    
    // Gets weapon classname
    static char sClassname[SMALL_LINE_LENGTH];
    WeaponsGetEntity(iD, sClassname, sizeof(sClassname)); 
    
    // Creates an attach swapped entity
    weaponIndex1 = CreateEntityByName(sClassname);

    // If entity isn't valid, then log
    if(weaponIndex1 != INVALID_ENT_REFERENCE)
    {
        // Spawn the entity into the world
        DispatchSpawn(weaponIndex1);

        // Sets weapon id
        WeaponsSetCustomID(weaponIndex1, iD);
        
        // Sets parent to the entity
        WeaponsSetOwner(weaponIndex1, clientIndex);
        ToolsSetEntityOwner(weaponIndex1, clientIndex);

        // Remove an entity movetype
        SetEntityMoveType(weaponIndex1, MOVETYPE_NONE);

        // Sets parent of a weapon
        SetVariantString("!activator");
        AcceptEntityInput(weaponIndex1, "SetParent", clientIndex);
    }
    else
    {
        // Unexpected error, log it
        LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Weapons, "Config Validation", "Failed to create swap weapon entity: \"%s\"", sClassname);
    }

    // Return on success
    return weaponIndex1;
}

/**
 * @brief Generate a new sequence for the (any) custom viewmodels.
 * 
 * @author This algorithm made by Andersso. But he hope, it as fast as it can be. Regards to him a lot.
 *
 * @param iSequences        The sequence array.
 * @param iSequenceCount    The sequence count.
 * @param weaponIndex       The weapon index.
 * @param iIndex            The sequence cell.
 * @return                  The sequence index.
 **/
int WeaponHDRBuildSwapSequenceArray(int iSequences[WEAPONS_SEQUENCE_MAX], int iSequenceCount, int weaponIndex, int iIndex = 0)
{
    // Initialize variables
    int iValue = iSequences[iIndex]; int swapIndex = -1;

    // Validate empty sequence
    if(!iValue)
    {
        // Continue to next if sequence wasn't an activity
        if((iValue = iSequences[iIndex] = WeaponHDRGetSequenceActivity(weaponIndex, iIndex)) == -1)
        {
            // Validate not a filled sequence
            if(++iIndex < iSequenceCount)
            {
                WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weaponIndex, iIndex);
                return -1;
            }
            
            // Return on success
            return 0;
        }
    }
    // Shift a big
    else if(iValue == -1)
    {
        // Validate not a filled sequence
        if(++iIndex < iSequenceCount)
        {
            WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weaponIndex, iIndex);
            return -1;
        }
        // Return on success
        return 0;
    }
    // Validate equality
    else if(iValue & SWAP_SEQ_PAIRED)
    {
        // Gets index
        swapIndex = (iValue & ~SWAP_SEQ_PAIRED) >> 16;

        // Gets activity value
        iValue &= 0x0000FFFF;
    }
    else
    {
        // Return on success
        return 0;
    }

    // i = sequence index
    for(int i = iIndex + 1; i < iSequenceCount; i++)
    {
        // Find next sequence
        int nextValue = WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weaponIndex, i);

        // Validate cell
        if(iValue == nextValue)
        {
            // Update
            swapIndex = i;

            // Let the index be be stored after the 16th bit, and add a bit-flag to indicate this being done
            iSequences[i] = nextValue | (iIndex << 16) | SWAP_SEQ_PAIRED;
            break;
        }
    }
    
    // Update the sequence array
    iSequences[iIndex] = swapIndex;
    
    // Return the sequence cell
    return iValue;
}

/**
 * @brief This function simulates the equivalent function in the SDK.
 *
 * @note The game has two methods for getting the sequence count:
 * 
 * 1. Local sequence count if the model has sequences built in the model itself.
 * 2. Virtual model sequence count if the model inherits the sequences from a different model, also known as an include model.
 *
 * @param iAnimating        The animating index.
 * @return                  The sequence count.
 **/
int WeaponHDRGetSequenceCount(int iAnimating)
{
    // Load some bytes from a memory address
    Address studioHdrClass = view_as<Address>(GetEntData(iAnimating, Animating_StudioHdr));
    
    // Validate address
    if(studioHdrClass == Address_Null)
    {
        return -1;
    }
    
    // Load some bytes from a memory address
    Address studioHdrStruct = view_as<Address>(LoadFromAddress(studioHdrClass + view_as<Address>(StudioHdrClass_StudioHdrStruct), NumberType_Int32));
    
    // Validate address
    if(studioHdrStruct != Address_Null)
    {
        int localSequenceCount = LoadFromAddress(studioHdrStruct + view_as<Address>(StudioHdrStruct_SequenceCount), NumberType_Int32);
        if(localSequenceCount)
        {
            return localSequenceCount;
        }
    }
    
    // Load some bytes from a memory address
    Address virtualModelStruct = view_as<Address>(LoadFromAddress(studioHdrClass + view_as<Address>(StudioHdrClass_VirualModelStruct), NumberType_Int32));
    
    // Validate address
    if(virtualModelStruct != Address_Null)
    {
        return LoadFromAddress(virtualModelStruct + view_as<Address>(VirtualModelStruct_SequenceVector_Size), NumberType_Int32);
    }
    
    // Return on unsuccess 
    return -1;
}

/**
 * @brief Calls an SDK sequence activity function with the given parameters.
 *
 * If the call type is Entity or Player, the index MUST ALWAYS be the FIRST parameter passed. 
 * If the call type is GameRules, then nothing special needs to be passed. 
 * If the return value is a Vector or QAngles, the SECOND parameter must be a Float[3]. 
 * If the return value is a string, the THIRD parameter must be a String buffer, and the FOURTH parameter must be the maximum length. 
 * All parameters must be passed after the above is followed. Failure to follow these rules will result in crashes or wildly unexpected behavior!
 *
 * If the return value is a float or integer, the return value will be this value. 
 * If the return value is a CBaseEntity, CBasePlayer, or edict, the return value will always be the entity index, or -1 for NULL.
 *
 * @note This function is far to advanced to be cloned.
 *
 * @param iAnimating        The animating index.
 * @param iSequence         The sequence index.
 * @return                  The activity index.
 **/
int WeaponHDRGetSequenceActivity(int iAnimating, int iSequence)
{
    return SDKCall(hSDKCallAnimatingGetSequenceActivity, iAnimating, iSequence);
}

/**
 * @brief Update a viewmodel transmit state.
 * 
 * @param iAnimating        The animating index.
 **/
void WeaponHDRUpdateTransmitState(int iAnimating)
{
    SDKCall(hSDKCallViewUpdateTransmitState, iAnimating);
}










/*
Address Animating_GetStudioHdrClass(int iAnimating)
{
    return view_as<Address>(GetEntData(iAnimating, Animating_StudioHdr));
}

Address StudioHdrClass_GetStudioHdrStruct(Address studioHdrClass)
{
    return studioHdrClass != Address_Null ? view_as<Address>(LoadFromAddress(studioHdrClass, NumberType_Int32)) : Address_Null;
}

int StudioHdrGetSequenceCount(Address studioHdrStruct)
{
    return LoadFromAddress(studioHdrStruct + view_as<Address>(StudioHdrStruct_SequenceCount), NumberType_Int32);
}

int Animating_GetNumMovements(int iAnimating, int iSequence)
{
    Address studioHdrStruct = StudioHdrClass_GetStudioHdrStruct(Animating_GetStudioHdrClass(iAnimating));
    Address studioAnimDesc = GetLocalAnimDescription(studioHdrStruct, iSequence);
    return StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_NumMovements);
}

float Animating_GetSequenceDuration(int iAnimating, int iSequence)
{
    Address studioHdrStruct = StudioHdrClass_GetStudioHdrStruct(Animating_GetStudioHdrClass(iAnimating));
    Address studioAnimDesc = GetLocalAnimDescription(studioHdrStruct, iSequence);
    PrintToServer("%f - %d", StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_Fps), StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_NumFrames));
    float cyclesPerSecond = view_as<float>(StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_Fps)) / (StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_NumFrames) - 1);
    return cyclesPerSecond != 0.0 ? 1.0 / cyclesPerSecond : 0.0;
}

Address GetLocalAnimDescription(Address studioHdrStruct, int &iSequence)
{
    if(iSequence < 0 || iSequence >= StudioHdrGetSequenceCount(studioHdrStruct))
    {
        iSequence = 0;
    }
    
    // return (mstudioanimdesc_t *)(((byte *)this) + localanimindex) + i;
    return studioHdrStruct + view_as<Address>(LoadFromAddress(studioHdrStruct + view_as<Address>(184), NumberType_Int32) + (iSequence * 4));
}

any StudioAnimDesc_GetValue(Address studioAnimDesc, StudioAnimDesc type, NumberType size = NumberType_Int32)
{
    return LoadFromAddress(studioAnimDesc + view_as<Address>(type), size);
}*/