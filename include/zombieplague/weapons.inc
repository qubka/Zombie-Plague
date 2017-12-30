/**
 * =============================================================================
 * Zombie Plague 7.x Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin).
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
 * @brief Gets the amount of all weapons.
 *
 * @return          		The weapon amount.	
 */
native int ZP_GetNumberWeapon();

/**
 * @brief Gets the name of a weapon at a given index.
 *
 * @param weaponID     	 	The weapon index.
 * @param name      		The string to return name in.
 * @param maxlenght			The lenght of string.
 **/
native void ZP_GetWeaponName(int weaponID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the entity a weapon at a given index.
 *
 * @param weaponID     	 	The weapon index.
 * @param entity      		The string to return entity in.
 * @param maxlenght			The lenght of string.
 **/
native void ZP_GetWeaponEntity(int weaponID, char[] entity, int maxlenght = 32);

/**
 * @brief Gets the definition index of the weapon.
 *
 * @param weaponID			The weapon index.
 * @return					The definition index. (m_iItemDefinitionIndex)
 **/
native int ZP_GetWeaponIndex(int weaponID);

/**
 * @brief Gets the cost of the weapon.
 * 
 * @param weaponID			The weapon index.
 * @return          		The cost amount.	
 **/
native int ZP_GetWeaponCost(int weaponID);

/**
 * @brief Gets the slot of the weapon.
 * 
 * @param weaponID			The weapon index.
 * @return          		The weapon slot.	
 **/
native int ZP_GetWeaponSlot(int weaponID);

/**
 * @brief Gets the level of the weapon.
 * 
 * @param weaponID			The weapon index.
 * @return          		The level amount.	
 **/
native int ZP_GetWeaponLevel(int weaponID);

/**
 * @brief Gets the online of the weapon.
 * 
 * @param weaponID			The weapon index.
 * @return          		The online amount.	
 **/
native int ZP_GetWeaponOnline(int weaponID);

/**
 * @brief Gets the damage of the weapon.
 * 
 * @param weaponID			The weapon index.
 * @return          		The damage amount.	
 **/
native float ZP_GetWeaponDamage(int weaponID);

/**
 * @brief Gets the knockback of the weapon.
 * 
 * @param weaponID			The weapon index.
 * @return          		The knockback amount.	
 **/
native float ZP_GetWeaponKnockBack(int weaponID);

/**
 * @brief Gets the models' class access of a weapon at a given index.
 *
 * @param weaponID     	 	The weapon index.
 * @param class      		The string to return class in.
 * @param maxlenght			The lenght of string.
 **/
native void ZP_GetWeaponModelClass(int weaponID, char[] class, int maxlenght = 32);

/**
 * @brief Gets the view model path a weapon at a given index.
 *
 * @param weaponID     	 	The weapon index.
 * @param model      		The string to return model in.
 * @param maxlenght			The lenght of string.
 **/
native void ZP_GetWeaponModelView(int weaponID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the index of the weapon view model.
 * 
 * @param weaponID			The weapon index.
 * @return          		The knockback amount.	
 **/
native int ZP_GetWeaponModelViewID(int weaponID);

/**
 * @brief Gets the world model path a weapon at a given index.
 *
 * @param weaponID     	 	The weapon index.
 * @param model      		The string to return model in.
 * @param maxlenght			The lenght of string.
 **/
native void ZP_GetWeaponModelWorld(int weaponID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the index of the weapon world model.
 * 
 * @param weaponID			The weapon index.
 * @return          		The knockback amount.	
 **/
native int ZP_GetWeaponModelWorldID(int weaponID);