/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          playertools.cpp
 *  Type:          Game 
 *  Description:   Useful stocks.
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
 * Creates commands for tools module. Called when commands are created.
 **/
void ToolsOnCommandsCreate(/*void*/)
{
	// Hook commands
	AddCommandListener(ToolsHook, "+lookatweapon");
}

/**
 * Hook client command.
 *
 * @param clientIndex		The client index.
 * @param commandMsg		Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments		Argument count.
 **/
public Action ToolsHook(int clientIndex, const char[] commandMsg, int iArguments)
{
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);
	
	// Validate client 
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return ACTION_HANDLED;
	}
	
	// If zombie's nightvision ?
	if(cBasePlayer->m_bZombie)
	{
		// If nightvision is disabled, then stop
		if(!gCvarList[CVAR_ZOMBIE_NIGHT_VISION])
		{
			return ACTION_HANDLED;
		}
		
		// Switch on/off nightvision
		cBasePlayer->m_bNightVisionOn = !cBasePlayer->m_bNightVisionOn;
	}
	
	// If human's flashlight ?
	else
	{
		// Switch on/off flashlight
		cBasePlayer->m_bFlashLightOn(true);
		
		// Emit sound
		cBasePlayer->InputEmitAISound(SNDCHAN_VOICE, SNDLEVEL_LIBRARY, "FLASH_LIGHT_SOUNDS");
	}
	
	// Block command
	return ACTION_HANDLED;
}

/**
 * Reset all values.
 *
 * @param clientIndex		The client index.
 **/
void ToolsResetVars(int clientIndex)
{
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Reset all variables
	cBasePlayer->m_bZombie 				= false;
	cBasePlayer->m_bSurvivor 			= false;
	cBasePlayer->m_bNemesis 			= false;
	cBasePlayer->m_bSkill		 		= false;
	cBasePlayer->m_nSkillCountDown 		= 0;
	cBasePlayer->m_nZombieClass 		= 0;
	cBasePlayer->m_nZombieNext 			= 0;
	cBasePlayer->m_nHumanClass 			= 0;
	cBasePlayer->m_nHumanNext 			= 0;
	cBasePlayer->m_bRespawn 		 	= TEAM_HUMAN;
	cBasePlayer->m_nRespawnTimes 		= 0;
	cBasePlayer->m_nAmmoPacks 			= 0;
	cBasePlayer->m_nLastBoughtAmount 	= 0;
	cBasePlayer->m_iLevel 				= 0;
	cBasePlayer->m_iExp 				= 0;

	// Reset all timers
	ToolsResetTimers(cBasePlayer);
}

/**
 * Respawn a player.
 *
 * @param cBasePlayer		The client index.
 **/
void ToolsForceToRespawn(CBasePlayer* cBasePlayer)
{
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index, false))
	{
		return;
	}
	
	// Verify that the client is dead
	if(IsPlayerAlive(cBasePlayer->Index))
	{
		return;
	}
	
	// Respawn as human ?
	if(GetConVarInt(gCvarList[CVAR_RESPAWN_DEATHMATCH]) == 1 || (GetConVarInt(gCvarList[CVAR_RESPAWN_DEATHMATCH]) == 2 && GetRandomInt(0, 1)) || (GetConVarInt(gCvarList[CVAR_RESPAWN_DEATHMATCH]) == 3 && fnGetHumans() < fnGetAlive() / 2))
	{
		cBasePlayer->m_bRespawn = TEAM_HUMAN;
	}
	
	// Respawn as zombie ?
	else
	{
		cBasePlayer->m_bRespawn = TEAM_ZOMBIE;
	}
	
	// Override respawn as zombie setting on nemesis and survivor rounds
	if(gServerData[Server_RoundMode] == GameModes_Survivor) cBasePlayer->m_bRespawn = TEAM_ZOMBIE;
	else if(gServerData[Server_RoundMode] == GameModes_Nemesis) cBasePlayer->m_bRespawn = TEAM_HUMAN;
	
	// Respawn a player
	cBasePlayer->m_iRespawnPlayer();
}

/**
 * Reset all player's timer.
 *
 * @param cBasePlayer		The client index.
 **/
void ToolsResetTimers(CBasePlayer* cBasePlayer)
{
	delete cBasePlayer->m_hZombieRespawnTimer;
	delete cBasePlayer->m_hZombieSkillTimer;
}