/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          extraitems.cpp
 *  Type:          Manager 
 *  Description:   Extra Items generator.
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

/**
 * Number of max valid extra items.
 **/
#define ExtraItemMax 32

/**
 * Array handle to store extra item native data.
 **/
ArrayList arrayExtraItems;
 
/**
 * Item native data indexes.
 **/
enum
{
    EXTRAITEMS_DATA_NAME,
    EXTRAITEMS_DATA_COST,
    EXTRAITEMS_DATA_LEVEL,
    EXTRAITEMS_DATA_ONLINE,
    EXTRAITEMS_DATA_LIMIT
}

/**
 * Array to store the item limit to player.
 **/
int gExtraBuyLimit[MAXPLAYERS+1][ExtraItemMax];

/**
 * Initialization of extra items. 
 **/
void ExtraItemsLoad(/*void*/)
{
    // No extra items?
    if(arrayExtraItems == INVALID_HANDLE)
    {
        LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Extraitems, "Extra Items Validation", "No extra items loaded");
    }
}

/**
 * Creates commands for extra items module. Called when commands are created.
 **/
void ExtraItemsOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zitemmenu", ExtraItemsCommandCatched, "Open the extra items menu.");
}

/**
 * Handles the <!zitemmenu> command. Open the extra items menu.
 * 
 * @param clientIndex        The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ExtraItemsCommandCatched(int clientIndex, int iArguments)
{
    // Open the extra items menu
    ExtraItemsMenu(clientIndex);
}

/*
 * Extra items natives API.
 */

/**
 * Give the extra item to the client.
 *
 * native bool ZP_GiveClientExtraItem(clientIndex, iD);
 **/
public int API_GiveClientExtraItem(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Player doens't exist (%d)", clientIndex);
        return -1;
    }
    
    // Gets item index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }

    // Call forward
    Action resultHandle = API_OnClientValidateExtraItem(clientIndex, iD);

    // Validate handle
    if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
    {
        // Call forward
        API_OnClientBuyExtraItem(clientIndex, iD); /// Buy item
        return true;
    }
    
    // Return on unsuccess
    return false;
}

/**
 * Sets the buy limit of the current player's item.
 *
 * native void ZP_SetClientExtraItemLimit(clientIndex, iD, limit);
 **/
public int API_SetClientExtraItemLimit(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Player doens't exist (%d)", clientIndex);
        return -1;
    }
    
    // Gets item index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }
    
    // Sets buy limit of the current player's item
    ItemsSetLimits(clientIndex, iD, GetNativeCell(3));
    
    // Return on success
    return iD;
}

/**
 * Gets the buy limit of the current player's item.
 *
 * native int ZP_GetClientExtraItemLimit(clientIndex, iD);
 **/
public int API_GetClientExtraItemLimit(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Player doens't exist (%d)", clientIndex);
        return -1;
    }
    
    // Gets item index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }
    
    // Return buy limit of the current player's item
    return ItemsGetLimits(clientIndex, iD);
}
 
/**
 * Load extra items from other plugin.
 *
 * native int ZP_RegisterExtraItem(name, cost, team, level, online, limit)
 **/
public int API_RegisterExtraItem(Handle isPlugin, int iNumParams)
{
    // If array hasn't been created, then create
    if(arrayExtraItems == INVALID_HANDLE)
    {
        // Create array in handle
        arrayExtraItems = CreateArray(ExtraItemMax);
    }

    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);
    
    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Can't register extra item with an empty name");
        return -1;
    }
    
    // Gets extra items amount
    int iCount = GetArraySize(arrayExtraItems);

    // Maximum amout of extra items
    if(iCount >= ExtraItemMax)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "ExtraItems Validation",  "Maximum number of extra items reached (%d). Skipping other items.", ExtraItemMax);
        return -1;
    }

    // Initialize char
    char sItemBuffer[SMALL_LINE_LENGTH];

    // Initialize array block
    ArrayList arrayExtraItem = CreateArray(ExtraItemMax);
    
    // Push native data into array
    GetNativeString(1, sItemBuffer, sizeof(sItemBuffer)); 
    arrayExtraItem.PushString(sItemBuffer);    // Index: 0
    arrayExtraItem.Push(GetNativeCell(2));     // Index: 1
    arrayExtraItem.Push(GetNativeCell(3));     // Index: 2
    arrayExtraItem.Push(GetNativeCell(4));     // Index: 3
    arrayExtraItem.Push(GetNativeCell(5));     // Index: 4
    
    // Store this handle in the main array
    arrayExtraItems.Push(arrayExtraItem);
    
    // Return id under which we registered the item
    return GetArraySize(arrayExtraItems)-1;
}

/**
 * Gets the amount of all extra items.
 *
 * native int ZP_GetNumberExtraItem();
 **/
