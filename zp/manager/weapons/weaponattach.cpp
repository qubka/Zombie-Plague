/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          weaponattach.cpp
 *  Type:          Module
 *  Description:   Weapon attachment functions.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin), Mitchell
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

// Comment to remove a weapon attachments on the back
#define USE_ATTACHMENTS
 
/**
 * @section All addons bits.
 **/
#define CSAddon_NONE            0
#define CSAddon_Flashbang1      (1<<0)
#define CSAddon_Flashbang2      (1<<1)
#define CSAddon_HEGrenade       (1<<2)
#define CSAddon_SmokeGrenade    (1<<3)
#define CSAddon_C4              (1<<4)
#define CSAddon_DefuseKit       (1<<5)
#define CSAddon_PrimaryWeapon   (1<<6)
#define CSAddon_SecondaryWeapon (1<<7)
#define CSAddon_Holster         (1<<8) 
#define CSAddon_Decoy           512
#define CSAddon_Knife           1024
#define CSAddon_TaGrenade       4096
/**
 * @endsection
 **/
 
/**
 * Number of valid addons.
 **/
enum WeaponAttachBitType
{
    BitType_Invalid = -1,         /** Used as return value when an bit doens't exist. */
    
    BitType_PrimaryWeapon,        /** Primary bit */
    BitType_SecondaryWeapon,      /** Secondary bit */
    BitType_Flashbang1,           /** Flashbang1 bit */
    BitType_Flashbang2,           /** Flashbang2 bit */
    BitType_HEGrenade,            /** Hegrenade bit */
    BitType_SmokeGrenade,         /** Smokegrenade bit */
    BitType_Decoy,                /** Decoy bit */
    BitType_Knife,                /** Knife bit */
    BitType_TaGrenade             /** Tagrenade bit */
    //BitType_C4                  /** C4 bit */
};
 
/**
 * Destoy weapon attachments.
 **/
public void WeaponAttachUnload(/*void*/) 
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++) 
    {
        // Validate client
        if(IsPlayerExist(i, false)) 
        {
            // Remove current attachment
            WeaponAttachmentRemoveEntity(i);
            WeaponAttachmentRemoveAddons(i);
        }
    }
}

/**
 * Set addons attachment.
 *
 * @param clientIndex       The client index.
 **/
