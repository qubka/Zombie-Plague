/**
 * ============================================================================
 *
 *  Zombie Plague #3 Generation
 *
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

#include <sourcemod>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin MenuClass =
{
	name        	= "[ZP] Menu: Class",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Human and zombie classes menu generator",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * Class menu cases.
 **/
enum ClassMenu
{
	ClassMenu_Human,		/** Human class menu slot. */
	ClassMenu_Zombie,		/** Zombie class menu slot. */	
};

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(StrEqual(sLibrary, "zombieplague"))
    {
        // Load translations phrases used by plugin
        LoadTranslations("zombieplague.phrases");
        
        // Create a commands
        RegConsoleCmd("zhumanclassmenu",  Command_HumanClassesMenu,  "Open the human classes menu.");
        RegConsoleCmd("zzombieclassmenu", Command_ZombieClassesMenu, "Open the zombie classes menu.");
    }
}

/**
 * Handles the zhumanclassmenu command. Open the human classes menu.
 * 
 * @param clientIndex		The client index.
 * @param iArguments		The number of arguments that were in the argument string.
 **/ 
public Action Command_HumanClassesMenu(int clientIndex, int iArguments)
{
	// Open the human classes menu
	MenuClasses(clientIndex, ClassMenu_Human);
}

/**
 * Handles the zzombieclassmenu command. Open the zombie classes menu.
 * 
 * @param clientIndex		The client index.
 * @param iArguments		The number of arguments that were in the argument string.
 **/ 
public Action Command_ZombieClassesMenu(int clientIndex, int iArguments)
{
	// Open the zombie classes menu
	MenuClasses(clientIndex, ClassMenu_Zombie);
}

/*
 * Zombie class and human class sub menu
 */

/**
 * Create a class menu.
 *
 * @param clientIndex			The client index.
 * @param iMode   				The type of the menu.
 **/
