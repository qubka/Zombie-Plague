/**
 * =============================================================================
 * Zombie Plague 8.x Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin).
 * =============================================================================
 *
 * This file is part of the Zombie Plague Core.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 **/

#if defined _zombieplaguemod_included
 #endinput
#endif
#define _zombieplaguemod_included

/**
 * Lenth of usual strings.
 **/
#define SMALL_LINE_LENGTH     32
#define NORMAL_LINE_LENGTH     64
#define BIG_LINE_LENGTH     128

/**
 * Number of player's classes.
 **/
enum ZPClassType
{
    TYPE_ZOMBIE,            /**< Make a zombie */
    TYPE_NEMESIS,           /**< Make a nemesis */
    TYPE_SURVIVOR,          /**< Make a survivor */
    TYPE_HUMAN              /**< Make a human */
};

/**
 * Number of options.
 **/
enum ZPSelectType
{
    NO,                
    YES
};


#include "zombieplague/menus.inc"
#include "zombieplague/weapons.inc"
#include "zombieplague/costumes.inc"
#include "zombieplague/gamemodes.inc"
#include "zombieplague/hitgroups.inc"
#include "zombieplague/extraitems.inc"
#include "zombieplague/humanclasses.inc" 
#include "zombieplague/zombieclasses.inc"


//*********************************************************************
//*                       CORE MAIN FORWARDS                              *
//*********************************************************************

/**
 * @brief Called when a client became a zombie/nemesis.
 * 
 * @param clientIndex        The client index.
 * @param attackerIndex      The attacker index.
 *
 * @noreturn
 **/
forward void ZP_OnClientInfected(int clientIndex, int attackerIndex);

/**
 * @brief Called when a client became a human/survivor.
 * 
 * @param clientIndex        The client index.
 *
 * @noreturn
 **/
forward void ZP_OnClientHumanized(int clientIndex);

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param clientIndex        The client index.
 * @param attackerIndex      The attacker index.
 * @param damageAmount       The amount of damage inflicted.
 * @param damageType         The ditfield of damage types
 *
 * @noreturn
 **/
forward void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount, int damageType);

/**
 * @brief Called when a client use a zombie skill.
 * 
 * @param clientIndex        The client index.
 *
 * @return                   Plugin_Handled or Plugin_Stop to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
forward Action ZP_OnClientSkillUsed(int clientIndex);

/**
 * @brief Called when a zombie skill duration is over.
 * 
 * @param clientIndex        The client index.
 *
 * @noreturn
 **/
forward void ZP_OnClientSkillOver(int clientIndex);

/**
 * @brief Called after a zombie round is started.
 *
 * @param modeIndex         The mode index. 
 *
 * @noreturn
 **/
forward void ZP_OnZombieModStarted(int modeIndex);

/**
 * @brief Called after a zombie core is loaded.
 *
 * @noreturn
 **/
forward void ZP_OnEngineExecute(/*void*/);

//*********************************************************************
//*                       CORE MAIN NATIVES                              *
//*********************************************************************

/**
 * Returns whether a player is allowed to do a certain operation or not.
 *
 * @param clientIndex        The client index.
 * @param flag               The access flag. See enum AdminFlag.
 *  
 * @return                   True or false.
 **/
native bool ZP_IsPlayerPrivileged(int clientIndex, AdminFlag flag);

/**
 * @brief Returns true if the player is a zombie, false if not. 
 *
 * @param clientIndex        The client index.
 *  
 * @return                   True or false.
 **/
native bool ZP_IsPlayerZombie(int clientIndex);

/**
 * @brief Returns true if the player is a human, false if not.
 *
 * @param clientIndex        The client index.
 *  
 * @return                   True or false.
 **/
native bool ZP_IsPlayerHuman(int clientIndex);

/**
 * @brief Returns true if the player is a nemesis, false if not. (In addition, Nemesis always have ZP_IsPlayerZombie() native)
 *
 * @param clientIndex        The client index.
 *  
 * @return                   True or false.
 **/
native bool ZP_IsPlayerNemesis(int clientIndex);

/**
 * @brief Returns true if the player is a survivor, false if not.
 *
 * @param clientIndex        The client index.
 *  
 * @return                   True or false.
 **/
native bool ZP_IsPlayerSurvivor(int clientIndex);

/**
 * @brief Returns true if the player use a zombie skill, false if not. 
 *
 * @param clientIndex        The client index.
 *  
 * @return                   True or false.
 **/
