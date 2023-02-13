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
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME    3.0
#define WEAPON_SWITCH_TIME  2.0
#define WEAPON_SWITCH2_TIME 1.66
#define WEAPON_ATTACK_TIME  1.0
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

// Sound index
int gSound;

// Cvars
ConVar hCvarJanusSignalCounter;
ConVar hCvarJanusActiveCounter;
ConVar hCvarJanusBeamDamage;
ConVar hCvarJanusBeamRadius;
ConVar hCvarJanusBeamMuzzle;
ConVar hCvarJanusBeamTracer;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarJanusSignalCounter = CreateConVar("zp_weapon_janus7_signal_counter", "100", "Amount of shots to activate second mode", 0, true, 0.0);
	hCvarJanusActiveCounter = CreateConVar("zp_weapon_janus7_active_counter", "150", "Amount of shots in the second mode", 0, true, 0.0);
	hCvarJanusBeamDamage    = CreateConVar("zp_weapon_janus7_beam_damage", "50.0", "Beam damage per shoot", 0, true, 0.0);
	hCvarJanusBeamRadius    = CreateConVar("zp_weapon_janus7_beam_radius", "500.0", "Radius when beam attach to nearby target", 0, true, 0.0);
	hCvarJanusBeamMuzzle    = CreateConVar("zp_weapon_janus7_beam_muzzle", "medicgun_invulnstatus_fullcharge_red", "Particle effect for the muzzle");
	hCvarJanusBeamTracer    = CreateConVar("zp_weapon_janus7_beam_tracer", "medicgun_beam_red_invun", "Particle effect for the tracer");

	AutoExecConfig(true, "zp_weapon_janus7", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("janus7");

	gSound = ZP_GetSoundKeyID("JANUSVII_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JANUSVII_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	Weapon_OnCreateEffect(client, weapon, "Kill");
	
	SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
	
	Weapon_OnCreateEffect(client, weapon);
	
	if (iStateMode == STATE_ACTIVE)
	{
		Weapon_OnCreateEffect(client, weapon, "Start");
	}
	
	ZP_SetWeaponAnimation(client, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW2 : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW); 

	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnDrop(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	Weapon_OnCreateEffect(client, weapon, "Kill");
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	if (iStateMode == STATE_ACTIVE)
	{
		return;
	}
	
	if (min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
	{
		return;
	}

	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_RELOAD : ANIM_RELOAD_SIGNAL); 
	ZP_SetPlayerAnimation(client, AnimType_Reload);
	
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

	SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	if (iStateMode != STATE_ACTIVE)
	{
		if (iClip <= 0)
		{
			if (iAmmo)
			{
				Weapon_OnReload(client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime);
				return; /// Execute fake reload
			}
		}
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}

	ZP_SetWeaponAnimation(client, (iStateMode == STATE_ACTIVE) ? ANIM_IDLE2 : (iStateMode == STATE_SIGNAL) ? ANIM_IDLE_SIGNAL : ANIM_IDLE); 

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	if (iStateMode == STATE_ACTIVE)
	{
		if (iCounter > hCvarJanusActiveCounter.IntValue)
		{
			Weapon_OnFinish(client, weapon, iClip, iAmmo, iCounter, iStateMode, flCurrentTime);
			return;
		}
		
		if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
		{
			return;
		}
		
		ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);
		
		ZP_SetViewAnimation(client, { ANIM_SHOOT2_1, ANIM_SHOOT2_2});

		Weapon_OnCreateBeam(client, weapon);
	}
	else
	{
		if (iClip <= 0)
		{
			EmitSoundToClient(client, SOUND_CLIP_EMPTY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_ITEM);
			SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
			return;
		}

		iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 
		
		if (iCounter > hCvarJanusSignalCounter.IntValue)
		{
			SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_SIGNAL);

			iCounter = -1;
			
			ZP_EmitSoundToAll(gSound, 3, client, SNDCHAN_VOICE, SNDLEVEL_SKILL);
			
			SetGlobalTransTarget(client);
			PrintHintText(client, "%t", "janus activated");
		}
		
		ZP_SetViewAnimation(client, (iStateMode == STATE_SIGNAL) ? { ANIM_SHOOT_SIGNAL_1, ANIM_SHOOT_SIGNAL_2 } : { ANIM_SHOOT1, ANIM_SHOOT2 });   

		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);    
	
		SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);

		static char sName[NORMAL_LINE_LENGTH];
		
		int view = ZP_GetClientViewModel(client, true);
		
		ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
		UTIL_CreateParticle(view, _, _, "1", sName, 0.1);
		
		ZP_GetWeaponModelShell(gWeapon, sName, sizeof(sName));
		UTIL_CreateParticle(view, _, _, "2", sName, 0.1);
		
		static float vVelocity[3]; int iFlags = GetEntityFlags(client); 
		float flSpread = 0.01; float flInaccuracy = 0.015;
		float vKickback[] = { /*upBase = */0.36, /* lateralBase = */0.47, /* upMod = */0.06, /* lateralMod = */0.05, /* upMax = */1.25, /* lateralMax = */1.5, /* directionChange = */6.0 };
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

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
		
		Weapon_OnCreateBullet(client, weapon, 0, GetRandomInt(0, 1000), flSpread, flInaccuracy);
	}
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME); 

	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponShoot(gWeapon));    

	SetEntProp(weapon, Prop_Data, "m_iHealth", iCounter + 1);
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	if (iStateMode == STATE_SIGNAL)
	{
		if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
		{
			return;
		}

		ZP_SetWeaponAnimation(client, ANIM_CHANGE);        

		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_ACTIVE);
		
		SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
		
		flCurrentTime += WEAPON_SWITCH_TIME;
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
		
		flCurrentTime -= 0.5;

		SetEntPropFloat(weapon, Prop_Send, "m_flUseLookAtAngle", flCurrentTime);
		
		Weapon_OnCreateEffect(client, weapon, "Start");
	}
}

