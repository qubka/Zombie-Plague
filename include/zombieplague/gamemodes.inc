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

#if defined _gamemodes_included
 #endinput
#endif
#define _gamemodes_included

/**
 * @brief Gets the current game mode.
 *
 * @return                  The mode index.    
 **/
native int ZP_GetCurrentGameMode();

/**
 * @brief Gets the last game mode.
 *
 * @return                  The mode index.    
 **/
native int ZP_GetLastGameMode();

/**
 * @brief Gets the amount of all game modes.
 *
 * @return                  The mode amount.    
 **/
native int ZP_GetNumberGameMode();

/**
 * @brief Start the game mode.
 * 
 * @param name              The mode index.
 * @param clientIndex       (Optional) The client index. (Which need to be infected/herozied, if value has 0, mode will be choose players itself)    
 **/
native void ZP_StartGameMode(int modeID, int clientIndex = 0);

/**
 * @brief Gets the index of a game mode at a given name.
 * 
 * @param name              The mode name.
 *
 * @return                  The mode index, or -1 on failure.
 **/
native int ZP_GetGameModeNameID(char[] name);

/**
 * @brief Gets the name of a game mode at a given index.
 *
 * @param modeID            The mode index.
 * @param name              The string to return name in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetGameModeName(int modeID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the description of a game mode at a given index.
 *
 * @param modeID            The mode index.
 * @param desc              The string to return desc in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetGameModeDesc(int modeID, char[] desc, int maxlenght = 32);

/**
 * @brief Gets the chance of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  The chance amount.    
 **/
native int ZP_GetGameModeChance(int modeID);

/**
 * @brief Gets the min players of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  The min players amount.    
 **/
native int ZP_GetGameModeMinPlayers(int modeID);

/**
 * @brief Gets the ratio of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  The ratio amount.    
 **/
native float ZP_GetGameModeRatio(int modeID);

/**
 * @brief Gets the start sound key of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The key id.
 **/
native int ZP_GetGameModeSoundStartID(int modeID);

/**
 * @brief Gets the ambient sound key of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The key id.
 **/
native int ZP_GetGameModeSoundAmbientID(int modeID);

/**
 * @brief Gets the ambient sound duration of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The duration amount.
 **/
native float ZP_GetGameModeSoundDuration(int modeID);

/**
 * @brief Gets the ambient sound volume of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The volume amount.
 **/
native float ZP_GetGameModeSoundVolume(int modeID);

/**
 * @brief Check the infection type of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  True or false.    
 **/
native bool ZP_IsGameModeInfect(int modeID);

/**
 * @brief Check the respawn type of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  True or false.    
 **/
native bool ZP_IsGameModeRespawn(int modeID);

/**
 * @brief Check the human class of the game mode.
 * 
 * @param modeID            The mode index.
 * @param class             The string to return class in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetGameModeHuman(int modeID, char[] class, int maxlenght = 32);

/**
 * @brief Check the zombie class of the game mode.
 * 
 * @param modeID            The mode index.
 * @param class             The string to return class in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetGameModeZombie(int modeID, char[] class, int maxlenght = 32);

/**
 * @brief Gets the deathmatch mode of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The deathmatch mode. 
 **/
native int ZP_GetGameModeMatch(int modeID);

/**
 * @brief Gets the amount of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The amount. 
 **/
native int ZP_GetGameModeAmount(int modeID);

/**
 * @brief Gets the delay of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The delay. 
 **/
native float ZP_GetGameModeDelay(int modeID);

/**
 * @brief Gets the last amount of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The last amount. 
 **/
native int ZP_GetGameModeLast(int modeID);

/**
 * @brief Check the suicide mode of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false.  
 **/
native bool ZP_IsGameModeSuicide(int modeID);

/**
 * @brief Check the escape mode of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false.  
 **/
native bool ZP_IsGameModeEscape(int modeID);

/**
 * @brief Check the xray access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeXRay(int modeID);

/**
 * @brief Check the regen access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeRegen(int modeID);

/**
 * @brief Check the skill access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeSkill(int modeID);

/**
 * @brief Check the leapjump access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeLeapJump(int modeID);

/**
 * @brief Check the weapon access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeWeapon(int modeID);

/**
 * @brief Check the extraitem access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeExtraItem(int modeID);