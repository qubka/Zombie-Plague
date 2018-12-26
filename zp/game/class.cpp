/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          class.cpp
 *  Type:          Game 
 *  Description:   Provides functions for managing classes.
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
 * Hook class cvar changes.
 **/
void ClassOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_HUMAN_CLASS_MENU]            = FindConVar("zp_human_class_menu");
    gCvarList[CVAR_HUMAN_ARMOR_PROTECT]         = FindConVar("zp_human_armor_protect");
    gCvarList[CVAR_HUMAN_LAST_INFECTION]        = FindConVar("zp_human_last_infection");
    gCvarList[CVAR_HUMAN_INF_AMMUNITION]        = FindConVar("zp_human_inf_ammunition");
    gCvarList[CVAR_HUMAN_PRICE_AMMUNITION]      = FindConVar("zp_human_price_ammunition");
    gCvarList[CVAR_SURVIVOR_SPEED]              = FindConVar("zp_survivor_speed");   
    gCvarList[CVAR_SURVIVOR_GRAVITY]            = FindConVar("zp_survivor_gravity"); 
    gCvarList[CVAR_SURVIVOR_HEALTH]             = FindConVar("zp_survivor_health"); 
    gCvarList[CVAR_SURVIVOR_INF_AMMUNITION]     = FindConVar("zp_survivor_inf_ammunition");
    gCvarList[CVAR_SURVIVOR_PRICE_AMMUNITION]   = FindConVar("zp_survivor_price_ammunition");
    gCvarList[CVAR_SURVIVOR_PLAYER_MODEL]       = FindConVar("zp_survivor_model");            
    gCvarList[CVAR_SURVIVOR_ARM_MODEL]          = FindConVar("zp_survivor_arm");             
    gCvarList[CVAR_ZOMBIE_CLASS_MENU]           = FindConVar("zp_zombie_class_menu");
    gCvarList[CVAR_ZOMBIE_FISRT_HEALTH]         = FindConVar("zp_zombie_additional_health");
    gCvarList[CVAR_ZOMBIE_NIGHT_VISION]         = FindConVar("zp_zombie_nvg_give");
    gCvarList[CVAR_ZOMBIE_XRAY]                 = FindConVar("zp_zombie_xray_give");          
    gCvarList[CVAR_ZOMBIE_CROSSHAIR]            = FindConVar("zp_zombie_crosshair_give");
    gCvarList[CVAR_NEMESIS_SPEED]               = FindConVar("zp_nemesis_speed");             
    gCvarList[CVAR_NEMESIS_GRAVITY]             = FindConVar("zp_nemesis_gravity");           
    gCvarList[CVAR_NEMESIS_HEALTH]              = FindConVar("zp_nemesis_health_ratio");      
    gCvarList[CVAR_NEMESIS_PLAYER_MODEL]        = FindConVar("zp_nemesis_model");             
    gCvarList[CVAR_CT_DEFAULT_GRENADES]         = FindConVar("mp_ct_default_grenades");
    gCvarList[CVAR_CT_DEFAULT_MELEE]            = FindConVar("mp_ct_default_melee");
    gCvarList[CVAR_CT_DEFAULT_SECONDARY]        = FindConVar("mp_ct_default_secondary");
    gCvarList[CVAR_CT_DEFAULT_PRIMARY]          = FindConVar("mp_ct_default_primary");
    gCvarList[CVAR_T_DEFAULT_GRENADES]          = FindConVar("mp_t_default_grenades");
    gCvarList[CVAR_T_DEFAULT_MELEE]             = FindConVar("mp_t_default_melee");
    gCvarList[CVAR_T_DEFAULT_SECONDARY]         = FindConVar("mp_t_default_secondary");
    gCvarList[CVAR_T_DEFAULT_PRIMARY]           = FindConVar("mp_t_default_primary");
    gCvarList[CVAR_H_DEFAULT_EQUIPMENT]         = FindConVar("zp_human_default_equipment");
    gCvarList[CVAR_H_DEFAULT_MELEE]             = FindConVar("zp_human_default_melee");
    gCvarList[CVAR_H_DEFAULT_SECONDARY]         = FindConVar("zp_human_default_secondary");
    gCvarList[CVAR_H_DEFAULT_PRIMARY]           = FindConVar("zp_human_default_primary");
    gCvarList[CVAR_Z_DEFAULT_EQUIPMENT]         = FindConVar("zp_zombie_default_equipment");
    gCvarList[CVAR_Z_DEFAULT_MELEE]             = FindConVar("zp_zombie_default_melee");
    gCvarList[CVAR_Z_DEFAULT_SECONDARY]         = FindConVar("zp_zombie_default_secondary");
    gCvarList[CVAR_Z_DEFAULT_PRIMARY]           = FindConVar("zp_zombie_default_primary");
    gCvarList[CVAR_N_DEFAULT_EQUIPMENT]         = FindConVar("zp_nemesis_default_equipment");
    gCvarList[CVAR_N_DEFAULT_MELEE]             = FindConVar("zp_nemesis_default_melee");
    gCvarList[CVAR_N_DEFAULT_SECONDARY]         = FindConVar("zp_nemesis_default_secondary");
    gCvarList[CVAR_N_DEFAULT_PRIMARY]           = FindConVar("zp_nemesis_default_primary");
    gCvarList[CVAR_S_DEFAULT_EQUIPMENT]         = FindConVar("zp_survivor_default_equipment");
    gCvarList[CVAR_S_DEFAULT_MELEE]             = FindConVar("zp_survivor_default_melee");
    gCvarList[CVAR_S_DEFAULT_SECONDARY]         = FindConVar("zp_survivor_default_secondary");
    gCvarList[CVAR_S_DEFAULT_PRIMARY]           = FindConVar("zp_survivor_default_primary");
    
    // Create server cvars
    gCvarList[CVAR_SERVER_OCCULUSE]             = FindConVar("sv_occlude_players");
    gCvarList[CVAR_SERVER_TRANSMIT_PLAYERS]     = FindConVar("sv_force_transmit_players");
    
    // Sets locked cvars to their locked value
    gCvarList[CVAR_CT_DEFAULT_GRENADES].SetString("");
    gCvarList[CVAR_CT_DEFAULT_MELEE].SetString("");
    gCvarList[CVAR_CT_DEFAULT_SECONDARY].SetString("");
    gCvarList[CVAR_CT_DEFAULT_PRIMARY].SetString("");
    gCvarList[CVAR_T_DEFAULT_GRENADES].SetString("");
    gCvarList[CVAR_T_DEFAULT_MELEE].SetString("");
    gCvarList[CVAR_T_DEFAULT_SECONDARY].SetString("");
    gCvarList[CVAR_T_DEFAULT_PRIMARY].SetString("");
    
    // Hook survivor cvars
    HookConVarChange(gCvarList[CVAR_SURVIVOR_SPEED],              ClassCvarsHookSurvivorSpeed);
    HookConVarChange(gCvarList[CVAR_SURVIVOR_GRAVITY],            ClassCvarsHookSurvivorGravity);
    HookConVarChange(gCvarList[CVAR_SURVIVOR_HEALTH],             ClassCvarsHookSurvivorHealth);
    
    // Hook zombie cvars
    HookConVarChange(gCvarList[CVAR_ZOMBIE_NIGHT_VISION],         ClassCvarsHookZombieNvg);
    HookConVarChange(gCvarList[CVAR_ZOMBIE_XRAY],                 ClassCvarsHookZombieVision);
    HookConVarChange(gCvarList[CVAR_ZOMBIE_CROSSHAIR],            ClassCvarsHookZombieCross);
    
    // Hook nemesis cvars
    HookConVarChange(gCvarList[CVAR_NEMESIS_SPEED],               ClassCvarsHookNemesisSpeed);
    HookConVarChange(gCvarList[CVAR_NEMESIS_GRAVITY],             ClassCvarsHookNemesisGravity);
    HookConVarChange(gCvarList[CVAR_NEMESIS_HEALTH],              ClassCvarsHookNemesisHealthR);
    
    // Hook weapon cvars
    HookConVarChange(gCvarList[CVAR_CT_DEFAULT_GRENADES],         ClassCvarsHookWeapons);
    HookConVarChange(gCvarList[CVAR_CT_DEFAULT_MELEE],            ClassCvarsHookWeapons);
    HookConVarChange(gCvarList[CVAR_CT_DEFAULT_SECONDARY],        ClassCvarsHookWeapons);
    HookConVarChange(gCvarList[CVAR_CT_DEFAULT_PRIMARY],          ClassCvarsHookWeapons);
    HookConVarChange(gCvarList[CVAR_T_DEFAULT_GRENADES],          ClassCvarsHookWeapons);
    HookConVarChange(gCvarList[CVAR_T_DEFAULT_MELEE],             ClassCvarsHookWeapons);
    HookConVarChange(gCvarList[CVAR_T_DEFAULT_SECONDARY],         ClassCvarsHookWeapons);
    HookConVarChange(gCvarList[CVAR_T_DEFAULT_PRIMARY],           ClassCvarsHookWeapons);
    
    // Hook model cvars
    HookConVarChange(gCvarList[CVAR_SURVIVOR_PLAYER_MODEL],       ClassCvarsHookModels);  
    HookConVarChange(gCvarList[CVAR_SURVIVOR_ARM_MODEL],          ClassCvarsHookModels);
    HookConVarChange(gCvarList[CVAR_NEMESIS_PLAYER_MODEL],        ClassCvarsHookModels);
}
 
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
        DeathOnHUD(victimIndex, attackerIndex);
        
        // Increment kills and frags
        ToolsSetClientScore(victimIndex, true, ToolsGetClientScore(victimIndex, true) + 1);
        ToolsSetClientScore(victimIndex, false, ToolsGetClientScore(victimIndex, false) + 1);
        
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
    ToolsSetClientHud(victimIndex, gCvarList[CVAR_ZOMBIE_CROSSHAIR].BoolValue);
    
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
        
        // Remove player weapons
        if(WeaponsRemoveAll(victimIndex, gCvarList[CVAR_N_DEFAULT_MELEE])) //! Give default
        {
            // Give default weapon
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_N_DEFAULT_EQUIPMENT]);
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_N_DEFAULT_SECONDARY]);
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_N_DEFAULT_PRIMARY]);
        }
        
        // Sets health, speed and gravity and armor
        ToolsSetClientHealth(victimIndex, (fnGetAlive() * gCvarList[CVAR_NEMESIS_HEALTH].IntValue), true);
        ToolsSetClientLMV(victimIndex, gCvarList[CVAR_NEMESIS_SPEED].FloatValue); 
        ToolsSetClientGravity(victimIndex, gCvarList[CVAR_NEMESIS_GRAVITY].FloatValue);
        ToolsSetClientArmor(victimIndex, 0);
        
        // Gets nemesis model
        gCvarList[CVAR_NEMESIS_PLAYER_MODEL].GetString(sModel, sizeof(sModel));
    }
    
    // Sets zombie properties
    else
    {
        // Update zombie class
        gClientData[victimIndex][Client_ZombieClass] = gClientData[victimIndex][Client_ZombieClassNext]; ZombieOnValidate(victimIndex);

        // Remove player weapons
        if(WeaponsRemoveAll(victimIndex, gCvarList[CVAR_Z_DEFAULT_MELEE])) //! Give default
        {
            // Give default weapon
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_Z_DEFAULT_EQUIPMENT]);
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_Z_DEFAULT_SECONDARY]);
            WeaponsGiveAll(victimIndex, gCvarList[CVAR_Z_DEFAULT_PRIMARY]);
        }
        
        // Sets health, speed and gravity and armor
        ToolsSetClientHealth(victimIndex, ZombieGetHealth(gClientData[victimIndex][Client_ZombieClass]) + ((fnGetZombies() <= 1) ? (fnGetAlive() * gCvarList[CVAR_ZOMBIE_FISRT_HEALTH].IntValue) : (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? RoundToFloor((gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[victimIndex][Client_Level]))) : 0)), true);
        ToolsSetClientLMV(victimIndex, ZombieGetSpeed(gClientData[victimIndex][Client_ZombieClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[victimIndex][Client_Level])) : 0.0));
        ToolsSetClientGravity(victimIndex, ZombieGetGravity(gClientData[victimIndex][Client_ZombieClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[victimIndex][Client_Level])) : 0.0));
        ToolsSetClientArmor(victimIndex, 0);
        
        // Gets zombie model
        ZombieGetModel(gClientData[victimIndex][Client_ZombieClass], sModel, sizeof(sModel));

        // If help messages enable, then show 
        if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
        {
            // Gets zombie info
            static char sInfo[BIG_LINE_LENGTH];
            ZombieGetInfo(gClientData[victimIndex][Client_ZombieClass], sInfo, sizeof(sInfo));
            
            // Show zombie personal info
            if(hasLength(sInfo)) TranslationPrintHintText(victimIndex, sInfo);
        }
        
        // If instant class menu enable, then show 
        if(gCvarList[CVAR_ZOMBIE_CLASS_MENU].BoolValue)
        {
            // Open the zombie classes menu
            ZombieMenu(victimIndex, true);
        }
    }

    // Apply model
    if(hasLength(sModel)) SetEntityModel(victimIndex, sModel);

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
        
        // Remove player weapons
        if(WeaponsRemoveAll(clientIndex, gCvarList[CVAR_S_DEFAULT_MELEE])) //! Give default
        {
            // Give default weapon
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_S_DEFAULT_EQUIPMENT]);
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_S_DEFAULT_SECONDARY]);
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_S_DEFAULT_PRIMARY]);
        }
        
        // Sets survivor health, speed, gravity and armor
        ToolsSetClientHealth(clientIndex, (fnGetAlive() * gCvarList[CVAR_SURVIVOR_HEALTH].IntValue), true);
        ToolsSetClientLMV(clientIndex, gCvarList[CVAR_SURVIVOR_SPEED].FloatValue); 
        ToolsSetClientGravity(clientIndex, gCvarList[CVAR_SURVIVOR_GRAVITY].FloatValue);
        ToolsSetClientArmor(clientIndex, 0); 
        
        // Gets survivor models
        gCvarList[CVAR_SURVIVOR_ARM_MODEL].GetString(sArm, sizeof(sArm)); gCvarList[CVAR_SURVIVOR_PLAYER_MODEL].GetString(sModel, sizeof(sModel));
    }
    else
    {
        // Update human class
        gClientData[clientIndex][Client_HumanClass] = gClientData[clientIndex][Client_HumanClassNext]; HumanOnValidate(clientIndex);

        // Remove player weapons
        if(WeaponsRemoveAll(clientIndex, gCvarList[CVAR_H_DEFAULT_MELEE])) //! Give default
        {
            // Give default weapon
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_H_DEFAULT_EQUIPMENT]);
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_H_DEFAULT_SECONDARY]);
            WeaponsGiveAll(clientIndex, gCvarList[CVAR_H_DEFAULT_PRIMARY]);
        }
        
        // Sets health, speed, gravity and armor
        ToolsSetClientHealth(clientIndex, HumanGetHealth(gClientData[clientIndex][Client_HumanClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? RoundToFloor((gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level]))) : 0), true);
        ToolsSetClientLMV(clientIndex, HumanGetSpeed(gClientData[clientIndex][Client_HumanClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level])) : 0.0));
        ToolsSetClientGravity(clientIndex, HumanGetGravity(gClientData[clientIndex][Client_HumanClass]) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[clientIndex][Client_Level])) : 0.0));
        ToolsSetClientArmor(clientIndex, (GetClientArmor(clientIndex) < HumanGetArmor(gClientData[clientIndex][Client_HumanClass])) ? HumanGetArmor(gClientData[clientIndex][Client_HumanClass]) : GetClientArmor(clientIndex));
        
        // Gets human models
        HumanGetArmModel(gClientData[clientIndex][Client_HumanClass], sArm, sizeof(sArm)); HumanGetModel(gClientData[clientIndex][Client_HumanClass], sModel, sizeof(sModel));

        // If help messages enable, then show 
        if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
        {
            // Gets human info
            static char sInfo[BIG_LINE_LENGTH];
            HumanGetInfo(gClientData[clientIndex][Client_HumanClass], sInfo, sizeof(sInfo));
            
            // Show human personal info
            if(hasLength(sInfo)) TranslationPrintHintText(clientIndex, sInfo);
        }
        
        // If instant class menu enable, then show 
        if(gCvarList[CVAR_HUMAN_CLASS_MENU].BoolValue)
        {
            // Open the human classes menu
            HumanMenu(clientIndex, true);
        }
    }
    
    // Apply models
    if(hasLength(sModel)) SetEntityModel(clientIndex, sModel);
    if(hasLength(sArm)) SetEntDataString(clientIndex, g_iOffset_PlayerArms, sArm, sizeof(sArm), true);

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

