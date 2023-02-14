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
	hCvarSkillReward = CreateConVar("zp_zclass_mutation_heavy_reward", "10", "Catch reward", 0, true, 0.0);

	AutoExecConfig(true, "zp_zclass_mutation_heavy", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		LoadTranslations("mutation_heavy.phrases");

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
	gZombie = ZP_GetClassNameID("mutationheavy");
	
	gSound = ZP_GetSoundKeyID("TRAP_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"TRAP_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
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
	SetEntityMoveType(client, MOVETYPE_WALK);
	
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
	if (ZP_GetClientClass(client) == gZombie)
	{
		if (bStandOnTrap[client])
		{
			bStandOnTrap[client] = false; /// To avoid placing trap on the trap
			return Plugin_Handled;
		}
		
		SetGlobalTransTarget(client);
		PrintHintText(client, "%t", "mutationheavy set");
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
		static float vPosition[3]; static float vAngle[3];
		
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
		GetClientEyeAngles(client, vAngle); vAngle[0] = vAngle[2] = 0.0; /// Only pitch

		int entity = UTIL_CreatePhysics("trap", vPosition, vAngle, "models/player/custom_player/zombie/ice/ice.mdl", PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);

		if (entity != -1)
		{
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
			SetEntProp(entity, Prop_Data, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER); /// Make trigger
			SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
			
			SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_NO);

			int trap = UTIL_CreateDynamic("trap", vPosition, vAngle, "models/player/custom_player/zombie/zombie_trap/trap.mdl", "idle", false);
			
			if (trap != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(trap, "SetParent", entity, trap);

				SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", trap); /// Store for animating
				
				SDKHook(trap, SDKHook_SetTransmit, TrapTransmitHook);
			}
			
			SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 

			//UTIL_SetRenderColor(entity, Color_Alpha, 0);
			AcceptEntityInput(entity, "DisableDraw"); 
			AcceptEntityInput(entity, "DisableShadow"); /// Prevents the entity from receiving shadows
			
			ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC, SNDLEVEL_SKILL);
			
			SDKHook(entity, SDKHook_Touch, TrapTouchHook);
		}
		
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
	if (IsPlayerExist(target))
	{
		if (ZP_IsPlayerHuman(target) && GetEntityMoveType(target) != MOVETYPE_NONE)
		{
			static float vPosition[3]; static float vAngle[3];

			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPosition);
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);
			
			TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);

			SetEntityMoveType(target, MOVETYPE_NONE);

			float flDuration = ZP_GetClassSkillDuration(gZombie);

			ZP_SetProgressBarTime(target, RoundToNearest(flDuration));
			
			UTIL_CreateFadeScreen(target, 0.3, flDuration / 2.0, FFADE_IN, {200, 80, 80, 75});  

			delete hHumanTrapped[target];
			hHumanTrapped[target] = CreateTimer(flDuration, ClientRemoveTrap, GetClientUserId(target), TIMER_FLAG_NO_MAPCHANGE);

			ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, SNDLEVEL_NORMAL);

			SetGlobalTransTarget(target);
			PrintHintText(target, "%t", "mutationheavy catch");
			
			int owner = GetEntPropEnt(entity, Prop_Data, "m_pParent");

			if (IsPlayerExist(owner, false))
			{
				static char sName[NORMAL_LINE_LENGTH];
				GetClientName(target, sName, sizeof(sName));
		
				SetGlobalTransTarget(owner);
				PrintHintText(owner, "%t", "mutationheavy catched", sName);
				
				ZP_SetClientMoney(owner, ZP_GetClientMoney(owner) + hCvarSkillReward.IntValue);
			}

			int trapIndex = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

			if (trapIndex != -1)
			{
				SetVariantString("trap");
				AcceptEntityInput(trapIndex, "SetAnimation");
				
				SDKUnhook(trapIndex, SDKHook_SetTransmit, TrapTransmitHook);
			}

			UTIL_RemoveEntity(entity, flDuration);
			
			SDKUnhook(entity, SDKHook_Touch, TrapTouchHook);
		}
		else if (ZP_IsPlayerZombie(target)) bStandOnTrap[target] = true; /// Resets installing here!
	}

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
	if (ZP_IsPlayerHuman(client))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/**
 * @brief Timer for remove trap.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveTrap(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);
	
	hHumanTrapped[client] = null;

	if (client)
	{    
		SetEntityMoveType(client, MOVETYPE_WALK);
		
		ZP_SetProgressBarTime(client, 0);
	}

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
	if (ZP_GetClientClass(client) == gZombie && ZP_GetClientSkillUsage(client))
	{
		static float vVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

		if (GetVectorLength(vVelocity) > 0.0)
		{
			ZP_ResetClientSkill(client);
			
			SetGlobalTransTarget(client);
			PrintHintText(client, "%t", "mutationheavy cancel");
		}
	}
	
	return Plugin_Continue;
}