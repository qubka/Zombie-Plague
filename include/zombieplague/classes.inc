/**
 * =============================================================================
 * Zombie Plague Copyright (C) 2015-2023 qubka (Nikita Ushakov).
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

#if defined _classes_included
 #endinput
#endif
#define _classes_included

/**
 * @section Number of valid bonuses.
 **/
enum BonusType
{
	BonusType_Invalid = -1,       /** Used as return value when a bonus doens't exist. */
	
	BonusType_Kill,               /** Kill bonus */
	BonusType_Damage,             /** Damage bonus */
	BonusType_Infect,             /** Infect or humanize bonus */  
	BonusType_Win,                /** Win bonus */ 
	BonusType_Lose,               /** Lose bonus */    
	BonusType_Draw                /** Draw bonus */ 
};
/**
 * @endsection
 **/

#include "zombieplague/classes/account.inc"
#include "zombieplague/classes/skillsystem.inc"
#include "zombieplague/classes/levelsystem.inc" 
 
/**
 * @brief Called when a client became/spawn a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 *
 * @noreturn
 **/
forward void ZP_OnClientUpdated(int client, int attacker); 

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 *
 * @noreturn
 **/
forward void ZP_OnClientDeath(int client, int attacker);

/**
 * @brief Called right before a client is about to respawn.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block respawn. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
forward Action ZP_OnClientRespawn(int client);
 
/**
 * @brief Called before show a class in the class menu.
 * 
 * @param client            The client index.
 * @param classID           The class index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
forward Action ZP_OnClientValidateClass(int client, int classID);

/**
 * @brief Infect/humanize a player.
 *
 * @param client            The client index.
 * @param attacker          (Optional) The attacker index. (0 = world, -1 = respawn)
 * @param type              (Optional) The class type. (-2 = zombie, -3 = human)
 *  
 * @return                  True or false.
 **/
native bool ZP_ChangeClient(int client, int attacker = 0, int type = -2);

/**
 * @brief Gets the amount of all classes.
 *
 * @return                  The class amount.    
 **/
native int ZP_GetNumberClass();

/**
 * @brief Gets the current class index of the client.
 * 
 * @param client            The client index.
 *
 * @return                  The class index.    
 **/
native int ZP_GetClientClass(int client);

/**
 * @brief Gets the human next class index of the client.
 * 
 * @param client            The client index.
 *
 * @return                  The class index.    
 **/
native int ZP_GetClientHumanClassNext(int client);

/**
 * @brief Gets the zombie next class index of the client.
 * 
 * @param client            The client index.
 *
 * @return                  The class index.    
 **/
native int ZP_GetClientZombieClassNext(int client);

/**
 * @brief Sets the human next class index to the client.
 * 
 * @param client            The client index.
 * @param classID           The class index.    
 **/
native void ZP_SetClientHumanClassNext(int client, int classID);

/**
 * @brief Sets the zombie next class index to the client.
 * 
 * @param client            The client index.
 * @param classID           The class index.    
 **/
native void ZP_SetClientZombieClassNext(int client, int classID);

/**
 * @brief Gets the random index of a class at a given type.
 * 
 * @param type              The class type.
 *
 * @return                  The class index, or -1 on failure.
 *
 * @note                    Can return a random index for multiple same unique types!
 **/
native int ZP_GetRandomClassTypeID(int type);

/**
 * @brief Gets the index of a class at a given name.
 * 
 * @param name              The class name.
 *
 * @return                  The class index, or -1 on failure.
 **/
native int ZP_GetClassNameID(const char[] name);

/**
 * @brief Gets the name of a class at a given index.
 *
 * @param classID           The class index.
 * @param name              The string to return name in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassName(int classID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the info of a class at a given index.
 *
 * @param classID           The class index.
 * @param info              The string to return info in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassInfo(int classID, char[] info, int maxlenght = 32);

/**
 * @brief Gets the index of a type at a given name.
 * 
 * @param name              The type name.
 *
 * @return                  The type index, or -1 on failure.
 **/
native int ZP_GetClassTypeID(const char[] name);

/**
 * @brief Gets the type of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The type index.    
 **/
native int ZP_GetClassType(int classID);

