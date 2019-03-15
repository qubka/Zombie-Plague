/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          apply.cpp
 *  Type:          Module
 *  Description:   Functions for applying attributes of class on a client.
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
 * @brief Client has been spawned.
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 **/
void ApplyOnClientSpawn(int clientIndex)
{ 
    // If mode doesn't started yet, then reset
    if(gServerData.RoundNew) 
    {
        // Resets some variables
        gClientData[clientIndex].RespawnTimes = 0;
        gClientData[clientIndex].Respawn = TEAM_HUMAN;
        gClientData[clientIndex].LastPurchase = 0;
        
        // Resets limit of weapons/items
        ItemsRemoveLimits(clientIndex);
        WeaponsRemoveLimits(clientIndex);
    }
    
    // Initialize type char
    static char sType[SMALL_LINE_LENGTH];
    
    // Validate respawn
    switch(gClientData[clientIndex].Respawn)
    {
        // Respawn as zombie?
        case TEAM_ZOMBIE : 
        {
            // Gets zombie class type
            ModesGetZombieClass(gServerData.RoundMode, sType, sizeof(sType));
    
            // Make zombies
            ApplyOnClientUpdate(clientIndex, _, hasLength(sType) ? sType : "zombie");
        }
        
        // Respawn as human ?
        case TEAM_HUMAN  : 
        {
            // Gets human class type
            ModesGetHumanClass(gServerData.RoundMode, sType, sizeof(sType));
        
            // Make humans
            ApplyOnClientUpdate(clientIndex, _, hasLength(sType) ? sType : "human");
        }
    }    
}

/**
 * @brief Infects/humanize a client.
 *
 * @param clientIndex       The victim index.
 * @param attackerIndex     (Optional) The attacker index.
 * @param sType             (Optional) The class type.
 * @return                  True or false.
 **/
