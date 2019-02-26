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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
 * @section Fade flags.
 **/
#define FFADE_IN                0x0001        
#define FFADE_OUT               0x0002        
#define FFADE_MODULATE          0x0004      
#define FFADE_STAYOUT           0x0008       
#define FFADE_PURGE             0x0010       
/**
 * @endsection
 **/
 
/**
 * @section Particle flags.
 **/
#define PARTICLE_WORLDORIGIN          5
#define PARTICLE_DISPATCH_FROM_ENTITY (1<<0)
/**
 * @endsection
 **/
 
/**
 * @brief Effects module init function.
 **/
void VEffectsOnInit(/*void*/)
{
    // If windows, then stop
    if(gServerData.Platform == OS_Windows)
    {
        return;
    }
    
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
    
    // If windows, then stop
    if(gServerData.Platform == OS_Windows)
    {
        return;
    }
    
    // Forward event to sub-modules
    ParticlesOnLoad();
}

/**
 * @brief Effects module purge function.
 **/
void VEffectsOnPurge(/*void*/)
{
    // If windows, then stop
    if(gServerData.Platform == OS_Windows)
    {
        return;
    }
    
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
    
    // Forward event to sub-modules
    VAmbienceOnCvarInit();
    RagdollOnCvarInit();
    PlayerVEffectsOnCvarInit();
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
 * @brief Client has been killed.
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

    // Forward event to sub-modules
    VEffectRemoveParticle(clientIndex);
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
    VEffectsShakeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_SHAKE_AMP], gCvarList[CVAR_VEFFECTS_SHAKE_FREQUENCY], gCvarList[CVAR_VEFFECTS_SHAKE_DURATION]);
    VEffectsFadeClientScreen(clientIndex, gCvarList[CVAR_VEFFECTS_FADE_DURATION], gCvarList[CVAR_VEFFECTS_FADE_TIME], FFADE_IN, {255, 0, 0, 50});

    // If particles disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_PARTICLES].BoolValue)
    {
        return;
    }

    // Forward event to sub-modules
    VEffectRemoveParticle(clientIndex);
    PlayerVEffectsOnClientInfected(clientIndex, attackerIndex);    
}

/**
 * @brief Client has been humanized.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectsOnClientHumanized(int clientIndex)
{
    // If particles disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_PARTICLES].BoolValue)
    {
        return;
    }

    // Forward event to sub-modules
    VEffectRemoveParticle(clientIndex);
    PlayerVEffectsOnClientHumanized(clientIndex);
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
    
    // If particles disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_PARTICLES].BoolValue)
    {
        return;
    }
    
    // Forward event to sub-modules
    PlayerVEffectsOnClientRegen(clientIndex);
}

/**
 * @brief Client has been leap jumped.
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
    Protobuf hShake = view_as<Protobuf>(StartMessageOne("Shake", clientIndex));

    // Validate message
    if(hShake != null)
    {
        // Write shake information to message handle
        hShake.SetInt("command", 0);
        hShake.SetFloat("local_amplitude", hAmplitude.FloatValue);
        hShake.SetFloat("frequency", hFrequency.FloatValue);
        hShake.SetFloat("duration", hDuration.FloatValue);

        // End usermsg and send to the client
        EndMessage();
    }
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
    Protobuf hFade = view_as<Protobuf>(StartMessageOne("Fade", clientIndex));

    // Validate message
    if(hFade != null)
    {
        // Write shake information to message handle
        hFade.SetInt("duration", RoundToNearest(hDuration.FloatValue * 1000.0)); 
        hFade.SetInt("hold_time", RoundToNearest(hHoldTime.FloatValue * 1000.0)); 
        hFade.SetInt("flags", iFlags); 
        hFade.SetColor("clr", vColor); 

        // End usermsg and send to the client
        EndMessage();
    }
}

/**
 * @brief Send a hint message to the client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param sMessage          The message to send.
 **/
void VEffectsHintClientScreen(int clientIndex, char[] sMessage)
{
    // Create message
    Protobuf hMessage = view_as<Protobuf>(StartMessageOne("HintText", clientIndex));

    // Validate message
    if(hMessage != null)
    {
        // Write shake information to message handle
        hMessage.SetString("text", sMessage);

        // End usermsg and send to the client
        EndMessage();
    }
}

/**
 * @brief Send a hud message to the client screen with specific parameters.
 * 
 * @param hSync             New HUD synchronization object.
 * @param clientIndex       The client index.
 * @param x                 x coordinate, from 0 to 1. -1.0 is the center.
 * @param y                 y coordinate, from 0 to 1. -1.0 is the center.
 * @param holdTime          Number of seconds to hold the text.
 * @param r                 Red color value.
 * @param g                 Green color value.
 * @param b                 Blue color value.
 * @param a                 Alpha transparency value.
 * @param effect            0/1 causes the text to fade in and fade out. 2 causes the text to flash[?].
 * @param fxTime            Duration of chosen effect (may not apply to all effects).
 * @param fadeIn            Number of seconds to spend fading in.
 * @param fadeOut           Number of seconds to spend fading out.
 * @param sMessage          The message to send.
 **/
