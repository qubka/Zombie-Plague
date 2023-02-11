/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          account.sp
 *  Type:          Module 
 *  Description:   Handles client accounts. (cash)
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
 
/*
 * Load other accont modules
 */
#include "zp/playerclasses/donatemenu.sp"

/**
 * @brief Account module init function.
 **/
void AccountOnInit()
{
	if (gCvarList.ACCOUNT_MONEY.IntValue != AccountType_Custom)
	{
		if (gServerData.MapLoaded)
		{
			if (gServerData.AccountSync != null)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsPlayerExist(i))
					{
						delete gClientData[i].AccountTimer;
					}
				}
				
				delete gServerData.AccountSync;
			}
		}
	}
	
	if (gCvarList.ACCOUNT_MONEY.IntValue == AccountType_Custom)
	{
		if (gServerData.AccountSync == null)
		{
			gServerData.AccountSync = CreateHudSynchronizer();
		}
	}
	
	if (gServerData.MapLoaded)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsPlayerExist(i, false))
			{
				_call.AccountOnClientUpdate(i);
			}
		}
	}
}

/**
 * @brief Creates commands for account module.
 **/
void AccountOnCommandInit()
{
	RegAdminCmd("zp_money_give", AccountGiveOnCommandCatched, ADMFLAG_GENERIC, "Gives the money. Usage: zp_money_give <name> [amount]");
	RegConsoleCmd("zp_money_donate", AccountDonateOnCommandCatched, "Donates the money. Usage: zp_money_donate <name> [amount]");
	
	DonateMenuOnCommandInit();
}

/**
 * @brief Hook account cvar changes.
 **/
void AccountOnCvarInit()
{
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
	
	gCvarList.ACCOUNT_CASH_AWARD.IntValue   = 0;
	gCvarList.ACCOUNT_BUY_ANYWHERE.IntValue = 1;
	gCvarList.ACCOUNT_BUY_IMMUNITY.IntValue = 0;
	
	HookConVarChange(gCvarList.ACCOUNT_MONEY,        AccountOnCvarHook); 
	HookConVarChange(gCvarList.ACCOUNT_CASH_AWARD,   CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.ACCOUNT_BUY_ANYWHERE, CvarsUnlockOnCvarHook);
	HookConVarChange(gCvarList.ACCOUNT_BUY_IMMUNITY, CvarsLockOnCvarHook);
}

/**
 * Cvar hook callback (zp_account_money)
 * @brief Account module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void AccountOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	AccountOnInit();
}

/**
 * @brief Client has been spawned.
 * 
 * @param client            The client index.
 **/
