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
	name            = "[ZP] Weapon: PlasmaGun",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/  
#define WEAPON_IDLE_TIME   10.0
#define WEAPON_ATTACK_TIME 1.5
/**
 * @endsection
 **/

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_DRAW,
	ANIM_RELOAD
};

// Decal index
int gTrail;

// Item index
int gWeapon;

// Sound index
int gSoundAttack; int gSoundIdle;

// Cvars
ConVar hCvarPlasmaSpeed;
ConVar hCvarPlasmaDamage;
ConVar hCvarPlasmaRadius;
ConVar hCvarPlasmaTrail;
ConVar hCvarPlasmaExp;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarPlasmaSpeed  = CreateConVar("zp_weapon_plasma_speed", "2000.0", "Projectile speed", 0, true, 0.0);
	hCvarPlasmaDamage = CreateConVar("zp_weapon_plasma_damage", "50.0", "Projectile damage", 0, true, 0.0);
	hCvarPlasmaRadius = CreateConVar("zp_weapon_plasma_radius", "150.0", "Damage radius", 0, true, 0.0);
	hCvarPlasmaTrail  = CreateConVar("zp_weapon_plasma_trail", "pyrovision_rockettrail", "Particle effect for the trail (''-default)");
	hCvarPlasmaExp    = CreateConVar("zp_weapon_plasma_explosion", "Explosion_bubbles", "Particle effect for the explosion (''-default)");
	
	AutoExecConfig(true, "zp_weapon_plasmagun", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("plasmagun");
	
	gSoundAttack = ZP_GetSoundKeyID("PLASMAGUN_SHOOT_SOUNDS");
	if (gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"PLASMAGUN_SHOOT_SOUNDS\" wasn't find");
	gSoundIdle = ZP_GetSoundKeyID("PLASMAGUN_IDLE_SOUNDS");
	if (gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"PLASMAGUN_IDLE_SOUNDS\" wasn't find");
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

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	Weapon_OnCreateEffect(client, weapon, "Kill");
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
	
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	if (iClip <= 0)
	{
		if (iAmmo)
		{
			Weapon_OnReload(client, weapon, iClip, iAmmo, flCurrentTime);
			return; /// Execute fake reload
		}
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	if (min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
	{
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

	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	
	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

	SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);

	Weapon_OnCreateEffect(client, weapon);
	
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnDrop(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	Weapon_OnCreateEffect(client, weapon, "Kill");
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	if (iClip <= 0)
	{
		EmitSoundToClient(client, SOUND_CLIP_EMPTY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_ITEM);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
		return;
	}

	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return;
	}

	iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponShoot(gWeapon));       

	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	ZP_EmitSoundToAll(gSoundAttack, 1, client, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);
	
	ZP_SetViewAnimation(client, { ANIM_SHOOT1, ANIM_SHOOT2 });   
	ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
	
	Weapon_OnCreatePlasma(client, weapon);

	static float vVelocity[3]; int iFlags = GetEntityFlags(client);
	float vKickback[] = { /*upBase = */0.25, /* lateralBase = */0.45, /* upMod = */0.155, /* lateralMod = */0.05, /* upMax = */1.5, /* lateralMax = */2.5, /* directionChange = */5.0 };
	
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
}

void Weapon_OnCreatePlasma(int client, int weapon)
{
	static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEndVelocity[3];

	ZP_GetPlayerEyePosition(client, 30.0, 5.0, 0.0, vPosition);

	GetClientEyeAngles(client, vAngle);

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	int entity = UTIL_CreateProjectile(vPosition, vAngle, gWeapon);

	if (entity != -1)
	{
		GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);

		NormalizeVector(vEndVelocity, vEndVelocity);

		ScaleVector(vEndVelocity, hCvarPlasmaSpeed.FloatValue);

		AddVectors(vEndVelocity, vVelocity, vEndVelocity);

		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);

		AcceptEntityInput(entity, "DisableDraw"); 
		AcceptEntityInput(entity, "DisableShadow"); 

		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

		SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01); 

		SDKHook(entity, SDKHook_Touch, PlasmaTouchHook);
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarPlasmaTrail.GetString(sEffect, sizeof(sEffect));

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(entity, vPosition, _, _, sEffect, 5.0);
		}
		else
		{
			TE_SetupBeamFollow(entity, gTrail, 0, 1.0, 3.0, 3.0, 1, {154, 205, 50, 200});
			TE_SendToAll();	
		}
	}
}

void Weapon_OnCreateEffect(int client, int weapon, char[] sInput = "")
{
	int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity");
	
	if (!hasLength(sInput))
	{
		if (entity != -1)
		{
			return;
		}

		static char sMuzzle[NORMAL_LINE_LENGTH];
		ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));

		entity = UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sMuzzle, 9999.9);
			
		if (entity != -1)
		{
			SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
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
		
		_call.Idle(client, weapon);
	}
	
	return Plugin_Continue;
}

//**********************************************
//* Item (rocket) hooks.                       *
//**********************************************

/**
 * @brief Plasma touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action PlasmaTouchHook(int entity, int target)
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

		static char sEffect[SMALL_LINE_LENGTH];
		hCvarPlasmaExp.GetString(sEffect, sizeof(sEffect));

		int iFlags = EXP_NOSOUND;

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
			iFlags |= EXP_NOFIREBALL; /// remove effect sprite
		}

		UTIL_CreateExplosion(vPosition, iFlags, _, hCvarPlasmaDamage.FloatValue, hCvarPlasmaRadius.FloatValue, "plasma", thrower, entity);

		ZP_EmitSoundToAll(gSoundAttack, 2, entity, SNDCHAN_STATIC, SNDLEVEL_EXPLOSION - 15);

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
