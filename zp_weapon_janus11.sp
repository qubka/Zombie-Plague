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
	name            = "[ZP] Weapon: Janus XI",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME         1.66
#define WEAPON_SWITCH_TIME       1.66
#define WEAPON_SWITCH2_TIME      1.66
#define WEAPON_ATTACK_TIME       0.3
#define WEAPON_ATTACK2_TIME      1.0
#define WEAPON_INSERT_TIME       0.43
#define WEAPON_INSERT_START_TIME 0.5
#define WEAPON_INSERT_END_TIME   0.86
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_START_RELOAD,
	ANIM_SHOOT2,
	ANIM_AFTER_RELOAD,
	ANIM_DRAW,
	ANIM_IDLE_SIGNAL,
	ANIM_SHOOT_SIGNAL_1,
	ANIM_START_RELOAD_SIGNAL,
	ANIM_INSERT1,
	ANIM_AFTER_RELOAD_SIGNAL,
	ANIM_DRAW_SIGNAL,
	ANIM_IDLE2,
	ANIM_SHOOT2_1,
	ANIM_DRAW2,
	ANIM_CHANGE,
	ANIM_CHANGE2,
	ANIM_INSERT2,
	ANIM_SHOOT_SIGNAL_2,
	ANIM_INSERT_SIGNAL_1,
	ANIM_INSERT_SIGNAL_2,
	ANIM_SHOOT2_2
};

// Weapon states
enum
{
	STATE_NORMAL,
	STATE_SIGNAL,
	STATE_ACTIVE
};

// Reload states
enum
{
	RELOAD_START,
	RELOAD_INSERT,
	RELOAD_END
};

// Weapon index
int gWeapon;

// Sound index
int gSound;

// Cvars
ConVar hCvarJanusSignalCounter;
ConVar hCvarJanusActiveCounter;
ConVar hCvarJanusActiveMultiplier;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	hCvarJanusSignalCounter    = CreateConVar("zp_weapon_janus11_signal_counter", "10", "Amount of shots to activate second mode", 0, true, 0.0);
	hCvarJanusActiveCounter    = CreateConVar("zp_weapon_janus11_active_counter", "10", "Amount of shots in the second mode", 0, true, 0.0);
	hCvarJanusActiveMultiplier = CreateConVar("zp_weapon_janus11_active_multiplier", "2.0", "Multiplier on the active state", 0, true, 0.0);
	
	// Generate config
	AutoExecConfig(true, "zp_weapon_janus11", "sourcemod/zombieplague");
}

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
		LoadTranslations("janus.phrases");
		
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
	gWeapon = ZP_GetWeaponNameID("janus11");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"janus11\" wasn't find");

	// Sounds
	gSound = ZP_GetSoundKeyID("JANUSXI_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JANUSXI_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnThink(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	/// HACK~HACK apply on each frame for shotguns
	
	// Validate clip/ammo
	if (iClip == ZP_GetWeaponClip(gWeapon) || iAmmo <= 0)
	{
		// Validate mode
		if (iReloadMode == RELOAD_END)
		{
			Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
			return;
		}
	}

	// Switch mode
	switch (iReloadMode)
	{
		case RELOAD_INSERT :
		{        
			// Validate animation delay
			if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
			{
				return;
			}

			// Sets reload animation
			ZP_SetWeaponAnimationPair(client, weapon, !iStateMode ? { ANIM_INSERT1, ANIM_INSERT2 } : { ANIM_INSERT_SIGNAL_1, ANIM_INSERT_SIGNAL_2 });
			ZP_SetPlayerAnimation(client, AnimType_ReloadLoop);
			
			// Adds the delay to the game tick
			flCurrentTime += WEAPON_INSERT_TIME;
			
			// Sets next attack time
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

			// Sets new reload state
			SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_END);
		}
		
		case RELOAD_END :
		{
			// Sets ammunition
			SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + 1);
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - 1);
			
			// Sets new reload state
			SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
		}
	}
}

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
	// Cancel mode change
	SetEntPropFloat(weapon, Prop_Send, "m_flUseLookAtAngle", 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
	// Sets draw animation
	ZP_SetWeaponAnimation(client, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW2 : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW); 

	// Cancel reload
	SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
	
	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
	// Validate mode
	if (iReloadMode == RELOAD_START)
	{
		// Validate clip
		if (iClip <= 0)
		{
			// Validate ammo
			if (iAmmo)
			{
				Weapon_OnReload(client, weapon, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
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

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
	// Validate mode
	if (iReloadMode > RELOAD_START)
	{
		Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
		return;
	}
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Validate mode
	if (iStateMode == STATE_ACTIVE)
	{
		// Validate counter
		if (iCounter > hCvarJanusActiveCounter.IntValue)
		{
			Weapon_OnFinish(client, weapon, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
			return;
		}

		// Sets attack animation
		ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT2_1, ANIM_SHOOT2_2 });   

		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + (ZP_GetWeaponShoot(gWeapon) - WEAPON_ATTACK_TIME));       

		// Play sound
		ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
	}
	else
	{
		// Validate clip
		if (iClip <= 0)
		{
			// Emit empty sound
			EmitSoundToClient(client, "*/weapons/clipempty_rifle.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
			return;
		}
		
		// Substract ammo
		iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 
		
		// Validate counter
		if (iCounter > hCvarJanusSignalCounter.IntValue)
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

		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponShoot(gWeapon));       
		
		// Play sound
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
	}
	
	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK2_TIME);
	
	// Sets attack animation
	///ZP_SetPlayerAnimation(client, AnimType_FirePrimary);;
	
	// Sets shots count
	SetEntProp(weapon, Prop_Data, "m_iHealth", iCounter + 1);

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
	float flSpread = 0.1; float flInaccuracy = 0.03;
	float vKickback[] = { /*upBase = */1.5, /* lateralBase = */1.25, /* upMod = */0.15, /* lateralMod = */0.05, /* upMax = */4.5, /* lateralMax = */3.5, /* directionChange = */7.0 };

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

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
	// Validate mode
	if (iStateMode == STATE_SIGNAL)
	{
		// Validate mode
		if (iReloadMode > RELOAD_START)
		{
			Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
			return;
		}
	
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
		SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", flCurrentTime);
	}
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
	// Validate mode
	if (iStateMode == STATE_ACTIVE)
	{
		return;
	}
	
	// Validate ammo
	if (iAmmo <= 0)
	{
		return;
	}
	
	// Validate clip
	if (iClip >= ZP_GetWeaponClip(gWeapon))
	{
		return;
	}
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	// Validate mode
	if (iReloadMode == RELOAD_START)
	{
		// Sets start reload animation
		ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_START_RELOAD : ANIM_START_RELOAD_SIGNAL); 
		ZP_SetPlayerAnimation(client, AnimType_ReloadStart);
		
		// Adds the delay to the game tick
		flCurrentTime += WEAPON_INSERT_END_TIME;
		
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

		// Sets new reload state
		SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
	}
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
	// Sets end animation
	ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_AFTER_RELOAD : ANIM_AFTER_RELOAD_SIGNAL); 
	ZP_SetPlayerAnimation(client, AnimType_ReloadEnd);
	
	// Adds the delay to the game tick
	flCurrentTime += WEAPON_INSERT_START_TIME;
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Stop reload
	SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
}

