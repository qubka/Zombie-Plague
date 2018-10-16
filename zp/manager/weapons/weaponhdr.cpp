/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          weaponhdr.cpp
 *  Type:          Module
 *  Description:   Weapon view/world models functions.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin), Andersso
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
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallAnimatingGetSequenceActivity;

/**
 * Variables to store virtual SDK adresses.
 **/
int Animating_StudioHdr;
int StudioHdrStruct_SequenceCount;
int VirtualModelStruct_SequenceVector_Size;
 
/**
 * StudioHdr structure.
 * https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/public/studio.h#L2371
 **/ 
enum StudioHdrClass
{
    StudioHdrClass_StudioHdrStruct = 0,
    StudioHdrClass_VirualModelStruct = 4
}

/**
 * StudioHdr structure.
 * https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/public/studio.h#L690
 **/ 
enum StudioAnimDesc
{
    StudioAnimDesc_Fps = 8,
    StudioAnimDesc_NumFrames = 16,
    StudioAnimDesc_NumMovements = 20,
}
 
/**
 * Initialize the main virtual offsets for the weapon HDR system.
 **/
void WeaponHDRInit(/*void*/)
{
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gServerData[Server_GameConfig][Game_Zombie], SDKConf_Signature, "Animating_GetSequenceActivity");

    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if(!(hSDKCallAnimatingGetSequenceActivity = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Weapons, "GameData Validation", "Failed to load SDK call \"CBaseAnimating::GetSequenceActivity\". Update signature in \"%s\"", PLUGIN_CONFIG);
    }
    
    // Load other offsets
    fnInitGameConfOffset(gServerData[Server_GameConfig][Game_Zombie], Animating_StudioHdr, "Animating_StudioHdr");
    fnInitGameConfOffset(gServerData[Server_GameConfig][Game_Zombie], StudioHdrStruct_SequenceCount, "StudioHdrStruct_SequenceCount");
    fnInitGameConfOffset(gServerData[Server_GameConfig][Game_Zombie], VirtualModelStruct_SequenceVector_Size, "VirtualModelStruct_SequenceVector_Size");
    
    /// Info bellow
    int lightingOriginOffset;
    fnInitSendPropOffset(lightingOriginOffset, "CBaseAnimating", "m_hLightingOrigin");
    
    // StudioHdr offset in gameconf is only relative to the offset of m_hLightingOrigin, in order to make the offset more resilient to game updates
    Animating_StudioHdr += lightingOriginOffset;
}

/**
 * Create the swapped (custom) weapon for the client.
 *
 * @param clientIndex       The cleint index.
 * @param viewIndex         The view index.
 * @param iD                The weapon index.
 **/
stock void WeaponHDRToggleViewModel(const int clientIndex, const int viewIndex, const int iD)
{
    // Initialize variable
    static int weaponIndex;

    // Resets toggle
    if((gClientData[clientIndex][Client_ToggleSequence] = !gClientData[clientIndex][Client_ToggleSequence]))
    {
        // Gets the swapped weapon index from the reference
        weaponIndex = EntRefToEntIndex(gClientData[clientIndex][Client_SwapWeapon]);

        // Validate no weapon, then create a swaped pair 
        if(weaponIndex == INVALID_ENT_REFERENCE)
        {
            weaponIndex = WeaponHDRCreateSwapWeapon(iD, clientIndex);
            gClientData[clientIndex][Client_SwapWeapon] = EntIndexToEntRef(weaponIndex);
        }
    }
    else
    {
        // Gets the weapon index from the reference
        weaponIndex = gClientData[clientIndex][Client_CustomWeapon];
    }

    // Sets a model for the weapon
    SetEntDataEnt2(viewIndex, g_iOffset_ViewModelWeapon, weaponIndex, true);
}

/**
 * Gets the view (player) weapon model.
 *
 * @param clientIndex       The cleint index.
 * @param viewIndex         The view index.
 * @return                  The model index.
 **/
