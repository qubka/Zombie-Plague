/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          gamemodes.cpp
 *  Type:          Core
 *  Description:   Select mode types.
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
 * Validation of the knife weapon.
 **/
#define	GameModesValidateInfection(%0) (%0 == GameModes_Infection || %0 == GameModes_Multi)
 
/**
 * Game modes.
 **/
enum /*<GameModesType>*/
{
	GameModes_None 			= -1, 	/** Used as return value when an mode didn't start */
	
	GameModes_Infection,			/** Normal infection */
	GameModes_Multi,				/** Multi infection */
	GameModes_Swarm,				/** Swarm mode */
	GameModes_Nemesis,				/** Nemesis round */
	GameModes_Survivor,				/** Survivor round */
	GameModes_Armageddon			/** Armageddon round */
};

/*
 * Some game servers do not hook events during hibernation,
 * so initialize them some of them on the first map start.
 */

/**
 * Load game modes data.
 **/
void GameModesLoad(/*void*/)
{
	// Forward event to modules (Fake)
	RoundStartOnRoundPreStart();
	RoundStartOnRoundStart();
	
	// Create timer for starting game mode
	CreateTimer(1.0, GameModesStart, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Main timer for start zombie round.
 *
 * @param hTimer			The timer handle.
 **/
public Action GameModesStart(Handle hTimer)
{
	// If gamemodes disabled, then stop
	if(!GetConVarInt(gCvarList[CVAR_GAME_CUSTOM_START]))
	{
		return ACTION_STOP;
	}
	
	// If round didn't start yet
	if(gServerData[Server_RoundNew])
	{
		// Get amount of total alive players
		int nAlive = fnGetAlive();

		// Switch amount of alive players
		switch(nAlive)
		{
			// Wait other players
			case 0, 1 : { /*void*/ }
			
			// If players exists
			default : 							
			{
				// If counter is counting ?
				if(gServerData[Server_RoundCount])
				{
					// If help messages enabled
					if(GetConVarBool(gCvarList[CVAR_MESSAGES_HELP]) && gServerData[Server_RoundCount] == (GetConVarInt(gCvarList[CVAR_GAME_CUSTOM_START]) - 2))
					{
						// Show help information
						TranslationPrintToChatAll("General round objective");
						TranslationPrintHintTextAll("General buttons reminder");
					}

					// Show counter message
					if(gServerData[Server_RoundCount] <= 20)
					{
						// Play counter sounds
						if(1 <= gServerData[Server_RoundCount] <= 10) SoundsInputEmitToAll("ROUND_COUNTER_SOUNDS", gServerData[Server_RoundCount]);
						
						// Player round start sounds
						if(gServerData[Server_RoundCount] == 20) SoundsInputEmitToAll("ROUND_START_SOUNDS");
						
						// Initialize string and format it
						TranslationPrintHintTextAll("Zombie comming", gServerData[Server_RoundCount]);
					}
				}
				
				// If else, than start game
				else 
				{
					GameModesEventStart(GameModes_None);
				}
				
				// Substitute second
				gServerData[Server_RoundCount]--;
			}
		}
	}

	// If not, then wait
	return ACTION_CONTINUE;
}

/**
 * Called right before mode is started.
 *
 * @param modeIndex			The mod index. 
 * @param clientIndex		(Optional) The client index.
 **/
void GameModesEventStart(int modeIndex, int clientIndex = 0)
{
	// Get real player index from event key
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);
	
	// Get amount of total alive players
	int nAlive = fnGetAlive();
	
	// Initialize max amount of zombies 
	int nMaxZombies;

	// Mode fully started
	gServerData[Server_RoundNew] 	= false;
	gServerData[Server_RoundEnd] 	= false;
	gServerData[Server_RoundStart] 	= true;

	// Initialize last round index
	static int lastRound;
	
	if(modeIndex == GameModes_None && lastRound != GameModes_Multi && GetRandomInt(1, GetConVarInt(gCvarList[CVAR_MODE_MULTI_CHANCE])) == GetConVarInt(gCvarList[CVAR_MODE_MULTI]) && nAlive > GetConVarInt(gCvarList[CVAR_MODE_MULTI_MIN]) || modeIndex == GameModes_Multi)
	{
		// Show mod info
		nMaxZombies = RoundToCeil(nAlive * GetConVarFloat(gCvarList[CVAR_MODE_MULTI_RATIO]));
		TranslationPrintHintTextAll("Multi mode");
		gServerData[Server_RoundMode] = GameModes_Multi;
		
		// Make random zombies
		GameModesTurnIntoZombies(cBasePlayer, nMaxZombies, nAlive);
		
		// Player game round sounds
		SoundsInputEmitToAll("ROUND_MULTI_SOUNDS");
	}
	
	else if(modeIndex == GameModes_None && lastRound != GameModes_Swarm && GetRandomInt(1, GetConVarInt(gCvarList[CVAR_MODE_SWARM_CHANCE])) == GetConVarInt(gCvarList[CVAR_MODE_SWARM]) && nAlive > GetConVarInt(gCvarList[CVAR_MODE_SWARM_MIN]) || modeIndex == GameModes_Swarm)
	{
		// Show mod info
		nMaxZombies = RoundToCeil(nAlive / GetConVarFloat(gCvarList[CVAR_MODE_SWARM_RATIO]));
		TranslationPrintHintTextAll("Multi swarm"); 
		gServerData[Server_RoundMode] = GameModes_Swarm;
		
		// Make random zombies
		GameModesTurnIntoZombies(cBasePlayer, nMaxZombies, nAlive);
		
		// Player game round sounds
		SoundsInputEmitToAll("ROUND_SWARM_SOUNDS");
	}
	
	else if(modeIndex == GameModes_None && lastRound != GameModes_Survivor && GetRandomInt(1, GetConVarInt(gCvarList[CVAR_MODE_SURVIVOR_CHANCE])) == GetConVarInt(gCvarList[CVAR_MODE_SURVIVOR]) && nAlive > GetConVarInt(gCvarList[CVAR_MODE_SURVIVOR_MIN]) || modeIndex == GameModes_Survivor)
	{
		// Get a random player
		if(modeIndex == GameModes_None)
		{
			cBasePlayer = CBasePlayer(fnGetRandomAlive(GetRandomInt(1, nAlive)));
		}
		
		// Show mod info
		nMaxZombies = (nAlive - 1);
		TranslationPrintHintTextAll("Mode survivor"); 
		gServerData[Server_RoundMode] = GameModes_Survivor;

		// Turn player into survivor
		MakeHumanIntoSurvivor(cBasePlayer);
		
		// Make random zombies
		GameModesTurnIntoZombies(cBasePlayer, nMaxZombies, nAlive);

		// Player game round sounds
		SoundsInputEmitToAll("ROUND_SURVIVOR_SOUNDS");
	}
	
	else if(modeIndex == GameModes_None && lastRound != GameModes_Armageddon && GetRandomInt(1, GetConVarInt(gCvarList[CVAR_MODE_ARMAGEDDON_CHANCE])) == GetConVarInt(gCvarList[CVAR_MODE_ARMAGEDDON]) && nAlive > GetConVarInt(gCvarList[CVAR_MODE_ARMAGEDDON_MIN]) || modeIndex == GameModes_Armageddon)
	{
		// Show mod info
		nMaxZombies = RoundToCeil(nAlive / 2.0);
		TranslationPrintHintTextAll("Mode armageddon"); 
		gServerData[Server_RoundMode] = GameModes_Armageddon;
		
		// Make random nemesises
		GameModesTurnIntoZombies(cBasePlayer, nMaxZombies, nAlive);

		// Player game round sounds
		SoundsInputEmitToAll("ROUND_ARMAGEDDON_SOUNDS");
	}
	
	else
	{
		// Get a random player
		if(modeIndex == GameModes_None)
		{
			cBasePlayer = CBasePlayer(fnGetRandomAlive(GetRandomInt(1, nAlive)));
		}
		
		if(modeIndex == GameModes_None && lastRound != GameModes_Nemesis && GetRandomInt(1, GetConVarInt(gCvarList[CVAR_MODE_NEMESIS_CHANCE])) == GetConVarInt(gCvarList[CVAR_MODE_NEMESIS]) && nAlive > GetConVarInt(gCvarList[CVAR_MODE_NEMESIS_MIN]) || modeIndex == GameModes_Nemesis)
		{
			// Show mod info
			TranslationPrintHintTextAll("Mode nemesis");
			gServerData[Server_RoundMode] = GameModes_Nemesis;
			
			// Make a nemesis
			InfectHumanToZombie(cBasePlayer, _, true);
			
			// Player game round sounds
			SoundsInputEmitToAll("ROUND_NEMESIS_SOUNDS");
		}
		else
		{
			// Show mod info
			TranslationPrintHintTextAll("Mode infection");
			gServerData[Server_RoundMode] = GameModes_Infection;
			
			// Make a zombie
			InfectHumanToZombie(cBasePlayer);
			
			// Player game round sounds
			SoundsInputEmitToAll("ROUND_NORMAL_SOUNDS");
		}
	}
	
	// Set mode index for the next round
	lastRound = gServerData[Server_RoundMode];
	
	// Remaining players should be humans
	GameModesTurnIntoHumans(cBasePlayer);
	
	// Terminate the round, ifzombies weren't infect
	if(!RoundEndOnValidate())
	{
		// Call forward
		API_OnZombieModStarted(gServerData[Server_RoundMode]);
	}
}

/**
 * Turn random players into the zombies.
 *
 * @param cBasePlayer		The client index.
 * @param nMaxZombies		The amount of zombies.
 * @param nAlive			The number of alive players.
 **/
void GameModesTurnIntoZombies(CBasePlayer* cBasePlayer, int nMaxZombies, int nAlive)
{
	// Initialize number of zombie 
	int nZombies;

	// Randomly turn players into zombies
	while (nZombies < nMaxZombies)
	{
		// Choose random player
		cBasePlayer = CBasePlayer(fnGetRandomAlive(GetRandomInt(1, nAlive)));
		
		// Verify that the client is exist
		if(!IsPlayerExist(cBasePlayer->Index))
		{
			continue;
		}
		
		// Verify that the client is human
		if(cBasePlayer->m_bZombie || cBasePlayer->m_bSurvivor)
		{
			continue;
		}
		
		// Make a zombie
		InfectHumanToZombie(cBasePlayer, _, (gServerData[Server_RoundMode] == GameModes_Armageddon) ? true : false);

		// Increment zombie count
		nZombies++;
	}
}

/**
 * Turn other players into the humans.
 *
 * @param cBasePlayer		The client index.
 **/
void GameModesTurnIntoHumans(CBasePlayer* cBasePlayer)
{
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
		
		// Verify that the client is human
		if(cBasePlayer->m_bZombie || cBasePlayer->m_bSurvivor)
		{
			continue;
		}
		
		// Switch to CT
		cBasePlayer->m_iTeamNum = TEAM_HUMAN;

		// Set glowing for the zombie vision
		cBasePlayer->m_bSetGlow(GetConVarBool(gCvarList[CVAR_ZOMBIE_XRAY]) ? true : false);
		
		// Turn into survivors during specific game mode
		if(gServerData[Server_RoundMode] == GameModes_Armageddon) MakeHumanIntoSurvivor(cBasePlayer);
	}
}