void Weapon_OnFinish(int client, int weapon, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
	ZP_SetWeaponAnimation(client, ANIM_CHANGE2);        

	SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_NORMAL);
	
	SetEntProp(weapon, Prop_Data, "m_iHealth", 0);

	flCurrentTime += WEAPON_SWITCH2_TIME;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
	
	Weapon_OnCreateEffect(client, weapon, "Stop");
}

void Weapon_OnCreateBullet(int client, int weapon, int iMode, int iSeed, float flSpread, float flInaccuracy)
{
	static float vPosition[3]; static float vAngle[3];

	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngle);

	ZP_FireBullets(client, weapon, vPosition, vAngle, iMode, iSeed, flInaccuracy, flSpread, 0.0, 0, GetEntPropFloat(weapon, Prop_Send, "m_flRecoilIndex"));
}

void Weapon_OnCreateBeam(int client, int weapon)
{
	static float vPosition[3]; static float vAngle[3]; static float vPosition2[3]; bool bFound;

	ZP_GetPlayerEyePosition(client, 30.0, 10.0, -10.0, vPosition);

	float flRadius = hCvarJanusBeamRadius.FloatValue;
	float flDamage = hCvarJanusBeamDamage.FloatValue;

	int i; int it = 1; /// iterator
	while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
	{
		if (ZP_IsPlayerHuman(i))
		{
			continue;
		}

		GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPosition2); vPosition2[2] += 45.0;

		if (!UTIL_TraceRay(client, i, vPosition, vPosition2, SelfFilter))
		{
			continue;
		}

		ZP_TakeDamage(i, client, weapon, flDamage, DMG_NEVERGIB, weapon);
		
		UTIL_CreateShakeScreen(i, 3.0, 1.0, 2.0);
		
		bFound = true; 
		break;
	}
	
	if (!bFound)
	{
		GetClientEyeAngles(client, vAngle);

		TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, SelfFilter, client);
		TR_GetEndPosition(vPosition2);
	}
	
	static char sEffect[SMALL_LINE_LENGTH];
	hCvarJanusBeamTracer.GetString(sEffect, sizeof(sEffect));	

	ZP_CreateWeaponTracer(client, weapon, "1", "muzzle_flash", sEffect, vPosition2, ZP_GetWeaponShoot(gWeapon));
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
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarJanusBeamMuzzle.GetString(sEffect, sizeof(sEffect));

		entity = UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sEffect, 9999.9);
			
		if (entity != -1)
		{
			SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
			
			AcceptEntityInput(entity, "Stop"); 
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
	if (weaponID == gWeapon)
	{
		ZP_CreateWeaponTracer(client, weapon, "1", "muzzle_flash", "weapon_tracers_mach", vBullet, ZP_GetWeaponShoot(gWeapon));
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
		static float flApplyModeTime;
		if ((flApplyModeTime = GetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle")) && flApplyModeTime <= GetGameTime())
		{
			SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);
			SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_ACTIVE);
		}
		
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
