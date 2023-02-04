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
	name            = "[ZP] Weapon: M32",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME         2.0
#define WEAPON_ATTACK_TIME       1.0
#define WEAPON_INSERT_TIME       0.86
#define WEAPON_INSERT_START_TIME 0.7
#define WEAPON_INSERT_END_TIME   0.63
/**
 * @endsection
 **/

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_START_INSERT,
	ANIM_DRAW,
	ANIM_INSERT1,
	ANIM_INSERT2,
	ANIM_FINISH_INSERT
};

// Reload states
enum
{
	RELOAD_START,
	RELOAD_INSERT,
	RELOAD_END
};

// Decal index
int gTrail;

// Item index
int gWeapon;

// Sound index
int gSound;

// Cvars
ConVar hCvarM32Speed;
ConVar hCvarM32Damage;
ConVar hCvarM32Radius;
ConVar hCvarM32Gravity;
ConVar hCvarM32Trail;
ConVar hCvarM32Exp;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	hCvarM32Speed   = CreateConVar("zp_weapon_m32_speed", "1500.0", "Projectile speed", 0, true, 0.0);
	hCvarM32Damage  = CreateConVar("zp_weapon_m32_damage", "150.0", "Projectile damage", 0, true, 0.0);
	hCvarM32Radius  = CreateConVar("zp_weapon_m32_radius", "300.0", "Damage radius", 0, true, 0.0);
	hCvarM32Gravity = CreateConVar("zp_weapon_m32_gravity", "1.5", "Projectile gravity", 0, true, 0.0);
	hCvarM32Trail   = CreateConVar("zp_weapon_m32_trail", "critical_rocket_red", "Particle effect for the trail (''-default)");
	hCvarM32Exp     = CreateConVar("zp_weapon_m32_explosion", "", "Particle effect for the explosion (''-default)");

	// Generate config
	AutoExecConfig(true, "zp_weapon_m32", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("m32");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"m32\" wasn't find");

	// Sounds
	gSound = ZP_GetSoundKeyID("M32_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"M32_SHOOT_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Models
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheModel("materials/sprites/xfireball3.vmt", true); /// for env_explosion
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnThink(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
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
			Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime);
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
			ZP_SetWeaponAnimationPair(client, weapon, { ANIM_INSERT1, ANIM_INSERT2 });
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

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
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
				Weapon_OnReload(client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime);
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
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
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
		ZP_SetWeaponAnimation(client, ANIM_START_INSERT); 
		ZP_SetPlayerAnimation(client, AnimType_ReloadStart);
		
		// Adds the delay to the game tick
		flCurrentTime += WEAPON_INSERT_START_TIME;
		
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

		// Sets new reload state
		SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
		
		// Sets default FOV for the client
		SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
	}
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
	// Sets end animation
	ZP_SetWeaponAnimation(client, ANIM_FINISH_INSERT);        
	ZP_SetPlayerAnimation(client, AnimType_ReloadEnd);
	
	// Adds the delay to the game tick
	flCurrentTime += WEAPON_INSERT_END_TIME;
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Stop reload
	SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
	// Sets draw animation
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	// Cancel reload
	SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
	
	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
	// Validate mode
	if (iReloadMode > RELOAD_START)
	{
		Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime);
		return;
	}
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Validate clip
	if (iClip <= 0)
	{
		// Emit empty sound
		EmitSoundToClient(client, "*/weapons/clipempty_rifle.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
		return;
	}
	
	// Validate water
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return;
	}

	// Substract ammo
	iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 

	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponShoot(gWeapon));    

	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	
	// Play sound
	ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
	
	// Sets attack animation
	ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT1, ANIM_SHOOT2 });
	ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
	
	// Create a grenade
	Weapon_OnCreateGrenade(client);

	// Initialize variables
	static float vVelocity[3]; int iFlags = GetEntityFlags(client);
	float vKickback[] = { /*upBase = */4.5, /* lateralBase = */2.5, /* upMod = */0.125, /* lateralMod = */0.05, /* upMax = */7.5, /* lateralMax = */3.5, /* directionChange = */7.0 };

	// Gets client velocity
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	// Apply kick back
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

	// Gets weapon muzzleflesh
	static char sMuzzle[NORMAL_LINE_LENGTH];
	ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));

	// Creates a muzzle
	UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sMuzzle, 0.1);
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
	// Validate mode
	if (iReloadMode > RELOAD_START)
	{
		Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime);
		return;
	}
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.3);
	
	// Sets FOV for the client
	int iDefaultFOV = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
	SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iFOV") == iDefaultFOV ? 55 : iDefaultFOV);
}