/**
 * @brief Checks the zombie type of the class.
 *
 * @param classID           The class index.
 *
 * @return                  True or false. 
**/
native bool ZP_IsClassZombie(int classID);

/**
 * @brief Gets the player model of a class at a given index.
 *
 * @param classID           The class index.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassModel(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the knife model of a class at a given index.
 *
 * @param classID           The class index.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassClaw(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the grenade model of a class at a given index.
 *
 * @param classID           The class index.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassGrenade(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the arm model of a human class at a given index.
 *
 * @param classID           The class index.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassArm(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the body index of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The body index.  
 **/
native int ZP_GetClassBody(int classID);

/**
 * @brief Gets the skin index of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The skin index.  
 **/
native int ZP_GetClassSkin(int classID);

/**
 * @brief Gets the health of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The health amount.    
 **/
native int ZP_GetClassHealth(int classID);

/**
 * @brief Gets the speed of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The speed amount.    
 **/
native float ZP_GetClassSpeed(int classID);

/**
 * @brief Gets the gravity of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The gravity amount.    
 **/
native float ZP_GetClassGravity(int classID);

/**
 * @brief Gets the knockback of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The knockback amount.    
 **/
native float ZP_GetClassKnockBack(int classID);

/**
 * @brief Gets the armor of the human class.
 *
 * @param classID           The class index.
 *
 * @return                  The armor amount.    
 **/
native int ZP_GetClassArmor(int classID);

/**
 * @brief Gets the level of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The level amount.    
 **/
native int ZP_GetClassLevel(int classID);

/**
 * @brief Gets the group of a class at a given index.
 *
 * @param classID           The class index.
 * @param group             The string to return group in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassGroup(int classID, char[] group, int maxlenght = 32);

/**
 * @brief Gets the group flags of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The flags bits.    
 **/
native int ZP_GetClassGroupFlags(int classID);

/**
 * @brief Gets the skill duration of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The duration amount.    
 **/
native float ZP_GetClassSkillDuration(int classID);

/**
 * @brief Gets the skill countdown of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The countdown amount.    
 **/
native float ZP_GetClassSkillCountdown(int classID);

/**
 * @brief Gets the skill cost of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The cost amount.    
 **/
native int ZP_GetClassSkillCost(int classID);

/**
 * @brief Checks the skill bar of the class.
 *
 * @param classID           The class index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsClassSkillBar(int classID);

/**
 * @brief Checks the health sprite of the class.
 *
 * @param classID           The class index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsClassHealthSprite(int classID);

/**
 * @brief Gets the regen health of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The regen amount.    
 **/
native int ZP_GetClassRegenHealth(int classID);

/**
 * @brief Gets the regen interval of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The regen interval amount.    
 **/
native float ZP_GetClassRegenInterval(int classID);

/**
 * @brief Checks the fall state of the class.
 *
 * @param classID           The class index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsClassFall(int classID);

/**
 * @brief Checks the spot state of the class.
 *
 * @param classID           The class index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsClassSpot(int classID);

/**
 * @brief Gets the fov of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The fov amount. 
 **/
native int ZP_GetClassFov(int classID);

/**
 * @brief Checks the crosshair of the class.
 *
 * @param classID           The class index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsClassCross(int classID);

/**
 * @brief Checks the nightvision of the class.
 *
 * @param classID           The class index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsClassNvgs(int classID);

/**
 * @brief Gets the overlay of a class at a given index.
 *
 * @param classID           The class index.
 * @param overlay           The string to return overlay in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassOverlay(int classID, char[] overlay, int maxlenght = 256);

/**
 * @brief Gets the weapon of a class at a given index.
 *
 * @param classID           The class index.
 * @param weapon            The array to return weapon in.
 * @param maxlenght         The lenght of array.
 **/
native void ZP_GetClassWeapon(int classID, int[] weapon, int maxlenght = 16);

/**
 * @brief Gets the money of a class.
 *
 * @param classID           The class index.
 * @param model             The model type.
 *
 * @return                  The money amount. 
 **/
native int ZP_GetClassMoney(int classID, BonusType bonus);

