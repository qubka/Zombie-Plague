/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          visualeffects.cpp
 *  Type:          Manager 
 *  Description:   Visual effects.
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

/*
 * Load other visual effect modules
 */
#include "zp/manager/visualeffects/visualambience.cpp"
#include "zp/manager/visualeffects/visualoverlays.cpp"
#include "zp/manager/visualeffects/playereffects.cpp"
#include "zp/manager/visualeffects/ragdoll.cpp"
#include "zp/manager/visualeffects/particles.cpp"
#include "zp/manager/visualeffects/healthsprite.cpp"

/**
 * @brief Effects module init function.
 **/
void VEffectsOnInit(/*void*/)
{
    // Forward event to sub-modules
    ParticlesOnInit();
}

/**
 * @brief Effects module load function.
 **/         
void VEffectsOnLoad(/*void*/)
{
    // Forward event to sub-modules
    VAmbienceOnLoad();
    ParticlesOnLoad();
    HealthOnLoad();
}

/**
 * @brief Effects module purge function.
 **/
void VEffectsOnPurge(/*void*/)
{
    // Forward event to sub-modules
    ParticlesOnPurge();
}

/**
 * @brief Hook effects cvar changes.
 **/
void VEffectsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_VEFFECTS_SHAKE]           = FindConVar("zp_veffects_shake"); 
    gCvarList[CVAR_VEFFECTS_SHAKE_AMP]       = FindConVar("zp_veffects_shake_amp");
    gCvarList[CVAR_VEFFECTS_SHAKE_FREQUENCY] = FindConVar("zp_veffects_shake_frequency");
    gCvarList[CVAR_VEFFECTS_SHAKE_DURATION]  = FindConVar("zp_veffects_shake_duration"); 
    gCvarList[CVAR_VEFFECTS_FADE]            = FindConVar("zp_veffects_fade"); 
    gCvarList[CVAR_VEFFECTS_FADE_TIME]       = FindConVar("zp_veffects_fade_time"); 
    gCvarList[CVAR_VEFFECTS_FADE_DURATION]   = FindConVar("zp_veffects_fade_duration"); 
    gCvarList[CVAR_VEFFECTS_IMMUNITY_ALPHA]  = FindConVar("sv_disable_immunity_alpha");
    
    // Sets locked cvars to their locked value
    gCvarList[CVAR_VEFFECTS_IMMUNITY_ALPHA].IntValue = 1;
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_IMMUNITY_ALPHA],  CvarsUnlockOnCvarHook);
    
    // Forward event to sub-modules
    VAmbienceOnCvarInit();
    RagdollOnCvarInit();
    HealthOnCvarInit();
    PlayerVEffectsOnCvarInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void VEffectsOnClientInit(int client)
{
    // Forward event to sub-modules
    VAmbienceOnClientInit(client);
}

/*
 * Effects main functions.
 */

/**
 * @brief The blast is started.
 * 
 * @param client            The client index.
 **/
void VEffectsOnBlast(int client)
{
    // Forward event to sub-modules
    VEffectsFadeClientScreen(client, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], FFADE_IN, {255, 255, 255, 255});
}

/**
 * @brief Client has been spawned.
 * 
 * @param client            The client index.
 **/
void VEffectsOnClientSpawn(int client)
{
    // Forward event to sub-modules
    ParticlesRemove(client);
}
 
/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void VEffectsOnClientDeath(int client)
{
    // Forward event to sub-modules
    ParticlesRemove(client);
}

/**
 * @brief Client has been hurt.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 * @param iHealth           The health amount.
 **/
void VEffectsOnClientHurt(int client, int attacker, int iHealth)
{
    // Validate attacker
    if(attacker > 0/* && attacker < MaxClients*/)
    {
        // Forward event to sub-modules
        HealthOnClientHurt(client, attacker, iHealth);
    }
}

/**
 * @brief Client has been infected.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
void VEffectsOnClientInfected(int client, int attacker)
{
    // Forward event to sub-modules
    ParticlesRemove(client);
    VEffectsShakeClientScreen(client, gCvarList[CVAR_VEFFECTS_SHAKE_AMP], gCvarList[CVAR_VEFFECTS_SHAKE_FREQUENCY], gCvarList[CVAR_VEFFECTS_SHAKE_DURATION]);
    VEffectsFadeClientScreen(client, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], FFADE_IN, {255, 0, 0, 50});
    PlayerVEffectsOnClientInfected(client, attacker);    
}

/**
 * @brief Client has been humanized.
 * 
 * @param client            The client index.
 **/
void VEffectsOnClientHumanized(int client)
{
    // Forward event to sub-modules
    ParticlesRemove(client);
    PlayerVEffectsOnClientHumanized(client);
}

/**
 * @brief Client has been changed class state.
 *
 * @param client            The client index.
 **/
void VEffectsOnClientUpdate(int client)
{
    // Forward event to sub-modules
    HealthOnClientUpdate(client);
}

/**
 * @brief Client has been regenerating.
 * 
 * @param client            The client index.
 **/
void VEffectsOnClientRegen(int client)
{
    // Forward event to sub-modules
    VEffectsFadeClientScreen(client, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], 0x0001, {0, 255, 0, 25});
    PlayerVEffectsOnClientRegen(client);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param client            The client index.
 **/
 void VEffectsOnClientJump(int client)
{
    // Forward event to sub-modules
    PlayerVEffectsOnClientJump(client);
}

/*
 * Stocks effects API.
 */

/**
 * @brief Shake a client screen with specific parameters.
 * 
 * @param client            The client index.
 * @param hAmplitude        The cvar with amplitude of shake.
 * @param hFrequency        The cvar with frequency of shake.
 * @param hDuration         The cvar with duration of shake in the seconds.
 **/
void VEffectsShakeClientScreen(int client, ConVar hAmplitude, ConVar hFrequency, ConVar hDuration)
{
    // If screen shake disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_SHAKE].BoolValue) 
    {
        return;
    }
    
    // Create message
    UTIL_CreateShakeScreen(client, hAmplitude.FloatValue, hFrequency.FloatValue, hDuration.FloatValue);
}

/**
 * @brief Fade a client screen with specific parameters.
 * 
 * @param client            The client index.
 * @param hDuration         The cvar with duration of fade in the seconds.
 * @param hHoldTime         The cvar with holding time of fade in the seconds.
 * @param iFlags            The flags.
 * @param vColor            The array with RGB color.
 **/
void VEffectsFadeClientScreen(int client, ConVar hDuration, ConVar hHoldTime, int iFlags, int vColor[4])
{
    // If screen fade disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_FADE].BoolValue) 
    {
        return;
    }
    
    // Create message
    UTIL_CreateFadeScreen(client, hDuration.FloatValue, hHoldTime.FloatValue, iFlags, vColor);
}