stock int WeaponHDRGetPlayerViewModel(const int clientIndex, const int viewIndex)
{
    // Gets viewmodel of the client
    return GetEntDataEnt2(clientIndex, g_iOffset_PlayerViewModel + (viewIndex * 4));
}

/**
 * Sets the view (player) weapon model.
 *
 * @param clientIndex       The cleint index.
 * @param viewIndex         The view index.
 * @param modelIndex        The model index.
 **/
stock void WeaponHDRSetPlayerViewModel(const int clientIndex, const int viewIndex, const int modelIndex)
{
    // Sets viewmodel for the client
    SetEntDataEnt2(clientIndex, g_iOffset_PlayerViewModel + (viewIndex * 4), modelIndex, true);
}

/**
 * Sets the world (player) weapon model.
 *
 * @param weaponIndex       The weapon index.
 * @param modelIndex        (Optional) The model index.
 * @param bodyIndex         (Optional) The body index.
 * @param skinIndex         (Optional) The skin index.
 **/
stock void WeaponHDRSetPlayerWorldModel(const int weaponIndex, const int modelIndex = 0, const int bodyIndex = 0, const int skinIndex = 0)
{ 
    // Get worldmodel entity
    int worldIndex = GetEntDataEnt2(weaponIndex, g_iOffset_WeaponWorldModel);

    // Validate worldmodel
    if(IsValidEdict(worldIndex))
    {
        // Sets model index for the worldmodel
        SetEntData(worldIndex, g_iOffset_EntityModelIndex, modelIndex, _, true);
        
        // Validate model
        if(modelIndex) 
        {
            // Find the datamap
            if(!g_iOffset_WeaponWorldSkin)
            {
                g_iOffset_WeaponWorldSkin = FindDataMapInfo(worldIndex, "m_nSkin"); /// Not work properly, but data offset exist in CBaseWeaponWorldModel
            }

            // Sets body/skin index for the worldmodel
            SetEntData(worldIndex, g_iOffset_WeaponBody, bodyIndex, _, true);
            SetEntData(worldIndex, g_iOffset_WeaponWorldSkin, skinIndex, _, true);
        }
    }//                                                                                       Using CBaseWeaponWorldModel - weaponworldmodel instead                                                                  
    ///SetEntData(weaponIndex, g_iOffset_EntityModelIndex, WeaponsGetModelWorldID(iD), _, true); for m_iWorldModelIndex not support body/skin!                                                                                               
}

/**
 * Sets the world (dropped) weapon model.
 *
 * @param referenceIndex    The reference index.
 **/
public void WeaponHDRSetDroppedModel(const int referenceIndex)
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
            // If dropmodel exist, then apply it
            if(WeaponsGetModelDropID(iD))
            {
                // Gets weapon dropmodel
                static char sModel[PLATFORM_MAX_PATH];
                WeaponsGetModelDrop(iD, sModel, sizeof(sModel));
                
                // Sets dropped model for the weapon
                SetEntityModel(weaponIndex, sModel);
                
                // Sets the body/skin index for the weapon
                SetEntData(weaponIndex, g_iOffset_WeaponBody, WeaponsGetModelBody(iD, ModelType_Drop), _, true);
                SetEntData(weaponIndex, g_iOffset_WeaponSkin, WeaponsGetModelSkin(iD, ModelType_Drop), _, true);
            }
        }
    }
}

/**
 * Sets invisibily/visibility for the entity.
 *
 * @param entityIndex       The entity index.
 * @param bInvisible        True or false.
 **/
stock void WeaponHDRSetEntityVisibility(const int entityIndex, const bool bInvisible)
{
    int iFlags = GetEntData(entityIndex, g_iOffset_EntityEffects);
    SetEntData(entityIndex, g_iOffset_EntityEffects, bInvisible ? iFlags & ~EF_NODRAW : iFlags | EF_NODRAW, _, true);
}

/**
 * Sets a swap weapon to a player.
 *
 * @param iD                The weapon id.
 * @param clientIndex       The client index.
 * @return                  The weapon index
 **/