void MenuClasses(int clientIndex, ClassMenu iMode) 
{
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		return;
	}

	// Initialize chars
	static char sBuffer[BIG_LINE_LENGTH];
	static char sName[NORMAL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	static char sLevel[SMALL_LINE_LENGTH];

	// Initialize menu
	Menu iMenu;
	
	// Sets the language to target
	SetGlobalTransTarget(clientIndex);
	
	// Amount of cases
	int iCount;
	
	// Switch the menu mode
	switch(iMode)
	{
		// Zombie classes menu
		case ClassMenu_Zombie :
		{
			// Create menu handle
			iMenu = CreateMenu(MenuZombieSlots);

			// Set title
			SetMenuTitle(iMenu, "%t", "@Choose zombieclass");
			
			// i = Zombie class number
			iCount = ZP_GetNumberZombieClass()
			for(int i = 0; i < iCount; i++)
			{
				// Get zombie class name
				ZP_GetZombieClassName(i, sName, sizeof(sName));
				if(!IsCharUpper(sName[0]) && !IsCharNumeric(sName[0])) sName[0] = CharToUpper(sName[0]);
				
				// Format some chars for showing in menu
				// Is string contains @, name will be translate
				Format(sLevel, sizeof(sLevel), "[LVL:%i]", ZP_GetZombieClassLevel(i));
				Format(sBuffer, sizeof(sBuffer), (sName[0] == '@') ? "%t    %s" : "%s    %s", sName, ZP_IsZombieClassVIP(i) ? "[VIP]" : ZP_GetZombieClassLevel(i) > 1 ? sLevel : "");
				
				// Show option
				IntToString(i, sInfo, sizeof(sInfo));
				AddMenuItem(iMenu, sInfo, sBuffer, MenuGetItemDraw(((!ZP_IsPlayerPrivileged(clientIndex, Admin_Custom1) && ZP_IsZombieClassVIP(i)) || ZP_GetClientLevel(clientIndex) < ZP_GetZombieClassLevel(i) || ZP_GetClientZombieClassNext(clientIndex) == i) ? false : true));
			}
		}
		
		// Human classes menu
		case ClassMenu_Human :
		{
			// Create menu handle
			iMenu = CreateMenu(MenuHumanSlots);

			// Set title
			SetMenuTitle(iMenu, "%t", "@Choose humanclass");
			
			// i = Human class number
			iCount = ZP_GetNumberHumanClass();
			for(int i = 0; i < iCount; i++)
			{
				// Get human class name
				ZP_GetHumanClassName(i, sName, sizeof(sName));
				if(!IsCharUpper(sName[0]) && !IsCharNumeric(sName[0])) sName[0] = CharToUpper(sName[0]);
				
				// Format some chars for showing in menu
				// Is string contains @, name will be translate
				Format(sLevel, sizeof(sLevel), "[LVL:%i]", ZP_GetHumanClassLevel(i));
				Format(sBuffer, sizeof(sBuffer), (sName[0] == '@') ? "%t    %s" : "%s    %s", sName, ZP_IsHumanClassVIP(i) ? "[VIP]" : ZP_GetHumanClassLevel(i) > 1 ? sLevel : "");
				
				// Show option
				IntToString(i, sInfo, sizeof(sInfo));
				AddMenuItem(iMenu, sInfo, sBuffer, MenuGetItemDraw(((!ZP_IsPlayerPrivileged(clientIndex, Admin_Custom1) && ZP_IsHumanClassVIP(i)) || ZP_GetClientLevel(clientIndex) < ZP_GetHumanClassLevel(i) || ZP_GetClientHumanClassNext(clientIndex) == i) ? false : true));
			}
		}
	}

	// Set exit and back button
	SetMenuExitBackButton(iMenu, true);

	// Set options and display it
	SetMenuOptionFlags(iMenu, MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK);
	DisplayMenu(iMenu, clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param iMenu				The handle of the menu being used.
 * @param mAction			The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex		The client index.
 * @param mSlot				The slot index selected (starting from 0).
 **/ 
public int MenuZombieSlots(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
	// Switch the menu action
	switch(mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			CloseHandle(iMenu);
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if(mSlot == MenuCancel_ExitBack)
			{
				// Open main menu back
				if(IsPlayerExist(clientIndex, false)) FakeClientCommand(clientIndex, "zmainmenu");
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if(!IsPlayerExist(clientIndex, false))
			{
				return;
			}

			// Initialize char
			static char sInfo[SMALL_LINE_LENGTH];

			// Get ID of zombie class
			GetMenuItem(iMenu, mSlot, sInfo, sizeof(sInfo));
			int iD = StringToInt(sInfo);
			
			// Set next zombie class
			ZP_SetClientZombieClass(clientIndex, iD);
	
			// Show class info
			ZP_PrintZombieClassInfo(clientIndex, iD);
		}
	}
}

/**
 * Called when client selects option in the human class menu, and handles it.
 *  
 * @param iMenu				The handle of the menu being used.
 * @param mAction			The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex		The client index.
 * @param mSlot				The slot index selected (starting from 0).
 **/ 
public int MenuHumanSlots(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
	// Switch the menu action
	switch(mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			CloseHandle(iMenu);
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if(mSlot == MenuCancel_ExitBack)
			{
				// Open main menu back
				if(IsPlayerExist(clientIndex, false)) FakeClientCommand(clientIndex, "zmainmenu");
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if(!IsPlayerExist(clientIndex, false))
			{
				return;
			}

			// Initialize char
			static char sInfo[SMALL_LINE_LENGTH];

			// Get ID of zombie class
			GetMenuItem(iMenu, mSlot, sInfo, sizeof(sInfo));
			int iD = StringToInt(sInfo);
			
			// Set next zombie class
			ZP_SetClientHumanClass(clientIndex, iD);
	
			// Show class info
			ZP_PrintHumanClassInfo(clientIndex, iD);
		}
	}
}

/**
 * Return itemdraw flag for radio menus.
 * 
 * @param menuCondition     If this is true, item will be drawn normally.
 **/
stock int MenuGetItemDraw(bool menuCondition)
{
    return menuCondition ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
}