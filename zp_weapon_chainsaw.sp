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
	name            = "[ZP] Weapon: ChainSaw",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME         5.0
#define WEAPON_IDLE2_TIME        1.66
#define WEAPON_ATTACK_TIME       1.5
#define WEAPON_ATTACK_START_TIME 0.5
#define WEAPON_ATTACK_END_TIME   1.5
#define WEAPON_ATTACK_SOUND_TIME 0.335
/**
 * @endsection
 **/

// Timer index
Handle hWeaponStab[MAXPLAYERS+1] = { null, ... }; 
 
// Item index
int gWeapon;

// Sound index
int gSoundAttack; int gSoundHit; int gSoundIdle;

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_DUMMY,
	ANIM_EMPTY_IDLE,
	ANIM_EMPTY_SHOOT1,
	ANIM_EMPTY_RELOAD,
	ANIM_EMPTY_DRAW,
	ANIM_ATTACK_END,
	ANIM_ATTACK_LOOP1,
	ANIM_ATTACK_LOOP2,
	ANIM_ATTACK_START,
	ANIM_EMPTY_SHOOT2
};

// Weapon states
enum
{
	STATE_BEGIN,
	STATE_ATTACK
};

// Cvars
ConVar hCvarChainsawSlashDamage;
ConVar hCvarChainsawStabDamage;
ConVar hCvarChainsawSlashDistance;
ConVar hCvarChainsawStabDistance;
ConVar hCvarChainsawRadiusDamage;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarChainsawSlashDamage   = CreateConVar("zp_weapon_chainsaw_slash_damage", "100.0", "Slash damage", 0, true, 0.0);
	hCvarChainsawStabDamage    = CreateConVar("zp_weapon_chainsaw_stab_damage", "50.0", "Stab damage", 0, true, 0.0);
	hCvarChainsawSlashDistance = CreateConVar("zp_weapon_chainsaw_slash_distance", "80.0", "Slash distance", 0, true, 0.0);
	hCvarChainsawStabDistance  = CreateConVar("zp_weapon_chainsaw_stab_distance", "90.0", "Stab distance", 0, true, 0.0);
	hCvarChainsawRadiusDamage  = CreateConVar("zp_weapon_chainsaw_radius_damage", "10.0", "Radius damage", 0, true, 0.0);
	
	AutoExecConfig(true, "zp_weapon_chainsaw", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("chainsaw");

	gSoundAttack = ZP_GetSoundKeyID("chainsaw_shoot_sounds");
	if (gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"chainsaw_shoot_sounds\" wasn't find");
	gSoundHit = ZP_GetSoundKeyID("chainsaw_hit_sounds");
	if (gSoundHit == -1) SetFailState("[ZP] Custom sound key ID from name : \"chainsaw_hit_sounds\" wasn't find");
	gSoundIdle = ZP_GetSoundKeyID("chainsaw_idle_sounds");
	if (gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"chainsaw_idle_sounds\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	delete hWeaponStab[client];
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (iClip <= 0)
	{
		if (iAmmo)
		{
			Weapon_OnReload(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
			return; /// Execute fake reload
		}
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
	
	if (iClip)
	{
		ZP_SetWeaponAnimation(client, ANIM_IDLE); 
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
	
		ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
	}
	else
	{
		ZP_SetWeaponAnimation(client, ANIM_EMPTY_IDLE);
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE2_TIME);
	}
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
	{
		return;
	}
	
	if (iStateMode > STATE_BEGIN)
	{
		Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		return;
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetWeaponAnimation(client, !iClip ? ANIM_EMPTY_RELOAD : ANIM_RELOAD); 
	ZP_SetPlayerAnimation(client, AnimType_Reload);
	
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
	
	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

	SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	
	ZP_SetWeaponAnimation(client, !iClip ? ANIM_EMPTY_DRAW : ANIM_DRAW); 
	
	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);

	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (iClip <= 0)
	{
		if (iStateMode > STATE_BEGIN)
		{
			Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		}
		else
		{
			Weapon_OnSecondaryAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		}
		return;
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		return;
	}
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);

	switch (iStateMode)
	{
		case STATE_BEGIN :
		{
			ZP_SetWeaponAnimation(client, ANIM_ATTACK_START);        

			SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_ATTACK);
			SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);

			flCurrentTime += WEAPON_ATTACK_START_TIME;
			
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);   
		}

		case STATE_ATTACK :
		{
			ZP_SetViewAnimation(client, { ANIM_ATTACK_LOOP1, ANIM_ATTACK_LOOP2 });   
			ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
	
			iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); if (!iClip)
			{
				Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
				return;
			}

			if (GetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle") < flCurrentTime)
			{
				ZP_EmitSoundToAll(gSoundAttack, 1, client, SNDCHAN_WEAPON);
				SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", flCurrentTime + WEAPON_ATTACK_SOUND_TIME);
			}
			
			flCurrentTime += ZP_GetWeaponShoot(gWeapon);
			
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);         

			SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
			
			Weapon_OnSlash(client, weapon, 0.0, true);

			static char sMuzzle[NORMAL_LINE_LENGTH];
			ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
			
			UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sMuzzle, 3.5);
			
			static float vVelocity[3]; int iFlags = GetEntityFlags(client);
			float vKickback[] = { /*upBase = */0.8, /* lateralBase = */2.45, /* upMod = */2.15, /* lateralMod = */1.05, /* upMax = */1.5, /* lateralMax = */3.5, /* directionChange = */5.0 };

			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

			if (GetVectorLength(vVelocity) <= 0.0)
			{
			}
			else if (!(iFlags & FL_ONGROUND))
			{
				for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 1.3;
			}
			else if (iFlags & FL_DUCKING)
			{
				for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 0.75;
			}
			else
			{
				for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 1.15;
			}
			ZP_CreateWeaponKickBack(client, vKickback[0], vKickback[1], vKickback[2], vKickback[3], vKickback[4], vKickback[5], RoundFloat(vKickback[6]));
		}
	}
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		return;
	}

	if (iStateMode > STATE_BEGIN)
	{
		Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		return;
	}
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);

	if (!iClip)
	{
		ZP_SetViewAnimation(client, { ANIM_EMPTY_SHOOT1, ANIM_EMPTY_SHOOT2 });    
		
		ZP_EmitSoundToAll(gSoundAttack, 4, client, SNDCHAN_WEAPON);
	}
	else
	{
		ZP_SetViewAnimation(client, { ANIM_SHOOT1, ANIM_SHOOT2 });     

		ZP_EmitSoundToAll(gSoundAttack, GetRandomInt(2, 3), client, SNDCHAN_WEAPON);
	}
	
	flCurrentTime += WEAPON_ATTACK_TIME;

	delete hWeaponStab[client];
	hWeaponStab[client] = CreateTimer(0.105, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
}

