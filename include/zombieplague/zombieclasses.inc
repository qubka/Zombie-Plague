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

#if defined _zombieclasses_included
 #endinput
#endif
#define _zombieclasses_included

/**
 * @brief Called before show a zombie class in the zombie class menu.
 * 
 * @param clientIndex       The client index.
 * @param classID           The index of class from ZP_RegisterZombieClass() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
forward Action ZP_OnClientValidateZombieClass(int clientIndex, int classID);

/**
 * @brief Gets the amount of all zombie classes.
 *
 * @return                  The zombie class amount.    
 */
native int ZP_GetNumberZombieClass();

/**
 * @brief Gets the zombie class index of the client.
 * 
 * @param clientIndex       The client index.
 * @return                  The zombie class index.    
 */
native int ZP_GetClientZombieClass(int clientIndex);

/**
 * @brief Gets the zombie next class index of the client.
 * 
 * @param clientIndex       The client index.
 * @return                  The zombie class index.    
 */
native int ZP_GetClientZombieClassNext(int clientIndex);

/**
 * @brief Sets the zombie class index to the client.
 * 
 * @param clientIndex       The client index.
 * @param classID           The zombie class index.    
 */
native void ZP_SetClientZombieClass(int clientIndex, int classID);

/**
 * @brief Registers a custom class which will be added to the zombie classes menu of ZP.
 *
 *     Note: The returned zombie class index can be later used to identify
 *             the class when calling the ZP_GetClientZombieClass() natives.
 *
 * @param name              Caption to display on the menu. (Only will be taken from translation file)
 * @param info              Caption to display in the hint. (""-off) (Only will be taken from translation file)
 * @param model             Player model to be used.
 * @param claw_model        Knife model to be used.
 * @param gren_model        Grenade model to be used.
 * @param health            Initial health points.
 * @param speed             Maximum speed.
 * @param gravity           Gravity multiplier.
 * @param knockback         Knockback multiplier.
 * @param level             Level required to select class.
 * @param vip               Class access only for VIP players.
 * @param duration          Duration of skill, for your custom addons. (0.0-off)
 * @param countdown         Countdown of skill, for your custom addons. (0.0-off)
 * @param regenhealth       Regenerating health. (0-off)
 * @param regeninterval     Regenerating health's interval. (0.0-off)
 * @param death             Emits death sound from a block from 'sounds.ini' config.
 * @param hurt              Emits hurt sound from a block from 'sounds.ini' config.
 * @param idle              Emits idle sound from a block from 'sounds.ini' config.
 * @param respawn           Emits respawn sound from a block from 'sounds.ini' config.
 * @param burn              Emits burn sound from a block from 'sounds.ini' config.
 * @param attack            Emits attack sound from a block from 'sounds.ini' config.
 * @param footstep          Emits footstep sound from a block from 'sounds.ini' config.
 * @param regen             Emits regen sound from a block from 'sounds.ini' config.
 *
 *     Note: The duration and countdown must be turn off together,
 *             for disabling skill usage.
 *
 * @return                  An internal zombie class index, or -1 on failure.
 **/
native int ZP_RegisterZombieClass(char[] name, char[] info, char[] model, char[] claw_model, char[] gren_model, int health = 100, float speed = 1.0, float gravity = 1.0, float knockback = 1.0, int level = 1, ZPSelectType vip = NO, float duration = 0.0, float countdown = 0.0, int regenhealth = 0, float regeninterval = 0.0, char[] death = "", char[] hurt = "", char[] idle = "", char[] respawn = "", char[] burn = "", char[] attack = "", char[] footstep = "", char[] regen = "");

/**
 * @brief Gets the name of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param name              The string to return name in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassName(int classID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the info of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param info              The string to return info in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassInfo(int classID, char[] info, int maxlenght = 32);

/**
 * @brief Gets the player model of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassModel(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the knife model of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassClaw(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the grenade model of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassGrenade(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the health of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The health amount.    
 **/
native int ZP_GetZombieClassHealth(int classID);

/**
 * @brief Gets the speed of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The speed amount.    
 **/
native float ZP_GetZombieClassSpeed(int classID);

/**
 * @brief Gets the gravity of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The gravity amount.    
 **/
native float ZP_GetZombieClassGravity(int classID);

/**
 * @brief Gets the knockback of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The knockback amount.    
 **/
native float ZP_GetZombieClassKnockBack(int classID);

/**
 * @brief Gets the level of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The level amount.    
 **/
native int ZP_GetZombieClassLevel(int classID);

/**
 * @brief Check the access of the zombie class.
 *
 * @param classID           The class index.
 * @return                  True or false.
 **/
native bool ZP_IsZombieClassVIP(int classID);

/**
 * @brief Gets the skill duration of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The duration amount.    
 **/
native float ZP_GetZombieClassSkillDuration(int classID);

/**
 * @brief Gets the skill countdown of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The countdown amount.    
 **/
native float ZP_GetZombieClassSkillCountdown(int classID);

/**
 * @brief Gets the regen of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The regen amount.    
 **/
native int ZP_GetZombieClassRegen(int classID);

/**
 * @brief Gets the regen interval of the zombie class.
 *
 * @param classID           The class index.
 * @return                  The regen interval amount.    
 **/
native float ZP_GetZombieClassRegenInterval(int classID);

/**
 * @brief Gets the index of the zombie class claw model.
 *
 * @param classID           The class index.
 * @return                  The model index.    
 **/
native int ZP_GetZombieClassClawID(int classID);

/**
 * @brief Gets the index of the zombie class grenade model.
 *
 * @param classID           The class index.
 * @return                  The model index.    
 **/
native int ZP_GetZombieClassGrenadeID(int classID);

/**
 * @brief Gets the death sound of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassSoundDeath(int classID, char[] sound, int maxlenght = 32);

/**
 * @brief Gets the hurt sound of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassSoundHurt(int classID, char[] sound, int maxlenght = 32);

/**
 * @brief Gets the idle sound of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassSoundIdle(int classID, char[] sound, int maxlenght = 32);

/**
 * @brief Gets the respawn sound of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassSoundRespawn(int classID, char[] sound, int maxlenght = 32);

/**
 * @brief Gets the burn sound of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassSoundBurn(int classID, char[] sound, int maxlenght = 32);

/**
 * @brief Gets the attack sound of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassSoundAttack(int classID, char[] sound, int maxlenght = 32);

/**
 * @brief Gets the footstep sound of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassSoundFoot(int classID, char[] sound, int maxlenght = 32);

/**
 * @brief Gets the regeneration sound of a zombie class at a given index.
 *
 * @param classID           The class index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetZombieClassSoundRegen(int classID, char[] sound, int maxlenght = 32);

/**
 * @brief Print the info about the zombie class.
 * 
 * @param clientIndex        The client index.
 * @param classID            The zombie class index.    
 */
native void ZP_PrintZombieClassInfo(int clientIndex, int classID);
