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
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Zombie Class: MutationLight",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the class.
 **/
#define ZOMBIE_CLASS_SKILL_MODE         /// Uncomment to make invisible static.
#define ZOMBIE_CLASS_SKILL_RATIO        0.2 // alpha amount = speed * ratio
/**
 * @endsection
 **/

// Sound index
int gSound;
#pragma unused gSound

// Zombie index
int gZombie;
#pragma unused gZombie

// Skill states
enum
{
	STATE_NORMAL,
	STATE_INVISIBLE
};

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

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
	// Classes
	gZombie = ZP_GetClassNameID("mutationlight");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"mutationlight\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("GHOST_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"GHOST_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	// Resets visibility
	UTIL_SetRenderColor(client, Color_Alpha, 255);
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie)
	{
		// Make model invisible
		UTIL_SetRenderColor(client, Color_Alpha, 0);

		// Play sound
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
		
		// Gets client viewmodel
		int view = ZP_GetClientViewModel(client, true);
		
		// Validate entity
		if (view != -1)
		{
			// Sets body index
			SetEntProp(view, Prop_Send, "m_nBody", STATE_INVISIBLE);
		}
	}
	
	// Allow usage
	return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param client            The client index.
 **/
public void ZP_OnClientSkillOver(int client)
{
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie)
	{
		// Resets visibility
		UTIL_SetRenderColor(client, Color_Alpha, 255);

		// Play sound
		ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
		
		// Gets client viewmodel
		int view = ZP_GetClientViewModel(client, true);
		
		// Validate entity
		if (view != -1)
		{
			// Sets body index
			SetEntProp(view, Prop_Send, "m_nBody", STATE_NORMAL);
		}
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
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie && ZP_GetClientSkillUsage(client))
	{
		// Gets client viewmodel
		int view = ZP_GetClientViewModel(client, true);
		
		// Validate entity
		if (view != -1)
		{
			// Sets body index
			SetEntProp(view, Prop_Send, "m_nBody", STATE_INVISIBLE);
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
#if defined ZOMBIE_CLASS_SKILL_MODE
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie && ZP_GetClientSkillUsage(client))
	{
		// Gets client velocity
		static float vVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

		// If the zombie move, then increase alpha
		int iAlpha = RoundToNearest(GetVectorLength(vVelocity) * ZOMBIE_CLASS_SKILL_RATIO);
		
		// Make model invisible
		UTIL_SetRenderColor(client, Color_Alpha, iAlpha);
	}
	
	// Allow button
	return Plugin_Continue;
}
#endif