void WeaponAttachmentSetAddons(int clientIndex)
{
    #if defined USE_ATTACHMENTS
    // Gets the current bits
    int iBits = GetEntData(clientIndex, g_iOffset_PlayerAddonBits); int iBitPurge; static int weaponIndex; static int iD;
    
    /*____________________________________________________________________________________________*/
    
    // Validate primary bits
    if(iBits & CSAddon_PrimaryWeapon)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_PrimaryWeapon))
        {
            // Gets weapon index
            weaponIndex = GetPlayerWeaponSlot(clientIndex, view_as<int>(SlotType_Primary));
            
            // Validate weapon
            if(IsValidEdict(weaponIndex))
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_PrimaryWeapon, "primary");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_PrimaryWeapon)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_PrimaryWeapon);
    }
    
    /*____________________________________________________________________________________________*/
    
    // Validate secondary bits
    if(iBits & CSAddon_SecondaryWeapon)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_SecondaryWeapon))
        {
            // Gets weapon index
            weaponIndex = GetPlayerWeaponSlot(clientIndex, view_as<int>(SlotType_Secondary));

            // Validate taser slot
            if(weaponIndex == GetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon))
            {
                // Gets weapon index
                weaponIndex = WeaponsAttachmentGetIndex(clientIndex, "weapon_taser");
            }
            
            // Validate weapon
            if(IsValidEdict(weaponIndex))
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_SecondaryWeapon, "pistol");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_SecondaryWeapon)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_SecondaryWeapon);
    }
    
    /*____________________________________________________________________________________________*/
    
    // Validate flashbang1 bits
    if(iBits & CSAddon_Flashbang1)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_Flashbang1))
        {
            // Gets weapon index
            weaponIndex = WeaponsAttachmentGetIndex(clientIndex, "weapon_flashbang");
            
            // Validate weapon
            if(weaponIndex != INVALID_ENT_REFERENCE)
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_Flashbang1, "grenade0");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_Flashbang1)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_Flashbang1);
    }
    
    /*____________________________________________________________________________________________*/
    
    // Validate flashbang2 bits
    if(iBits & CSAddon_Flashbang2)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_Flashbang2))
        {
            // Gets weapon index
            weaponIndex = WeaponsAttachmentGetIndex(clientIndex, "weapon_flashbang");
            
            // Validate weapon
            if(weaponIndex != INVALID_ENT_REFERENCE)
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_Flashbang2, "eholster");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_Flashbang2)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_Flashbang2);
    }
    
    /*____________________________________________________________________________________________*/
    
    // Validate hegrenade bits
    if(iBits & CSAddon_HEGrenade)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_HEGrenade))
        {
            // Gets weapon index
            weaponIndex = WeaponsAttachmentGetIndex(clientIndex, "weapon_hegrenade");
            
            // Validate weapon
            if(weaponIndex != INVALID_ENT_REFERENCE)
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_HEGrenade, "grenade1");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_HEGrenade)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_HEGrenade);
    }
    
    /*____________________________________________________________________________________________*/
    
    // Validate smokegrenade bits
    if(iBits & CSAddon_SmokeGrenade)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_SmokeGrenade))
        {
            // Gets weapon index
            weaponIndex = WeaponsAttachmentGetIndex(clientIndex, "weapon_smokegrenade");
            
            // Validate weapon
            if(weaponIndex != INVALID_ENT_REFERENCE)
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_SmokeGrenade, "grenade2");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_SmokeGrenade)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_SmokeGrenade);
    }
    
    /*____________________________________________________________________________________________*/
    
    // Validate decoy bits
    if(iBits & CSAddon_Decoy)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_Decoy))
        {
            // Gets weapon index
            weaponIndex = WeaponsAttachmentGetIndex(clientIndex, "weapon_decoy");
            
            // Validate weapon
            if(weaponIndex != INVALID_ENT_REFERENCE)
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_Decoy, "grenade3");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_Decoy)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_Decoy);
    }
    
    /*____________________________________________________________________________________________*/
    
    // Validate knife bits
    if(iBits & CSAddon_Knife)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_Knife))
        {
            // Gets weapon index
            weaponIndex = GetPlayerWeaponSlot(clientIndex, view_as<int>(SlotType_Melee));
            
            // Validate weapon
            if(IsValidEdict(weaponIndex))
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_Knife, "knife");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_Knife)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_Knife);
    }
    
    /*____________________________________________________________________________________________*/
    
    // Validate tagrenade bits
    if(iBits & CSAddon_TaGrenade)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_TaGrenade))
        {
            // Gets weapon index
            weaponIndex = WeaponsAttachmentGetIndex(clientIndex, "weapon_tagrenade");
            
            // Validate weapon
            if(weaponIndex != INVALID_ENT_REFERENCE)
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_TaGrenade, "grenade4");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_TaGrenade)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_TaGrenade);
    }
    
    /*____________________________________________________________________________________________*/
    
    /** Uncomment bellow, if you want to use c4 model **/
    /*
    // Validate c4 bits 
    if(iBits & CSAddon_C4)
    {
        // Gets the client's bits
        if(!(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_C4))
        {
            // Gets weapon index
            weaponIndex = GetPlayerWeaponSlot(clientIndex, view_as<int>(SlotType_C4));
            
            // Validate weapon
            if(IsValidEdict(weaponIndex))
            {
                // Validate custom index
                iD = gWeaponData[weaponIndex];
                if(iD != -1)
                {
                    // Create weapon's addons
                    WeaponAttachmentCreateAddons(clientIndex, iD, BitType_C4, "c4");
                }
            }
        }
    }
    else if(gClientData[clientIndex][Client_AttachmentBits] & CSAddon_C4)
    {
        // Remove current addons
        WeaponAttachmentRemoveAddons(clientIndex, BitType_C4);
    }
    */

    /*____________________________________________________________________________________________*/
    
    // Validate addons
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_PrimaryWeapon]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_PrimaryWeapon;
    }
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_SecondaryWeapon]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_SecondaryWeapon;
    }
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_Flashbang1]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_Flashbang1;
    }
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_Flashbang2]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_Flashbang2;
    }
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_HEGrenade]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_HEGrenade;
    }
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_SmokeGrenade]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_SmokeGrenade;
    }
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_Decoy]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_Decoy;
    }
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_Knife]) != INVALID_ENT_REFERENCE || (gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Nemesis]))
    {
        iBitPurge |= CSAddon_Knife;
    }
    if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_TaGrenade]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_TaGrenade;
    }
    /*if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][BitType_C4]) != INVALID_ENT_REFERENCE)
    {
        iBitPurge |= CSAddon_C4;
    }*/
    
    // Store the bits for next usage
    gClientData[clientIndex][Client_AttachmentBits] = iBits;
    SetEntData(clientIndex, g_iOffset_PlayerAddonBits, iBits &~ iBitPurge, _, true);
    #else
        #pragma unused clientIndex
    #endif
}

