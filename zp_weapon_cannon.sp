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
	name            = "[ZP] Weapon: Cannon",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME   1.66
#define WEAPON_ATTACK_TIME 5.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_DRAW,
	ANIM_SHOOT2
};

// Item index
int gWeapon;

// Sound index
int gSound;

// Cvars
ConVar hCvarCannonSpeed;
ConVar hCvarCannonDamage;
ConVar hCvarCannonRadius;
ConVar hCvarCannonLife;
ConVar hCvarCannonIgnite;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	hCvarCannonSpeed  = CreateConVar("zp_weapon_cannon_speed", "1000.0", "Projectile speed", 0, true, 0.0);  
	hCvarCannonDamage = CreateConVar("zp_weapon_cannon_damage", "400.0", "Projectile damage", 0, true, 0.0); 
	hCvarCannonRadius = CreateConVar("zp_weapon_cannon_radius", "200.0", "Damage radius", 0, true, 0.0); 
	hCvarCannonLife   = CreateConVar("zp_weapon_cannon_life", "0.7", "Duration of life", 0, true, 0.0);   
	hCvarCannonIgnite = CreateConVar("zp_weapon_cannon_ignite", "3.0", "Duration of ignite", 0, true, 0.0);

	// Generate config
	AutoExecConfig(true, "zp_weapon_cannon", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("cannon");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"cannon\" wasn't find");

	// Sounds
	gSound = ZP_GetSoundKeyID("CANNON_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"CANNON_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int client, int weapon, int iAmmo, float flCurrentTime)
{
	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));

	// Create an effect
	Weapon_OnCreateEffect(weapon);
}

void Weapon_OnIdle(int client, int weapon, int iAmmo, float flCurrentTime)
{
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

void Weapon_OnHolster(int client, int weapon, int iAmmo, float flCurrentTime)
{
	// Stop an effect
	Weapon_OnCreateEffect(weapon, "Kill");
}

void Weapon_OnDrop(int client, int weapon, int iAmmo, float flCurrentTime)
{
	
	// Kill an effect
	Weapon_OnCreateEffect(weapon, "Kill");
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iAmmo, float flCurrentTime)
{
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Validate ammo
	if (iAmmo <= 0)
	{
		// Emit empty sound
		EmitSoundToClient(client, SOUND_CLIP_EMPTY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_ITEM);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
		return;
	}

	// Validate water
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return;
	}

	// Substract ammo
	iAmmo -= 1; SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo); 

	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponShoot(gWeapon));

	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
 
	// Play sound
	ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);
	
	// Sets attack animation
	ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT1, ANIM_SHOOT2 });
	ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
	
	// Initialize vector
	static float vPosition[5][3];

	// Gets weapon position
	ZP_GetPlayerEyePosition(client, 50.0, 60.0, -10.0,  vPosition[0]);
	ZP_GetPlayerEyePosition(client, 50.0, 30.0, -10.0,  vPosition[1]);
	ZP_GetPlayerEyePosition(client, 50.0, 0.0,  -10.0,  vPosition[2]);
	ZP_GetPlayerEyePosition(client, 50.0, -30.0, -10.0, vPosition[3]);
	ZP_GetPlayerEyePosition(client, 50.0, -60.0, -10.0, vPosition[4]);

	// i - fire index
	for (int i = 0; i < 5; i++)
	{
		// Create a fire
		Weapon_OnCreateFire(client, weapon, vPosition[i]);
	}

	// Initialize variables
	static float vVelocity[3]; int iFlags = GetEntityFlags(client);
	float vKickback[] = { /*upBase = */7.5, /* lateralBase = */4.45, /* upMod = */0.225, /* lateralMod = */0.05, /* upMax = */7.5, /* lateralMax = */4.5, /* directionChange = */7.0 };
	
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
	
	// Start an effect
	Weapon_OnCreateEffect(weapon, "Start");
	Weapon_OnCreateEffect(weapon, "FireUser2");
}

void Weapon_OnCreateFire(int client, int weapon, float vPosition[3])
{
	// Initialize vectors
	static float vAngle[3]; static float vVelocity[3]; static float vEndVelocity[3];

	// Gets client eye angle
	GetClientEyeAngles(client, vAngle);

	// Gets client velocity
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	// Create a rocket entity
	int entity = UTIL_CreateProjectile(vPosition, vAngle);

	// Validate entity
	if (entity != -1)
	{
		// Sets grenade model scale
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 10.0);
		
		// Returns vectors in the direction of an angle
		GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);

		// Normalize the vector (equal magnitude at varying distances)
		NormalizeVector(vEndVelocity, vEndVelocity);

		// Apply the magnitude by scaling the vector
		ScaleVector(vEndVelocity, hCvarCannonSpeed.FloatValue);

		// Adds two vectors
		AddVectors(vEndVelocity, vVelocity, vEndVelocity);

		// Push the fire
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);
		
		// Sets an entity color
		UTIL_SetRenderColor(entity, Color_Alpha, 0);
		AcceptEntityInput(entity, "DisableShadow"); /// Prevents the entity from receiving shadows
		
		// Sets parent for the entity
		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

		// Sets gravity
		SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01); 

		// Create touch hook
		SDKHook(entity, SDKHook_Touch, FireTouchHook);

		// Gets fire life
		float flDuration = hCvarCannonLife.FloatValue;

		// Create an effect
		UTIL_CreateParticle(entity, vPosition, _, _, "new_flame_core", flDuration);
		
		// Kill after some duration
		UTIL_RemoveEntity(entity, flDuration);
	}
}

void Weapon_OnCreateEffect(int weapon, char[] sInput = "")
{
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
		
		// Gets worldmodel index
		int world = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		
		// Validate model 
		if (world != -1)
		{
			// Gets weapon muzzleflesh
			static char sMuzzle[NORMAL_LINE_LENGTH];
			ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
	
			// Create an attach fire effect
			entity = UTIL_CreateParticle(world, _, _, "mag_eject", sMuzzle);
			
			// Validate entity 
			if (entity != -1)
			{
				// Sets effect index
				SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
				
				// Stop an effect
				AcceptEntityInput(entity, "Stop"); 
				
				// Initialize flags char
				static char sFlags[SMALL_LINE_LENGTH];
				FormatEx(sFlags, sizeof(sFlags), "OnUser2 !self:Stop::%f:-1", 0.5);
				
				// Sets modified flags on the entity
				SetVariantString(sFlags);
				AcceptEntityInput(entity, "AddOutput");
			}
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
		GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
								\
		GetGameTime()           \
	)    

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
		// Button secondary attack press
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

//**********************************************
//* Item (fire) hooks.                         *
//**********************************************

/**
 * @brief Fire touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action FireTouchHook(int entity, int target)
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

		// Validate client
		if (IsPlayerExist(target))
		{
			// Validate zombie
			if (ZP_IsPlayerZombie(target)) 
			{
				// Put the fire on
				UTIL_IgniteEntity(target, hCvarCannonIgnite.FloatValue);  
			}
		}

		// Gets entity position
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		// Create an explosion
		UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND, _, hCvarCannonDamage.FloatValue, hCvarCannonRadius.FloatValue, "cannon", thrower, entity);

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