void Weapon_OnCreateGrenade(int client)
{
	// Initialize vectors
	static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vSpeed[3];

	// Gets weapon position
	ZP_GetPlayerEyePosition(client, 30.0, 10.0, 0.0, vPosition);

	// Gets client eye angle
	GetClientEyeAngles(client, vAngle);

	// Gets client velocity
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	// Create a rocket entity
	int entity = UTIL_CreateProjectile(vPosition, vAngle, "models/weapons/cso/m32/w_m32_projectile.mdl");

	// Validate entity
	if (entity != -1)
	{
		// Returns vectors in the direction of an angle
		GetAngleVectors(vAngle, vSpeed, NULL_VECTOR, NULL_VECTOR);

		// Normalize the vector (equal magnitude at varying distances)
		NormalizeVector(vSpeed, vSpeed);

		// Apply the magnitude by scaling the vector
		ScaleVector(vSpeed, hCvarM32Speed.FloatValue);

		// Adds two vectors
		AddVectors(vSpeed, vVelocity, vSpeed);

		// Push the rocket
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vSpeed);

		// Sets parent for the entity
		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

		// Sets gravity
		SetEntPropFloat(entity, Prop_Data, "m_flGravity", hCvarM32Gravity.FloatValue); 

		// Create touch hook
		SDKHook(entity, SDKHook_Touch, GrenadeTouchHook);
		
		// Gets particle name
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarM32Trail.GetString(sEffect, sizeof(sEffect));

		// Validate effect
		if (hasLength(sEffect))
		{
			// Create an effect
			UTIL_CreateParticle(entity, vPosition, _, _, sEffect, 5.0);
		}
		else
		{
			// Attach beam follow
			TE_SetupBeamFollow(entity, gTrail, 0, 1.0, 4.0, 4.0, 2, {230, 224, 212, 200});
			TE_SendToAll();	
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
		SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
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

//**********************************************
//* Item (grenade) hooks.                       *
//**********************************************

/**
 * @brief Grenade touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action GrenadeTouchHook(int entity, int target)
{
	// Validate target
	if (IsValidEdict(target))
	{
		// Gets thrower index
		int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");

		// Validate thrower
		if (thrower == target)
		{
			// Return on the unsuccess
			return Plugin_Continue;
		}

		// Gets entity position
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		// Gets particle name
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarM32Exp.GetString(sEffect, sizeof(sEffect));

		// Initialze exp flag
		int iFlags = EXP_NOSOUND;

		// Validate effect
		if (hasLength(sEffect))
		{
			// Create an explosion effect
			UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
			iFlags |= EXP_NOFIREBALL; /// remove effect sprite
		}
		
		// Create an explosion
		UTIL_CreateExplosion(vPosition, iFlags, _, hCvarM32Damage.FloatValue, hCvarM32Radius.FloatValue, "m32", thrower, entity);

		// Play sound
		ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, SNDLEVEL_NORMAL);

		// Remove the entity from the world
		AcceptEntityInput(entity, "Kill");
	}

	// Return on the success
	return Plugin_Continue;
}

/**
 * @brief Called before a grenade sound is emitted.
 *
 * @param grenade           The grenade index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow sounds. Anything else
 *                              (like Plugin_Stop) to block sounds.
 **/
public Action ZP_OnGrenadeSound(int grenade, int weaponID)
{
	// Validate custom grenade
	if (weaponID == gWeapon)
	{
		// Block sounds
		return Plugin_Stop; 
	}
	
	// Allow sounds
	return Plugin_Continue;
}
