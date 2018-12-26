/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          damage.cpp
 *  Type:          Game 
 *  Description:   Modify damage values here.
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
 * Client is joining the server.
 * 
 * @param clientIndex       The client index.  
 **/
void DamageClientInit(const int clientIndex)
{
    // Hook damage callbacks
    SDKHook(clientIndex, SDKHook_TraceAttack,  DamageOnTraceAttack);
    SDKHook(clientIndex, SDKHook_OnTakeDamage, DamageOnTakeDamage);
}

/**
 * Hook damage cvar changes.
 **/
void DamageOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_JUMPBOOST_KNOCKBACK]         = FindConVar("zp_jumpboost_knockback");
    gCvarList[CVAR_NEMESIS_KNOCKBACK]           = FindConVar("zp_nemesis_knockback");
    
    // Create server cvars
    gCvarList[CVAR_SERVER_FRIENDLY_FIRE]        = FindConVar("mp_friendlyfire");
    gCvarList[CVAR_SERVER_FRIENDLY_GRENADE]     = FindConVar("ff_damage_reduction_grenade");
    gCvarList[CVAR_SERVER_FRIENDLY_BULLETS]     = FindConVar("ff_damage_reduction_bullets");
    gCvarList[CVAR_SERVER_FRIENDLY_OTHER]       = FindConVar("ff_damage_reduction_other");
    gCvarList[CVAR_SERVER_FRIENDLY_SELF]        = FindConVar("ff_damage_reduction_grenade_self");
    
    // Sets locked cvars to their locked value
    gCvarList[CVAR_SERVER_FRIENDLY_FIRE].IntValue = 0;
    CvarsOnCheatSet(gCvarList[CVAR_SERVER_FRIENDLY_GRENADE], 0);
    CvarsOnCheatSet(gCvarList[CVAR_SERVER_FRIENDLY_BULLETS], 0);
    CvarsOnCheatSet(gCvarList[CVAR_SERVER_FRIENDLY_OTHER],   0);
    CvarsOnCheatSet(gCvarList[CVAR_SERVER_FRIENDLY_SELF],    0);
    
    // Hook locked cvars to prevent it from changing
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_FIRE],        CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_GRENADE],     CvarsHookLocked2);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_BULLETS],     CvarsHookLocked2);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_OTHER],       CvarsHookLocked2);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_SELF],        CvarsHookLocked2);
}
 
/**
 * Hook: OnTraceAttack
 * Called right before the bullet enters a client.
 * 
 * @param victimIndex       The victim index.
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflictor index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageType        The type of damage inflicted.
 * @param ammoType          The ammo type of the attacker weapon.
 * @param hitgroupBox       The hitbox index.  
 * @param hitgroupIndex     The hitgroup index.  
 **/
public Action DamageOnTraceAttack(const int victimIndex, int &attackerIndex, int &inflicterIndex, float &damageAmount, int &damageType, int &ammoType, int hitgroupBox, int hitgroupIndex)
{
    // If gamemodes enable, then check round
    if(gCvarList[CVAR_GAME_CUSTOM_START].IntValue)
    {
        // If mode doesn't started yet, then stop trace
        if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
        {
            // Stop trace
            return Plugin_Handled;
        }
    }
    
    // Validate victim
    if(IsPlayerExist(victimIndex))
    {
        // Validate attacker
        if(IsPlayerExist(attackerIndex))
        {
            // Validate team
            if(GetClientTeam(victimIndex) == GetClientTeam(attackerIndex))
            {
                // Stop trace
                return Plugin_Handled;
            }
        }
    }

    // If damage hitgroups disabled, then allow damage
    if(!gCvarList[CVAR_GAME_CUSTOM_HITGROUPS].BoolValue)
    {
        // Allow trace
        return Plugin_Continue;
    }

    // Gets hitgroup index
    int iIndex = HitGroupToIndex(hitgroupIndex);

    // If index can't be found, then allow damage
    if(iIndex == -1)
    {
        // Allow trace
        return Plugin_Continue;
    }

    // If damage is disabled for this hitgroup, then stop
    if(!HitGroupsCanDamage(iIndex))
    {
        // Stop trace
        return Plugin_Handled;
    }

    // Allow trace
    return Plugin_Continue;
}

/**
 * Hook: OnTakeDamage
 * Called right before damage is done.
 * 
 * @param victimIndex       The victim index.
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageType        The type of damage inflicted.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 * @param damageForce       The velocity of damage force.
 * @param damagePosition    The origin of damage.
 **/
