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
	name            = "[ZP] Weapon: Janus I",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME    2.0
#define WEAPON_SWITCH_TIME  2.0
#define WEAPON_SWITCH2_TIME 1.66
#define WEAPON_ATTACK_TIME  2.8
#define WEAPON_ATTACK2_TIME 1.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
	ANIM_IDLE_A,
	ANIM_SHOOT1_A,
	ANIM_SHOOT2_EMPTY_A,
	ANIM_SHOOT2_A,
	ANIM_CHANGE_A,
	ANIM_DRAW_A,
	ANIM_SHOOT_SIGNAL_1,
	ANIM_CHANGE2_A,
	ANIM_IDLE_B,
	ANIM_DRAW_B,
	ANIM_SHOOT1_B,
	ANIM_SHOOT2_B,
	ANIM_CHANGE_B,
	ANIM_IDLE_SIGNAL,
	ANIM_DRAW_SIGNAL,
	ANIM_SHOOT_EMPTY_SIGNAL,
	ANIM_SHOOT_SIGNAL_2
};

// Weapon states
enum
{
	STATE_NORMAL,
	STATE_SIGNAL,
	STATE_ACTIVE
};

// Decal index
int gTrail;

// Weapon index
int gWeapon;

// Sound index
int gSound;

// Cvars
ConVar hCvarJanusSignalCounter;
ConVar hCvarJanusActiveCounter;
ConVar hCvarJanusGrenadeDamage;
ConVar hCvarJanusGrenadeSpeed;
ConVar hCvarJanusGrenadeGravity;
ConVar hCvarJanusGrenadeRadius;
ConVar hCvarJanusGrenadeTrail;
ConVar hCvarJanusGrenadeExp;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarJanusSignalCounter  = CreateConVar("zp_weapon_janus1_signal_counter", "7", "Amount of shots to activate second mode", 0, true, 0.0);
	hCvarJanusActiveCounter  = CreateConVar("zp_weapon_janus1_active_counter", "14", "Amount of shots in the second mode", 0, true, 0.0);
	hCvarJanusGrenadeDamage  = CreateConVar("zp_weapon_janus1_grenade_damage", "350.0", "", 0, true, 0.0);
	hCvarJanusGrenadeSpeed   = CreateConVar("zp_weapon_janus1_grenade_speed", "1500.0", "", 0, true, 0.0);
	hCvarJanusGrenadeGravity = CreateConVar("zp_weapon_janus1_grenade_gravity", "1.5", "", 0, true, 0.0);
	hCvarJanusGrenadeRadius  = CreateConVar("zp_weapon_janus1_grenade_radius", "400.0", "", 0, true, 0.0);
	hCvarJanusGrenadeTrail   = CreateConVar("zp_weapon_janus1_trail", "critical_rocket_blue", "Particle effect for the trail (''-default)");
	hCvarJanusGrenadeExp     = CreateConVar("zp_weapon_janus1_grenade_explosion", "projectile_fireball_crit_blue", "Particle effect for the explosion (''-default)");
	
	AutoExecConfig(true, "zp_weapon_janus1", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		LoadTranslations("janus.phrases");

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
	gWeapon = ZP_GetWeaponNameID("janus1");
	
	gSound = ZP_GetSoundKeyID("janusi_shoot_sounds");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"janusi_shoot_sounds\" wasn't find");
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

