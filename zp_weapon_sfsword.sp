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
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_IDLE_ON_TIME  10.0
#define WEAPON_IDLE_OFF_TIME 5.0
/**
 * @endsection
 **/

// Timer index
Handle hWeaponStab[MAXPLAYERS+1] = { null, ... }; 
Handle hWeaponSwing[MAXPLAYERS+1] = { null, ... }; 
Handle hWeaponSwingAgain[MAXPLAYERS+1] = { null, ... }; 
 
// Weapon index
int gWeapon;

// Sound index
int gSoundAttack; int gSoundHit; int gSoundIdle;

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

// Cvars
ConVar hCvarSfswordSlashDamage;
ConVar hCvarSfswordStabDamage;
ConVar hCvarSfswordSlashDistance;
ConVar hCvarSfswordStabDistance;
ConVar hCvarSfswordRadiusDamage;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarSfswordSlashDamage   = CreateConVar("zp_weapon_sfsword_slash_damage", "50.0", "Slash damage", 0, true, 0.0);
	hCvarSfswordStabDamage    = CreateConVar("zp_weapon_sfsword_stab_damage", "100.0", "Stab damage", 0, true, 0.0);
	hCvarSfswordSlashDistance = CreateConVar("zp_weapon_sfsword_slash_distance", "70.0", "Slash distance", 0, true, 0.0);
	hCvarSfswordStabDistance  = CreateConVar("zp_weapon_sfsword_stab_distance", "35.0", "Stab distance", 0, true, 0.0);
	hCvarSfswordRadiusDamage  = CreateConVar("zp_weapon_sfsword_radius_damage", "10.0", "Radius damage", 0, true, 0.0);
	
	AutoExecConfig(true, "zp_weapon_sfsword", "sourcemod/zombieplague");
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
	delete hWeaponStab[client];
	delete hWeaponSwing[client];
	delete hWeaponSwingAgain[client];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("sfsword");

	gSoundAttack = ZP_GetSoundKeyID("sfsword_hit_sounds");
	if (gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"sfsword_hit_sounds\" wasn't find");
	gSoundHit = ZP_GetSoundKeyID("sfsword2_hit_sounds");
	if (gSoundHit == -1) SetFailState("[ZP] Custom sound key ID from name : \"sfsword2_hit_sounds\" wasn't find");
	gSoundIdle = ZP_GetSoundKeyID("sfsword_idle_sounds");
	if (gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"sfsword_idle_sounds\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnIdle(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);

	if (iChangeMode)
	{
		ZP_SetWeaponAnimation(client, ANIM_OFF_IDLE); 
	
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_OFF_TIME);
	}
	else
	{
		ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_ON_TIME);
	
		ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
	}
}

void Weapon_OnHolster(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	delete hWeaponStab[client];
	delete hWeaponSwing[client];
	delete hWeaponSwingAgain[client];
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
}

