/**
 * ============================================================================
 *
 *  Zombie Plague
 *
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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Weapon: Molotov",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}


// Item index
int gWeapon; int gDublicat;

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		if (ZP_IsMapLoaded())
		{
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("molotov");
	gDublicat = ZP_GetWeaponNameID("inc grenade");
	if (gWeapon == -1 || gDublicat == -1) SetFailState("[ZP] Custom weapon ID from name : \"molotov\" or \"inc grenade\" wasn't find");
}

/**
 * @brief Called before show a weapon in the weapons menu.
 * 
 * @param client            The client index.
 * @param weaponID          The weapon index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
public Action ZP_OnClientValidateWeapon(int client, int weaponID)
{
	if (weaponID == gWeapon)
	{
		if (ZP_IsPlayerHasWeapon(client, gDublicat) != -1)
		{
			return Plugin_Handled;
		}
	}
	else if (weaponID == gDublicat)
	{
		if (ZP_IsPlayerHasWeapon(client, gWeapon) != -1)
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	if (ZP_IsPlayerHuman(client))
	{
		UTIL_ExtinguishEntity(client);
	}
}

/**
 * @brief Called before a client take a fake damage.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index. (Not validated!)
 * @param inflicter         The inflicter index. (Not validated!)
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The ditfield of damage types.
 * @param weapon            The weapon index or -1 for unspecified.
 *
 * @note To block damage reset the damage to zero. 
 **/
public void ZP_OnClientValidateDamage(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &weapon)
{
	if (iBits & DMG_BURN || iBits & DMG_DIRECT)
	{
		if (ZP_IsPlayerZombie(client))
		{
			if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > WLEVEL_CSGO_FEET || GetEntityMoveType(client) == MOVETYPE_NONE)
			{
				UTIL_ExtinguishEntity(client);
			}
			else
			{
				float flSlowdown; float flDuration; int iD = GetEntProp(inflictor, Prop_Data, m_iCustomID);
		
				if (iD == gDublicat)
				{
					flDamage *= ZP_GetWeaponDamage(gDublicat);
					
					flSlowdown = ZP_GetWeaponKnockBack(gDublicat);
					
					flDuration = ZP_GetWeaponModelHeat(gDublicat);
				}
				else if (iD == gWeapon)
				{
					flDamage *= ZP_GetWeaponDamage(gWeapon);
					
					flSlowdown = ZP_GetWeaponKnockBack(gWeapon);
					
					flDuration = ZP_GetWeaponModelHeat(gWeapon);
				}
				else return;

				if (iBits & DMG_BURN) UTIL_IgniteEntity(client, flDuration);

				SetEntPropFloat(client, Prop_Send, "m_flStamina", min(flSlowdown, 100.0));
	
				return;
			}
		}
		
		flDamage *= 0.0;
	}
}
