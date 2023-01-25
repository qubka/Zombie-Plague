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
	name            = "[ZP] Weapon: Sfsword",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_SLASH_DAMAGE            50.0
#define WEAPON_STAB_DAMAGE             100.0
#define WEAPON_RADIUS_DAMAGE           10.0
#define WEAPON_SLASH_DISTANCE          70.0
#define WEAPON_STAB_DISTANCE           35.0
#define WEAPON_IDLE_ON_TIME            10.0
#define WEAPON_IDLE_OFF_TIME           5.0
/**
 * @endsection
 **/

// Timer index
Handle hWeaponStab[MAXPLAYERS+1] = { null, ... }; 
Handle hWeaponSwing[MAXPLAYERS+1] = { null, ... }; 
Handle hWeaponSwingAgain[MAXPLAYERS+1] = { null, ... }; 
 
// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSoundAttack; int gSoundHit; int gSoundIdle; ConVar hSoundLevel;
#pragma unused gSoundAttack, gSoundHit, gSoundIdle, hSoundLevel

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_ON,
	ANIM_OFF,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_IDLE2,
	ANIM_MIDSLASH1,
	ANIM_MIDSLASH2,
	ANIM_MIDSLASH3,
	ANIM_OFF_IDLE,
	ANIM_OFF_SLASH1,
	ANIM_OFF_SLASH2
};

// Weapon attack
enum
{
	ATTACK_SLASH_1,
	ATTACK_SLASH_2,
	ATTACK_SLASH_3,
	ATTACK_SLASH_DOUBLE,
	ATTACK_SLASH_SIZE
};

// Weapon states
enum
{
	STATE_ON,
	STATE_OFF
};

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
		hWeaponSwingAgain[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE 
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
	delete hWeaponSwingAgain[client];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
	// Initialize weapon
	gWeapon = ZP_GetWeaponNameID("sfsword");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"sfsword\" wasn't find");

	// Sounds
	gSoundAttack = ZP_GetSoundKeyID("SFSWORD_HIT_SOUNDS");
	if (gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"SFSWORD_HIT_SOUNDS\" wasn't find");
	gSoundHit = ZP_GetSoundKeyID("SFSWORD2_HIT_SOUNDS");
	if (gSoundHit == -1) SetFailState("[ZP] Custom sound key ID from name : \"SFSWORD2_HIT_SOUNDS\" wasn't find");
	gSoundIdle = ZP_GetSoundKeyID("SFSWORD_IDLE_SOUNDS");
	if (gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"SFSWORD_IDLE_SOUNDS\" wasn't find");

	// Cvars
	hSoundLevel = FindConVar("zp_seffects_level");
	if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnIdle(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iStep, iChangeMode, flCurrentTime

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	// Resets sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);

	// Validate mode
	if (iChangeMode)
	{
		// Sets idle animation
		ZP_SetWeaponAnimation(client, ANIM_OFF_IDLE); 
	
		// Sets next idle time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_OFF_TIME);
	}
	else
	{
		// Sets idle animation
		ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
		// Sets next idle time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_ON_TIME);
	
		// Play sound
		ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, hSoundLevel.IntValue);
	}
}

