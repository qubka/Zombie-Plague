/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          roundend.cpp
 *  Type:          Game 
 *  Description:   Round end event.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
 * Round module init function.
 **/
void RoundEndInit(/*void*/)
{
    // Hook server events
    HookEvent("cs_win_panel_round", RoundEndOnPanel,    EventHookMode_Pre);
}

/**
 * Called when TerminateRound is called.
 * 
 * @param flDelay           Time (in seconds) until new round starts
 * @param CReason           Reason for round end
 **/
public Action CS_OnTerminateRound(float& flDelay, CSRoundEndReason& CReason)
{
    // Gets team scores
    int nZombieScore = GetTeamScore(TEAM_ZOMBIE);
    int nHumanScore = GetTeamScore(TEAM_HUMAN);
    
    // Resets server grobal variables
    gServerData[Server_RoundNew] = false;
    gServerData[Server_RoundEnd] = true;
    gServerData[Server_RoundStart] = false;

    // Initialize variable
    static OverlayType CType;

    // Switch end round reason
    switch(CReason)
    {
        case CSRoundEnd_GameStart : return Plugin_Continue;

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

                // Sets overlay
                CType = Overlay_HumanWin;
                
                // Set the reason
                CReason = CSRoundEnd_CTWin;
            }
            // If there are zombies, then zombies win the round
            else if(nZombies && !nHumans)
            {
                // Increment T score
                nZombieScore++;

                // Sets overlay
                CType = Overlay_ZombieWin;
                
                // Set the reason
                CReason = CSRoundEnd_TerroristWin;
            }
            // We know here, that either zombies or humans is 0 (not both)
            else
            {
                // Increment <> score
                /** skip **/

                // Sets overlay
                CType = Overlay_Draw;
                
                // Set the reason
                CReason = CSRoundEnd_Draw;
            }
        }
    }
    
    // Sets score in the scoreboard
    SetTeamScore(TEAM_ZOMBIE, nZombieScore);
    SetTeamScore(TEAM_HUMAN,  nHumanScore);

    //*********************************************************************
    //*                    GIVE BONUSES AND SHOW OVERLAYS                 *
    //*********************************************************************
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i, false))
        {
            // Validate team
            if(GetClientTeam(i) <= TEAM_SPECTATOR)
            {
                continue;
            }
            
            // Give money bonus
            gClientData[i][Client_Money] += gClientData[i][Client_Zombie] ? nZombieBonus : nHumanBonus;

            // Display overlay to the client
            VOverlayOnClientUpdate(i, CType);
        }
    }
    
    // Forward event to modules
    SoundsOnRoundEnd(CReason);
    
    // Return on success
    return Plugin_Changed;
}

/**
 * Validate round ending.
 *
 * @param validateRound     If true, then validate amount of players.
 **/
bool RoundEndOnValidate(const bool validateRound = true)
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
        CS_TerminateRound(gCvarList[CVAR_SERVER_RESTART_DELAY].FloatValue, CSRoundEnd_CTWin, false);
    }
    // If there are zombies, then zombies win the round
    else if(nZombies && !nHumans)
    {
        CS_TerminateRound(gCvarList[CVAR_SERVER_RESTART_DELAY].FloatValue, CSRoundEnd_TerroristWin, false);
    }
    // We know here, that either zombies or humans is 0 (not both)
    else
    {
        CS_TerminateRound(gCvarList[CVAR_SERVER_RESTART_DELAY].FloatValue, CSRoundEnd_Draw, false);
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
        TranslationPrintHintTextAll("zombie left"); 
        
        // Terminate the round with humans as the winner
        CS_TerminateRound(gCvarList[CVAR_SERVER_RESTART_DELAY].FloatValue, CSRoundEnd_CTWin, false);
    }
    // If the last human disconnecting, then terminate round
    else if(nZombies && !nHumans)
    {
        // Show message
        TranslationPrintHintTextAll("human left"); 

        // Terminate the round with zombies as the winner
        CS_TerminateRound(gCvarList[CVAR_SERVER_RESTART_DELAY].FloatValue, CSRoundEnd_TerroristWin, false);
    }
    // If the last player disconnecting, then terminate round
    else if(!nZombies && !nHumans)
    {
        // Show message
        TranslationPrintHintTextAll("player left"); 

        // Terminate the round with zombies as the winner
        CS_TerminateRound(gCvarList[CVAR_SERVER_RESTART_DELAY].FloatValue, CSRoundEnd_Draw, false);
    }
}

/**
 * Event callback (cs_win_panel_round)
 * The win panel was been created.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action RoundEndOnPanel(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Sets whether an event broadcasting will be disabled
    if(!dontBroadcast) 
    {
        // Disable broadcasting
        hEvent.BroadcastDisabled = true;
    }
}
