/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          playereffects.cpp
 *  Type:          Module 
 *  Description:   Player visual effects.
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
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param nemesisMode       (Optional) Indicates that client will be a nemesis.
 * @param respawnMode       (Optional) Indicates that infection was on spawn.
 **/
void PlayerVEffectsOnClientInfected(int clientIndex, bool nemesisMode = false, bool respawnMode = false)
{
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];

    // Initialize duration variable
    static float flDuration;

    // Validate respawn
    if(respawnMode)
    {
        // If respawn effect disabled, then stop
        if(!gCvarList[CVAR_VEFFECTS_RESPAWN].BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = gCvarList[CVAR_VEFFECTS_RESPAWN_DURATION].FloatValue;
        if(!flDuration)
        {
            return;
        }

        // Gets respawn particle
        gCvarList[CVAR_VEFFECTS_RESPAWN_NAME].GetString(sParticle, sizeof(sParticle));
        gCvarList[CVAR_VEFFECTS_RESPAWN_ATTACH].GetString(sAttachment, sizeof(sAttachment));
    }
    else
    {
        // Validate nemesis
        if(nemesisMode)
        {
            // If nemesis effect disabled, then stop
            if(!gCvarList[CVAR_VEFFECTS_NEMESIS].BoolValue) 
            {
                return;
            }
            
            // If the duration is zero, then stop
            flDuration = gCvarList[CVAR_VEFFECTS_NEMESIS_DURATION].FloatValue;
            if(!flDuration)
            {
                return;
            }

            // Gets nemesis particle
            gCvarList[CVAR_VEFFECTS_NEMESIS_NAME].GetString(sParticle, sizeof(sParticle)); 
            gCvarList[CVAR_VEFFECTS_NEMESIS_ATTACH].GetString(sAttachment, sizeof(sAttachment));
        }
        // Validate zombie
        else
        {
            // If infect effect disabled, then stop
            if(!gCvarList[CVAR_VEFFECTS_INFECT].BoolValue) 
            {
                return;
            }
            
            // If the duration is zero, then stop
            flDuration = gCvarList[CVAR_VEFFECTS_INFECT_DURATION].FloatValue;
            if(!flDuration)
            {
                return;
            }

            // Gets infect particle
            gCvarList[CVAR_VEFFECTS_INFECT_NAME].GetString(sParticle, sizeof(sParticle)); 
            gCvarList[CVAR_VEFFECTS_INFECT_ATTACH].GetString(sAttachment, sizeof(sAttachment));
        }
    }

    // Emit effect
    VEffectSpawnParticle(clientIndex, sAttachment, sParticle, flDuration);
}

/**
 * Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerVEffectsOnClientRegen(int clientIndex)
{
    // If regeneration effect disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_HEAL].BoolValue) 
    {
        return;
    }
    
    // If the duration is zero, then stop
    float flDuration = gCvarList[CVAR_VEFFECTS_HEAL_DURATION].FloatValue;
    if(!flDuration)
    {
        return;
    }
    
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];
    
    // Gets healing particle
    gCvarList[CVAR_VEFFECTS_HEAL_NAME].GetString(sParticle, sizeof(sParticle));
    gCvarList[CVAR_VEFFECTS_HEAL_ATTACH].GetString(sAttachment, sizeof(sAttachment));
    
    // Emit heal effect
    VEffectSpawnParticle(clientIndex, sAttachment, sParticle, flDuration);
}

/**
 * Client has been humanized.
 * 
 * @param clientIndex       The client index.
 * @param survivorMode      (Optional) Indicates that client will be a survivor.
 **/
void PlayerVEffectsOnClientHumanized(int clientIndex, bool survivorMode = false)
{
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];
    
    // Initialize duration variable
    static float flDuration;
    
    // Validate survivor
    if(survivorMode)
    {
        // If survivor effect disabled, then stop
        if(!gCvarList[CVAR_VEFFECTS_SURVIVOR].BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = gCvarList[CVAR_VEFFECTS_SURVIVOR_DURATION].FloatValue;
        if(!flDuration)
        {
            return;
        }

        // Gets survivor particle
        gCvarList[CVAR_VEFFECTS_SURVIVOR_NAME].GetString(sParticle, sizeof(sParticle)); 
        gCvarList[CVAR_VEFFECTS_SURVIVOR_ATTACH].GetString(sAttachment, sizeof(sAttachment)); 
    }
    else
    {
        // If antidot effect disabled, then stop
        if(!gCvarList[CVAR_VEFFECTS_ANTIDOT].BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = gCvarList[CVAR_VEFFECTS_ANTIDOT_DURATION].FloatValue;
        if(!flDuration)
        {
            return;
        }

        // Gets antidot particle
        gCvarList[CVAR_VEFFECTS_ANTIDOT_NAME].GetString(sParticle, sizeof(sParticle)); 
        gCvarList[CVAR_VEFFECTS_ANTIDOT_ATTACH].GetString(sAttachment, sizeof(sAttachment)); 
    }
    
    // Emit effect
    VEffectSpawnParticle(clientIndex, sAttachment, sParticle, flDuration);
}

/**
 * Client has been leap jump.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerVEffectsOnClientJump(int clientIndex)
{
    // If jump effect disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_LEAP].BoolValue) 
    {
        return;
    }
    
    // If the duration is zero, then stop
    float flDuration = gCvarList[CVAR_VEFFECTS_LEAP_DURATION].FloatValue;
    if(!flDuration)
    {
        return;
    }
    
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];
    
    // Gets jump particle
    gCvarList[CVAR_VEFFECTS_LEAP_NAME].GetString(sParticle, sizeof(sParticle)); 
    gCvarList[CVAR_VEFFECTS_LEAP_ATTACH].GetString(sAttachment, sizeof(sAttachment));
    
    // Emit jump effect
    VEffectSpawnParticle(clientIndex, sAttachment, sParticle, flDuration);
}