void Weapon_OnDeploy(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_ON);
	
	SetEntProp(weapon, Prop_Data, "m_iHealth", ATTACK_SLASH_1);
	
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);

	if (iChangeMode)
	{
		ZP_SetViewAnimation(client, { ANIM_OFF_SLASH1, ANIM_OFF_SLASH2 });

		ZP_SetPlayerAnimation(client, AnimType_MeleeStab);
		
		delete hWeaponStab[client];
		hWeaponStab[client] = CreateTimer(0.35, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		ZP_EmitSoundToAll(gSoundAttack, 5, client, SNDCHAN_WEAPON);
	}
	else
	{
		int iCount = iStep % ATTACK_SLASH_SIZE;

		switch (iCount)
		{
			case ATTACK_SLASH_DOUBLE :
			{
				ZP_SetWeaponAnimation(client, ANIM_STAB);   
				
				ZP_EmitSoundToAll(gSoundAttack, 4, client, SNDCHAN_WEAPON);
			}

			default :
			{
				ZP_SetWeaponAnimation(client, ANIM_MIDSLASH1 + iCount);   
				
				ZP_EmitSoundToAll(gSoundAttack, GetRandomInt(1, 3), client, SNDCHAN_WEAPON);
			}
		}

		ZP_SetPlayerAnimation(client, AnimType_MeleeSlash);
		
		delete hWeaponSwing[client];
		hWeaponSwing[client] = CreateTimer(0.35, Weapon_OnSwing, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		SetEntProp(weapon, Prop_Data, "m_iHealth", iCount + 1);
	}

	flCurrentTime += ZP_GetWeaponShoot(gWeapon);
				
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iStep, int iChangeMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
	
	if (iChangeMode)
	{
		if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
		{
			return;
		}
		
		ZP_SetWeaponAnimation(client, ANIM_ON); 
	}
	else
	{
		ZP_SetWeaponAnimation(client, ANIM_OFF);
	}
	
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
	
	if (IsValidEdict(entity))
	{
		SetEntProp(entity, Prop_Send, "m_nBody", (!iChangeMode));
	}
	
	SetEntProp(weapon, Prop_Data, "m_iMaxHealth", (!iChangeMode));
	
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
				
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSlash(int client, int weapon, float flRightShift, float flUpShift, bool bSlash)
{    
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];

	ZP_GetPlayerEyePosition(client, 0.0, 0.0, 5.0 + flUpShift, vPosition);
	ZP_GetPlayerEyePosition(client, (bSlash ? hCvarSfswordSlashDistance : hCvarSfswordStabDistance).FloatValue, flRightShift, 5.0 + flUpShift, vEndPosition);

	Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, SelfFilter, client);

	int victim;
	
	if (!TR_DidHit(hTrace))
	{
		static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
		static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
		
		delete hTrace;
		hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, SelfFilter, client);
		
		if (TR_DidHit(hTrace))
		{
			victim = TR_GetEntityIndex(hTrace);

			if (victim < 1 || ZP_IsBSPModel(victim))
			{
				UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, SelfFilter, client);
			}
		}
	}
	
	if (TR_DidHit(hTrace))
	{
		victim = TR_GetEntityIndex(hTrace);
		
		TR_GetEndPosition(vEndPosition, hTrace);

		if (victim < 1 || ZP_IsBSPModel(victim))
		{
			TR_GetPlaneNormal(hTrace, vNormal); 
	
			TE_SetupSparks(vEndPosition, vNormal, 50, 2);
			TE_SendToAll();
			
			ZP_EmitSoundToAll(gSoundHit, bSlash ? GetRandomInt(3, 4) : 5, client, SNDCHAN_ITEM);
		}
		else
		{
			UTIL_CreateDamage(_, vEndPosition, client, (bSlash ? hCvarSfswordSlashDamage : hCvarSfswordStabDamage).FloatValue, hCvarSfswordRadiusDamage.FloatValue, DMG_NEVERGIB, gWeapon);

			if (IsPlayerExist(victim) && ZP_IsPlayerZombie(victim))
			{
				ZP_EmitSoundToAll(gSoundHit, bSlash ? GetRandomInt(1, 2) : 5, victim, SNDCHAN_ITEM);
			}
		}
	}
	
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
	int client = GetClientOfUserId(userID); int weapon;

	hWeaponStab[client] = null;

	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{    
		Weapon_OnSlash(client, weapon, 0.0, 0.0, false);
	}

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
	int client = GetClientOfUserId(userID); int weapon;

	hWeaponSwing[client] = null;

	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{ 
		float flUpShift = 14.0;
		float flRightShift = 14.0;
		float flRightModifier = 2.0;
		
		switch ((GetEntProp(weapon, Prop_Data, "m_iHealth") - 1) % ATTACK_SLASH_SIZE)
		{
			case ATTACK_SLASH_2:
			{
				flRightShift *= -1.0;
				flRightModifier *= -1.0;
			}
			
			case ATTACK_SLASH_DOUBLE:
			{
				delete hWeaponSwingAgain[client];
				hWeaponSwingAgain[client] = CreateTimer(0.3, Weapon_OnSwingAgain, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		for (int i = 0; i < 12; i++)
		{
			Weapon_OnSlash(client, weapon, flRightShift -= flRightModifier, flUpShift -= 2.0, true);
		}
	}

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
	int client = GetClientOfUserId(userID); int weapon;

	hWeaponSwingAgain[client] = null;

	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{
		float flRightShift = -14.0;
		for (int i = 0; i < 14; i++)
		{
			Weapon_OnSlash(client, weapon, flRightShift += 2.0, 0.0, true);
		}
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
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
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
	if (weaponID == gWeapon)
	{
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
	if (weaponID == gWeapon)
	{
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
	if (weaponID == gWeapon)
	{
		if (iButtons & IN_ATTACK)
		{
			_call.PrimaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK); //! Bugfix
			return Plugin_Changed;
		}

		if (iButtons & IN_ATTACK2 || GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
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
