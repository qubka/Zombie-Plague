/**
 * =============================================================================
 * Zombie Plague X Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin).
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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
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

#if !defined _sdkhooks_included
  #include <sdkhooks>
#endif

//*********************************************************************
//*                       CORE MAIN FORWARDS                          *
//*********************************************************************

/**
 * @brief Called after a core is loaded.
 *
 * @noreturn
 **/
forward void ZP_OnEngineExecute(/*void*/);

//*********************************************************************
//*                       CORE MAIN NATIVES                           *
//*********************************************************************

/**
 * Validate the attachment on the entity.
 *
 * @param entityIndex       The entity index.
 * @param attach            The attachment name.
 *
 * @return                  True or false.
 **/
native bool ZP_LookupAttachment(int entityIndex, char[] attach);

/**
 * Gets the attachment of the entity.
 *
 * @param entityIndex       The entity index.
 * @param attach            The attachment name.
 * @param origin            The origin output.
 * @param angle             The angle output.
 *
 * @noreturn
 **/
native void ZP_GetAttachment(int entityIndex, char[] attach, float origin[3], float angles[3]);

/**
 * @brief Gets the sequence of the entity.
 *
 * @param entityIndex       The entity index.
 * @param anim              The sequence name. (activity name)
 *
 * @return                  The sequence index.
 **/
native int ZP_LookupSequence(int entityIndex, char[] anim);

/**
 * @brief Gets the pose of the entity.
 *
 * @param entityIndex       The entity index.
 * @param pose              The pose name.
 *
 * @return                  The pose parameter.
 **/
native int ZP_LookupPoseParameter(int entityIndex, char[] pose);

/**
 * @brief Resets the sequence of the entity.
 *
 * @param entityIndex       The entity index.
 * @param anim              The sequence name.
 *
 * @noreturn
 **/
native void ZP_ResetSequence(int entityIndex, char[] anim);

/**
 * @brief Gets the total sequence amount.
 *
 * @param entityIndex       The entity index.
 *
 * @return                  The sequence count.
 **/
native int ZP_GetSequenceCount(int entityIndex);

/**
 * @brief Gets the duration of a sequence.
 *
 * @param entityIndex       The entity index.
 * @param sequence          The sequence index.
 *
 * @return                  The sequence duration. 
 **/
native float ZP_GetSequenceDuration(int entityIndex, int sequence);

/**
 * @brief Gets the activity of a sequence.
 *
 * @param entityIndex       The entity index.
 * @param sequence          The sequence index.
 *
 * @return                  The activity index.
 **/
native int ZP_GetSequenceActivity(int entityIndex, int sequence);

/**
 * @brief Checks that the entity is a brush.
 *
 * @param entityIndex       The entity index.
 *  
 * @return                  True or false.
 **/
native bool ZP_IsBSPModel(int clientIndex);

/**
 * @brief Respawn a player.
 *
 * @param clientIndex       The client index.
 *  
 * @return                  True or false.
**/
native bool ZP_RespawnClient(int clientIndex);

/**
 * @brief Used to iterate all the clients collision within a sphere.
 *
 * @param it                The iterator.
 * @param center            The sphere origin.
 * @param radius            The sphere radius.
 *  
 * @return                  The client index.
 **/
native int ZP_FindPlayerInSphere(int &it, float center[3], float radius);

/**
 * @brief Emulate 'bullet_shot' on the server and does the damage calculations.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param origin            The position to the spawn.
 * @param angle             The angle to the spawn.
 * @param mode              The mode index.
 * @param seed              The randomizing seed.
 * @param inaccuracy        The inaccuracy variable.
 * @param spread            The spread variable.
 * @param sound             The sound type.
 *
 * @return                  True or false.
 **/
native bool ZP_FireBullets(int clientIndex, int weaponIndex, float origin[3], float angle[3], int mode, int seed, float inaccuracy, float spread, int sound);

/**
 * @brief Returns whether a player is in group or not.
 *
 * @param clientIndex       The client index.
 * @param group             The group name.
 *  
 * @return                  True or false.
 **/
native bool ZP_IsPlayerInGroup(int clientIndex, char[] group);

/**
 * @brief Returns true if the player is a zombie, false if not. 
 *
 * @param clientIndex       The client index.
 *  
 * @return                  True or false.
 **/
native bool ZP_IsPlayerZombie(int clientIndex);

/**
 * @brief Returns true if the player is a human, false if not.
 *
 * @param clientIndex       The client index.
 *  
 * @return                  True or false.
 **/
native bool ZP_IsPlayerHuman(int clientIndex);

/**
 * @brief Gets the last player disconnected time.
 *
 * @param clientIndex       The client index.
 *  
 * @return                  The 32bit timestamp. (Number of seconds since unix epoch)
 **/
native int ZP_GetClientTime(int clientIndex);

//*********************************************************************
//*                       CORE USEFUL NATIVES                         *
//*********************************************************************

/**
 * @brief Gets the new round state.
 *
 * @return                  True or false.
 **/
native bool ZP_IsNewRound();

/**
 * @brief Gets the end round state.
 *
 * @return                  True or false.
**/
native bool ZP_IsEndRound();

/**
 * @brief Gets the new round state.
 *
 * @return                  True or false.
 **/
native bool ZP_IsStartedRound();

/**
 * @brief Gets the number of round.
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

#if !defined _utils_included
    #include <utils>
#endif

/** Load other libraries **/
#include "zombieplague/menus.inc"
#include "zombieplague/sounds.inc"
#include "zombieplague/weapons.inc"
#include "zombieplague/classes.inc"
#include "zombieplague/costumes.inc"
#include "zombieplague/gamemodes.inc"
#include "zombieplague/hitgroups.inc"
#include "zombieplague/extraitems.inc" 