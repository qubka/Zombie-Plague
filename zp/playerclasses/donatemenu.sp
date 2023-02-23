/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          donatemenu.sp
 *  Type:          Module 
 *  Description:   Provides functions for managing donate menu.
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
 * @brief Creates commands for account module.
 **/
void DonateMenuOnCommandInit()
{
	RegConsoleCmd("zdonate", DonateMenuOnCommandCatched, "Opens the donates menu.");
}

/**
 * Console command callback (zdonate)
 * @brief Opens the donates menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action DonateMenuOnCommandCatched(int client, int iArguments)
{
	if (IsClientValid(client, false))
	{
		DonateMenu(client, gCvarList.ACCOUNT_BET.IntValue, gCvarList.ACCOUNT_COMMISION.FloatValue);
	}
	return Plugin_Handled;
}

/**
 * @brief Creates the donates menu.
 *
 * @param client            The client index.
 * @param iMoney            The money amount.   
 * @param flCommision       The commission amount.
 **/
void DonateMenu(int client, int iMoney, float flCommision) 
{
	int iBet = gCvarList.ACCOUNT_BET.IntValue;
	if (iMoney < iBet)
	{
		iMoney = iBet;
	}

	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sInfo[SMALL_LINE_LENGTH];
	
	Menu hMenu = new Menu(DonateMenuSlots);
	
	SetGlobalTransTarget(client);

	if (flCommision <= 0.0)
	{
		hMenu.SetTitle("%t", "account donate", iMoney, "menu money");
	}
	else
	{
		if (flCommision >= 0.01)
		{
			FormatEx(sInfo, sizeof(sInfo), "%d%", RoundToNearest(flCommision * 100.0));
		}
		else
		{
			FormatEx(sInfo, sizeof(sInfo), "%.2f%", flCommision * 100.0);
		}
		hMenu.SetTitle("%t", "account commission", iMoney, "menu money", sInfo);
	}

	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "account increase");
		
		FormatEx(sInfo, sizeof(sInfo), "-2 %d %f", iMoney, flCommision);
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney <= gClientData[client].Money));

		FormatEx(sBuffer, sizeof(sBuffer), "%t", "account decrease");
		
		FormatEx(sInfo, sizeof(sInfo), "-1 %d %f", iMoney, flCommision);
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney > iBet));
	}
	
	int iAmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientValid(i, false) || client == i)
		{
			continue;
		}

		FormatEx(sBuffer, sizeof(sBuffer), "%N", i);

		FormatEx(sInfo, sizeof(sInfo), "%d %d %f", GetClientUserId(i), iMoney, flCommision);
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney <= gClientData[client].Money));

		iAmount++;
	}
	
	if (!iAmount)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer);
	}
	
	hMenu.ExitBackButton = true;

	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the donates menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int DonateMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				if (!IsClientValid(client, false))
				{
					return 0;
				}
				
				int iD[2]; iD = MenusCommandToArray("zdonate");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsClientValid(client, false))
			{
				return 0;
			}

			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			static char sInfo[3][SMALL_LINE_LENGTH];
			ExplodeString(sBuffer, " ", sInfo, sizeof(sInfo), sizeof(sInfo[]));
			int target = StringToInt(sInfo[0]); int iMoney = StringToInt(sInfo[1]); 
			float flCommision = StringToFloat(sInfo[2]);

			switch (target)
			{
				case -1 :
				{
					DonateMenu(client, iMoney - gCvarList.ACCOUNT_BET.IntValue, flCommision + gCvarList.ACCOUNT_DECREASE.FloatValue);
				}
				
				case -2  :
				{
					DonateMenu(client, iMoney + gCvarList.ACCOUNT_BET.IntValue, flCommision - gCvarList.ACCOUNT_DECREASE.FloatValue);
				}
				
				default :
				{
					target = GetClientOfUserId(target);
				
					if (target)
					{
						int iAmount;
						if (flCommision <= 0.0)
						{
							iAmount = iMoney;
						}
						else
						{
							iAmount = RoundToNearest(float(iMoney) * (1.0 - flCommision));
						}
						
						AccountSetClientCash(client, gClientData[client].Money - iMoney);
						AccountSetClientCash(target, gClientData[target].Money + iAmount);
						
						if (gCvarList.MESSAGES_DONATE.BoolValue)
						{
							GetClientName(client, sInfo[0], sizeof(sInfo[]));
							GetClientName(target, sInfo[1], sizeof(sInfo[]));
							
							TranslationPrintToChatAll("info donate", sInfo[0], iAmount, "menu money", sInfo[1]);
						}
					}
					else
					{

						TranslationPrintHintText(client, true, "block selecting target");
					
						EmitSoundToClient(client, SOUND_BUTTON_CMD_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER); 
					}
				}
			}
		}
	}
	
	return 0;
}
