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
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] ExtraItem: Madness",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of extra items",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Timer index
Handle hZombieMadness[MAXPLAYERS+1] = { null, ... }; 

// Sound index
int gSound;
 
// Item index
int gItem;

// Cvars
ConVar hCvarMadnessDuration;  
ConVar hCvarMadnessRadius;  
ConVar hCvarMadnessDistance;  
ConVar hCvarMadnessColor;  
	
/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarMadnessDuration = CreateConVar("zp_extraitem_madness_duration", "5.0", "Madness duration", 0, true, 0.0); 
	hCvarMadnessRadius   = CreateConVar("zp_extraitem_madness_radius", "20.0", "Madness aura size (radius)", 0, true, 0.0);
	hCvarMadnessDistance = CreateConVar("zp_extraitem_madness_distance", "600.0", "Madness aura size (distance)", 0, true, 0.0);
	hCvarMadnessColor    = CreateConVar("zp_extraitem_madness_color", "150 0 0 255", "Madness aura color in 'RGBA'");
	
	AutoExecConfig(true, "zp_extraitem_madness", "sourcemod/zombieplague");
}
	
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
	gItem = ZP_GetExtraItemNameID("madness");
	
	gSound = ZP_GetSoundKeyID("ZOMBIE_MADNESS_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"ZOMBIE_MADNESS_SOUNDS\" wasn't find");
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		hZombieMadness[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
	}
}
/**
 * @brief Called once a client is authorized and fully in-game, and 
 *        after all post-connection authorizations have been performed.  
 *
 * @note  This callback is gauranteed to occur on all clients, and always 
 *        after each OnClientPutInServer() call.
 * 
 * @param client            The client index. 
 **/
public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_TraceAttack, TraceAttackHook);
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	delete hZombieMadness[client];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	delete hZombieMadness[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	delete hZombieMadness[client];
}

/**
 * @brief Called before show an extraitem in the equipment menu.
 * 
 * @param client            The client index.
 * @param itemID            The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int client, int itemID)
{
	if (itemID == gItem)
	{
		if (hZombieMadness[client] != null)
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

/**
 * @brief Called after select an extraitem in the equipment menu.
 * 
 * @param client            The client index.
 * @param itemID            The item index.
 **/
public void ZP_OnClientBuyExtraItem(int client, int itemID)
{
	if (itemID == gItem)
	{
		static float vPosition[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);

		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_SKILL);

		float flDuration = hCvarMadnessDuration.FloatValue;

		static char sEffect[SMALL_LINE_LENGTH];
		hCvarMadnessColor.GetString(sEffect, sizeof(sEffect));
	
		UTIL_CreateLight(client, vPosition, _, _, _, _, _, _, _, sEffect, hCvarMadnessDistance.FloatValue, hCvarMadnessRadius.FloatValue, flDuration);
		
		ZP_SetProgressBarTime(client, RoundToNearest(flDuration));
		
		delete hZombieMadness[client];
		hZombieMadness[client] = CreateTimer(flDuration, ClientRemoveMadnesss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * @brief Timer for remove madness.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveMadnesss(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);
	
	hZombieMadness[client] = null;
	
	if (client)
	{
		ZP_SetProgressBarTime(client, 0);
	}

	return Plugin_Stop;
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
	if (hZombieMadness[client] != null)
	{
		flDamage *= 0.1;
	}
}

/**
 * Hook: OnTraceAttack
 * @brief Called right before the bullet enters a client.
 * 
 * @param client            The victim index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The type of damage inflicted.
 * @param iAmmo             The ammo type of the attacker weapon.
 * @param iHitBox           The hitbox index.  
 * @param iHitGroup         The hitgroup index.  
 **/
public Action TraceAttackHook(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &iAmmo, int iHitBox, int iHitGroup)
{
	return hZombieMadness[client] != null ? Plugin_Handled : Plugin_Continue;
}