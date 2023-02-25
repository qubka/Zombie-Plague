/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          debug.sp
 *  Type:          Core
 *  Description:   Place to put custom functions and test stuff.
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
 * @brief Creates commands for debug module.
 **/
void DebugOnCommandInit()
{
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
	static bool bDebug;
	if (!bDebug)
	{
		ServerCommand("sm prof start");

		LogEvent(false, LogType_Normal, LOG_DEBUG_DETAIL, LogModule_Debug, "Debug Tool", "Start the dump debug logging. Use again to stop process");
	} 
	else 
	{
		static char sPath[PLATFORM_LINE_LENGTH];
		BuildPath(Path_SM, sPath, sizeof(sPath), "logs/debug_");

		static char sLog[PLATFORM_LINE_LENGTH];
		static char sLine[PLATFORM_LINE_LENGTH];

		FindConVar("con_logfile").GetString(sLog, sizeof(sLog));
		FormatEx(sLine, sizeof(sLine), "%s%d.txt", sPath, GetTime());

		ServerCommand("sm prof stop; con_logfile \"%s\"; sm prof dump vprof; con_logfile \"%s\";", sLine, sLog);

		LogEvent(false, LogType_Normal, LOG_DEBUG_DETAIL, LogModule_Debug, "Debug Tool", "Stop the dump debug logging. Results was saved in \"%s\"", sLine);
	}

	bDebug = !bDebug;
	return Plugin_Handled;
}
