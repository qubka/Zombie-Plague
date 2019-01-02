/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          tools_functions.cpp
 *  Type:          Game 
 *  Description:   API for offsets/signatures exposed in tools.cpp
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
 * @section Hud elements flags.
 **/
#define HIDEHUD_WEAPONSELECTION     (1<<0)   // Hide ammo count & weapon selection
#define HIDEHUD_FLASHLIGHT          (1<<1)
#define HIDEHUD_ALL                 (1<<2)
#define HIDEHUD_HEALTH              (1<<3)   // Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD          (1<<4)   // Hide when local player's dead
#define HIDEHUD_NEEDSUIT            (1<<5)   // Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS          (1<<6)   // Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT                (1<<7)   // Hide all communication elements (saytext, voice icon, etc)
#define HIDEHUD_CROSSHAIR           (1<<8)   // Hide crosshairs
#define HIDEHUD_VEHICLE_CROSSHAIR   (1<<9)   // Hide vehicle crosshair
#define HIDEHUD_INVEHICLE           (1<<10)
#define HIDEHUD_BONUS_PROGRESS      (1<<11)  // Hide bonus progress display (for bonus map challenges)
/**
 * @endsection
 **/
 
/**
 * @section Entity effects flags.
 **/
#define EF_BONEMERGE                (1<<0)     // Performs bone merge on client side
#define EF_BRIGHTLIGHT              (1<<1)     // DLIGHT centered at entity origin
#define EF_DIMLIGHT                 (1<<2)     // Player flashlight
#define EF_NOINTERP                 (1<<3)     // Don't interpolate the next frame
#define EF_NOSHADOW                 (1<<4)     // Disables shadow
#define EF_NODRAW                   (1<<5)     // Prevents the entity from drawing and networking
#define EF_NORECEIVESHADOW          (1<<6)     // Don't receive shadows
#define EF_BONEMERGE_FASTCULL       (1<<7)     // For use with EF_BONEMERGE. If this is set, then it places this ents origin at its parent and uses the parent's bbox + the max extents of the aiment. Otherwise, it sets up the parent's bones every frame to figure out where to place the aiment, which is inefficient because it'll setup the parent's bones even if the parent is not in the PVS.
#define EF_ITEM_BLINK               (1<<8)     // Makes the entity blink
#define EF_PARENT_ANIMATES          (1<<9)     // Always assume that the parent entity is animating
#define EF_FOLLOWBONE               (1<<10)    
/**
 * @endsection
 **/
 
/**
 * Tools flashlight function module init function.
 **/
void ToolsFInit(/*void*/)
{
    // Initialize command char
    static char sCommand[SMALL_LINE_LENGTH];
    
    // Validate alias
    if(hasLength(sCommand))
    {
        // Unhook listeners
        RemoveCommandListener2(ToolsOnFlashlight, sCommand);
    }
    
    // Gets menu command alias
    gCvarList[CVAR_GAME_CUSTOM_LIGHT_BUTTON].GetString(sCommand, sizeof(sCommand));
    
    // Validate alias
    if(!hasLength(sCommand))
    {
        // Unhook listeners
        RemoveCommandListener2(ToolsOnFlashlight, sCommand);
        return;
    }
    
    // Hook listeners
    AddCommandListener(ToolsOnFlashlight, sCommand);
}

/**
 * Creates commands for tools module.
 **/
void ToolsOnCommandsCreate(/*void*/)
{
    // Hook listeners
    AddCommandListener(ToolsOnGeneric, "kill");
    AddCommandListener(ToolsOnGeneric, "explode");
    AddCommandListener(ToolsOnGeneric, "killvector");
    AddCommandListener(ToolsOnGeneric, "jointeam");
    
    // Hook messages
    HookUserMessage(GetUserMessageId("TextMsg"), ToolsMessage, true);
}

/**
 * Hook tools cvar changes.
 **/
void ToolsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_GAME_CUSTOM_LIGHT_BUTTON] = FindConVar("zp_game_custom_light_button");  
    gCvarList[CVAR_MESSAGES_HELP]            = FindConVar("zp_messages_help");
    gCvarList[CVAR_MESSAGES_BLOCK]           = FindConVar("zp_messages_block");
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_GAME_CUSTOM_LIGHT_BUTTON], ToolsFCvarsHookEnable);
}