native bool ZP_IsPlayerUseZombieSkill(int clientIndex);

/**
 * @brief Force to respawn a player.
 *
 * @param clientIndex        The client index.
 *  
 * @noreturn
 **/
native void ZP_ForceClientRespawn(int clientIndex);

/**
 * @brief Force to switch a player's class.
 *
 * @param clientIndex        The client index.
 * @param attackerIndex      (Optional) The attacker index.
 * @param typeIndex          The class type. See enum ZPClassType.
 *  
 * @noreturn
 **/
native void ZP_SwitchClientClass(int clientIndex, int attackerIndex = 0, ZPClassType typeIndex);

/**
 * @brief Gets the player's amount of ammopacks.
 *
 * @param clientIndex        The client index.
 *  
 * @return                   The number of ammopacks.
 **/
native int ZP_GetClientAmmoPack(int clientIndex);

/**
 * @brief Sets the player's amount of ammopacks.
 *
 * @param clientIndex        The client index.
 * @param amountAmmo         The number of ammopacks.
 *  
 * @noreturn
 **/
native void ZP_SetClientAmmoPack(int clientIndex, int amountAmmo);

/**
 * @brief Gets the player's amount of previous ammopacks spended.
 *
 * @param clientIndex        The client index.
 *  
 * @return                   The number of ammopacks.
 **/
native int ZP_GetClientLastBought(int clientIndex);

/**
 * @brief Sets the player's amount of ammopacks spending.
 *
 * @param clientIndex        The client index.
 * @param amountAmmo         The number of ammopacks.
 *  
 * @noreturn
 **/
native void ZP_SetClientLastBought(int clientIndex, int amountAmmo);

/**
 * @brief Gets the player's level.
 *
 * @param clientIndex        The client index.
 *  
 * @return                   The number of level.
 **/
native int ZP_GetClientLevel(int clientIndex);

/**
 * @brief Sets the player's level.
 *
 * @param clientIndex        The client index.
 * @param amountLevel        The number of level.
 *  
 * @noreturn
 **/
native int ZP_SetClientLevel(int clientIndex, int amountLevel);

/**
 * @brief Gets the player's exp.
 *
 * @param clientIndex        The client index.
 *  
 * @return                   The number of exp.
 **/
native int ZP_GetClientExp(int clientIndex);

/**
 * @brief Sets the player's exp.
 *
 * @param clientIndex        The client index.
 * @param amountExp          The number of exp.
 *  
 * @return                   True if the sound was emit, false otherwise.
 **/
native int ZP_SetClientExp(int clientIndex, int amountExp);

//*********************************************************************
//*                       CORE USEFUL NATIVES                              *
//*********************************************************************

/**
 * Emits random sound from a block from 'sounds.ini' config.
 *
 * @param sKey                The key to search for sound ID.
 * @param clientIndex         (Optional) The client index.
 *  
 * @noreturn
 **/
native bool ZP_EmitSound(char[] sKey, int clientIndex = 0);

/**
 * Gets the new round's state.
 *
 * @return                  True or false.
 **/
native bool ZP_IsNewRound();

/**
 * Gets the end round's state.
 *
 * @return                  True or false.
**/
native bool ZP_IsEndRound();

/**
 * Gets the new round's state.
 *
 * @return                  True or false.
 **/
native bool ZP_IsStartedRound();

/**
 * Gets the number of round.
 *
 * @return                  The round counter.
 **/
native int ZP_GetNumberRound();

/**
 * @brief Gets amount of total humans.
 * 
 * @return                  The amount of total humans.
 **/
native int ZP_GetHumanAmount();

/**
 * @brief Gets amount of total zombies.
 *
 * @return                  The amount of total zombies.
 **/
native int ZP_GetZombieAmount();

/**
 * @brief Gets amount of total alive players.
 *
 * @return                  The amount of total alive players.
 **/
native int ZP_GetAliveAmount();

/**
 * @brief Gets amount of total playing players.
 *
 * @return                   The amount of total playing players.
 **/
native int ZP_GetPlayingAmount();

/**
 * @brief Gets index of the random human.
 *
 * @return                  The index of random human.
 **/
native int ZP_GetRandomHuman();

/**
 * @brief Gets index of the random zombie.
 *
 * @return                  The index of random zombie.
 **/
native int ZP_GetRandomZombie();

/**
 * @brief Gets index of the random survivor.
 *
 * @return                  The index of random survivor.
 **/
