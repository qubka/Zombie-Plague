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
void DonateMenuOnCommandInit(/*void*/)
{
	// Create commands
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
	DonateMenu(client, gCvarList.ACCOUNT_BET.IntValue, gCvarList.ACCOUNT_COMMISION.FloatValue);
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
	// If amount below bet, then set to default
	int iBet = gCvarList.ACCOUNT_BET.IntValue;
	if (iMoney < iBet)
	{
		iMoney = iBet;
	}

	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sInfo[SMALL_LINE_LENGTH];
	
	// Creates menu handle
	Menu hMenu = new Menu(DonateMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);

	// Validate commission
	if (flCommision <= 0.0)
	{
		// Sets donate title
		hMenu.SetTitle("%t", "account donate", iMoney, "money");
	}
	else
	{
		// Round mode for above 1% commision
		if (flCommision >= 0.01)
		{
			FormatEx(sInfo, sizeof(sInfo), "%d%", RoundToNearest(flCommision * 100.0));
		}
		else
		{
			FormatEx(sInfo, sizeof(sInfo), "%.2f%", flCommision * 100.0);
		}
		// Sets commission title
		hMenu.SetTitle("%t", "account commission", iMoney, "money", sInfo);
	}

	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "account increase");
		
		// Show increase option
		FormatEx(sInfo, sizeof(sInfo), "-2 %d %f", iMoney, flCommision);
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney <= gClientData[client].Money));

		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "account decrease");
		
		// Show decrease option
		FormatEx(sInfo, sizeof(sInfo), "-1 %d %f", iMoney, flCommision);
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney > iBet));
	}
	
	// i = client index
	int iAmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if (!IsPlayerExist(i, false) || client == i)
		{
			continue;
		}

		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%N", i);

		// Show option
		FormatEx(sInfo, sizeof(sInfo), "%d %d %f", GetClientUserId(i), iMoney, flCommision);
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney <= gClientData[client].Money));

		// Increment amount
		iAmount++;
	}
	
	// If there are no cases, add an "(Empty)" line
	if (!iAmount)
	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
		hMenu.AddItem("empty", sBuffer);
	}
	
	// Sets exit and back button
	hMenu.ExitBackButton = true;

	// Sets options and display it
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
				int iD[2]; iD = MenusCommandToArray("zdonate");
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
			static char sInfo[3][SMALL_LINE_LENGTH];
			ExplodeString(sBuffer, " ", sInfo, sizeof(sInfo), sizeof(sInfo[]));
			int target = StringToInt(sInfo[0]); int iMoney = StringToInt(sInfo[1]); 
			float flCommision = StringToFloat(sInfo[2]);

			// Validate button info
			switch (target)
			{
				// Client hit 'Decrease' button 
				case -1 :
				{
					DonateMenu(client, iMoney - gCvarList.ACCOUNT_BET.IntValue, flCommision + gCvarList.ACCOUNT_DECREASE.FloatValue);
				}
				
				// Client hit 'Increase' button
				case -2  :
				{
					DonateMenu(client, iMoney + gCvarList.ACCOUNT_BET.IntValue, flCommision - gCvarList.ACCOUNT_DECREASE.FloatValue);
				}
				
				// Client hit 'Target' button
				default :
				{
					/// Function returns 0 if invalid userid, then stop
					target = GetClientOfUserId(target);
				
					// Validate target
					if (target)
					{
						// Validate commision
						int iAmount;
						if (flCommision <= 0.0)
						{
							// Sets amount
							iAmount = iMoney;
						}
						else
						{
							// Calculate amount
							iAmount = RoundToNearest(float(iMoney) * (1.0 - flCommision));
						}
						
						// Sets money for the client
						AccountSetClientCash(client, gClientData[client].Money - iMoney);
						
						// Sets money for the target 
						AccountSetClientCash(target, gClientData[target].Money + iAmount);
						
						// If help messages enabled, then show info
						if (gCvarList.MESSAGES_DONATE.BoolValue)
						{
							// Gets client/target name
							GetClientName(client, sInfo[0], sizeof(sInfo[]));
							GetClientName(target, sInfo[1], sizeof(sInfo[]));
							
							// Show message of successful transaction
							TranslationPrintToChatAll("info donate", sInfo[0], iAmount, "money", sInfo[1]);
						}
					}
					else
					{

						// Show block info
						TranslationPrintHintText(client, "block selecting target");
					
						// Emit error sound
						EmitSoundToClient(client, SOUND_BUTTON_CMD_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER); 
					}
				}
			}
		}
	}
	
	return 0;
}
