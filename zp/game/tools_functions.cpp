/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          tools_functions.cpp
 *  Type:          Game 
 *  Description:   API for offsets/signatures exposed in tools.cpp
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
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action ToolsHook(int clientIndex, const char[] commandMsg, int iArguments)
{
    // Validate client 
    if(IsPlayerExist(clientIndex))
    {
        // If zombie nightvision ?
        if(gClientData[clientIndex][Client_Zombie])
        {
            // Switch on/off nightvision
            if(gCvarList[CVAR_ZOMBIE_NIGHT_VISION] && !gServerData[Server_RoundEnd]) VOverlayOnClientUpdate(clientIndex, !ToolsGetClientNightVision(clientIndex, true) ? Overlay_Vision : Overlay_Reset);
        }
        // If human flashlight ?
        else
        {
            // Switch on/off flashlight
            ToolsSetClientFlashLight(clientIndex, true);
            
            // Forward event to modules
            SoundsOnClientFlashLight(clientIndex);
        }
    }
    
    // Block command
    return Plugin_Handled;
}

/**
 * Client is join/leave the server.
 *
 * @param clientIndex       The client index.
 **/
void ToolsResetVars(int clientIndex)
{
    // Resets all variables
    gClientData[clientIndex][Client_Zombie] = false;
    gClientData[clientIndex][Client_Survivor] = false;
    gClientData[clientIndex][Client_Nemesis] = false;
    gClientData[clientIndex][Client_Skill] = false;
    gClientData[clientIndex][Client_Loaded] = false;
    gClientData[clientIndex][Client_AutoRebuy] = false;
    gClientData[clientIndex][Client_SkillCountDown] = 0.0;
    gClientData[clientIndex][Client_ZombieClass] = 0;
    gClientData[clientIndex][Client_ZombieClassNext] = 0;
    gClientData[clientIndex][Client_HumanClass] = 0;
    gClientData[clientIndex][Client_HumanClassNext] = 0;
    gClientData[clientIndex][Client_Respawn] = TEAM_HUMAN;
    gClientData[clientIndex][Client_RespawnTimes] = 0;
    gClientData[clientIndex][Client_AmmoPacks] = 0;
    gClientData[clientIndex][Client_LastBoughtAmount] = 0;
    gClientData[clientIndex][Client_Level] = 1;
    gClientData[clientIndex][Client_Exp] = 0;
    gClientData[clientIndex][Client_DataID] = -1;
    gClientData[clientIndex][Client_Costume] = -1;
    gClientData[clientIndex][Client_AttachmentCostume] = INVALID_ENT_REFERENCE;
    gClientData[clientIndex][Client_AttachmentBits] = 0;
    gClientData[clientIndex][Client_AttachmentAddons] = { INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE };
    gClientData[clientIndex][Client_AttachmentMuzzle] = INVALID_ENT_REFERENCE;
    gClientData[clientIndex][Client_AttachmentWeapon] = INVALID_ENT_REFERENCE;
    gClientData[clientIndex][Client_AttachmentLast][0] = '\0';
    gClientData[clientIndex][Client_ViewModels] = { INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE };
    gClientData[clientIndex][Client_LastSequence] = -1;
    gClientData[clientIndex][Client_CustomWeapon] = 0;
    gClientData[clientIndex][Client_DrawSequence] = -1;
    gClientData[clientIndex][Client_WeaponIndex] = -1;
    gClientData[clientIndex][Client_ToggleSequence] = false;
    gClientData[clientIndex][Client_LastSequenceParity] = -1;
    gClientData[clientIndex][Client_SwapWeapon] = INVALID_ENT_REFERENCE;
    
    // Resets all timers
    ToolsResetTimers(clientIndex);
}

/**
 * Respawn a player.
 *
 * @param clientIndex       The client index.
 **/
void ToolsForceToRespawn(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }
    
    // Verify that the client is dead
    if(IsPlayerAlive(clientIndex))
    {
        return;
    }
    
    // Respawn as human ?
    if(gCvarList[CVAR_RESPAWN_DEATHMATCH].IntValue == 1 || (gCvarList[CVAR_RESPAWN_DEATHMATCH].IntValue == 2 && GetRandomInt(0, 1)) || (gCvarList[CVAR_RESPAWN_DEATHMATCH].IntValue == 3 && fnGetHumans() < fnGetAlive() / 2))
    {
        gClientData[clientIndex][Client_Respawn] = TEAM_HUMAN;
    }
    // Respawn as zombie ?
    else
    {
        gClientData[clientIndex][Client_Respawn] = TEAM_ZOMBIE;
    }
    
    // Override respawn as zombie setting on nemesis and survivor rounds
    if(ModesIsSurvivor(gServerData[Server_RoundMode]) && !ModesIsNemesis(gServerData[Server_RoundMode])) gClientData[clientIndex][Client_Respawn] = TEAM_ZOMBIE;
    else if(ModesIsNemesis(gServerData[Server_RoundMode]) && !ModesIsSurvivor(gServerData[Server_RoundMode])) gClientData[clientIndex][Client_Respawn] = TEAM_HUMAN;
    
    // Respawn a player
    SDKCall(hSDKCallRoundRespawn, clientIndex);
}

