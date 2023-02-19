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
	name            = "[ZP] Weapon: InfectBomb",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_COLOR {75, 255, 75, 255}
/**
 * @endsection
 **/
 
// Decal index
int gBeam; int gHalo; int gTrail;

// Sound index
int gSound;
 
// Item index
int gWeapon;

// Type index
int gType;

// Cvars
ConVar hCvarInfectRadius;
ConVar hCvarInfectLast;
ConVar hCvarInfectSingle;
ConVar hCvarInfectSticky;
ConVar hCvarInfectTrail;
ConVar hCvarInfectEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarInfectRadius = CreateConVar("zp_weapon_infectbomb_radius", "200.0", "Infection radius", 0, true, 0.0);
	hCvarInfectLast   = CreateConVar("zp_weapon_infectbomb_last", "0", "Can last human infect?", 0, true, 0.0, true, 1.0);
	hCvarInfectSingle = CreateConVar("zp_weapon_infectbomb_single", "0", "Only 1 human can be infected?", 0, true, 0.0, true, 1.0);
	hCvarInfectSticky = CreateConVar("zp_weapon_infectbomb_sticky", "0", "Sticky to walls?", 0, true, 0.0, true, 1.0);
	hCvarInfectTrail  = CreateConVar("zp_weapon_infectbomb_trail", "0", "Attach trail to the projectile?", 0, true, 0.0, true, 1.0);
	hCvarInfectEffect = CreateConVar("zp_weapon_infectbomb_effect", "explosion_hegrenade_dirt", "Particle effect for the explosion (''-default)");
	
	AutoExecConfig(true, "zp_weapon_infectbomb", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		HookEvent("tagrenade_detonate", EventEntityTanade, EventHookMode_Post);

		AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
		
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
	gWeapon = ZP_GetWeaponNameID("infect bomb");

	gSound = ZP_GetSoundKeyID("INFECT_GRENADE_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"INFECT_GRENADE_SOUNDS\" wasn't find");
	
	gType = ZP_GetClassTypeID("zombie");
	if (gType == -1) SetFailState("[ZP] Custom class type ID from name : \"zombie\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	gBeam = PrecacheModel("materials/sprites/lgtning.vmt", true);
	gHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
}

/**
 * @brief Called before show a weapon in the weapons menu.
 * 
 * @param client            The client index.
 * @param weaponID          The weapon index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
public Action ZP_OnClientValidateWeapon(int client, int weaponID)
{
	if (weaponID == gWeapon)
	{
		if (!ZP_IsGameModeInfect(ZP_GetCurrentGameMode()))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

/**
 * @brief Called after a custom grenade is created.
 *
 * @param client            The client index.
 * @param grenade           The grenade index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnGrenadeCreated(int client, int grenade, int weaponID)
{
	if (weaponID == gWeapon)
	{
		if (hCvarInfectTrail.BoolValue)
		{
			TE_SetupBeamFollow(grenade, gTrail, 0, 1.0, 10.0, 10.0, 5, WEAPON_BEAM_COLOR);
			TE_SendToAll();	
		}
	}
}

/**
 * @brief Tagrenade touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action TanadeTouchHook(int entity, int target)
{
	return hCvarInfectSticky.BoolValue ? Plugin_Continue : Plugin_Handled;
}

/**
 * Event callback (tagrenade_detonate)
 * @brief The tagrenade is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityTanade(Event hEvent, char[] sName, bool dontBroadcast) 
{
	int owner = GetClientOfUserId(hEvent.GetInt("userid")); 

	static float vPosition[3];

	int grenade = hEvent.GetInt("entityid");
	vPosition[0] = hEvent.GetFloat("x"); 
	vPosition[1] = hEvent.GetFloat("y"); 
	vPosition[2] = hEvent.GetFloat("z");

	if (IsValidEdict(grenade))
	{
		float flRadius = hCvarInfectRadius.FloatValue;
		bool bLast = hCvarInfectLast.BoolValue;
		bool bSingle = hCvarInfectSingle.BoolValue;
		
		if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)
		{
			if (ZP_IsGameModeInfect(ZP_GetCurrentGameMode()) && ZP_IsStartedRound())
			{
				int i; int it = 1; /// iterator
				while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
				{
					if (ZP_IsPlayerZombie(i))
					{
						continue;
					}

					if (!UTIL_CanSeeEachOther(grenade, i, vPosition, SelfFilter))
					{
						continue;
					}
					
					if (!bLast && ZP_GetHumanAmount() <= 1)
					{
						break;
					}

					ZP_ChangeClient(i, owner, gType);
					
					if (bSingle)
					{
						break;
					}
				}
			}

			static char sEffect[SMALL_LINE_LENGTH];
			hCvarInfectEffect.GetString(sEffect, sizeof(sEffect));
			
			if (hasLength(sEffect))
			{
				UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
			}
			else
			{
				TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, WEAPON_BEAM_COLOR, 0, 0);
				TE_SendToAll();
			}
			
			AcceptEntityInput(grenade, "Kill");

			RequestFrame(EventEntityTanadePost);
		}
	}
	
	return Plugin_Continue;
}

/**
 * Event callback (tagrenade_detonate)
 * @brief The tagrenade was exployed. (Post)
 **/
public void EventEntityTanadePost()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerExist(i) && ZP_IsPlayerHuman(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flDetectedByEnemySensorTime", ZP_IsGameModeXRay(ZP_GetCurrentGameMode()) ? (GetGameTime() + 9999.0) : 0.0);
		}
	}
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
 * @param numClients        Number of clients in the array (modify this value ifyou add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entity            Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFrags            The sound flags.
 * @param sEntry            The game sound entry name.
 * @param iSeed             The sound seed.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS], int &numClients, char sSample[PLATFORM_MAX_PATH], int &entity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFrags, char sEntry[PLATFORM_MAX_PATH], int& iSeed)
{
	if (IsValidEdict(entity))
	{
		if (GetEntProp(entity, Prop_Data, "m_iHammerID") == gWeapon)
		{
			if (!strncmp(sSample[30], "arm", 3, false))
			{
				if (ZP_GetSound(gSound, 1, sSample, sizeof(sSample)))
				{
					return Plugin_Changed; 
				}
			}
			else if (!strncmp(sSample[30], "det", 3, false))
			{
				if (ZP_GetSound(gSound, 2, sSample, sizeof(sSample)))
				{
					return Plugin_Changed; 
				}
			}
			else if (!strncmp(sSample[30], "exp", 3, false))
			{
				if (ZP_GetSound(gSound, 3, sSample, sizeof(sSample)))
				{
					return Plugin_Changed; 
				}
			}
		}
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