#if defined USE_ATTACHMENTS
/**
 * Create addons attachment.
 *
 * @param clientIndex       The client index.
 * @param iD                The weapon id.
 * @param bitType           The bit type.
 * @param sAttach           The attachment bone of the entity parent.
 **/
void WeaponAttachmentCreateAddons(int clientIndex, int iD, WeaponAttachBitType bitType, char[] sAttach)
{
    // Remove current addons
    WeaponAttachmentRemoveAddons(clientIndex, bitType);

    // If world model exist, then apply it
    if(WeaponsGetModelWorldID(iD))
    {
        // Create an attach addon entity 
        int entityIndex = CreateEntityByName("prop_dynamic_override");
        
        // If entity isn't valid, then skip
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Gets weapon's world model
            static char sModel[PLATFORM_MAX_PATH];
            WeaponsGetModelWorld(iD, sModel, sizeof(sModel)); 

            // Dispatch main values of the entity
            DispatchKeyValue(entityIndex, "model", sModel);
            DispatchKeyValue(entityIndex, "spawnflags", "256"); /// Start with collision disabled
            DispatchKeyValue(entityIndex, "solid", "0");
           
            // Sets bodygroup of the entity
            SetVariantInt(WeaponsGetModelViewBody(iD));
            AcceptEntityInput(entityIndex, "SetBodyGroup");
            
            // Sets skin of the entity
            SetVariantInt(WeaponsGetModelViewSkin(iD));
            AcceptEntityInput(entityIndex, "Skin");
            
            // Spawn the entity into the world
            DispatchSpawn(entityIndex);
            
            // Sets parent to the entity
            SetEntDataEnt2(entityIndex, g_iOffset_EntityOwnerEntity, clientIndex, true);
            
            // Sets parent to the client
            SetVariantString("!activator");
            AcceptEntityInput(entityIndex, "SetParent", clientIndex, entityIndex);
            
            // Sets attachment to the client
            SetVariantString(sAttach);
            AcceptEntityInput(entityIndex, "SetParentAttachment", clientIndex, entityIndex);
            
            // Hook entity callbacks
            SDKHook(entityIndex, SDKHook_SetTransmit, WeaponAttachmentOnTransmit);
            
            // Store the client's cache
            gClientData[clientIndex][Client_AttachmentAddons][bitType] = EntIndexToEntRef(entityIndex);
        }
    }
}