/**
 * Cvar hook callback (zp_game_custom_light_button)
 * Flashlight module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ToolsFCvarsHookEnable(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Forward event to modules
    ToolsFInit();
}
    
/**
 * Callback for command listeners.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action ToolsOnGeneric(const int clientIndex, const char[] commandMsg, const int iArguments)
{
    // Validate client 
    if(IsPlayerExist(clientIndex, false))
    {
        // Switches client commands
        switch(commandMsg[0])
        {
            // Suicide
            case 'k', 'e' : 
            {
                return Plugin_Handled;
            }
            
            // Jointeam
            case 'j' :
            {
                // Retrieves a command argument given its index
                static char sArg[SMALL_LINE_LENGTH];
                GetCmdArg(1, sArg, sizeof(sArg));

                // Gets team index
                int iTeam = StringToInt(sArg);

                // Switch team
                switch(GetClientTeam(clientIndex))
                {
                    // Non-playable team
                    case TEAM_NONE :
                    {
                        // Switch new team
                        switch(iTeam)
                        {
                            // Playable team
                            case TEAM_HUMAN, TEAM_ZOMBIE :
                            {
                                // Validate last disconnection delay
                                int iDelay = RoundToNearest(float(GetTime() - gClientData[clientIndex][Client_Time]) / 60.0);
                                if(iDelay > gCvarList[CVAR_SERVER_ROUNDTIME_ZP].IntValue || gServerData[Server_RoundMode] == -1)
                                {
                                    // Switch team
                                    ToolsSetClientTeam(clientIndex, !(clientIndex % 2) ? TEAM_HUMAN : TEAM_ZOMBIE);
                                    
                                    // If game round didn't start, then respawn
                                    if(gServerData[Server_RoundMode] == -1)
                                    {
                                        // Force client to respawn
                                        ToolsForceToRespawn(clientIndex);
                                    }
                                    else
                                    {   
                                        // Sets timer for respawn player
                                        delete gClientData[clientIndex][Client_RespawnTimer];
                                        gClientData[clientIndex][Client_RespawnTimer] = CreateTimer(ModesGetDelay(gServerData[Server_RoundMode]), DeathOnRespawn, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
                                    }

                                    // Fix first connection time
                                    if(gClientData[clientIndex][Client_Time] <= 0) gClientData[clientIndex][Client_Time] = GetTime();
                                    
                                    // Block command
                                    return Plugin_Handled;
                                }
                            }
                        }
                    }
                
                    // Spectator team
                    case TEAM_SPECTATOR :
                    {
                        // Switch new team
                        switch(iTeam)
                        {
                            // Playable team
                            case TEAM_HUMAN, TEAM_ZOMBIE :
                            {
                                // If game round didn't start, then respawn
                                if(gServerData[Server_RoundMode] == -1)
                                {
                                    // Switch team
                                    ToolsSetClientTeam(clientIndex, !(clientIndex % 2) ? TEAM_HUMAN : TEAM_ZOMBIE);
                                    
                                    // Force client to respawn
                                    ToolsForceToRespawn(clientIndex);
                                    
                                    // Block command
                                    return Plugin_Handled;
                                }
                            }
                        }
                    }
                    
                    // T team
                    case TEAM_ZOMBIE :
                    {
                        // Switch new team
                        switch(iTeam)
                        {
                            // Block command     
                            case TEAM_NONE, TEAM_HUMAN : return Plugin_Handled;
                        }
                    }
                    
                    // CT team
                    case TEAM_HUMAN :
                    {
                        // Switch new team
                        switch(iTeam)
                        {
                            // Block command     
                            case TEAM_NONE, TEAM_ZOMBIE : return Plugin_Handled;
                        }
                    }
                }
                
                // Forward event to modules
                VOverlayOnClientUpdate(clientIndex, Overlay_Reset);
            }
        }
    }
    
    // Allow commands
    return Plugin_Continue;
}

/**
 * Callback for command listener to on/off flashlight/nvgs.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action ToolsOnFlashlight(const int clientIndex, const char[] commandMsg, const int iArguments)
{
    // Validate client 
    if(IsPlayerExist(clientIndex))
    {
        // Gets class overlay
        static char sOverlay[PLATFORM_MAX_PATH];
        ClassGetOverlay(gClientData[clientIndex][Client_Class], sOverlay, sizeof(sOverlay));

        // Validate nvgs
        if(ClassIsNvgs(gClientData[clientIndex][Client_Class]) || hasLength(sOverlay)) 
        {
            // If round didn't end yet, then stop
            if(gServerData[Server_RoundEnd]) //! Avoid reset round end overlays
            {
                // Block command
                return Plugin_Handled;
            }
            
            // Switch on/off nightvision  
            VOverlayOnClientUpdate(clientIndex, ToolsGetClientNightVision(clientIndex, true) ? Overlay_Reset : Overlay_Vision);
            
            // Forward event to modules
            SoundsOnClientNvgs(clientIndex);
        }
        else
        {
            // Switch on/off flashlight
            ToolsSetClientFlashLight(clientIndex, true);
            
            // Forward event to modules
            SoundsOnClientFlashLight(clientIndex);
        }
        
        // Block command
        return Plugin_Handled;
    }
    
    // Allow command
    return Plugin_Continue;
}

/**
 * Hook client messages.
 *
 * @param iMessage          The message index.
 * @param hBuffer           Handle to the input bit buffer.
 * @param iPlayers          Array containing player indexes.
 * @param playersNum        Number of players in the array.
 * @param bReliable         True if message is reliable, false otherwise.
 * @param bInit             True if message is an initmsg, false otherwise.
 **/
