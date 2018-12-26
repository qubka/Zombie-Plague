/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          levelsystem.cpp
 *  Type:          Game 
 *  Description:   Provides functions for level system.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
 * Number of max valid levels.
 **/
#define LevelSystemMax 100

/**
 * Arrays to store the level data.
 **/
int  LevelSystemNum;
static char LevelSystemStats[LevelSystemMax][SMALL_LINE_LENGTH];
 
/**
 * HUD synchronization handle.
 **/
Handle hHudLevel;
 
/**
 * Level system module init function.
 **/
void LevelSystemInit(/*void*/)
{
    // If level system disabled, then purge
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        // Validate loaded map
        if(IsMapLoaded())
        {
            // Validate sync
            if(hHudLevel != INVALID_HANDLE)
            {
                // i = client index
                for(int i = 1; i <= MaxClients; i++)
                {
                    // Validate client
                    if(IsPlayerExist(i))
                    {
                        // Remove timer
                        delete gClientData[i][Client_LevelTimer];
                    }
                }
                
                // Remove sync
                delete hHudLevel;
            }
        }
        return;
    }
    
    /*
     * Creates a HUD synchronization object. This object is used to automatically assign and re-use channels for a set of messages.
     * The HUD has a hardcoded number of channels (usually 6) for displaying text. You can use any channel for any area of the screen. 
     * Text on different channels can overlap, but text on the same channel will erase the old text first. This overlapping and overwriting gets problematic.
     * A HUD synchronization object automatically selects channels for you based on the following heuristics: - If channel X was last used by the object, 
     * and hasn't been modified again, channel X gets re-used. - Otherwise, a new channel is chosen based on the least-recently-used channel.
     * This ensures that if you display text on a sync object, that the previous text displayed on it will always be cleared first. 
     * This is because your new text will either overwrite the old text on the same channel, or because another channel has already erased your text.
     * Note that messages can still overlap if they are on different synchronization objects, or they are displayed to manual channels.
     * These are particularly useful for displaying repeating or refreshing HUD text, in addition to displaying multiple message sets in one area of the screen 
     * (for example, center-say messages that may pop up randomly that you don't want to overlap each other).
     */
    delete hHudLevel;
    hHudLevel = CreateHudSynchronizer();
    
    // Resets level data
    LevelSystemNum = 0;

    // Initialize level list
    static char sList[PLATFORM_MAX_PATH];
    gCvarList[CVAR_LEVEL_STATISTICS].GetString(sList, sizeof(sList));

    // Check if list is empty, then skip
    if(hasLength(sList))
    {
        // Convert list string to pieces
        LevelSystemNum = ExplodeString(sList, " ", LevelSystemStats, sizeof(LevelSystemStats), sizeof(LevelSystemStats[])) - 1;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i))
            {
                // Enable level system
                LevelSystemOnClientUpdate(i);
            }
        }
    }
}

/**
 * Hook level system cvar changes.
 **/
void LevelSystemOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_LEVEL_SYSTEM]                = FindConVar("zp_level_system");
    gCvarList[CVAR_LEVEL_STATISTICS]            = FindConVar("zp_level_statistics"); 
    gCvarList[CVAR_LEVEL_HEALTH_RATIO]          = FindConVar("zp_level_health_ratio");
    gCvarList[CVAR_LEVEL_SPEED_RATIO]           = FindConVar("zp_level_speed_ratio");
    gCvarList[CVAR_LEVEL_GRAVITY_RATIO]         = FindConVar("zp_level_gravity_ratio");
    gCvarList[CVAR_LEVEL_DAMAGE_RATIO]          = FindConVar("zp_level_damage_ratio");
    gCvarList[CVAR_LEVEL_DAMAGE_HUMAN]          = FindConVar("zp_level_damage_human");
    gCvarList[CVAR_LEVEL_DAMAGE_ZOMBIE]         = FindConVar("zp_level_damage_zombie");
    gCvarList[CVAR_LEVEL_DAMAGE_SURVIVOR]       = FindConVar("zp_level_damage_survivor");
    gCvarList[CVAR_LEVEL_INFECT]                = FindConVar("zp_level_infect");
    gCvarList[CVAR_LEVEL_KILL_HUMAN]            = FindConVar("zp_level_kill_human");
    gCvarList[CVAR_LEVEL_KILL_ZOMBIE]           = FindConVar("zp_level_kill_zombie");
    gCvarList[CVAR_LEVEL_KILL_NEMESIS]          = FindConVar("zp_level_kill_nemesis");
    gCvarList[CVAR_LEVEL_KILL_SURVIVOR]         = FindConVar("zp_level_kill_survivor");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_R]          = FindConVar("zp_level_hud_zombie_R");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_G]          = FindConVar("zp_level_hud_zombie_G");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_B]          = FindConVar("zp_level_hud_zombie_B");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_R]           = FindConVar("zp_level_hud_human_R");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_G]           = FindConVar("zp_level_hud_human_G");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_B]           = FindConVar("zp_level_hud_human_B");
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_LEVEL_SYSTEM],                LevelSystemCvarsHookEnable);       
    HookConVarChange(gCvarList[CVAR_LEVEL_HEALTH_RATIO],          LevelSystemCvarsHookHealth);         
    HookConVarChange(gCvarList[CVAR_LEVEL_SPEED_RATIO],           LevelSystemCvarsHookSpeed);           
    HookConVarChange(gCvarList[CVAR_LEVEL_GRAVITY_RATIO],         LevelSystemCvarsHookGravity); 
}

