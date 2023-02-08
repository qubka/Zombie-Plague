/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          market.sp
 *  Type:          Module
 *  Description:   Handles client market.
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
 * @section Number of valid buy menus.
 **/
enum /*MenuType*/
{
	/* Favorites */
	MenuType_FavEdit = -3,  /** Edit menu */  
	MenuType_FavAdd,        /** Add menu */
	MenuType_FavBuy,        /** Favorites menu */  
	
	/* Main */
	MenuType_Buy            /** Buymenu menu */
};
/**
 * @endsection
 **/ 
 
/*
 * Load other menus modules
 */
#include "zp/manager/playerclasses/marketmenu.sp"

/**
 * @brief Hook market cvar changes.
 **/
void MarketOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.MARKET                = FindConVar("zp_market");
	gCvarList.MARKET_BUYMENU        = FindConVar("zp_market_buymenu");
	gCvarList.MARKET_BUTTON         = FindConVar("zp_market_button");
	gCvarList.MARKET_REOPEN         = FindConVar("zp_market_reopen");
	gCvarList.MARKET_FAVORITES      = FindConVar("zp_market_favorites");

	// Hook cvars
	HookConVarChange(gCvarList.MARKET,        MarketOnCvarHook);
	HookConVarChange(gCvarList.MARKET_BUTTON, MarketOnCvarHook);

	// Load cvars
	MarketOnCvarLoad();
}

/**
 * @brief Creates commands for market module.
 **/
void MarketOnCommandInit(/*void*/)
{
	// Forward event to sub-modules
	MarketMenuOnCommandInit();
}

/**
 * @brief Load market listeners changes.
 **/
void MarketOnCvarLoad(/*void*/)
{
	// Validate buy button
	if (gCvarList.MARKET.BoolValue && gCvarList.MARKET_BUTTON.BoolValue)
	{
		// Hook commands
		AddCommandListener(MarketOnCommandListened, "open_buymenu");
	}
	else
	{
		// Unhook commands
		RemoveCommandListener2(MarketOnCommandListened, "open_buymenu");
	}
}

/*
 * Market main functions.
 */

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 * @param bOpen             True to open favorites menu, false to skip. 
 **/
void MarketOnClientUpdate(int client, bool bOpen = true)
{
	// Resets shopping cart for client
	MarketResetShoppingCart(client); 
	
	// Validate cart size
	if (bOpen && gClientData[client].DefaultCart.Length)
	{
		// Opens favorites menu
		MarketBuyMenu(client, MenuType_FavBuy);
	}
	
	// Validate real client
	if (gCvarList.MARKET_BUTTON.BoolValue && !IsFakeClient(client)) 
	{
		// Unlock VGUI buy panel
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "1");
	}
}

/**
 * @brief Fake client has been think.
 *
 * @param client            The client index.
 **/
