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
	name            = "[ZP] Weapon: Fists",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/  
#define WEAPON_IDLE_TIME 1.3
/**
 * @endsection
 **/

// Timer index
Handle hWeaponPunch[MAXPLAYERS+1] = { null, ... }; 

// Weapon index
int gWeapon; 

// Sound index
int gSound;

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_DRAW,
	ANIM_PUNCH_RIGHT,
	ANIM_PUNCH_LEFT,
	ANIM_PUNCH_HAND,
	ANIM_GRAB_CASH,
	ANIM_RAPPEL,
	ANIM_RAPPEL_END
};

// Weapon states
enum
{
	PUNCH_ALLOW,
	PUNCH_BLOCK
};

// Cvars
ConVar hCvarFistsDamage;
ConVar hCvarFistsRadius;
ConVar hCvarFistsDistance;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarFistsDamage   = CreateConVar("zp_weapon_fists_damage", "100.0", "Punch damage", 0, true, 0.0);
	hCvarFistsRadius   = CreateConVar("zp_weapon_fists_radius", "50.0", "Damage radius", 0, true, 0.0);
	hCvarFistsDistance = CreateConVar("zp_weapon_fists_distance", "60.0", "Punch distance", 0, true, 0.0);
	
	AutoExecConfig(true, "zp_weapon_fists", "sourcemod/zombieplague");
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
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		hWeaponPunch[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE 
	}
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	delete hWeaponPunch[client];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("fists");
	if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"fists\" wasn't find");
	
	gSound = ZP_GetSoundKeyID("FISTS_HIT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"FISTS_HIT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int client, int weapon, float flCurrentTime)
{
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnIdle(int client, int weapon, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);

	SetEntProp(weapon, Prop_Data, "m_iMaxHealth", PUNCH_ALLOW);
}

void Weapon_OnPrimaryAttack(int client, int weapon, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	ZP_SetWeaponAnimationPair(client, weapon, { ANIM_PUNCH_LEFT, ANIM_PUNCH_RIGHT });
	ZP_SetPlayerAnimation(client, AnimType_MeleeSlash);
	
	delete hWeaponPunch[client];
	hWeaponPunch[client] = CreateTimer(0.16, Weapon_OnPunch, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	ZP_EmitSoundToAll(gSound, GetRandomInt(3, 7), client, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);
	
	flCurrentTime += ZP_GetWeaponShoot(gWeapon);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSecondaryAttack(int client, int weapon, float flCurrentTime)
{
	if (GetEntProp(weapon, Prop_Data, "m_iMaxHealth"))
	{
		return;
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	ZP_SetWeaponAnimation(client, ANIM_PUNCH_HAND);
	ZP_SetPlayerAnimation(client, AnimType_MeleeStab);
	
	delete hWeaponPunch[client];
	hWeaponPunch[client] = CreateTimer(0.83, Weapon_OnPunch, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	ZP_EmitSoundToAll(gSound, GetRandomInt(3, 7), client, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);
	
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
				
	SetEntProp(weapon, Prop_Data, "m_iMaxHealth", PUNCH_BLOCK);            
				
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
}

void Weapon_OnHit(int client, int weapon)
{    
	static float vPosition[3]; static float vEndPosition[3];

	ZP_GetPlayerEyePosition(client, 0.0, 0.0, 5.0, vPosition);
	ZP_GetPlayerEyePosition(client, hCvarFistsDistance.FloatValue, 0.0, 5.0, vEndPosition);

	Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, SelfFilter, client);

	if (!TR_DidHit(hTrace))
	{
		static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
		static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
		
		delete hTrace;
		hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, SelfFilter, client);
		
		if (TR_DidHit(hTrace))
		{
			int victim = TR_GetEntityIndex(hTrace);

			if (victim < 1 || ZP_IsBSPModel(victim))
			{
				UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, SelfFilter, client);
			}
		}
	}
	
	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(vEndPosition, hTrace);

		UTIL_CreateDamage(_, vEndPosition, client, hCvarFistsDamage.FloatValue, hCvarFistsRadius.FloatValue, DMG_NEVERGIB, gWeapon);

		ZP_EmitSoundToAll(gSound, GetRandomInt(1, 2), client, SNDCHAN_ITEM, SNDLEVEL_MELEE - 10);
	}
	
	delete hTrace;
}

/**
 * @brief Timer for punch effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnPunch(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID); int weapon;

	hWeaponPunch[client] = null;

	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{    
		Weapon_OnHit(client, weapon);
	}

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
 * @brief Called after a custom weapon is created.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int client, int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", PUNCH_ALLOW);
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
	if (weaponID == gWeapon)
	{
		delete hWeaponPunch[client];
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
	if (weaponID == gWeapon)
	{
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
	if (weaponID == gWeapon)
	{
		if (iButtons & IN_ATTACK)
		{
			_call.PrimaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK); //! Bugfix
			return Plugin_Changed;
		}

		if (iButtons & IN_ATTACK2)
		{
			_call.SecondaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK2); //! Bugfix
			return Plugin_Changed;
		}
		
		_call.Idle(client, weapon);
	}
	
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