public Action DamageOnTakeDamage(const int victimIndex, int &attackerIndex, int &inflictorIndex, float &damageAmount, int &damageType, int &weaponIndex, const float damageForce[3], const float damagePosition[3]/*, int damagecustom*/)
{
    //*********************************************************************
    //*                   VALIDATION OF THE INFLICTOR                     *
    //*********************************************************************
    
    // Validate inflictor
    if(IsValidEdict(inflictorIndex))
    {
        // Gets classname of the inflictor
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(inflictorIndex, sClassname, sizeof(sClassname));

        // If entity is a trigger, then allow damage (Map is damaging client)
        if(StrContains(sClassname, "trigger") > -1)
        {
            // Allow damage
            return Plugin_Continue;
        }
    }

    //*********************************************************************
    //*                     VALIDATION OF THE PLAYER                      *
    //*********************************************************************
    
    // If gamemodes disabled, then skip
    if(!gCvarList[CVAR_GAME_CUSTOM_START].IntValue)
    {
        // Allow damage
        return Plugin_Continue;
    }
    
    // If mode doesn't started yet, then stop
    if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
    {
        // Block damage
        return Plugin_Handled;
    }

    // Validate victim
    if(!IsPlayerExist(victimIndex))
    {
        // Block damage
        return Plugin_Handled;
    }

    //*********************************************************************
    //*                    APPLY DAMAGE TO THE PLAYER                     *
    //*********************************************************************

    // Call forward
    API_OnClientDamaged(victimIndex, attackerIndex, inflictorIndex, damageAmount, damageType, weaponIndex);
    
    // Validate attacker
    if(IsPlayerExist(attackerIndex))
    {
        // Validate team
        if(GetClientTeam(victimIndex) == GetClientTeam(attackerIndex))
        {
            // Stop trace
            return Plugin_Handled;
        }
            
        // Initialize additional knockback multiplier for zombie
        float knockbackAmount = gClientData[victimIndex][Client_Nemesis] ? gCvarList[CVAR_NEMESIS_KNOCKBACK].FloatValue : ZombieGetKnockBack(gClientData[victimIndex][Client_ZombieClass]);

        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // Validate custom index
            int iD = WeaponsGetCustomID(weaponIndex);
            if(iD != INVALID_ENT_REFERENCE)
            {
                damageAmount *= WeaponsGetDamage(iD);
                knockbackAmount *= WeaponsGetKnockBack(iD);
            }
        }
        
        // If level system enabled, then apply multiplier
        if(gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
        {
            damageAmount *= float(gClientData[attackerIndex][Client_Level]) * gCvarList[CVAR_LEVEL_DAMAGE_RATIO].FloatValue + 1.0;
        }

        // Client was damaged by 'bullet'
        if(damageType & DMG_NEVERGIB)
        {
            // If damage hitgroups enabled, then apply multiplier
            if(gCvarList[CVAR_GAME_CUSTOM_HITGROUPS].BoolValue)
            {
                // Validate hitgroup index
                int iHitIndex = HitGroupToIndex(GetEntData(victimIndex, g_iOffset_PlayerHitGroup));
                if(iHitIndex != -1)
                {
                    knockbackAmount *= HitGroupsGetKnockback(iHitIndex);
                }
            }
    
            // Validate zombie
            if(gClientData[attackerIndex][Client_Zombie])
            {
                // If victim is zombie, then stop
                if(gClientData[victimIndex][Client_Zombie])
                {
                    // Block damage
                    return Plugin_Handled;
                }

                // If the gamemode allow infection, then apply it
                if(ModesIsInfection(gServerData[Server_RoundMode]))
                {
                    // Infect victim
                    return DamageOnClientInfect(victimIndex, attackerIndex, damageAmount);
                }
            }
            // Verify that the attacker is human 
            else
            {
                // Apply knockback
                DamageOnClientKnockBack(victimIndex, attackerIndex, damageAmount * knockbackAmount);
            }
        }
        
        // Give rewards for applied damage
        DamageOnClientAmmo(attackerIndex, damageAmount);
        DamageOnClientExp(attackerIndex, damageAmount);
        
        // If help messages enabled, show info
        if(gCvarList[CVAR_MESSAGES_HELP].BoolValue) TranslationPrintHintText(attackerIndex, "damage info", GetClientHealth(victimIndex));
    }
    
    // Apply fake damage
    return DamageOnClientFakeDamage(victimIndex, damageAmount, damageType);
}