void MarketOnFakeClientThink(int client)
{
	// Buying chance
	if (GetRandomInt(0, 10))
	{
		return
	} 

	// Get random item
	int iD = GetRandomInt(0, gServerData.ExtraItems.Length - 1);

	// If item/weapon is not available during gamemode, then stop
	if (gServerData.RoundStart && !(ItemsGetWeaponID(iD) != -1 ? ModesIsWeapon(gServerData.RoundMode) : ModesIsExtraItem(gServerData.RoundMode)) || (gServerData.RoundEnd && gClientData[client].Zombie))
	{
		return;
	}
		
	// Validate access
	if (!ItemsHasAccessByType(client, iD)) 
	{
		return;
	}
	
	// Call forward
	Action hResult;
	gForwardData._OnClientValidateExtraItem(client, iD, hResult);
	
	// Validate access
	if (hResult == Plugin_Stop || hResult == Plugin_Handled)
	{
		return;
	}
	
	// Gets extra item group
	static char sBuffer[SMALL_LINE_LENGTH];
	ItemsGetGroup(iD, sBuffer, sizeof(sBuffer));
	
	// Validate access
	if ((hasLength(sBuffer) && !IsPlayerInGroup(client, sBuffer)) || gClientData[client].Level < ItemsGetLevel(iD) || fnGetPlaying() < ItemsGetOnline(iD) || (ItemsGetLimit(iD) && ItemsGetLimit(iD) <= ItemsGetLimits(client, iD)) || (ItemsGetCost(iD) && gClientData[client].Money < ItemsGetCost(iD)))
	{
		return;
	}

	// Give weapon for the player
	WeaponsGive(client, iD);

	// If item has a cost
	if (ItemsGetCost(iD))
	{
		// Remove money and store it for returning if player will be first zombie
		AccountSetClientCash(client, gClientData[client].Money - ItemsGetCost(iD));
		gClientData[client].LastPurchase += ItemsGetCost(iD);
	}
	
	// If item has a limit
	if (ItemsGetLimit(iD))
	{
		// Increment count
		ItemsSetLimits(client, iD, ItemsGetLimits(client, iD) + 1);
	}
	
	// If help messages enabled, then show info
	if (gCvarList.MESSAGES_ITEM_ALL.BoolValue)
	{
		// Gets client name
		static char sInfo[SMALL_LINE_LENGTH];
		GetClientName(client, sInfo, sizeof(sInfo));

		// Gets extra item name
		ItemsGetName(iD, sBuffer, sizeof(sBuffer));

		// Show item buying info
		TranslationPrintToChatAll("info buy", sInfo, sBuffer);
	}
	
	// Call forward
	gForwardData._OnClientBuyExtraItem(client, iD); /// Buy item
}

/**
 * Cvar hook callback (zp_market_buymenu, zp_market_buymenu_*)
 * @brief Market module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void MarketOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	// Forward event to modules
	MarketOnCvarLoad();
}

/**
 * Listener command callback (open_buymenu)
 * @brief Buying of the weapons.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action MarketOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	// Validate real client
	if (IsPlayerExist(client, false) && !IsFakeClient(client))
	{
		// Lock VGUI buy panel
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "0");
		
		// Opens buy menu
		MarketMenu(client);
		
		// Sets timer for reseting command
		delete gClientData[client].BuyTimer;
		gClientData[client].BuyTimer = CreateTimer(1.0, MarketOnClientBuyMenu, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Block command
	return Plugin_Handled; 
}

/**
 * @brief Timer callback, auto-close a default buy menu.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action MarketOnClientBuyMenu(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Clear timer
	gClientData[client].BuyTimer = null;
	
	// Validate client
	if (client)
	{
		// Unlock VGUI buy panel
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "1");
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Called when a player attempts to purchase an item.
 * 
 * @param client            The client index.
 * @param sName             The weapon name.
 **/
public Action CS_OnBuyCommand(int client, const char[] sName)
{
	// Allow buy for humans if default buymenu is enable
	return gCvarList.MARKET_BUYMENU.BoolValue && !gClientData[client].Zombie ? Plugin_Continue : Plugin_Handled;
}

/*
 * Stocks market API.
 */

/**
 * @brief Resets the shopping history for a client.
 *
 * @param client            The client index.
 **/
void MarketResetShoppingCart(int client)
{
	// If array hasn't been created, then create
	if (gClientData[client].DefaultCart == null)
	{
		// Initialize a default cart array
		gClientData[client].DefaultCart = new ArrayList();
	}
	
	// Validate cart size
	if (gClientData[client].DefaultCart.Length)
	{
		// Recreate shopping cart array
		delete gClientData[client].ShoppingCart;
		gClientData[client].ShoppingCart = gClientData[client].DefaultCart.Clone();
	}
}

/**
 * @brief Clear the shopping history for a client.
 * 
 * @param client            The client index.
 **/
/*void MarketClearShoppingCart(int client)
{
	// If mode already started, then stop
	if (!gServerData.RoundNew)
	{
		return;
	}
	
	// If array hasn't been created, then stop
	if (gClientData[client].ShoppingCart != null)
	{
		// Clear out the array of all data
		gClientData[client].ShoppingCart.Clear();
	}
}*/