/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          account.sp
 *  Type:          Module 
 *  Description:   Handles client accounts. (cash)
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
 * @section Account types.
 **/ 
enum /*AccountType*/
{
	AccountType_Disabled,
	AccountType_Classic,
	AccountType_Custom
}
/**
 * @endsection
 **/   

/**
 * @brief Account module init function.
 **/
void AccountOnInit(/*void*/)
{
	// If custom disabled, then remove hud
	if (gCvarList.ACCOUNT_MONEY.IntValue != AccountType_Custom)
	{
		// Validate loaded map
		if (gServerData.MapLoaded)
		{
			// Validate sync
			if (gServerData.AccountSync != null)
			{
				// i = client index
				for (int i = 1; i <= MaxClients; i++)
				{
					// Validate client
					if (IsPlayerExist(i))
					{
						// Remove timer
						delete gClientData[i].AccountTimer;
					}
				}
				
				// Remove sync
				delete gServerData.AccountSync;
			}
		}
	}
	
	// If custom enabled, then create sync
	if (gCvarList.ACCOUNT_MONEY.IntValue == AccountType_Custom)
	{
		// Creates a HUD synchronization object
		if (gServerData.AccountSync == null)
		{
			gServerData.AccountSync = CreateHudSynchronizer();
		}
	}
	
	// Validate loaded map
	if (gServerData.MapLoaded)
	{
		// i = client index
		for (int i = 1; i <= MaxClients; i++)
		{
			// Validate client
			if (IsPlayerExist(i, false))
			{
				// Enable account system
				_call.AccountOnClientUpdate(i);
			}
		}
	}
}

/**
 * @brief Creates commands for account module.
 **/
void AccountOnCommandInit(/*void*/)
{
	// Hook commands
	RegAdminCmd("zp_money_give", AccountGiveOnCommandCatched, ADMFLAG_GENERIC, "Gives the money. Usage: zp_money_give <name> [amount]");
	RegConsoleCmd("zp_money_donate", AccountDonateOnCommandCatched, "Donates the money. Usage: zp_money_donate <name> [amount]");
	RegConsoleCmd("zdonate", AccountMenuOnCommandCatched, "Opens the donates menu.");
}

/**
 * @brief Hook account cvar changes.
 **/
void AccountOnCvarInit(/*void*/)
{
	// Create cvars
	gCvarList.ACCOUNT_CASH_AWARD   = FindConVar("mp_playercashawards");
	gCvarList.ACCOUNT_BUY_ANYWHERE = FindConVar("mp_buy_anywhere");
	gCvarList.ACCOUNT_BUY_IMMUNITY = FindConVar("mp_buy_during_immunity");
	gCvarList.ACCOUNT_MONEY        = FindConVar("zp_account_money");
	gCvarList.ACCOUNT_CONNECT      = FindConVar("zp_account_connect");
	gCvarList.ACCOUNT_BET          = FindConVar("zp_account_bet");
	gCvarList.ACCOUNT_COMMISION    = FindConVar("zp_account_commision");
	gCvarList.ACCOUNT_DECREASE     = FindConVar("zp_account_decrease");
	gCvarList.ACCOUNT_HUD_R        = FindConVar("zp_account_hud_R");
	gCvarList.ACCOUNT_HUD_G        = FindConVar("zp_account_hud_G");
	gCvarList.ACCOUNT_HUD_B        = FindConVar("zp_account_hud_B");
	gCvarList.ACCOUNT_HUD_A        = FindConVar("zp_account_hud_A");
	gCvarList.ACCOUNT_HUD_X        = FindConVar("zp_account_hud_X");
	gCvarList.ACCOUNT_HUD_Y        = FindConVar("zp_account_hud_Y");
	
	// Sets locked cvars to their locked values
	gCvarList.ACCOUNT_CASH_AWARD.IntValue   = 0;
	gCvarList.ACCOUNT_BUY_ANYWHERE.IntValue = 1;
	gCvarList.ACCOUNT_BUY_IMMUNITY.IntValue = 0;
	
	// Hook cvars
	HookConVarChange(gCvarList.ACCOUNT_MONEY,        AccountOnCvarHook); 
	HookConVarChange(gCvarList.ACCOUNT_CASH_AWARD,   CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.ACCOUNT_BUY_ANYWHERE, CvarsUnlockOnCvarHook);
	HookConVarChange(gCvarList.ACCOUNT_BUY_IMMUNITY, CvarsLockOnCvarHook);
}

