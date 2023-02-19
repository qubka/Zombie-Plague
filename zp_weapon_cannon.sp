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
	hCvarCannonSpeed  = CreateConVar("zp_weapon_cannon_speed", "1000.0", "Projectile speed", 0, true, 0.0);  
	hCvarCannonDamage = CreateConVar("zp_weapon_cannon_damage", "400.0", "Projectile damage", 0, true, 0.0); 
	hCvarCannonRadius = CreateConVar("zp_weapon_cannon_radius", "200.0", "Damage radius", 0, true, 0.0); 
	hCvarCannonLife   = CreateConVar("zp_weapon_cannon_life", "0.7", "Duration of life", 0, true, 0.0);   
	hCvarCannonIgnite = CreateConVar("zp_weapon_cannon_ignite", "5.0", "Duration of ignite", 0, true, 0.0);

	AutoExecConfig(true, "zp_weapon_cannon", "sourcemod/zombieplague");
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
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("cannon");

	gSound = ZP_GetSoundKeyID("CANNON_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"CANNON_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int client, int weapon, int iAmmo, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));

	Weapon_OnCreateEffect(weapon);
}

void Weapon_OnIdle(int client, int weapon, int iAmmo, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnHolster(int client, int weapon, int iAmmo, float flCurrentTime)
{
	Weapon_OnCreateEffect(weapon, "Kill");
}

void Weapon_OnDrop(int client, int weapon, int iAmmo, float flCurrentTime)
{
	Weapon_OnCreateEffect(weapon, "Kill");
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iAmmo, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	if (iAmmo <= 0)
	{
		EmitSoundToClient(client, SOUND_CLIP_EMPTY, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
		return;
	}

	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return;
	}

	iAmmo -= 1; SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo); 

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponShoot(gWeapon));

	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
 
	ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON);
	
	ZP_SetViewAnimation(client, { ANIM_SHOOT1, ANIM_SHOOT2 });
	ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
	
	static float vPosition[5][3];

	ZP_GetPlayerEyePosition(client, 50.0, 60.0, -10.0,  vPosition[0]);
	ZP_GetPlayerEyePosition(client, 50.0, 30.0, -10.0,  vPosition[1]);
	ZP_GetPlayerEyePosition(client, 50.0, 0.0,  -10.0,  vPosition[2]);
	ZP_GetPlayerEyePosition(client, 50.0, -30.0, -10.0, vPosition[3]);
	ZP_GetPlayerEyePosition(client, 50.0, -60.0, -10.0, vPosition[4]);

	for (int i = 0; i < 5; i++)
	{
		Weapon_OnCreateFire(client, weapon, vPosition[i]);
	}

	static float vVelocity[3]; int iFlags = GetEntityFlags(client);
	float vKickback[] = { /*upBase = */7.5, /* lateralBase = */4.45, /* upMod = */0.225, /* lateralMod = */0.05, /* upMax = */7.5, /* lateralMax = */4.5, /* directionChange = */7.0 };
	
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
	
	Weapon_OnCreateEffect(weapon, "Start");
	Weapon_OnCreateEffect(weapon, "FireUser2");
}

void Weapon_OnCreateFire(int client, int weapon, float vPosition[3])
{
	static float vAngle[3]; static float vVelocity[3]; static float vEndVelocity[3];

	GetClientEyeAngles(client, vAngle);

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	int entity = UTIL_CreateProjectile(vPosition, vAngle, gWeapon);

	if (entity != -1)
	{
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 10.0);
		
		GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);

		NormalizeVector(vEndVelocity, vEndVelocity);

		ScaleVector(vEndVelocity, hCvarCannonSpeed.FloatValue);

		AddVectors(vEndVelocity, vVelocity, vEndVelocity);

		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);

		AcceptEntityInput(entity, "DisableDraw"); 
		AcceptEntityInput(entity, "DisableShadow"); 
		
		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

		SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01); 

		SDKHook(entity, SDKHook_Touch, FireTouchHook);

		float flDuration = hCvarCannonLife.FloatValue;

		UTIL_CreateParticle(entity, vPosition, _, _, "new_flame_core", flDuration);
		
		UTIL_RemoveEntity(entity, flDuration);
	}
}

void Weapon_OnCreateEffect(int weapon, char[] sInput = "")
{
	int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity");
	
	if (!hasLength(sInput))
	{
		if (entity != -1)
		{
			return;
		}
		
		int world = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		
		if (world != -1)
		{
			static char sMuzzle[NORMAL_LINE_LENGTH];
			ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
	
			entity = UTIL_CreateParticle(world, _, _, "mag_eject", sMuzzle);
			
			if (entity != -1)
			{
				SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
				
				AcceptEntityInput(entity, "Stop"); 
				
				static char sFlags[SMALL_LINE_LENGTH];
				FormatEx(sFlags, sizeof(sFlags), "OnUser2 !self:Stop::%f:-1", 0.5);
				
				SetVariantString(sFlags);
				AcceptEntityInput(entity, "AddOutput");
			}
		}
	}
	else
	{
		if (entity != -1)
		{
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
 * @brief Called on drop of a weapon.
 *
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDrop(int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
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
	if (weaponID == gWeapon)
	{
		if (iButtons & IN_ATTACK)
		{
			_call.PrimaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK); //! Bugfix
			return Plugin_Changed;
		}
		
		_call.Idle(client, weapon);
	}
	
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
	if (IsValidEdict(target))
	{
		int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");

		if (thrower == target)
		{
			return Plugin_Continue;
		}

		if (IsPlayerExist(target))
		{
			if (ZP_IsPlayerZombie(target)) 
			{
				UTIL_IgniteEntity(target, hCvarCannonIgnite.FloatValue);  
			}
		}

		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND, _, hCvarCannonDamage.FloatValue, hCvarCannonRadius.FloatValue, "cannon", thrower, entity);

		AcceptEntityInput(entity, "Kill");
	}

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
	if (weaponID == gWeapon)
	{
		return Plugin_Stop; 
	}
	
	return Plugin_Continue;
}
