/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
	name            = "[ZP] Weapon: Ethereal",
	author          = "qubka (Nikita Ushakov), nuclear silo",
	description     = "Addon of custom weapon",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME                10.0
#define WEAPON_ATTACK_TIME              1.0
#define WEAPON_SWITCH_TIME              3.5
/**
 * @endsection
 **/

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSoundAttack; int gSoundIdle; ConVar hSoundLevel;
#pragma unused gSoundAttack, gSoundIdle, hSoundLevel

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_RELOAD,
	ANIM_DRAW
};

// Weapon states
enum
{
	STATE_NORMAL,
	STATE_ACTIVE
};

ConVar g_cvarTracerEnable;
ConVar g_cvarTracerMaterial;
ConVar g_cvarTracerLife;
ConVar g_cvarTracerWidth;
ConVar g_cvarTracerColor;

int gBeam = -1;
int g_iColor[4];

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnPluginStart()
{
	//RegConsoleCmd("sm_ethereal", Command_Ethereal);
	
	g_cvarTracerEnable = CreateConVar("sm_store_tracer_enable", "1", "Enable tracers for normal mode");
	g_cvarTracerMaterial = CreateConVar("sm_store_tracer_material", "materials/sprites/laserbeam.vmt", "Material to be used with tracers");
	g_cvarTracerLife = CreateConVar("sm_store_tracer_life", "0.2", "Life of a tracer in seconds");
	g_cvarTracerWidth = CreateConVar("sm_store_tracer_width", "0.2", "Life of a tracer in seconds");
	g_cvarTracerColor = CreateConVar("sm_store_tracer_color", "0 255 255 255", "Color of a tracer");
	
	AutoExecConfig(true, "ethereal", "sourcemod/zombieplague");
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

public void OnMapStart()
{
	char temp[PLATFORM_MAX_PATH];
	g_cvarTracerMaterial.GetString(temp, sizeof(temp));
	gBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	
	char s_ColorValue[64];
	g_cvarTracerColor.GetString(s_ColorValue, sizeof(s_ColorValue));
	
	ColorStringToArray(s_ColorValue, g_iColor);
	
	// Weapons
	gWeapon = ZP_GetWeaponNameID("etherial");
	if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"etherial\" wasn't find");
	
	// Sounds
	gSoundAttack = ZP_GetSoundKeyID("ETHERIAL_SHOOT_SOUNDS");
	if (gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"ETHERIAL_SHOOT_SOUNDS\" wasn't find");
	gSoundIdle = ZP_GetSoundKeyID("ETHERIAL_IDLE_SOUNDS");
	if (gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"ETHERIAL_IDLE_SOUNDS\" wasn't find");
	
	// Cvars
	hSoundLevel = FindConVar("zp_seffects_level");
	if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Cancel reload
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0); 
	
	// Stop sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

	// Sets draw animation
	ZP_SetWeaponAnimation(client, ANIM_DRAW); 

	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate clip
	if (min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
	{
		return;
	}

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Sets reload animation
	ZP_SetWeaponAnimation(client, ANIM_RELOAD); 
	ZP_SetPlayerAnimation(client, AnimType_Reload);
	
	// Adds the delay to the game tick
	flCurrentTime += ZP_GetWeaponReload(gWeapon);
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

	// Stop sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	
	// Remove the delay to the game tick
	flCurrentTime -= 0.5;
	
	// Sets reloading time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	// Sets shots count
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
	
	// Gets new amount
	int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

	// Sets ammunition
	SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

	// Sets reload time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate clip
	if (iClip <= 0)
	{
		// Validate ammo
		if (iAmmo)
		{
			Weapon_OnReload(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
			return; /// Execute fake reload
		}
	}
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}

	// Sets idle animation
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 

	// Play sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, hSoundLevel.IntValue);
	
	// Sets next idle time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}
	
	// Validate clip
	if (iClip <= 0)
	{
		// Emit empty sound
		EmitSoundToClient(client, "weapons/clipempty_rifle.wav");
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
		return;
	}

	// Substract ammo
	iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 
	

	// Sets attack animation
	ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT1, ANIM_SHOOT2 });   

	// Play sound
	ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
	ZP_EmitSoundToAll(gSoundAttack, 1, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
	
	// Sets attack animation
	ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
	if (iStateMode == STATE_NORMAL)
	{
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponSpeed(gWeapon));       

		// Sets next idle time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
		
		// Sets shots count
		SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);

		// Sets weapon muzzle
		static char sName[NORMAL_LINE_LENGTH];
		ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
		UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sName, 0.1);
		
		// Initialize variables
		static float vVelocity[3]; int iFlags = GetEntityFlags(client); 
		float flSpread = 0.01; float flInaccuracy = 0.013;

		// Gets client velocity
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

		// Apply kick back
		if (GetVectorLength(vVelocity) <= 0.0)
		{
			ZP_CreateWeaponKickBack(client, 0.0, 0.4, 0.10, 0.02, 1.5, 1.5, 7);
		}
		else if (!(iFlags & FL_ONGROUND))
		{
			ZP_CreateWeaponKickBack(client, 0.0, 1.0, 0.4, 0.15, 2.0, 1.0, 5);
			flInaccuracy = 0.1;
			flSpread = 0.12;
		}
		else if (iFlags & FL_DUCKING)
		{
			ZP_CreateWeaponKickBack(client, 0.0, 0.5, 0.1, 0.025, 1.1, 2.3, 9);
			flInaccuracy = 0.05;
		}
		else
		{
			ZP_CreateWeaponKickBack(client, 2.0, 1.2, 0.14, 0.0375, 1.8, 2.8, 8);
		}
		
		// Create a bullet
		Weapon_OnCreateBullet(client, weapon, 0, GetRandomInt(0, 1000), flSpread, flInaccuracy);
		
		// Create a fire
		//Weapon_OnCreateBeam(client, weapon);
	}
	else
	{
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + (ZP_GetWeaponSpeed(gWeapon)/2));       

		// Sets next idle time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
		
		// Sets shots count
		SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);

		// Sets weapon muzzle
		static char sName[NORMAL_LINE_LENGTH];
		ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
		UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sName, 0.1);
		
		// Initialize variables
		static float vVelocity[3]; int iFlags = GetEntityFlags(client); 
		float flSpread = 0.01; float flInaccuracy = 0.013;

		// Gets client velocity
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

		// Apply kick back
		if (GetVectorLength(vVelocity) <= 0.0)
		{
			ZP_CreateWeaponKickBack(client, 2.5, 1.5, 0.15, 0.05, 5.5, 4.5, 7);
		}
		else if (!(iFlags & FL_ONGROUND))
		{
			ZP_CreateWeaponKickBack(client, 5.0, 2.0, 0.4, 0.15, 7.0, 5.0, 5);
			flInaccuracy = 0.02;
			flSpread = 0.05;
		}
		else if (iFlags & FL_DUCKING)
		{
			ZP_CreateWeaponKickBack(client, 2.5, 0.5, 0.1, 0.025, 5.1, 6.3, 9);
			flInaccuracy = 0.01;
		}
		else
		{
			ZP_CreateWeaponKickBack(client, 2.8, 1.8, 0.14, 0.0375, 5.8, 5.8, 8);
		}
		
		// Create a bullet
		Weapon_OnCreateBullet(client, weapon, 0, GetRandomInt(0, 1000), flSpread, flInaccuracy);
	}
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
	#pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
	
	// Validate mode
	if (iStateMode == STATE_NORMAL)
	{
		// Validate animation delay
		if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
		{
			return;
		}
	
		// Sets change animation
		ZP_SetWeaponAnimation(client, ANIM_RELOAD);        

		// Sets active state
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_ACTIVE);
		
		// Sets shots count
		//SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
		
		// Adds the delay to the game tick
		flCurrentTime += WEAPON_SWITCH_TIME;
				
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
		
		// Remove the delay to the game tick
		flCurrentTime -= 0.5;
		
		// Sets switching time
		SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
		
		SetGlobalTransTarget(client);
		PrintHintText(client, "Mode: Electric");
	}
	else
	{
		// Validate animation delay
		if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
		{
			return;
		}
	
		// Sets change animation
		ZP_SetWeaponAnimation(client, ANIM_RELOAD);        

		// Sets active state
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_NORMAL);
		
		// Sets shots count
		//SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
		
		// Adds the delay to the game tick
		flCurrentTime += WEAPON_SWITCH_TIME;
				
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
		
		// Remove the delay to the game tick
		flCurrentTime -= 0.5;
		
		// Sets switching time
		SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
		
		SetGlobalTransTarget(client);
		PrintHintText(client, "Mode: Normal");
	}
}