public int API_GetNumberExtraItem(Handle isPlugin, int iNumParams)
{
    return GetArraySize(arrayExtraItems);
}

/**
 * Gets the name of a extra item at a given index.
 *
 * native void ZP_GetExtraItemName(iD, sName, maxLen);
 **/
public int API_GetExtraItemName(Handle isPlugin, int iNumParams)
{
    // Gets item index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    ItemsGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the cost of the extra item.
 *
 * native int ZP_GetExtraItemCost(iD);
 **/
public int API_GetExtraItemCost(Handle isPlugin, int iNumParams)
{
    // Gets item index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ItemsGetCost(iD);
}

/**
 * Gets the level of the extra item.
 *
 * native int ZP_GetExtraItemLevel(iD);
 **/
public int API_GetExtraItemLevel(Handle isPlugin, int iNumParams)
{
    // Gets item index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ItemsGetLevel(iD);
}

/**
 * Gets the online of the extra item.
 *
 * native int ZP_GetExtraItemOnline(iD);
 **/
public int API_GetExtraItemOnline(Handle isPlugin, int iNumParams)
{
    // Gets item index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ItemsGetOnline(iD);
}

/**
 * Gets the limit of the extra item.
 *
 * native int ZP_GetExtraItemLimit(iD);
 **/
public int API_GetExtraItemLimit(Handle isPlugin, int iNumParams)
{
    // Gets item index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ItemsGetLimit(iD);
}

/**
 * Print the info about the extra item.
 *
 * native void ZP_PrintExtraItemInfo(clientIndex, iD);
 **/
public int API_PrintExtraItemInfo(Handle isPlugin, int iNumParams)
{
    // If help messages disable, then stop 
    if(!gCvarList[CVAR_MESSAGES_HELP].BoolValue)
    {
        return -1;
    }
    
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Player doens't exist (%d)", clientIndex);
        return -1;
    }
    
    // Gets item index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= GetArraySize(arrayExtraItems))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Extraitems, "Native Validation", "Invalid the item index (%d)", iD);
        return -1;
    }
    
    // Gets extra item name
    static char sItemName[SMALL_LINE_LENGTH];
    ItemsGetName(iD, sItemName, sizeof(sItemName));

    // Gets client name
    static char sClientName[SMALL_LINE_LENGTH];
    GetClientName(clientIndex, sClientName, sizeof(sClientName));
    
    // Show message of successful buying
    TranslationPrintToChatAll("Buy extraitem", sClientName, sItemName);
    
    // Return on success
    return sizeof(sClientName);
}

/*
 * Extra items data reading API.
 */

/**
 * Gets the name of a item at a given index.
 *
 * @param iD                The item index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ItemsGetName(int iD, char[] sName, int iMaxLen)
{
    // Gets array handle of extra item at given index
    ArrayList arrayExtraItem = arrayExtraItems.Get(iD);

    // Gets extra item name
    arrayExtraItem.GetString(EXTRAITEMS_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the price of ammo for the item.
 *
 * @param iD                The item index.
 * @return                  The ammo price.    
 **/
stock int ItemsGetCost(int iD)
{
    // Gets array handle of extra item at given index
    ArrayList arrayExtraItem = arrayExtraItems.Get(iD);

    // Gets extra item cost
    return arrayExtraItem.Get(EXTRAITEMS_DATA_COST);
}

/**
 * Gets the level for the item.
 *
 * @param iD                The item index.
 * @return                  The level value.    
 **/
stock int ItemsGetLevel(int iD)
{
    // Gets array handle of extra item at given index
    ArrayList arrayExtraItem = arrayExtraItems.Get(iD);

    // Gets extra item level
    return arrayExtraItem.Get(EXTRAITEMS_DATA_LEVEL);
}

/**
 * Gets the online for the item.
 *
 * @param iD                The item index.
 * @return                  The online value.    
 **/
stock int ItemsGetOnline(int iD)
{
    // Gets array handle of extra item at given index
    ArrayList arrayExtraItem = arrayExtraItems.Get(iD);

    // Gets extra item online
    return arrayExtraItem.Get(EXTRAITEMS_DATA_ONLINE);
}

/**
 * Gets the limit for the item.
 * @param iD                The item index.
 * @return                  The limit value.    
 **/
stock int ItemsGetLimit(int iD)
{
    // Gets array handle of extra item at given index
    ArrayList arrayExtraItem = arrayExtraItems.Get(iD);

    // Gets extra item limit
    return arrayExtraItem.Get(EXTRAITEMS_DATA_LIMIT);
}

/**
 * Remove the buy limit of the all client's items.
 *
 * @param clientIndex       The client index.
 **/
