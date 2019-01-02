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
#define PLUGIN_VERSION      "X"
#define PLUGIN_TAG          "zp"
#define PLUGIN_CONFIG       "plugin.zombieplague"
#define PLUGIN_AUTHOR       "qubka (Nikita Ushakov), Greyscale, Richard Helgeby"
#define PLUGIN_COPYRIGHT    "Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)"
#define PLUGIN_BRANCH       "zp-X"
#define PLUGIN_LINK         "https://forums.alliedmods.net/showthread.php?t=290657"
#define PLUGIN_LICENSE      "GNU GPL, Version 3"
#define PLUGIN_DATE         "26-December-2018T19:49:00-GMT+01:00"
/**
 * @endsection
 **/

/**
 * Creates commands for version module.
 **/
void VersionOnCommandsCreate(/*void*/)
{
    RegConsoleCmd("zp_version", VersionCommandCatched, "Prints version info about this plugin.");
}

/**
 * Load version info data.
 **/
void VersionLoad(/*void*/)
{
    // Print a version into the console
    VersionCommandCatched(LANG_SERVER, LANG_SERVER);
}

/**
 * Handles the <!zp_version> command. Called when a generic console command is invoked.
 * 
 * @param clientIndex      The client index.
 * @param iArguments       The number of arguments that were in the argument string.
 **/ 
public Action VersionCommandCatched(const int clientIndex, const int iArguments)
{
    // Initialize variables
    static char sBuffer[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH];
    static char sLine[BIG_LINE_LENGTH];

    // Quick clear string buffer
    sBuffer[0] = '\0'; sLine[0] = '\0';

    #define FORMATSTRING "%24s: %s\n"

    // Format strings
    FormatEx(sLine, sizeof(sLine), "\n%s\n", PLUGIN_NAME);
    StrCat(sBuffer, sizeof(sBuffer), sLine);

    FormatEx(sLine, sizeof(sLine), "%s\n\n", PLUGIN_COPYRIGHT);
    StrCat(sBuffer, sizeof(sBuffer), sLine);

    FormatEx(sLine, sizeof(sLine), FORMATSTRING, "Version", PLUGIN_VERSION);
    StrCat(sBuffer, sizeof(sBuffer), sLine);

    FormatEx(sLine, sizeof(sLine), FORMATSTRING, "Last edit", PLUGIN_DATE);
    StrCat(sBuffer, sizeof(sBuffer), sLine);

    FormatEx(sLine, sizeof(sLine), FORMATSTRING, "License", PLUGIN_LICENSE);
    StrCat(sBuffer, sizeof(sBuffer), sLine);

    FormatEx(sLine, sizeof(sLine), FORMATSTRING, "Link+", PLUGIN_LINK);
    StrCat(sBuffer, sizeof(sBuffer), sLine);

    FormatEx(sLine, sizeof(sLine), FORMATSTRING, "Branch", PLUGIN_BRANCH);
    StrCat(sBuffer, sizeof(sBuffer), sLine);

    // Send information into the console
    ReplyToCommand(clientIndex, sBuffer);
    return Plugin_Handled;
}