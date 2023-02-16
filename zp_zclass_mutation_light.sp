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
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Invisible state
bool bInvisible[MAXPLAYERS+1];

// Sound index
int gSound;

// Zombie index
int gZombie;

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
	gZombie = ZP_GetClassNameID("mutationlight");
	
	gSound = ZP_GetSoundKeyID("GHOST_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"GHOST_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	bInvisible[client] = false;
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	if (bInvisible[client])
	{
		AcceptEntityInput(client, "EnableDraw"); 
		AcceptEntityInput(client, "EnableShadow");
		
		bInvisible[client] = false;
	}
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	if (bInvisible[client])
	{
		AcceptEntityInput(client, "EnableDraw"); 
		AcceptEntityInput(client, "EnableShadow");
		
		bInvisible[client] = false;
	}
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
	if (ZP_GetClientClass(client) == gZombie)
	{
		AcceptEntityInput(client, "DisableDraw"); 
		AcceptEntityInput(client, "DisableShadow");
		
		bInvisible[client] = true;

		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
		
		int view = ZP_GetClientViewModel(client, true);
		
		if (view != -1)
		{
			SetEntProp(view, Prop_Send, "m_nBody", STATE_INVISIBLE);
		}
	}
	
	return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param client            The client index.
 **/
public void ZP_OnClientSkillOver(int client)
{
	if (ZP_GetClientClass(client) == gZombie)
	{
		AcceptEntityInput(client, "EnableDraw"); 
		AcceptEntityInput(client, "EnableShadow");
		
		bInvisible[client] = false;

		ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
		
		int view = ZP_GetClientViewModel(client, true);
		
		if (view != -1)
		{
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
	if (ZP_GetClientClass(client) == gZombie && ZP_GetClientSkillUsage(client))
	{
		int view = ZP_GetClientViewModel(client, true);
		
		if (view != -1)
		{
			SetEntProp(view, Prop_Send, "m_nBody", STATE_INVISIBLE);
		}
	}
}