stock int WeaponHDRCreateSwapWeapon(const int iD, const int clientIndex)
{
    // Gets the weapon index from the reference
    int weaponIndex1 = gClientData[clientIndex][Client_CustomWeapon];

    // i = weapon number
    static int iSize; if(!iSize) iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex2 = GetEntDataEnt2(clientIndex, g_iOffset_CharacterWeapons + (i * 4));
        
        // Validate swapped weapon
        if(IsValidEdict(weaponIndex2) && weaponIndex1 != weaponIndex2)
        {
            return weaponIndex2;
        }
    }
    
    // Gets weapon classname
    static char sWeapon[SMALL_LINE_LENGTH];
    WeaponsGetEntity(iD, sWeapon, sizeof(sWeapon)); 
    
    // Create an attach swapped entity
    int itemIndex = CreateEntityByName(sWeapon);

    // If entity isn't valid, then log
    if(itemIndex != INVALID_ENT_REFERENCE)
    {
        // Spawn the entity into the world
        DispatchSpawn(itemIndex);

        // Sets the weapon id
        WeaponsSetCustomID(itemIndex, iD);
        
        // Sets parent to the entity
        SetEntDataEnt2(itemIndex, g_iOffset_WeaponOwner, clientIndex, true);
        SetEntDataEnt2(itemIndex, g_iOffset_EntityOwnerEntity, clientIndex, true);

        // Remove an entity movetype
        SetEntityMoveType(itemIndex, MOVETYPE_NONE);

        // Sets the parent of a weapon
        SetVariantString("!activator");
        AcceptEntityInput(itemIndex, "SetParent", clientIndex);
    }
    else
    {
        // Unexpected error, log it
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Config Validation", "Failed to create swap weapon entity: \"%s\"", sWeapon);
    }

    // Return on the success
    return itemIndex;
}

/**
 * Generate a new sequence for the (any) custom viewmodels.
 * This algorithm give Andersso an headache. But he hope, it as fast as it can be. Regards to him a lot.
 *
 * @param iSequences        The sequence array.
 * @param nSequenceCount    The sequence count.
 * @param weaponIndex       The weapon index.
 * @param iIndex            The sequence cell.
 * @return                  The sequence index.
 **/
