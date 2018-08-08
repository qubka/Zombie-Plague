/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          visualeffects.cpp
 *  Type:          Module 
 *  Description:   Visual effects.
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

 /*
  * Load other visual effect modules
  */
#include "zp/manager/visualeffects/visualambience.cpp"
#include "zp/manager/visualeffects/playereffects.cpp"
#include "zp/manager/visualeffects/visualoverlay.cpp"
#include "zp/manager/visualeffects/ragdoll.cpp"
 
/**
 * @section Explosion flags.
 **/
#define EXP_NODAMAGE            (1<<0)
#define EXP_REPEATABLE          (1<<1)
#define EXP_NOFIREBALL          (1<<2)
#define EXP_NOSMOKE             (1<<3)
#define EXP_NODECAL             (1<<4)
#define EXP_NOSPARKS            (1<<5)
#define EXP_NOSOUND             (1<<6)
#define EXP_RANDOMORIENTATION   (1<<7)
#define EXP_NOFIREBALLSMOKE     (1<<8)
#define EXP_NOPARTICLES         (1<<9)
#define EXP_NODLIGHTS           (1<<10)
#define EXP_NOCLAMPMIN          (1<<11)
#define EXP_NOCLAMPMAX          (1<<12)
/**
 * @endsection
 **/

/**
 * Load visual effects data.
 **/
void VEffectsLoad(/*void*/)
{
    // Forward event to sub-modules
    VAmbienceLoad();
    VOverlayLoad();
}

/**
 * Plugin has just finished creating/hooking cvars.
 **/
 void VEffectsOnCvarInit(/*void*/)
{
    // Hook zp_veffects_* cvars
    VAmbienceCvarsHook();
}

/**
 * Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectOnClientDeath(const int clientIndex)
{
    // If particles disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_PARTICLES].BoolValue)
    {
        return;
    }
    
    // Validate round state 
    if(gServerData[Server_RoundStart]) //! [Optimized]
    {
        // Forward event to sub-modules
        VEffectRemoveParticle(clientIndex);
    }
}

/**
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param nemesisMode       (Optional) Indicates that client will be a nemesis.
 * @param respawnMode       (Optional) Indicates that infection was on spawn.
 **/
void VEffectsOnClientInfected(const int clientIndex, const bool nemesisMode = false, const bool respawnMode = false)
{
    // If particles disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_PARTICLES].BoolValue)
    {
        return;
    }

    // Forward event to sub-modules
    if(!respawnMode) VEffectRemoveParticle(clientIndex);
    VEffectsShakeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_SHAKE_AMP], gCvarList[CVAR_VEFFECTS_SHAKE_FREQUENCY], gCvarList[CVAR_VEFFECTS_SHAKE_DURATION]);
    VEffectsFadeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], 0x0001, {255, 0, 0, 50});
    PlayerVEffectsOnClientInfected(clientIndex, nemesisMode, respawnMode);
}

/**
 * Client has been humanized.
 * 
 * @param clientIndex       The client index.
 * @param survivorMode      (Optional) Indicates that client will be a survivor.
 * @param respawnMode       (Optional) Indicates that humanized was on spawn.
 **/
void VEffectsOnClientHumanized(const int clientIndex, const bool survivorMode = false, const bool respawnMode = false)
{
    // If particles disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_PARTICLES].BoolValue)
    {
        return;
    }

    // Forward event to sub-modules
    if(!respawnMode) VEffectRemoveParticle(clientIndex);
    PlayerVEffectsOnClientHumanized(clientIndex, survivorMode);
}

/**
 * Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectsOnClientRegen(const int clientIndex)
{
    // If particles disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_PARTICLES].BoolValue)
    {
        return;
    }
    
    // Forward event to sub-modules
    VEffectsFadeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], 0x0001, {0, 255, 0, 25});
    PlayerVEffectsOnClientRegen(clientIndex);
}

/**
 * Client has been leap jump.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectsOnClientJump(const int clientIndex)
{
    // If particles disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_PARTICLES].BoolValue)
    {
        return;
    }
    
    // Forward event to sub-modules
    PlayerVEffectsOnClientJump(clientIndex);
}

/*
 * Effect stocks.
 */

/**
 * Shake a client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param hAmplitude        The cvar with amplitude of shake.
 * @param hFrequency        The cvar with frequency of shake.
 * @param hDuration         The cvar with duration of shake in the seconds.
 **/
