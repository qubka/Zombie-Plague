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
	name            = "[ZP] Weapon: Ethereal",
	author          = "qubka (Nikita Ushakov), nuclear silo",
	description     = "Addon of custom weapon",
	version         = "1.1",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME                10.0
#define WEAPON_ATTACK_TIME              1.0
#define WEAPON_TRACER_ENABLED
#define WEAPON_TRACER_LIFE              0.2
#define WEAPON_TRACER_WIDTH             0.2
#define WEAPON_TRACER_COLOR             {0, 255, 255, 255}
/**
 * @endsection
 **/

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSoundAttack; int gSoundIdle;
#pragma unused gSoundAttack, gSoundIdle

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_RELOAD,
	ANIM_DRAW
};

// Decal index
int gBeam = -1;

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	// Validate library
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		// Load translations phrases used by plugin
		LoadTranslations("etherial.phrases");

		// If map loaded, then run custom forward
		if (ZP_IsMapLoaded())
		{
			// Execute it
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	// Models
	gBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	// Weapons
	gWeapon = ZP_GetWeaponNameID("etherial");
	if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"etherial\" wasn't find");
	
	// Sounds
	gSoundAttack = ZP_GetSoundKeyID("ETHERIAL_SHOOT_SOUNDS");
	if (gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"ETHERIAL_SHOOT_SOUNDS\" wasn't find");
	gSoundIdle = ZP_GetSoundKeyID("ETHERIAL_IDLE_SOUNDS");
	if (gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"ETHERIAL_IDLE_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, flCurrentTime

	// Cancel reload
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0); 
	
	// Stop sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, flCurrentTime

	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

	// Sets draw animation
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 

	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, flCurrentTime

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

	// Stop sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	
	// Remove the delay to the game tick
	flCurrentTime -= 0.5;
	
	// Sets reloading time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, flCurrentTime
	
	// Gets new amount
	int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

	// Sets ammunition
	SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

	// Sets reload time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, flCurrentTime

	// Validate clip
	if (iClip <= 0)
	{
		// Validate ammo
		if (iAmmo)
		{
			Weapon_OnReload(client, weapon, iClip, iAmmo, flCurrentTime);
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

	// Play sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_HOME);
	
	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, flCurrentTime

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Validate clip
	if (iClip <= 0)
	{
		// Emit empty sound
		ClientCommand(client, "play weapons/clipempty_rifle.wav");
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
		return;
	}

	// Substract ammo
	iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 

	// Sets attack animation
	ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT1, ANIM_SHOOT2 });   

	// Play sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	ZP_EmitSoundToAll(gSoundAttack, 1, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
	
	// Sets attack animation
	ZP_SetPlayerAnimation(client, AnimType_FirePrimary);

	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponShoot(gWeapon));       

	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
	
	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);

	// Sets weapon muzzle
	static char sName[NORMAL_LINE_LENGTH];
	ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
	UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sName, 0.1);
	
	// Initialize variables
	static float vVelocity[3]; int iFlags = GetEntityFlags(client); 
	float flSpread = 0.01; float flInaccuracy = 0.013;
	float vKickback[] = { /*upBase = */0.1, /* lateralBase = */0.4, /* upMod = */0.10, /* lateralMod = */0.02, /* upMax = */1.5, /* lateralMax = */1.5, /* directionChange = */5.0 };
	
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

	// Create a fire
	Weapon_OnCreateBeam(client, weapon);
}

void Weapon_OnCreateBeam(int client, int weapon)
{
	//#pragma unused client, weapon

	// Initialize vectors
	static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

	// Gets client position
	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngle);

	// Emulate bullet shot
	ZP_FireBullets(client, weapon, vPosition, vAngle, 0, GetRandomInt(0, 1000), 0.0, 0.0, 0.0, 0, 0.0);
	
	// Create the end-point trace
	TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, SelfFilter, client);

	// Returns the collision position of a trace result
	TR_GetEndPosition(vEndPosition);

	// Gets weapon position
	ZP_GetPlayerEyePosition(client, 30.0, 10.0, -5.0, vPosition);

	// Gets beam lifetime
	//float flLife = ZP_GetWeaponShoot(gWeapon);

	// Sent a beam
	TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, 0, 0, 0, WEAPON_TRACER_LIFE, WEAPON_TRACER_WIDTH, WEAPON_TRACER_WIDTH, 1, 0.0, WEAPON_TRACER_COLOR, 0);
	TE_SendToClient(client);

	// Gets worldmodel index
	int world = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");

	// Validate entity
	if (world != -1)
	{
		// Gets attachment position
		ZP_GetAttachment(world, "muzzle_flash", vPosition, vAngle);
		
		// Sent a beam
		TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, 0, 0, 0, WEAPON_TRACER_LIFE, WEAPON_TRACER_WIDTH, WEAPON_TRACER_WIDTH, 1, 0.0, WEAPON_TRACER_COLOR, 0);
		int[] iClients = new int[MaxClients]; int iCount;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPlayerExist(i, false) || i == client || IsFakeClient(i)) continue;
			iClients[iCount++] = i;
		}
		TE_Send(iClients, iCount);
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
			iButtons &= (~IN_ATTACK); //! Bugfix
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