/*
 * Damage natives API.
 */
 
/**
 * Applies fake damage to a player.
 *
 * native void ZP_TakeDamage(clientIndex, attackerIndex, damageAmount, damageType, weaponIndex);
 **/
public int API_TakeDamage(Handle hPlugin, const int iNumParams)
{
    // Gets data from native cells
    int clientIndex = GetNativeCell(1);
    int attackerIndex = GetNativeCell(2);
    float damageAmount = GetNativeCell(3);
    int damageType = GetNativeCell(4);
    int weaponIndex = GetNativeCell(5);

    // Call fake hook
    Action resultHandle = DamageOnTakeDamage(clientIndex, attackerIndex, attackerIndex, damageAmount, damageType, weaponIndex, NULL_VECTOR, NULL_VECTOR);
    
    // Validate damage 
    if(resultHandle == Plugin_Changed)
    {
        // If attacker doens't exist, then make a self damage
        if(!IsPlayerExist(attackerIndex, false)) attackerIndex = clientIndex;

        // Create the damage to kill
        SDKHooks_TakeDamage(clientIndex, attackerIndex, attackerIndex, damageAmount);
    }
}

/*
 * Other main functions
 */

/**
 * Damage without pain shock.
 *
 * @param clientIndex       The client index.
 * @param damageAmount      The amount of damage inflicted. 
 * @param damageType        The type of damage inflicted.
 **/
stock Action DamageOnClientFakeDamage(const int clientIndex, const float damageAmount, const int damageType)
{
    // Validate amount
    if(!damageAmount)
    {
        // Block damage
        return Plugin_Handled;
    }
    
    // Forward event to modules
    SoundsOnClientHurt(clientIndex, damageType);
    
    // Gets health
    int healthAmount = GetClientHealth(clientIndex);
    
    // Validate health
    if(healthAmount)
    {
        // Count the damage
        healthAmount -= RoundFloat(damageAmount);
        
        // If amount of damage to high, then stop
        if(healthAmount <= 0)
        {
            // Allow damage
            return Plugin_Changed;
        }
        else
        {
            // Sets applied damage
            ToolsSetClientHealth(clientIndex, healthAmount);
            
            // Block damage
            return Plugin_Handled;
        }
    }
    else
    {
        // Allow damage
        return Plugin_Changed;
    }
}

/**
 * Reducing armor and infect the victim.
 *
 * @param victimIndex       The victim index.
 * @param attackerIndex     The attacker index.
 * @param damageAmount      The amount of damage inflicted. 
 **/
stock Action DamageOnClientInfect(const int victimIndex, const int attackerIndex, const float damageAmount)
{
    // Last human need to be killed ?
    if(!gCvarList[CVAR_HUMAN_LAST_INFECTION].BoolValue && fnGetHumans() <= 1)
    {
        // Allow damage
        return Plugin_Changed;
    }
    
    // Human armor need to be reduced before infecting ?
    if(gCvarList[CVAR_HUMAN_ARMOR_PROTECT].BoolValue)
    {
        // Gets armor
        int armorAmount = GetClientArmor(victimIndex);

        // Verify that the victim has an armor
        if(armorAmount)
        {
            // Count the damage
            armorAmount -= RoundFloat(damageAmount);

            // Sets a new armor amount
            ToolsSetClientArmor(victimIndex, armorAmount < 0 ? 0 : armorAmount);
            
            // Block infection
            return Plugin_Handled;
        }
    }

    // Make a zombie
    ClassMakeZombie(victimIndex, attackerIndex);

    // Block damage
    return Plugin_Handled;
}

/** 
 * Set velocity knockback for applied damage.
 *
 * @param victimIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param knockbackAmount   The knockback multiplier.
 **/
