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
void SkillSystemOnCvarInit()
{    
	gCvarList.SKILL_ZOMBIE_BUTTON       = FindConVar("zp_skill_zombie_button");  
	gCvarList.SKILL_ZOMBIE_BUTTON_BLOCK = FindConVar("zp_skill_zombie_button_block");  	
	gCvarList.SKILL_HUMAN_BUTTON        = FindConVar("zp_skill_human_button");  
	gCvarList.SKILL_HUMAN_BUTTON_BLOCK  = FindConVar("zp_skill_human_button_block");  

	HookConVarChange(gCvarList.SKILL_ZOMBIE_BUTTON, SkillSystemOnCvarHook);
	HookConVarChange(gCvarList.SKILL_HUMAN_BUTTON, SkillSystemOnCvarHook);
	
	SkillSystemOnCvarLoad();
}

/**
 * @brief Load tools listeners changes.
 **/
void SkillSystemOnCvarLoad()
{
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
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
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
	if (IsPlayerExist(client) && gClientData[client].Zombie)
	{
		SkillSystemOnClientStart(client);
		return gCvarList.SKILL_ZOMBIE_BUTTON_BLOCK.BoolValue ? Plugin_Handled : Plugin_Continue;
	}
	
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
	if (IsPlayerExist(client) && !gClientData[client].Zombie)
	{
		SkillSystemOnClientStart(client);
		return gCvarList.SKILL_HUMAN_BUTTON_BLOCK.BoolValue ? Plugin_Handled : Plugin_Continue;
	}
	
	return Plugin_Continue;
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void SkillSystemOnClientUpdate(int client)
{
	gClientData[client].Skill = false;
	gClientData[client].SkillCounter = 0.0;

	ToolsSetProgressBarTime(client, 0);
	
	if (!ModesIsRegen(gServerData.RoundMode))
	{
		return;
	}

	float flInterval = ClassGetRegenInterval(gClientData[client].Class);
	if (!flInterval || !ClassGetRegenHealth(gClientData[client].Class))
	{
		return;
	}
	
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
	SkillSystemOnClientStart(client);
}

/**
 * @brief Called when player press skill button.
 *
 * @param client            The client index.
 **/
void SkillSystemOnClientStart(int client)
{
	if (!ModesIsSkill(gServerData.RoundMode))
	{
		return;
	}
	
	float flInterval = ClassGetSkillDuration(gClientData[client].Class);
	if (!flInterval && (!ClassGetSkillCountdown(gClientData[client].Class)))
	{
		return;
	}

	if (!gClientData[client].Skill && gClientData[client].SkillCounter <= 0.0)
	{
		Action hResult; 
		gForwardData._OnClientSkillUsed(client, hResult);
		
		if (hResult == Plugin_Handled || hResult == Plugin_Stop)
		{
			return;
		}

		gClientData[client].Skill = true;
		
		if (ClassIsSkillBar(gClientData[client].Class))
		{
			ToolsSetProgressBarTime(client, RoundToNearest(flInterval));
		}
		
		int iCost = ClassGetSkillCost(gClientData[client].Class);
		if (iCost)
		{
			ToolsSetHealth(client, max(ToolsGetHealth(client) - iCost, 1));
		}
		
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
	int client = GetClientOfUserId(userID);

	gClientData[client].SkillTimer = null;
	
	if (client)
	{
		gClientData[client].Skill = false;
		gClientData[client].SkillCounter = ClassGetSkillCountdown(gClientData[client].Class);
		
		ToolsSetProgressBarTime(client, 0);
		
		delete gClientData[client].CounterTimer;
		gClientData[client].CounterTimer = CreateTimer(1.0, SkillSystemOnClientCount, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		gForwardData._OnClientSkillOver(client);
	}

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
	int client = GetClientOfUserId(userID);

	if (client)
	{
		gClientData[client].SkillCounter--;
		
		if (gClientData[client].SkillCounter <= 0.0)
		{
			TranslationPrintHintText(client, "skill ready");

			gClientData[client].CounterTimer = null;
			
			return Plugin_Stop;
		}

		TranslationPrintHintText(client, "skill countdown", RoundToNearest(gClientData[client].SkillCounter));
		
		return Plugin_Continue;
	}
	
	gClientData[client].CounterTimer = null;
	
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
	int client = GetClientOfUserId(userID);

	if (client)
	{
		static float vVelocity[3];
		ToolsGetVelocity(client, vVelocity);
		
		if (GetVectorLength(vVelocity) <= 0.0)
		{
			int iHealth = ToolsGetHealth(client); // Store for next usage
			if (iHealth < ClassGetHealth(gClientData[client].Class))
			{
				int iRegen = iHealth + ClassGetRegenHealth(gClientData[client].Class);
				
				if (iRegen > ClassGetHealth(gClientData[client].Class))
				{
					iRegen = ClassGetHealth(gClientData[client].Class);
				}
				
				ToolsSetHealth(client, iRegen);

				SoundsOnClientRegen(client);
				VEffectsOnClientRegen(client);
			}
		}

		return Plugin_Continue;
	}

	gClientData[client].HealTimer = null;
	
	return Plugin_Stop;
}

/*
 * Skill system natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void SkillSystemOnNativeInit()
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
	int client = GetNativeCell(1);

	return gClientData[client].Skill;
}

/**
 * @brief Gets the player skill countdown.
 *
 * @note native float ZP_GetClientSkillCountdown(client);
 **/
public int API_GetClientSkillCountdown(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	return view_as<int>(gClientData[client].SkillCounter);
}

/**
 * @brief Stop the player skill or countdown. 
 *
 * @note native void ZP_ResetClientSkill(client);
 **/
public int API_ResetClientSkill(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	
	if (!IsPlayerExist(client, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Skills, "Native Validation", "Invalid the client index (%d)", client);
		return 0;
	}
	
	delete gClientData[client].SkillTimer;
	delete gClientData[client].CounterTimer;
	gClientData[client].Skill = false;
	gClientData[client].SkillCounter = 0.0;
	
	if (ClassIsSkillBar(gClientData[client].Class))
	{
		ToolsSetProgressBarTime(client, 0);
	}
	
	return 0;
}
