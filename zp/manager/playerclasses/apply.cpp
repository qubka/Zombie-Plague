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
 * @section Number of valid bonuses.
 **/
enum /*BonusType*/
{ 
    BonusType_Invalid = -1,     /** Used as return value when a bonus doens't exist. */
    
    BonusType_Kill,             /** Kill bonus */
    BonusType_Damage,           /** Damage bonus */
    BonusType_Infect            /** Infect or humanize bonus */  
};
/**
 * @endsection
 **/
 
/**
 * Infects/humanize a client.
 *
 * @param clientIndex       The victim index.
 * @param attackerIndex     (Optional) The attacker index.
 * @param sName             (Optional) The class name.
 * @param respawnMode       (Optional) Indicates that infection was on spawn.
 * @return                  True or false.
 **/
stock bool ApplyClassUpdate(const int clientIndex, const int attackerIndex = 0, const char[] sName = "")
{
    // Validate client 
    if(!IsPlayerExist(clientIndex))
    {
        return false;
    }

    //*********************************************************************
    //*                  UPDATE VARIABLES OF THE PLAYER                   *
    //*********************************************************************

    // Validate human
    if(!strcmp(sName, "human", false))
    {
        // Update class class
        gClientData[clientIndex][Client_Class] = gClientData[clientIndex][Client_HumanClassNext]; HumanOnValidate(clientIndex);
        gClientData[clientIndex][Client_Zombie] = false;
    }
    // Validate zombie
    else if(!strcmp(sName, "zombie", false))
    {
        // Update class class
        gClientData[clientIndex][Client_Class] = gClientData[clientIndex][Client_ZombieClassNext]; ZombieOnValidate(clientIndex);
        gClientData[clientIndex][Client_Zombie] = true;
    }
    // Validate custom
    else
    {
        // Validate class index
        int iD = ClassNameToIndex(sName);
        if(iD == -1)
        {
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class name: \"%s\"", sName);
            return false;
        }

        // Update class class
        gClientData[clientIndex][Client_Class] = iD;
        gClientData[clientIndex][Client_Zombie] = ClassIsZombie(gClientData[clientIndex][Client_Class]);
    }
    
    // Resets some tools
    ToolsResetTimers(clientIndex);
    ToolsSetClientFlashLight(clientIndex, false);
    
    // Resets some variables
    gClientData[clientIndex][Client_Skill] = false;
    gClientData[clientIndex][Client_SkillCountDown] = 0.0;
    
    // Remove player weapons
    if(WeaponsRemoveAll(clientIndex)) //! Give default
    {
        // Gets class weapons
        static int iWeapon[CLASSES_WEAPON_MAX];
        ClassGetWeapon(gClientData[clientIndex][Client_Class], iWeapon, sizeof(iWeapon));
        
        // i = weapon id
        for(int i = 0; i < sizeof(iWeapon); i++)
        {
            // Give  weapons
            WeaponsGive(clientIndex, i);
        }
    }
    
    // Sets health, speed and gravity and armor
    ToolsSetClientHealth(clientIndex, ClassGetHealth(gClientData[clientIndex][Client_Class]) + ((fnGetZombies() <= 1) ? (fnGetAlive() * gCvarList[CVAR_ZOMBIE_FISRT_HEALTH].IntValue) : (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? RoundToFloor((gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level]))) : 0)), true);
    ToolsSetClientLMV(clientIndex, ClassGetSpeed(gClientData[clientIndex][Client_Class]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level])) : 0.0));
    ToolsSetClientGravity(clientIndex, ClassGetGravity(gClientData[clientIndex][Client_Class]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level])) : 0.0));
    ToolsSetClientArmor(clientIndex, (GetClientArmor(clientIndex) < HumanGetArmor(gClientData[clientIndex][Client_Class])) ? HumanGetArmor(gClientData[clientIndex][Client_Class]) : GetClientArmor(clientIndex));
    ToolsSetClientHud(clientIndex, ClassIsCross(gClientData[clientIndex][Client_Class]));
    ToolsSetClientFov(clientIndex, ClassGetFov(gClientData[clientIndex][Client_Class]));

    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];
    
    // Gets class player models
    ClassGetModel(gClientData[clientIndex][Client_Class], sModel, sizeof(sModel));
    if(hasLength(sModel)) SetEntityModel(clientIndex, sModel);
    
    // Gets class arm models
    ClassGetArmModel(gClientData[clientIndex][Client_Class], sModel, sizeof(sModel)); 
    if(hasLength(sModel)) SetEntDataString(clientIndex, g_iOffset_PlayerArms, sModel, sizeof(sModel), true);
    
    // If help messages enable, then show 
    if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
    {
        // Gets class info
        ClassGetInfo(gClientData[clientIndex][Client_Class], sModel, sizeof(sModel));
        
        // Show personal info
        if(hasLength(sModel)) TranslationPrintHintText(clientIndex, sModel);
    }

    //*********************************************************************
    //*           REWARDS AND BONUSES FOR INFECTOR OF THE HUMAN           *
    //*********************************************************************
    
    // Validate attacker
    if(IsPlayerExist(attackerIndex)) 
    {
        // Create a fake event
        DeathOnHUD(clientIndex, attackerIndex);
        
        // Increment kills and frags
        ToolsSetClientScore(clientIndex, true, ToolsGetClientScore(clientIndex, true) + 1);
        ToolsSetClientScore(clientIndex, false, ToolsGetClientScore(clientIndex, false) + 1);
        
        // Gets class exp and money
        static int iExp[3]; static int iMoney[3];
        ClassGetExp(gClientData[clientIndex][Client_Class], iExp, sizeof(iExp));
        ClassGetMoney(gClientData[clientIndex][Client_Class], iMoney, sizeof(iMoney));
        
        // Increment exp and bonuses
        LevelSystemOnSetExp(attackerIndex, gClientData[attackerIndex][Client_Exp] + iExp[BonusType_Infect]);
        AccountSetClientCash(attackerIndex, gClientData[attackerIndex][Client_Money] + iMoney[BonusType_Infect]);
        ToolsSetClientHealth(attackerIndex, GetClientHealth(attackerIndex) + ClassGetLifeSteal(gClientData[clientIndex][Client_Class]));
    }
    // If infection was done by server
    else if(!attackerIndex)
    {
        // Return money, which was spent before server infection
        AccountSetClientCash(clientIndex, gClientData[clientIndex][Client_Money] + gClientData[clientIndex][Client_LastBoughtAmount]);
        gClientData[clientIndex][Client_LastBoughtAmount] = 0;
        
        // Validate respawn on the infection
        if(ModesIsEscape(gServerData[Server_RoundMode]))
        {
            // Teleport to the spawn
            TeleportEntity(clientIndex, gClientData[clientIndex][Client_Spawn], NULL_VECTOR, NULL_VECTOR);
        }
    }
    
    // Validate zombie
    if(gClientData[clientIndex][Client_Zombie])
    {
        // Forward event to modules
        SkillsOnClientInfected(clientIndex);
        SoundsOnClientInfected(clientIndex, attackerIndex);
        VEffectsOnClientInfected(clientIndex);
        
        // If instant zombie class menu enable, then open 
        if(gCvarList[CVAR_GAME_CUSTOM_ZOMBIE_MENU].BoolValue)
        {
            // Open the zombie classes menu
            ZombieMenu(clientIndex, true);
        }
    }
    else
    {
        // Forward event to modules
        SoundsOnClientHumanized(clientIndex);
        VEffectsOnClientHumanized(clientIndex);
        
        // If instant human class menu enable, then open 
        if(gCvarList[CVAR_GAME_CUSTOM_HUMAN_MENU].BoolValue)
        {
            // Open the zombie classes menu
            HumanMenu(clientIndex, true);
        }
    }
    
    // // Forward event to modules
    LevelSystemOnClientUpdate(clientIndex);
    VOverlayOnClientUpdate(clientIndex, Overlay_Vision);
    RequestFrame(view_as<RequestFrameCallback>(AccountOnClientUpdate), GetClientUserId(clientIndex));
    RequestFrame(view_as<RequestFrameCallback>(WeaponsOnClientUpdate), GetClientUserId(clientIndex));
    
    // Validate respawn
    if(respawnMode) 
    {
        // Resets some variables
        gClientData[clientIndex][Client_LastBoughtAmount] = 0;
        gClientData[clientIndex][Client_RespawnTimes] = 0;
        
        // Resets limit of extraitems
        ItemsRemoveLimits(clientIndex);
    }
    else
    {
        // Switch team
        ToolsSetClientTeam(clientIndex,  gClientData[clientIndex][Client_Zombie] ? TEAM_ZOMBIE : TEAM_HUMAN);

        // Sets glowing for the zombie vision
        ToolsSetClientDetecting(clientIndex, ModesIsXRay(gServerData[Server_RoundMode]));
        
        // Terminate the round
        RoundEndOnValidate();
    }

    // Call forward
    API_OnClientUpdated(clientIndex, attackerIndex);
    return true;
}