/**
 * Hook: SetTransmit
 * Called right before the entity transmitting to other entities.
 *
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public Action WeaponAttachmentOnTransmit(int entityIndex , int clientIndex)
{
    // i = slot index
    for(WeaponAttachBitType i = BitType_PrimaryWeapon; i <= BitType_TaGrenade; i++)
    {
        // Validate addons
        if(EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentAddons][i]) == entityIndex)
        {
            // Validate observer mode
            if(GetEntData(clientIndex, g_iOffset_PlayerObserverMode))
            {
                // Allow transmitting    
                return Plugin_Continue;
            }

            // Block transmitting
            return Plugin_Handled;
        }
    }
    
    // Get the owner of the entity
    int ownerIndex = GetEntDataEnt2(entityIndex, g_iOffset_EntityOwnerEntity);

    // Validate dead owner
    if(!IsPlayerAlive(ownerIndex))
    {
        // Block transmitting
        return Plugin_Handled;
    }
    
    // Validate observer mode
    if(GetEntData(clientIndex, g_iOffset_PlayerObserverMode) == TEAM_OBSERVER && ownerIndex == GetEntDataEnt2(clientIndex, g_iOffset_PlayerObserverTarget))
    {
        // Block transmitting
        return Plugin_Handled;
    }

    // Allow transmitting
    return Plugin_Continue;
}

/**
 * Returns index if the player has a weapon.
 *
 * @param clientIndex       The client index.
 * @param sWeaponName       The weapon name.
 *
 * @return                  The weapon index.
 **/
stock int WeaponsAttachmentGetIndex(int clientIndex, char[] sWeaponName)
{
    // Initialize char
    char sClassname[SMALL_LINE_LENGTH];

    // i = weapon number
    int iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_CharacterWeapons + (i * 4));

        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // Get weapon classname
            GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));

            // If weapon find, then return
            if(!strcmp(sClassname[7], sWeaponName[7], false))
            {
                return weaponIndex;
            }
        }

        // Go to next weapon
        continue;
    }

    // If wasn't found
    return INVALID_ENT_REFERENCE;
}
#endif

/**
 * Gets the current position of the client's weapon attachment.
 *
 * native void ZP_GetWeaponAttachmentPos(clientIndex, attachment, position, view);
 **/
public int API_GetWeaponAttachmentPos(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Retrieves the string length from a native parameter string
    static int maxLen;
    GetNativeStringLength(2, maxLen);
    
    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Weapons, "Native Validation", "Can't find attachment position with an empty name");
        return -1;
    }

    // Gets native data
    static char sAttach[SMALL_LINE_LENGTH];

    // General
    GetNativeString(2, sAttach, sizeof(sAttach));   

    // Gets the attachment position
    static float vPosition[3];
    WeaponAttachmentGetPosition(clientIndex, sAttach, vPosition);

    // Return on success
    return SetNativeArray(3, vPosition, sizeof(vPosition));
}

/**
 * Gets the current position of the client's weapon attachment.
 *
 * @param clientIndex       The client index.
 * @param sAttach           The attachment bone of the entity parent.
 * @param vPosition         Array to store vector in. 
 **/
void WeaponAttachmentGetPosition(int clientIndex, char[] sAttach, float vPosition[3])
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Gets the current attachment from the client's reference
    int entityIndex = EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentEntity]);

    // If a weapon attachment doesn't exist, create one
    if(entityIndex == INVALID_ENT_REFERENCE) 
    {
        // Create an attachment
        entityIndex = WeaponAttachmentCreateEntity(clientIndex);

        // Validate attachment
        if(entityIndex == INVALID_ENT_REFERENCE) 
        {
            return;
        }
        
        // Store the client's attachment to the reference
        gClientData[clientIndex][Client_AttachmentEntity] = EntIndexToEntRef(entityIndex);
    }

    // Gets the active weapon index from the client
    int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon);

    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        return;
    }

    // Validate a new weapon
    if(gClientData[clientIndex][Client_AttachmentWeapon] != weaponIndex || !!strcmp(sAttach, gClientData[clientIndex][Client_AttachmentLast], false)) 
    {
        // Store the client's cache
        gClientData[clientIndex][Client_AttachmentWeapon] = weaponIndex;
        strcopy(gClientData[clientIndex][Client_AttachmentLast], SMALL_LINE_LENGTH, sAttach);

        // Clears parent of the entity
        AcceptEntityInput(entityIndex, "ClearParent");

        // Gets the world model index
        weaponIndex = GetEntDataEnt2(weaponIndex, g_iOffset_WeaponWorldModel);

        // Validate world/view model
        if(!IsValidEdict(weaponIndex))
        {
            return;
        }

        // Sets parent to the entity
        SetVariantString("!activator");
        AcceptEntityInput(entityIndex, "SetParent", weaponIndex, entityIndex);

        // Sets attachment to the entity
        SetVariantString(sAttach);
        AcceptEntityInput(entityIndex, "SetParentAttachment", weaponIndex, entityIndex);
    }

    // Find the datamap
    if(!g_iOffset_WeaponAttachment)
    {
        g_iOffset_WeaponAttachment = FindDataMapInfo(entityIndex, "m_vecAbsOrigin");
    }
    
    // Gets current entity's position
    GetEntDataVector(entityIndex, g_iOffset_WeaponAttachment, vPosition);
}