/**
 * Cvar hook callback (zp_money)
 * @brief Account module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void AccountOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (oldValue[0] == newValue[0])
	{
		return;
	}
	
	// Forward event to modules
	AccountOnInit();
}

/**
 * @brief Client has been spawned.
 * 
 * @param client            The client index.
 **/
void AccountOnClientSpawn(int client)
{
	// Resets HUD on the team change
	_call.AccountOnClientUpdate(client);
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void AccountOnClientDeath(int client)
{
	// Enable HUD for spectator
	_call.AccountOnClientUpdate(client);
}

/**
 * @brief Client has been changed class state. *(Post)
 *
 * @param userID            The user id.
 **/
public void AccountOnClientUpdate(int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Validate client
	if (client)
	{
		// Validate real client
		if (!IsFakeClient(client))
		{
			// Manipulate with account type
			delete gClientData[client].AccountTimer;
			switch (gCvarList.ACCOUNT_MONEY.IntValue)
			{
				case AccountType_Disabled : 
				{
					// Hide money bar panel
					gCvarList.ACCOUNT_CASH_AWARD.ReplicateToClient(client, "0");
				}
				
				case AccountType_Classic : 
				{
					// Show money bar panel
					gCvarList.ACCOUNT_CASH_AWARD.ReplicateToClient(client, "1");
					
					// Update client money
					AccountSetMoney(client, gClientData[client].Money);
				}
				
				case AccountType_Custom : 
				{
					// Hide money bar panel
					gCvarList.ACCOUNT_CASH_AWARD.ReplicateToClient(client, "0");
					
					// Sets timer for player account HUD
					gClientData[client].AccountTimer = CreateTimer(1.0, AccountOnClientHUD, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

/**
 * @brief Timer callback, show HUD text within information about client account value. (money)
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action AccountOnClientHUD(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Validate client
	if (client)
	{
		// Store the default index
		int target = client;

		// Validate spectator 
		if (!IsPlayerAlive(client))
		{
			// Validate spectator mode
			int iSpecMode = ToolsGetObserverMode(client);
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
			{
				// Allow timer
				return Plugin_Continue;
			}
			
			// Gets observer target
			target = ToolsGetObserverTarget(client);
			
			// Validate target
			if (!IsPlayerExist(target)) 
			{
				// Allow timer
				return Plugin_Continue;
			}
		}
		
		// Print hud text to the client
		TranslationPrintHudText(gServerData.AccountSync, client, gCvarList.ACCOUNT_HUD_X.FloatValue, gCvarList.ACCOUNT_HUD_Y.FloatValue, 1.1, gCvarList.ACCOUNT_HUD_R.IntValue, gCvarList.ACCOUNT_HUD_G.IntValue, gCvarList.ACCOUNT_HUD_B.IntValue, gCvarList.ACCOUNT_HUD_A.IntValue, 0, 0.0, 0.0, 0.0, "account info", "money", gClientData[target].Money);

		// Allow timer
		return Plugin_Continue;
	}

	// Clear timer
	gClientData[client].AccountTimer = null;

	// Destroy timer
	return Plugin_Stop;
}

/**
 * Console command callback (zp_money_give)
 * @brief Gives the money.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action AccountGiveOnCommandCatched(int client, int iArguments)
{
	// If not enough arguments given, then stop
	if (iArguments < 2)
	{
		// Write syntax info
		TranslationReplyToCommand(client, "account give invalid args");
		return Plugin_Handled;
	}
	
	// Initialize argument char
	static char sArgument[SMALL_LINE_LENGTH];
	
	// Gets target index
	GetCmdArg(1, sArgument, sizeof(sArgument));
	int target = FindTarget(client, sArgument, true, false);

	// Validate target
	if (target < 0)
	{
		// Note: FindTarget automatically write error messages
		return Plugin_Handled;
	}
	
	// Gets money amount
	GetCmdArg(2, sArgument, sizeof(sArgument));
	
	// Validate amount
	int iMoney = StringToInt(sArgument);
	if (iMoney <= 0)
	{
		// Write error info
		TranslationReplyToCommand(client, "account give invalid amount", iMoney);
		return Plugin_Handled;
	}

	// Sets money for the target 
	AccountSetClientCash(target, gClientData[target].Money + iMoney);

	// Log action to game events
	LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Classes, "Command", "Admin \"%N\" gived money: \"%d\" to Player \"%N\"", client, iMoney, target);
	return Plugin_Handled;
}

/**
 * Console command callback (zp_money_donate)
 * @brief Donates the money.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action AccountDonateOnCommandCatched(int client, int iArguments)
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return Plugin_Handled;
	}
	
	// If not enough arguments given, then stop
	if (iArguments < 2)
	{
		// Write syntax info
		TranslationReplyToCommand(client, "account donate invalid args");
		return Plugin_Handled;
	}
	
	// Initialize argument char
	static char sArgument[SMALL_LINE_LENGTH];
	
	// Gets target index
	GetCmdArg(1, sArgument, sizeof(sArgument));
	int target = FindTarget(client, sArgument, true, false);

	// Validate target
	if (target < 0 || client == target)
	{
		// Note: FindTarget automatically write error messages
		return Plugin_Handled;
	}
	
	// Gets money amount
	GetCmdArg(2, sArgument, sizeof(sArgument));
	
	// Validate amount
	int iMoney = StringToInt(sArgument); int iBet = gCvarList.ACCOUNT_BET.IntValue;
	if (iMoney <= 0 || iMoney > gClientData[client].Money || iMoney < iBet)
	{
		// Write error info
		TranslationReplyToCommand(client, "account give invalid amount", iMoney);
		return Plugin_Handled;
	}

	// Validate commision
	int iAmount; float flCommision = gCvarList.ACCOUNT_COMMISION.FloatValue - ((float(iMoney) / float(iBet)) * gCvarList.ACCOUNT_DECREASE.FloatValue);
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
		static char sInfo[2][SMALL_LINE_LENGTH];
		GetClientName(client, sInfo[0], sizeof(sInfo[]));
		GetClientName(target, sInfo[1], sizeof(sInfo[]));
		
		// Show message of successful transaction
		TranslationPrintToChatAll("donate info", sInfo[0], iAmount, "money", sInfo[1]);
	}
	
	// Return on success
	return Plugin_Handled;
}

/**
 * Console command callback (zdonate)
 * @brief Opens the donates menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action AccountMenuOnCommandCatched(int client, int iArguments)
{
	AccountMenu(client, gCvarList.ACCOUNT_BET.IntValue, gCvarList.ACCOUNT_COMMISION.FloatValue);
	return Plugin_Handled;
}

/*
 * Account natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void AccountOnNativeInit(/*void*/)
{
	CreateNative("ZP_GetClientMoney",        API_GetClientMoney);
	CreateNative("ZP_SetClientMoney",        API_SetClientMoney);
	CreateNative("ZP_GetClientLastPurchase", API_GetClientLastPurchase);
	CreateNative("ZP_SetClientLastPurchase", API_SetClientLastPurchase);
}

/**
 * @brief Gets the player amount of money.
 *
 * @note native int ZP_GetClientMoney(client);
 **/
public int API_GetClientMoney(Handle hPlugin, int iNumParams)
{
	// Gets real player index from native cell 
	int client = GetNativeCell(1);

	// Return the value 
	return gClientData[client].Money;
}

/**
 * @brief Sets the player amount of money.
 *
 * @note native void ZP_SetClientMoney(client, iD);
 **/
public int API_SetClientMoney(Handle hPlugin, int iNumParams)
{
	// Gets real player index from native cell 
	int client = GetNativeCell(1);

	// Sets money for the client
	AccountSetClientCash(client, GetNativeCell(2));
}

/**
 * @brief Gets the player amount of previous money spended.
 *
 * @note native int ZP_GetClientLastPurchase(client);
 **/
public int API_GetClientLastPurchase(Handle hPlugin, int iNumParams)
{
	// Gets real player index from native cell 
	int client = GetNativeCell(1);

	// Return the value 
	return gClientData[client].LastPurchase;
}

/**
 * @brief Sets the player amount of money spending.
 *
 * @note native void ZP_SetClientLastPurchase(client, iD);
 **/
public int API_SetClientLastPurchase(Handle hPlugin, int iNumParams)
{
	// Gets real player index from native cell 
	int client = GetNativeCell(1);

	// Sets purchase for the client
	gClientData[client].LastPurchase = GetNativeCell(2);
}

/*
 * Stocks account API.
 */

/**
 * @brief Sets a client account value.
 * 
 * @param client            The client index.
 * @param iMoney            The money amount.
 **/
void AccountSetClientCash(int client, int iMoney)
{
	// Call forward
	gForwardData._OnClientMoney(client, iMoney);
	
	// If value below 0, then set to 0
	if (iMoney < 0)
	{
		iMoney = 0;
	}

	// Sets money
	gClientData[client].Money = iMoney;
	
	// Update money in the database
	DataBaseOnClientUpdate(client, ColumnType_Money);

	// If account disabled, then stop
	if (gCvarList.ACCOUNT_MONEY.IntValue != AccountType_Classic)
	{
		return;
	}
	
	// Update client money
	AccountSetMoney(client, gClientData[client].Money);
}

/**
 * @brief Sets the money on a client.
 *
 * @param client            The client index.
 * @param iMoney            The money amount.
 **/
void AccountSetMoney(int client, int iMoney)
{
	SetEntProp(client, Prop_Send, "m_iAccount", iMoney);
}

/*
 * Menu account API.
 */

/**
 * @brief Creates the donates menu.
 *
 * @param client            The client index.
 * @param iMoney            The money amount.   
 * @param flCommision       The commission amount.
 **/
void AccountMenu(int client, int iMoney, float flCommision) 
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
	Menu hMenu = new Menu(AccountMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);

	// Validate commission
	if (flCommision <= 0.0)
	{
		// Sets donate title
		hMenu.SetTitle("%t", "donate", iMoney, "money");
	}
	else
	{
		// Sets commission title
		FormatEx(sInfo, sizeof(sInfo), "%.2f%", flCommision);
		hMenu.SetTitle("%t", "commission", iMoney, "money", sInfo);
	}

	// Format some chars for showing in menu
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "increase");
	
	// Show increase option
	FormatEx(sInfo, sizeof(sInfo), "-2 %d %f", iMoney, flCommision);
	hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney <= gClientData[client].Money));

	// Format some chars for showing in menu
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "decrease");
	
	// Show decrease option
	FormatEx(sInfo, sizeof(sInfo), "-1 %d %f", iMoney, flCommision);
	hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney > iBet));
	
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
public int AccountMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				return;
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
					AccountMenu(client, iMoney - gCvarList.ACCOUNT_BET.IntValue, flCommision + gCvarList.ACCOUNT_DECREASE.FloatValue);
				}
				
				// Client hit 'Increase' button
				case -2  :
				{
					AccountMenu(client, iMoney + gCvarList.ACCOUNT_BET.IntValue, flCommision - gCvarList.ACCOUNT_DECREASE.FloatValue);
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
							TranslationPrintToChatAll("donate info", sInfo[0], iAmount, "money", sInfo[1]);
						}
					}
					else
					{

						// Show block info
						TranslationPrintHintText(client, "selecting target block");
					
						// Emit error sound
						ClientCommand(client, "play buttons/button10.wav"); 
					}
				}
			}
		}
	}
}