void VEffectsShakeClientScreen(const int clientIndex, const ConVar hAmplitude, const ConVar hFrequency, const ConVar hDuration)
{
    // If screen shake disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_SHAKE].BoolValue) 
    {
        return;
    }
    
    // Create message
    Handle hShake = StartMessageOne("Shake", clientIndex);

    // Validate message
    if(hShake != INVALID_HANDLE)
    {
        // Write shake information to message handle
        PbSetInt(hShake,   "command", 0);
        PbSetFloat(hShake, "local_amplitude", hAmplitude.FloatValue);
        PbSetFloat(hShake, "frequency", hFrequency.FloatValue);
        PbSetFloat(hShake, "duration", hDuration.FloatValue);

        // End usermsg and send to client
        EndMessage();
    }
}

/**
 * Fade a client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param hDuration         The cvar with duration of fade in the seconds.
 * @param hHoldTime         The cvar with holding time of fade in the seconds.
 * @param iFlags            The flags.
 * @param vColor            The array with RGB color.
 **/
void VEffectsFadeClientScreen(const int clientIndex, const ConVar hDuration, const ConVar hHoldTime, const int iFlags, const int vColor[4])
{
    // If screen fade disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_FADE].BoolValue) 
    {
        return;
    }
    
    // Create message
    Handle hFade = StartMessageOne("Fade", clientIndex);

    // Validate message
    if(hFade != INVALID_HANDLE)
    {
        // Write shake information to message handle
        PbSetInt(hFade, "duration", RoundToNearest(hDuration.FloatValue * 1000.0)); 
        PbSetInt(hFade, "hold_time", RoundToNearest(hHoldTime.FloatValue * 1000.0)); 
        PbSetInt(hFade, "flags", iFlags); 
        PbSetColor(hFade, "clr", vColor); 

        // End usermsg and send to client
        EndMessage();
    }
}

/**
 * Send a hint message to client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param sMessage          The message to send.
 **/
void VEffectsHintClientScreen(const int clientIndex, const char[] sMessage)
{
    // Create message
    Handle hMessage = StartMessageOne("HintText", clientIndex);

    // Validate message
    if(hMessage != INVALID_HANDLE)
    {
        // Write shake information to message handle
        PbSetString(hMessage, "text", sMessage);

        // End usermsg and send to client
        EndMessage();
    }
}

/**
 * Create an attached particle entity.
 * 
 * @param clientIndex       The client index.
 * @param sAttach           The attachment name.
 * @param sType             The type of the particle.
 * @param flDurationTime    The duration of light.
 * @return                  The entity index.
 **/
int VEffectSpawnParticle(const int clientIndex, const char[] sAttach, const char[] sType, const float flDurationTime)
{
    // Create an attach particle entity
    int entityIndex = CreateEntityByName("info_particle_system");
    
    // If entity isn't valid, then skip
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        DispatchKeyValue(entityIndex, "start_active", "1");
        DispatchKeyValue(entityIndex, "effect_name", sType);
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Sets parent to the entity
        SetVariantString("!activator");
        AcceptEntityInput(entityIndex, "SetParent", clientIndex, entityIndex);
        SetEntDataEnt2(entityIndex, g_iOffset_EntityOwnerEntity, clientIndex, true);
        
        // Sets attachment to the entity
        if(strlen(sAttach))
        { 
            SetVariantString(sAttach); 
            AcceptEntityInput(entityIndex, "SetParentAttachment", clientIndex, entityIndex);
        }
        else
        {
            // Initialize vector variables
            static float vOrigin[3];

            // Gets client position
            GetClientAbsOrigin(clientIndex, vOrigin);

            // Spawn the entity
            DispatchKeyValueVector(entityIndex, "origin", vOrigin);
        }
        
        // Activate the entity
        ActivateEntity(entityIndex);
        AcceptEntityInput(entityIndex, "Start");
        
        // Initialize char
        static char sTime[SMALL_LINE_LENGTH];
        Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", flDurationTime);
        
        // Sets modified flags on the entity
        SetVariantString(sTime);
        AcceptEntityInput(entityIndex, "AddOutput");
        AcceptEntityInput(entityIndex, "FireUser1");
    }
    
    // Return on the success
    return entityIndex;
}

