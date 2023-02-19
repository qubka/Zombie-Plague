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
#include "zp/playerclasses/marketmenu.sp"

/**
 * @brief Hook market cvar changes.
 **/
void MarketOnCvarInit()
{
	gCvarList.MARKET                  = FindConVar("zp_market");
	gCvarList.MARKET_BUYMENU          = FindConVar("zp_market_buymenu");
	gCvarList.MARKET_BUTTON           = FindConVar("zp_market_button");
	gCvarList.MARKET_REOPEN           = FindConVar("zp_market_reopen");
	gCvarList.MARKET_FAVORITES        = FindConVar("zp_market_favorites");
	gCvarList.MARKET_ZOMBIE_OPEN_ALL  = FindConVar("zp_market_zombie_open_all_menu");
	gCvarList.MARKET_HUMAN_OPEN_ALL   = FindConVar("zp_market_human_open_all_menu");
	gCvarList.MARKET_OFF_WHEN_STARTED = FindConVar("zp_market_off_menu_when_mode_started");
	gCvarList.MARKET_BUYTIME          = FindConVar("zp_market_buytime");

	HookConVarChange(gCvarList.MARKET,        MarketOnCvarHook);
	HookConVarChange(gCvarList.MARKET_BUTTON, MarketOnCvarHook);

	MarketOnCvarLoad();
}

/**
 * @brief Creates commands for market module.
 **/
void MarketOnCommandInit()
{
	MarketMenuOnCommandInit();
}

/**
 * @brief Load market listeners changes.
 **/
