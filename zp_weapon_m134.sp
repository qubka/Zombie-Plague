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
	name            = "[ZP] Weapon: M134",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Item index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound;
#pragma unused gSound

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_ATTACK_START,
	ANIM_ATTACK_END
};

// Weapon states
enum
{
	STATE_BEGIN,
	STATE_ATTACK
};

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME              2.0
#define WEAPON_ATTACK_START_TIME      1.0
#define WEAPON_ATTACK_END_TIME        1.0
/**
 * @endsection
 **/

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
	gWeapon = ZP_GetWeaponNameID("m134");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"m134\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("M134_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"M134_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Kill an effect
	Weapon_OnCreateEffect(client, weapon, "Kill");
	
	// Cancel reload
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate clip
	if (iClip <= 0)
	{
		// Validate ammo
		if (iAmmo)
		{
			Weapon_OnReload(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
			return; /// Execute fake reload
		}
	}
	
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

void Weapon_OnDrop(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
	
	// Kill an effect
	Weapon_OnCreateEffect(client, weapon, "Kill");
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);

	// Create an effect
	Weapon_OnCreateEffect(client, weapon);
	
	// Sets draw animation
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	// Sets attack state
	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);
	
	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate mode
	if (iStateMode > STATE_BEGIN)
	{
		Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		return;
	}

	// Validate clip
	if (min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
	{
		return;
	}

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Sets reload animation
	ZP_SetWeaponAnimation(client, ANIM_RELOAD); 
	ZP_SetPlayerAnimation(client, AnimType_Reload);
	
	// Adds the delay to the game tick
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	// Remove the delay to the game tick
	flCurrentTime -= 0.5;
	
	// Sets reloading time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
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

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate clip
	if (iClip <= 0)
	{
		// Validate mode
		if (iStateMode > STATE_BEGIN)
		{
			Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
		}
		return;
	}

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	// Switch mode
	switch (iStateMode)
	{
		case STATE_BEGIN :
		{
			// Sets begin animation
			ZP_SetWeaponAnimation(client, ANIM_ATTACK_START);        

			// Sets attack state
			SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_ATTACK);

			// Adds the delay to the game tick
			flCurrentTime += WEAPON_ATTACK_START_TIME;
			
			// Sets next attack time
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);   
		}
		
		case STATE_ATTACK:
		{
			// Start an effect
			Weapon_OnCreateEffect(client, weapon, "Start");
		
			// Play sound
			ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);

			// Substract ammo
			iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 
		
			// Sets attack animation
			ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT1, ANIM_SHOOT2 });   
		
			// Adds the delay to the game tick
			flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
			
			// Sets next attack time
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);         

			// Sets shots count
			SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);

			// Gets weapon muzzle
			static char sName[NORMAL_LINE_LENGTH];
			ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
			UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sName, 0.1);

			// Initialize variables
			static float vVelocity[3]; int iFlags = GetEntityFlags(client); 
			float flSpread = 0.01; float flInaccuracy = 0.013;
			float vKickback[] = { /*upBase = */0.5, /* lateralBase = */1.1, /* upMod = */0.15, /* lateralMod = */0.05, /* upMax = */1.1, /* lateralMax = */1.45, /* directionChange = */5.0 };
			
			// Gets client velocity
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

			// Apply kick back
			if (GetVectorLength(vVelocity) <= 0.0)
			{
			}
			else if (!(iFlags & FL_ONGROUND))
			{
				for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 1.3;
				flInaccuracy = 0.02;
				flSpread = 0.05;
			}
			else if (iFlags & FL_DUCKING)
			{
				for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 0.75;
				flInaccuracy = 0.01;
			}
			else
			{
				for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 1.15;
			}
			ZP_CreateWeaponKickBack(client, vKickback[0], vKickback[1], vKickback[2], vKickback[3], vKickback[4], vKickback[5], RoundFloat(vKickback[6]));
			
			// Create a bullet
			Weapon_OnCreateBullet(client, weapon, 0, GetRandomInt(0, 1000), flSpread, flInaccuracy);
		}
	}
}

void Weapon_OnEndAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate mode
	if (iStateMode > STATE_BEGIN)
	{
		// Sets end animation
		ZP_SetWeaponAnimation(client, ANIM_ATTACK_END);        

		// Sets begin state
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);

		// Adds the delay to the game tick
		flCurrentTime += WEAPON_ATTACK_END_TIME;
		
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
		
		// Stop an effect
		Weapon_OnCreateEffect(client, weapon, "Stop");
	}
}

void Weapon_OnCreateBullet(int client, int weapon, int iMode, int iSeed, float flSpread, float flInaccuracy)
{
	//#pragma unused client, weapon, iMode, iSeed, flSpread, flInaccuracy
	
	// Initialize vectors
	static float vPosition[3]; static float vAngle[3];

	// Gets weapon position
	ZP_GetPlayerGunPosition(client, 30.0, 0.0, 0.0, vPosition);

	// Gets client eye angle
	GetClientEyeAngles(client, vAngle);

	// Emulate bullet shot
	ZP_FireBullets(client, weapon, vPosition, vAngle, iMode, iSeed, flInaccuracy, flSpread, 0.0, 0, GetEntPropFloat(weapon, Prop_Send, "m_flRecoilIndex"));
}

void Weapon_OnCreateEffect(int client, int weapon, char[] sInput = "")
{
	//#pragma unused client, weapon, sInput

	// Gets effect index
	int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity");
	
	// Is effect should be created ?
	if (!hasLength(sInput))
	{
		// Validate entity 
		if (entity != -1)
		{
			return;
		}

		// Creates a muzzle
		entity = UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "2", "weapon_shell_casing_minigun", 9999.9);
		
		// Validate entity 
		if (entity != -1)
		{
			// Sets effect index
			SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
			
			// Stop an effect
			AcceptEntityInput(entity, "Stop"); 
		}
	}
	else
	{
		// Validate entity 
		if (entity != -1)
		{
			// Toggle state
			AcceptEntityInput(entity, sInput); 
		}
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
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);
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
 * @brief Called on drop of a weapon.
 *
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDrop(int weapon, int weaponID)
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Call event
		_call.Drop(-1, weapon);
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
				_call.Reload(client, weapon);
				iButtons &= (~IN_RELOAD); //! Bugfix
				return Plugin_Changed;
			}
		}

		// Button primary attack press
		if (iButtons & IN_ATTACK)
		{
			// Call event
			_call.PrimaryAttack(client, weapon);
			return Plugin_Changed;
		}
		// Button primary attack release
		else if (iLastButtons & IN_ATTACK)
		{
			// Call event
			_call.EndAttack(client, weapon);
		}
		
		// Call event
		_call.Idle(client, weapon);
	}
	
	// Allow button
	return Plugin_Continue;
}