void Weapon_OnHolster(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iStep, iChangeMode, flCurrentTime
	
	// Delete timers
	delete hWeaponStab[client];
	delete hWeaponSwing[client];
	delete hWeaponSwingAgain[client];
	
	// Stop sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iStep, iChangeMode, flCurrentTime

	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	
	// Sets draw animation
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	// Sets default mode
	SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_ON);
	
	// Sets attack mode
	SetEntProp(weapon, Prop_Data, "m_iHealth", ATTACK_SLASH_1);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iStep, iChangeMode, flCurrentTime

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Resets sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);

	// Validate mode
	if (iChangeMode)
	{
		// Sets attack animation  
		ZP_SetWeaponAnimationPair(client, weapon, { ANIM_OFF_SLASH1, ANIM_OFF_SLASH2 });

		// Sets attack animation
		ZP_SetPlayerAnimation(client, AnimType_MeleeStab);
		
		// Create timer for stab
		delete hWeaponStab[client];
		hWeaponStab[client] = CreateTimer(0.35, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		// Play the attack sound
		ZP_EmitSoundToAll(gSoundAttack, 5, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
	}
	else
	{
		// Generate the attack mode
		int iCount = iStep % ATTACK_SLASH_SIZE;

		// Switch count
		switch (iCount)
		{
			case ATTACK_SLASH_DOUBLE :
			{
				// Sets attack animation  
				ZP_SetWeaponAnimation(client, ANIM_STAB);   
				
				// Play the attack sound
				ZP_EmitSoundToAll(gSoundAttack, 4, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
			}

			default :
			{
				// Sets attack animation  
				ZP_SetWeaponAnimation(client, ANIM_MIDSLASH1 + iCount);   
				
				// Play the attack sound
				ZP_EmitSoundToAll(gSoundAttack, GetRandomInt(1, 3), client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
			}
		}

		// Sets attack animation
		ZP_SetPlayerAnimation(client, AnimType_MeleeSlash);
		
		// Create timer for swing
		delete hWeaponSwing[client];
		hWeaponSwing[client] = CreateTimer(0.35, Weapon_OnSwing, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		// Sets attack mode
		SetEntProp(weapon, Prop_Data, "m_iHealth", iCount + 1);
	}

	// Adds the delay to the game tick
	flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
				
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iStep, iChangeMode, flCurrentTime
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	// Resets sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	
	// Validate mode
	if (iChangeMode)
	{
		// Validate water
		if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
		{
			return;
		}
		
		// Sets on animation
		ZP_SetWeaponAnimation(client, ANIM_ON); 
	}
	else
	{
		// Sets off animation
		ZP_SetWeaponAnimation(client, ANIM_OFF);
	}
	
	// Gets worldmodel index
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
	
	// Validate entity
	if (IsValidEdict(entity))
	{
		// Sets body index
		SetEntProp(entity, Prop_Send, "m_nBody", (!iChangeMode));
	}
	
	// Sets different mode
	SetEntProp(weapon, Prop_Data, "m_iMaxHealth", (!iChangeMode));
	
	// Adds the delay to the game tick
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
				
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSlash(int client, int weapon, float flRightShift, float flUpShift, bool bSlash)
{    
	//#pragma unused client, weapon, flRightShift, bSlash

	// Initialize vectors
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];

	// Gets weapon position
	ZP_GetPlayerGunPosition(client, 0.0, 0.0, 5.0 + flUpShift, vPosition);
	ZP_GetPlayerGunPosition(client, bSlash ? WEAPON_SLASH_DISTANCE : WEAPON_STAB_DISTANCE, flRightShift, 5.0 + flUpShift, vEndPosition);

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
			ZP_EmitSoundToAll(gSoundHit, bSlash ? GetRandomInt(3, 4) : 5, client, SNDCHAN_ITEM, hSoundLevel.IntValue);
		}
		else
		{
			// Create the damage for victims
			UTIL_CreateDamage(_, vEndPosition, client, bSlash ? WEAPON_SLASH_DAMAGE : WEAPON_STAB_DAMAGE, WEAPON_RADIUS_DAMAGE, DMG_NEVERGIB, gWeapon);

			// Validate victim
			if (IsPlayerExist(victim) && ZP_IsPlayerZombie(victim))
			{
				// Play sound
				ZP_EmitSoundToAll(gSoundHit, bSlash ? GetRandomInt(1, 2) : 5, victim, SNDCHAN_ITEM, hSoundLevel.IntValue);
			}
		}
	}
	
	// Close trace 
	delete hTrace;
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
		// Do slash
		Weapon_OnSlash(client, weapon, 0.0, 0.0, false);
	}

	// Destroy timer
	return Plugin_Stop;
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
		float flRightShift = 14.0;
		float flRightModifier = 2.0;
		
		// Swith attack mode
		switch ((GetEntProp(weapon, Prop_Data, "m_iHealth") - 1) % ATTACK_SLASH_SIZE)
		{
			case ATTACK_SLASH_2:
			{
				// Change shift
				flRightShift *= -1.0;
				flRightModifier *= -1.0;
			}
			
			case ATTACK_SLASH_DOUBLE:
			{
				// Create timer for swing again
				delete hWeaponSwingAgain[client];
				hWeaponSwingAgain[client] = CreateTimer(0.3, Weapon_OnSwingAgain, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		for (int i = 0; i < 12; i++)
		{
			// Do slash
			Weapon_OnSlash(client, weapon, flRightShift -= flRightModifier, flUpShift -= 2.0, true);
		}
	}

	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Timer for swing again effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnSwingAgain(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID); int weapon;

	// Clear timer 
	hWeaponSwingAgain[client] = null;

	// Validate client
	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{
		float flRightShift = -14.0;
		for (int i = 0; i < 14; i++)
		{
			// Do slash
			Weapon_OnSlash(client, weapon, flRightShift += 2.0, 0.0, true);
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
								\
		GetEntProp(%2, Prop_Data, "m_iHealth"), \
								\
		GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
								\
		GetGameTime() \
	)

/**
 * @brief Called after a custom weapon is created.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int client, int weapon, int weaponID)
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Resets variables
		SetEntProp(weapon, Prop_Data, "m_iHealth", ATTACK_SLASH_1);
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_ON);
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
		// Call event
		_call.Holster(client, weapon);
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
		if (iButtons & IN_ATTACK2 || GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
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