stock void DamageOnClientKnockBack(const int victimIndex, const int attackerIndex, float knockbackAmount)
{
    // If victim is not on the ground, then apply it
    if(!(GetEntityFlags(victimIndex) & FL_ONGROUND))
    {
        // Apply knockback jumpboost multiplier
        knockbackAmount *= gCvarList[CVAR_JUMPBOOST_KNOCKBACK].FloatValue;
    }
    
    // Validate amount
    if(!knockbackAmount)
    {
        // Block knock
        return;
    }

    // Initialize vectors
    static float vEntAngle[3]; static float vEntPosition[3]; static float vBulletPosition[3]; static float vVelocity[3]; 

    // Gets the attacker position
    GetClientEyeAngles(attackerIndex, vEntAngle);
    GetClientEyePosition(attackerIndex, vEntPosition);

    // Create the infinite trace
    Handle hTrace = TR_TraceRayFilterEx(vEntPosition, vEntAngle, MASK_SHOT, RayType_Infinite, TraceFilter, attackerIndex);

    // Validate trace
    if(TR_GetEntityIndex(hTrace) == victimIndex)
    {
        // Gets the hit point
        TR_GetEndPosition(vBulletPosition, hTrace);

        // Gets vector from the given starting and ending points
        MakeVectorFromPoints(vEntPosition, vBulletPosition, vVelocity);

        // Normalize the vector (equal magnitude at varying distances)
        NormalizeVector(vVelocity, vVelocity);

        // Apply the magnitude by scaling the vector
        ScaleVector(vVelocity, knockbackAmount);

        // Adds the given vector to the client current velocity
        ToolsClientVelocity(victimIndex, vVelocity);
    }
    
    // Close the trace
    delete hTrace;
}

/**
 * Reward ammopacks for applied damage.
 *
 * @param clientIndex       The client index.
 * @param damageAmount      The amount of damage inflicted. 
 **/
stock void DamageOnClientAmmo(const int clientIndex, const float damageAmount)
{
    // Initialize client applied damage
    static int nAppliedDamage[MAXPLAYERS+1];
    
    // Increment total damage
    nAppliedDamage[clientIndex] += RoundFloat(damageAmount);
    
    // Counting bonuses
    int nBonus = gClientData[clientIndex][Client_Zombie] ? gCvarList[CVAR_BONUS_DAMAGE_ZOMBIE].IntValue : gClientData[clientIndex][Client_Survivor] ? gCvarList[CVAR_BONUS_DAMAGE_SURVIVOR].IntValue : gCvarList[CVAR_BONUS_DAMAGE_HUMAN].IntValue;

    // Validate bonus
    if(!nBonus)
    {
        return;
    }
    
    // Computing multiplier
    int nMultipler = nAppliedDamage[clientIndex] / nBonus;
    
    // Validate multiplier
    if(!nMultipler) 
    {
        return;
    }
    
    // Give ammopacks for the attacker
    AccountSetClientCash(clientIndex, gClientData[clientIndex][Client_AmmoPacks] + nMultipler);
    
    // Resets damage filter
    nAppliedDamage[clientIndex] -= nMultipler * nBonus;
}

/**
 * Reward experience for applied damage.
 *
 * @param clientIndex       The client index.
 * @param damageAmount      The amount of damage inflicted. 
 **/
stock void DamageOnClientExp(const int clientIndex, const float damageAmount)
{
    // If level system disabled, then stop
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }
    
    // Initialize client applied damage
    static int nAppliedDamage[MAXPLAYERS+1];
    
    // Increment total damage
    nAppliedDamage[clientIndex] += RoundFloat(damageAmount);
    
    // Counting bonuses
    int nBonus = gClientData[clientIndex][Client_Zombie] ? gCvarList[CVAR_LEVEL_DAMAGE_ZOMBIE].IntValue : gClientData[clientIndex][Client_Survivor] ? gCvarList[CVAR_LEVEL_DAMAGE_SURVIVOR].IntValue : gCvarList[CVAR_LEVEL_DAMAGE_HUMAN].IntValue;

    // Validate bonus
    if(!nBonus)
    {
        return;
    }
    
    // Computing multiplier
    int nMultipler = nAppliedDamage[clientIndex] / nBonus;
    
    // Validate multiplier
    if(!nMultipler) 
    {
        return;
    }
    
    // Give experience for the attacker
    LevelSystemOnSetExp(clientIndex, gClientData[clientIndex][Client_Exp] + nMultipler);
    
    // Resets damage filter
    nAppliedDamage[clientIndex] -= nMultipler * nBonus;
}

/*
 * Trace filtering functions
 */
 
/**
 * Trace filter.
 *  
 * @param entityIndex       The entity index.
 * @param contentsMask      The contents mask.
 * @param clientIndex       The client index.
 *
 * @return                  True or false.
 **/
public bool TraceFilter(const int entityIndex, const int contentsMask, const int clientIndex)
{
    return (1 <= entityIndex <= MaxClients && entityIndex != clientIndex);
}