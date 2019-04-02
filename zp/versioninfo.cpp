/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          versioninfo.cpp
 *  Type:          Main 
 *  Description:   Version information.
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
 * @section Modification information.
 **/
#define PLUGIN_NAME         "Zombie Plague"
#define PLUGIN_VERSION      "X.015"
#define PLUGIN_TAG          "zp"
#define PLUGIN_CONFIG       "plugin.zombieplague"
#define PLUGIN_AUTHOR       "qubka (Nikita Ushakov), Greyscale, Richard Helgeby"
#define PLUGIN_COPYRIGHT    "Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)"
#define PLUGIN_BRANCH       "master"
#define PLUGIN_LINK         "https://forums.alliedmods.net/showthread.php?t=290657"
#define PLUGIN_LICENSE      "GNU GPL, Version 3"
#define PLUGIN_DATE         "02-April-2019T11:30:00-GMT+03:00"
/**
 * @endsection
 **/

/**
 * @brief Creates commands for version module.
 **/
void VersionOnCommandInit(/*void*/)
{
    RegConsoleCmd("zp_version", VersionOnCommandCatched, "Prints version info about this plugin.");
}

/**
 * @brief Version module load function.
 **/
void VersionOnLoad(/*void*/)
{
    // Print a version into the console
    VersionOnCommandCatched(LANG_SERVER, LANG_SERVER);
}

/**
 * Console command callback (zp_version)
 * @brief Prints version info about this plugin.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action VersionOnCommandCatched(int clientIndex, int iArguments)
{
    // Initialize variables
    static char sBuffer[HUGE_LINE_LENGTH]; sBuffer[0] = '\0';
    static char sLine[BIG_LINE_LENGTH]; sLine[0] = '\0';

    /// Format strings
    FormatEx(sLine, sizeof(sLine), "\n%s\n", PLUGIN_NAME);
    StrCat(sBuffer, sizeof(sBuffer), sLine);
    FormatEx(sLine, sizeof(sLine), "%s\n\n", PLUGIN_COPYRIGHT);
    StrCat(sBuffer, sizeof(sBuffer), sLine);
    FormatEx(sLine, sizeof(sLine), "%24s: %s\n", "Version", PLUGIN_VERSION);
    StrCat(sBuffer, sizeof(sBuffer), sLine);
    FormatEx(sLine, sizeof(sLine), "%24s: %s\n", "Last edit", PLUGIN_DATE);
    StrCat(sBuffer, sizeof(sBuffer), sLine);
    FormatEx(sLine, sizeof(sLine), "%24s: %s\n", "License", PLUGIN_LICENSE);
    StrCat(sBuffer, sizeof(sBuffer), sLine);
    FormatEx(sLine, sizeof(sLine), "%24s: %s\n", "Link+", PLUGIN_LINK);
    StrCat(sBuffer, sizeof(sBuffer), sLine);
    FormatEx(sLine, sizeof(sLine), "%23s: %s\n", "Branch", PLUGIN_BRANCH);
    StrCat(sBuffer, sizeof(sBuffer), sLine);

    // Send information into the console
    ReplyToCommand(clientIndex, sBuffer);
    return Plugin_Handled;
}