public Action ToolsMessage(UserMsg iMessage, BfRead hBuffer, const int[] iPlayers, const int playersNum, const bool bReliable, const bool bInit)
{
    // Initialize engine message
    static char sTxtMsg[PLATFORM_MAX_PATH]; 
    PbReadString(hBuffer, "params", sTxtMsg, sizeof(sTxtMsg), 0); 

    // Initialize block message list
    static char sBlockMsg[PLATFORM_MAX_PATH];
    gCvarList[CVAR_MESSAGES_BLOCK].GetString(sBlockMsg, sizeof(sBlockMsg)); 

    // Block messages on the matching
    return (StrContains(sBlockMsg, sTxtMsg, false) != -1) ? Plugin_Handled : Plugin_Continue; 
}

/**
 * Client is join/leave the server.
 *
 * @param clientIndex       The client index.
 **/
void ToolsResetVars(const int clientIndex)
{
    // Resets all variables
    gClientData[clientIndex][Client_Zombie] = false;
    gClientData[clientIndex][Client_Skill] = false;
    gClientData[clientIndex][Client_Loaded] = false;
    gClientData[clientIndex][Client_AutoRebuy] = false;
    gClientData[clientIndex][Client_SkillCountDown] = 0.0;
    gClientData[clientIndex][Client_Class] = 0;
    gClientData[clientIndex][Client_HumanClassNext] = 0;
    gClientData[clientIndex][Client_ZombieClassNext] = 0;
    gClientData[clientIndex][Client_Respawn] = TEAM_HUMAN;
    gClientData[clientIndex][Client_RespawnTimes] = 0;
    gClientData[clientIndex][Client_Money] = 0;
    gClientData[clientIndex][Client_LastBoughtAmount] = 0;
    gClientData[clientIndex][Client_Level] = 1;
    gClientData[clientIndex][Client_Exp] = 0;
    gClientData[clientIndex][Client_DataID] = -1;
    gClientData[clientIndex][Client_Costume] = -1;
    gClientData[clientIndex][Client_Time] = 0;
    gClientData[clientIndex][Client_Spawn] = NULL_VECTOR;
    gClientData[clientIndex][Client_AttachmentCostume] = INVALID_ENT_REFERENCE;
    gClientData[clientIndex][Client_AttachmentBits] = 0;
    gClientData[clientIndex][Client_AttachmentAddons] = { INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE, INVALID_ENT_REFERENCE };
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
void ToolsForceToRespawn(const int clientIndex)
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
    int iDeathMatch = ModesGetMatch(gServerData[Server_RoundMode]);
    if(iDeathMatch == 1 || (iDeathMatch == 2 && GetRandomInt(0, 1)) || (iDeathMatch == 3 && fnGetHumans() < fnGetAlive() / 2))
    {
        gClientData[clientIndex][Client_Respawn] = TEAM_HUMAN;
    }
    // Respawn as zombie ?
    else
    {
        gClientData[clientIndex][Client_Respawn] = TEAM_ZOMBIE;
    }

    // Respawn a player
    CS_RespawnPlayer(clientIndex);
}

