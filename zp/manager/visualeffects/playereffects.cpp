/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          playereffects.cpp
 *  Type:          Module 
 *  Description:   Player visual effects.
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
 * @brief Hook player effects cvar changes.
 **/
void PlayerVEffectsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList.VEFFECTS_INFECT           = FindConVar("zp_veffects_infect"); 
    gCvarList.VEFFECTS_HUMANIZE         = FindConVar("zp_veffects_humanize"); 
    gCvarList.VEFFECTS_RESPAWN          = FindConVar("zp_veffects_respawn"); 
    gCvarList.VEFFECTS_RESPAWN_NAME     = FindConVar("zp_veffects_respawn_name");
    gCvarList.VEFFECTS_RESPAWN_ATTACH   = FindConVar("zp_veffects_respawn_attachment"); 
    gCvarList.VEFFECTS_RESPAWN_DURATION = FindConVar("zp_veffects_respawn_duration");
    gCvarList.VEFFECTS_HEAL             = FindConVar("zp_veffects_heal"); 
    gCvarList.VEFFECTS_HEAL_NAME        = FindConVar("zp_veffects_heal_name");
    gCvarList.VEFFECTS_HEAL_ATTACH      = FindConVar("zp_veffects_heal_attachment"); 
    gCvarList.VEFFECTS_HEAL_DURATION    = FindConVar("zp_veffects_heal_duration");
    gCvarList.VEFFECTS_LEAP             = FindConVar("zp_veffects_leap"); 
    gCvarList.VEFFECTS_LEAP_NAME        = FindConVar("zp_veffects_leap_name");
    gCvarList.VEFFECTS_LEAP_ATTACH      = FindConVar("zp_veffects_leap_attachment"); 
    gCvarList.VEFFECTS_LEAP_DURATION    = FindConVar("zp_veffects_leap_duration");
}

/**
 * @brief Client has been infected.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
void PlayerVEffectsOnClientInfected(int client, int attacker)
{
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];

    // Initialize duration variable
    static float flDuration;

    // Validate respawn
    if (gServerData.RoundStart && !attacker)
    {
        // If respawn effect disabled, then stop
        if (!gCvarList.VEFFECTS_RESPAWN.BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = gCvarList.VEFFECTS_RESPAWN_DURATION.FloatValue;
        if (!flDuration)
        {
            return;
        }

        // Gets respawn particle
        gCvarList.VEFFECTS_RESPAWN_NAME.GetString(sParticle, sizeof(sParticle));
        gCvarList.VEFFECTS_RESPAWN_ATTACH.GetString(sAttachment, sizeof(sAttachment));
    }
    else
    {
        // If infect effect disabled, then stop
        if (!gCvarList.VEFFECTS_INFECT.BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = ClassGetEffectTime(gClientData[client].Class);
        if (!flDuration)
        {
            return;
        }

        // Gets infect particle
        ClassGetEffectName(gClientData[client].Class, sParticle, sizeof(sParticle)); 
        ClassGetEffectAttach(gClientData[client].Class, sAttachment, sizeof(sAttachment));
    }

    // Emit a infect effect
    ParticlesCreate(client, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been humanized.
 * 
 * @param client            The client index.
 **/
void PlayerVEffectsOnClientHumanized(int client)
{
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];
    
    // Initialize duration variable
    static float flDuration;
    
    // Validate respawn
    if (gServerData.RoundNew)
    {
        // If respawn effect disabled, then stop
        if (!gCvarList.VEFFECTS_RESPAWN.BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = gCvarList.VEFFECTS_RESPAWN_DURATION.FloatValue;
        if (!flDuration)
        {
            return;
        }

        // Gets respawn particle
        gCvarList.VEFFECTS_RESPAWN_NAME.GetString(sParticle, sizeof(sParticle));
        gCvarList.VEFFECTS_RESPAWN_ATTACH.GetString(sAttachment, sizeof(sAttachment));
    }
    else
    {
        // If humanize effect disabled, then stop
        if (!gCvarList.VEFFECTS_HUMANIZE.BoolValue) 
        {
            return;
        }
        
        // If the duration is zero, then stop
        flDuration = ClassGetEffectTime(gClientData[client].Class);
        if (!flDuration)
        {
            return;
        }

        // Gets humanize particle
        ClassGetEffectName(gClientData[client].Class, sParticle, sizeof(sParticle)); 
        ClassGetEffectAttach(gClientData[client].Class, sAttachment, sizeof(sAttachment));
    }
    
    // Emit a humanize effect
    ParticlesCreate(client, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been regenerating.
 * 
 * @param client            The client index.
 **/
void PlayerVEffectsOnClientRegen(int client)
{
    // If regeneration effect disabled, then stop
    if (!gCvarList.VEFFECTS_HEAL.BoolValue) 
    {
        return;
    }
    
    // If the duration is zero, then stop
    float flDuration = gCvarList.VEFFECTS_HEAL_DURATION.FloatValue;
    if (!flDuration)
    {
        return;
    }
    
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];
    
    // Gets healing particle
    gCvarList.VEFFECTS_HEAL_NAME.GetString(sParticle, sizeof(sParticle));
    gCvarList.VEFFECTS_HEAL_ATTACH.GetString(sAttachment, sizeof(sAttachment));
    
    // Emit a heal effect
    ParticlesCreate(client, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param client            The client index.
 **/
void PlayerVEffectsOnClientJump(int client)
{
    // If jump effect disabled, then stop
    if (!gCvarList.VEFFECTS_LEAP.BoolValue) 
    {
        return;
    }
    
    // If the duration is zero, then stop
    float flDuration = gCvarList.VEFFECTS_LEAP_DURATION.FloatValue;
    if (!flDuration)
    {
        return;
    }
    
    // Initialize particles char
    static char sParticle[SMALL_LINE_LENGTH];
    static char sAttachment[SMALL_LINE_LENGTH];
    
    // Gets jump particle
    gCvarList.VEFFECTS_LEAP_NAME.GetString(sParticle, sizeof(sParticle)); 
    gCvarList.VEFFECTS_LEAP_ATTACH.GetString(sAttachment, sizeof(sAttachment));
    
    // Emit a jump effect
    ParticlesCreate(client, sAttachment, sParticle, flDuration);
}