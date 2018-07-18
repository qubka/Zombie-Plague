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
 * @section All round end reasons.
 **/
#define ROUNDEND_TARGET_BOMBED                          0        // Target Successfully Bombed!
#define ROUNDEND_VIP_ESCAPED                            1        // The VIP has escaped!
#define ROUNDEND_VIP_ASSASSINATED                       2        // VIP has been assassinated!
#define ROUNDEND_TERRORISTS_ESCAPED                     3        // The terrorists have escaped!
#define ROUNDEND_CTS_PREVENTESCAPE                      4        // The CT have prevented most of the terrorists from escaping!
#define ROUNDEND_ESCAPING_TERRORISTS_NEUTRALIZED        5        // Escaping terrorists have all been neutralized!
#define ROUNDEND_BOMB_DEFUSED                           6        // The bomb has been defused!
#define ROUNDEND_CTS_WIN                                7        // Counter-Terrorists Win!
#define ROUNDEND_TERRORISTS_WIN                         8        // Terrorists Win!
#define ROUNDEND_ROUND_DRAW                             9        // Round Draw!
#define ROUNDEND_ALL_HOSTAGES_RESCUED                   10       // All Hostages have been rescued!
#define ROUNDEND_TARGET_SAVED                           11       // Target has been saved!
#define ROUNDEND_HOSTAGES_NOT_RESCUED                   12       // Hostages have not been rescued!
#define ROUNDEND_TERRORISTS_NOT_ESCAPED                 13       // Terrorists have not escaped!
#define ROUNDEND_VIP_NOT_ESCAPED                        14       // VIP has not escaped!
#define ROUNDEND_GAME_COMMENCING                        15       // Game Commencing!
/**
 * @endsection
 **/

/**
 * The round is ending.
 *
 * @param CReason           Reason the round has ended.
 **/
public Action RoundEndOnRoundEnd(int &CReason)
{
    // Initialize team scores
    int nZombieScore = GetTeamScore(TEAM_ZOMBIE);
    int nHumanScore = GetTeamScore(TEAM_HUMAN);

    // Resets server grobal variables
    gServerData[Server_RoundNew] = false;
    gServerData[Server_RoundEnd] = true;
    gServerData[Server_RoundStart] = false;

    // Initialize some variables
    int nHumanBonus; int nZombieBonus; OverlayType CType;

    // Switch end round reason
    switch(CReason)
    {
        /// Counter-Terrorists Win!
        case ROUNDEND_CTS_WIN :
        {
            // Increment CT score
            nHumanScore++;
            
            // Calculate bonuses
            nZombieBonus = gCvarList[CVAR_BONUS_ZOMBIE_FAIL].IntValue;
            nHumanBonus  = gCvarList[CVAR_BONUS_HUMAN_WIN].IntValue;
            
            // Sets the overlay
            CType = Overlay_HumanWin;
        }
    
        /// Terrorists Win!
        case ROUNDEND_TERRORISTS_WIN :     
        {    
            // Increment T score
            nZombieScore++;
            
            // Calculate bonuses
            nZombieBonus = gCvarList[CVAR_BONUS_ZOMBIE_WIN].IntValue;
            nHumanBonus  = gCvarList[CVAR_BONUS_HUMAN_FAIL].IntValue;
            
            // Sets the overlay
            CType = Overlay_ZombieWin;
        }

        /// Round Draw!
        case ROUNDEND_ROUND_DRAW :
        {
            // Increment <> score
            /** skip **/
            
            // Calculate bonuses
            nZombieBonus = gCvarList[CVAR_BONUS_ZOMBIE_DRAW].IntValue;
            nHumanBonus  = gCvarList[CVAR_BONUS_HUMAN_DRAW].IntValue;
            
            // Sets the overlay
            CType = Overlay_Draw;
        }

        /// Game Commencing!
        case ROUNDEND_GAME_COMMENCING : return;
        
        /// Other Results!
        default : 
        {
            // Gets amount of total humans and zombies
            int nHumans  = fnGetHumans();
            int nZombies = fnGetZombies();
    
            // If there are no zombies, that means there must be humans, they win the round
            if(!nZombies && nHumans)
            {
                // Increment CT score
                nHumanScore++;
                
                // Calculate bonuses
                nZombieBonus = gCvarList[CVAR_BONUS_ZOMBIE_FAIL].IntValue;
                nHumanBonus  = gCvarList[CVAR_BONUS_HUMAN_WIN].IntValue;
                
                // Sets the overlay
                CType = Overlay_HumanWin;
                
                // Set the reason
                CReason = ROUNDEND_CTS_WIN;
            }
            // If there are zombies, then zombies win the round
            else if(nZombies && !nHumans)
            {
                // Increment T score
                nZombieScore++;
                
                // Calculate bonuses
                nZombieBonus = gCvarList[CVAR_BONUS_ZOMBIE_WIN].IntValue;
                nHumanBonus  = gCvarList[CVAR_BONUS_HUMAN_FAIL].IntValue;
                
                // Sets the overlay
                CType = Overlay_ZombieWin;
                
                // Set the reason
                CReason = ROUNDEND_TERRORISTS_WIN;
            }
            // We know here, that either zombies or humans is 0 (not both)
            else
            {
                // Increment <> score
                /** skip **/
                
                // Calculate bonuses
                nZombieBonus = gCvarList[CVAR_BONUS_ZOMBIE_DRAW].IntValue;
                nHumanBonus  = gCvarList[CVAR_BONUS_HUMAN_DRAW].IntValue;
                
                // Sets the overlay
                CType = Overlay_Draw;
                
                // Set the reason
                CReason = ROUNDEND_ROUND_DRAW;
            }
        }
    }

    // Sets score in the scoreboard
    SetTeamScore(TEAM_ZOMBIE, nZombieScore);
    SetTeamScore(TEAM_HUMAN,  nHumanScore);

    //*********************************************************************
    //*                    GIVE BONUSES AND SHOW OVERLAYS                       *
    //*********************************************************************
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i, false))
        {
            // Give ammopack bonuses
            gClientData[i][Client_AmmoPacks] += gClientData[i][Client_Zombie] ? nZombieBonus : nHumanBonus;

            // Display overlay to client
            VOverlayOnClientUpdate(i, CType);
        }
    }
}

