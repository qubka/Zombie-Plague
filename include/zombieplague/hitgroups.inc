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

#if defined _higrouplist_included
 #endinput
#endif
#define _higrouplist_included

/**
 * @brief Gets the amount of all hitgrups.
 **/
native int ZP_GetNumberHitgroup();

/**
 * @brief Gets the array index at which the hitgroup index is at.
 *
 * @param hitgroup          The real hitgroup index.
 * @return                  The hitgroup index.
 **/
native int ZP_GetHitgroupID(int hitgroup);

/**
 * @brief Gets the name of a hitgroup at a given index.
 *
 * @param hitID             The hitgroup index.
 * @param name              The string to return name in.
 * @param maxlenght         The max length of the string.
 **/
native void ZP_GetHitgroupName(int hitID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the real hitgroup index of the hitgroup.
 * 
 * @param hitID             The hitgroup index.
 * @return                  The real hitgroup index.
 **/
native int ZP_GetHitgroupIndex(int hitID);

/**
 * @brief Gets the damage value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 * @return                  True if hitgroup can be damaged, false if not.
 **/
native bool ZP_IsHitgroupDamage(int hitID);

/**
 * @brief Sets the damage value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 * @param damage            True to allow damage to hitgroup, false to block damage.
 **/
native void ZP_SetHitgroupDamage(int hitID, bool damage);

/**
 * @brief Gets the knockback value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 * @return                  The knockback multiplier of the hitgroup.
 **/
native float ZP_GetHitgroupKnockback(int hitID);

/**
 * @brief Sets the knockback value of the hitgroup.
 *
 * @param hitID             The hitgroup index.
 * @param knockback         The knockback multiplier for the hitgroup.
 **/
native void ZP_SetHitgroupKnockback(int hitID, float knockback);
