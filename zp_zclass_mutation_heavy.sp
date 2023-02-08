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
	name            = "[ZP] Zombie Class: MutationHeavy",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Timer index
Handle hHumanTrapped[MAXPLAYERS+1] = { null, ... }; bool bStandOnTrap[MAXPLAYERS+1];

// Sound index
int gSound;
 
// Zombie index
int gZombie;

// Cvars
ConVar hCvarSkillReward;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	hCvarSkillReward = CreateConVar("zp_zclass_mutation_heavy_reward", "10", "Catch reward", 0, true, 0.0);

	// Generate config
	AutoExecConfig(true, "zp_zclass_mutation_heavy", "sourcemod/zombieplague");
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
		// Load translations phrases used by plugin
		LoadTranslations("mutation_heavy.phrases");

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
	gZombie = ZP_GetClassNameID("mutationheavy");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"mutationheavy\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("TRAP_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"TRAP_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Purge timer
		hHumanTrapped[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
	}
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	// Delete timer
	delete hHumanTrapped[client];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	// Delete timer
	delete hHumanTrapped[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	// Resets move
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	// Delete timer
	delete hHumanTrapped[client];
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
		// Validate place
		if (bStandOnTrap[client])
		{
			bStandOnTrap[client] = false; /// To avoid placing trap on the trap
			return Plugin_Handled;
		}
		
		// Show message
		SetGlobalTransTarget(client);
		PrintHintText(client, "%t", "mutationheavy set");
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
		// Initialize vectors
		static float vPosition[3]; static float vAngle[3];
		
		// Gets client position/angles
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
		GetClientEyeAngles(client, vAngle); vAngle[0] = vAngle[2] = 0.0; /// Only pitch

		// Create a physics entity
		int entity = UTIL_CreatePhysics("trap", vPosition, vAngle, "models/player/custom_player/zombie/ice/ice.mdl", PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);

		// Validate entity
		if (entity != -1)
		{
			// Sets physics
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
			SetEntProp(entity, Prop_Data, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER); /// Make trigger
			SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);

			// Create a prop_dynamic entity
			int trap = UTIL_CreateDynamic("trap", vPosition, vAngle, "models/player/custom_player/zombie/zombie_trap/trap.mdl", "idle", false);
			
			// Validate entity
			if (trap != -1)
			{
				// Sets parent to the entity
				SetVariantString("!activator");
				AcceptEntityInput(trap, "SetParent", entity, trap);

				// Sets owner to the entity
				SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", trap); /// Store for animating
				
				// Create transmit hook
				SDKHook(trap, SDKHook_SetTransmit, TrapTransmitHook);
			}
			
			// Sets owner to the entity
			SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 

			// Sets an entity color
			UTIL_SetRenderColor(entity, Color_Alpha, 0);
			AcceptEntityInput(entity, "DisableShadow"); /// Prevents the entity from receiving shadows
			
			// Play sound
			ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC, SNDLEVEL_SKILL);
			
			// Create touch hook
			SDKHook(entity, SDKHook_Touch, TrapTouchHook);
		}
		
		// Show message
		SetGlobalTransTarget(client);
		PrintHintText(client, "%t", "mutationheavy success");
	}
}

/**
 * @brief Trap touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action TrapTouchHook(int entity, int target)
{
	// Validate target
	if (IsPlayerExist(target))
	{
		// Validate human
		if (ZP_IsPlayerHuman(target) && GetEntityMoveType(target) != MOVETYPE_NONE)
		{
			// Initialize vectors
			static float vPosition[3]; static float vAngle[3];

			// Gets victim origin/angle
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPosition);
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);
			
			// Teleport the entity
			TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);

			// Trap the client
			SetEntityMoveType(target, MOVETYPE_NONE);

			// Gets skill duration
			float flDuration = ZP_GetClassSkillDuration(gZombie);

			// Create timer for removing freezing
			delete hHumanTrapped[target];
			hHumanTrapped[target] = CreateTimer(flDuration, ClientRemoveTrapEffect, GetClientUserId(target), TIMER_FLAG_NO_MAPCHANGE);

			// Play sound
			ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, SNDLEVEL_NORMAL);

			// Show message
			SetGlobalTransTarget(target);
			PrintHintText(target, "%t", "mutationheavy catch");
			
			// Gets owner index
			int owner = GetEntPropEnt(entity, Prop_Data, "m_pParent");

			// Validate owner
			if (IsPlayerExist(owner, false))
			{
				// Gets target name
				static char sName[NORMAL_LINE_LENGTH];
				GetClientName(target, sName, sizeof(sName));
		
				// Show message
				SetGlobalTransTarget(owner);
				PrintHintText(owner, "%t", "mutationheavy catched", sName);
				
				// Give reward
				ZP_SetClientMoney(owner, ZP_GetClientMoney(owner) + hCvarSkillReward.IntValue);
			}

			// Gets trap model 
			int trapIndex = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

			// Validate entity
			if (trapIndex != -1)
			{
				// Play animation of the model
				SetVariantString("trap");
				AcceptEntityInput(trapIndex, "SetAnimation");
				
				// Remove transmit hook
				SDKUnhook(trapIndex, SDKHook_SetTransmit, TrapTransmitHook);
			}

			// Kill after some duration
			UTIL_RemoveEntity(entity, flDuration);
			
			// Remove touch hook
			SDKUnhook(entity, SDKHook_Touch, TrapTouchHook);
		}
		// Validate zombie
		else if (ZP_IsPlayerZombie(target)) bStandOnTrap[target] = true; /// Resets installing here!
	}

	// Return on the success
	return Plugin_Continue;
}

/**
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entity            The entity index.
 * @param client            The client index.
 **/
public Action TrapTransmitHook(int entity, int client)
{
	// Validate human
	if (ZP_IsPlayerHuman(client))
	{
		// Block transmitting
		return Plugin_Handled;
	}

	// Allow transmitting
	return Plugin_Continue;
}

/**
 * @brief Timer for remove trap effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveTrapEffect(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);
	
	// Clear timer 
	hHumanTrapped[client] = null;

	// Validate client
	if (client)
	{    
		// Untrap the client
		SetEntityMoveType(client, MOVETYPE_WALK);
	}

	// Destroy timer
	return Plugin_Stop;
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
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie && ZP_GetClientSkillUsage(client))
	{
		// Gets client velocity
		static float vVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

		// If the zombie move, then reset skill
		if (GetVectorLength(vVelocity) > 0.0)
		{
			// Resets skill
			ZP_ResetClientSkill(client);
			
			// Show message
			SetGlobalTransTarget(client);
			PrintHintText(client, "%t", "mutationheavy cancel");
		}
	}
	
	// Allow button
	return Plugin_Continue;
}