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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * Sequence paired shift.
 **/
#define SWAP_SEQ_PAIRED (1<<31)
 
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
    SetEntDataEnt2(viewIndex, g_iOffset_ModelWeapon, weaponIndex, true);
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
    return GetEntDataEnt2(clientIndex, g_iOffset_Model + (viewIndex * 4));
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
    SetEntDataEnt2(clientIndex, g_iOffset_Model + (viewIndex * 4), iModel, true);
}

/**
 * @brief Gets the world (player) weapon model.
 *
 * @param weaponIndex       The weapon index.
 **/
int WeaponHDRGetPlayerWorldModel(int weaponIndex)
{ 
    // Gets worldmodel of the weapon
    return GetEntDataEnt2(weaponIndex, g_iOffset_WorldModel);
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
    int worldIndex = WeaponHDRGetPlayerWorldModel(weaponIndex);

    // Validate worldmodel
    if(worldIndex != INVALID_ENT_REFERENCE)
    {
        // Sets model index for the worldmodel
        ToolsSetModelIndex(worldIndex, iModel);
        
        // Validate model
        if(iModel) 
        {
            // Find the datamap
            if(!g_iOffset_WorldSkin)
            {
                g_iOffset_WorldSkin = FindDataMapInfo(worldIndex, "m_nSkin"); /// Not work properly, but data offset exist in CBaseWeaponWorldModel
            }

            // Sets body/skin index for the worldmodel
            ToolsSetTextures(worldIndex, iBody);
            SetEntData(worldIndex, g_iOffset_WorldSkin, iSkin, _, true); /// Not work 
        }
    }//                                                                                       Using CBaseWeaponWorldModel - weaponworldmodel instead                                                                  
    ///ToolsSetModelIndex(weaponIndex, WeaponsGetModelWorldID(iD)); for m_iWorldModelIndex not support body/skin!                                                                                               
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
                ToolsSetTextures(weaponIndex, WeaponsGetModelBody(iD, ModelType_Drop),  WeaponsGetModelSkin(iD, ModelType_Drop));
            }
        }
    }
}

/**
 * @brief Sets a visibility state of the weapon.
 *
 * @param weaponIndex       The weapon index.
 * @param bInvisible        True or false.
 **/
void WeaponHDRSetEntityVisibility(int weaponIndex, bool bInvisible)
{
    int iFlags = ToolsGetEffect(weaponIndex);
    ToolsSetEffect(weaponIndex, bInvisible ? (iFlags & ~EF_NODRAW) : (iFlags | EF_NODRAW));
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
    int iSize = ToolsGetMyWeapons();
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex2 = GetEntDataEnt2(clientIndex, g_iOffset_MyWeapons + (i * 4));
        
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
        if(DispatchSpawn(weaponIndex1))
        {
            // Sets weapon id
            WeaponsSetCustomID(weaponIndex1, iD);
            
            // Sets parent to the entity
            WeaponsSetOwner(weaponIndex1, clientIndex);
            ToolsSetOwner(weaponIndex1, clientIndex);

            // Remove an entity movetype
            SetEntityMoveType(weaponIndex1, MOVETYPE_NONE);

            // Sets parent of a weapon
            SetVariantString("!activator");
            AcceptEntityInput(weaponIndex1, "SetParent", clientIndex, weaponIndex1);
        }
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
 * @author This algorithm made by Andersso.
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
        if((iValue = iSequences[iIndex] = ToolsGetSequenceActivity(weaponIndex, iIndex)) == -1)
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
        int iNext = WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weaponIndex, i);

        // Validate cell
        if(iValue == iNext)
        {
            // Update
            swapIndex = i;

            // Let the index be be stored after the 16th bit, and add a bit-flag to indicate this being done
            iSequences[i] = iNext | (iIndex << 16) | SWAP_SEQ_PAIRED;
            break;
        }
    }
    
    // Update the sequence array
    iSequences[iIndex] = swapIndex;
    
    // Return the sequence cell
    return iValue;
}