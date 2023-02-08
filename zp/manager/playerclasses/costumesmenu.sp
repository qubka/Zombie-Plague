/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          costumesmenu.sp
 *  Type:          Module 
 *  Description:   Provides functions for managing costumes menu.
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
 * @brief Creates commands for costumes module.
 **/
void CostumesMenuOnCommandInit(/*void*/)
{
	// Create commands
	RegConsoleCmd("zcostume", CostumesMenuOnCommandCatched, "Opens the costumes menu.");
}

/**
 * Console command callback (zcostume)
 * @brief Opens the costumes menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action CostumesMenuOnCommandCatched(int client, int iArguments)
{
	CostumesMenu(client);
	return Plugin_Handled;
}

/*
 * Menu costumes API.
 */

/**
 * @brief Creates a costume menu.
 *
 * @param client            The client index.
 **/
void CostumesMenu(int client)
{
	// If module is disabled, then stop
	if (!gCvarList.COSTUMES.BoolValue)
	{
		return;
	}
	
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	static char sLevel[SMALL_LINE_LENGTH];
	static char sGroup[SMALL_LINE_LENGTH];
	
	// Creates menu handle
	Menu hMenu = new Menu(CostumesMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", "costumes menu");
	
	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "costumes remove");
		
		// Show add option
		hMenu.AddItem("-1", sBuffer);
	}
	
	// Initialize forward
	Action hResult;
	
	// i = array index
	int iSize = gServerData.Costumes.Length; int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		// Call forward
		gForwardData._OnClientValidateCostume(client, i, hResult);
		
		// Skip, if class is disabled
		if (hResult == Plugin_Stop)
		{
			continue;
		}
		
		// Gets costume data
		CostumesGetName(i, sName, sizeof(sName));
		CostumesGetGroup(i, sGroup, sizeof(sGroup));
		
		// Format some chars for showing in menu
		FormatEx(sLevel, sizeof(sLevel), "%t", "level", CostumesGetLevel(i));
		FormatEx(sBuffer, sizeof(sBuffer), "%t  %s", sName, (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) ? sGroup : (gClientData[client].Level < CostumesGetLevel(i)) ? sLevel : "");

		// Show option
		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw((hResult == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) || gClientData[client].Level < CostumesGetLevel(i) || gClientData[client].Costume == i) ? false : true));
	
		// Increment amount
		iAmount++;
	}
	
	// If there are no cases, add an "(Empty)" line
	if (!iAmount)
	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}

	// Sets exit and back button
	hMenu.ExitBackButton = true;

	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the main menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int CostumesMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}

		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				// Opens menu back
				int iD[2]; iD = MenusCommandToArray("zcostume");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
			
			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);
			
			// Validate button info
			switch (iD)
			{
				// Client hit 'Remove' button
				case -1 :
				{
					// Remove current costume
					CostumesRemove(client);
					
					// Sets costume to the client
					gClientData[client].Costume = -1;
				}
			
				// Client hit 'Costume' button
				default :
				{
					// Call forward
					Action hResult;
					gForwardData._OnClientValidateCostume(client, iD, hResult);
					
					// Validate handle
					if (hResult == Plugin_Continue || hResult == Plugin_Changed)
					{
						// Sets costume to the client
						gClientData[client].Costume = iD;
						
						// Update costume in the database
						DataBaseOnClientUpdate(client, ColumnType_Costume);
						
						// Sets costume
						CostumesCreateEntity(client);
					}
				}
			}
		}
	}
	
	return 0;
}