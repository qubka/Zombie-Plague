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
	name            = "[ZP] Weapon: Janus VII",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_SIGNAL_COUNTER       100
#define WEAPON_ACTIVE_COUNTER       150
#define WEAPON_BEAM_DAMAGE          50.0
#define WEAPON_BEAM_RADIUS          500.0
#define WEAPON_BEAM_SHAKE_AMP       10.0
#define WEAPON_BEAM_SHAKE_FREQUENCY 1.0
#define WEAPON_BEAM_SHAKE_DURATION  2.0
#define WEAPON_IDLE_TIME            3.0
#define WEAPON_SWITCH_TIME          2.0
#define WEAPON_SWITCH2_TIME         1.66
#define WEAPON_ATTACK_TIME          1.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_SIGNAL_1,
	ANIM_CHANGE,
	ANIM_IDLE2,
	ANIM_DRAW2,
	ANIM_SHOOT2_1,
	ANIM_SHOOT2_2,
	ANIM_CHANGE2,
	ANIM_IDLE_SIGNAL,
	ANIM_RELOAD_SIGNAL,
	ANIM_DRAW_SIGNAL,
	ANIM_SHOOT_SIGNAL_2
};

// Weapon states
enum
{
	STATE_NORMAL,
	STATE_SIGNAL,
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
		// Load translations phrases used by plugin
		LoadTranslations("zombieplague.phrases");
		
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
	gWeapon = ZP_GetWeaponNameID("janus7");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"janus7\" wasn't find");

	// Sounds
	gSound = ZP_GetSoundKeyID("JANUSVII_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JANUSVII_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
	
	// Kill an effect
	Weapon_OnCreateEffect(client, weapon, "Kill");
	
	// Cancel mode change
	SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);
	
	// Cancel reload
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime

	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	
	// Create an effect
	Weapon_OnCreateEffect(client, weapon);
	
	// Validate mode
	if (iStateMode == STATE_ACTIVE)
	{
		// Start an effect
		Weapon_OnCreateEffect(client, weapon, "Start");
	}
	
	// Sets draw animation
	ZP_SetWeaponAnimation(client, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW2 : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW); 

	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnDrop(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
	
	// Kill an effect
	Weapon_OnCreateEffect(client, weapon, "Kill");
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
	
	// Validate mode
	if (iStateMode == STATE_ACTIVE)
	{
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
	ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_RELOAD : ANIM_RELOAD_SIGNAL); 
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

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
	
	// Gets new amount
	int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

	// Sets ammunition
	SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

	// Sets reload time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime

	// Validate mode
	if (iStateMode != STATE_ACTIVE)
	{
		// Validate clip
		if (iClip <= 0)
		{
			// Validate ammo
			if (iAmmo)
			{
				Weapon_OnReload(client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime);
				return; /// Execute fake reload
			}
		}
	}
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}

	// Sets idle animation
	ZP_SetWeaponAnimation(client, (iStateMode == STATE_ACTIVE) ? ANIM_IDLE2 : (iStateMode == STATE_SIGNAL) ? ANIM_IDLE_SIGNAL : ANIM_IDLE); 

	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Validate mode
	if (iStateMode == STATE_ACTIVE)
	{
		// Validate counter
		if (iCounter > WEAPON_ACTIVE_COUNTER)
		{
			Weapon_OnFinish(client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime);
			return;
		}
		
		// Validate water
		if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
		{
			return;
		}
		
		// Play sound
		ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
		
		// Sets attack animation
		ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT2_1, ANIM_SHOOT2_2});

		// Create a beam
		Weapon_OnCreateBeam(client, weapon);
	}
	else
	{
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
		
		// Validate counter
		if (iCounter > WEAPON_SIGNAL_COUNTER)
		{
			// Sets signal mode
			SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_SIGNAL);

			// Sets shots count
			iCounter = -1;
			
			// Play sound
			ZP_EmitSoundToAll(gSound, 3, client, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
			
			// Show message
			SetGlobalTransTarget(client);
			PrintHintText(client, "%t", "janus activated");
		}
		
		// Sets attack animation
		ZP_SetWeaponAnimationPair(client, weapon, (iStateMode == STATE_SIGNAL) ? { ANIM_SHOOT_SIGNAL_1, ANIM_SHOOT_SIGNAL_2 } : { ANIM_SHOOT1, ANIM_SHOOT2 });   

		// Play sound
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);    
	
		// Sets shots count
		SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);

		// Initiliaze name char
		static char sName[NORMAL_LINE_LENGTH];
		
		// Gets viewmodel index
		int view = ZP_GetClientViewModel(client, true);
		
		// Gets weapon muzzle
		ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
		UTIL_CreateParticle(view, _, _, "1", sName, 0.1);
		
		// Gets weapon shell
		ZP_GetWeaponModelShell(gWeapon, sName, sizeof(sName));
		UTIL_CreateParticle(view, _, _, "2", sName, 0.1);
		
		// Initialize variables
		static float vVelocity[3]; int iFlags = GetEntityFlags(client); 
		float flSpread = 0.01; float flInaccuracy = 0.015;
		float vKickback[] = { /*upBase = */0.96, /* lateralBase = */1.1, /* upMod = */0.06, /* lateralMod = */0.05, /* upMax = */1.25, /* lateralMax = */2.5, /* directionChange = */6.0 };
		
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
	
	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME); 
	
	// Sets attack animation
	///ZP_SetPlayerAnimation(client, AnimType_FirePrimary);;

	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponSpeed(gWeapon));    

	// Sets shots count
	SetEntProp(weapon, Prop_Data, "m_iHealth", iCounter + 1);
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
	
	// Validate mode
	if (iStateMode == STATE_SIGNAL)
	{
		// Validate animation delay
		if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
		{
			return;
		}

		// Sets change animation
		ZP_SetWeaponAnimation(client, ANIM_CHANGE);        

		// Sets active state
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_ACTIVE);
		
		// Sets shots count
		SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
		
		// Adds the delay to the game tick
		flCurrentTime += WEAPON_SWITCH_TIME;
		
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
		
		// Remove the delay to the game tick
		flCurrentTime -= 0.5;

		// Sets switching time
		SetEntPropFloat(weapon, Prop_Send, "m_flUseLookAtAngle", flCurrentTime);
		
		// Start an effect
		Weapon_OnCreateEffect(client, weapon, "Start");
	}
}