/**
 * @brief Gets the experience of a class.
 *
 * @param classID           The class index.
 * @param experience        The array to return experience in.
 * @param maxlenght         The lenght of array.
 *
 * @return                  The experience amount. 
 **/
native int ZP_GetClassExperience(int classID, BonusType bonus);

/**
 * @brief Gets the lifesteal of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The steal amount.    
 **/
native int ZP_GetClassLifeSteal(int classID);

/**
 * @brief Gets the ammunition of the human class.
 *
 * @param classID           The class index.
 *
 * @return                  The ammunition type.    
 **/
native int ZP_GetClassAmmunition(int classID);

/**
 * @brief Gets the leap jump of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The leap jump.    
 **/
native int ZP_GetClassLeapJump(int classID);

/**
 * @brief Gets the leap force of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The leap force.    
 **/
native float ZP_GetClassLeapForce(int classID);

/**
 * @brief Gets the leap countdown of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The leap countdown.    
 **/
native float ZP_GetClassLeapCountdown(int classID);

/**
 * @brief Gets the effect name of a class at a given index.
 *
 * @param classID           The class index.
 * @param name              The string to return name in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassEffectName(int classID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the effect attachment of a class at a given index.
 *
 * @param classID           The class index.
 * @param attach            The string to return attach in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetClassEffectAttach(int classID, char[] attach, int maxlenght = 32);

/**
 * @brief Gets the effect time of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The effect time.    
 **/
native float ZP_GetClassEffectTime(int classID);

/**
 * @brief Gets the index of the class claw model.
 *
 * @param classID           The class index.
 *
 * @return                  The model index.    
 **/
native int ZP_GetClassClawID(int classID);

/**
 * @brief Gets the index of the class grenade model.
 *
 * @param classID           The class index.
 *
 * @return                  The model index.    
 **/
native int ZP_GetClassGrenadeID(int classID);

/**
 * @brief Gets the death sound key of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.   
 **/
native int ZP_GetClassSoundDeathID(int classID);

/**
 * @brief Gets the hurt sound key of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.   
 **/
native int ZP_GetClassSoundHurtID(int classID);

/**
 * @brief Gets the idle sound key of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.   
 **/
native int ZP_GetClassSoundIdleID(int classID);

/**
 * @brief Gets the infect sound key of the human class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.
 **/
native int ZP_GetClassSoundInfectID(int classID);

/**
 * @brief Gets the respawn sound key of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.   
 **/
native int ZP_GetClassSoundRespawnID(int classID);

/**
 * @brief Gets the burn sound key of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.   
 **/
native int ZP_GetClassSoundBurnID(int classID);

/**
 * @brief Gets the footstep sound key of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.   
 **/
native int ZP_GetClassSoundFootID(int classID);

/**
 * @brief Gets the regeneration sound key of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.   
 **/
native int ZP_GetClassSoundRegenID(int classID);

/**
 * @brief Gets the leap jump sound key of the class.
 *
 * @param classID           The class index.
 *
 * @return                  The key id.   
 **/
native int ZP_GetClassSoundJumpID(int classID);


/**
 * @brief Return true if type flag bit set.
 * 
 * @param iTypes            The class types.
 * @param iType             The class type.
 **/
stock bool ZP_ClassHasTypeBits(int iTypes, int iType)
{
	return (!iTypes || CheckBit(iTypes, iType));
}

/**
 * @brief Gets the current team index of the player.
 *
 * @param client            The client index.
 * @return                  The team index.
 **/
stock int ZP_GetPlayerTeam(int client)
{
	return ZP_IsPlayerHuman(client) ? TEAM_HUMAN : TEAM_ZOMBIE;
}

/**
 * @brief Sets the player animating event.
 *
 * @param client            The client index.
 * @param event             The event type.
 * @param data              The activity index.
 *
 * @noreturn
 **/
stock void ZP_SetPlayerAnimation(int client, PlayerAnimEvent event, int data = 0)
{
	TE_Start("PlayerAnimEvent");
	TE_WriteNum("m_hPlayer", EntIndexToEntRef(client) & 0x7FFF);
	TE_WriteNum("m_iEvent", view_as<int>(event));
	TE_WriteNum("m_nData", data);
	TE_SendToAll();
}