void AccountOnClientSpawn(int client)
{
	_call.AccountOnClientUpdate(client);
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void AccountOnClientDeath(int client)
{
	_call.AccountOnClientUpdate(client);
}

/**
 * @brief Client has been changed class state. *(Post)
 *
 * @param userID            The user id.
 **/
public void AccountOnClientUpdate(int userID)
{
	int client = GetClientOfUserId(userID);

	if (client)
	{
		if (!IsFakeClient(client))
		{
			delete gClientData[client].AccountTimer;
			switch (gCvarList.ACCOUNT_MONEY.IntValue)
			{
				case AccountType_Disabled : 
				{
					gCvarList.ACCOUNT_CASH_AWARD.ReplicateToClient(client, "0");
				}
				
				case AccountType_Classic : 
				{
					gCvarList.ACCOUNT_CASH_AWARD.ReplicateToClient(client, "1");
					
					AccountSetMoney(client, gClientData[client].Money);
				}
				
				case AccountType_Custom : 
				{
					gCvarList.ACCOUNT_CASH_AWARD.ReplicateToClient(client, "0");
					
					gClientData[client].AccountTimer = CreateTimer(1.0, AccountOnClientHUD, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		
		gClientData[client].LastPurchase = 0;
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
	int client = GetClientOfUserId(userID);

	if (client)
	{
		int target = client;

		if (!IsPlayerAlive(client))
		{
			int iSpecMode = ToolsGetObserverMode(client);
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
			{
				return Plugin_Continue;
			}
			
			target = ToolsGetObserverTarget(client);
			
			if (!IsPlayerExist(target)) 
			{
				return Plugin_Continue;
			}
		}
		
		TranslationPrintHudText(gServerData.AccountSync, client, gCvarList.ACCOUNT_HUD_X.FloatValue, gCvarList.ACCOUNT_HUD_Y.FloatValue, 1.1, gCvarList.ACCOUNT_HUD_R.IntValue, gCvarList.ACCOUNT_HUD_G.IntValue, gCvarList.ACCOUNT_HUD_B.IntValue, gCvarList.ACCOUNT_HUD_A.IntValue, 0, 0.0, 0.0, 0.0, "info account", "money", gClientData[target].Money);

		return Plugin_Continue;
	}

	gClientData[client].AccountTimer = null;

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
	if (iArguments < 2)
	{
		TranslationReplyToCommand(client, "account give invalid args");
		return Plugin_Handled;
	}
	
	static char sArgument[SMALL_LINE_LENGTH];
	
	GetCmdArg(1, sArgument, sizeof(sArgument));
	int target = FindTarget(client, sArgument, true, false);

	if (target < 0)
	{
		return Plugin_Handled;
	}
	
	GetCmdArg(2, sArgument, sizeof(sArgument));
	
	int iMoney = StringToInt(sArgument);
	if (iMoney <= 0)
	{
		TranslationReplyToCommand(client, "account give invalid amount", iMoney);
		return Plugin_Handled;
	}

	AccountSetClientCash(target, gClientData[target].Money + iMoney);

	LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Account, "Command", "Admin \"%N\" gived money: \"%d\" to Player \"%N\"", client, iMoney, target);
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
	if (!IsPlayerExist(client, false))
	{
		return Plugin_Handled;
	}
	
	if (iArguments < 2)
	{
		TranslationReplyToCommand(client, "account donate invalid args");
		return Plugin_Handled;
	}
	
	static char sArgument[SMALL_LINE_LENGTH];
	
	GetCmdArg(1, sArgument, sizeof(sArgument));
	int target = FindTarget(client, sArgument, true, false);

	if (target < 0 || client == target)
	{
		return Plugin_Handled;
	}
	
	GetCmdArg(2, sArgument, sizeof(sArgument));
	
	int iMoney = StringToInt(sArgument); int iBet = gCvarList.ACCOUNT_BET.IntValue;
	if (iMoney <= 0 || iMoney > gClientData[client].Money || iMoney < iBet)
	{
		TranslationReplyToCommand(client, "account give invalid amount", iMoney);
		return Plugin_Handled;
	}

	int iAmount; float flCommision = gCvarList.ACCOUNT_COMMISION.FloatValue - ((float(iMoney) / float(iBet)) * gCvarList.ACCOUNT_DECREASE.FloatValue);
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
		static char sInfo[2][SMALL_LINE_LENGTH];
		GetClientName(client, sInfo[0], sizeof(sInfo[]));
		GetClientName(target, sInfo[1], sizeof(sInfo[]));
		
		TranslationPrintToChatAll("info donate", sInfo[0], iAmount, "money", sInfo[1]);
	}
	
	return Plugin_Handled;
}

/*
 * Account natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void AccountOnNativeInit()
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
	int client = GetNativeCell(1);

	return gClientData[client].Money;
}

/**
 * @brief Sets the player amount of money.
 *
 * @note native void ZP_SetClientMoney(client, iD);
 **/
public int API_SetClientMoney(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	AccountSetClientCash(client, GetNativeCell(2));
	return 0;
}

/**
 * @brief Gets the player amount of previous money spended.
 *
 * @note native int ZP_GetClientLastPurchase(client);
 **/
public int API_GetClientLastPurchase(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	return gClientData[client].LastPurchase;
}

/**
 * @brief Sets the player amount of money spending.
 *
 * @note native void ZP_SetClientLastPurchase(client, iD);
 **/
public int API_SetClientLastPurchase(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	gClientData[client].LastPurchase = GetNativeCell(2);
	return 0;
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
	gForwardData._OnClientMoney(client, iMoney);
	
	if (iMoney < 0)
	{
		iMoney = 0;
	}

	gClientData[client].Money = iMoney;
	
	DataBaseOnClientUpdate(client, ColumnType_Money);

	if (gCvarList.ACCOUNT_MONEY.IntValue != AccountType_Classic)
	{
		return;
	}
	
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
