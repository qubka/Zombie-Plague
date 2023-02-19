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
	name            = "[ZP] Weapon: Watercannon",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME         1.66
#define WEAPON_ATTACK_START_TIME 0.2
#define WEAPON_ATTACK_END_TIME   0.7
/**
 * @endsection
 **/

// Item index
int gWeapon;

// Sound index
int gSound;

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_ATTACK_LOOP1,
	ANIM_ATTACK_LOOP2,
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

// Cvars
ConVar hCvarWaterSpeed;
ConVar hCvarWaterDamage;
ConVar hCvarWaterRadius;
ConVar hCvarWaterLife;
ConVar hCvarWaterIgnite;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarWaterSpeed  = CreateConVar("zp_weapon_watercannon_speed", "1000.0", "Projectile speed", 0, true, 0.0);
	hCvarWaterDamage = CreateConVar("zp_weapon_watercannon_damage", "50.0", "Projectile damage", 0, true, 0.0);
	hCvarWaterRadius = CreateConVar("zp_weapon_watercannon_radius", "30.0", "Damage radius", 0, true, 0.0);
	hCvarWaterLife   = CreateConVar("zp_weapon_watercannon_life", "0.8", "Duration of life", 0, true, 0.0);
	hCvarWaterIgnite = CreateConVar("zp_weapon_watercannon_ignite", "1.0", "Duration of ignite", 0, true, 0.0);

	AutoExecConfig(true, "zp_weapon_watercannon", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("watercannon");

	gSound = ZP_GetSoundKeyID("WATERCANNON_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"WATERCANNON_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	Weapon_OnCreateEffect(weapon, "Kill");
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
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
	ZP_SetPlayerAnimation(client, AnimType_Reload);
	
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
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
	
	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);

	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
	
	Weapon_OnCreateEffect(weapon);
}

void Weapon_OnDrop(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	Weapon_OnCreateEffect(weapon, "Kill");
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

	switch (iStateMode)
	{
		case STATE_BEGIN :
		{
			ZP_SetWeaponAnimation(client, ANIM_ATTACK_START);        

			SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_ATTACK);

			flCurrentTime += WEAPON_ATTACK_START_TIME;
			
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
		}

		case STATE_ATTACK :
		{
			ZP_SetViewAnimation(client, { ANIM_ATTACK_LOOP1, ANIM_ATTACK_LOOP2 });   
			ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
	
			iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); if (!iClip)
			{
				Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
				return;
			}

			ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON);

			flCurrentTime += ZP_GetWeaponShoot(gWeapon);
			
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);         

			SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
			
			Weapon_OnCreateFire(client, weapon);

			static float vVelocity[3]; int iFlags = GetEntityFlags(client);
			float vKickback[] = { /*upBase = */0.25, /* lateralBase = */0.35, /* upMod = */0.15, /* lateralMod = */0.05, /* upMax = */0.5, /* lateralMax = */0.25, /* directionChange = */4.0 };
			
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
		}
	}
}

void Weapon_OnCreateFire(int client, int weapon)
{
	static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEndVelocity[3];

	ZP_GetPlayerEyePosition(client, 30.0, 7.5, 0.0, vPosition);
	
	GetClientEyeAngles(client, vAngle);

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	int entity = UTIL_CreateProjectile(vPosition, vAngle, gWeapon);

	if (entity != -1)
	{
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 10.0);
		
		GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);

		NormalizeVector(vEndVelocity, vEndVelocity);

		ScaleVector(vEndVelocity, hCvarWaterSpeed.FloatValue);

		AddVectors(vEndVelocity, vVelocity, vEndVelocity);

		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);

		AcceptEntityInput(entity, "DisableDraw"); 
		AcceptEntityInput(entity, "DisableShadow"); 
		
		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

		SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01); 

		SDKHook(entity, SDKHook_Touch, FireTouchHook);
		
		UTIL_RemoveEntity(entity, hCvarWaterLife.FloatValue);
	}
}

void Weapon_OnEndAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (iStateMode > STATE_BEGIN)
	{
		ZP_SetWeaponAnimation(client, ANIM_ATTACK_END);        

		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);

		flCurrentTime += WEAPON_ATTACK_END_TIME;
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
		
		Weapon_OnCreateEffect(weapon, "Stop");
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

			entity = UTIL_CreateParticle(world, _, _, "muzzle_flash", sMuzzle);
			
			if (entity != -1)
			{
				SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
				
				AcceptEntityInput(entity, "Stop"); 
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
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
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
		
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		UTIL_CreateDamage(_, vPosition, thrower, hCvarWaterDamage.FloatValue, hCvarWaterRadius.FloatValue, DMG_NEVERGIB, gWeapon);
		
		if (IsPlayerExist(target) && ZP_IsPlayerZombie(target)) 
		{
			UTIL_IgniteEntity(target, hCvarWaterIgnite.FloatValue);   
		}
		
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