stock int WeaponHDRBuildSwapSequenceArray(int iSequences[WeaponsSequencesMax], const int nSequenceCount, const int weaponIndex, int iIndex = 0)
{
    #define SWAP_SEQ_PAIRED (1 << 31)
    
    // Initialize variables
    int iValue = iSequences[iIndex]; int swapIndex = -1;

    // Validate empty sequence
    if(!iValue)
    {
        // Continue to next if sequence wasn't an activity
        if((iValue = iSequences[iIndex] = Animating_GetSequenceActivity(weaponIndex, iIndex)) == -1)
        {
            // Validate not a filled sequence
            if(++iIndex < nSequenceCount)
            {
                WeaponHDRBuildSwapSequenceArray(iSequences, nSequenceCount, weaponIndex, iIndex);
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
        if(++iIndex < nSequenceCount)
        {
            WeaponHDRBuildSwapSequenceArray(iSequences, nSequenceCount, weaponIndex, iIndex);
            return -1;
        }
        // Return on success
        return 0;
    }
    // Validate equality
    else if(iValue & SWAP_SEQ_PAIRED)
    {
        // Gets the index
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
    for(int i = iIndex + 1; i < nSequenceCount; i++)
    {
        // Find next sequence
        int nextValue = WeaponHDRBuildSwapSequenceArray(iSequences, nSequenceCount, weaponIndex, i);

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
 * This function simulates the equivalent function in the SDK.
 *
 * The game has two methods for getting the sequence count:
 * 
 * 1. Local sequence count if the model has sequences built in the model itself.
 * 2. Virtual model sequence count if the model inherits the sequences from a different model, also known as an include model.
 *
 * @param iAnimating        The animating index.
 * @return                  The sequence count.
 **/
stock int Animating_GetSequenceCount(const int iAnimating)
{
    // Load some bytes from a memory address
    Address studioHdrClass = view_as<Address>(GetEntData(iAnimating, Animating_StudioHdr));
    
    // Validate adress
    if(studioHdrClass == Address_Null)
    {
        return -1;
    }
    
    // Load some bytes from a memory address
    Address studioHdrStruct = view_as<Address>(LoadFromAddress(studioHdrClass + view_as<Address>(StudioHdrClass_StudioHdrStruct), NumberType_Int32));
    
    // Validate adress
    if(studioHdrStruct != Address_Null)
    {
        int localSequenceCount = LoadFromAddress(studioHdrStruct + view_as<Address>(StudioHdrStruct_SequenceCount), NumberType_Int32);
        
        if(localSequenceCount != 0)
        {
            return localSequenceCount;
        }
    }
    
    // Load some bytes from a memory address
    Address virtualModelStruct = view_as<Address>(LoadFromAddress(studioHdrClass + view_as<Address>(StudioHdrClass_VirualModelStruct), NumberType_Int32));
    
    // Validate adress
    if(virtualModelStruct != Address_Null)
    {
        return LoadFromAddress(virtualModelStruct + view_as<Address>(VirtualModelStruct_SequenceVector_Size), NumberType_Int32);
    }
    
    // Return on unsuccess 
    return -1;
}

/**
 * Calls an SDK sequence activity function with the given parameters.
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
 * This function is far to advanced to be cloned.
 *
 * @param iAnimating            The animating index.
 * @param nSequence             The sequence index.
 * @return                      The activity index.
 **/
stock int Animating_GetSequenceActivity(const int iAnimating, const int nSequence)
{
    return SDKCall(hSDKCallAnimatingGetSequenceActivity, iAnimating, nSequence);
}

/*
stock Address Animating_GetStudioHdrClass(const int iAnimating)
{
    return view_as<Address>(GetEntData(iAnimating, Animating_StudioHdr));
}

stock Address StudioHdrClass_GetStudioHdrStruct(Address studioHdrClass)
{
    return studioHdrClass != Address_Null ? view_as<Address>(LoadFromAddress(studioHdrClass, NumberType_Int32)) : Address_Null;
}

stock int StudioHdrGetSequenceCount(Address studioHdrStruct)
{
    return LoadFromAddress(studioHdrStruct + view_as<Address>(StudioHdrStruct_SequenceCount), NumberType_Int32);
}

stock int Animating_GetNumMovements(const int iAnimating, const int nSequence)
{
    Address studioHdrStruct = StudioHdrClass_GetStudioHdrStruct(Animating_GetStudioHdrClass(iAnimating));
    
    Address studioAnimDesc = GetLocalAnimDescription(studioHdrStruct, nSequence);
    
    return StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_NumMovements);
}

stock float Animating_GetSequenceDuration(const int iAnimating, const int nSequence)
{
    Address studioHdrStruct = StudioHdrClass_GetStudioHdrStruct(Animating_GetStudioHdrClass(iAnimating));
    Address studioAnimDesc = GetLocalAnimDescription(studioHdrStruct, nSequence);
    PrintToServer("%f - %i", StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_Fps), StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_NumFrames));
    float cyclesPerSecond = view_as<float>(StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_Fps)) / (StudioAnimDesc_GetValue(studioAnimDesc, StudioAnimDesc_NumFrames) - 1);
    return cyclesPerSecond != 0.0 ? 1.0 / cyclesPerSecond : 0.0;
}

stock Address GetLocalAnimDescription(Address studioHdrStruct, int nSequence)
{
    if(nSequence < 0 || nSequence >= StudioHdrGetSequenceCount(studioHdrStruct))
    {
        nSequence = 0;
    }
    
    // return (mstudioanimdesc_t *)(((byte *)this) + localanimindex) + i;
    return studioHdrStruct + view_as<Address>(LoadFromAddress(studioHdrStruct + view_as<Address>(184), NumberType_Int32) + (nSequence * 4));
}

stock any StudioAnimDesc_GetValue(Address studioAnimDesc, StudioAnimDesc type, NumberType size = NumberType_Int32)
{
    return LoadFromAddress(studioAnimDesc + view_as<Address>(type), size);
}*/