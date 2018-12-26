/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          roundstart.cpp
 *  Type:          Game 
 *  Description:   Round start event.
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
 * Number of max rounds during map.
 **/
#define RoundMax 15

/**
 * Round module init function.
 **/
void RoundStartInit(/*void*/)
{
    // Hook server events
    HookEvent("round_prestart", RoundStartOnRoundPreStart, EventHookMode_Pre);
    HookEvent("round_start",    RoundStartOnRoundStart,    EventHookMode_Post);
}

/**
 * Load round module.
 **/
void RoundStartLoad(/*void*/)
{
    // Resets server global variables
    gServerData[Server_RoundNew] = true;
    gServerData[Server_RoundEnd] = false;
    gServerData[Server_RoundStart] = false;
    
    // Update server grobal variables
    gServerData[Server_RoundMode] = -1;
    gServerData[Server_RoundNumber] = 0;
    gServerData[Server_RoundCount] = gCvarList[CVAR_GAME_CUSTOM_START].IntValue;
    
    // Gets current map name
    GetCurrentMap(gServerData[Server_MapName], sizeof(gServerData[Server_MapName]));
}

/**
 * Hook round cvar changes.
 **/
void RoundStartOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_SERVER_TEAM_BALANCE]         = FindConVar("mp_autoteambalance"); 
    gCvarList[CVAR_SERVER_LIMIT_TEAMS]          = FindConVar("mp_limitteams");
    gCvarList[CVAR_SERVER_WARMUP_TIME]          = FindConVar("mp_warmuptime");
    gCvarList[CVAR_SERVER_WARMUP_PERIOD]        = FindConVar("mp_do_warmup_period");
    gCvarList[CVAR_SERVER_ROUNDTIME_ZP]         = FindConVar("mp_roundtime");
    gCvarList[CVAR_SERVER_ROUNDTIME_CS]         = FindConVar("mp_roundtime_hostage");
    gCvarList[CVAR_SERVER_ROUNDTIME_DE]         = FindConVar("mp_roundtime_defuse");
    gCvarList[CVAR_SERVER_ROUND_RESTART]        = FindConVar("mp_restartgame");
    gCvarList[CVAR_SERVER_RESTART_DELAY]        = FindConVar("mp_round_restart_delay");
    
    // Sets locked cvars to their locked value
    gCvarList[CVAR_SERVER_TEAM_BALANCE].IntValue  = 0;
    gCvarList[CVAR_SERVER_LIMIT_TEAMS].IntValue   = 0;
    gCvarList[CVAR_SERVER_WARMUP_TIME].IntValue   = 0;
    gCvarList[CVAR_SERVER_WARMUP_PERIOD].IntValue = 0;
    
    // Hook locked cvars to prevent it from changing
    HookConVarChange(gCvarList[CVAR_SERVER_TEAM_BALANCE],         CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_LIMIT_TEAMS],          CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_WARMUP_TIME],          CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_WARMUP_PERIOD],        CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_ZP],         RoundStartHookTime);
    HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_CS],         RoundStartHookTime);
    HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_DE],         RoundStartHookTime);
    HookConVarChange(gCvarList[CVAR_SERVER_ROUND_RESTART],        RoundStartHookRestart);
}

/**
 * Event callback (round_prestart)
 * The round is start.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action RoundStartOnRoundPreStart(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Resets server global variables
    gServerData[Server_RoundNew] = true;
    gServerData[Server_RoundEnd] = false;
    gServerData[Server_RoundStart] = false;
    
    // Update server grobal variables
    gServerData[Server_RoundMode] = -1;
    gServerData[Server_RoundNumber]++;
    gServerData[Server_RoundCount] = gCvarList[CVAR_GAME_CUSTOM_START].IntValue;

    // Balance of all teams
    RoundStartOnBalanceTeams();
}

/**
 * Event callback (round_start)
 * The round is started.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action RoundStartOnRoundStart(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Forward event to sub-modules
    RoundStartOnKillEntity();
    SoundsOnRoundStart();
}

/**
 * Balances all teams.
 **/
void RoundStartOnBalanceTeams(/*void*/)
{
    // Move team clients to random teams
    
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
    
            // Swith team
            bool bState = ToolsGetClientDefuser(i);
            ToolsSetClientTeam(i, !(i % 2) ? TEAM_HUMAN : TEAM_ZOMBIE);
            ToolsSetClientDefuser(i, bState);
        }
    }
}

/**
 * Kills all objective entities.
 **/
void RoundStartOnKillEntity(/*void*/)
{
    // Initialize some variables
    static char sClassname[NORMAL_LINE_LENGTH];
    static const char sObjective[NORMAL_LINE_LENGTH+1] = "func_bomb_target_hostage_entity_func_hostage_rescue_func_buyzone";

    // Gets max amount of entities
    int nGetMaxEnt = GetMaxEntities();
    
    // x = entity index
    for(int x = MaxClients; x <= nGetMaxEnt; x++)
    {
        // Validate entity
        if(IsValidEdict(x))
        {
            // Gets valid edict classname
            GetEdictClassname(x, sClassname, sizeof(sClassname));
            
            // Validate objectives
            if(StrContains(sObjective, sClassname) != -1) 
            {
                AcceptEntityInput(x, "Kill"); //! Destroy
            }
            // Validate weapon
            else if(!strncmp(sClassname, "weapon_", 7, false))
            {
                // Gets the weapon owner
                int clientIndex = GetEntDataEnt2(x, g_iOffset_WeaponOwner);
                
                // Validate owner
                if(!IsPlayerExist(clientIndex))
                {
                    AcceptEntityInput(x, "Kill"); //! Destroy
                }
            }
        }
    }
}

/**
 * Cvar hook callback (mp_roundtime, mp_roundtime_hostage, mp_roundtime_defuse)
 * Prevent from long rounds.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void RoundStartHookTime(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // If cvar is mp_roundtime_hostage or mp_roundtime_defuse, then continue
    if(hConVar == gCvarList[CVAR_SERVER_ROUNDTIME_CS] || hConVar == gCvarList[CVAR_SERVER_ROUNDTIME_DE])
    {
        // Revert to specific value
        hConVar.IntValue = gCvarList[CVAR_SERVER_ROUNDTIME_ZP].IntValue;
    }
    
    // If value was invalid, then stop
    int iDelay = StringToInt(newValue);
    if(iDelay <= RoundMax)
    {
        return;
    }
    
    // Revert to minimum value
    hConVar.SetInt(RoundMax);
}

/**
 * Cvar hook callback. (mp_restartgame)
 * Stops restart and just ends the round.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void RoundStartHookRestart(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Prevent round restart
    hConVar.IntValue = 0;

    // If value was invalid, then stop
    int iDelay = StringToInt(newValue);
    if(iDelay <= 0)
    {
        return;
    }
    
    // Resets number of rounds
    gServerData[Server_RoundNumber] = 0;
    
    // Resets score in the scoreboard
    SetTeamScore(TEAM_ZOMBIE, 0);
    SetTeamScore(TEAM_HUMAN,  0);

    // Terminate the round with restart time as delay
    CS_TerminateRound(1.0, CSRoundEnd_GameStart, true);
}