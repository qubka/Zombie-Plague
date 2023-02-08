/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          arsenalmenu.sp
 *  Type:          Module 
 *  Description:   Provides functions for managing arsenal menu.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @brief Creates commands for arsenal module.
 **/
void ArsenalMenuOnCommandInit(/*void*/)
{
	// Create commands
	RegConsoleCmd("zarsenal", ArsenalMenuOnCommandCatched, "Opens the arsenal menu.");
}

/**
 * Console command callback (zarsenal)
 * @brief Opens the arsenal menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ArsenalMenuOnCommandCatched(int client, int iArguments)
{
	// Validate arsenal
	if (gCvarList.ARSENAL.BoolValue && !gCvarList.ARSENAL_RANDOM_WEAPONS.BoolValue)
	{
		ArsenalOpen(client, gClientData[client].CurrentMenu);
	}
	return Plugin_Handled;
}

/**
 * @brief Creates an arsenal menu.
 *
 * @param client            The client index.
 * @param mSection          The section index.
 **/
void ArsenalMenu(int client, int mSection)
{
	// Validate client
	if (!IsPlayerExist(client))
	{
		return;
	}
	
	// Disable menu for non humans and if blocked
	bool bDisabled = gClientData[client].BlockMenu || gClientData[client].Zombie || gClientData[client].Custom;

	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	static char sLevel[SMALL_LINE_LENGTH];
	static char sOnline[SMALL_LINE_LENGTH];
	static char sGroup[SMALL_LINE_LENGTH];

	// Gets amount of total players
	int iPlaying = fnGetPlaying();

	// Creates menu handle
	Menu hMenu = ArsenalSectionToHandle(mSection);
	
	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	static char sTitle[3][SMALL_LINE_LENGTH] = { "choose primary", "choose secondary", "choose melee" };
	hMenu.SetTitle("%t", sTitle[mSection]);

	// Gets current arsenal list
	ArrayList hList = gServerData.Arsenal.Get(mSection);

	// i = array index
	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Gets weapon id from the list
		int iD = hList.Get(i);

		// Gets weapon data
		WeaponsGetName(iD, sName, sizeof(sName));
		WeaponsGetGroup(iD, sGroup, sizeof(sGroup))

		// Format some chars for showing in menu    
		FormatEx(sLevel, sizeof(sLevel), "%t", "level", WeaponsGetLevel(iD));
		FormatEx(sOnline, sizeof(sOnline), "%t", "online", WeaponsGetOnline(iD));  
		FormatEx(sBuffer, sizeof(sBuffer), (i == iSize - 1) ? "%t  %s\n \n" : "%t  %s", sName, hasLength(sGroup) ? sGroup : (gClientData[client].Level < WeaponsGetLevel(iD)) ? sLevel : (iPlaying < WeaponsGetOnline(iD)) ? sOnline : "");

		// Show option
		IntToString(iD, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw((bDisabled || (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) || gClientData[client].Level < WeaponsGetLevel(iD) || iPlaying < WeaponsGetOnline(iD)) ? false : true));
	}

	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t [%t]", "market remember", gClientData[client].AutoSelect ? "On" : "Off");
		
		// Show toggle option
		hMenu.AddItem("-1", sBuffer);
	}
	
	// Sets exit button
	hMenu.ExitButton = true;

	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the market buy menu, and handles it. (primary)
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ArsenalMenuSlots1(Menu hMenu, MenuAction mAction, int client, int mSlot)
{   
	return ArsenalMenuSlots(hMenu, mAction, client, mSlot, ArsenalType_Primary);
}

/**
 * @brief Called when client selects option in the market buy menu, and handles it. (secondary)
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ArsenalMenuSlots2(Menu hMenu, MenuAction mAction, int client, int mSlot)
{   
	return ArsenalMenuSlots(hMenu, mAction, client, mSlot, ArsenalType_Secondary);
}

/**
 * @brief Called when client selects option in the market buy menu, and handles it. (melee)
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ArsenalMenuSlots3(Menu hMenu, MenuAction mAction, int client, int mSlot)
{   
	return ArsenalMenuSlots(hMenu, mAction, client, mSlot, ArsenalType_Melee);
}

/**
 * @brief Called when client selects option in the market buy menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param iIndex            The arsenal menu index.
 **/ 
int ArsenalMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot, int iIndex)
{
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}

		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client))
			{
				return 0;
			}
			
			// Validate any except human, then stop
			if (gClientData[client].Zombie || gClientData[client].Custom)
			{
				// Show block info
				TranslationPrintHintText(client, "block using menu");
				
				// Emit error sound
				EmitSoundToClient(client, SOUND_WEAPON_CANT_BUY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}

			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// Validate button info
			switch (iD)
			{
				// Client hit 'Remember' button
				case -1 :
				{
					// Toggle autoselect
					gClientData[client].AutoSelect = !gClientData[client].AutoSelect;
					
					// Opens same menu back
					ArsenalMenu(client, iIndex);
				}
				
				// Client hit 'Weapon' button
				default :
				{
					// Give weapon for the player
					WeaponsGive(client, iD);
					
					// If help messages enabled, then show info
					if (gCvarList.MESSAGES_WEAPON_INFO.BoolValue)
					{
						// Gets weapon info
						WeaponsGetInfo(iD, sBuffer, sizeof(sBuffer));
						
						// Show weapon personal info
						if (hasLength(sBuffer)) TranslationPrintHintText(client, sBuffer);
					}
					
					// Store selected weapon id
					gClientData[client].Arsenal[iIndex] = iD;
					gClientData[client].CurrentMenu = iIndex + 1;

					// Opens next menu
					if (ArsenalOpen(client, gClientData[client].CurrentMenu))
					{
						return 0;
					}

					// If last one, give additional weapons and opens favorites menu

					// Give additional weapons
					ArsenalGiveAdds(client);
					
					// Validate cart size
					if (gClientData[client].DefaultCart.Length)
					{
						// Opens favorites menu
						MarketBuyMenu(client, MenuType_FavBuy);
					}
				}
			}
		}
	}
	
	return 0;
}

/**
 * @brief Find the handle at which the section is at.
 * 
 * @param mSection          The section index.
 * @return                  The menu handle.
 **/
Menu ArsenalSectionToHandle(int mSection)
{
	switch (mSection)
	{
		case ArsenalType_Primary :
		{
			return new Menu(ArsenalMenuSlots1);
		}
		
		case ArsenalType_Secondary :
		{
			return new Menu(ArsenalMenuSlots2);
		}

		default :
		{
			return new Menu(ArsenalMenuSlots3);
		}
	}
}