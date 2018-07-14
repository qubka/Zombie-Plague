/*
 * ============================================================================  
 *  
 *  Zombie Plague Mod #3 Generation
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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

#if defined USE_DHOOKS
    #tryinclude <dhooks>   
#endif

#pragma semicolon 1
#pragma newdecls required

// Main
#include "zp/global.cpp"  
#include "zp/versioninfo.cpp"
#include "zp/cvars.cpp"    

// Core
#include "zp/core/log.cpp"  
#include "zp/core/zombieplague.cpp" 
#include "zp/core/debug.cpp" 
#include "zp/core/config.cpp"
#include "zp/core/database.cpp"
#include "zp/core/translation.cpp"    
#include "zp/core/paramparser.cpp" 

// Visual effects 
#include "zp/manager/visualeffects/visualeffects.cpp" //!(Module)

// Game
#include "zp/game/events.cpp"
#include "zp/game/antistick.cpp"
#include "zp/game/account.cpp"
#include "zp/game/tools.cpp"
#include "zp/game/spawn.cpp"
#include "zp/game/death.cpp"
#include "zp/game/damage.cpp"
#include "zp/game/roundstart.cpp"
#include "zp/game/jumpboost.cpp"
#include "zp/game/roundend.cpp"
#include "zp/game/class.cpp"
#include "zp/game/skillsystem.cpp"
#include "zp/game/runcmd.cpp"
#include "zp/game/levelsystem.cpp"
#include "zp/game/commands.cpp"

// Manager
#include "zp/manager/zombieclasses.cpp"
#include "zp/manager/humanclasses.cpp"
#include "zp/manager/extraitems.cpp"
#include "zp/manager/downloads.cpp"
#include "zp/manager/hitgroups.cpp"
#include "zp/manager/costumes.cpp"
#include "zp/manager/weapons.cpp"
#include "zp/manager/models.cpp"
#include "zp/manager/sounds.cpp"
#include "zp/manager/menus.cpp"
#include "zp/manager/gamemodes.cpp"

// API
#include "zp/api/api.cpp"

/* 
 * Thanks for code and ideas to Greyscale, Richard Helgeby and AlliedMods community :)
 */

/**
 * Record plugin info.
 **/
public Plugin Zombie_Plague =
{
    name            = PLUGIN_NAME,
    author          = PLUGIN_AUTHOR,
    description     = PLUGIN_COPYRIGHT,
    version         = PLUGIN_VERSION,
    url             = PLUGIN_LINK
}

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*               you know _exactly_ what you are doing!!!             *
//*********************************************************************

/**
    * Called before plugin is loaded.
 **/
public APLRes AskPluginLoad2(Handle iMyself, bool bLate, char[] sError, int iErrorMax)
{
    // Load API
    return APIInit();
}

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
    // Forward event to modules
    ConfigInit();
    EventInit();
    LogInit();
    CostumesInit();
    CommandsInit();
    CvarsInit();
    ToolsInit();
    SoundsInit();
    AccountInit();
    WeaponsInit();
    LevelSystemInit();
    TranslationInit();
    GameEngineInit();
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Forward event to modules
    ConfigLoad();
    ModelsLoad();
    SoundsLoad();
    WeaponsLoad();
    DownloadsLoad();
    ZombieClassesLoad();
    HumanClassesLoad();
    CostumesLoad();
    VEffectsLoad();
    ExtraItemsLoad();
    LevelSystemLoad();
    GameModesLoad();
    MenusLoad();
    HitgroupsLoad();
    DataBaseLoad();
    VersionLoad();
    GameEngineLoad();
}

/**
 * The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // Forward event to modules
    ToolsPurge();
}

/**
 * Plugin is unload.
 **/
public void OnPluginEnd(/*void*/)
{
    // Forward event to modules
    WeaponsUnload();
    DataBaseUnload();
}