/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin DamageBox =
{
	name        	= "[ZP] Addon: DamageBox",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Show hint text within applied damage",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * Called when a client take a fake damage.
 * 
 * @param clientIndex		The client index.
 * @param attackerIndex		The attacker index.
 * @param damageAmount		The amount of damage inflicted.
 **/
public void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount)
{
	// Validate attacker
	if(!IsPlayerExist(attackerIndex))
	{
		return;
	}
	
	// Validate victim
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// Initialize char
	static char sMessage[BIG_LINE_LENGTH];
	
	// Count damage
	int healthAmount = GetClientHealth(clientIndex) - RoundFloat(damageAmount);

	// Format message
	Format(sMessage, BIG_LINE_LENGTH, "<font color='#FFFFFF'>HP:</font> <font color='#FF0000'>%i</font>", (healthAmount < 0) ? 0 : healthAmount);
	
	// Sent hint message
	Handle hMessage = StartMessageOne("HintText", attackerIndex);
	PbSetString(hMessage, "text", sMessage);
	EndMessage();
}