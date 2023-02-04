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
	name            = "[ZP] Weapon: Skullaxe",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/    
#define WEAPON_IDLE_TIME 8.33
/**
 * @endsection
 **/

// Timer index
Handle hWeaponStab[MAXPLAYERS+1] = { null, ... }; 
Handle hWeaponSwing[MAXPLAYERS+1] = { null, ... }; 
 
// Weapon index
int gWeapon;

// Sound index
int gSound;

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_STAB_MISS,
	ANIM_MIDSLASH1,
	ANIM_MIDSLASH2,
	ANIM_SLASH_START,
	ANIM_SLASH3
};

// Cvars
ConVar hCvarSkullaxeSlashDamage;
ConVar hCvarSkullaxeStabDamage;
ConVar hCvarSkullaxeSlashDistance;
ConVar hCvarSkullaxeStabDistance;
ConVar hCvarSkullaxeRadiusDamage;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	hCvarSkullaxeSlashDamage   = CreateConVar("zp_weapon_skullaxe_slash_damage", "50.0", "Slash damage", 0, true, 0.0);
	hCvarSkullaxeStabDamage    = CreateConVar("zp_weapon_skullaxe_stab_damage", "100.0", "Stab damage", 0, true, 0.0);
	hCvarSkullaxeSlashDistance = CreateConVar("zp_weapon_skullaxe_slash_distance", "80.0", "Slash distance", 0, true, 0.0);
	hCvarSkullaxeStabDistance  = CreateConVar("zp_weapon_skullaxe_stab_distance", "90.0", "Stab distance", 0, true, 0.0);
	hCvarSkullaxeRadiusDamage  = CreateConVar("zp_weapon_skullaxe_radius_damage", "10.0", "Radius damage", 0, true, 0.0);
	
	// Generate config
	AutoExecConfig(true, "zp_weapon_skullaxe", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	// Validate library
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		// If map loaded, then run custom forward
		if (ZP_IsMapLoaded())
		{
			// Execute it
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Purge timers
		hWeaponStab[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE 
		hWeaponSwing[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE 
	}
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	// Delete timers
	delete hWeaponStab[client];
	delete hWeaponSwing[client];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
	// Initialize weapon
	gWeapon = ZP_GetWeaponNameID("skullaxe");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"skullaxe\" wasn't find");

	// Sounds
	gSound = ZP_GetSoundKeyID("SKULLAXE_HIT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SKULLAXE_HIT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int client, int weapon, float flCurrentTime)
{
	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

	// Sets idle animation
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnIdle(int client, int weapon, float flCurrentTime)
{
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	// Sets idle animation
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnPrimaryAttack(int client, int weapon, float flCurrentTime)
{
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	// Sets attack animation  
	ZP_SetWeaponAnimation(client, ANIM_SLASH_START);    
	ZP_SetPlayerAnimation(client, AnimType_MeleeSlash);
	
	// Create timer for swing
	delete hWeaponSwing[client];
	hWeaponSwing[client] = CreateTimer(1.0, Weapon_OnSwing, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	// Play the attack sound
	ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
	
	// Adds the delay to the game tick
	flCurrentTime += ZP_GetWeaponShoot(gWeapon);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSecondaryAttack(int client, int weapon, float flCurrentTime)
{
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	// Sets attack animation  
	ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SLASH2, ANIM_SLASH3 });
	ZP_SetPlayerAnimation(client, AnimType_MeleeStab);
	
	// Create timer for stab
	delete hWeaponStab[client];
	hWeaponStab[client] = CreateTimer(1.0, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	// Play the attack sound
	ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
	
	// Adds the delay to the game tick
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
				
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSlash(int client, int weapon, float flRightShift, float flUpShift, bool bSlash)
{    
	// Initialize vectors
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];

	// Gets weapon position
	ZP_GetPlayerEyePosition(client, 0.0, 0.0, 5.0 + flUpShift, vPosition);
	ZP_GetPlayerEyePosition(client, (bSlash ? hCvarSkullaxeSlashDistance : hCvarSkullaxeStabDistance).FloatValue, flRightShift, 5.0 + flUpShift, vEndPosition);

	// Create the end-point trace
	Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, SelfFilter, client);

	// Initialize some variables
	int victim;
	
	// Validate collisions
	if (!TR_DidHit(hTrace))
	{
		// Initialize the hull box
		static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
		static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
		
		// Create the hull trace
		delete hTrace;
		hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, SelfFilter, client);
		
		// Validate collisions
		if (TR_DidHit(hTrace))
		{
			// Gets victim index
			victim = TR_GetEntityIndex(hTrace);

			// Is hit world ?
			if (victim < 1 || ZP_IsBSPModel(victim))
			{
				UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, SelfFilter, client);
			}
		}
	}
	
	// Validate collisions
	if (TR_DidHit(hTrace))
	{
		// Sets hit animation  
		if (bSlash) ZP_SetWeaponAnimation(client, ANIM_SLASH1);   

		// Gets victim index
		victim = TR_GetEntityIndex(hTrace);
		
		// Returns the collision position of a trace result
		TR_GetEndPosition(vEndPosition, hTrace);

		// Is hit world ?
		if (victim < 1 || ZP_IsBSPModel(victim))
		{
			// Returns the collision plane
			TR_GetPlaneNormal(hTrace, vNormal); 
	
			// Create a sparks effect
			TE_SetupSparks(vEndPosition, vNormal, 50, 2);
			TE_SendToAll();
			
			// Play sound
			ZP_EmitSoundToAll(gSound, 4, client, SNDCHAN_ITEM, SNDLEVEL_LIBRARY);
		}
		else
		{
			// Create the damage for victims
			UTIL_CreateDamage(_, vEndPosition, client, (bSlash ? hCvarSkullaxeSlashDamage : hCvarSkullaxeStabDamage).FloatValue, hCvarSkullaxeRadiusDamage.FloatValue, DMG_NEVERGIB, gWeapon);

			// Validate victim
			if (IsPlayerExist(victim) && ZP_IsPlayerZombie(victim))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 3, victim, SNDCHAN_ITEM, SNDLEVEL_LIBRARY);
			}
		}
	}
	else
	{
		// Sets miss animation  
		if (bSlash) ZP_SetWeaponAnimation(client, ANIM_STAB_MISS);   

		// Play sound
		ZP_EmitSoundToAll(gSound, 5, client, SNDCHAN_ITEM, SNDLEVEL_FRIDGE);
	}
	
	// Close trace 
	delete hTrace;
}

/**
 * @brief Timer for swing effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnSwing(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID); int weapon;

	// Clear timer 
	hWeaponSwing[client] = null;

	// Validate client
	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{
		float flUpShift = 14.0;
		for (int i = 0; i < 15; i++)
		{
			// Do slash
			Weapon_OnSlash(client, weapon, 0.0, flUpShift -= 4.0, true);
		}
	}

	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Timer for stab effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnStab(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID); int weapon;

	// Clear timer 
	hWeaponStab[client] = null;

	// Validate client
	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{
		float flRightShift = -14.0;
		for (int i = 0; i < 15; i++)
		{
			// Do slash
			Weapon_OnSlash(client, weapon, flRightShift += 4.0, 0.0, false);
		}
	}

	// Destroy timer
	return Plugin_Stop;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2)         \
								\
	Weapon_On%0                 \
	(                           \
		%1,                     \
		%2,                     \
		GetGameTime() \
	)

/**
 * @brief Called on holster of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponHolster(int client, int weapon, int weaponID) 
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Delete timers
		delete hWeaponStab[client];
		delete hWeaponSwing[client];
	}
}

/**
 * @brief Called on deploy of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDeploy(int client, int weapon, int weaponID) 
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Call event
		_call.Deploy(client, weapon);
	}
}

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param client            The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Change) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Button primary attack press
		if (iButtons & IN_ATTACK)
		{
			// Call event
			_call.PrimaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK); //! Bugfix
			return Plugin_Changed;
		}

		// Button secondary attack press
		if (iButtons & IN_ATTACK2)
		{
			// Call event
			_call.SecondaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK2); //! Bugfix
			return Plugin_Changed;
		}
		
		// Call event
		_call.Idle(client, weapon);
	}
	
	// Allow button
	return Plugin_Continue;
}

/**
 * @brief Trace filter.
 *  
 * @param entity            The entity index.
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 *
 * @return                  True or false.
 **/
public bool SelfFilter(int entity, int contentsMask, int filter)
{
	return (entity != filter);
}