void Weapon_OnFinish(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	//#pragma unused client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
	
	// Sets change animation
	ZP_SetWeaponAnimation(client, ANIM_CHANGE2);        

	// Sets active state
	SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_NORMAL);
	
	// Sets shots count
	SetEntProp(weapon, Prop_Data, "m_iHealth", 0);

	// Adds the delay to the game tick
	flCurrentTime += WEAPON_SWITCH2_TIME;
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
	
	// Stop an effect
	Weapon_OnCreateEffect(client, weapon, "Stop");
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

void Weapon_OnCreateBeam(int client, int weapon)
{
	//#pragma unused client, weapon
	
	// Initialize variables
	static float vPosition[3]; static float vAngle[3]; static float vEnemy[3]; bool bFound;

	// Gets weapon position
	ZP_GetPlayerGunPosition(client, 30.0, 10.0, -10.0, vPosition);

	// Find any players in the radius
	int i; int it = 1; /// iterator
	while ((i = ZP_FindPlayerInSphere(it, vPosition, WEAPON_BEAM_RADIUS)) != -1)
	{
		// Skip humans
		if (ZP_IsPlayerHuman(i))
		{
			continue;
		}

		// Gets victim center
		GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy); vEnemy[2] += 45.0;

		// Validate visibility
		if (!UTIL_TraceRay(client, i, vPosition, vEnemy, SelfFilter))
		{
			continue;
		}

		// Create the damage for victims
		ZP_TakeDamage(i, client, weapon, WEAPON_BEAM_DAMAGE, DMG_NEVERGIB, weapon);
		
		// Create a shake
		UTIL_CreateShakeScreen(i, WEAPON_BEAM_SHAKE_AMP, WEAPON_BEAM_SHAKE_FREQUENCY, WEAPON_BEAM_SHAKE_DURATION);
		
		// Sets found state
		bFound = true; 
		break;
	}
	
	// Found the aim origin
	if (!bFound)
	{
		// Gets client eye angle
		GetClientEyeAngles(client, vAngle);

		// Calculate aim end-vector
		TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, SelfFilter, client);
		TR_GetEndPosition(vEnemy);
	}

	// Sent a beam
	ZP_CreateWeaponTracer(client, weapon, "1", "muzzle_flash", "medicgun_beam_red_invun", vEnemy, ZP_GetWeaponSpeed(gWeapon));
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
		entity = UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", "medicgun_invulnstatus_fullcharge_red", 9999.9);
			
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
		GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
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
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_NORMAL);
		SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
		SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);
		SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
	}
}

/**
 * @brief Called on bullet of a weapon.
 *
 * @param client            The client index.
 * @param vBullet           The position of a bullet hit.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponBullet(int client, float vBullet[3], int weapon, int weaponID)
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Sent a tracer
		ZP_CreateWeaponTracer(client, weapon, "1", "muzzle_flash", "weapon_tracers_mach", vBullet, ZP_GetWeaponSpeed(gWeapon));
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
		// Time to apply new mode
		static float flApplyModeTime;
		if ((flApplyModeTime = GetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle")) && flApplyModeTime <= GetGameTime())
		{
			// Sets switching time
			SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);

			// Sets different mode
			SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_ACTIVE);
		}
		
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
