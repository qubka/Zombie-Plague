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
	name            = "[ZP] Weapon: Balrog I",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE2_TIME   1.66
#define WEAPON_ATTACK2_TIME 3.0
#define WEAPON_RELOAD2_TIME 2.96
#define WEAPON_SWITCH_TIME  2.0
#define WEAPON_SWITCH2_TIME 1.26
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_DRAW,
	ANIM_RELOAD,
	ANIM_CHANGE,
	ANIM_CHANGE2,
	ANIM_IDLE2_1,
	ANIM_SHOOT2_1,
	ANIM_SHOOT2_2,
	ANIM_RELOAD2,
	ANIM_IDLE2_2,
};

// Weapon states
enum
{
	STATE_NORMAL,
	STATE_ACTIVE
};

// Weapon index
int gWeapon;

// Sound index
int gSound;

// Cvars
ConVar hCvarBalrogDamage;
ConVar hCvarBalrogRadius;
ConVar hCvarBalrogExp;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarBalrogDamage = CreateConVar("zp_weapon_balrog1_damage", "600.0", "Explosion damage", 0, true, 0.0);
	hCvarBalrogRadius = CreateConVar("zp_weapon_balrog1_radius", "150.0", "Explosion radius", 0, true, 0.0);
	hCvarBalrogExp    = CreateConVar("zp_weapon_balrog1_explosion", "explosion_hegrenade_interior", "Particle effect for the explosion (''-default)");
	
	AutoExecConfig(true, "zp_weapon_balrog1", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("balrog1");
	
	gSound = ZP_GetSoundKeyID("BALROGI2_SHOOT_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALROGI2_SHOOT_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	PrecacheModel("materials/sprites/xfireball3.vmt", true); /// for env_explosion
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 
	
	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (!iStateMode)
	{
		return;
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetViewAnimation(client, { ANIM_IDLE2_1, ANIM_IDLE2_2});
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE2_TIME);
}

bool Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (!iStateMode)
	{
		return false;
	}
	
	if (min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
	{
		return false;
	}

	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return false;
	}
	
	ZP_SetWeaponAnimation(client, ANIM_RELOAD2); 
	
	flCurrentTime += WEAPON_RELOAD2_TIME;
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);

	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
	
	return true;
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

	SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

bool Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (!iStateMode)
	{
		return false;
	}

	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return false;
	}
	
	if (iClip <= 0)
	{
		EmitSoundToClient(client, SOUND_CLIP_EMPTY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_LIBRARY);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
		return false;
	}
	
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return false;
	}
	
	flCurrentTime += WEAPON_ATTACK2_TIME;
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
	 
	iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 
	 
	ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL);
	
	ZP_SetViewAnimation(client, { ANIM_SHOOT2_1, ANIM_SHOOT2_2});
	
	Weapon_OnCreateExplosion(client, weapon);
	
	SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
	
	static char sName[NORMAL_LINE_LENGTH];
	
	int view = ZP_GetClientViewModel(client, true);
	
	ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
	UTIL_CreateParticle(view, _, _, "1", sName, 0.1);
	
	ZP_GetWeaponModelShell(gWeapon, sName, sizeof(sName));
	UTIL_CreateParticle(view, _, _, "2", sName, 0.1);
	
	return true;
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	if (iClip <= 0)
	{
		return;
	}
	
	if (!iStateMode)
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

		ZP_SetWeaponAnimation(client, ANIM_CHANGE); 
		
		flCurrentTime += WEAPON_SWITCH_TIME;
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 

		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_ACTIVE);
	}
	else
	{
		ZP_SetWeaponAnimation(client, ANIM_CHANGE2); 

		flCurrentTime += WEAPON_SWITCH2_TIME;

		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
		
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
	}
}

void Weapon_OnCreateExplosion(int client, int weapon)
{
	static float vPosition[3]; static float vAngle[3]; static float vEndPosition[3]; 

	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngle);
	
	TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, SelfFilter, client); 

	if (TR_DidHit()) 
	{
		TR_GetEndPosition(vEndPosition); 
	
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarBalrogExp.GetString(sEffect, sizeof(sEffect));

		int iFlags = EXP_NOSOUND;

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(_, vEndPosition, _, _, sEffect, 2.0);
			iFlags |= EXP_NOFIREBALL; /// remove effect sprite
		}
		
		UTIL_CreateExplosion(vEndPosition, iFlags, _, hCvarBalrogDamage.FloatValue, hCvarBalrogRadius.FloatValue, "balrog1", client, weapon);
		
		ZP_EmitAmbientSound(gSound, 2, vEndPosition, SOUND_FROM_WORLD, SNDLEVEL_NORMAL);
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
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_NORMAL);
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
		static float flReloadTime;
		if ((flReloadTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flReloadTime <= GetGameTime())
		{
			_call.ReloadFinish(client, weapon);
		}
		else
		{
			if (iButtons & IN_RELOAD)
			{
				if (_call.Reload(client, weapon))
				{
					iButtons &= (~IN_RELOAD); //! Bugfix
					return Plugin_Changed;
				}
			}
		}
		
		if (iButtons & IN_ATTACK)
		{
			if (_call.PrimaryAttack(client, weapon))
			{
				iButtons &= (~IN_ATTACK); //! Bugfix
				return Plugin_Changed;
			}
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
