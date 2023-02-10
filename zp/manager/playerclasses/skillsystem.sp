/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          skillsystem.sp
 *  Type:          Module 
 *  Description:   Provides functions for zombie skills system.
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

/**
 * @brief Hook skills cvar changes.
 **/
void SkillSystemOnCvarInit(/*void*/)
{    
	// Creates cvars
	gCvarList.SKILL_ZOMBIE_BUTTON       = FindConVar("zp_skill_zombie_button");  
	gCvarList.SKILL_ZOMBIE_BUTTON_BLOCK = FindConVar("zp_skill_zombie_button_block");  	
	gCvarList.SKILL_HUMAN_BUTTON        = FindConVar("zp_skill_human_button");  
	gCvarList.SKILL_HUMAN_BUTTON_BLOCK  = FindConVar("zp_skill_human_button_block");  

	// Hook cvars
	HookConVarChange(gCvarList.SKILL_ZOMBIE_BUTTON, SkillSystemOnCvarHook);
	HookConVarChange(gCvarList.SKILL_HUMAN_BUTTON, SkillSystemOnCvarHook);
	
	// Load cvars
	SkillSystemOnCvarLoad();
}

/**
 * @brief Load tools listeners changes.
 **/
void SkillSystemOnCvarLoad()
{
	// Hook commands
	CreateCommandListener(gCvarList.SKILL_ZOMBIE_BUTTON, SkillSystemOnCommandListenedZombie);
	CreateCommandListener(gCvarList.SKILL_HUMAN_BUTTON, SkillSystemOnCommandListenedHuman);
}

/**
 * Cvar hook callback (zp_skill_button)
 * @brief Skills module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void SkillSystemOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	// Forward event to modules
	SkillSystemOnCvarLoad();
}

/**
 * Listener command callback (any)
 * @brief Usage of the skill for zombie.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action SkillSystemOnCommandListenedZombie(int client, char[] commandMsg, int iArguments)
{
	// Validate client 
	if (IsPlayerExist(client) && gClientData[client].Zombie)
	{
		// Do the skill
		SkillSystemOnClientStart(client);
		return gCvarList.SKILL_ZOMBIE_BUTTON_BLOCK.BoolValue ? Plugin_Handled : Plugin_Continue;
	}
	
	// Allow command
	return Plugin_Continue;
}

/**
 * Listener command callback (any)
 * @brief Usage of the skill for human.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action SkillSystemOnCommandListenedHuman(int client, char[] commandMsg, int iArguments)
{
	// Validate client 
	if (IsPlayerExist(client) && !gClientData[client].Zombie)
	{
		// Do the skill
		SkillSystemOnClientStart(client);
		return gCvarList.SKILL_HUMAN_BUTTON_BLOCK.BoolValue ? Plugin_Handled : Plugin_Continue;
	}
	
	// Allow command
	return Plugin_Continue;
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void SkillSystemOnClientUpdate(int client)
{
	// Resets variables
	gClientData[client].Skill = false;
	gClientData[client].SkillCounter = 0.0;

	// Resets the progress bar 
	ToolsSetProgressBarTime(client, 0);
	
	// If health restoring disabled, then stop
	if (!ModesIsRegen(gServerData.RoundMode))
	{
		return;
	}

	// Validate class regen interval/amount
	float flInterval = ClassGetRegenInterval(gClientData[client].Class);
	if (!flInterval || !ClassGetRegenHealth(gClientData[client].Class))
	{
		return;
	}
	
	// Sets timer for restoring health
	delete gClientData[client].HealTimer;
	gClientData[client].HealTimer = CreateTimer(flInterval, SkillSystemOnClientRegen, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief Fake client has been think.
 *
 * @param client            The client index.
 **/
void SkillSystemOnFakeClientThink(int client)
{
	// Do the skill
	SkillSystemOnClientStart(client);
}

/**
 * @brief Called when player press skill button.
 *
 * @param client            The client index.
 **/
