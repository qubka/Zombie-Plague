/**
 * =============================================================================
 * Zombie Plague X Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin).
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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
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

#if defined _higrouplist_included
 #endinput
#endif
#define _higrouplist_included

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index. (Not validated!)
 * @param inflicterIndex    The inflicter index. (Not validated!)
 * @param damage            The amount of damage inflicted.
 * @param bits              The ditfield of damage types.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 *
 * @noreturn
 **/
forward void ZP_OnClientDamaged(int clientIndex, int &attackerIndex, int &inflicterIndex, float &damage, int &bits, int &weaponIndex);

/**
 * @brief Gets the amount of all hitgrups.
 **/
native int ZP_GetNumberHitGroup();

/**
 * @brief Gets the array index at which the hitgroup index is at.
 *
 * @param hitgroup          The real hitgroup index.
 *
 * @return                  The hitgroup index, or -1 on failure.
 **/
native int ZP_GetHitGroupID(int hitgroup);

/**
 * @brief Gets the index of a higroup at a given name.
 *
 * @param name              The higroup name.
 *
 * @return                  The higroup index, or -1 on failure.
 **/
native int ZP_GetHitGroupNameID(char[] name);

/**
 * @brief Gets the name of a hitgroup at a given index.
 *
 * @param hitID             The hitgroup index.
 * @param name              The string to return name in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetHitGroupName(int hitID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the real hitgroup index of the hitgroup.
 * 
 * @param hitID             The hitgroup index.
 *
 * @return                  The real hitgroup index.
 **/
native int ZP_GetHitGroupIndex(int hitID);

/**
 * @brief Checks the damage value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 *
 * @return                  True if hitgroup can be damaged, false if not.
 **/
native bool ZP_IsHitGroupDamage(int hitID);

/**
 * @brief Gets the knockback value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 *
 * @return                  The knockback multiplier of the hitgroup.
 **/
native float ZP_GetHitGroupKnockBack(int hitID);

/**
 * @brief Gets the armor value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 *
 * @return                  The armor multiplier of the hitgroup.
 **/
native float ZP_GetHitGroupArmor(int hitID);

/**
 * @brief Gets the bonus value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 *
 * @return                  The bonus multiplier of the hitgroup.
 **/
native float ZP_GetHitGroupBonus(int hitID);

/**
 * @brief Gets the heavy value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 *
 * @return                  The heavy multiplier of the hitgroup.
 **/
native float ZP_GetHitGroupHeavy(int hitID);

/**
 * @brief Checks the protect value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 *
 * @return                  True if hitgroup can be protected, false if not.
 **/
native bool ZP_IsHitGroupProtect(int hitID);
