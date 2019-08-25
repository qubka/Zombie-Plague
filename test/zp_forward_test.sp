/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Test: forward",
    author          = "qubka (Nikita Ushakov) | Nyuu",
    description     = "Test of ZP_OnClientDamagedPost",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
* @brief Called after client takes a damage.
*
* @param client            The client index.
* @param attacker          The attacker index. (Not validated!)
* @param cHealth           The health of client after being damaged
* @param cArmor            The armor of client after being damaged
* @param cHealthDamage     The amount of damage to health.
* @param cArmorDamage      The amount of damage to armor.
* @param bits              The bitfield of damage types.
* @param weapon            The weapon index or -1 for unspecified.
*
* @noreturn
**/
public void ZP_OnClientDamagedPost(int client, int attacker, int cHealth,int cArmor, int cHealthDamage,int cArmorDamage ,int bits, int weapon){
    if(attacker > 0 && !IsFakeClient(attacker))
    {
        PrintToChat(attacker," attacker: %d",attacker);
        PrintToChat(attacker," victim: %d",client);
        PrintToChat(attacker," health: %d -%d",cHealth,cHealthDamage);
        PrintToChat(attacker," armor: %d -%d",cArmor,cArmorDamage);
        PrintToChat(attacker," bits: %d, weapon: %d",bits,weapon);
    }
}
