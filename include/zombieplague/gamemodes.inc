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

#if defined _gamemodes_included
 #endinput
#endif
#define _gamemodes_included

#include <cstrike>

/**
 * @brief Called after a round is started.
 *
 * @param mode              The mode index. 
 *
 * @noreturn
 **/
forward void ZP_OnGameModeStart(int mode);

/**
 * @brief Called after a round is ended.
 *
 * @param reason            The reason index. 
 *
 * @noreturn
 **/
forward void ZP_OnGameModeEnd(CSRoundEndReason reason);

/**
 * @brief Called before show a game mode in the modes menu.
 * 
 * @param client            The client index.
 * @param modeID            The mode index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
forward Action ZP_OnClientValidateMode(int client, int modeID);

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
 * @param modeID            The mode index.
 * @param target            (Optional) The target index. (Which need to be infected/herozied, if value has -1, mode will be choose players randomly)    
 **/
native void ZP_StartGameMode(int modeID, int target = -1);

/**
 * @brief Gets the index of a game mode at a given name.
 * 
 * @param name              The mode name.
 *
 * @return                  The mode index, or -1 on failure.
 **/
native int ZP_GetGameModeNameID(const char[] name);

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
 * @brief Gets the description color of a game mode at a given index.
 *
 * @param modeID            The mode index.
 * @param color             The array to return color in.
 * @param maxlenght         The max length of the array.
 **/
native void ZP_GetGameModeDescColor(int modeID, int[] color, int maxlenght = 4);

/**
 * @brief Gets the description X coordinate of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The coordinate value.
 **/
native float ZP_GetGameModeDescPosX(int modeID);

/**
 * @brief Gets the description Y coordinate of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The coordinate value.
 **/
native float ZP_GetGameModeDescPosY(int modeID); 

/**
 * @brief Gets the description time of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The time amount. 
 **/
native float ZP_GetGameModeDescTime(int modeID);

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
 * @brief Gets the human health of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  The health amount.    
 **/
native int ZP_GetGameModeHealthHuman(int modeID);

/**
 * @brief Gets the zombie health of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  The health amount.    
 **/
native int ZP_GetGameModeHealthZombie(int modeID);

/**
 * @brief Gets the group of a game mode at a given index.
 *
 * @param modeID            The mode index.
 * @param group             The string to return group in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetGameModeGroup(int modeID, char[] group, int maxlenght = 32);

/**
 * @brief Gets the group flags of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The flags bits.
 **/
native int ZP_GetGameModeGroupFlags(int modeID);

/**
 * @brief Gets the start sound key of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The key id.
 **/
native int ZP_GetGameModeSoundStartID(int modeID);

/**
 * @brief Gets the end human sound key of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The key id.
 **/
native int ZP_GetGameModeSoundEndHumanID(int modeID);

/**
 * @brief Gets the end zombie sound key of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The key id.
 **/
native int ZP_GetGameModeSoundEndZombieID(int modeID);

/**
 * @brief Gets the end draw sound key of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The key id.
 **/
native int ZP_GetGameModeSoundEndDrawID(int modeID);

/**
 * @brief Gets the comeback sound key of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The key id.
 **/
native int ZP_GetGameModeSoundComebackID(int modeID);

/**
 * @brief Gets the ambient sound key of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The key id.
 **/
native int ZP_GetGameModeSoundAmbientID(int modeID);

/**
 * @brief Checks the infection type of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  True or false.    
 **/
native bool ZP_IsGameModeInfect(int modeID);

/**
 * @brief Checks the respawn type of the game mode.
 * 
 * @param modeID            The mode index.
 *
 * @return                  True or false.    
 **/
native bool ZP_IsGameModeRespawn(int modeID);

/**
 * @brief Gets the human type of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The type index. 
 **/
native int ZP_GetGameModeTypeHuman(int modeID);

/**
 * @brief Gets the zombie type of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  The type index. 
 **/
native int ZP_GetGameModeTypeZombie(int modeID);

/**
 * @brief Checks the human win overlay of the game mode.
 * 
 * @param modeID            The mode index.
 * @param overlay           The string to return overlay in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetGameModeOverlayHuman(int modeID, char[] overlay, int maxlenght = 256);

/**
 * @brief Checks the zombie win overlay of the game mode.
 * 
 * @param modeID            The mode index.
 * @param overlay           The string to return overlay in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetGameModeOverlayZombie(int modeID, char[] overlay, int maxlenght = 256);

/**
 * @brief Checks the draw overlay of the game mode.
 * 
 * @param modeID            The mode index.
 * @param overlay           The string to return overlay in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetGameModeOverlayDraw(int modeID, char[] overlay, int maxlenght = 256);    

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
 * @brief Checks the suicide mode of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false.  
 **/
native bool ZP_IsGameModeSuicide(int modeID);

/**
 * @brief Checks the escape mode of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false.  
 **/
native bool ZP_IsGameModeEscape(int modeID);

/**
 * @brief Checks the blast mode of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeBlast(int modeID);

/**
 * @brief Checks the xray access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeXRay(int modeID);

/**
 * @brief Checks the regen access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeRegen(int modeID);

/**
 * @brief Checks the skill access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeSkill(int modeID);

/**
 * @brief Checks the leapjump access of the game mode.
 *
 * @param modeID            The mode index.
 *
 * @return                  True or false. 
 **/
native bool ZP_IsGameModeLeapJump(int modeID);