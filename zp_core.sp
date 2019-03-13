/*
 * ============================================================================  
 *  
 *  Zombie Plague
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
 *  
 *  Regards to Greyscale and Richard Helgeby, a lot of useful code
 *  was taken from the great plugin for Counter Strike: Source
 *  and remaked to Zombie Plague modification.
 *
 *  This project started back on late 2007, when the free infection mods
 *    around were quite buggy and MeRcyLeZZ wanted to make one big mode.
 *  Acctually Zombie Plague was the most popular mode in Counter Strike 1.6
 *  So when I look on Zombie:Reloaded, I planned to port Zombie Plague mode
 *  to Counter Strike: Global Offensive. I hope you will enjoy playing.
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
 */
 
// Comment to remove a DHook module features (experimental branch)
#define USE_DHOOKS

// Sourcemod
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#if defined USE_DHOOKS
    #tryinclude <dhooks>   
#endif

#pragma semicolon 1
#pragma newdecls required

// Main
#include "zp/global.cpp"  
#include "zp/versioninfo.cpp"  

// Core
#include "zp/core/api.cpp"
#include "zp/core/paramparser.cpp" 
#include "zp/core/config.cpp"
#include "zp/core/cvars.cpp"  
#include "zp/core/log.cpp"
#include "zp/core/zombieplague.cpp" 
#include "zp/core/debug.cpp" 
#include "zp/core/commands.cpp"
#include "zp/core/database.cpp"
#include "zp/core/translation.cpp"   
#include "zp/core/decryptor.cpp"

// Manager
#include "zp/manager/visualeffects.cpp"
#include "zp/manager/menus.cpp"
#include "zp/manager/classes.cpp"
#include "zp/manager/extraitems.cpp"
#include "zp/manager/downloads.cpp"
#include "zp/manager/hitgroups.cpp"
#include "zp/manager/costumes.cpp"
#include "zp/manager/weapons.cpp"
#include "zp/manager/sounds.cpp"
#include "zp/manager/gamemodes.cpp"


/* 
 * Thanks for code and ideas to Greyscale, Richard Helgeby and AlliedMods community :)
 */

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_COPYRIGHT,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_LINK
}

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*               you know _exactly_ what you are doing!!!             *
//*********************************************************************

/**
 * @brief Called before plugin is loaded.
 **/
public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] sError, int iErrorMax)
{
    // Load API
    return APIOnInit();
}

/**
 * @brief Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
    // Forward event to modules
    TranslationOnInit();  
    ConfigOnInit();
    CvarsOnInit();
    CommandsOnInit();
    LogOnInit();
    GameEngineOnInit();
    ClassesOnInit();
    CostumesOnInit(); 
    HitGroupsOnInit();
    SoundsOnInit();
    DataBaseOnInit();
    GameModesOnInit();
    WeaponsOnInit();
    VEffectsOnInit();
    ExtraItemsOnInit();
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Forward event to modules
    SoundsOnLoad();
    WeaponsOnLoad();
    VEffectsOnLoad();
    DownloadsOnLoad();
    ClassesOnLoad();
    CostumesOnLoad();
    GameModesOnLoad();
    VersionOnLoad();
    GameEngineOnLoad();
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // Forward event to modules
    ClassesOnPurge();
    VEffectsOnPurge();
    GameModesOnPurge();
    GameEngineOnPurge();
}

/**
 * @brief Plugin is unload.
 **/
public void OnPluginEnd(/*void*/)
{
    // Forward event to modules
    WeaponsOnUnload();
    DataBaseOnUnload();
    CostumesOnUnload();
    ///ConfigOnUnload();
}

/**
 * @brief Called once a client successfully connects.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientConnected(int clientIndex)
{
    // Forward event to modules
    ClassesOnClientConnect(clientIndex);
    DataBaseOnClientConnect(clientIndex);
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect_Post(int clientIndex)
{
    // Forward event to modules
    DataBaseOnClientDisconnectPost(clientIndex);
    ClassesOnClientDisconnectPost(clientIndex);
}

/**
 * @brief Called once a client is authorized and fully in-game, and 
 *        after all post-connection authorizations have been performed.  
 *
 * @note  This callback is gauranteed to occur on all clients, and always 
 *        after each OnClientPutInServer() call.
 * 
 * @param clientIndex       The client index. 
 **/
public void OnClientPostAdminCheck(int clientIndex)
{
    // Forward event to modules
    HitGroupsOnClientInit(clientIndex);
    WeaponsOnClientInit(clientIndex);
    ClassesOnClientInit(clientIndex);
    DataBaseOnClientInit(clientIndex);
    CostumesOnClientInit(clientIndex);
}