bool ApplyOnClientUpdate(int clientIndex, int attackerIndex = 0, char[] sType = "zombie")
{
    // Validate client 
    if(!IsPlayerExist(clientIndex))
    {
        return false;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Validate human
    if(!strcmp(sType, "human", false))
    {
        // Update class class
        gClientData[clientIndex].Class = gClientData[clientIndex].HumanClassNext; HumanValidateClass(clientIndex);
        gClientData[clientIndex].Zombie = false;
        
        // If mode doesn't started yet, then allow
        if(gServerData.RoundNew)
        {
            // If instant human class menu enable, then open 
            if(gCvarList[CVAR_HUMAN_MENU].BoolValue)
            {
                // Opens the human classes menu
                ClassMenu(clientIndex, "choose humanclass", "human", gClientData[clientIndex].HumanClassNext, true);
            }
        }
    }
    // Validate zombie
    else if(!strcmp(sType, "zombie", false))
    {
        // Update class class
        gClientData[clientIndex].Class = gClientData[clientIndex].ZombieClassNext; ZombieValidateClass(clientIndex);
        gClientData[clientIndex].Zombie = true;
        
        // If instant zombie class menu enable, then open 
        if(gCvarList[CVAR_ZOMBIE_MENU].BoolValue)
        {
            // Opens the zombie classes menu
            ClassMenu(clientIndex, "choose zombieclass", "zombie", gClientData[clientIndex].ZombieClassNext, true);
        }
    }
    // Validate custom
    else
    {
        // Validate class index
        int iD = ClassTypeToIndex(sType);
        if(iD == -1)
        {
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class type: \"%s\"", sType);
            return false;
        }

        // Update class class
        gClientData[clientIndex].Class = iD;
        gClientData[clientIndex].Zombie = ClassIsZombie(gClientData[clientIndex].Class);
    }
    
    // Delete player timers
    gClientData[clientIndex].ResetTimers();
    
    // Resets some tools
    ToolsSetClientFlashLight(clientIndex, false);
    ToolsSetClientDetecting(clientIndex, false);
    
    // Resets some variables
    gClientData[clientIndex].Skill = false;
    gClientData[clientIndex].SkillCounter = 0.0;
    
    // Remove player weapons
    if(WeaponsRemoveAll(clientIndex)) /// Give default
    {
        // Gets class weapons
        static int iWeapon[SMALL_LINE_LENGTH];
        ClassGetWeapon(gClientData[clientIndex].Class, iWeapon, sizeof(iWeapon));
        
        // i = weapon id
        for(int i = 0; i < sizeof(iWeapon); i++)
        {
            // Give weapons
            WeaponsGive(clientIndex, iWeapon[i]);
        }
    }
    
    // Sets health, speed and gravity and armor
    ToolsSetClientHealth(clientIndex, ClassGetHealth(gClientData[clientIndex].Class) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? RoundToNearest(gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[clientIndex].Level)) : 0), true);
    ToolsSetClientLMV(clientIndex, ClassGetSpeed(gClientData[clientIndex].Class) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[clientIndex].Level)) : 0.0));
    ToolsSetClientGravity(clientIndex, ClassGetGravity(gClientData[clientIndex].Class) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[clientIndex].Level)) : 0.0));
    ToolsSetClientArmor(clientIndex, (GetClientArmor(clientIndex) < ClassGetArmor(gClientData[clientIndex].Class)) ? ClassGetArmor(gClientData[clientIndex].Class) : GetClientArmor(clientIndex));
    ToolsSetClientHud(clientIndex, ClassIsCross(gClientData[clientIndex].Class));
    ToolsSetClientSpot(clientIndex, ClassIsSpot(gClientData[clientIndex].Class));
    ToolsSetClientFov(clientIndex, ClassGetFov(gClientData[clientIndex].Class));

    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    
    // Gets class player models
    ClassGetModel(gClientData[clientIndex].Class, sModel, sizeof(sModel));
    if(hasLength(sModel)) SetEntityModel(clientIndex, sModel);
    
    // Gets class arm models
    ClassGetArmModel(gClientData[clientIndex].Class, sModel, sizeof(sModel)); 
    if(hasLength(sModel)) ToolsSetClientArm(clientIndex, sModel, sizeof(sModel));
    
    // If help messages enabled, then show info
    if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
    {
        // Gets class info
        ClassGetInfo(gClientData[clientIndex].Class, sModel, sizeof(sModel));
        
        // Show personal info
        if(hasLength(sModel)) TranslationPrintHintText(clientIndex, sModel);
    }

    /*_________________________________________________________________________________________________________________________________________*/
    
    // Validate attacker
    if(IsPlayerExist(attackerIndex, false)) 
    {
        // Create a fake death event
        static char sIcon[SMALL_LINE_LENGTH];
        gCvarList[CVAR_INFECT_ICON].GetString(sIcon, sizeof(sIcon));
        DeathOnClientHUD(clientIndex, attackerIndex, sIcon, gCvarList[CVAR_HEAD_ICON].BoolValue);
        
        // Increment kills and frags
        ToolsSetClientScore(attackerIndex, true, ToolsGetClientScore(attackerIndex, true) + 1);
        ToolsSetClientScore(clientIndex, false, ToolsGetClientScore(clientIndex, false) + 1);
        
        // Gets class exp and money bonuses
        static int iExp[6]; static int iMoney[6];
        ClassGetExp(gClientData[attackerIndex].Class, iExp, sizeof(iExp));
        ClassGetMoney(gClientData[attackerIndex].Class, iMoney, sizeof(iMoney));
        
        // Increment money/exp
        LevelSystemOnSetExp(attackerIndex, gClientData[attackerIndex].Exp + iExp[BonusType_Infect]);
        AccountSetClientCash(attackerIndex, gClientData[attackerIndex].Money + iMoney[BonusType_Infect]);
        
        // If attacker is alive, then give lifesteal 
        if(IsPlayerAlive(attackerIndex)) 
        {
            // Add lifesteal health
            ToolsSetClientHealth(attackerIndex, GetClientHealth(attackerIndex) + ClassGetLifeSteal(gClientData[attackerIndex].Class));
        }
    }
    // If change was done by server
    else if(!attackerIndex)
    {
        // Return money, which was spent before server change
        AccountSetClientCash(clientIndex, gClientData[clientIndex].Money + gClientData[clientIndex].LastPurchase);
        
        // Validate respawn on the change
        if(ModesIsEscape(gServerData.RoundMode))
        {
            // Gets spawn position
            static float vOrigin[3];
            SpawnGetRandomPosition(vOrigin);
            
            // Teleport player back on the spawn point
            TeleportEntity(clientIndex, vOrigin, NULL_VECTOR, NULL_VECTOR);
        }
    } gClientData[clientIndex].LastPurchase = 0; /// Reset purhase amount
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Validate zombie
    if(gClientData[clientIndex].Zombie)
    {
        // Forward event to modules
        SoundsOnClientInfected(clientIndex, attackerIndex);
        VEffectsOnClientInfected(clientIndex, attackerIndex);
    }
    else
    {
        // Forward event to modules
        VEffectsOnClientHumanized(clientIndex);
    }
    
    // Forward event to modules
    SoundsOnClientUpdate(clientIndex);
    SkillSystemOnClientUpdate(clientIndex);
    LevelSystemOnClientUpdate(clientIndex);
    VOverlayOnClientUpdate(clientIndex, Overlay_Reset);
    if(gClientData[clientIndex].Vision) VOverlayOnClientUpdate(clientIndex, Overlay_Vision); /// HACK~HACK
    _call.AccountOnClientUpdate(clientIndex);
    _call.WeaponsOnClientUpdate(clientIndex);
    
    // If mode already started, then change team
    if(!gServerData.RoundNew)
    {
        // Validate zombie
        if(gClientData[clientIndex].Zombie)
        {
            // Switch team
            ToolsSetClientTeam(clientIndex, TEAM_ZOMBIE);
        }
        else
        {
            // Switch team
            ToolsSetClientTeam(clientIndex, TEAM_HUMAN);
            
            // Sets glowing for the zombie vision
            ToolsSetClientDetecting(clientIndex, ModesIsXRay(gServerData.RoundMode));
        }
        
        // Terminate the round
        ModesValidateRound();
    }

    // Call forward
    gForwardData._OnClientUpdated(clientIndex, attackerIndex);
    return true;
}

/**
 * @brief Sets a client team index. (Alive only)
 *
 * @param clientIndex       The client index.
 * @param iTeam             The team index.
 **/
void ApplyOnClientTeam(int clientIndex, int iTeam)
{
    // Switch team
    bool bState = ToolsGetClientDefuser(clientIndex);
    ToolsSetClientTeam(clientIndex, iTeam);
    ToolsSetClientDefuser(clientIndex, bState); /// HACK~HACK

    // Sets glowing for the zombie vision
    ToolsSetClientDetecting(clientIndex, ModesIsXRay(gServerData.RoundMode));
}   