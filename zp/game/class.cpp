/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          class.cpp
 *  Type:          Game 
 *  Description:   Provides functions for managing classes.
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
 * Infects a client.
 *
 * @param victimIndex       The victim index.
 * @param attackerIndex     (Optional) The attacker index.
 * @param nemesisMode       (Optional) Indicates that client will be a nemesis.
 * @param respawnMode       (Optional) Indicates that infection was on spawn.
 **/
void ClassMakeZombie(const int victimIndex, const int attackerIndex = 0, const bool nemesisMode = false, const bool respawnMode = false)
{
    // Validate client 
    if(!IsPlayerExist(victimIndex))
    {
        return;
    }
    
    //*********************************************************************
    //*           REWARDS AND BONUSES FOR INFECTOR OF THE HUMAN           *
    //*********************************************************************
    
    // Verify that the infector is exist
    if(IsPlayerExist(attackerIndex)) 
    {
        // Create a fake event
        EventFakePlayerDeath(victimIndex, attackerIndex);
        
        // Increment kills and frags
        ToolsSetClientScore(victimIndex, true, ToolsGetClientScore(victimIndex, true));
        ToolsSetClientScore(victimIndex, false, ToolsGetClientScore(victimIndex, false));
        
        // Increment exp and bonuses
        ToolsSetClientHealth(attackerIndex, GetClientHealth(attackerIndex) + gCvarList[CVAR_BONUS_INFECT_HEALTH].IntValue);
        AccountSetClientCash(attackerIndex, gClientData[attackerIndex][Client_AmmoPacks] + gCvarList[CVAR_BONUS_INFECT].IntValue);
        LevelSystemOnSetExp(attackerIndex, gClientData[attackerIndex][Client_Exp] + gCvarList[CVAR_LEVEL_INFECT].IntValue);
    }
    // If infection was done by server
    else if(!attackerIndex)
    {
        // Return ammopacks, which was spent before server infection
        AccountSetClientCash(victimIndex, gClientData[victimIndex][Client_AmmoPacks] + gClientData[victimIndex][Client_LastBoughtAmount]);
        gClientData[victimIndex][Client_LastBoughtAmount] = 0;
    }

    //*********************************************************************
    //*                  UPDATE VARIABLES OF THE PLAYER                   *
    //*********************************************************************
    
    // Resets some tools
    ToolsResetTimers(victimIndex);
    ToolsSetClientDetecting(victimIndex, false);
    ToolsSetClientFlashLight(victimIndex, false); 
    ToolsSetClientHud(victimIndex, false);
    
    // Resets some variables
    gClientData[victimIndex][Client_Zombie] = true;
    gClientData[victimIndex][Client_Survivor] = false;
    gClientData[victimIndex][Client_Nemesis] = false;
    gClientData[victimIndex][Client_Skill] = false;
    gClientData[victimIndex][Client_SkillCountDown] = 0.0;

    //*********************************************************************
    //*       UPDATE MODELS AND SET ZOMBIE/NEMESIS CLASS PROPERTIES       *
    //*********************************************************************
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    
    // Sets nemesis properties
    if(nemesisMode)
    {
        // Sets nemesis variable
        gClientData[victimIndex][Client_Nemesis] = true;
        
        // Update zombie class
        gClientData[victimIndex][Client_ZombieClass] = 0;
        
        // Sets health, speed and gravity and armor
        ToolsSetClientHealth(victimIndex, (fnGetAlive() * gCvarList[CVAR_NEMESIS_HEALTH].IntValue));
        ToolsSetClientLMV(victimIndex, gCvarList[CVAR_NEMESIS_SPEED].FloatValue); 
        ToolsSetClientGravity(victimIndex, gCvarList[CVAR_NEMESIS_GRAVITY].FloatValue);
        ToolsSetClientArmor(victimIndex, 0);
        
        // Gets nemesis model
        gCvarList[CVAR_NEMESIS_PLAYER_MODEL].GetString(sModel, sizeof(sModel));
        
        // Remove player weapons
        if(WeaponsRemoveAll(victimIndex, gCvarList[CVAR_N_DEFAULT_MELEE])) //! Give default
        {
            // Give default weapon
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_N_DEFAULT_GRENADES]);
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_N_DEFAULT_SECONDARY]);
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_N_DEFAULT_PRIMARY]);
        }
    }
    
    // Sets zombie properties
    else
    {
        // Update zombie class
        gClientData[victimIndex][Client_ZombieClass] = gClientData[victimIndex][Client_ZombieClassNext]; ZombieOnValidate(victimIndex);

        // Sets health, speed and gravity and armor
        ToolsSetClientHealth(victimIndex, ZombieGetHealth(gClientData[victimIndex][Client_ZombieClass]) + ((fnGetZombies() <= 1) ? (fnGetAlive() * gCvarList[CVAR_ZOMBIE_FISRT_HEALTH].IntValue) : (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? RoundToFloor((gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[victimIndex][Client_Level]))) : 0)));
        ToolsSetClientLMV(victimIndex, ZombieGetSpeed(gClientData[victimIndex][Client_ZombieClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[victimIndex][Client_Level])) : 0.0));
        ToolsSetClientGravity(victimIndex, ZombieGetGravity(gClientData[victimIndex][Client_ZombieClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[victimIndex][Client_Level])) : 0.0));
        ToolsSetClientArmor(victimIndex, 0);
        
        // Gets zombie model
        ZombieGetModel(gClientData[victimIndex][Client_ZombieClass], sModel, sizeof(sModel));
        
        // Remove player weapons
        if(WeaponsRemoveAll(victimIndex, gCvarList[CVAR_Z_DEFAULT_MELEE])) //! Give default
        {
            // Give default weapon
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_Z_DEFAULT_GRENADES]);
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_Z_DEFAULT_SECONDARY]);
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_Z_DEFAULT_PRIMARY]);
        }
        // If help messages enable, then show 
        if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
        {
            // Gets zombie info
            static char sInfo[BIG_LINE_LENGTH];
            ZombieGetInfo(gClientData[victimIndex][Client_ZombieClass], sInfo, sizeof(sInfo));
            
            // Show zombie personal info
            if(strlen(sInfo)) TranslationPrintHintText(victimIndex, sInfo);
        }
    }
    
    // Apply model
    if(strlen(sModel)) SetEntityModel(victimIndex, sModel);

    // Forward event to modules
    SkillsOnClientInfected(victimIndex, nemesisMode);
    SoundsOnClientInfected(victimIndex, respawnMode);
    VEffectsOnClientInfected(victimIndex, nemesisMode, respawnMode);
    LevelSystemOnClientUpdate(victimIndex);
    if(gCvarList[CVAR_ZOMBIE_NIGHT_VISION]) VOverlayOnClientUpdate(victimIndex, Overlay_Vision);
    RequestFrame(view_as<RequestFrameCallback>(AccountOnClientUpdate), GetClientUserId(victimIndex));
    RequestFrame(view_as<RequestFrameCallback>(WeaponsOnClientUpdate), GetClientUserId(victimIndex));
    
    // Switch to T
    ToolsSetClientTeam(victimIndex, TEAM_ZOMBIE);
    
    // Terminate the round, if all human was infected
    RoundEndOnValidate();

    // Call forward
    API_OnClientInfected(victimIndex, attackerIndex, nemesisMode, respawnMode);
}