/**
 * Reset all player timers.
 *
 * @param clientIndex       The client index.
 **/
void ToolsResetTimers(int clientIndex)
{
    delete gClientData[clientIndex][Client_LevelTimer];
    delete gClientData[clientIndex][Client_AccountTimer];
    delete gClientData[clientIndex][Client_RespawnTimer];
    delete gClientData[clientIndex][Client_ZombieSkillTimer];
    delete gClientData[clientIndex][Client_ZombieCountDownTimer];
    delete gClientData[clientIndex][Client_ZombieHealTimer];
    delete gClientData[clientIndex][Client_ZombieMoanTimer]; 
}

/**
 * Purge all player timers.
 *
 * @param clientIndex       The client index.
 **/
void ToolsPurgeTimers(int clientIndex)
{
    gClientData[clientIndex][Client_LevelTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_AccountTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_RespawnTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_ZombieSkillTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_ZombieCountDownTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_ZombieHealTimer] = INVALID_HANDLE;    
    gClientData[clientIndex][Client_ZombieMoanTimer] = INVALID_HANDLE; 
}

/**
 * Get or set a client velocity.
 *
 * @param clientIndex       The client index.
 * @param vecVelocity       Array to store vector in, or velocity to set on client.
 * @param bApply            True to get client velocity, false to set it.
 * @param bStack            If modifying velocity, then true will stack new velocity onto the client
 *                          current velocity, false will reset it.
 **/