void Weapon_OnCreateBullet(int client, int weapon, int iMode, int iSeed, float flSpread, float flInaccuracy)
{
	#pragma unused client, weapon, iMode, iSeed, flSpread, flInaccuracy
	
	// Initialize vectors
	static float vPosition[3]; static float vAngle[3];

	// Gets weapon position
	ZP_GetPlayerGunPosition(client, 30.0, 7.0, 0.0, vPosition);

	// Gets client eye angle
	GetClientEyeAngles(client, vAngle);

	// Emulate bullet shot
	ZP_FireBullets(client, weapon, vPosition, vAngle, iMode, iSeed, flInaccuracy, flSpread, 0.0, 0, GetEntPropFloat(weapon, Prop_Send, "m_flRecoilIndex"));
}

void Weapon_OnCreateBeam(int client, int weapon)
{
	#pragma unused client, weapon

	// Initialize vectors
	static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

	// Gets weapon position
	ZP_GetPlayerGunPosition(client, 30.0, 10.0, -5.0, vPosition);

	// Gets client eye angle
	GetClientEyeAngles(client, vAngle);

	// Create the end-point trace
	TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, SelfFilter, client);

	// Returns the collision position of a trace result
	TR_GetEndPosition(vEndPosition);

	// Gets beam lifetime
	//float flLife = ZP_GetWeaponSpeed(gWeapon);

	// Sent a beam
	TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, 0, 0, 0, g_cvarTracerLife.FloatValue, g_cvarTracerWidth.FloatValue, g_cvarTracerWidth.FloatValue, 1, 0.0, g_iColor, 0);
	TE_SendToClient(client);

	// Gets worldmodel index
	int world = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");

	// Validate entity
	if (world != -1)
	{
		static float vPosition2[3];
		
		// Gets attachment position
		ZP_GetAttachment(world, "muzzle_flash", vPosition, vAngle);
		//WA_GetAttachmentPos(client, "muzzle_flash", vPosition2);
		
		// Sent a beam
		TE_SetupBeamPoints(vPosition2, vEndPosition, gBeam, 0, 0, 0, g_cvarTracerLife.FloatValue, g_cvarTracerWidth.FloatValue, g_cvarTracerWidth.FloatValue, 1, 0.0, g_iColor, 0);
		int[] iClients = new int[MaxClients]; int iCount;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPlayerExist(i, false) || i == client || IsFakeClient(i)) continue;
			iClients[iCount++] = i;
		}
		TE_Send(iClients, iCount);
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
		GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
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
 * @brief Called on bullet of a weapon.
 *
 * @param client            The client index.
 * @param vBullet           The position of a bullet hit.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponBullet(int client, float vBullet[3], int weapon, int weaponID)
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Sent a beam
		if(GetEntProp(weapon, Prop_Data, "m_iMaxHealth") == STATE_ACTIVE)
			ZP_CreateWeaponTracer(client, weapon, "1", "muzzle_flash", "weapon_tracers_taser", vBullet, 0.1);
		else 
		{
			if(g_cvarTracerEnable.BoolValue)
				Weapon_OnCreateBeam(client, weapon);
		}
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
		// Time to reload weapon
		static float flReloadTime;
		if ((flReloadTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flReloadTime <= GetGameTime())
		{
			// Call event
			_call.ReloadFinish(client, weapon);
		}
		else
		{
			// Button reload press
			if (iButtons & IN_RELOAD)
			{
				// Call event
				_call.Reload(client, weapon);
				iButtons &= (~IN_RELOAD); //! Bugfix
				return Plugin_Changed;
			}
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

public void ColorStringToArray(const char[] sColorString, int aColor[4])
{
	char asColors[5][5];
	ExplodeString(sColorString, " ", asColors, sizeof(asColors), sizeof(asColors[]));

	aColor[0] = StringToInt(asColors[0]);
	aColor[1] = StringToInt(asColors[1]);
	aColor[2] = StringToInt(asColors[2]);
	aColor[3] = StringToInt(asColors[3]);
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