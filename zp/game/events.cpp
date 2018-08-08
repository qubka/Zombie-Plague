/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          events.cpp
 *  Type:          Game 
 *  Description:   Event hooking and forwarding.
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
 * Hook events used by plugin.
 **/
void EventInit(/*void*/)
{
    // Hook server events
    HookEvent("round_prestart",      EventRoundPreStart,    EventHookMode_Pre);
    HookEvent("round_start",         EventRoundStart,       EventHookMode_Post);
    HookEvent("round_end",           EventRoundEnd,         EventHookMode_Pre);
    HookEvent("cs_win_panel_round",  EventBlockWinPanel,    EventHookMode_Pre);

    // Hook player events
    HookEvent("player_spawn",        EventPlayerSpawn,      EventHookMode_Post);
    HookEvent("player_death",        EventPlayerDeath,      EventHookMode_Pre);
    HookEvent("player_jump",         EventPlayerJump,       EventHookMode_Post);
    HookEvent("weapon_fire",         EventPlayerFire,       EventHookMode_Pre);
    HookEvent("hostage_follows",     EventPlayerHostage,    EventHookMode_Post);

    // Hook temp events
    AddTempEntHook("Shotgun Shot",   EventPlayerShoot);
}

/*
 * Global player events.
 */

/**
 * Called once a client successfully connects.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientConnected(int clientIndex)
{
    #define ToolsOnClientConnect ToolsResetVars
    
    // Forward event to modules
    ToolsOnClientConnect(clientIndex);
}

/**
 * Called when a client is disconnected from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect_Post(int clientIndex)
{
    #define ToolsOnClientDisconnect ToolsResetVars
    
    // Forward event to modules
    DataBaseOnClientDisconnect(clientIndex);
    ToolsOnClientDisconnect(clientIndex);
    RoundEndOnClientDisconnect();
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 * 
 * @param clientIndex       The client index. 
 **/
public void OnClientPostAdminCheck(int clientIndex)
{
    // Forward event to modules
    DamageClientInit(clientIndex);
    WeaponsClientInit(clientIndex);
    AntiStickClientInit(clientIndex);
    DataBaseClientInit(clientIndex);
    CostumesClientInit(clientIndex);
}

/*
 * Global server events.
 */

/**
 * Event callback (round_prestart)
 * The round is start.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventRoundPreStart(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Forward event to modules
    RoundStartOnRoundPreStart();
}

/**
 * Event callback (round_start)
 * The round is started.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventRoundStart(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Forward event to modules
    RoundStartOnRoundStart();
    SoundsOnRoundStart();
}

/**
 * Event callback (round_end)
 * The round is end.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventRoundEnd(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Get all required event info.
    int iReason = hEvent.GetInt("reason");

    // Forward event to modules
    RoundEndOnRoundEnd(iReason);
    SoundsOnRoundEnd(iReason);
}

/**
 * Event callback (player_spawn)
 * Client has been spawned.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerSpawn(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Forward event to modules
    SpawnOnClientSpawn(clientIndex);
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerDeath(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int victimIndex   = GetClientOfUserId(hEvent.GetInt("userid"));
    int attackerIndex = GetClientOfUserId(hEvent.GetInt("attacker"));
    
    // Validate client
    if(!IsPlayerExist(victimIndex, false))
    {
        // If the client isn't a player, a player really didn't die now. Some
        // other mods might sent this event with bad data.
        return Plugin_Handled;
        }

    // Forward event to modules
    RagdollOnClientDeath(victimIndex);
    SoundsOnClientDeath(victimIndex);
    VEffectOnClientDeath(victimIndex);
    WeaponsOnClientDeath(victimIndex);
    DeathOnClientDeath(victimIndex, attackerIndex);
    
    // Allow death
    return Plugin_Continue;
}

/**
 * Event creation (player_death)
 * Client has been killed. (Fake)
 * 
 * @param victimIndex       The victim index.
 * @param attackerIndex     The attacker index.
 **/
public void EventFakePlayerDeath(const int victimIndex, const int attackerIndex)
{
    // Create and send custom death icon
    Event hEvent = CreateEvent("player_death");
    if(hEvent != INVALID_HANDLE)
    {
        // Sets event properties
        hEvent.SetInt("userid", GetClientUserId(victimIndex));
        hEvent.SetInt("attacker", GetClientUserId(attackerIndex));
        hEvent.SetString("weapon", "weapon_claws");
        hEvent.SetBool("headshot", true);
        
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Send fake event
            if(IsPlayerExist(i, false) && !IsFakeClient(i)) hEvent.FireToClient(i);
        }
        
        // Close it
        hEvent.Close();
    }
}

/**
 * Event callback (player_jump)
 * Client has been jumped.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerJump(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Forward event to modules
    JumpBoostOnClientJump(clientIndex);
}

/**
 * Event callback (weapon_fire)
 * Client has been shooted.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerFire(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Gets the active weapon index from the client
    int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon);
    
    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        return;
    }
    
    // Forward event to modules
    WeaponsOnFire(clientIndex, weaponIndex);
}

/**
 * Event callback (hostage_follows)
 * Client has been carried hostage.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerHostage(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // Forward event to modules
    WeaponsOnHostage(clientIndex);
}

/**
 * Event callback (cs_win_panel_round)
 * The win panel was been created.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventBlockWinPanel(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Sets whether an event broadcasting will be disabled
    if(!dontBroadcast) 
    {
        // Disable broadcasting
        hEvent.BroadcastDisabled = true;
    }
}

/**
 * Event callback (Shotgun Shot)
 * The bullet was been created.
 * 
 * @param sTEName           The temp name.
 * @param iPlayers          Array containing target player indexes.
 * @param numClients        Number of players in the array.
 * @param flDelay           Delay in seconds to send the TE.
 **/ 
public Action EventPlayerShoot(const char[] sTEName, const int[] iPlayers, int numClients, float flDelay) 
{ 
    // Gets all required event info
    int clientIndex = TE_ReadNum("m_iPlayer") + 1;

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Continue;
    }

    // Gets the active weapon index from the client
    int weaponIndex = GetEntDataEnt2(clientIndex, g_iOffset_PlayerActiveWeapon);
    
    // Validate weapon
    if(!IsValidEdict(weaponIndex))
    {
        return Plugin_Continue;
    }
    
    // Forward event to modules
    return WeaponsOnShoot(clientIndex, weaponIndex);
}