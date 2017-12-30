/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin MenuShop =
{
	name        	= "[ZP] Menu: Shop",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Weapons and extraitems menu generator",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * Number of valid player slots.
 **/
enum
{ 
	WEAPON_SLOT_INVALID = -1, 		/** Used as return value when an weapon doens't exist. */
	
	WEAPON_SLOT_PRIMARY, 			/** Primary slot */
	WEAPON_SLOT_SECONDARY, 			/** Secondary slot */
	WEAPON_SLOT_MELEE, 				/** Melee slot */
	WEAPON_SLOT_EQUEPMENT			/** Equepment slot */
};

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Load translations phrases used by plugin
	LoadTranslations("zombieplague.phrases");
	
	// Create a commands
	RegConsoleCmd("zshopmenu", Command_ShopMenu, "Open the main shop menu.");
	RegConsoleCmd("zsubshopmenu", Command_SubShopMenu, "Open the sub shop menu.");
}

/**
 * Handles the zshopmenu command. Open the main shop menu.
 * 
 * @param clientIndex		The client index.
 * @param iArguments		The number of arguments that were in the argument string.
 **/ 
public Action Command_ShopMenu(int clientIndex, int iArguments)
{
	// Open an admin menu
	MenuMainShop(clientIndex);
}

/**
 * Handles the zsubshopmenu command. Open the sub main shop menu.
 * 
 * @param clientIndex		The client index.
 * @param iArguments		The number of arguments that were in the argument string.
 **/ 
public Action Command_SubShopMenu(int clientIndex, int iArguments)
{
	// Open an admin menu
	MenuSubShop(clientIndex);
}

/*
 * Shop menu
 */
  
/**
 * Create a shop menu.
 *
 * @param clientIndex		The client index.
 **/