void VEffectsHudClientScreen(Handle hSync, int clientIndex, float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut, char[] sMessage)
{
    // Sets HUD parameters for drawing text
    SetHudTextParams(x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut);
        
    // Print translated phrase to the client screen
    ShowSyncHudText(clientIndex, hSync, sMessage);
}

/**
 * @brief Create an attached particle entity.
 * 
 * @param clientIndex       The client index.
 * @param sAttach           The attachment name.
 * @param sType             The type of the particle.
 * @param flDurationTime    The duration of light.
 * @return                  The entity index.
 **/
int VEffectSpawnParticle(int clientIndex, char[] sAttach, char[] sType, float flDurationTime)
{
    // Validate name
    if(!hasLength(sType))
    {
        return INVALID_ENT_REFERENCE;
    }
    
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
        ToolsSetEntityOwner(entityIndex, clientIndex);
        
        // Sets attachment to the entity
        if(hasLength(sAttach))
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
        
        // Initialize time char
        static char sTime[SMALL_LINE_LENGTH];
        FormatEx(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", flDurationTime);
        
        // Sets modified flags on the entity
        SetVariantString(sTime);
        AcceptEntityInput(entityIndex, "AddOutput");
        AcceptEntityInput(entityIndex, "FireUser1");
    }
    
    // Return on success
    return entityIndex;
}

/**
 * @brief Delete an attached particle from the entity.
 * 
 * @param clientIndex       The client index.
 **/
void VEffectRemoveParticle(int clientIndex)
{
    // Initialize classname char
    static char sClassname[SMALL_LINE_LENGTH];

    // i = entity index
    int MaxEntities = GetMaxEntities();
    for(int i = MaxClients; i <= MaxEntities; i++)
    {
        // Validate entity
        if(IsValidEdict(i))
        {
            // Gets valid edict classname
            GetEdictClassname(i, sClassname, sizeof(sClassname));

            // If entity is an attach particle entity
            if(sClassname[0] == 'i' && sClassname[5] == 'p' && sClassname[6] == 'a')
            {
                // Validate parent
                if(ToolsGetEntityOwner(i) == clientIndex)
                {
                    AcceptEntityInput(i, "Kill"); /// Destroy
                }
            }
        }
    }
}

/**
 * @brief Create an attached muzzle to the entity.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The weapon index.
 * @param sEffect           The effect name.
 **/
void VEffectSpawnMuzzle(int clientIndex, int entityIndex, char[] sEffect)
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
 * @brief Create an attached muzzlesmoke to the entity.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The weapon index.
 **/
void VEffectSpawnMuzzleSmoke(int clientIndex, int entityIndex)
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
 * @brief Delete an attached muzzlesmoke from the entity.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The weapon index.
 **/
void VEffectRemoveMuzzle(int clientIndex, int entityIndex)
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
 * @brief Dispatch an attached effect.
 * 
 * @param entityIndex       (Optional) The entity index.
 * @param sParticle         (Optional) The particle name.
 * @param sItem             (Optional) The particle item.
 * @param vStart            (Optional) The start origin.
 * @param vEnd              (Optional) The end origin.
 * @param vAngle            (Optional) The angle vector.
 * @param iAttachment       (Optional) The attachment index.
 **/
void VEffectDispatch(int entityIndex = 0, char[] sParticle = "", char[] sIndex = "", float vStart[3] = NULL_VECTOR, float vEnd[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, int iAttachment = 0) 
{
    // Dispatch effect
    TE_Start("EffectDispatch");
    if(hasLength(sParticle)) TE_WriteNum("m_nHitBox", VEffectGetParticleEffectIndex(sParticle)); 
    if(hasLength(sIndex)) TE_WriteNum("m_iEffectName", VEffectGetEffectIndex(sIndex));
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
        TE_WriteNum("m_nDamageType", PARTICLE_WORLDORIGIN);
        TE_WriteNum("m_fFlags", PARTICLE_DISPATCH_FROM_ENTITY); /// @link https://developer.valvesoftware.com/wiki/SDK_Known_Issues_List_Fixed#Server%20Dispatching%20an%20Attached%20Particle%20Effect
        TE_WriteNum("m_nAttachmentIndex", iAttachment);
    }
}

/**
 * @brief Searches for the index of a given string in a dispatch table.
 *
 * @param sEffect           The effect name.
 * @return                  The item index.
 **/
int VEffectGetEffectIndex(char[] sEffect)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;

    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("EffectDispatch");
    }

    // Searches for the index of a given string in a string table
    int itemIndex = FindStringIndex(tableIndex, sEffect);

    // Validate item
    if(itemIndex != INVALID_STRING_INDEX)
    {
        return itemIndex;
    }

    // Return on the unsuccess
    return 0;
}

/**
 * @brief Searches for the index of a given string in an effect table.
 *
 * @param sEffect           The effect name.
 * @return                  The item index.
 **/
int VEffectGetParticleEffectIndex(char[] sEffect)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;

    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("ParticleEffectNames");
    }

    // Searches for the index of a given string in a string table
    int itemIndex = FindStringIndex(tableIndex, sEffect);

    // Validate item
    if(itemIndex != INVALID_STRING_INDEX)
    {
        return itemIndex;
    }

    // Return on the unsuccess
    return 0;
}