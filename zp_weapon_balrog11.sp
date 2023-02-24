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
	name            = "[ZP] Weapon: Balrog XI",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_ATTACK_TIME 1.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT,
	ANIM_START_RELOAD,
	ANIM_INSERT,
	ANIM_AFTER_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_BSC1,
	ANIM_SHOOT_BSC2
};

// Decal index
int gTrail;

// Weapon index
int gWeapon;

// Sound index
int gSound;

// Cvars
ConVar hCvarBalrogDamage;
ConVar hCvarBalrogRadius;
ConVar hCvarBalrogSpeed;
ConVar hCvarBalrogCounter;
ConVar hCvarBalrogLife;
ConVar hCvarBalrogTrail;
ConVar hCvarBalrogExp;
ConVar hCvarBalrogIgnite;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarBalrogDamage  = CreateConVar("zp_weapon_balrog11_damage", "250.0", "Explosion damage", 0, true, 0.0);
	hCvarBalrogRadius  = CreateConVar("zp_weapon_balrog11_radius", "50.0", "Explosion radius", 0, true, 0.0);
	hCvarBalrogSpeed   = CreateConVar("zp_weapon_balrog11_speed", "1000.0", "Projectile speed", 0, true, 0.0);
	hCvarBalrogCounter = CreateConVar("zp_weapon_balrog11_counter", "4", "Amount of bullets shoot to gain 1 fire bullet", 0, true, 0.0);
	hCvarBalrogLife    = CreateConVar("zp_weapon_balrog11_life", "0.5", "Duration of life", 0, true, 0.0);
	hCvarBalrogTrail   = CreateConVar("zp_weapon_balrog11_trail", "flaregun_trail_crit_red", "Particle effect for the trail (''-default)");
	hCvarBalrogExp     = CreateConVar("zp_weapon_balrog11_explosion", "projectile_fireball_crit_red", "Particle effect for the explosion (''-default)");
	hCvarBalrogIgnite  = CreateConVar("zp_weapon_balrog11_ignite", "5.0", "Duration of ignite", 0, true, 0.0);

	AutoExecConfig(true, "zp_weapon_balrog11", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("balrog11");

	gSound = ZP_GetSoundKeyID("balrogxi2_shoot_sounds");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"balrogxi2_shoot_sounds\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheModel("materials/sprites/xfireball3.vmt", true); /// for env_explosion
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int client, int weapon, int iCounter, int iAmmo, float flCurrentTime)
{
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnShoot(int client, int weapon, int iCounter, int iAmmo, float flCurrentTime)
{
	if (!GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount"))
	{
		return;
	}
	
	if (iCounter > hCvarBalrogCounter.IntValue)
	{
		if (iAmmo < ZP_GetWeaponClip(gWeapon))
		{
			SetEntProp(weapon, Prop_Data, "m_iMaxHealth", iAmmo + 1);
		 
			ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_WEAPON);
			
			iCounter = -1;
		}
	}

	SetEntProp(weapon, Prop_Data, "m_iHealth", iCounter + 1);
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iCounter, int iAmmo, float flCurrentTime)
{
	int iAnim = ZP_GetWeaponAnimation(client);
	if (iAnim == ANIM_START_RELOAD || iAnim == ANIM_INSERT)
	{
		return;
	}
	
	if (iAmmo <= 0)
	{
		return;
	}

	if (GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack") > flCurrentTime)
	{
		return;
	}
	
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return;
	}

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
	
	flCurrentTime += ZP_GetWeaponShoot(gWeapon);
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);

	iAmmo -= 1; SetEntProp(weapon, Prop_Data, "m_iMaxHealth", iAmmo); 
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
 
	ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON);
	
	ZP_SetViewAnimation(client, { ANIM_SHOOT_BSC1, ANIM_SHOOT_BSC2 });
	
	static float vPosition[5][3];

	ZP_GetPlayerEyePosition(client, 50.0, 60.0, -10.0, vPosition[0]);
	ZP_GetPlayerEyePosition(client, 50.0, 30.0, -10.0, vPosition[1]);
	ZP_GetPlayerEyePosition(client, 50.0, 0.0, -10.0, vPosition[2]);
	ZP_GetPlayerEyePosition(client, 50.0, -30.0, -10.0, vPosition[3]);
	ZP_GetPlayerEyePosition(client, 50.0, -60.0, -10.0, vPosition[4]);

	for (int i = 0; i < 5; i++)
	{
		Weapon_OnCreateFire(client, weapon, vPosition[i]);
	}

	static float vVelocity[3]; int iFlags = GetEntityFlags(client);
	float vKickback[] = { /*upBase = */10.5, /* lateralBase = */7.45, /* upMod = */0.225, /* lateralMod = */0.05, /* upMax = */10.5, /* lateralMax = */7.5, /* directionChange = */7.0 };
	
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
	
	static char sName[NORMAL_LINE_LENGTH];
	
	int view = ZP_GetClientViewModel(client, true);
	
	ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
	UTIL_CreateParticle(view, _, _, "1", sName, 0.1);
	
	ZP_GetWeaponModelShell(gWeapon, sName, sizeof(sName));
	UTIL_CreateParticle(view, _, _, "2", sName, 0.1);
}

void Weapon_OnCreateFire(int client, int weapon, const float vPosition[3])
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

		ScaleVector(vEndVelocity, hCvarBalrogSpeed.FloatValue);

		AddVectors(vEndVelocity, vVelocity, vEndVelocity);

		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);

		AcceptEntityInput(entity, "DisableDraw"); 
		AcceptEntityInput(entity, "DisableShadow"); 
		
		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

		SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01); 

		SDKHook(entity, SDKHook_Touch, FireTouchHook);
		
		float flDuration = hCvarBalrogLife.FloatValue;
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarBalrogTrail.GetString(sEffect, sizeof(sEffect));

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(entity, vPosition, _, _, sEffect, flDuration);
		}
		else
		{
			TE_SetupBeamFollow(entity, gTrail, 0, flDuration, 10.0, 10.0, 5, {227, 66, 52, 200});
			TE_SendToAll();	
		}
		
		UTIL_RemoveEntity(entity, flDuration);
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
		GetEntProp(%2, Prop_Data, "m_iHealth"), \
								\
		GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
								\
		GetGameTime()           \
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
		SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", 0);
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
		if (!(iButtons & IN_ATTACK) && iButtons & IN_ATTACK2)
		{
			_call.SecondaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK2); //! Bugfix
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

/**
 * @brief Called on shoot of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponShoot(int client, int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
		_call.Shoot(client, weapon);
	}
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

		if (IsClientValid(target))
		{
			if (ZP_IsPlayerZombie(target)) 
			{
				UTIL_IgniteEntity(target, hCvarBalrogIgnite.FloatValue);  
			}
		}

		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		static char sEffect[SMALL_LINE_LENGTH];
		hCvarBalrogExp.GetString(sEffect, sizeof(sEffect));

		int iFlags = EXP_NOSOUND;

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
			iFlags |= EXP_NOFIREBALL; /// remove effect sprite
		}		

		UTIL_CreateExplosion(vPosition, iFlags, _, hCvarBalrogDamage.FloatValue, hCvarBalrogRadius.FloatValue, "balrog11", thrower, entity);
		
		ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC);
		
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
