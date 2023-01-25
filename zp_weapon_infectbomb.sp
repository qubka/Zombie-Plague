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
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the grenade.
 **/
#define GRENADE_INFECT_RADIUS          200.0        // Infection size (radius)
//#define GRENADE_INFECT_LAST          // Can last human infect [uncomment-no // comment-yes]
#define GRENADE_INFECT_EXP_TIME        2.0          // Duration of the explosion effect in seconds
//#define GRENADE_INFECT_ATTACH        // Will be attach to the wall [uncomment-no // comment-yes]
/**
 * @endsection
 **/
 
// Sound index and XRay vision
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Item index
int gWeapon;
#pragma unused gWeapon

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	// Validate library
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		// Hook entity events
		HookEvent("tagrenade_detonate", EventEntityTanade, EventHookMode_Post);

		// Hook server sounds
		AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
		
		// If map loaded, then run custom forward
		if (ZP_IsMapLoaded())
		{
			// Execute it
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
	// Weapons
	gWeapon = ZP_GetWeaponNameID("infect bomb");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"infect bomb\" wasn't find");

	// Sounds
	gSound = ZP_GetSoundKeyID("INFECT_GRENADE_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"INFECT_GRENADE_SOUNDS\" wasn't find");
	
	// Cvars
	hSoundLevel = FindConVar("zp_seffects_level");
	if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
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
	// Check the weapon index
	if (weaponID == gWeapon)
	{
		// Validate access
		if (!ZP_IsGameModeInfect(ZP_GetCurrentGameMode()))
		{
			return Plugin_Handled;
		}
	}

	// Allow showing
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
	// Validate custom grenade
	if (weaponID == gWeapon) /* OR if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)*/
	{
		// Hook entity callbacks
		SDKHook(grenade, SDKHook_Touch, TanadeTouchHook);
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
#if defined GRENADE_INFECT_ATTACH
	return Plugin_Continue;
#else
	return Plugin_Handled;
#endif
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
	// Gets real player index from event key
	int owner = GetClientOfUserId(hEvent.GetInt("userid")); 

	// Initialize vectors
	static float vPosition[3];

	// Gets all required event info
	int grenade = hEvent.GetInt("entityid");
	vPosition[0] = hEvent.GetFloat("x"); 
	vPosition[1] = hEvent.GetFloat("y"); 
	vPosition[2] = hEvent.GetFloat("z");

	// Validate entity
	if (IsValidEdict(grenade))
	{
		// Validate custom grenade
		if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)
		{
			// Validate infection round
			if (ZP_IsGameModeInfect(ZP_GetCurrentGameMode()) && ZP_IsStartedRound())
			{
				// Find any players in the radius
				int i; int it = 1; /// iterator
				while ((i = ZP_FindPlayerInSphere(it, vPosition, GRENADE_INFECT_RADIUS)) != -1)
				{
					// Skip zombies
					if (ZP_IsPlayerZombie(i))
					{
						continue;
					}

					// Validate visibility
					if (!UTIL_CanSeeEachOther(grenade, i, vPosition, SelfFilter))
					{
						continue;
					}

#if defined GRENADE_INFECT_LAST
					// Change class to zombie
					ZP_ChangeClient(i, owner, "zombie");
#else
					if (ZP_GetHumanAmount() > 1) ZP_ChangeClient(i, owner, "zombie");
#endif
				}
			}

			// Create an explosion effect
			UTIL_CreateParticle(_, vPosition, _, _, "explosion_hegrenade_dirt", GRENADE_INFECT_EXP_TIME);
			
			// Remove grenade
			AcceptEntityInput(grenade, "Kill");

			// Resets glow on the next frame
			RequestFrame(EventEntityTanadePost);
		}
	}
	
	// Allow event
	return Plugin_Continue;
}

/**
 * Event callback (tagrenade_detonate)
 * @brief The tagrenade was exployed. (Post)
 **/
public void EventEntityTanadePost(/*void*/)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate human
		if (IsPlayerExist(i) && ZP_IsPlayerHuman(i))
		{
			// Bugfix with tagrenade glow
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
	// Validate client
	if (IsValidEdict(entity))
	{
		// Validate custom grenade
		if (GetEntProp(entity, Prop_Data, "m_iHammerID") == gWeapon)
		{
			// Validate sound
			if (!strncmp(sSample[30], "arm", 3, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
				
				// Block sounds
				return Plugin_Stop; 
			}
			else if (!strncmp(sSample[30], "det", 3, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
				
				// Block sounds
				return Plugin_Stop; 
			}
			else if (!strncmp(sSample[30], "exp", 3, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
				
				// Block sounds
				return Plugin_Stop; 
			}
		}
	}
	
	// Allow sounds
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
