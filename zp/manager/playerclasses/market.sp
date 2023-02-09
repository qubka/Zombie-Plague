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
	gCvarList.MARKET                  = FindConVar("zp_market");
	gCvarList.MARKET_BUYMENU          = FindConVar("zp_market_buymenu");
	gCvarList.MARKET_BUTTON           = FindConVar("zp_market_button");
	gCvarList.MARKET_REOPEN           = FindConVar("zp_market_reopen");
	gCvarList.MARKET_FAVORITES        = FindConVar("zp_market_favorites");
	gCvarList.MARKET_ZOMBIE_OPEN_ALL  = FindConVar("zp_market_zombie_open_all_menu");
	gCvarList.MARKET_HUMAN_OPEN_ALL   = FindConVar("zp_market_human_open_all_menu");
	gCvarList.MARKET_OFF_WHEN_STARTED = FindConVar("zp_market_off_menu_when_mode_started");
	gCvarList.MARKET_BUYTIME          = FindConVar("zp_market_buytime");

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
	// If module is disabled, then stop
	if (!gCvarList.MARKET.BoolValue)
	{
		return;
	}
	
	//
	if (gCvarList.MARKET_FAVORITES.BoolValue)
	{
		// Resets shopping cart for client
		MarketResetShoppingCart(client); 
		
		// Validate cart size
		if (bOpen && gClientData[client].DefaultCart.Length)
		{
			// Opens favorites menu
			MarketBuyMenu(client, MenuType_FavBuy);
		}
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
	// If module is disabled, then stop
	if (!gCvarList.MARKET.BoolValue)
	{
		return;
	}
	
	// Buying chance
	if (GetRandomInt(0, 10))
	{
		return
	} 

	// Buy random item
	MarketBuyItem(client, GetRandomInt(0, gServerData.ExtraItems.Length - 1), false);
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
 * @param sClassname        The weapon entity.
 **/
public Action CS_OnBuyCommand(int client, const char[] sClassname)
{
	// Emulate purchase of custom weapon
	if (gCvarList.MARKET_BUYMENU.BoolValue)
	{
		// Find the custom weapon id by an ent name (first available one)
		int iD = -1; gServerData.Entities.GetValue(sClassname, iD);
		if (iD != -1 && WeaponsHasAccessByType(client, iD))
		{
			// Gets weapon def index
			int iItem = view_as<int>(WeaponsGetDefIndex(iD));

			// If item has a cost
			int iCost = CS_GetWeaponPrice(client, CS_ItemDefIndexToID(iItem));
			if (iCost)
			{
				// Remove money and store it for returning if player will be first zombie
				AccountSetClientCash(client, gClientData[client].Money - iCost);
				gClientData[client].LastPurchase += iCost;
			}
			
			// Give weapon for the player
			WeaponsGive(client, iD);
			
			// If help messages enabled, then show info
			if (gCvarList.MESSAGES_WEAPON_INFO.BoolValue)
			{
				// Gets weapon info
				static char sInfo[SMALL_LINE_LENGTH];
				WeaponsGetInfo(iD, sInfo, sizeof(sInfo));
				
				// Show weapon personal info
				if (hasLength(sInfo)) TranslationPrintHintText(client, sInfo);
			}
		}
	}
	
	// Block buy
	return Plugin_Handled;
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

/**
 * @brief .
 * 
 * @param client            The client index.
 * @param iD                The item index.
 * @param bInfo             (Optional) Show personal info messages?
 * @return                  True on success, false otherwise.
 **/
bool MarketBuyItem(int client, int iD, bool bInfo = true)
{
	// Validate access
	if (!ItemsHasAccessByType(client, iD) || MarketBuyTimeExpired(client, ItemsGetSectionID(iD)) || MarketItemNotAvailable(client, iD)) 
	{
		return false;
	}
	
	// Call forward
	Action hResult;
	gForwardData._OnClientValidateExtraItem(client, iD, hResult);
	
	// Validate access
	if (hResult == Plugin_Stop || hResult == Plugin_Handled)
	{
		return false;
	}

	// Give weapon for the player (if exists)
	WeaponsGive(client, ItemsGetWeaponID(iD));

	// If item has a cost
	int iCost = ItemsGetCost(iD);
	if (iCost)
	{
		// Remove money and store it for returning if player will be first zombie
		AccountSetClientCash(client, gClientData[client].Money - iCost);
		gClientData[client].LastPurchase += iCost;
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
		static char sName[SMALL_LINE_LENGTH];
		ItemsGetName(iD, sName, sizeof(sName));

		// Show item buying info
		TranslationPrintToChatAll("info buy", sInfo, sName);
	}
	
	// If help messages enabled, then show info
	if (bInfo && gCvarList.MESSAGES_ITEM_INFO.BoolValue)
	{
		// Gets item info
		static char sInfo[SMALL_LINE_LENGTH];
		ItemsGetInfo(iD, sInfo, sizeof(sInfo));
		
		// Show item personal info
		if (hasLength(sInfo)) TranslationPrintHintText(client, sInfo);
	}

	// Call forward
	gForwardData._OnClientBuyExtraItem(client, iD); /// Buy item
	return true;
}

/**
 * @brief .
 * 
 * @param client            The client index.
 * @param iD                The item index.
 * @return                  True or false.
 **/
bool MarketItemNotAvailable(int client, int iD)
{
	// Gets item data
	static char sGroup[SMALL_LINE_LENGTH];
	ItemsGetGroup(iD, sGroup, sizeof(sGroup));
	
	// Validate access
	return (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) || (ItemsGetWeaponID(iD) != -1 && WeaponsFindByID(client, ItemsGetWeaponID(iD)) != -1) || gClientData[client].Level < ItemsGetLevel(iD) || fnGetPlaying() < ItemsGetOnline(iD) || (ItemsGetLimit(iD) && ItemsGetLimit(iD) <= ItemsGetLimits(client, iD)) || (ItemsGetCost(iD) && gClientData[client].Money < ItemsGetCost(iD));
}

/**
 * @brief .
 * 
 * @param client            The client index.
 * @param mSection          (Optional) The section index.
 * @return                  True or false.
 **/
bool MarketBuyTimeExpired(int client, int mSection = -1)
{
	// Skip last secion (equipment)
	if (mSection == gServerData.Sections.Length - 1)
	{
		return false;
	}
	
	// Validate the buy time except 
	return gCvarList.MARKET_OFF_WHEN_STARTED.BoolValue && gServerData.RoundStart && (GetGameTime() - gClientData[client].SpawnTime > gCvarList.MARKET_BUYTIME.FloatValue);
}