/**
 * Reset all player timers.
 *
 * @param clientIndex       The client index.
 **/
void ToolsResetTimers(const int clientIndex)
{
    delete gClientData[clientIndex][Client_LevelTimer];
    delete gClientData[clientIndex][Client_AccountTimer];
    delete gClientData[clientIndex][Client_RespawnTimer];
    delete gClientData[clientIndex][Client_SkillTimer];
    delete gClientData[clientIndex][Client_CountDownTimer];
    delete gClientData[clientIndex][Client_HealTimer];
    delete gClientData[clientIndex][Client_MoanTimer];
    delete gClientData[clientIndex][Client_AmbientTimer];
}

/**
 * Purge all player timers.
 *
 * @param clientIndex       The client index.
 **/
void ToolsPurgeTimers(const int clientIndex)
{
    gClientData[clientIndex][Client_LevelTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_AccountTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_RespawnTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_SkillTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_CountDownTimer] = INVALID_HANDLE;
    gClientData[clientIndex][Client_HealTimer] = INVALID_HANDLE;    
    gClientData[clientIndex][Client_MoanTimer] = INVALID_HANDLE; 
    gClientData[clientIndex][Client_AmbientTimer] = INVALID_HANDLE; 
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
stock void ToolsClientVelocity(const int clientIndex, float vecVelocity[3], const bool bApply = true, const bool bStack = true)
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
stock void ToolsGetClientVelocity(const int clientIndex, float vecVelocity[3])
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
 * @param iValue            The health value.
 * @param bSet              True to set maximum value, false to modify health.  
 **/
stock void ToolsSetClientHealth(const int clientIndex, const int iValue, const bool bSet = false)
{
    // Sets health of client
    SetEntData(clientIndex, g_iOffset_PlayerHealth, iValue, _, true);
    
    // If set is true, then set max health
    if(bSet) 
    {
        // Find the datamap
        if(!g_iOffset_PlayerMaxHealth)
        {
            g_iOffset_PlayerMaxHealth  = FindDataMapInfo(clientIndex, "m_iMaxHealth");
        }

        // Sets max health of client
        SetEntData(clientIndex, g_iOffset_PlayerMaxHealth, iValue, _, true);
    }
}

/**
 * Set a client lagged movement value.
 *
 * @param clientIndex       The client index.
 * @param flValue           The LMV value.
 **/
stock void ToolsSetClientLMV(const int clientIndex, const float flValue)
{
    // Sets lagged movement value of client
    SetEntDataFloat(clientIndex, g_iOffset_PlayerLMV, flValue, true);
}

/**
 * Set a client armor value.
 * @param clientIndex       The client index.
 * @param iValue            The armor value.
 **/
stock void ToolsSetClientArmor(const int clientIndex, const int iValue)
{
    // Sets armor of client
    SetEntData(clientIndex, g_iOffset_PlayerArmor, iValue, _, true);
}

/**
 * Set a client team index.
 *
 * @param clientIndex       The client index.
 * @param iValue            The team index.
 **/
stock void ToolsSetClientTeam(const int clientIndex, const int nTeam)
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
        CS_SwitchTeam(clientIndex, nTeam); 
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
stock bool ToolsGetClientNightVision(const int clientIndex, const bool bOwnership = false)
{
    // If ownership is true, then gets the ownership of nightvision on client
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
stock void ToolsSetClientNightVision(const int clientIndex, const bool bEnable, const bool bOwnership = false)
{
    // If ownership is true, then toggle the ownership of nightvision on client
    SetEntData(clientIndex, bOwnership ? g_iOffset_PlayerHasNightVision : g_iOffset_PlayerNightVisionOn, bEnable, _, true);
}

/**
 * Get defuser value on a client.
 *
 * @param clientIndex       The client index.
 * @return                  The aspect of the client defuser.
 **/
stock bool ToolsGetClientDefuser(const int clientIndex, const bool bOwnership = false)
{
    // Gets value on the client
    return view_as<bool>(GetEntData(clientIndex, g_iOffset_PlayerHasDefuser, 1));
}

/**
 * Control defuser value on a client.
 *
 * @param clientIndex       The client index.
 * @param bEnable           Enable or disable an aspect of defuser.
 **/
stock void ToolsSetClientDefuser(const int clientIndex, const bool bEnable)
{
    // Sets value on the client
    SetEntData(clientIndex, g_iOffset_PlayerHasDefuser, bEnable, _, true);
}

/**
 * Set a client score or deaths.
 * 
 * @param clientIndex       The client index.
 * @param bScore            True to look at score, false to look at deaths.  
 * @param iValue            The value of the client score or deaths.
 **/
stock void ToolsSetClientScore(const int clientIndex, const bool bScore = true, const int iValue = 0)
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
 * @param clientIndex       The client index.
 * @param bScore            True to look at score, false to look at deaths.  
 * @return                  The score or death count of the client.
 **/
stock int ToolsGetClientScore(const int clientIndex, const bool bScore = true)
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
stock void ToolsSetClientGravity(const int clientIndex, const float flValue)
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
stock void ToolsSetClientSpot(const int clientIndex, const bool bEnable)
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
stock void ToolsSetClientDetecting(const int clientIndex, const bool bEnable)
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
stock void ToolsSetClientHud(const int clientIndex, const bool bEnable)
{   
    // Sets value on the client
    SetEntData(clientIndex, g_iOffset_PlayerHUD, bEnable ? (GetEntData(clientIndex, g_iOffset_PlayerHUD) & ~HIDEHUD_CROSSHAIR) : (GetEntData(clientIndex, g_iOffset_PlayerHUD) | HIDEHUD_CROSSHAIR), _, true);
}

/**
 * Set a client flashlight.
 * 
 * @param clientIndex       The client index.
 * @param bEnable           Enable or disable an aspect of flashlight.
 **/
stock void ToolsSetClientFlashLight(const int clientIndex, const bool bEnable)
{
    // Sets value on the client
    SetEntData(clientIndex, g_iOffset_EntityEffects, bEnable ? (GetEntData(clientIndex, g_iOffset_EntityEffects) ^ EF_DIMLIGHT) : 0, _, true);
}

/**
 * Set a client fov.
 * 
 * @param clientIndex       The client index.
 * @param iFov              (Optional) The fov amount.
 **/
stock void ToolsSetClientFov(const int clientIndex, const int iFov = 90)
{
    // Sets value on the client
    SetEntData(clientIndex, g_iOffset_PlayerFov, iFov, _, true);
    SetEntData(clientIndex, g_iOffset_PlayerDefaultFOV, iFov, _, true);
}

/*_____________________________________________________________________________________________________*/

/**
 * Update a entity transmit state.
 * 
 * @param entityIndex       The entity index.
 **/
stock void ToolsUpdateTransmitState(const int entityIndex)
{
    SDKCall(hSDKCallEntityUpdateTransmitState, entityIndex);
}

/**
 * Validate the attachment on the entity.
 *
 * @param entityIndex       The entity index.
 * @param sAttach           The attachment name.
 * @return                  True or false.
 **/
stock bool ToolsLookupAttachment(const int entityIndex, const char[] sAttach)
{
    return (hasLength(sAttach) && SDKCall(hSDKCallLookupAttachment, entityIndex, sAttach));
}

/**
 * Gets the attachment of the entity.
 *
 * @param entityIndex       The entity index.
 * @param sAttach           The attachment name.
 * @param vOrigin           The origin ouput.
 * @param vAngle            The angle ouput.
 **/
stock void ToolsGetAttachment(const int entityIndex, const char[] sAttach, float vOrigin[3], float vAngle[3])
{
    // Validate length
    if(!hasLength(sAttach))
    {
        return;
    }
    
    // Validate windows
    if(GameEnginePlatform(OS_Windows))
    {
        SDKCall(hSDKCallGetAttachment_Windows, entityIndex, sAttach, vOrigin, vAngle); 
    }
    else
    {
        int iAnimating = SDKCall(hSDKCallLookupAttachment, entityIndex, sAttach);
        if(iAnimating)
        {
            SDKCall(hSDKCallGetAttachment_Linux, entityIndex, iAnimating, vOrigin, vAngle); 
        }
    }
}