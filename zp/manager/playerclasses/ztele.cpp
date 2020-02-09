/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          ztele.cpp
 *  Type:          Module 
 *  Description:   ZTele handle functions.
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
 * @brief Creates commands for ZTele module.
 **/
void ZTeleOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegAdminCmd("zp_ztele_force", ZTeleForceOnCommandCatched, ADMFLAG_GENERIC, "Force ZTele on a client. Usage: zp_ztele_force <client>");
    RegConsoleCmd("ztele", ZTeleOnCommandCatched, "Teleport back to spawn.");
    RegConsoleCmd("zp_ztele_menu", ZTeleMenuOnCommandCatched, "Opens the teleport menu.");
}

/**
 * @brief Hook account cvar changes.
 **/
void ZTeleOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList.ZTELE_ESCAPE          = FindConVar("zp_ztele_escape");
    gCvarList.ZTELE_ZOMBIE          = FindConVar("zp_ztele_zombie");
    gCvarList.ZTELE_HUMAN           = FindConVar("zp_ztele_human");
    gCvarList.ZTELE_DELAY_ZOMBIE    = FindConVar("zp_ztele_delay_zombie");
    gCvarList.ZTELE_DELAY_HUMAN     = FindConVar("zp_ztele_delay_human");
    gCvarList.ZTELE_MAX_ZOMBIE      = FindConVar("zp_ztele_max_zombie");
    gCvarList.ZTELE_MAX_HUMAN       = FindConVar("zp_ztele_max_human");
    gCvarList.ZTELE_AUTOCANCEL      = FindConVar("zp_ztele_autocancel");
    gCvarList.ZTELE_AUTOCANCEL_DIST = FindConVar("zp_ztele_autocancel_distance");
}

/**
 * Console command callback (zp_ztele_force)
 * @brief Force ZSpawn on a client.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/
public Action ZTeleForceOnCommandCatched(int client, int iArguments)
{
    // If not enough arguments given, then stop
    if (iArguments < 1)
    {
        TranslationReplyToCommand(client, "ztele command force syntax");
        return Plugin_Handled;
    }
    
    // Initialize argument char
    static char sArgument[SMALL_LINE_LENGTH]; static char sName[SMALL_LINE_LENGTH]; int targets[MAXPLAYERS]; bool tn_is_ml;
    
    // Get targetname
    GetCmdArg(1, sArgument, sizeof(sArgument));
    
    // Find a target
    int iCount = ProcessTargetString(sArgument, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, sName, sizeof(sName), tn_is_ml);
    
    // Check if there was a problem finding a client
    if (iCount <= 0)
    {
        // Write error info
        TranslationReplyToCommand(client, "ztele invalid client");
        return Plugin_Handled;
    }
    
    // i = client index
    for (int i = 0; i < iCount; i++)
    {
        // Give client the item
        bool bSuccess = ZTeleClient(targets[i], true);
        
        // Tell admin the outcome of the command if only 1 client was targetted
        if (iCount == 1)
        {
            if (bSuccess)
            {
                TranslationReplyToCommand(client, "ztele command force successful", sName);
            }
            else
            {
                TranslationReplyToCommand(client, "ztele command force unsuccessful", sName);
            }
        }
        
        // Log action to game events
        LogEvent(true, LogType_Normal, LOG_GAME_EVENTS, LogModule_ZTele, "Force ZTele", "\"%L\" teleported \"%L\" to spawn.", client, targets[i]);
    }
    
    // Log action to game events
    return Plugin_Handled;
}

/**
 * Console command callback (ztele)
 * @brief Teleport back to spawn if you are stuck.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/
public Action ZTeleOnCommandCatched(int client, int iArguments)
{
    ZTeleClient(client);
    return Plugin_Handled;
}

/**
 * Console command callback (zp_ztele_menu)
 * @brief Opens the teleport menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZTeleMenuOnCommandCatched(int client, int iArguments)
{
    ZTeleMenu(client);
    return Plugin_Handled;
}

/*
 * Stocks ztele API.
 */

