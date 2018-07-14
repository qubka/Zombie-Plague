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

#if defined _menulist_included
 #endinput
#endif
#define _menulist_included

/**
 * @brief Called before show a main menu.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block showing. Anything else
 *                              (like Plugin_Continue) to allow showing.
 **/
forward Action ZP_OnClientValidateMainMenu(int clientIndex);

/**
 * @brief Gets the amount of all menus.
 **/
native int ZP_GetNumberMenu();

/**
 * @brief Gets the name of a menu at a given index.
 *
 * @param menuID            The menu index.
 * @param name              The string to return name in.
 * @param maxlenght         The max length of the string.
 **/
native void ZP_GetMenuName(int menuID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the flags of a menu at a given index.
 *
 * @param menuID            The menu index.
 * @param flags             The string to return flags in.
 * @param maxlenght         The max length of the string.
 **/
native void ZP_GetMenuAccess(int menuID, char[] flags, int maxlenght = 32);

/**
 * @brief Gets the command of a menu at a given index.
 *
 * @param menuID            The menu index.
 * @param command           The string to return command in.
 * @param maxlenght         The max length of the string.
 **/
native void ZP_GetMenuCommand(int menuID, char[] command, int maxlenght = 32);
