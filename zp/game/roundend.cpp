/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          roundend.cpp
 *  Type:          Game 
 *  Description:   Round end event.
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
 * Delay between round ending and new round starting. (Normal)
 **/
#define ROUNDEND_DELAY 5.0

/**
 * Possible round end outcomes.
 **/
#define RoundEnd_ZombiesWin 	CSRoundEnd_TerroristWin
#define RoundEnd_HumansWin 		CSRoundEnd_CTWin

/**
 * The round is ending by them self.
 **/
public Action RoundEndOnRoundEnd(/*void*/)
{
	// Reset server grobal bools
	gServerData[Server_RoundNew] 	= false;
	gServerData[Server_RoundEnd] 	= true;
	gServerData[Server_RoundStart] 	= false;

	// If round end timer is running, then kill it
	delete gServerData[Server_RoundTimer];
}

/**
 * Call termination of the round with human advantageously.
 *
 * @param hTimer			The timer handle.
 **/
public Action RoundEndTimer(Handle hTimer)
{
	// Clear timer
	gServerData[Server_RoundTimer] = NULL;

	// Terminate round without validation
	RoundEndOnValidate(false);
	
	// Destroy timer
	return ACTION_STOP;
}

/**
 * Validate round with human advantageously and also terminate it when round isn't active.
 *
 * @param validateRound		If true, then validate amount of players.
 **/
bool RoundEndOnValidate(bool validateRound = true)
{
	// If gamemodes disabled, then stop
	if(!GetConVarInt(gCvarList[CVAR_GAME_CUSTOM_START]))
	{
		// Round isn't active
		return false;
	}
	
	// Get amount of total playing players
	int nPlayers = fnGetPlaying();
	
	// If there aren't clients on both teams, then stop
	if(!nPlayers)
	{
		// Round isn't active
		return false;
	}
	
	// Get amount of total humans and zombies
	int nHumans  = fnGetHumans();
	int nZombies = fnGetZombies();
	
	// If round need to be validate
	if(validateRound)
	{
		// Mode didn't started yet?
		if(gServerData[Server_RoundNew])
		{
			// Get amount of total alive players
			int nAlive = fnGetAlive();
			
			// If more than two players still play
			if(nAlive > 1)
			{
				// Round isn't over
				return false;
			}
		}
		
		// If there are clients on both teams during validation, then stop
		if(nZombies && nHumans)
		{
			// Round isn't over
			return false;
		}
	}
	
	// We know here, that either zombies or humans is 0 (not both)
	
	// If there are no zombies, that means there must be humans, they win the round
	if(nHumans)
	{
		CS_TerminateRound(ROUNDEND_DELAY, RoundEnd_HumansWin, false);
	}
	// If there are zombies, then zombies win the round
	else
	{
		CS_TerminateRound(ROUNDEND_DELAY, RoundEnd_ZombiesWin, false);
	}

	// Round is over
	return true;
}

/**
 * Called when TerminateRound is called.
 * 
 * @param flDelay			Time (in seconds) until new round startsю
 * @param CReason			The reason of the round end.
 **/	
public Action CS_OnTerminateRound(float &flDelay, CSRoundEndReason &CReason)
{
	// If round didn't started, then stop
	if(!gServerData[Server_RoundStart])
	{
		return ACTION_CHANGED;
	}
	
	// Initialize team score
	static int nScore[2];
	
	// Get amount of total playing players
	int nPlayers = fnGetPlaying();
	
	// If there aren't clients on both teams, then stop
	if(!nPlayers)
	{
		return ACTION_CHANGED;
	}
	
	// Initialize bonus variables
	int nHumanBonus; int nZombieBonus; 
	
	// Switch end round reason
	switch(CReason)
	{
		case CSRoundEnd_TerroristWin : 	
		{	
			// Increment T score
			nScore[0]++;
			
			// Calculate bonuses
			nZombieBonus = GetConVarInt(gCvarList[CVAR_BONUS_ZOMBIE_WIN]);
			nHumanBonus  = GetConVarInt(gCvarList[CVAR_BONUS_HUMAN_FAIL]);
		}

		case CSRoundEnd_CTWin :
		{
			// Increment CT score
			nScore[1]++;
			
			// Calculate bonuses
			nZombieBonus = GetConVarInt(gCvarList[CVAR_BONUS_ZOMBIE_FAIL]);
			nHumanBonus  = GetConVarInt(gCvarList[CVAR_BONUS_HUMAN_WIN]);
		}

		default : return ACTION_CHANGED;
	}

	// Set score in the scoreboard
	SetTeamScore(TEAM_ZOMBIE, nScore[0]);
	SetTeamScore(TEAM_HUMAN,  nScore[1]);
	
	//*********************************************************************
	//*            		GIVE BONUSES AND SHOW OVERLAYS           	  	  *
	//*********************************************************************
	
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Get real player index from event key
		CBasePlayer* cBasePlayer = CBasePlayer(i);
		
		// Validate client
		if(!IsPlayerExist(cBasePlayer->Index, false))
		{
			continue;
		}

		// Display overlay to client
		VOverlayOnClientUpdate(cBasePlayer->Index, (CReason == CSRoundEnd_TerroristWin) ? Overlay_ZombieWin : Overlay_HumanWin);

		// Give ammopack bonuses
		cBasePlayer->m_nAmmoPacks += cBasePlayer->m_bZombie ? nZombieBonus : nHumanBonus;
	}
	
	// Allow to terminate
	return ACTION_CHANGED;
}

/**
 * Checking the last human or the last zombie disconnection.
 **/
void RoundEndOnClientDisconnect(/*void*/)
{
	// If mode doesn't started yet, then stop
	if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
	{
		// Round isn't active
		return;
	}

	// Get amount of total humans and zombies
	int nHumans  = fnGetHumans();
	int nZombies = fnGetZombies();

	// If the last zombie disconnecting, then terminate round
	if(!nZombies && nHumans)
	{
		// Show message
		TranslationPrintHintTextAll("Zombie Left"); 
		
		// Terminate the round with humans as the winner
		CS_TerminateRound(ROUNDEND_DELAY, RoundEnd_HumansWin, false);
		return;
	}
	
	// If the last human disconnecting, then terminate round
	if(nZombies && !nHumans)
	{
		// Show message
		TranslationPrintHintTextAll("Human Left"); 

		// Terminate the round with zombies as the winner
		CS_TerminateRound(ROUNDEND_DELAY, RoundEnd_ZombiesWin, false);
		return;
	}
}