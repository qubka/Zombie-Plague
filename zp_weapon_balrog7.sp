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
	name            = "[ZP] Weapon: Balrog VII",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Weapon index
int gWeapon;

// Sound index
int gSound;

// Cvars
ConVar hCvarBalrogRatio;
ConVar hCvarBalrogDamage;
ConVar hCvarBalrogRadius;
ConVar hCvarBalrogExp;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarBalrogRatio  = CreateConVar("zp_weapon_balrog7_ratio", "6", "Amount of bullets to trigger explosion (clip/ratio = amount)", 0, true, 0.0);
	hCvarBalrogDamage = CreateConVar("zp_weapon_balrog7_damage", "300.0", "Explosion damage", 0, true, 0.0);
	hCvarBalrogRadius = CreateConVar("zp_weapon_balrog7_radius", "150.0", "Explosion radius", 0, true, 0.0);
	hCvarBalrogExp    = CreateConVar("zp_weapon_balrog7_explosion", "explosion_hegrenade_interior", "Particle effect for the explosion (''-default)");
	
	AutoExecConfig(true, "zp_weapon_balrog7", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("balrog7");
	
	gSound = ZP_GetSoundKeyID("balrogvii2_shoot_sounds");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"balrogvii2_shoot_sounds\" wasn't find");
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

void Weapon_OnReload(int client, int weapon, const float vBullet[3], int iCounter, float flCurrentTime)
{
	SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
}

void Weapon_OnSecondaryAttack(int client, int weapon, const float vBullet[3], int iCounter, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetPlayerAnimation(client, PLAYERANIMEVENT_FIRE_GUN_SECONDARY);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 0.3);
	
	int iDefaultFOV = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
	SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iFOV") == iDefaultFOV ? 55 : iDefaultFOV);
}

void Weapon_OnBullet(int client, int weapon, const float vBullet[3], int iCounter, float flCurrentTime)
{
	if (iCounter > (ZP_GetWeaponClip(gWeapon) / hCvarBalrogRatio.IntValue))
	{
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarBalrogExp.GetString(sEffect, sizeof(sEffect));

		int iFlags = EXP_NOSOUND;

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(_, vBullet, _, _, sEffect, 2.0);
			iFlags |= EXP_NOFIREBALL; /// remove effect sprite
		}
		
		UTIL_CreateExplosion(vBullet, iFlags, _, hCvarBalrogDamage.FloatValue, hCvarBalrogRadius.FloatValue, "balrog7", client, weapon);

		ZP_EmitAmbientSound(gSound, 1, vBullet, SOUND_FROM_WORLD);
		
		iCounter = -1;
	}
	
	SetEntProp(weapon, Prop_Data, "m_iClip2", iCounter + 1);
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2,%3)      \
								\
	Weapon_On%0                 \
	(                           \
		%1,                     \
		%2,                     \
		%3,                     \
								\
		GetEntProp(%2, Prop_Data, "m_iClip2"), \
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
		SetEntProp(weapon, Prop_Data, "m_iClip2", 0);
	}
}

/**
 * @brief Called on reload of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponReload(int client, int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
		_call.Reload(client, weapon, NULL_VECTOR);
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
public void ZP_OnWeaponBullet(int client, const float vBullet[3], int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
		_call.Bullet(client, weapon, vBullet);
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
			_call.SecondaryAttack(client, weapon, NULL_VECTOR);
			iButtons &= (~IN_ATTACK2); //! Bugfix
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}