/**
 * Client has been changed class state.
 *
 * @param clientIndex       The client index.
 **/
void LevelSystemOnClientUpdate(const int clientIndex)
{
    // If level system disabled, then stop
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }
    
    // Validate level amount
    if(!LevelSystemNum)
    {
        return;
    }

    // Validate real client
    if(!IsFakeClient(clientIndex))
    {
        // Sets timer for player level HUD
        delete gClientData[clientIndex][Client_LevelTimer];
        gClientData[clientIndex][Client_LevelTimer] = CreateTimer(1.0, LevelSystemOnHUD, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * Sets the client level and prevent it from overloading.
 *
 * @param clientIndex       The client index.
 * @param nLevel            The level amount.
 **/
void LevelSystemOnSetLvl(const int clientIndex, const int nLevel)
{
    // If level system disabled, then stop
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }

    // Validate level amount
    if(!LevelSystemNum)
    {
        return;
    }

    // If amount below 0, then stop
    if(nLevel < 0)
    {
        return;
    }

    // Sets the level
    gClientData[clientIndex][Client_Level] = nLevel;

    // Validate level
    if(gClientData[clientIndex][Client_Level] > LevelSystemNum)
    {
        // Update it
        gClientData[clientIndex][Client_Level] = LevelSystemNum;
    }
    else
    {
        // Validate client
        if(IsPlayerExist(clientIndex)) 
        {
            // Forward event to modules
            SoundsOnClientLevelUp(clientIndex);
        }
    }
}

/**
 * Sets the client experience, increasing level if it reach level experience limit and prevent it from overloading.
 *
 * @param clientIndex       The client index.
 * @param nExperience       The experience amount.
 **/
void LevelSystemOnSetExp(const int clientIndex, const int nExperience)
{
    // If level system disabled, then stop
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }

    // Validate level amount
    if(!LevelSystemNum)
    {
        return;
    }

    // If amount below 0, then stop
    if(nExperience < 0)
    {
        return;
    }

    // Sets the experience
    gClientData[clientIndex][Client_Exp] = nExperience;

    // Give experience to the player
    if(gClientData[clientIndex][Client_Level] == LevelSystemNum && gClientData[clientIndex][Client_Exp] > StringToInt(LevelSystemStats[gClientData[clientIndex][Client_Level]]))
    {
        gClientData[clientIndex][Client_Exp] = StringToInt(LevelSystemStats[gClientData[clientIndex][Client_Level]]);
    }
    else
    {
        // Loop throught experience
        while(gClientData[clientIndex][Client_Level] < LevelSystemNum && gClientData[clientIndex][Client_Exp] >= StringToInt(LevelSystemStats[gClientData[clientIndex][Client_Level]]))
        {
            // Increase level
            LevelSystemOnSetLvl(clientIndex, gClientData[clientIndex][Client_Level] + 1);
        }
    }
}

