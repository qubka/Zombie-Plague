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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @brief Client has been spawned.
 * 
 * @param client            The victim index.
 * @param attacker          The attacker index.
 **/
void ApplyOnClientSpawn(int client)
{ 
    // If mode doesn't started yet, then reset
    if(gServerData.RoundNew) 
    {
        // Resets some variables
        gClientData[client].RespawnTimes = 0;
        gClientData[client].Respawn = TEAM_HUMAN;
        gClientData[client].LastPurchase = 0;
        
        // Resets limit of weapons/items
        ItemsRemoveLimits(client);
        WeaponsRemoveLimits(client);
    }
    
    // Initialize type char
    static char sType[SMALL_LINE_LENGTH];
    
    // Validate respawn
    switch(gClientData[client].Respawn)
    {
        // Respawn as zombie?
        case TEAM_ZOMBIE : 
        {
            // Gets zombie class type
            ModesGetZombieClass(gServerData.RoundMode, sType, sizeof(sType));
    
            // Make zombies
            ApplyOnClientUpdate(client, _, hasLength(sType) ? sType : "zombie");
        }
        
        // Respawn as human ?
        case TEAM_HUMAN  : 
        {
            // Gets human class type
            ModesGetHumanClass(gServerData.RoundMode, sType, sizeof(sType));
        
            // Make humans
            ApplyOnClientUpdate(client, _, hasLength(sType) ? sType : "human");
        }
    }    
}

/**
 * @brief Infects/humanize a client.
 *
 * @param client            The victim index.
 * @param attacker          (Optional) The attacker index.
 * @param sType             (Optional) The class type.
 * @return                  True or false.
 **/