void Weapon_OnSlash(int client, int weapon, float flRightShift, bool bSlash)
{    
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];

	ZP_GetPlayerEyePosition(client, 0.0, 0.0, 10.0, vPosition);
	ZP_GetPlayerEyePosition(client, (bSlash ? hCvarChainsawSlashDistance : hCvarChainsawStabDistance).FloatValue, flRightShift, 10.0, vEndPosition);

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
			
			ZP_EmitSoundToAll(gSoundHit, GetRandomInt(1, 2), client, SNDCHAN_ITEM);
		}
		else
		{
			UTIL_CreateDamage(_, vEndPosition, client, (bSlash ? hCvarChainsawSlashDamage : hCvarChainsawStabDamage).FloatValue, hCvarChainsawRadiusDamage.FloatValue, DMG_NEVERGIB, gWeapon);

			if (IsClientValid(victim) && ZP_IsPlayerZombie(victim))
			{
				ZP_EmitSoundToAll(gSoundHit, GetRandomInt(3, 4), victim, SNDCHAN_ITEM);
			}
		}
	}
	
	delete hTrace;
}

void Weapon_OnEndAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (iStateMode > STATE_BEGIN)
	{
		ZP_SetWeaponAnimation(client, ANIM_ATTACK_END);        

		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);

		flCurrentTime += WEAPON_ATTACK_END_TIME;
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
	}
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
		float flRightShift = -14.0;
		for (int i = 0; i < 15; i++)
		{
			Weapon_OnSlash(client, weapon, flRightShift += 4.0, false);
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
		GetEntProp(%2, Prop_Send, "m_iClip1"), \
								\
		GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
								\
		GetEntProp(%2, Prop_Data, "m_iHealth"), \
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
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);
		SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);
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
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
		static float flReloadTime;
		if ((flReloadTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flReloadTime <= GetGameTime())
		{
			_call.ReloadFinish(client, weapon);
		}
		else
		{
			if (iButtons & IN_RELOAD)
			{
				_call.Reload(client, weapon);
				iButtons &= (~IN_RELOAD); //! Bugfix
				return Plugin_Changed;
			}
		}

		if (iButtons & IN_ATTACK)
		{
			_call.PrimaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK); //! Bugfix
			return Plugin_Changed;
		}
		else if (iLastButtons & IN_ATTACK)
		{
			_call.EndAttack(client, weapon);
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
