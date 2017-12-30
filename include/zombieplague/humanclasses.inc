/**
 * =============================================================================
 * Zombie Plague 7.x Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin).
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

#if defined _humanclasses_included
 #endinput
#endif
#define _humanclasses_included

/**
 * @brief Gets the amount of all human classes.
 *
 * @return          		The human class amount.	
 */
native int ZP_GetNumberHumanClass();

/**
 * @brief Gets the human class index of the client.
 * 
 * @param clientIndex		The client index.
 * @return          		The human class index.	
 */
native int ZP_GetClientHumanClass(int clientIndex);

/**
 * @brief Gets the human next class index of the client.
 * 
 * @param clientIndex		The client index.
 * @return          		The human class index.	
 */
native int ZP_GetClientHumanClassNext(int clientIndex);

/**
 * @brief Sets the human class index to the client.
 * 
 * @param clientIndex		The client index.
 * @param classID       	The human class index.	
 */
native void ZP_SetClientHumanClass(int clientIndex, int classID);

/**
 * @brief Registers a custom class which will be added to the human classes menu of ZP.
 *
 * 	Note: The returned human class ID can be later used to identify
 * 			the class when calling the ZP_GetClientHumanClass() natives.
 *
 * @param name				Caption to display on the menu.
 * @param model				Player model to be used.
 * @param arm_model			Arm model to be used.
 * @param health			Initial health points.
 * @param speed				Maximum speed.
 * @param gravity			Gravity multiplier.
 * @param armor				Armor on the spawn. (100-maximum)
 * @param level 			Level required to select class
 * @param female			Will be a female.
 * @param vip				Will available only for VIP.
 *
 * 	Note: The duration and countdown must be turn off together,
 *	 		for disabling skill usage.
 *
 * @return					An internal human class ID, or -1 on failure.
 **/
native int ZP_RegisterHumanClass(char[] name, char[] model, char[] arm_model, int health, float speed, float gravity, int armor, int level, ZPSelectType female = NO, ZPSelectType vip = NO);

/**
 * @brief Gets the name of a human class at a given index.
 *
 * @param classID     	 	The class index.
 * @param name     			The string to return name in.
 * @param maxlenght			The lenght of string.
 **/
native void ZP_GetHumanClassName(int classID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the player model of a human class at a given index.
 *
 * @param classID     	 	The class index.
 * @param model      		The string to return model in.
 * @param maxlenght			The lenght of string.
 **/
native void ZP_GetHumanClassModel(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the arm model of a human class at a given index.
 *
 * @param classID     	 	The class index.
 * @param model      		The string to return model in.
 * @param maxlenght			The lenght of string.
 **/
native void ZP_GetHumanClassArm(int classID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the health of the human class.
 *
 * @param classID        	The class index.
 * @return          		The health amount.	
 **/
native int ZP_GetHumanClassHealth(int classID);

/**
 * @brief Gets the speed of the human class.
 *
 * @param classID        	The class index.
 * @return          		The speed amount.	
 **/
native float ZP_GetHumanClassSpeed(int classID);

/**
 * @brief Gets the gravity of the human class.
 *
 * @param classID        	The class index.
 * @return          		The gravity amount.	
 **/
native float ZP_GetHumanClassGravity(int classID);

/**
 * @brief Gets the armor of the human class.
 *
 * @param classID        	The class index.
 * @return          		The armor amount.	
 **/
native int ZP_GetHumanClassArmor(int classID);

/**
 * @brief Gets the level of the human class.
 *
 * @param classID        	The class index.
 * @return          		The level amount.	
 **/
native int ZP_GetHumanClassLevel(int classID);

/**
 * @brief Check the gender of the human class.
 *
 * @param classID        	The class index.
 * @return          		True or false.
 **/
native bool ZP_IsHumanClassFemale(int classID);

/**
 * @brief Check the access of the human class.
 *
 * @param classID        	The class index.
 * @return          		True or false.
 **/
native bool ZP_IsHumanClassVIP(int classID);

/**
 * @brief Print the info about the human class.
 * 
 * @param clientIndex		The client index.
 * @param classID        	The human class index.	
 */
native void ZP_PrintHumanClassInfo(int clientIndex, int classID);