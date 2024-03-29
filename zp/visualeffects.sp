/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          visualeffects.sp
 *  Type:          Manager 
 *  Description:   Visual effects.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
#include "zp/visualeffects/visualambience.sp"
#include "zp/visualeffects/visualoverlays.sp"
#include "zp/visualeffects/playereffects.sp"
#include "zp/visualeffects/ragdoll.sp"
#include "zp/visualeffects/particles.sp"
#include "zp/visualeffects/healthsprite.sp"

/**
 * @brief Effects module load function.
 **/         
void VEffectsOnLoad()
{
	VAmbienceOnLoad();
	HealthOnLoad();
}

/**
 * @brief Hook effects cvar changes.
 **/
void VEffectsOnCvarInit()
{
	gCvarList.VEFFECTS_IMMUNITY_ALPHA = FindConVar("sv_disable_immunity_alpha");
	
	gCvarList.VEFFECTS_IMMUNITY_ALPHA.IntValue = 1;
	
	HookConVarChange(gCvarList.VEFFECTS_IMMUNITY_ALPHA,  CvarsUnlockOnCvarHook);
	
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
	VAmbienceOnClientInit(client);
}

/*
 * Effects main functions.
 */

/**
 * @brief Client has been spawned.
 * 
 * @param client            The client index.
 **/
void VEffectsOnClientSpawn(int client)
{
	ParticlesRemove(client);
}
 
/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void VEffectsOnClientDeath(int client)
{
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
	if (attacker > 0/* && attacker < MaxClients*/)
	{
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
	ParticlesRemove(client);
	PlayerVEffectsOnClientInfected(client, attacker);    
}

/**
 * @brief Client has been humanized.
 * 
 * @param client            The client index.
 **/
void VEffectsOnClientHumanized(int client)
{
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
	HealthOnClientUpdate(client);
}

/**
 * @brief Client has been regenerating.
 * 
 * @param client            The client index.
 **/
void VEffectsOnClientRegen(int client)
{
	PlayerVEffectsOnClientRegen(client);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param client            The client index.
 **/
 void VEffectsOnClientJump(int client)
{
	PlayerVEffectsOnClientJump(client);
}

/**
 * @brief The blast is started.
 * 
 * @param client            The client index.
 **/
void VEffectsOnBlast(int client)
{
	UTIL_CreateFadeScreen(client, 0.7, 0.3, FFADE_IN, {255, 255, 255, 255});
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
	UTIL_CreateShakeScreen(client, hAmplitude.FloatValue, hFrequency.FloatValue, hDuration.FloatValue);
}

/**
 * @brief Fade a client screen with specific parameters.
 * 
 * @param client            The client index.
 * @param hDuration         The cvar with duration of fade in the seconds.
 * @param hHoldTime         The cvar with holding time of fade in the seconds.
 * @param hR                The cvar with red color.
 * @param hG                The cvar with green color.
 * @param hB                The cvar with blue color.
 * @param hA                The cvar with alpha amount.
 **/
void VEffectsFadeClientScreen(int client, ConVar hDuration, ConVar hHoldTime, ConVar hR, ConVar hG, ConVar hB, ConVar hA)
{
	static int vColor[4];
	vColor[0] = hR.IntValue;
	vColor[1] = hG.IntValue;
	vColor[2] = hB.IntValue;
	vColor[3] = hA.IntValue;
	
	UTIL_CreateFadeScreen(client, hDuration.FloatValue, hHoldTime.FloatValue, FFADE_IN, vColor);
}
