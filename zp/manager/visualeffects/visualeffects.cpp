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
#define EXP_NODAMAGE               1
#define EXP_REPEATABLE             2
#define EXP_NOFIREBALL             4
#define EXP_NOSMOKE                8
#define EXP_NODECAL               16
#define EXP_NOSPARKS              32
#define EXP_NOSOUND               64
#define EXP_RANDOMORIENTATION    128
#define EXP_NOFIREBALLSMOKE      256
#define EXP_NOPARTICLES          512
#define EXP_NODLIGHTS           1024
#define EXP_NOCLAMPMIN          2048
#define EXP_NOCLAMPMAX          4096
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
void VEffectOnClientDeath(int clientIndex)
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
void VEffectsOnClientInfected(int clientIndex, bool nemesisMode = false, bool respawnMode = false)
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
void VEffectsOnClientHumanized(int clientIndex, bool survivorMode = false, bool respawnMode = false)
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
void VEffectsOnClientRegen(int clientIndex)
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
void VEffectsOnClientJump(int clientIndex)
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
 * Shake a client's screen with specific parameters.
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
 * Fade a client's screen with specific parameters.
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
 * Send a hint message to client's screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param sMessage          The message to send.
 **/
void VEffectsHintClientScreen(int clientIndex, char[] sMessage)
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
 * @param sAttach           The attachment bone of the entity parent.
 * @param sType             The type of the particle.
 * @param flDurationTime    The duration of light.
 * @return                  The entity index.
 **/
int VEffectSpawnParticle(int clientIndex, char[] sAttach, char[] sType, float flDurationTime)
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

            // Gets client's position
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
void VEffectRemoveParticle(int clientIndex)
{
    // Initialize char
    static char sClassname[NORMAL_LINE_LENGTH];
    
    // Gets max amount of entities
    int nGetMaxEnt = GetMaxEntities();
    
    // entityIndex = entity index
    for(int entityIndex = MaxClients; entityIndex <= nGetMaxEnt; entityIndex++)
    {
        // If entity isn't valid, then continue
        if(IsValidEdict(entityIndex))
        {
            // Gets valid edict's classname
            GetEdictClassname(entityIndex, sClassname, sizeof(sClassname));
            
            // If entity is an attach particle entity
            if(!strncmp(sClassname, "info_pa", 7, false)) //! Only validate few charcters
            {
                // Validate parent
                if(GetEntDataEnt2(entityIndex, g_iOffset_EntityOwnerEntity) == clientIndex)
                {
                    AcceptEntityInput(entityIndex, "Kill"); //! Destroy!
                }
            }
        }
    }
}

/**
 * Create an attached muzzlesmoke to the entity.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The weapon index.
 **/
void VEffectSpawnMuzzleSmoke(int clientIndex, int entityIndex)
{
    #define PARTICLE_DISPATCH_FROM_ENTITY (1 << 0)
    #define PATTACH_WORLDORIGIN 5

    TE_Start("EffectDispatch");
    TE_WriteNum("entindex", entityIndex);
    TE_WriteNum("m_fFlags", PARTICLE_DISPATCH_FROM_ENTITY); // https://developer.valvesoftware.com/wiki/SDK_Known_Issues_List_Fixed#Server%20Dispatching%20an%20Attached%20Particle%20Effect
    TE_WriteNum("m_nHitBox", fnGetTableItemIndex("ParticleEffectNames", "weapon_muzzle_smoke"));
    TE_WriteNum("m_iEffectName", fnGetTableItemIndex("EffectDispatch", "ParticleEffect"));
    TE_WriteNum("m_nAttachmentIndex", 1);
    TE_WriteNum("m_nDamageType", PATTACH_WORLDORIGIN);
    TE_SendToClient(clientIndex);
}

/**
 * Delete an attached muzzlesmoke from the entity.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The weapon index.
 **/
void VEffectRemoveMuzzle(int clientIndex, int entityIndex)
{
    TE_Start("EffectDispatch");
    TE_WriteNum("entindex", entityIndex);
    TE_WriteNum("m_iEffectName", fnGetTableItemIndex("EffectDispatch", "ParticleEffectStop"));
    TE_SendToClient(clientIndex);
}