/**
 * Timer callback, show HUD text within information about client level and experience.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action LevelSystemOnHUD(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Initialize variables
        static char sInfo[SMALL_LINE_LENGTH]; static int iRed, iGreen, iBlue;
    
        // Validate zombie hud
        if(gClientData[clientIndex][Client_Zombie])
        {
            // Validate nemesis hud
            if(gClientData[clientIndex][Client_Nemesis])
            {
                strcopy(sInfo, sizeof(sInfo), "nemesis");
            }
            else
            {
                // Gets zombie name
                ZombieGetName(gClientData[clientIndex][Client_ZombieClass], sInfo, sizeof(sInfo));
            }
            
            // Gets colors 
            iRed = gCvarList[CVAR_LEVEL_HUD_ZOMBIE_R].IntValue;
            iGreen = gCvarList[CVAR_LEVEL_HUD_ZOMBIE_G].IntValue;
            iBlue = gCvarList[CVAR_LEVEL_HUD_ZOMBIE_B].IntValue;
        }
        // Otherwise, show human hud
        else
        {
            // Validate survivor hud
            if(gClientData[clientIndex][Client_Survivor])
            {
                strcopy(sInfo, sizeof(sInfo), "survivor");
            }
            else
            {
                // Gets human name
                HumanGetName(gClientData[clientIndex][Client_HumanClass], sInfo, sizeof(sInfo));
            }
            // Gets colors 
            iRed = gCvarList[CVAR_LEVEL_HUD_HUMAN_R].IntValue;
            iGreen = gCvarList[CVAR_LEVEL_HUD_HUMAN_G].IntValue;
            iBlue = gCvarList[CVAR_LEVEL_HUD_HUMAN_B].IntValue;
        }

        // Print hud text to client
        TranslationPrintHudText(hHudLevel, clientIndex, 0.02, 0.885, 1.1, iRed, iGreen, iBlue, 255, 0, 0.0, 0.0, 0.0, "level info", GetClientArmor(clientIndex), sInfo, gClientData[clientIndex][Client_Level], gClientData[clientIndex][Client_Exp], LevelSystemStats[gClientData[clientIndex][Client_Level]]);
    
        // Allow timer
        return Plugin_Continue;
    }
    
    // Clear timer
    gClientData[clientIndex][Client_LevelTimer] = INVALID_HANDLE;
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Cvar hook callback (zp_level_system)
 * Levelsystem module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void LevelSystemCvarsHookEnable(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    LevelSystemInit();
}

/**
 * Cvar hook callback (zp_level_health_ratio)
 * Reload the health variable on zombie/human.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void LevelSystemCvarsHookHealth(ConVar hConVar, const char[] oldValue, const char[] newValue)
{    
    // If level system disabled, then stop
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }
    
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i))
            {
                // Validate zombie
                if(gClientData[i][Client_Zombie] && !gClientData[i][Client_Nemesis])
                {
                    // Update variable
                    ToolsSetClientHealth(i, ZombieGetHealth(gClientData[i][Client_ZombieClass]) + (RoundToFloor(gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[i][Client_Level]))), true);
                }
                // Validate human
                else if(!gClientData[i][Client_Zombie] && !gClientData[i][Client_Survivor])
                {
                    // Update variable
                    ToolsSetClientHealth(i, HumanGetHealth(gClientData[i][Client_HumanClass]) + (RoundToFloor(gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[i][Client_Level]))), true);
                }
            }
        }
    }
}

/**
 * Cvar hook callback (zp_level_speed_ratio)
 * Reload the speed variable on zombie/human.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void LevelSystemCvarsHookSpeed(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // If level system disabled, then stop
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }
    
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i))
            {
                // Validate zombie
                if(gClientData[i][Client_Zombie] && !gClientData[i][Client_Nemesis])
                {
                    // Update variable
                    ToolsSetClientLMV(i, ZombieGetSpeed(gClientData[i][Client_ZombieClass]) + (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[i][Client_Level])));
                    
                }
                // Validate human
                else if(!gClientData[i][Client_Zombie] && !gClientData[i][Client_Survivor])
                {
                    // Update variable
                    ToolsSetClientLMV(i, HumanGetSpeed(gClientData[i][Client_HumanClass]) + (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[i][Client_Level])));
                }
            }
        }
    }
}

/**
 * Cvar hook callback (zp_level_gravity_ratio)
 * Reload the gravity variable on zombie/human.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void LevelSystemCvarsHookGravity(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // If level system disabled, then stop
    if(!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }
    
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i))
            {
                // Validate zombie
                if(gClientData[i][Client_Zombie] && !gClientData[i][Client_Nemesis])
                {
                    // Update variable
                    ToolsSetClientGravity(i, ZombieGetGravity(gClientData[i][Client_ZombieClass]) + (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[i][Client_Level])));
                }
                // Validate human
                else if(!gClientData[i][Client_Zombie] && !gClientData[i][Client_Survivor])
                {
                    // Update variable
                    ToolsSetClientGravity(i, HumanGetGravity(gClientData[i][Client_HumanClass]) + (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[i][Client_Level])));
                }
            }
        }
    }
}