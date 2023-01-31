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
	name            = "[ZP] Weapon: Balrog I",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_EXPLOSION_DAMAGE         300.0
#define WEAPON_EXPLOSION_RADIUS         150.0
#define WEAPON_EXPLOSION_TIME           2.0
#define WEAPON_IDLE2_TIME               1.66
#define WEAPON_ATTACK2_TIME             3.0
#define WEAPON_RELOAD2_TIME             2.96
#define WEAPON_SWITCH_TIME              2.0
#define WEAPON_SWITCH2_TIME             1.26
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_DRAW,
	ANIM_RELOAD,
	ANIM_CHANGE,
	ANIM_CHANGE2,
	ANIM_IDLE2_1,
	ANIM_SHOOT2_1,
	ANIM_SHOOT2_2,
	ANIM_RELOAD2,
	ANIM_IDLE2_2,
};

// Weapon states
enum
{
	STATE_NORMAL,
	STATE_ACTIVE
};

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound;
#pragma unused gSound

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
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
	// Weapons
	gWeapon = ZP_GetWeaponNameID("balrog1");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"balrog1\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("BALROGI2_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALROGI2_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Cancel reload
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
	
	// Sets draw animation
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	// Resets variables
	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
	
	// Validate mode
	if (!iStateMode)
	{
		return;
	}
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	// Sets idle animation
	ZP_SetWeaponAnimationPair(client, weapon, { ANIM_IDLE2_1, ANIM_IDLE2_2});
	
	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE2_TIME);
}

bool Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate mode
	if (!iStateMode)
	{
		return false;
	}
	
	// Validate clip
	if (min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
	{
		return false;
	}

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return false;
	}
	
	// Sets reload animation
	ZP_SetWeaponAnimation(client, ANIM_RELOAD2); 
	
	// Adds the delay to the game tick
	flCurrentTime += WEAPON_RELOAD2_TIME;
	
	// Sets next attack time
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	// Remove the delay to the game tick
	flCurrentTime -= 0.5;
	
	// Sets reloading time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);

	// Sets normal state
	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
	
	// Return on the success
	return true;
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Gets new amount
	int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

	// Sets ammunition
	SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

	// Sets reload time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

bool Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate mode
	if (!iStateMode)
	{
		return false;
	}

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return false;
	}
	
	// Validate clip
	if (iClip <= 0)
	{
		// Emit empty sound
		ClientCommand(client, "play weapons/clipempty_rifle.wav");
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
		return false;
	}
	
	// Validate water
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return false;
	}
	
	// Adds the delay to the game tick
	flCurrentTime += WEAPON_ATTACK2_TIME;
	
	// Sets next attack time
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
	 
	// Substract ammo
	iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 
	 
	// Play sound
	ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
	
	// Sets attack animation
	ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT2_1, ANIM_SHOOT2_2});
	
	// Create a explosion
	Weapon_OnCreateExplosion(client, weapon);
	
	// Sets normal state
	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
	
	// Initialize name char
	static char sName[NORMAL_LINE_LENGTH];
	
	// Gets viewmodel index
	int view = ZP_GetClientViewModel(client, true);
	
	// Create a muzzle
	ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
	UTIL_CreateParticle(view, _, _, "1", sName, 0.1);
	
	// Create a shell
	ZP_GetWeaponModelShell(gWeapon, sName, sizeof(sName));
	UTIL_CreateParticle(view, _, _, "2", sName, 0.1);
	
	// Return on the success
	return true;
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Validate clip
	if (iClip <= 0)
	{
		return;
	}
	
	// Validate mode
	if (!iStateMode)
	{
		/// Block the real attack
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

		// Sets change animation
		ZP_SetWeaponAnimation(client, ANIM_CHANGE); 
		
		// Adds the delay to the game tick
		flCurrentTime += WEAPON_SWITCH_TIME;
		
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 

		// Sets active state
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_ACTIVE);
	}
	else
	{
		// Sets change animation
		ZP_SetWeaponAnimation(client, ANIM_CHANGE2); 

		// Adds the delay to the game tick
		flCurrentTime += WEAPON_SWITCH2_TIME;

		// Sets next attack time
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
		
		// Sets normal state
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
	}
}

void Weapon_OnCreateExplosion(int client, int weapon)
{
	//#pragma unused client, weapon
	
	// Initialize vectors
	static float vPosition[3]; static float vAngle[3]; static float vEndPosition[3]; 

	// Gets weapon position
	ZP_GetPlayerEyePosition(client, 30.0, 0.0, 0.0, vPosition);

	// Gets client eye angle
	GetClientEyeAngles(client, vAngle);
	
	// Fire a bullet 
	TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, SelfFilter, client); 

	// Validate collisions
	if (TR_DidHit()) 
	{
		// Returns the collision position of a trace result
		TR_GetEndPosition(vEndPosition); 
	
		// Create an explosion
		UTIL_CreateExplosion(vEndPosition, EXP_NOFIREBALL | EXP_NOSOUND, _, WEAPON_EXPLOSION_DAMAGE, WEAPON_EXPLOSION_RADIUS, "balrog1", client, weapon);

		// Create an explosion effect
		UTIL_CreateParticle(_, vEndPosition, _, _, "explosion_hegrenade_interior", WEAPON_EXPLOSION_TIME);
	
		// Play sound
		ZP_EmitAmbientSound(gSound, 2, vEndPosition, SOUND_FROM_WORLD, SNDLEVEL_NORMAL);
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
		GetEntProp(%2, Prop_Data, "m_iHealth"), \
								\
		GetGameTime()           \
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
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
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
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Time to reload weapon
		static float flReloadTime;
		if ((flReloadTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flReloadTime <= GetGameTime())
		{
			// Call event
			_call.ReloadFinish(client, weapon);
		}
		else
		{
			// Button reload press
			if (iButtons & IN_RELOAD)
			{
				// Call event
				if (_call.Reload(client, weapon))
				{
					iButtons &= (~IN_RELOAD); //! Bugfix
					return Plugin_Changed;
				}
			}
		}
		
		// Button primary attack press
		if (iButtons & IN_ATTACK)
		{
			// Call event
			if (_call.PrimaryAttack(client, weapon))
			{
				iButtons &= (~IN_ATTACK); //! Bugfix
				return Plugin_Changed;
			}
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