/**
 * Delete an attached particle from the entity.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectRemoveParticle(const int clientIndex)
{
    // Initialize char
    static char sClassname[NORMAL_LINE_LENGTH];
    
    // Gets max amount of entities
    int nGetMaxEnt = GetMaxEntities();
    
    // x = entity index
    for(int x = MaxClients; x <= nGetMaxEnt; x++)
    {
        // Validate entity
        if(IsValidEdict(x))
        {
            // Gets valid edict classname
            GetEdictClassname(x, sClassname, sizeof(sClassname));
            
            // If entity is an attach particle entity
            if(!strncmp(sClassname, "info_pa", 7, false)) //! Only validate few charcters
            {
                // Validate parent
                if(GetEntDataEnt2(x, g_iOffset_EntityOwnerEntity) == clientIndex)
                {
                    AcceptEntityInput(x, "Kill"); //! Destroy
                }
            }
        }
    }
}

/**
 * Create an attached muzzle to the entity.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The weapon index.
 * @param sEffect           The effect name.
 **/
void VEffectSpawnMuzzle(const int clientIndex, const int entityIndex, const char[] sEffect)
{
    // Initialize vector variables
    static float vOrigin[3];

    // Gets client position
    GetClientAbsOrigin(clientIndex, vOrigin); 

    // Create an effect
    VEffectDispatch(entityIndex, sEffect, "ParticleEffect", vOrigin, vOrigin, _, 1);
    TE_SendToClient(clientIndex);
}

/**
 * Create an attached muzzlesmoke to the entity.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The weapon index.
 **/
void VEffectSpawnMuzzleSmoke(const int clientIndex, const int entityIndex)
{
    // Initialize vector variables
    static float vOrigin[3];

    // Gets client position
    GetClientAbsOrigin(clientIndex, vOrigin); 

    // Create an effect
    VEffectDispatch(entityIndex, "weapon_muzzle_smoke", "ParticleEffect", vOrigin, vOrigin, _, 1);
    TE_SendToClient(clientIndex);
}

/**
 * Delete an attached muzzlesmoke from the entity.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The weapon index.
 **/
void VEffectRemoveMuzzle(const int clientIndex, const int entityIndex)
{
    // Initialize vector variables
    static float vOrigin[3];

    // Gets client position
    GetClientAbsOrigin(clientIndex, vOrigin); 

    // Delete an effect
    VEffectDispatch(entityIndex, _, "ParticleEffectStop", vOrigin, vOrigin);
    TE_SendToClient(clientIndex);
}

/**
 * Dispatch an attached effect.
 * 
 * @param entityIndex       (Optional) The entity index.
 * @param sParticle         (Optional) The particle name.
 * @param sItem             (Optional) The particle item.
 * @param vStart            (Optional) The start origin.
 * @param vEnd              (Optional) The end origin.
 * @param vAngle            (Optional) The angle vector.
 * @param iAttachment       (Optional) The attachment index.
 **/
void VEffectDispatch(const int entityIndex = 0, const char[] sParticle = "", const char[] sIndex = "", const float vStart[3] = NULL_VECTOR, const float vEnd[3] = NULL_VECTOR, const float vAngle[3] = NULL_VECTOR, const int iAttachment = 0) 
{
    // Dispatch effect
    TE_Start("EffectDispatch");
    if(strlen(sParticle)) TE_WriteNum("m_nHitBox", fnGetParticleEffectIndex(sParticle)); 
    if(strlen(sIndex)) TE_WriteNum("m_iEffectName", fnGetEffectIndex(sIndex));
    TE_WriteFloat("m_vOrigin.x", vEnd[0]);
    TE_WriteFloat("m_vOrigin.y", vEnd[1]);
    TE_WriteFloat("m_vOrigin.z", vEnd[2]);
    TE_WriteFloat("m_vStart.x", vStart[0]);
    TE_WriteFloat("m_vStart.y", vStart[1]);
    TE_WriteFloat("m_vStart.z", vStart[2]);
    TE_WriteVector("m_vAngles", vAngle);
    TE_WriteNum("entindex", entityIndex);
    if(iAttachment) 
    {
        #define PATTACH_WORLDORIGIN 5
        #define PARTICLE_DISPATCH_FROM_ENTITY (1 << 0)
    
        TE_WriteNum("m_nDamageType", PATTACH_WORLDORIGIN);
        TE_WriteNum("m_fFlags", PARTICLE_DISPATCH_FROM_ENTITY); /// https://developer.valvesoftware.com/wiki/SDK_Known_Issues_List_Fixed#Server%20Dispatching%20an%20Attached%20Particle%20Effect
        TE_WriteNum("m_nAttachmentIndex", iAttachment);
    }
}