/**
 * Humanize a client.
 * 
 * @param clientIndex       The client index.
 * @param survivorMode      (Optional) Indicates that client will be a survivor.
 * @param respawnMode       (Optional) Indicates that humanizing was on spawn.
 **/
void ClassMakeHuman(const int clientIndex, const bool survivorMode = false, const bool respawnMode = false)
{
    // Validate client 
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    //*********************************************************************
    //*                  UPDATE VARIABLES OF THE PLAYER                   *
    //*********************************************************************
    
    // Resets some tools
    ToolsResetTimers(clientIndex);
    ToolsSetClientDetecting(clientIndex, (gCvarList[CVAR_ZOMBIE_XRAY].BoolValue && !respawnMode));
    ToolsSetClientFlashLight(clientIndex, false);
    ToolsSetClientHud(clientIndex, true);
    
    // Resets some variables
    gClientData[clientIndex][Client_Zombie] = false;
    gClientData[clientIndex][Client_Survivor] = false;
    gClientData[clientIndex][Client_Nemesis] = false;
    gClientData[clientIndex][Client_Skill] = false;
    gClientData[clientIndex][Client_SkillCountDown] = 0.0;
    if(respawnMode) 
    {
        gClientData[clientIndex][Client_LastBoughtAmount] = 0;
        gClientData[clientIndex][Client_RespawnTimes] = 0;
        
        // Resets limit of extra items
        ItemsRemoveLimits(clientIndex);
    }

    //*********************************************************************
    //*       UPDATE MODELS AND SET HUMAN/SURVIVOR CLASS PROPERTIES       *
    //*********************************************************************
    
    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH]; static char sArm[PLATFORM_MAX_PATH];
    
    // Sets survivor properties
    if(survivorMode)
    {
        // Sets survivor variable
        gClientData[clientIndex][Client_Survivor] = true;
    
        // Update human class
        gClientData[clientIndex][Client_HumanClass] = 0;
        
        // Sets survivor health, speed, gravity and armor
        ToolsSetClientHealth(clientIndex, (fnGetAlive() * gCvarList[CVAR_SURVIVOR_HEALTH].IntValue));
        ToolsSetClientLMV(clientIndex, gCvarList[CVAR_SURVIVOR_SPEED].FloatValue); 
        ToolsSetClientGravity(clientIndex, gCvarList[CVAR_SURVIVOR_GRAVITY].FloatValue);
        ToolsSetClientArmor(clientIndex, 0);
        
        // Gets survivor model
        gCvarList[CVAR_SURVIVOR_PLAYER_MODEL].GetString(sModel, sizeof(sModel)); sArm[0] = '\0';
        
        // Remove player weapons
        if(WeaponsRemoveAll(clientIndex, gCvarList[CVAR_S_DEFAULT_MELEE])) //! Give default
        {
            // Give default weapon
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_S_DEFAULT_GRENADES]);
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_S_DEFAULT_SECONDARY]);
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_S_DEFAULT_PRIMARY]);
        }
    }
    else
    {
        // Update human class
        gClientData[clientIndex][Client_HumanClass] = gClientData[clientIndex][Client_HumanClassNext]; HumanOnValidate(clientIndex);

        // Sets health, speed, gravity and armor
        ToolsSetClientHealth(clientIndex, HumanGetHealth(gClientData[clientIndex][Client_HumanClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? RoundToFloor((gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level]))) : 0));
        ToolsSetClientLMV(clientIndex, HumanGetSpeed(gClientData[clientIndex][Client_HumanClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level])) : 0.0));
        ToolsSetClientGravity(clientIndex, HumanGetGravity(gClientData[clientIndex][Client_HumanClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level])) : 0.0));
        ToolsSetClientArmor(clientIndex, (GetClientArmor(clientIndex) < HumanGetArmor(gClientData[clientIndex][Client_HumanClass])) ? HumanGetArmor(gClientData[clientIndex][Client_HumanClass]) : GetClientArmor(clientIndex));

        // Gets human models
        HumanGetArmModel(gClientData[clientIndex][Client_HumanClass], sArm, sizeof(sArm)); HumanGetModel(gClientData[clientIndex][Client_HumanClass], sModel, sizeof(sModel));

        // Remove player weapons
        if(WeaponsRemoveAll(clientIndex, gCvarList[CVAR_H_DEFAULT_MELEE])) //! Give default
        {
            // Give default weapon
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_H_DEFAULT_GRENADES]);
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_H_DEFAULT_SECONDARY]);
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_H_DEFAULT_PRIMARY]);
        }
    }
    
    // Apply models
    if(strlen(sModel)) SetEntityModel(clientIndex, sModel);
    if(strlen(sArm)) SetEntDataString(clientIndex, g_iOffset_PlayerArms, sArm, sizeof(sArm), true);
    
    // Forward event to modules
    SoundsOnClientHumanized(clientIndex);
    VEffectsOnClientHumanized(clientIndex, survivorMode, respawnMode);
    VOverlayOnClientUpdate(clientIndex, Overlay_Reset);
    LevelSystemOnClientUpdate(clientIndex);
    RequestFrame(view_as<RequestFrameCallback>(AccountOnClientUpdate), GetClientUserId(clientIndex));
    RequestFrame(view_as<RequestFrameCallback>(WeaponsOnClientUpdate), GetClientUserId(clientIndex));
    
    // Validate non-respawn
    if(!respawnMode) 
    {
        // Switch to CT
        ToolsSetClientTeam(clientIndex, TEAM_HUMAN);
    }
    
    // Call forward
    API_OnClientHumanized(clientIndex, survivorMode, respawnMode);
}
