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
void ArsenalMenuOnCommandInit()
{
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
	if (IsClientValid(client) && gCvarList.ARSENAL.BoolValue && !gCvarList.ARSENAL_RANDOM_WEAPONS.BoolValue)
	{
		ArsenalOpen(client, gClientData[client].CurrentMenu);
	}
	return Plugin_Handled;
}

/**
 * @brief Creates an arsenal menu.
 *
 * @param client            The client index.
 * @param iSection          The section index.
 **/
void ArsenalMenu(int client, int iSection)
{
	bool bLocked = gClientData[client].ArsenalUsed || gClientData[client].Zombie || gClientData[client].Custom;

	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	Menu hMenu = ArsenalSectionToHandle(iSection);
	
	SetGlobalTransTarget(client);
	
	static char sTitle[3][SMALL_LINE_LENGTH] = { "choose primary", "choose secondary", "choose melee" };
	hMenu.SetTitle("%t", sTitle[iSection]);

	int iPlaying = fnGetPlaying();
	int iFlags = GetUserFlagBits(client);

	ArrayList hList = gServerData.Arsenal.Get(iSection);

	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		int iD = hList.Get(i);

		WeaponsGetName(iD, sName, sizeof(sName));
		int iLevel = WeaponsGetLevel(iD);
		int iOnline = WeaponsGetOnline(iD);
		int iGroup = WeaponsGetGroupFlags(iD);
		
		bool bEnabled = false;
		
		if (iGroup && !(iGroup & iFlags))
		{
			WeaponsGetGroup(iD, sInfo, sizeof(sInfo));
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu group", sInfo);
		}
		else if (gCvarList.LEVEL_SYSTEM.BoolValue && gClientData[client].Level < iLevel)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu level", iLevel);
		}
		else if (iPlaying < iOnline)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu online", iOnline);    
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);
			bEnabled = true;
		}
		
		if (i == iSize - 1)
		{
			StrCat(sBuffer, sizeof(sBuffer), "\n \n");
		}
		
		IntToString(iD, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(bEnabled && !bLocked));
	}
	
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n \n", "arsenal skip");
		hMenu.AddItem("-2", sBuffer);
	}
	
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t [%t]", "arsenal remember", gClientData[client].AutoSelect ? "On" : "Off");
		hMenu.AddItem("-1", sBuffer);
	}

	hMenu.ExitButton = true;

	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the arsenal menu, and handles it. (primary)
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
 * @brief Called when client selects option in the arsenal menu, and handles it. (secondary)
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
 * @brief Called when client selects option in the arsenal menu, and handles it. (melee)
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
 * @brief Called when client selects option in the arsenal menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param iIndex            The arsenal menu index.
 **/ 
int ArsenalMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot, int iIndex)
{
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}

		case MenuAction_Select :
		{
			if (!IsClientValid(client))
			{
				return 0;
			}
			
			if (gClientData[client].Zombie || gClientData[client].Custom)
			{
				TranslationPrintHintText(client, "block using menu");
				
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}

			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			switch (iD)
			{
				case -1 :
				{
					gClientData[client].AutoSelect = !gClientData[client].AutoSelect;
					
					ArsenalMenu(client, iIndex);
				}

				default :
				{
					if (iD != -2)
					{
						WeaponsGive(client, iD);
						
						EmitSoundToClient(client, SOUND_BUY_ITEM, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
						
						if (gCvarList.MESSAGES_WEAPON_INFO.BoolValue)
						{
							WeaponsGetInfo(iD, sBuffer, sizeof(sBuffer));
							
							if (hasLength(sBuffer)) TranslationPrintHintText(client, sBuffer);
						}
					}
					else
					{
						EmitSoundToClient(client, SOUND_BUY_ITEM_FAILED, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
					}
					
					gClientData[client].Arsenal[iIndex] = iD;
					gClientData[client].CurrentMenu = iIndex + 1;

					if (ArsenalOpen(client, gClientData[client].CurrentMenu))
					{
						return 0;
					}
					
					if (!gClientData[client].ArsenalUsed)
					{
						ArsenalGiveAdds(client);
						
						if (gClientData[client].DefaultCart.Length)
						{
							MarketBuyMenu(client, MenuType_FavBuy);
						}
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
 * @param iSection          The section index.
 * @return                  The menu handle.
 **/
Menu ArsenalSectionToHandle(int iSection)
{
	switch (iSection)
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