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
	name            = "[ZP] Weapon: SFPistol",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_COLOR      {185, 212, 11, 255}
#define WEAPON_IDLE_TIME       3.33
#define WEAPON_ATTACK_END_TIME 0.5
/**
 * @endsection
 **/

// Item index
int gWeapon;

// Sound index
int gSoundAttack; int gSoundIdle;

// Decal index
int gBeam;

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_ATTACK_LOOP1,
	ANIM_ATTACK_LOOP2,
	ANIM_DRAW,
	ANIM_RELOAD,
	ANIM_ATTACK_END
};

// Weapon states
enum
{
	STATE_BEGIN,
	STATE_ATTACK
};

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
	gWeapon = ZP_GetWeaponNameID("sfpistol");

	gSoundAttack = ZP_GetSoundKeyID("sfpistol_shoot_sounds");
	if (gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"sfpistol_shoot_sounds\" wasn't find");
	gSoundIdle = ZP_GetSoundKeyID("sfpistol_idle_sounds");
	if (gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"sfpistol_idle_sounds\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
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
	
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
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
	
	ZP_SetWeaponAnimation(client, ANIM_RELOAD); 
	ZP_SetPlayerAnimation(client, PLAYERANIMEVENT_RELOAD);
	
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
	
	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
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

	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_BEGIN);

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

	ZP_SetViewAnimation(client, { ANIM_ATTACK_LOOP1, ANIM_ATTACK_LOOP2 });   
	ZP_SetPlayerAnimation(client, PLAYERANIMEVENT_FIRE_GUN_PRIMARY);
	
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_ATTACK);
	
	iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); if (!iClip)
	{
		Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		return;
	}
	
	ZP_StopSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON);
	ZP_EmitSoundToAll(gSoundAttack, 1, client, SNDCHAN_WEAPON);

	flCurrentTime += ZP_GetWeaponShoot(gWeapon);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);         

	Weapon_OnCreateBeam(client, weapon);
	
	static char sMuzzle[NORMAL_LINE_LENGTH];
	ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));

	UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sMuzzle, 0.1);
}

void Weapon_OnCreateBeam(int client, int weapon)
{
	static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngle);

	ZP_FireBullets(client, weapon, vPosition, vAngle, 0, GetRandomInt(0, 1000), 0.0, 0.0, 0.0, 0, 0.0);

	TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, SelfFilter, client);
	
	TR_GetEndPosition(vEndPosition);

	ZP_GetPlayerEyePosition(client, 30.0, 3.5, -10.0, vPosition);

	TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, 0, 0, 0, ZP_GetWeaponShoot(gWeapon), 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
	TE_SendToAll();
}

void Weapon_OnEndAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (iStateMode > STATE_BEGIN)
	{
		ZP_SetWeaponAnimation(client, ANIM_ATTACK_END);        

		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_BEGIN);

		flCurrentTime += WEAPON_ATTACK_END_TIME;
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
	}
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
		GetEntProp(%2, Prop_Data, "m_iSecondaryAmmoCount"), \
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
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_BEGIN);
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
