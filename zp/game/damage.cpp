/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          damage.cpp
 *  Type:          Game 
 *  Description:   Modify damage values here.
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
 * Client is joining the server.
 * 
 * @param clientIndex       The client index.  
 **/
void DamageClientInit(int clientIndex)
{
    // Hook damage callbacks
    SDKHook(clientIndex, SDKHook_TraceAttack,  DamageOnTraceAttack);
    SDKHook(clientIndex, SDKHook_OnTakeDamage, DamageOnTakeDamage);
}
 
/**
 * Hook: OnTraceAttack
 * Called right before the bullet enters a client.
 * 
 * @param victimIndex       The victim index.
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflictor index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 * @param ammoType          The ammo type of the attacker's weapon.
 * @param hitroupBox        The hitbox index.  
 * @param hitgroupIndex     The hitgroup index.  
 **/
public Action DamageOnTraceAttack(int victimIndex, int &attackerIndex, int &inflicterIndex, float &damageAmount, int &damageBits, int &ammoType, int hitroupBox, int hitgroupIndex)
{
    // If gamemodes enable, then validate state
    if(gCvarList[CVAR_GAME_CUSTOM_START].IntValue)
    {
        // If mode doesn't started yet, then stop trace
        if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
        {
            // Stop trace
            return Plugin_Handled;
        }
    }

    // Verify that the clients are exists
    if(!IsPlayerExist(victimIndex) || !IsPlayerExist(attackerIndex))
    {
        // Stop trace
        return Plugin_Handled;
    }

    // If clients have same class, then stop trace
    if(GetClientTeam(victimIndex) == GetClientTeam(attackerIndex))
    {
        // Stop trace
        return Plugin_Handled;
    }

    // If damage hitgroups cvar is disabled, then allow damage
    if(!gCvarList[CVAR_GAME_CUSTOM_HITGROUPS].BoolValue)
    {
        // Allow trace
        return Plugin_Continue;
    }

    // Get hitgroup index
    int iIndex = HitgroupToIndex(hitroupBox);

    // If index can't be found, then allow damage
    if(iIndex == -1)
    {
        // Allow trace
        return Plugin_Continue;
    }

    // If damage is disabled for this hitgroup, then stop
    if(!HitgroupsCanDamage(iIndex))
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
 * @param inflicterIndex    The inflicter index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action DamageOnTakeDamage(int victimIndex, int &attackerIndex, int &inflicterIndex, float &damageAmount, int &damageBits)
{
    //*********************************************************************
    //*                   VALIDATION OF THE INFLICTOR                     *
    //*********************************************************************
    
    // If inflicter isn't valid, then skip
    if(IsValidEdict(inflicterIndex))
    {
        // Gets classname of the inflictor
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(inflicterIndex, sClassname, sizeof(sClassname));

        // If entity is a trigger, then allow damage (Map is damaging client)
        if(StrContains(sClassname, "trigger") > -1)
        {
            // Allow damage
            return Plugin_Continue;
        }
    }
    
    //*********************************************************************
    //*                     VALIDATION OF THE PLAYER                           *
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

    // Verify that the victim is exist
    if(!IsPlayerExist(victimIndex))
    {
        // Block damage
        return Plugin_Handled;
    }

    //*********************************************************************
    //*                    APPLY DAMAGE TO THE PLAYER                     *
    //*********************************************************************

    // Client was damaged by 'bullet'
    if(damageBits & DMG_NEVERGIB)
    {
        // Verify that the attacker is exist
        if(!IsPlayerExist(attackerIndex))
        {
            // Block damage
            return Plugin_Handled;
        }

        // Initialize additional knockback multiplier for zombie
        float knockbackAmount = ZombieGetKnockBack(gClientData[victimIndex][Client_ZombieClass]);

        // Apply hitgrops damage multiplier
        if(gCvarList[CVAR_GAME_CUSTOM_HITGROUPS].BoolValue)
        {
            int iHitIndex = HitgroupToIndex(GetEntData(victimIndex, g_iOffset_PlayerHitGroup));
            if(iHitIndex != -1)
            {
                knockbackAmount *= HitgroupsGetKnockback(iHitIndex);
            }
        }
        
        // Gets the active weapon index from the client
        int weaponIndex = GetEntDataEnt2(attackerIndex, g_iOffset_PlayerActiveWeapon);
        
        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            int iIndex = gWeaponData[weaponIndex];
            if(iIndex != -1)
            {
                damageAmount *= WeaponsGetDamage(iIndex);
                knockbackAmount *= WeaponsGetKnockBack(iIndex);
            }
        }
        
        // Apply level damage multiplier
        if(gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
        {
            damageAmount *= float(gClientData[attackerIndex][Client_Level]) * gCvarList[CVAR_LEVEL_DAMAGE_RATIO].FloatValue + 1.0;
        }

        // Verify that the attacker is zombie 
        if(gClientData[attackerIndex][Client_Zombie])
        {
            // If victim is zombies, then stop
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
        
        // Give rewards for applied damage
        DamageOnClientAmmo(attackerIndex, damageAmount);
        DamageOnClientExp(attackerIndex, damageAmount);
        
        // If help messages enabled, show info
        if(gCvarList[CVAR_MESSAGES_HELP].BoolValue) TranslationPrintHintText(attackerIndex, "Damage info", GetClientHealth(victimIndex));
    }
    
    // Call forward
    API_OnClientDamaged(victimIndex, attackerIndex, damageAmount, damageBits);

    // Apply fake damage
    return DamageOnClientFakeDamage(victimIndex, damageAmount, damageBits);
}

/*
 * Other main functions
 */

/**
 * Damage without pain shock.
 *
 * @param clientIndex       The client index.
 * @param damageAmount      The amount of damage inflicted. 
 * @param damageBits        The type of damage inflicted.
 **/
stock Action DamageOnClientFakeDamage(int clientIndex, float damageAmount, int damageBits)
{
    // Verify that the damage is positive
    if(!damageAmount)
    {
        // Block damage
        return Plugin_Handled;
    }
    
    // Forward event to modules
    SoundsOnClientHurt(clientIndex, damageBits);
    
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
stock Action DamageOnClientInfect(int victimIndex, int attackerIndex, float damageAmount)
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
stock void DamageOnClientKnockBack(int victimIndex, int attackerIndex, float knockbackAmount)
{
    // If nemesis knockback disabled, then stop
    if(!gCvarList[CVAR_NEMESIS_KNOCKBACK].BoolValue && gClientData[victimIndex][Client_Nemesis])
    {
        return;
    }

    // Initialize vectors
    static float vClientLoc[3]; static float vEyeAngle[3]; static float vAttackerLoc[3]; static float vVelocity[3];

    // Gets victim's and attacker's position
    GetClientAbsOrigin(victimIndex, vClientLoc);
    GetClientEyeAngles(attackerIndex, vEyeAngle);
    GetClientEyePosition(attackerIndex, vAttackerLoc);

    // Calculate knockback end-vector
    TR_TraceRayFilter(vAttackerLoc, vEyeAngle, MASK_ALL, RayType_Infinite, FilterNoPlayers);
    TR_GetEndPosition(vClientLoc);

    // Gets vector from the given starting and ending points
    MakeVectorFromPoints(vAttackerLoc, vClientLoc, vVelocity);

    // Normalize the vector (equal magnitude at varying distances)
    NormalizeVector(vVelocity, vVelocity);

    // Apply the magnitude by scaling the vector
    ScaleVector(vVelocity, knockbackAmount);

    // ADD the given vector to the client's current velocity
    ToolsClientVelocity(victimIndex, vVelocity);
}

/**
 * Reward ammopacks for applied damage.
 *
 * @param clientIndex       The client index.
 * @param damageAmount      The amount of damage inflicted. 
 **/
stock void DamageOnClientAmmo(int clientIndex, float damageAmount)
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
    ToolsSetClientCash(clientIndex, gClientData[clientIndex][Client_AmmoPacks] + nMultipler);
    
    // Resets damage filter
    nAppliedDamage[clientIndex] -= nMultipler * nBonus;
}

/**
 * Reward experience for applied damage.
 *
 * @param clientIndex       The client index.
 * @param damageAmount      The amount of damage inflicted. 
 **/
stock void DamageOnClientExp(int clientIndex, float damageAmount)
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
 *
 * @return                  True or false.
 **/
public bool FilterNoPlayers(int entityIndex, int contentsMask)
{
    // If entity is a player, continue tracing
    return !(1 <= entityIndex <= MaxClients);
}