/**
 * Create an attachment entity for the client.
 *
 * @param clientIndex       The client index.
 * @return                  The entity index.
 **/
int WeaponAttachmentCreateEntity(int clientIndex) 
{
    // Remove current attachment
    WeaponAttachmentRemoveEntity(clientIndex);

    // Create an attach info entity
    int entityIndex = CreateEntityByName("info_target");

    // If entity isn't valid, then skip
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Spawn the entity into the world
        DispatchSpawn(entityIndex);
    
        // Clear the client's cache
        gClientData[clientIndex][Client_AttachmentWeapon] = INVALID_ENT_REFERENCE;
        gClientData[clientIndex][Client_AttachmentLast][0] = '\0';
    }

    // Return index on the success
    return entityIndex;
}

/**
 * Remove an attachment entity from the client.
 *
 * @param clientIndex       The client index.
 **/
void WeaponAttachmentRemoveEntity(int clientIndex) 
{
    // Gets the current attachment from the client's reference
    int entityIndex = EntRefToEntIndex(gClientData[clientIndex][Client_AttachmentEntity]);
    
    // Validate attachment
    if(entityIndex != INVALID_ENT_REFERENCE) 
    {
        AcceptEntityInput(entityIndex, "Kill");
    }

    // Clear the client's cache
    gClientData[clientIndex][Client_AttachmentEntity] = INVALID_ENT_REFERENCE;
    gClientData[clientIndex][Client_AttachmentWeapon] = INVALID_ENT_REFERENCE;
    gClientData[clientIndex][Client_AttachmentLast][0] = '\0';
}

/**
 * Remove an attachment addons from the client.
 *
 * @param clientIndex       The client index.
 * @param bitType           The bit type.
 **/
void WeaponAttachmentRemoveAddons(int clientIndex, WeaponAttachBitType bitType = BitType_Invalid) 
{
    #if defined USE_ATTACHMENTS
    // Validate all
    if(bitType == BitType_Invalid)
    {
        // i = slot index
        for(WeaponAttachBitType i = BitType_PrimaryWeapon; i <= BitType_TaGrenade; i++)
        {
            // Validate addons
            if(IsValidEdict(gClientData[clientIndex][Client_AttachmentAddons][i])) 
            {
                AcceptEntityInput(gClientData[clientIndex][Client_AttachmentAddons][i], "Kill");
            }

            // Clear the client's cache
            gClientData[clientIndex][Client_AttachmentBits] = CSAddon_NONE;
            gClientData[clientIndex][Client_AttachmentAddons][i] = INVALID_ENT_REFERENCE;
        }
    }
    else
    {
        // Validate addons
        if(IsValidEdict(gClientData[clientIndex][Client_AttachmentAddons][bitType])) 
        {
            AcceptEntityInput(gClientData[clientIndex][Client_AttachmentAddons][bitType], "Kill");
        }

        // Clear the client's cache
        gClientData[clientIndex][Client_AttachmentBits] = CSAddon_NONE;
        gClientData[clientIndex][Client_AttachmentAddons][bitType] = INVALID_ENT_REFERENCE;
    }
    #else
        #pragma unused clientIndex, bitType
    #endif
}