void SkillSystemOnClientStart(int client)
{
	// If skill disabled, then stop
	if (!ModesIsSkill(gServerData.RoundMode))
	{
		return;
	}
	
	// Validate class skill duration/countdown
	float flInterval = ClassGetSkillDuration(gClientData[client].Class);
	if (!flInterval && (!ClassGetSkillCountdown(gClientData[client].Class)))
	{
		return;
	}

	// Verify that the skills are avalible
	if (!gClientData[client].Skill && gClientData[client].SkillCounter <= 0.0)
	{
		// Call forward
		Action hResult; 
		gForwardData._OnClientSkillUsed(client, hResult);
		
		// Block skill usage
		if (hResult == Plugin_Handled || hResult == Plugin_Stop)
		{
			return;
		}

		// Sets skill usage
		gClientData[client].Skill = true;
		
		// Validate skill bar
		if (ClassIsSkillBar(gClientData[client].Class))
		{
			// Sets progress bar 
			ToolsSetProgressBarTime(client, RoundToNearest(flInterval));
		}
		
		// Validate skill cost
		int iCost = ClassGetSkillCost(gClientData[client].Class);
		if (iCost)
		{
			// Apply damage but not critical
			ToolsSetHealth(client, max(ToolsGetHealth(client) - iCost, 1));
		}
		
		// Sets timer for removing skill usage
		delete gClientData[client].SkillTimer;
		gClientData[client].SkillTimer = CreateTimer(flInterval, SkillSystemOnClientEnd, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * @brief Timer callback, remove a skill usage.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillSystemOnClientEnd(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Clear timer
	gClientData[client].SkillTimer = null;
	
	// Validate client
	if (client)
	{
		// Remove skill usage and set countdown time
		gClientData[client].Skill = false;
		gClientData[client].SkillCounter = ClassGetSkillCountdown(gClientData[client].Class);
		
		// Resets the progress bar 
		ToolsSetProgressBarTime(client, 0);
		
		// Sets timer for countdown
		delete gClientData[client].CounterTimer;
		gClientData[client].CounterTimer = CreateTimer(1.0, SkillSystemOnClientCount, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		// Call forward
		gForwardData._OnClientSkillOver(client);
	}

	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Timer callback, the skill countdown.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillSystemOnClientCount(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Validate client
	if (client)
	{
		// Substitute counter
		gClientData[client].SkillCounter--;
		
		// If counter is over, then stop
		if (gClientData[client].SkillCounter <= 0.0)
		{
			// Show message
			TranslationPrintHintText(client, "skill ready");

			// Clear timer
			gClientData[client].CounterTimer = null;
			
			// Destroy timer
			return Plugin_Stop;
		}

		// Show counter
		TranslationPrintHintText(client, "skill countdown", RoundToNearest(gClientData[client].SkillCounter));
		
		// Allow timer
		return Plugin_Continue;
	}
	
	// Clear timer
	gClientData[client].CounterTimer = null;
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Timer callback, restore a player health.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillSystemOnClientRegen(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Validate client
	if (client)
	{
		// Gets client velocity
		static float vVelocity[3];
		ToolsGetVelocity(client, vVelocity);
		
		// If the client don't move, then check health
		if (GetVectorLength(vVelocity) <= 0.0)
		{
			// If restoring is available, then do it
			int iHealth = ToolsGetHealth(client); // Store for next usage
			if (iHealth < ClassGetHealth(gClientData[client].Class))
			{
				// Initialize a new health amount
				int iRegen = iHealth + ClassGetRegenHealth(gClientData[client].Class);
				
				// If new health more, than set default class health
				if (iRegen > ClassGetHealth(gClientData[client].Class))
				{
					iRegen = ClassGetHealth(gClientData[client].Class);
				}
				
				// Update health
				ToolsSetHealth(client, iRegen);

				// Forward event to modules
				SoundsOnClientRegen(client);
				VEffectsOnClientRegen(client);
			}
		}

		// Allow timer
		return Plugin_Continue;
	}

	// Clear timer
	gClientData[client].HealTimer = null;
	
	// Destroy timer
	return Plugin_Stop;
}

/*
 * Skill system natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void SkillSystemOnNativeInit(/*void*/)
{
	CreateNative("ZP_GetClientSkillUsage",     API_GetClientSkillUsage);
	CreateNative("ZP_GetClientSkillCountdown", API_GetClientSkillCountdown);
	CreateNative("ZP_ResetClientSkill",        API_ResetClientSkill);
}

/**
 * @brief Gets the player skill state.
 *
 * @note native bool ZP_GetClientSkillUsage(client);
 **/
public int API_GetClientSkillUsage(Handle hPlugin, int iNumParams)
{
	// Gets real player index from native cell 
	int client = GetNativeCell(1);

	// Return the value
	return gClientData[client].Skill;
}

/**
 * @brief Gets the player skill countdown.
 *
 * @note native float ZP_GetClientSkillCountdown(client);
 **/
public int API_GetClientSkillCountdown(Handle hPlugin, int iNumParams)
{
	// Gets real player index from native cell 
	int client = GetNativeCell(1);

	// Return the value (Float fix)
	return view_as<int>(gClientData[client].SkillCounter);
}

/**
 * @brief Stop the player skill or countdown. 
 *
 * @note native void ZP_ResetClientSkill(client);
 **/
public int API_ResetClientSkill(Handle hPlugin, int iNumParams)
{
	// Gets real player index from native cell 
	int client = GetNativeCell(1);
	
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Classes, "Native Validation", "Invalid the client index (%d)", client);
		return 0;
	}
	
	// Resets the values
	delete gClientData[client].SkillTimer;
	delete gClientData[client].CounterTimer;
	gClientData[client].Skill = false;
	gClientData[client].SkillCounter = 0.0;
	
	// Validate skill bar
	if (ClassIsSkillBar(gClientData[client].Class))
	{
		// Resets the progress bar 
		ToolsSetProgressBarTime(client, 0);
	}
	
	return 0;
}