stock void ToolsClientVelocity(int clientIndex, float vecVelocity[3], bool bApply = true, bool bStack = true)
{
    // If retrieve if true, then get client velocity
    if(!bApply)
    {
        // i = vector component
        for(int i = 0; i < 3; i++)
        {
            vecVelocity[i] = GetEntDataFloat(clientIndex, g_iOffset_PlayerVelocity + (i * 4));
        }
        
        // Stop here
        return;
    }
    
    // If stack is true, then add client velocity
    if(bStack)
    {
        // Gets client velocity
        static float vecClientVelocity[3];
        
        // i = vector component
        for(int i = 0; i < 3; i++)
        {
            vecClientVelocity[i] = GetEntDataFloat(clientIndex, g_iOffset_PlayerVelocity + (i * 4));
        }
        
        AddVectors(vecClientVelocity, vecVelocity, vecVelocity);
    }
    
    // Apply velocity on client
    TeleportEntity(clientIndex, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

/**
 * Gets client velocity.
 *
 * @param clientIndex       The client index.
 * @param vecVelocity       Array to store vector in.
 **/
stock void ToolsGetClientVelocity(int clientIndex, float vecVelocity[3])
{
    // i = vector component
    for(int i = 0; i < 3; i++)
    {
        vecVelocity[i] = GetEntDataFloat(clientIndex, g_iOffset_PlayerVelocity + (i * 4));
    }
}

/**
 * Set a client health value.
 *
 * @param clientIndex       The client index.
 * @param iValue            Armor value.
 **/
stock void ToolsSetClientHealth(int clientIndex, int iValue)
{
    // Sets health of client
    SetEntData(clientIndex, g_iOffset_PlayerHealth, iValue, _, true);
}

/**
 * Set a client lagged movement value.
 *
 * @param clientIndex       The client index.
 * @param flValue           LMV value.
 **/
stock void ToolsSetClientLMV(int clientIndex, float flValue)
{
    // Sets lagged movement value of client
    SetEntDataFloat(clientIndex, g_iOffset_PlayerLMV, flValue, true);
}

/**
 * Set a client armor value.
 * @param clientIndex   The client index.
 * @param iValue         Armor value.
 **/
stock void ToolsSetClientArmor(int clientIndex, int iValue)
{
    // Sets armor of client
    SetEntData(clientIndex, g_iOffset_PlayerArmor, iValue, _, true);
}

/**
 * Set a client team index.
 *
 * @param clientIndex       The client index.
 * @param iValue            Team index.
 **/
stock void ToolsSetClientTeam(int clientIndex, int nTeam)
{
    // Validate team
    if(GetClientTeam(clientIndex) <= TEAM_SPECTATOR) //! Fix, thanks to inklesspen!
    {
        // Sets team of client
        ChangeClientTeam(clientIndex, nTeam);
    }
    else
    {
        // Switch team of client
        SDKCall(hSDKCallSwitchTeam, clientIndex, nTeam);
    }
}

/**
 * Get nightvision values on a client.
 *
 * @param clientIndex       The client index.
 * @param ownership         If true, function will return the value of the client ownership of nightvision.
 *                          If false, function will return the value of the client on/off state of the nightvision.
 * @return                  True if aspect of nightvision is enabled on the client, false if not.
 **/
stock bool ToolsGetClientNightVision(int clientIndex, bool bOwnership = false)
{
    // If ownership is true, then toggle the ownership of nightvision on client
    return view_as<bool>(GetEntData(clientIndex, bOwnership ? g_iOffset_PlayerHasNightVision : g_iOffset_PlayerNightVisionOn, 1));
}

/**
 * Control nightvision values on a client.
 *
 * @param clientIndex       The client index.
 * @param bEnable           Enable or disable an aspect of nightvision. (see ownership parameter)
 * @param bOwnership        If true, enable will toggle the client ownership of nightvision.
 *                          If false, enable will toggle the client on/off state of the nightvision.
 **/
stock void ToolsSetClientNightVision(int clientIndex, bool bEnable, bool bOwnership = false)
{
    // If ownership is true, then toggle the ownership of nightvision on client
    SetEntData(clientIndex, bOwnership ? g_iOffset_PlayerHasNightVision : g_iOffset_PlayerNightVisionOn, bEnable, _, true);
}

/**
 * Set a client score or deaths.
 * 
 * @param clientIndex       The client index.
 * @param bScore            True to look at score, false to look at deaths.  
 * @param iValue            The value of the client score or deaths.
 **/
stock void ToolsSetClientScore(int clientIndex, bool bScore = true, int iValue = 0)
{
    // Find the datamap
    if(!g_iOffset_PlayerFrags || !g_iOffset_PlayerDeath)
    {
        g_iOffset_PlayerFrags  = FindDataMapInfo(clientIndex, "m_iFrags");
        g_iOffset_PlayerDeath = FindDataMapInfo(clientIndex, "m_iDeaths");
    }
    
    // If score is true, then set client score, otherwise set client deaths
    SetEntData(clientIndex, bScore ? g_iOffset_PlayerFrags : g_iOffset_PlayerDeath, iValue, _, true);
}

/**
 * Get or set a client score or deaths.
 * 
 * @param clientIndex        The client index.
 * @param bScore            True to look at score, false to look at deaths.  
 * @return                  The score or death count of the client.
 **/
stock int ToolsGetClientScore(int clientIndex, bool bScore = true)
{
    // If score is true, then return client score, otherwise return client deaths
    return bScore ? GetClientFrags(clientIndex) : GetClientDeaths(clientIndex);
}

/**
 * Set a client gravity.
 * 
 * @param clientIndex       The client index.
 * @param flValue           The value of the client gravity.
 **/
stock void ToolsSetClientGravity(int clientIndex, float flValue)
{
    // Find the datamap
    if(!g_iOffset_PlayerGravity)
    {
        g_iOffset_PlayerGravity = FindDataMapInfo(clientIndex, "m_flGravity");
    }
    
    // Sets value on the client
    SetEntDataFloat(clientIndex, g_iOffset_PlayerGravity, flValue, true);
}

/**
 * Set a client spotting.
 * 
 * @param clientIndex       The client index.
 * @param bEnable           Enable or disable an aspect of spotting.
 **/
stock void ToolsSetClientSpot(int clientIndex, bool bEnable)
{
    // Sets value on the client
    SetEntData(clientIndex, g_iOffset_PlayerSpotted, bEnable, 1, true);
}

/**
 * Set a client detecting.
 * 
 * @param clientIndex       The client index.
 * @param bEnable           Enable or disable an aspect of detection.
 **/
stock void ToolsSetClientDetecting(int clientIndex, bool bEnable)
{
    // Sets value on the client
    SetEntDataFloat(clientIndex, g_iOffset_PlayerDetected, bEnable ? (GetGameTime() + 9999.0) : 0.0, true);
}

/**
 * Set a client hud.
 * 
 * @param clientIndex       The client index.
 * @param bEnable           Enable or disable an aspect of hud.
 **/
stock void ToolsSetClientHud(int clientIndex, bool bEnable)
{   
    #define HIDEHUD_CROSSHAIR (1 << 8)
    // Sets value on the client
    SetEntData(clientIndex, g_iOffset_PlayerHUD, bEnable ? (GetEntData(clientIndex, g_iOffset_PlayerHUD) & ~HIDEHUD_CROSSHAIR) : (GetEntData(clientIndex, g_iOffset_PlayerHUD) | HIDEHUD_CROSSHAIR), _, true);
}

/**
 * Set a client flashlight.
 * 
 * @param clientIndex       The client index.
 * @param bEnable           Enable or disable an aspect of flashlight.
 **/
stock void ToolsSetClientFlashLight(int clientIndex, bool bEnable)
{
    #define EF_FLASHLIGHT 4
    // Sets value on the client
    SetEntData(clientIndex, g_iOffset_PlayerFlashLight, bEnable ? (GetEntData(clientIndex, g_iOffset_PlayerFlashLight) ^ EF_FLASHLIGHT) : (EF_FLASHLIGHT ^ EF_FLASHLIGHT), _, true);
}

/**
 * Set a round termination.
 * 
 * @param CReason           Reason the round has ended.
 **/
stock void ToolsTerminateRound(int CReason)
{
    // Terminate round
    SDKCall(hSDKCallTerminateRound, gCvarList[CVAR_SERVER_RESTART_DELAY].FloatValue, CReason);
}