stock void ItemsRemoveLimits(int clientIndex)
{
    // If array hasn't been created, then skip
    if(arrayExtraItems != INVALID_HANDLE)
    {
        // Remove all extraitems limit
        for(int i = 0; i < GetArraySize(arrayExtraItems); i++)
        {
            gExtraBuyLimit[clientIndex][i] = 0;
        }
    }
}

/**
 * Sets the buy limit of the current client's item.
 *
 * @param clientIndex       The client index.
 * @param iD                The item index.
 * @param nLimit            The limit value.    
 **/
stock void ItemsSetLimits(int clientIndex, int iD, int nLimit)
{
    // Sets buy limit for the client
    gExtraBuyLimit[clientIndex][iD] = nLimit;
}

/**
 * Gets the buy limit of the current client's item.
 *
 * @param clientIndex       The client index.
 * @param iD                The item index.
 **/
stock int ItemsGetLimits(int clientIndex, int iD)
{
    // Gets buy limit for the client
    return gExtraBuyLimit[clientIndex][iD];
}

/*
 * Stocks extra items API.
 */
 
/**
 * Create the extra items menu.
 *  
 * @param clientIndex        The client index.
 **/ 
void ExtraItemsMenu(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // Initialize chars
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sName[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];

    // Create extra items menu handle
    Menu hMenu = CreateMenu(ExtraItemsSlots);

    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "Buy extraitems");
    
    // Initialize forward
    Action resultHandle;
    
    // i = Extra item number
    int iCount = GetArraySize(arrayExtraItems);
    for(int i = 0; i < iCount; i++)
    {
        // Call forward
        resultHandle = API_OnClientValidateExtraItem(clientIndex, i);
        
        // Validate handle
        if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
        {
            // Gets extra item name
            ItemsGetName(i, sName, sizeof(sName));
            if(!IsCharUpper(sName[0]) && !IsCharNumeric(sName[0])) sName[0] = CharToUpper(sName[0]);
            
            // Format some chars for showing in menu
            Format(sBuffer, sizeof(sBuffer), "%t    %t", sName, "Ammopacks", ItemsGetCost(i));

            // Show option
            IntToString(i, sInfo, sizeof(sInfo));
            hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(gClientData[clientIndex][Client_Level] < ItemsGetLevel(i) || fnGetPlaying() < ItemsGetOnline(i) || (ItemsGetLimit(i) != 0 && ItemsGetLimit(i) <= ItemsGetLimits(clientIndex, i) || gClientData[clientIndex][Client_AmmoPacks] < ItemsGetCost(i)) ? false : true));
        }
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iCount)
    {
        static char sEmpty[SMALL_LINE_LENGTH];
        Format(sEmpty, sizeof(sEmpty), "%t", "Empty");

        hMenu.AddItem("empty", sEmpty, ITEMDRAW_DISABLED);
    }
    
    // Sets exit and back button
    hMenu.ExitBackButton = true;
    
    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the extra items menu, and handles it.
 *  
 * @param hMenu              The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot              The slot index selected (starting from 0).
 **/ 
public int ExtraItemsSlots(Menu hMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            delete hMenu;
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Open main menu back
                MenuMain(clientIndex);
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
            if(gServerData[Server_RoundEnd] || gClientData[clientIndex][Client_Nemesis] || gClientData[clientIndex][Client_Survivor])
            {
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }

            // Initialize char
            static char sItemName[SMALL_LINE_LENGTH];

            // Gets ID of the extra item
            hMenu.GetItem(mSlot, sItemName, sizeof(sItemName));
            int iD = StringToInt(sItemName);
            
            // Call forward
            Action resultHandle = API_OnClientValidateExtraItem(clientIndex, iD);

            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Call forward
                API_OnClientBuyExtraItem(clientIndex, iD); /// Buy item
        
                // If help messages enable, then show 
                if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
                {
                    // Gets extra item name
                    ItemsGetName(iD, sItemName, sizeof(sItemName));

                    // Gets client name
                    static char sClientName[SMALL_LINE_LENGTH];
                    GetClientName(clientIndex, sClientName, sizeof(sClientName));

                    // Show message of successful buying
                    TranslationPrintToChatAll("Buy extraitem", sClientName, sItemName);
                }
                
                // If item has a cost
                if(ItemsGetCost(iD))
                {
                    // Remove ammo and store it for returning if player will be first zombie
                    ToolsSetClientCash(clientIndex, gClientData[clientIndex][Client_AmmoPacks] - ItemsGetCost(iD));
                    gClientData[clientIndex][Client_LastBoughtAmount] += ItemsGetCost(iD);
                    
                    // If item has a limit
                    if(ItemsGetLimit(iD))
                    {
                        // Increment count
                        ItemsSetLimits(clientIndex, iD, ItemsGetLimits(clientIndex, iD) + 1);
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