void Weapon_OnFinish(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
	
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
}

void Weapon_OnCreateBullet(int client, int weapon, int iMode, int iSeed, float flSpread, float flInaccuracy)
{
	
	// Initialize vectors
	static float vPosition[3]; static float vAngle[3];

	// Gets client position
	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngle);

	// Emulate bullet shot
	ZP_FireBullets(client, weapon, vPosition, vAngle, iMode, iSeed, flInaccuracy, flSpread, 0.0, 0, GetEntPropFloat(weapon, Prop_Send, "m_flRecoilIndex"));
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
		GetEntProp(%2, Prop_Data, "m_iReloadHudHintCount"), \
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
		SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_NORMAL);
		SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
		SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);
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
		ZP_CreateWeaponTracer(client, weapon, "1", "muzzle_flash", "weapon_tracers_shot", vBullet, ZP_GetWeaponShoot(gWeapon));
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
		// Call event
		_call.Think(client, weapon);

		// Button reload press
		if (iButtons & IN_RELOAD)
		{
			// Call event
			_call.Reload(client, weapon);
			iButtons &= (~IN_RELOAD); //! Bugfix
			return Plugin_Changed;
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
 * @brief Called before a client take a fake damage.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index. (Not validated!)
 * @param inflicter         The inflicter index. (Not validated!)
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The ditfield of damage types.
 * @param weapon            The weapon index or -1 for unspecified.
 *
 * @note To block damage reset the damage to zero. 
 **/
public void ZP_OnClientValidateDamage(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &weapon)
{
	// Client was damaged by 'bullet'
	if (iBits & DMG_NEVERGIB)
	{
		// Validate weapon
		if (IsValidEdict(weapon))
		{
			// Validate custom weapon
			if (GetEntProp(weapon, Prop_Data, "m_iHammerID") == gWeapon)
			{
				// Add additional damage
				if (GetEntProp(weapon, Prop_Data, "m_iMaxHealth")) flDamage *= hCvarJanusActiveMultiplier.FloatValue;
			}
		}
	}
}
