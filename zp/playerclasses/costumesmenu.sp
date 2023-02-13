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
void CostumesMenuOnCommandInit()
{
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
	if (IsPlayerExist(client, false) && gCvarList.COSTUMES.BoolValue)
	{
		CostumesMenu(client);
	}
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
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	Menu hMenu = new Menu(CostumesMenuSlots);
	
	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%t", "costumes menu");
	
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "costumes remove");
		hMenu.AddItem("-1", sBuffer);
	}
		
	int iFlags = GetUserFlagBits(client);
	
	Action hResult;
	
	int iSize = gServerData.Costumes.Length; int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		gForwardData._OnClientValidateCostume(client, i, hResult);
		
		if (hResult == Plugin_Stop)
		{
			continue;
		}
		
		CostumesGetName(i, sName, sizeof(sName));
		int iLevel = CostumesGetLevel(i);
		int iGroup = CostumesGetGroupFlags(i);
		
		bool bEnabled = false;
		
		if (iGroup && !(iGroup & iFlags))
		{
			CostumesGetGroup(i, sInfo, sizeof(sInfo));
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu group", sInfo);
		}
		else if (gCvarList.LEVEL_SYSTEM.BoolValue && gClientData[client].Level < iLevel)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu level", iLevel);
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);
			bEnabled = true;
		}

		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(bEnabled && hResult != Plugin_Handled && gClientData[client].Costume != i));
	
		iAmount++;
	}
	
	if (!iAmount)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}

	hMenu.ExitBackButton = true;

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
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}

		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				if (!IsPlayerExist(client, false))
				{
					return 0;
				}
				
				int iD[2]; iD = MenusCommandToArray("zcostume");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
			
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);
			
			switch (iD)
			{
				case -1 :
				{
					CostumesRemove(client);
					
					gClientData[client].Costume = -1;
				}
			
				default :
				{
					Action hResult;
					gForwardData._OnClientValidateCostume(client, iD, hResult);
					
					if (hResult == Plugin_Continue || hResult == Plugin_Changed)
					{
						gClientData[client].Costume = iD;
						
						DataBaseOnClientUpdate(client, ColumnType_Costume);
						
						CostumesCreateEntity(client);
					}
				}
			}
		}
	}
	
	return 0;
}