bool ApplyOnClientUpdate(int client, int attacker = 0, char[] sType = "zombie")
{
    // Validate client 
    if(!IsPlayerExist(client))
    {
        return false;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Validate human
    if(!strcmp(sType, "human", false))
    {
        // Update class class
        gClientData[client].Class = gClientData[client].HumanClassNext; HumanValidateClass(client);
        gClientData[client].Zombie = false;
        
        // If mode doesn't started yet, then allow
        if(gServerData.RoundNew)
        {
            // If instant human class menu enable, then open 
            if(gCvarList[CVAR_HUMAN_MENU].BoolValue)
            {
                // Opens the human classes menu
                ClassMenu(client, "choose humanclass", "human", gClientData[client].HumanClassNext, true);
            }
        }
    }
    // Validate zombie
    else if(!strcmp(sType, "zombie", false))
    {
        // Update class class
        gClientData[client].Class = gClientData[client].ZombieClassNext; ZombieValidateClass(client);
        gClientData[client].Zombie = true;
        
        // If instant zombie class menu enable, then open 
        if(gCvarList[CVAR_ZOMBIE_MENU].BoolValue)
        {
            // Opens the zombie classes menu
            ClassMenu(client, "choose zombieclass", "zombie", gClientData[client].ZombieClassNext, true);
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
        gClientData[client].Class = iD;
        gClientData[client].Zombie = ClassIsZombie(gClientData[client].Class);
    }
    
    // Delete player timers
    gClientData[client].ResetTimers();
    
    // Resets some tools
    ToolsSetFlashLight(client, false);
    ToolsSetDetecting(client, false);
    
    // Resets some variables
    gClientData[client].Skill = false;
    gClientData[client].SkillCounter = 0.0;
    
    // Remove player weapons
    if(WeaponsRemove(client)) /// Give default
    {
        // Gets class weapons
        static int iWeapon[SMALL_LINE_LENGTH];
        ClassGetWeapon(gClientData[client].Class, iWeapon, sizeof(iWeapon));
        
        // i = weapon id
        for(int i = 0; i < sizeof(iWeapon); i++)
        {
            // Give weapons
            WeaponsGive(client, iWeapon[i]);
        }
    }
    
    // Sets health, speed and gravity and armor
    ToolsSetHealth(client, ClassGetHealth(gClientData[client].Class) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? RoundToNearest(gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[client].Level)) : 0), true);
    ToolsSetLMV(client, ClassGetSpeed(gClientData[client].Class) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[client].Level)) : 0.0));
    ToolsSetGravity(client, ClassGetGravity(gClientData[client].Class) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[client].Level)) : 0.0));
    ToolsSetArmor(client, (ToolsGetArmor(client) < ClassGetArmor(gClientData[client].Class)) ? ClassGetArmor(gClientData[client].Class) : ToolsGetArmor(client));
    ToolsSetHud(client, ClassIsCross(gClientData[client].Class));
    ToolsSetSpot(client, ClassIsSpot(gClientData[client].Class));
    ToolsSetFov(client, ClassGetFov(gClientData[client].Class));

    // Initialize model char
    static char sModel[PLATFORM_LINE_LENGTH];
    
    // Gets class player models
    ClassGetModel(gClientData[client].Class, sModel, sizeof(sModel));
    if(hasLength(sModel)) SetEntityModel(client, sModel);
    
    // Gets class arm models
    ClassGetArmModel(gClientData[client].Class, sModel, sizeof(sModel)); 
    if(hasLength(sModel)) ToolsSetArm(client, sModel);
    
    // If help messages enabled, then show info
    if(gCvarList[CVAR_MESSAGES_CLASS_INFO].BoolValue)
    {
        // Gets class info
        ClassGetInfo(gClientData[client].Class, sModel, sizeof(sModel));
        
        // Show personal info
        if(hasLength(sModel)) TranslationPrintHintText(client, sModel);
    }

    /*_________________________________________________________________________________________________________________________________________*/
    
    // Validate attacker
    if(IsPlayerExist(attacker, false)) 
    {
        // Create a fake death event
        static char sIcon[SMALL_LINE_LENGTH];
        gCvarList[CVAR_ICON_INFECT].GetString(sIcon, sizeof(sIcon));
        DeathCreateIcon(GetClientUserId(client), GetClientUserId(attacker), sIcon, gCvarList[CVAR_ICON_HEAD].BoolValue);
        
        // Increment kills and frags
        ToolsSetScore(attacker, true, ToolsGetScore(attacker, true) + 1);
        ToolsSetScore(client, false, ToolsGetScore(client, false) + 1);
        
        // Gets class exp and money bonuses
        static int iExp[6]; static int iMoney[6];
        ClassGetExp(gClientData[attacker].Class, iExp, sizeof(iExp));
        ClassGetMoney(gClientData[attacker].Class, iMoney, sizeof(iMoney));
        
        // Increment money/exp
        LevelSystemOnSetExp(attacker, gClientData[attacker].Exp + iExp[BonusType_Infect]);
        AccountSetClientCash(attacker, gClientData[attacker].Money + iMoney[BonusType_Infect]);
        
        // If attacker is alive, then give lifesteal 
        if(IsPlayerAlive(attacker)) 
        {
            // Add lifesteal health
            ToolsSetHealth(attacker, ToolsGetHealth(attacker) + ClassGetLifeSteal(gClientData[attacker].Class));
        }
    }
    // If change was done by server
    else if(!attacker)
    {
        // Return money, which was spent before server change
        AccountSetClientCash(client, gClientData[client].Money + gClientData[client].LastPurchase);
        
        // Validate respawn on the change
        if(ModesIsEscape(gServerData.RoundMode))
        {
            // Teleport player back on the spawn point
            AntiStickTeleportToRespawn(client);
        }
    } gClientData[client].LastPurchase = 0; /// Resets purhase amount
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Validate zombie
    if(gClientData[client].Zombie)
    {
        // Forward event to modules
        SoundsOnClientInfected(client, attacker);
        VEffectsOnClientInfected(client, attacker);
    }
    else
    {
        // Forward event to modules
        VEffectsOnClientHumanized(client);
    }
    
    // Forward event to modules
    SoundsOnClientUpdate(client);
    SkillSystemOnClientUpdate(client);
    LevelSystemOnClientUpdate(client);
    VEffectsOnClientUpdate(client);
    VOverlayOnClientUpdate(client, Overlay_Reset);
    if(gClientData[client].Vision) VOverlayOnClientUpdate(client, Overlay_Vision); /// HACK~HACK
    _call.AccountOnClientUpdate(client);
    _call.WeaponsOnClientUpdate(client);
    
    // If mode already started, then change team
    if(!gServerData.RoundNew)
    {
        // Validate zombie
        if(gClientData[client].Zombie)
        {
            // Switch team
            ToolsSetTeam(client, TEAM_ZOMBIE);
        }
        else
        {
            // Switch team
            ToolsSetTeam(client, TEAM_HUMAN);
            
            // Sets glowing for the zombie vision
            ToolsSetDetecting(client, ModesIsXRay(gServerData.RoundMode));
        }
        
        // Terminate the round
        ModesValidateRound();
    }

    // Call forward
    gForwardData._OnClientUpdated(client, attacker);
    return true;
}

/**
 * @brief Sets a client team index. (Alive only)
 *
 * @param client            The client index.
 * @param iTeam             The team index.
 **/
void ApplyOnClientTeam(int client, int iTeam)
{
    // Switch team
    bool bState = ToolsGetDefuser(client);
    ToolsSetTeam(client, iTeam);
    ToolsSetDefuser(client, bState); /// HACK~HACK

    // Sets glowing for the zombie vision
    ToolsSetDetecting(client, ModesIsXRay(gServerData.RoundMode));
}   