/**
 * Cvar hook callback (zp_survivor_speed)
 * Reload the speed variable on survivors.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookSurvivorSpeed(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate survivor
            if(IsPlayerExist(i) && gClientData[i][Client_Survivor])
            {
                // Update variable
                ToolsSetClientLMV(i, gCvarList[CVAR_SURVIVOR_SPEED].FloatValue);
            }
        }
    }
}

/**
 * Cvar hook callback (zp_survivor_gravity)
 * Reload the gravity variable on survivors.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookSurvivorGravity(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate survivor
            if(IsPlayerExist(i) && gClientData[i][Client_Survivor])
            {
                // Update variable
                ToolsSetClientGravity(i, gCvarList[CVAR_SURVIVOR_GRAVITY].FloatValue);
            }
        }
    }
}

/**
 * Cvar hook callback (zp_survivor_gravity)
 * Reload the health variable on survivors.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookSurvivorHealth(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate survivor
            if(IsPlayerExist(i) && gClientData[i][Client_Survivor])
            {
                // Update variable
                ToolsSetClientHealth(i, gCvarList[CVAR_SURVIVOR_HEALTH].IntValue, true);
            }
        }
    }
}

/**
 * Cvar hook callback (zp_nemesis_speed)
 * Reload the speed variable on nemesis.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookNemesisSpeed(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate nemesis
            if(IsPlayerExist(i) && gClientData[i][Client_Nemesis])
            {
                // Update variable
                ToolsSetClientLMV(i, gCvarList[CVAR_NEMESIS_SPEED].FloatValue);
            }
        }
    }
}

/**
 * Cvar hook callback (zp_nemesis_gravity)
 * Reload the gravity variable on nemesis.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookNemesisGravity(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate nemesis
            if(IsPlayerExist(i) && gClientData[i][Client_Nemesis])
            {
                // Update variable
                ToolsSetClientGravity(i, gCvarList[CVAR_NEMESIS_GRAVITY].FloatValue);
            }
        }
    }
}

/**
 * Cvar hook callback (zp_nemesis_health_ratio)
 * Reload the gravity variable on nemesis.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookNemesisHealthR(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate nemesis
            if(IsPlayerExist(i) && gClientData[i][Client_Nemesis])
            {
                // Update variable
                ToolsSetClientHealth(i, (fnGetAlive() * gCvarList[CVAR_NEMESIS_HEALTH].IntValue), true);
            }
        }
    }
}

/**
 * Cvar hook callback (zp_zombie_crosshair_give)
 * Reload the crosshair variable on zombies.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookZombieCross(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate zombie
            if(IsPlayerExist(i) && gClientData[i][Client_Zombie])
            {
                // Update variable
                ToolsSetClientHud(i, gCvarList[CVAR_ZOMBIE_CROSSHAIR].BoolValue);
            }
        }
    }
}

/**
 * Cvar hook callback (zp_zombie_nvg_give)
 * Reload the nightvision variable on zombies.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookZombieNvg(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate zombie
            if(IsPlayerExist(i) && gClientData[i][Client_Zombie])
            {
                // Update variable
                VOverlayOnClientUpdate(i, gCvarList[CVAR_ZOMBIE_NIGHT_VISION].BoolValue ? Overlay_Vision : Overlay_Reset);
            }
        }
    }
}

/**
 * Cvar hook callback (zp_zombie_xray_give)
 * Enable or disable wall hack feature due to the x-ray vision.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookZombieVision(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // If feature is disabled, then stop
    if(!gCvarList[CVAR_ZOMBIE_XRAY].BoolValue)
    {
        // Validate loaded map
        if(IsMapLoaded())
        {
            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate client
                if(IsPlayerExist(i))
                {
                    // Update variable
                    ToolsSetClientDetecting(i, false);
                }
            }
        }

        // Sets locked cvars to their default value
        gCvarList[CVAR_SERVER_OCCULUSE].IntValue = 1;
        gCvarList[CVAR_SERVER_TRANSMIT_PLAYERS].IntValue = 0;
        
        // Remove hooks
        UnhookConVarChange(gCvarList[CVAR_SERVER_OCCULUSE],             CvarsHookLocked);
        UnhookConVarChange(gCvarList[CVAR_SERVER_TRANSMIT_PLAYERS],     CvarsHookUnlocked);
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate human
            if(IsPlayerExist(i) && !gClientData[i][Client_Zombie] && !gClientData[i][Client_Survivor])
            {
                // Update variable
                ToolsSetClientDetecting(i, true);
            }
        }
    }
    
    // Sets locked cvars to their locked value
    gCvarList[CVAR_SERVER_OCCULUSE].IntValue = 0;
    gCvarList[CVAR_SERVER_TRANSMIT_PLAYERS].IntValue = 1;
    
    // Hook locked cvars to prevent it from changing
    HookConVarChange(gCvarList[CVAR_SERVER_OCCULUSE],             CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_TRANSMIT_PLAYERS],     CvarsHookUnlocked);
}

/**
 * Cvar hook callback. (mp_ct_default_*, mp_t_default_*)
 * Prevents changes of default cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookWeapons(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to locked value
    hConVar.SetString("");
}

/**
 * Cvar hook callback (zp_survivor_model, zp_survivor_arm, zp_nemesis_model)
 * Precache player models.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ClassCvarsHookModels(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // Validate player model
        static char sPath[PLATFORM_MAX_PATH];
        hConVar.GetString(sPath, sizeof(sPath));
        if(!ModelsPrecacheStatic(sPath))
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid model path. File not found: \"%s\"", sPath);
        }
    }
}