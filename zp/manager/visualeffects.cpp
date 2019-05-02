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
 * @param clientIndex       The client index.  
 **/
void VEffectOnClientInit(int clientIndex)
{
    // Forward event to sub-modules
    ParticlesOnClientInit(clientIndex);
}

/*
 * Effects main functions.
 */

/**
 * @brief The blast is started.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectOnBlast(int clientIndex)
{
    // Forward event to sub-modules
    VEffectsFadeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], FFADE_IN, {255, 255, 255, 255});
}

/**
 * @brief Client has been spawned.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectOnClientSpawn(int clientIndex)
{
    // Forward event to sub-modules
    ParticlesRemove(clientIndex);
}
 
/**
 * @brief Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectOnClientDeath(int clientIndex)
{
    // Forward event to sub-modules
    ParticlesRemove(clientIndex);
}

/**
 * @brief Client has been hurt.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param iHealth           The health amount.
 **/
void VEffectOnClientHurt(int clientIndex, int attackerIndex, int iHealth)
{
    // Validate attacker
    if(attackerIndex > 0/* && attackerIndex < MaxClients*/)
    {
        // Forward event to sub-modules
        HealthOnClientHurt(clientIndex, attackerIndex, iHealth);
    }
}

/**
 * @brief Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
void VEffectsOnClientInfected(int clientIndex, int attackerIndex)
{
    // Forward event to sub-modules
    ParticlesRemove(clientIndex);
    VEffectsShakeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_SHAKE_AMP], gCvarList[CVAR_VEFFECTS_SHAKE_FREQUENCY], gCvarList[CVAR_VEFFECTS_SHAKE_DURATION]);
    VEffectsFadeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], FFADE_IN, {255, 0, 0, 50});
    PlayerVEffectsOnClientInfected(clientIndex, attackerIndex);    
}

/**
 * @brief Client has been humanized.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectsOnClientHumanized(int clientIndex)
{
    // Forward event to sub-modules
    ParticlesRemove(clientIndex);
    PlayerVEffectsOnClientHumanized(clientIndex);
}

/**
 * @brief Client has been changed class state.
 *
 * @param clientIndex       The client index.
 **/
void VEffectsOnClientUpdate(int clientIndex)
{
    // Forward event to sub-modules
    HealthOnClientUpdate(clientIndex);
}

/**
 * @brief Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectsOnClientRegen(int clientIndex)
{
    // Forward event to sub-modules
    VEffectsFadeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], 0x0001, {0, 255, 0, 25});
    PlayerVEffectsOnClientRegen(clientIndex);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param clientIndex       The client index.
 **/
 void VEffectsOnClientJump(int clientIndex)
{
    // Forward event to sub-modules
    PlayerVEffectsOnClientJump(clientIndex);
}

/*
 * Stocks effects API.
 */

/**
 * @brief Shake a client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param hAmplitude        The cvar with amplitude of shake.
 * @param hFrequency        The cvar with frequency of shake.
 * @param hDuration         The cvar with duration of shake in the seconds.
 **/
void VEffectsShakeClientScreen(int clientIndex, ConVar hAmplitude, ConVar hFrequency, ConVar hDuration)
{
    // If screen shake disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_SHAKE].BoolValue) 
    {
        return;
    }
    
    // Create message
    UTIL_CreateShakeScreen(clientIndex, hAmplitude.FloatValue, hFrequency.FloatValue, hDuration.FloatValue);
}

/**
 * @brief Fade a client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param hDuration         The cvar with duration of fade in the seconds.
 * @param hHoldTime         The cvar with holding time of fade in the seconds.
 * @param iFlags            The flags.
 * @param vColor            The array with RGB color.
 **/
void VEffectsFadeClientScreen(int clientIndex, ConVar hDuration, ConVar hHoldTime, int iFlags, int vColor[4])
{
    // If screen fade disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_FADE].BoolValue) 
    {
        return;
    }
    
    // Create message
    UTIL_CreateFadeScreen(clientIndex, hDuration.FloatValue, hHoldTime.FloatValue, iFlags, vColor);
}