native int ZP_GetRandomSurvivor();

/**
 * @brief Gets index of the random nemesis.
 *
 * @return                  The index of random nemesis.
 **/
native int ZP_GetRandomNemesis();

//*********************************************************************
//*                       OTHER USEFUL STOCKS                              *
//*********************************************************************

/**
 * @brief Returns true if the player is connected and alive, false if not.
 *
 * @param clientIndex       The client index.
 * @param aliveness         (Optional) Set to true to validate that the client is alive, false to ignore.
 *  
 * @return                    True or false.
 **/
stock bool IsPlayerExist(const int clientIndex, const bool aliveness = true)
{
    // If client isn't valid
    if(clientIndex <= 0 || clientIndex > MaxClients)
    {
        return false;
    }

    // If client isn't connected
    if(!IsClientConnected(clientIndex))
    {
        return false;
    }

    // If client isn't in game
    if(!IsClientInGame(clientIndex) || IsClientInKickQueue(clientIndex))
    {
        return false;
    }

    // If client is TV
    if(IsClientSourceTV(clientIndex))
    {
        return false;
    }

    // If client isn't alive
    if(aliveness && !IsPlayerAlive(clientIndex))
    {
        return false;
    }

    // If client exist
    return true;
}

/**
 * Create a particle entity.
 * 
 * @param parentIndex       The client index.
 * @param sAttach           (Optional) The attachment bone of the entity parent.
 * @param sType             The type of the particle.
 * @param flDurationTime    The duration of light.
 * @return                  The entity index.
 **/
stock int FakeCreateParticle(const int parentIndex, const char[] sAttach = "", const char[] sType, const float flDurationTime)
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
        AcceptEntityInput(entityIndex, "SetParent", parentIndex, entityIndex);
        SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", parentIndex);
        
        // Sets attachment to the entity
        if(strlen(sAttach))
        { 
            SetVariantString(sAttach); 
            AcceptEntityInput(entityIndex, "SetParentAttachment", parentIndex, entityIndex);
        }
        else
        {
            // Initialize vector variables
            static float vOrigin[3];

            // Gets parent's position
            GetEntPropVector(parentIndex, Prop_Send, "m_vecOrigin", vOrigin);

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
 * @brief Create an fake entity.
 * 
 * @param vOrigin           The origin of the entity.
 * @param flDurationTime    The duration of life.
 * @return                  The entity index.
 **/
stock int FakeCreateEntity(const float vOrigin[3], const float flDurationTime)
{
    // Create an fake info entity
    int entityIndex = CreateEntityByName("info_target");

    // If entity isn't valid, then skip
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Spawn the entity
        DispatchKeyValueVector(entityIndex, "origin", vOrigin);

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
 * @brief Shake a client's screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param flAmplitude       The amplitude of shake.
 * @param flFrequency       The frequency of shake.
 * @param flDuration        The duration of shake in the seconds.
 **/
stock void FakeCreateShakeScreen(const int clientIndex, const float flAmplitude, const float flFrequency, const float flDuration)
{
    // Create message
    Handle hShake = StartMessageOne("Shake", clientIndex);

    // Validate message
    if(hShake != INVALID_HANDLE)
    {
        // Write shake information to message handle
        PbSetInt(hShake,   "command", 0);
        PbSetFloat(hShake, "local_amplitude", flAmplitude);
        PbSetFloat(hShake, "frequency", flFrequency);
        PbSetFloat(hShake, "duration", flDuration);

        // End usermsg and send to client
        EndMessage();
    }
}

/**
 * @brief Fade a client's screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param flDuration        The duration of fade in the seconds.
 * @param flHoldTime        The holding time of fade in the seconds.
 * @param iFlags            The flags.
 * @param vColor            The array with RGB color.
 **/
stock void FakeCreateFadeScreen(const int clientIndex, const float flDuration, const float flHoldTime, const int iFlags, const int vColor[4])
{
    // Create message
    Handle hFade = StartMessageOne("Fade", clientIndex);

    // Validate message
    if(hFade != INVALID_HANDLE)
    {
        // Write shake information to message handle
        PbSetInt(hFade, "duration", RoundToNearest(flDuration * 1000.0)); 
        PbSetInt(hFade, "hold_time", RoundToNearest(flHoldTime * 1000.0)); 
        PbSetInt(hFade, "flags", iFlags); 
        PbSetColor(hFade, "clr", vColor); 

        // End usermsg and send to client
        EndMessage();
    }
}
