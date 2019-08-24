/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          debug.cpp
 *  Type:          Core
 *  Description:   Place to put custom functions and test stuff.
 *
 *  Copyright (C) 2015-2019  Greyscale, Richard Helgeby
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
 * @brief Creates commands for debug module.
 **/
void DebugOnCommandInit(/*void*/)
{
    // Hook commands
    RegAdminCmd("zp_debug", DebugOnCommandCatched, ADMFLAG_GENERIC, "Prints debugging dump info the log file.");
}

/**
 * Console command callback (zp_debug)
 * @brief Creates the debug log.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action DebugOnCommandCatched(int client, int iArguments)
{
    // Validate mode
    static bool bDebug;
    if (!bDebug)
    {
        // Start the dump
        ServerCommand("sm prof start");

        // Log event
        LogEvent(false, LogType_Normal, LOG_DEBUG_DETAIL, LogModule_Debug, "Debug Tool", "Start the dump debug logging. Use again to stop process");
    } 
    else 
    {
        // Initialize path
        static char sPath[PLATFORM_LINE_LENGTH];
        BuildPath(Path_SM, sPath, sizeof(sPath), "logs/debug_");

        // Initialize variables
        static char sLog[PLATFORM_LINE_LENGTH];
        static char sLine[PLATFORM_LINE_LENGTH];

        // Gets path to log file
        FindConVar("con_logfile").GetString(sLog, sizeof(sLog));
        FormatEx(sLine, sizeof(sLine), "%s%d.txt", sPath, GetTime());

        // Stop the dump
        ServerCommand("sm prof stop; con_logfile \"%s\"; sm prof dump vprof; con_logfile \"%s\";", sLine, sLog);

        // Log event
        LogEvent(false, LogType_Normal, LOG_DEBUG_DETAIL, LogModule_Debug, "Debug Tool", "Stop the dump debug logging. Results was saved in \"%s\"", sLine);
    }

    // Resets the variable
    bDebug = !bDebug;
    return Plugin_Handled;
}