/*
 * ============================================================================  
 *  
 *  Zombie Plague
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

// Extension
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <dhooks>   

// Helper
#include <utils>

#pragma semicolon 1
#pragma newdecls required

// Modules
#include "zp/global.sp"  
#include "zp/versioninfo.sp"  
#include "zp/api.sp"
#include "zp/paramparser.sp" 
#include "zp/config.sp"
#include "zp/cvars.sp"  
#include "zp/log.sp"
#include "zp/zombieplague.sp" 
#include "zp/debug.sp" 
#include "zp/memory.sp" 
#include "zp/commands.sp"
#include "zp/database.sp"
#include "zp/translation.sp"   
#include "zp/decryptor.sp"
#include "zp/visualeffects.sp"
#include "zp/menus.sp"
#include "zp/classes.sp"
#include "zp/extraitems.sp"
#include "zp/downloads.sp"
#include "zp/hitgroups.sp"
#include "zp/costumes.sp"
#include "zp/weapons.sp"
#include "zp/sounds.sp"
#include "zp/gamemodes.sp"


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
	return APIOnInit();
}

/**
 * @brief Plugin is loading.
 **/
public void OnPluginStart()
{
	TranslationOnInit();  
	ConfigOnInit();
	CvarsOnInit();
	GameEngineOnInit();
	CommandsOnInit();
	MemoryOnInit();
	LogOnInit();
	ClassesOnInit();
	CostumesOnInit(); 
	SoundsOnInit();
	DataBaseOnInit();
	GameModesOnInit();
	WeaponsOnInit();
	ExtraItemsOnInit();
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	ConfigOnLoad();
	ClassesOnLoad(true); /// init only types
	MenusOnLoad();
	SoundsOnLoad();
	VEffectsOnLoad();
	DownloadsOnLoad();
	WeaponsOnLoad();
	ClassesOnLoad();
	CostumesOnLoad();
	GameModesOnLoad();
	ExtraItemsOnLoad();
	HitGroupsOnLoad();
	LevelSystemOnLoad();
	VersionOnLoad();
	GameEngineOnLoad();
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	GameEngineOnMapEnd();
	GameModesOnMapEnd();
	ExtraItemsOnMapEnd();
}

/**
 * @brief Plugin is unload.
 **/
public void OnPluginEnd()
{
	WeaponsOnUnload();
	DataBaseOnUnload();
	CostumesOnUnload();
	MemoryOnUnload();
}

/**
 * @brief Called once a client successfully connects.
 *
 * @param client            The client index.
 **/
public void OnClientConnected(int client)
{
	ClassesOnClientConnect(client);
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect_Post(int client)
{
	DataBaseOnClientDisconnectPost(client);
	ClassesOnClientDisconnectPost(client);
}

/**
 * @brief Called once a client is authorized and fully in-game, and 
 *        after all post-connection authorizations have been performed.  
 *
 * @note  This callback is gauranteed to occur on all clients, and always 
 *        after each OnClientPutInServer() call.
 * 
 * @param client            The client index. 
 **/
public void OnClientPostAdminCheck(int client)
{
	HitGroupsOnClientInit(client);
	WeaponsOnClientInit(client);
	ClassesOnClientInit(client);
	DataBaseOnClientInit(client);
	CostumesOnClientInit(client);
	VEffectsOnClientInit(client);
}
