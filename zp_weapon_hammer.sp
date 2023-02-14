/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015-2018 qubka (Nikita Ushakov)
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
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Weapon: Hammer",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/  
#define WEAPON_IDLESTAB_TIME  1.33
#define WEAPON_IDLESLASH_TIME 4.0
/**
 * @endsection
 **/

// Timer index
Handle hWeaponStab[MAXPLAYERS+1] = { null, ... }; 
 
// Item index
int gWeapon;

// Sound index
int gSound;

// Animation sequences
enum
{
	ANIM_DRAW,
	ANIM_IDLESLASH,
	ANIM_DRAWSTAB,
	ANIM_IDLESTAB,
	ANIM_MOVESLASH,
	ANIM_MOVESTAB,
	ANIM_SLASH1,
	ANIM_STAB1,
	ANIM_SLASH2,
	ANIM_STAB2
};

// Weapon states
enum
{
	STATE_SLASH,
	STATE_STAB
};

// Cvars
ConVar hCvarHammerSlashDamage;
ConVar hCvarHammerStabDamage;
ConVar hCvarHammerSlashDistance;
ConVar hCvarHammerStabDistance;
ConVar hCvarHammerRadiusDamage;
ConVar hCvarHammerActiveSlow;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarHammerSlashDamage   = CreateConVar("zp_weapon_hammer_slash_damage", "1000.0", "Slash damage", 0, true, 0.0);
	hCvarHammerStabDamage    = CreateConVar("zp_weapon_hammer_stab_damage", "500.0", "Stab damage", 0, true, 0.0);
	hCvarHammerSlashDistance = CreateConVar("zp_weapon_hammer_slash_distance", "90.0", "Slash distance", 0, true, 0.0);
	hCvarHammerStabDistance  = CreateConVar("zp_weapon_hammer_stab_distance", "80.0", "Stab distance", 0, true, 0.0);
	hCvarHammerRadiusDamage  = CreateConVar("zp_weapon_hammer_radius_damage", "50.0", "Radius damage", 0, true, 0.0);
	hCvarHammerActiveSlow    = CreateConVar("zp_weapon_hammer_active_slow", "25.0", "Stamina-based slowdown while carrying in active mode", 0, true, 0.0, true, 100.0);
	
	AutoExecConfig(true, "zp_weapon_hammer", "sourcemod/zombieplague");
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
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("big hammer");

	gSound = ZP_GetSoundKeyID("HAMMER_HIT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HAMMER_HIT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iChangeMode, float flCurrentTime)
{
	delete hWeaponStab[client];
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iChangeMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	if (iChangeMode)
	{
		ZP_SetWeaponAnimation(client, ANIM_IDLESTAB); 
	
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLESTAB_TIME);
	}
	else
	{
		ZP_SetWeaponAnimation(client, ANIM_IDLESLASH); 
	
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLESLASH_TIME);
	}
}

void Weapon_OnDeploy(int client, int weapon, int iChangeMode, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	
	ZP_SetWeaponAnimation(client, iChangeMode ? ANIM_DRAWSTAB : ANIM_DRAW); 
	
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iChangeMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	if (!iChangeMode)
	{
		ZP_SetViewAnimation(client, { ANIM_SLASH1, ANIM_SLASH2 });  
		
		ZP_SetPlayerAnimation(client, AnimType_MeleeSlash);
		
		delete hWeaponStab[client];
		hWeaponStab[client] = CreateTimer(1.0, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		ZP_SetViewAnimation(client, { ANIM_STAB1, ANIM_STAB2 }); 
		
		ZP_SetPlayerAnimation(client, AnimType_MeleeStab);
		
		delete hWeaponStab[client];
		hWeaponStab[client] = CreateTimer(0.2, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	ZP_EmitSoundToAll(gSound, 3, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL);
	
	flCurrentTime += ZP_GetWeaponShoot(gWeapon);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);        
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iChangeMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	ZP_SetWeaponAnimation(client, !iChangeMode ? ANIM_MOVESTAB : ANIM_MOVESLASH); 

	flCurrentTime += ZP_GetWeaponReload(gWeapon);
			
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
	
	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
}

void Weapon_OnSlash(int client, int weapon, float flRightShift, bool bSlash)
{    
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];

	ZP_GetPlayerEyePosition(client, 0.0, 0.0, 5.0, vPosition);
	ZP_GetPlayerEyePosition(client, (bSlash ? hCvarHammerSlashDistance : hCvarHammerStabDistance).FloatValue, flRightShift, 5.0, vEndPosition);

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
	
			TE_SetupSparks(vEndPosition, vNormal, 100, 10);
			TE_SendToAll();
		}
		else
		{
			UTIL_CreateDamage(_, vEndPosition, client, (bSlash ? hCvarHammerSlashDamage : hCvarHammerStabDamage).FloatValue, hCvarHammerRadiusDamage.FloatValue, DMG_NEVERGIB, gWeapon);
		}

		ZP_EmitSoundToAll(gSound, bSlash ? 2 : 1, client, SNDCHAN_ITEM, SNDLEVEL_NORMAL);
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
		Weapon_OnSlash(client, weapon, 0.0, !GetEntProp(weapon, Prop_Data, "m_iMaxHealth"));
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
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_SLASH);
		SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
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
		static float flSlowdown;
		if ((flSlowdown = hCvarHammerActiveSlow.FloatValue) && !GetEntProp(weapon, Prop_Data, "m_iMaxHealth"))
		{
			SetEntPropFloat(client, Prop_Send, "m_flStamina", flSlowdown);
		}
		
		static float flApplyModeTime;
		if ((flApplyModeTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flApplyModeTime <= GetGameTime())
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

			SetEntProp(weapon, Prop_Data, "m_iMaxHealth", !GetEntProp(weapon, Prop_Data, "m_iMaxHealth"));
		}

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