void Weapon_OnHolster(int client, int weapon, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}

	ZP_SetWeaponAnimation(client, (iStateMode == STATE_ACTIVE) ? ANIM_IDLE_B : (iStateMode == STATE_SIGNAL) ? ANIM_IDLE_SIGNAL : ANIM_IDLE_A);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnDeploy(int client, int weapon, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	
	ZP_SetWeaponAnimation(client, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW_B : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW_A); 

	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
		
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return;
	}
	
	if (iStateMode == STATE_ACTIVE)
	{
		if (iCounter > hCvarJanusActiveCounter.IntValue)
		{
			Weapon_OnFinish(client, weapon, iAmmo, iCounter, iStateMode, flCurrentTime);
			return;
		}

		ZP_SetViewAnimation(client, { ANIM_SHOOT1_B, ANIM_SHOOT2_B});

		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK2_TIME);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponReload(gWeapon));    
	
		ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_WEAPON);
	}
	else
	{
		if (iAmmo <= 0)
		{
			EmitSoundToClient(client, SOUND_CLIP_EMPTY, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
			return;
		}

		iAmmo -= 1; SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo);

		if (iCounter > hCvarJanusSignalCounter.IntValue)
		{
			SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_SIGNAL);

			SetEntProp(weapon, Prop_Data, "m_iClip2", 0);

			ZP_EmitSoundToAll(gSound, 4, client, SNDCHAN_VOICE);

			SetGlobalTransTarget(client);
			PrintHintText(client, "%t", "janus activated");
			
			EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
		}
		
		if (!iAmmo)
		{
			ZP_SetWeaponAnimation(client, (iStateMode == STATE_SIGNAL) ? ANIM_SHOOT_EMPTY_SIGNAL : ANIM_SHOOT2_EMPTY_A);
		
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK2_TIME);
		}
		else
		{
			ZP_SetViewAnimation(client, (iStateMode == STATE_SIGNAL) ? { ANIM_SHOOT_SIGNAL_1, ANIM_SHOOT_SIGNAL_2 } : { ANIM_SHOOT1_A, ANIM_SHOOT2_A});
		
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
		}
   
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponShoot(gWeapon));  
		
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON);
	}
	
	ZP_SetPlayerAnimation(client, PLAYERANIMEVENT_RELOAD);

	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);

	SetEntProp(weapon, Prop_Data, "m_iClip2", iCounter + 1);

	Weapon_OnCreateGrenade(client);

	static float vVelocity[3]; int iFlags = GetEntityFlags(client);
	float vKickback[] = { /*upBase = */2.5, /* lateralBase = */1.5, /* upMod = */0.15, /* lateralMod = */0.05, /* upMax = */5.5, /* lateralMax = */4.5, /* directionChange = */7.0 };

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	if (GetVectorLength(vVelocity, true) <= 0.0)
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
	
	static char sMuzzle[NORMAL_LINE_LENGTH];
	ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));

	UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sMuzzle, 0.1);
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	if (iStateMode == STATE_SIGNAL)
	{
		if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
		{
			return;
		}
	
		ZP_SetWeaponAnimation(client, ANIM_CHANGE_A);        
		ZP_SetPlayerAnimation(client, PLAYERANIMEVENT_FIRE_GUN_SECONDARY);

		SetEntProp(weapon, Prop_Data, "m_iClip2", 0);
		
		flCurrentTime += WEAPON_SWITCH_TIME;
				
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
		
		flCurrentTime -= 0.5;
		
		SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	}
}

void Weapon_OnFinish(int client, int weapon, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	ZP_SetWeaponAnimation(client, ANIM_CHANGE_B);        

	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_NORMAL);
	
	SetEntProp(weapon, Prop_Data, "m_iClip2", 0);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);

	flCurrentTime += WEAPON_SWITCH2_TIME;
				
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
}

void Weapon_OnCreateGrenade(int client)
{
	static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEndVelocity[3];

	ZP_GetPlayerEyePosition(client, 30.0, 10.0, 0.0, vPosition);

	GetClientEyeAngles(client, vAngle);

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	int entity = UTIL_CreateProjectile(vPosition, vAngle, gWeapon, "models/weapons/cso/m32/w_m32_projectile.mdl");

	if (entity != -1)
	{
		GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);

		NormalizeVector(vEndVelocity, vEndVelocity);

		ScaleVector(vEndVelocity, hCvarJanusGrenadeSpeed.FloatValue);

		AddVectors(vEndVelocity, vVelocity, vEndVelocity);

		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);

		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

		SetEntPropFloat(entity, Prop_Data, "m_flGravity", hCvarJanusGrenadeGravity.FloatValue); 

		SDKHook(entity, SDKHook_Touch, GrenadeTouchHook);
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarJanusGrenadeTrail.GetString(sEffect, sizeof(sEffect));

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(entity, vPosition, _, _, sEffect, 5.0);
		}
		else
		{
			TE_SetupBeamFollow(entity, gTrail, 0, 1.0, 3.0, 3.0, 2, {211, 211, 211, 200});
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
		GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
								\
		GetEntProp(%2, Prop_Data, "m_iClip2"), \
								\
		GetEntProp(%2, Prop_Data, "m_iSecondaryAmmoCount"), \
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
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_NORMAL);
		SetEntProp(weapon, Prop_Data, "m_iClip2", 0);
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
		static float flApplyModeTime;
		if ((flApplyModeTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flApplyModeTime <= GetGameTime())
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
			SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_ACTIVE);
		}

		if (iButtons & IN_ATTACK)
		{
			_call.PrimaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK); //! Bugfix
			return Plugin_Changed;
		}
		
		if (iButtons & IN_ATTACK2)
		{
			_call.SecondaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK2); //! Bugfix
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
 * @brief Grenade touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action GrenadeTouchHook(int entity, int target)
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
		hCvarJanusGrenadeExp.GetString(sEffect, sizeof(sEffect));

		int iFlags = EXP_NOSOUND;

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
			iFlags |= EXP_NOFIREBALL; /// remove effect sprite
		}

		UTIL_CreateExplosion(vPosition, iFlags, _, hCvarJanusGrenadeDamage.FloatValue, hCvarJanusGrenadeRadius.FloatValue, "janus1", thrower, entity);

		ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC);

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
