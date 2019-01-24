/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          playereffects.cpp
 *  Type:          Module 
 *  Description:   Player visual effects.
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
 * @brief Hook player effects cvar changes.
 **/
void PlayerVEffectsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_VEFFECTS_PARTICLES]        = FindConVar("zp_veffects_particles"); 
    gCvarList[CVAR_VEFFECTS_INFECT]           = FindConVar("zp_veffects_infect"); 
    gCvarList[CVAR_VEFFECTS_HUMANIZE]         = FindConVar("zp_veffects_humanize"); 
    gCvarList[CVAR_VEFFECTS_RESPAWN]          = FindConVar("zp_veffects_respawn"); 
    gCvarList[CVAR_VEFFECTS_RESPAWN_NAME]     = FindConVar("zp_veffects_respawn_name");
    gCvarList[CVAR_VEFFECTS_RESPAWN_ATTACH]   = FindConVar("zp_veffects_respawn_attachment"); 
    gCvarList[CVAR_VEFFECTS_RESPAWN_DURATION] = FindConVar("zp_veffects_respawn_duration");
    gCvarList[CVAR_VEFFECTS_HEAL]             = FindConVar("zp_veffects_heal"); 
    gCvarList[CVAR_VEFFECTS_HEAL_NAME]        = FindConVar("zp_veffects_heal_name");
    gCvarList[CVAR_VEFFECTS_HEAL_ATTACH]      = FindConVar("zp_veffects_heal_attachment"); 
    gCvarList[CVAR_VEFFECTS_HEAL_DURATION]    = FindConVar("zp_veffects_heal_duration");
    gCvarList[CVAR_VEFFECTS_LEAP]             = FindConVar("zp_veffects_leap"); 
    gCvarList[CVAR_VEFFECTS_LEAP_NAME]        = FindConVar("zp_veffects_leap_name");
    gCvarList[CVAR_VEFFECTS_LEAP_ATTACH]      = FindConVar("zp_veffects_leap_attachment"); 
    gCvarList[CVAR_VEFFECTS_LEAP_DURATION]    = FindConVar("zp_veffects_leap_duration");
}

/**
 * @brief Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
void PlayerVEffectsOnClientInfected(const int clientIndex, const int attackerIndex)
{
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];

    // Initialize duration variable
    static float flDuration;

    // Validate respawn
    if(gServerData.RoundStart && !attackerIndex)
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
        // If infect effect disabled, then stop
        if(!gCvarList[CVAR_VEFFECTS_INFECT].BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = ClassGetEffectTime(gClientData[clientIndex].Class);
        if(!flDuration)
        {
            return;
        }

        // Gets infect particle
        ClassGetEffectName(gClientData[clientIndex].Class, sParticle, sizeof(sParticle)); 
        ClassGetEffectAttach(gClientData[clientIndex].Class, sAttachment, sizeof(sAttachment));
    }

    // Emit a infect effect
    VEffectSpawnParticle(clientIndex, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been humanized.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerVEffectsOnClientHumanized(const int clientIndex)
{
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];
    
    // Initialize duration variable
    static float flDuration;
    
    // Validate respawn
    if(gServerData.RoundNew)
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
        // If humanize effect disabled, then stop
        if(!gCvarList[CVAR_VEFFECTS_HUMANIZE].BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = ClassGetEffectTime(gClientData[clientIndex].Class);
        if(!flDuration)
        {
            return;
        }

        // Gets humanize particle
        ClassGetEffectName(gClientData[clientIndex].Class, sParticle, sizeof(sParticle)); 
        ClassGetEffectAttach(gClientData[clientIndex].Class, sAttachment, sizeof(sAttachment));
    }
    
    // Emit a humanize effect
    VEffectSpawnParticle(clientIndex, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerVEffectsOnClientRegen(const int clientIndex)
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
    
    // Emit a heal effect
    VEffectSpawnParticle(clientIndex, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerVEffectsOnClientJump(const int clientIndex)
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
    
    // Emit a jump effect
    VEffectSpawnParticle(clientIndex, sAttachment, sParticle, flDuration);
}