void MenuMainShop(int clientIndex) 
{
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// Sets the language to target
	SetGlobalTransTarget(clientIndex);

	// Initialize menu
	Menu iMenu = CreateMenu(MenuShopSlots);

	// Set title
	SetMenuTitle(iMenu, "%t", "@Buy weapons");
	
	// Initialize char
	static char sBuffer[NORMAL_LINE_LENGTH];

	// Show pistol list
	Format(sBuffer, sizeof(sBuffer), "%t", "Buy pistols");
	AddMenuItem(iMenu, "1", sBuffer);
	
	// Show shotgun list
	Format(sBuffer, sizeof(sBuffer), "%t", "Buy shothuns");
	AddMenuItem(iMenu, "2", sBuffer);
	
	// Show rifle list
	Format(sBuffer, sizeof(sBuffer), "%t", "Buy rifles");
	AddMenuItem(iMenu, "3", sBuffer);
	
	// Show sniper list
	Format(sBuffer, sizeof(sBuffer), "%t", "Buy snipers");
	AddMenuItem(iMenu, "4", sBuffer);
	
	// Show machinegun list
	Format(sBuffer, sizeof(sBuffer), "%t", "Buy machinehuns");
	AddMenuItem(iMenu, "5", sBuffer);

	// Set exit and back button
	SetMenuExitBackButton(iMenu, true);

	// Set options and display it
	SetMenuOptionFlags(iMenu, MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK);
	DisplayMenu(iMenu, clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the shop menu, and handles it.
 *  
 * @param iMenu				The handle of the menu being used.
 * @param mAction			The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex		The client index.
 * @param mSlot				The slot index selected (starting from 0).
 **/ 
public int MenuShopSlots(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
	// Switch the menu action
	switch(mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			CloseHandle(iMenu);
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if(mSlot == MenuCancel_ExitBack)
			{
				// Open main menu back
				if(IsPlayerExist(clientIndex, false)) FakeClientCommand(clientIndex, "zmainmenu");
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Create sub menu 
			MenuSubShop(clientIndex, mSlot);
		}
	}
}

/*
 * Extraitem and weapon sub menu
 */

/**
 * Used for creating sub part of weapons menu and extraitems menu.
 *  
 * @param clientIndex		The client index.
 * @param mSlot				The slot index selected. (starting from 0)
 **/ 
void MenuSubShop(int clientIndex, int mSlot = -1)
{
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// If client is survivor or nemesis, then stop 
	if(ZP_IsPlayerSurvivor(clientIndex) || ZP_IsPlayerNemesis(clientIndex))
	{
		// Emit error sound
		ClientCommand(clientIndex, "play buttons/button11.wav");
		return;
	}
	
	// Initialize chars
	static char sBuffer[BIG_LINE_LENGTH];
	static char sName[NORMAL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	// Initialize menu
	Menu iMenu;
	
	// Sets the language to target
	SetGlobalTransTarget(clientIndex);
	
	// Amount of cases
	int iCount;
	
	// Extra items menu
	if(mSlot == -1 || ZP_IsPlayerZombie(clientIndex))	
	{
		// Create extra items menu handle
		iMenu = CreateMenu(MenuItemsSlots);

		// Set title
		SetMenuTitle(iMenu, "%t", "@Buy extraitems");
		
		// i = Extra item number
		iCount = ZP_GetNumberExtraItem();
		for(int i = 0; i < iCount; i++)
		{
			// Skip some extra items, if team is not equal
			if(ZP_IsPlayerZombie(clientIndex) && !ZP_GetExtraItemTeam(i) || ZP_IsPlayerHuman(clientIndex) && ZP_GetExtraItemTeam(i))
				continue;
		
			// Get extra item name
			ZP_GetExtraItemName(i, sName, sizeof(sName));
			if(!IsCharUpper(sName[0]) && !IsCharNumeric(sName[0])) sName[0] = CharToUpper(sName[0]);
			
			// Format some chars for showing in menu
			// Is string contains @, name will be translate
			Format(sBuffer, sizeof(sBuffer), (sName[0] == '@') ? "%t    %t" : "%s    %t", sName, "Ammopacks", ZP_GetExtraItemCost(i));

			// Show option
			IntToString(i, sInfo, sizeof(sInfo));
			AddMenuItem(iMenu, sInfo, sBuffer, MenuGetItemDraw(ZP_GetClientLevel(clientIndex) < ZP_GetExtraItemLevel(i) || ZP_GetAliveAmount() < ZP_GetExtraItemOnline(i) || (ZP_GetExtraItemLimit(i) != 0 && ZP_GetExtraItemLimit(i) <= ZP_GetClientExtraItemLimit(clientIndex, i)) || ZP_GetClientAmmoPack(clientIndex) < ZP_GetExtraItemCost(i)) ? false : true);
		}
	}
	// Weapons menu
	else
	{
		// Create menu handle
		iMenu = CreateMenu(MenuWeaponsSlots);
		
		// Set title
		SetMenuTitle(iMenu, "%t", "@Buy weapons");
		
		// i = Weapon number number
		iCount = ZP_GetNumberWeapon();
		for(int i = 0; i < iCount; i++)
		{
			// Skip some weapons, if slot isn't equal
			if(ZP_GetWeaponSlot(i) != mSlot)
				continue;
		
			// Get weapon name
			ZP_GetWeaponName(i, sName, sizeof(sName));
			if(!IsCharUpper(sName[0]) && !IsCharNumeric(sName[0])) sName[0] = CharToUpper(sName[0]);
			
			// Format some chars for showing in menu
			Format(sBuffer, sizeof(sBuffer), (ZP_GetWeaponCost(i)) ? "%s    %t" : "%s", sName, "Ammopacks", ZP_GetWeaponCost(i));

			// Show option
			IntToString(i, sInfo, sizeof(sInfo));
			AddMenuItem(iMenu, sInfo, sBuffer, MenuGetItemDraw((ZP_GetClientLevel(clientIndex) < ZP_GetWeaponLevel(i) || ZP_GetAliveAmount() < ZP_GetWeaponOnline(i) || ZP_GetClientAmmoPack(clientIndex) < ZP_GetWeaponCost(i)) ? false : true));
		}
	}
	
	// If there are no cases, add an "(Empty)" line
	if(!iCount)
	{
		static char sEmpty[SMALL_LINE_LENGTH];
		Format(sEmpty, sizeof(sEmpty), "%t", "Empty");

		AddMenuItem(iMenu, "empty", sEmpty, ITEMDRAW_DISABLED);
	}
	
	// Set exit and back button
	SetMenuExitBackButton(iMenu, true);
	
	// Set options and display it
	SetMenuOptionFlags(iMenu, MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK);
	DisplayMenu(iMenu, clientIndex, MENU_TIME_FOREVER);
}

/**
 * Called when client selects option in the extra items menu, and handles it.
 *  
 * @param iMenu				The handle of the menu being used.
 * @param mAction			The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex		The client index.
 * @param mSlot				The slot index selected (starting from 0).
 **/ 
public int MenuItemsSlots(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
	// Switch the menu action
	switch(mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			CloseHandle(iMenu);
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if(mSlot == MenuCancel_ExitBack)
			{
				// Open main menu back
				if(IsPlayerExist(clientIndex, false)) FakeClientCommand(clientIndex, "zmainmenu");
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if(!IsPlayerExist(clientIndex))
			{
				return;
			}
			
			// If round ended, then stop
			// If client is survivor or nemesis, then stop
			if(ZP_GetRoundState(SERVER_ROUND_END) || ZP_IsPlayerSurvivor(clientIndex) || ZP_IsPlayerNemesis(clientIndex))
			{
				// Emit error sound
				ClientCommand(clientIndex, "play buttons/button11.wav");	
				return;
			}

			// Initialize char
			static char sItemName[NORMAL_LINE_LENGTH];

			// Get ID of the extra item
			GetMenuItem(iMenu, mSlot, sItemName, sizeof(sItemName));
			int iD = StringToInt(sItemName);
			
			// Validate, that buying was successful
			if(ZP_GiveClientExtraItem(clientIndex, iD))
			{
				// Show message of successful buying
				ZP_PrintExtraItemInfo(clientIndex, iD);
				
				// If item has a cost
				if(ZP_GetExtraItemCost(iD))
				{
					// Remove ammo and store it for returning if player will be first zombie
					ZP_SetClientAmmoPack(clientIndex, ZP_GetClientAmmoPack(clientIndex) - ZP_GetExtraItemCost(iD));
					ZP_SetClientLastBought(clientIndex, ZP_GetClientLastBought(clientIndex) + ZP_GetExtraItemCost(iD));
					
					// If item has a limit
					if(ZP_GetExtraItemLimit(iD))
					{
						// Increment count
						ZP_SetClientExtraItemLimit(clientIndex, iD, ZP_GetClientExtraItemLimit(clientIndex, iD) + 1);
					}
				}
			}
			else
			{
				// Emit error sound
				ClientCommand(clientIndex, "play buttons/button11.wav");	
			}
		}
	}
}

/**
 * Called when client selects option in the shop menu, and handles it.
 *  
 * @param iMenu				The handle of the menu being used.
 * @param mAction			The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex		The client index.
 * @param mSlot				The slot index selected (starting from 0).
 **/ 
public int MenuWeaponsSlots(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
	// Switch the menu action
	switch(mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			CloseHandle(iMenu);
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if(mSlot == MenuCancel_ExitBack)
			{
				// Open weapon menu back
				MenuMainShop(clientIndex);
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if(!IsPlayerExist(clientIndex))
			{
				return;
			}
			
			// If client is survivor or zombie, then stop
			if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
			{
				// Emit error sound
				ClientCommand(clientIndex, "play buttons/button11.wav");	
				return;
			}
			
			// Initialize char
			static char sWeaponEntity[SMALL_LINE_LENGTH];

			// Get ID of the weapon
			GetMenuItem(iMenu, mSlot, sWeaponEntity, sizeof(sWeaponEntity));
			int iD = StringToInt(sWeaponEntity);

			// Get weapon alias
			ZP_GetWeaponEntity(iD, sWeaponEntity, sizeof(sWeaponEntity));
			
			// If client have this weapon
			if(IsPlayerHasWeapon(clientIndex, sWeaponEntity))
			{
				// Emit error sound
				ClientCommand(clientIndex, "play buttons/button11.wav");	
				return;
			}
			
			// Force client to drop weapon
			if(!StrEqual(sWeaponEntity, "weapon_taser"))
			{
				WeaponsDrop(clientIndex, GetPlayerWeaponSlot(clientIndex, (!ZP_GetWeaponSlot(iD)) ? WEAPON_SLOT_SECONDARY : WEAPON_SLOT_PRIMARY));
			}
			
			// Give weapon for the player
			GivePlayerItem(clientIndex, sWeaponEntity);
			FakeClientCommandEx(clientIndex, "use %s", sWeaponEntity);

			// If weapon has a cost
			if(ZP_GetWeaponCost(iD))
			{
				// Remove ammo and store it for returning if player will be first zombie
				ZP_SetClientAmmoPack(clientIndex, ZP_GetClientAmmoPack(clientIndex) - ZP_GetWeaponCost(iD));
				ZP_SetClientLastBought(clientIndex, ZP_GetClientLastBought(clientIndex) + ZP_GetWeaponCost(iD));
			}
		}
	}
}

/**
 * Drop weapon function.
 *
 * @param clientIndex		The client index.
 * @param weaponIndex		The weapon index.
 **/
void WeaponsDrop(int clientIndex, int weaponIndex)
{
	// If entity isn't valid, then stop
	if(!IsValidEdict(weaponIndex)) 
	{
		return;
	}
	
	// Get the owner of the weapon
	int ownerIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hOwnerEntity");

	// If owner index is different, so set it again
	if(ownerIndex != clientIndex) 
	{
		SetEntPropEnt(weaponIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
	}

	// Forces a player to drop weapon
	CS_DropWeapon(clientIndex, weaponIndex, false);
}

/**
 * Return itemdraw flag for radio menus.
 * 
 * @param menuCondition     If this is true, item will be drawn normally.
 **/
stock int MenuGetItemDraw(bool menuCondition)
{
    return menuCondition ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
}