/**
 * @brief Teleports a client back to spawn if conditions are met.
 * 
 * @param client            The client index.
 * @param bForce            (Optional) True to force teleporting of the client, false to follow rules.
 * @return                  True if teleport was successful, false otherwise. 
 **/
bool ZTeleClient(int client, bool bForce = false)
{
    // Validate client
    if (!IsPlayerExist(client))
    {
        return false;
    }
    
    // If the cvar is disabled and the round are non-escape, then stop
    bool bZTeleEscape = gCvarList.ZTELE_ESCAPE.BoolValue;
    if (!bForce && bZTeleEscape && !ModesIsEscape(gServerData.RoundMode))
    {
        // Tell client that feature is restricted at this time
        TranslationPrintToChat(client, "ztele restricted escape");
        return false;
    }
    
    // Is client is zombie ?
    bool bInfect = gClientData[client].Zombie;

    // If zombie cvar is disabled and the client is a zombie, then stop
    bool bZTeleZombie = gCvarList.ZTELE_ZOMBIE.BoolValue;
    if (!bForce && bInfect && !bZTeleZombie)
    {
        // Tell client they must be human to use this feature
        TranslationPrintToChat(client, "ztele restricted zombie");
        return false;
    }

    // If zombie has spawned, get before value, get the after value otherwise
    // If the cvar is disabled and the client is a human, then stop
    bool bZTeleHuman = gCvarList.ZTELE_HUMAN.BoolValue;
    if (!bForce && !bInfect && !bZTeleHuman)
    {
        // Tell client that feature is restricted at this time
        TranslationPrintToChat(client, "ztele restricted human");
        return false;
    }
    
    // If the tele limit has been reached, then stop
    int iZTeleMax = bInfect ? gCvarList.ZTELE_MAX_ZOMBIE.IntValue : gCvarList.ZTELE_MAX_HUMAN.IntValue;
    if (!bForce && gClientData[client].TeleTimes >= iZTeleMax)
    {
        // Tell client that they have already reached their limit
        TranslationPrintToChat(client, "ztele max", iZTeleMax);
        return false;
    }
    
    // If teleport is already in progress, then stop
    if (gClientData[client].TeleTimer != null)
    {
        if (!bForce)
        {
            TranslationPrintToChat(client, "ztele in progress");
        }
        return false;
    }
    
    // If we are forcing, then teleport now and stop
    if (bForce)
    {
        // Teleport client to spawn
        SpawnTeleportToRespawn(client);
        return true;
    }
    
    // Get current location
    ToolsGetAbsOrigin(client, gClientData[client].TeleOrigin);
    
    // Set timeleft array to value of respective cvar
    gClientData[client].TeleCounter = bInfect ? gCvarList.ZTELE_DELAY_ZOMBIE.IntValue : gCvarList.ZTELE_DELAY_HUMAN.IntValue;
    if (gClientData[client].TeleCounter > 0)
    {
        // Tell client how much time is left until teleport
        TranslationPrintHintText(client, "ztele countdown", gClientData[client].TeleCounter);
        
        // Start timer
        gClientData[client].TeleTimer = CreateTimer(1.0, ZTeleOnClientCount, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
    }
    else
    {
        // Teleport player back on the spawn point
        SpawnTeleportToRespawn(client);
        
        // Increment teleport count
        gClientData[client].TeleTimes++;
        
        // If we're forcing the ZTele, then don't increment the count or print how many teleports they have used
        // Tell client they've been teleported
        TranslationPrintHintText(client, "ztele countdown end", gClientData[client].TeleTimes, iZTeleMax);
    }
    
    // Return true on success
    return true;
}

/**
 * @brief Timer callback, counts down teleport to the client.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ZTeleOnClientCount(Handle timer, int userID)
{
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID);

    // Validate client
    if (client)
    {
        // Validate auto cancel on movement
        if (gCvarList.ZTELE_AUTOCANCEL.BoolValue)
        {
            // Gets origin position
            static float vPosition[3];
            ToolsGetAbsOrigin(client, vPosition); 
            
            // Gets the distance from starting origin
            float flDistance = GetVectorDistance(vPosition, gClientData[client].TeleOrigin);
            float flAutoCancelDist = gCvarList.ZTELE_AUTOCANCEL_DIST.FloatValue;
  
            // Check if distance has been surpassed
            if (flDistance > flAutoCancelDist)
            {
                // Tell client teleport has been cancelled
                TranslationPrintHintText(client, "ztele autocancel centertext");
                TranslationPrintToChat(client, "ztele autocancel text", RoundToNearest(flAutoCancelDist));
                
                // Clear timer
                gClientData[client].TeleTimer = null;
                
                // Stop timer
                return Plugin_Stop;
            }
        }

        // Decrement time left
        gClientData[client].TeleCounter--;
        
        // Tell client how much time is left until teleport
        TranslationPrintHintText(client, "ztele countdown", gClientData[client].TeleCounter);
        
        // Time has expired
        if (gClientData[client].TeleCounter <= 0)
        {
            // Teleport player back on the spawn point
            SpawnTeleportToRespawn(client);
            
            // Increment teleport count
            gClientData[client].TeleTimes++;
            
            // Tell client spawn protection is over
            TranslationPrintHintText(client, "ztele countdown end", gClientData[client].TeleTimes, gClientData[client].Zombie ? gCvarList.ZTELE_MAX_ZOMBIE.IntValue : gCvarList.ZTELE_MAX_HUMAN.IntValue);
            
            // Clear timer
            gClientData[client].TeleTimer = null;
            
            // Destroy timer
            return Plugin_Stop;
        }
        
        // Allow timer
        return Plugin_Continue;
    }
    
    // Clear timer
    gClientData[client].TeleTimer = null;
    
    // Destroy timer
    return Plugin_Stop;
}

/*
 * Menu ztele API.
 */
 
 /**
 * @brief Creates the teleport menu.
 *
 * @param client            The client index.
 **/
void ZTeleMenu(int client) 
{
    // Validate client
    if (!IsPlayerExist(client, false))
    {
        return;
    }
    
    // Initialize variables
    static char sBuffer[NORMAL_LINE_LENGTH]; 
    static char sInfo[SMALL_LINE_LENGTH];
    
    // Creates menu handle
    Menu hMenu = new Menu(ZTeleMenuSlots);
    
    // Sets language to target
    SetGlobalTransTarget(client);

    // Sets donate title
    hMenu.SetTitle("%t", "ztele menu");
    
    // i = client index
    int iAmount;
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if (!IsPlayerExist(i))
        {
            continue;
        }

        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%N", i);

        // Show option
        IntToString(GetClientUserId(i), sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer);

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
public int ZTeleMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
                int iD[2]; iD = MenusCommandToArray("zp_ztele_menu");
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
            int target = GetClientOfUserId(StringToInt(sBuffer));
            
            // Validate target
            if (target) 
            {
                // Get the target's name for future use
                GetClientName(target, sBuffer, sizeof(sBuffer));
                
                // Force ZSpawn on the target
                bool bSuccess = ZTeleClient(target, true);
                
                // Tell admin the outcome of the action
                if (bSuccess)
                {
                    TranslationPrintToChat(client, "ztele command force successful", sBuffer);
                }
                else
                {
                    TranslationPrintToChat(client, "ztele command force unsuccessful", sBuffer);
                }
            }
            else
            {
                // Show block info
                TranslationPrintHintText(client, "selecting target block");
                
                // Emit error sound
                ClientCommand(client, "play buttons/button11.wav"); 
            }
            
            // Re-send the menu
            ZTeleMenu(client);
        }
    }
}