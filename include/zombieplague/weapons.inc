/**
 * =============================================================================
 * Zombie Plague 8.x Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin).
 * =============================================================================
 *
 * This file is part of the Zombie Plague Core.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 **/

#if defined _weaponlist_included
 #endinput
#endif
#define _weaponlist_included

/**
 * @brief Called after a custom weapon is created.
 *
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
forward void ZP_OnWeaponCreated(int weaponIndex, int weaponID);

/**
 * @brief Gets the current position of the weapon attachment.
 *
 * @param clientIndex       The client index.
 * @param attachment        The attachment bone of the entity parent.
 * @raram position          Array to store vector in.
 **/
native void ZP_GetWeaponAttachmentPos(int clientIndex, char[] attachment, float position[3]);

/**
 * @brief Gives the weapon by a given name.
 *
 * @param clientIndex       The client index.
 * @param name              The weapon name.
 * @return                  The weapon index.
 **/
native int ZP_GiveClientWeapon(int clientIndex, char[] name);

/**
 * @brief Gets the custom weapon id from a given weapon index. 
 *
 * @param weaponIndex       The weapon index.
 * @return                  The weapon ID or -1 if no weapon was found.
 **/
native int ZP_GetWeaponID(int weaponIndex);

/**
 * @brief Gets the custom weapon id from a given name.
 *
 * @param name              The weapon name.
 * @return                  The weapon ID or -1 if no weapon was found.
 **/
native int ZP_GetWeaponNameID(char[] name);

/**
 * @brief Gets the amount of all weapons.
 *
 * @return                  The weapon amount.    
 **/
native int ZP_GetNumberWeapon();

/**
 * @brief Gets the name of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param name              The string to return name in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponName(int weaponID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the entity a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param entity            The string to return entity in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponEntity(int weaponID, char[] entity, int maxlenght = 32);

/**
 * @brief Gets the definition index of the weapon.
 *
 * @param weaponID          The weapon ID.
 * @return                  The definition index. (m_iItemDefinitionIndex)
 **/
native int ZP_GetWeaponIndex(int weaponID);

/**
 * @brief Gets the cost of the weapon.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The cost amount.    
 **/
native int ZP_GetWeaponCost(int weaponID);

/**
 * @brief Gets the slot of the weapon.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The weapon slot.    
 **/
native int ZP_GetWeaponSlot(int weaponID);

/**
 * @brief Gets the level of the weapon.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The level amount.    
 **/
native int ZP_GetWeaponLevel(int weaponID);

/**
 * @brief Gets the online of the weapon.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The online amount.    
 **/
native int ZP_GetWeaponOnline(int weaponID);

/**
 * @brief Gets the damage of the weapon.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The damage amount.    
 **/
native float ZP_GetWeaponDamage(int weaponID);

/**
 * @brief Gets the knockback of the weapon.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The knockback amount.    
 **/
native float ZP_GetWeaponKnockBack(int weaponID);

/**
 * @brief Gets the clip ammo of the weapon.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The clip ammo amount.
 **/
native int ZP_GetWeaponClip(int weaponID);

/**
 * @brief Gets the reserve clip of the weapon.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The reserve ammo amount.    
 **/
native int ZP_GetWeaponAmmo(int weaponID);

/**
 * @brief Gets the shoot delay of the weapon.
 *
 * @param weaponID          The weapon ID.
 * @return                  The delay amount.    
 **/
native float ZP_GetWeaponSpeed(int weaponID);

/**
 * @brief Gets the reload duration of the weapon.
 *
 * @param weaponID          The weapon ID.
 * @return                  The duration amount.    
 **/
native float ZP_GetWeaponReload(int weaponID);

/**
 * @brief Gets the sound key of the weapon.
 *
 * @param weaponID          The weapon ID.
 * @return                  The key index.
 **/
native int ZP_GetWeaponSoundID(int weaponID);

/**
 * @brief Gets the class access of the weapon.
 *
 * @param iD                The weapon id.
 * @return                  The class access index.
 **/
native int ZP_GetWeaponClass(int weaponID);

/**
 * @brief Gets the view model path a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponModelView(int weaponID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the index of the weapon view model.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The view model index.    
 **/
native int ZP_GetWeaponModelViewID(int weaponID);

/**
 * @brief Gets the world model path a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponModelWorld(int weaponID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the index of the weapon world model.
 * 
 * @param weaponID          The weapon ID.
 * @return                  The world model index.    
 **/
native int ZP_GetWeaponModelWorldID(int weaponID);

/**
 * @brief Gets the body index of the weapon model.
 *
 * @param weaponID          The weapon ID.
 * @return                  The view model body index.    
 **/
native int ZP_GetWeaponModelBody(int weaponID);

/**
 * @brief Gets the skin index of the weapon model.
 *
 * @param weaponID          The weapon ID.
 * @return                  The view model skin index.    
 **/
native int ZP_GetWeaponModelSkin(int weaponID);

/**
 * @brief Gets the heat amount of the weapon model.
 *
 * @param weaponID          The weapon ID.
 * @return                  The heat amount.    
 **/
native float ZP_GetWeaponModelHeat(int weaponID);

/**
 * @brief Returns true if the player has a current weapon, false if not.
 *
 * @param clientIndex       The client index.
 * @param weaponID          The weapon id.
 *
 * @return                  True or false.
 **/
stock bool ZP_IsPlayerHasWeapon(const int clientIndex, const int weaponID)
{
    // Gets number of all client weapons
    int iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    
    // i = weapon number
    for (int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntPropEnt(clientIndex, Prop_Send, "m_hMyWeapons", i);
        
        // If entity isn't valid, then skip
        if(IsValidEdict(weaponIndex))
        {
            // If weapon find, then return
            if(ZP_GetWeaponID(weaponIndex) == weaponID)
            {
                return true;
            }
        }
        
        // Go to next weapon
        continue;
    }

    // If wasn't found
    return false;
}

/**
 * @brief Returns true if the player hold a current weapon, false if not.
 * 
 * @param clientIndex       The client index. 
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 * 
 * @return                  True or false.
 **/
stock bool ZP_IsPlayerHoldWeapon(const int clientIndex, int &weaponIndex, const int weaponID)
{
    // Validate client
    if (!IsPlayerExist(clientIndex))
    {
        return false;
    }

    // Gets weapon index
    weaponIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hActiveWeapon");

    // If entity isn't valid, then stop
    if(!IsValidEdict(weaponIndex))
    {
        return false;
    }

    // If weapon didn't find, then stop
    if(ZP_GetWeaponID(weaponIndex) != weaponID)
    {
        return false;
    }

    // Return on success
    return true;
}
