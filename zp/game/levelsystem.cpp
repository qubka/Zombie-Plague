/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          levelsystem.cpp
 *  Type:          Game 
 *  Description:   Provides functions for level system.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/
 
/**
 * Number of max valid levels.
 **/
#define LevelSystemMax 100

/**
 * Arrays to store the level's data.
 **/
int  LevelSystemNum;
static char LevelSystemStats[LevelSystemMax][SMALL_LINE_LENGTH];
 
/**
 * Prepare all level data.
 **/
void LevelSystemLoad()
{
	// Reset level's data
	LevelSystemNum = 0;

	// If level system disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]))
	{
		return;
	}
	
	// Initialize level list
	static char sList[PLATFORM_MAX_PATH];
	GetConVarString(gCvarList[CVAR_LEVEL_STATISTICS], sList, sizeof(sList));

	// Check iflist is empty, then skip
	if(strlen(sList))
	{
		// Convert list string to pieces
		LevelSystemNum = ExplodeString(sList, ",", LevelSystemStats, sizeof(LevelSystemStats), sizeof(LevelSystemStats[])) - 1;

		// Loop throught pieces
		for(int i = 0; i <= LevelSystemNum; i++)
		{
			// Trim string
			TrimString(LevelSystemStats[i]);
		}
		
		// Create timer
		if(LevelSystemNum) CreateTimer(1.0, LevelSystemHUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Validate the client's level and prevent it from overloading.
 *
 * @param cBasePlayer    	The client index.
 **/
void LevelSystemOnValidate(CBasePlayer* cBasePlayer)
{
	// If level system disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]))
	{
		return;
	}
	
	// Validate level amount
	if(!LevelSystemNum)
	{
		return;
	}
	
	// Validate level
	if(cBasePlayer->m_iLevel > LevelSystemNum)
	{
		// Update it
		cBasePlayer->m_iLevel = LevelSystemNum;
	}
}

/**
 * Validate the client's experience, increasing level ifit reach level's experience limit and prevent it from overloading.
 *
 * @param cBasePlayer    	The client index.
 **/
void LevelSystemOnValidateExp(CBasePlayer* cBasePlayer)
{
	// If level system disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]))
	{
		return;
	}
	
	// Validate level amount
	if(!LevelSystemNum)
	{
		return;
	}
	
	// Give experience to the player
	if(cBasePlayer->m_iLevel == LevelSystemNum && cBasePlayer->m_iExp > StringToInt(LevelSystemStats[cBasePlayer->m_iLevel]))
	{
		cBasePlayer->m_iExp = StringToInt(LevelSystemStats[cBasePlayer->m_iLevel]);
	}
	else
	{
		// Loop throught experience
		while(cBasePlayer->m_iLevel < LevelSystemNum && cBasePlayer->m_iExp >= StringToInt(LevelSystemStats[cBasePlayer->m_iLevel]))
		{
			// Increase level
			cBasePlayer->m_iLevel++;
			
			// Emit levelup sound
			if(IsPlayerExist(cBasePlayer->Index)) cBasePlayer->InputEmitAISound(SNDCHAN_STATIC, SNDLEVEL_NORMAL, "LEVEL_UP_SOUNDS");
		}
	}
}

/**
 * Main timer for show HUD text within information about client's level and experience.
 *
 * @param hTimer			The timer handle.
 **/
public Action LevelSystemHUD(Handle hTimer)
{
	// Initialize variables
	CBasePlayer* cBasePlayer;
	
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Get real player index from event key
		cBasePlayer = CBasePlayer(i);
		
		// Verify that the client is exist
		if(!IsPlayerExist(cBasePlayer->Index))
		{
			continue;
		}
		
		// Print hud text to client
		TranslationPrintHudText(cBasePlayer->Index, 0.02, 0.9, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0, "Level info", cBasePlayer->m_iLevel, cBasePlayer->m_iExp, LevelSystemStats[cBasePlayer->m_iLevel]);
	}
}