/**
 * Validate round ending.
 *
 * @param validateRound     If true, then validate amount of players.
 **/
bool RoundEndOnValidate(bool validateRound = true)
{
    // If gamemodes disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_START].IntValue)
    {
        // Round isn't active
        return false;
    }
    
    // If mode doesn't started yet, then stop
    if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
    {
        // Round isn't active
        return false;
    }

    // Gets amount of total humans and zombies
    int nHumans  = fnGetHumans();
    int nZombies = fnGetZombies();
    
    // If round need to be validate
    if(validateRound)
    {
        // If there are clients on both teams during validation, then stop
        if(nZombies && nHumans)
        {
            // Round isn't over
            return false;
        }
    }

    // If there are no zombies, that means there must be humans, they win the round
    if(!nZombies && nHumans)
    {
        ToolsTerminateRound(ROUNDEND_CTS_WIN);
    }
    // If there are zombies, then zombies win the round
    else if(nZombies && !nHumans)
    {
        ToolsTerminateRound(ROUNDEND_TERRORISTS_WIN);
    }
    // We know here, that either zombies or humans is 0 (not both)
    else
    {
        ToolsTerminateRound(ROUNDEND_ROUND_DRAW);
    }

    // Round is over
    return true;
}

/**
 * Checking the last human/zombie disconnection.
 **/
void RoundEndOnClientDisconnect(/*void*/)
{
    // If gamemodes disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_START].IntValue)
    {
        // Round isn't active
        return;
    }
    
    // If mode doesn't started yet, then stop
    if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
    {
        // Round isn't active
        return;
    }

    // Gets amount of total humans and zombies
    int nHumans  = fnGetHumans();
    int nZombies = fnGetZombies();

    // If the last zombie disconnecting, then terminate round
    if(!nZombies && nHumans)
    {
        // Show message
        TranslationPrintHintTextAll("Zombie Left"); 
        
        // Terminate the round with humans as the winner
        ToolsTerminateRound(ROUNDEND_CTS_WIN);
    }
    // If the last human disconnecting, then terminate round
    else if(nZombies && !nHumans)
    {
        // Show message
        TranslationPrintHintTextAll("Human Left"); 

        // Terminate the round with zombies as the winner
        ToolsTerminateRound(ROUNDEND_TERRORISTS_WIN);
    }
    // If the last player disconnecting, then terminate round
    else if(!nZombies && !nHumans)
    {
        // Show message
        TranslationPrintHintTextAll("Player Left"); 

        // Terminate the round with zombies as the winner
        ToolsTerminateRound(ROUNDEND_ROUND_DRAW);
    }
}