void MarketOnCvarLoad()
{
	if (gCvarList.MARKET.BoolValue && gCvarList.MARKET_BUTTON.BoolValue)
	{
		AddCommandListener(MarketOnCommandListened, "open_buymenu");
	}
	else
	{
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
	if (!gCvarList.MARKET.BoolValue)
	{
		return;
	}
	
	if (gCvarList.MARKET_FAVORITES.BoolValue)
	{
		MarketResetShoppingCart(client); 
		
		if (bOpen && gClientData[client].DefaultCart.Length)
		{
			MarketBuyMenu(client, MenuType_FavBuy);
		}
	}
	
	if (gCvarList.MARKET_BUTTON.BoolValue && !IsFakeClient(client)) 
	{
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
	if (!gCvarList.MARKET.BoolValue)
	{
		return;
	}
	
	if (GetRandomInt(0, 10))
	{
		return
	} 

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
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
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
	if (IsPlayerExist(client, false) && !IsFakeClient(client))
	{
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "0");
		
		MarketMenu(client);
		
		delete gClientData[client].BuyTimer;
		gClientData[client].BuyTimer = CreateTimer(1.0, MarketOnClientBuyMenu, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
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
	int client = GetClientOfUserId(userID);

	gClientData[client].BuyTimer = null;
	
	if (client)
	{
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "1");
	}
	
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
	if (gCvarList.MARKET_BUYMENU.BoolValue)
	{
		int iD = -1; gServerData.Entities.GetValue(sClassname, iD);
		if (iD != -1 && WeaponsHasAccessByType(client, iD))
		{
			int iItem = view_as<int>(WeaponsGetDefIndex(iD));

			int iCost = CS_GetWeaponPrice(client, CS_ItemDefIndexToID(iItem));
			if (iCost)
			{
				AccountSetClientCash(client, gClientData[client].Money - iCost);
				gClientData[client].LastPurchase += iCost;
			}
			
			WeaponsGive(client, iD);
			
			EmitSoundToClient(client, SOUND_BUY_ITEM, SOUND_FROM_PLAYER, SNDCHAN_ITEM);    
			
			if (gCvarList.MESSAGES_WEAPON_INFO.BoolValue)
			{
				static char sInfo[SMALL_LINE_LENGTH];
				WeaponsGetInfo(iD, sInfo, sizeof(sInfo));
				
				if (hasLength(sInfo)) TranslationPrintHintText(client, sInfo);
			}
		}
	}
	
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
	if (gClientData[client].DefaultCart == null)
	{
		gClientData[client].DefaultCart = new ArrayList();
	}
	
	if (gClientData[client].DefaultCart.Length)
	{
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
	if (!gServerData.RoundNew)
	{
		return;
	}
	
	if (gClientData[client].ShoppingCart != null)
	{
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
	if (!ItemsHasAccessByType(client, iD) || MarketIsBuyTimeExpired(client, ItemsGetSectionID(iD)) || !MarketIsItemAvailable(client, iD)) 
	{
		return false;
	}
	
	Action hResult;
	gForwardData._OnClientValidateExtraItem(client, iD, hResult);
	
	if (hResult == Plugin_Stop || hResult == Plugin_Handled)
	{
		return false;
	}

	WeaponsGive(client, ItemsGetWeaponID(iD));
	
	EmitSoundToClient(client, SOUND_BUY_ITEM, SOUND_FROM_PLAYER, SNDCHAN_ITEM);    

	int iCost = ItemsGetCost(iD);
	if (iCost)
	{
		AccountSetClientCash(client, gClientData[client].Money - iCost);
		gClientData[client].LastPurchase += iCost;
	}
	
	if (ItemsGetLimit(iD))
	{
		ItemsSetLimits(client, iD, ItemsGetLimits(client, iD) + 1);
	}
	
	if (ItemsGetFlags(iD) & ADMFLAG_CUSTOM1) // "o" - the item available once per map.
	{
		ItemsSetMapLimits(client, iD);
	}
	
	if (gCvarList.MESSAGES_ITEM_ALL.BoolValue)
	{
		static char sInfo[SMALL_LINE_LENGTH];
		GetClientName(client, sInfo, sizeof(sInfo));

		static char sName[SMALL_LINE_LENGTH];
		ItemsGetName(iD, sName, sizeof(sName));

		TranslationPrintToChatAll("info buy", sInfo, sName);
	}
	
	if (bInfo && gCvarList.MESSAGES_ITEM_INFO.BoolValue)
	{
		static char sInfo[SMALL_LINE_LENGTH];
		ItemsGetInfo(iD, sInfo, sizeof(sInfo));
		
		if (hasLength(sInfo)) TranslationPrintHintText(client, sInfo);
	}

	gForwardData._OnClientBuyExtraItem(client, iD); /// Buy item
	return true;
}

/**
 * @brief Checks that item purhase is available.
 * 
 * @param client            The client index.
 * @param iD                The item index.
 * @return                  True or false.
 **/
bool MarketIsItemAvailable(int client, int iD)
{
	if (ItemHasFlags(client, iD)) 
	{
		return false;
	}

	if (gCvarList.LEVEL_SYSTEM.BoolValue && gClientData[client].Level < ItemsGetLevel(iD))
	{
		return false;
	}

	int iCost = ItemsGetCost(iD);
	if (iCost && gClientData[client].Money < iCost)
	{
		return false;
	}

	int iLimit = ItemsGetLimit(iD);
	if (iLimit && iLimit <= ItemsGetLimits(client, iD))
	{
		return false;
	}

	int iOnline = ItemsGetOnline(iD);
	if (iOnline > 1 && fnGetPlaying() < iOnline)
	{
		return false;
	}
	
	int iWeapon = ItemsGetWeaponID(iD);
	if (iWeapon != -1 && WeaponsFindByID(client, iWeapon) != -1)
	{
		return false;
	}

	int iGroup = ItemsGetGroupFlags(iD);
	if (iGroup && !(iGroup & GetUserFlagBits(client)))
	{
		return false;
	}
	
	return true;
}

/**
 * @brief Checks that buytime is expired.
 * 
 * @param client            The client index.
 * @param iSection          (Optional) The section index.
 * @return                  True or false.
 **/
bool MarketIsBuyTimeExpired(int client, int iSection = -1)
{
	if (iSection == gServerData.Sections.Length - 1)
	{
		return false;
	}
	
	return gCvarList.MARKET_OFF_WHEN_STARTED.BoolValue && gServerData.RoundStart && (GetGameTime() - gClientData[client].SpawnTime > gCvarList.MARKET_BUYTIME.FloatValue);
}
