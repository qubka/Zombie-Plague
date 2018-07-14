/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          commands.cpp
 *  Type:          Game 
 *  Description:   Console command initilization and hooking.
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
 * Commands are created.
 **/
void CommandsInit(/*void*/)
{
    // Hook commands
    AddCommandListener(CommandsHook, "jointeam");
    AddCommandListener(CommandsHook, "kill");
    AddCommandListener(CommandsHook, "explode");
    AddCommandListener(CommandsHook, "killvector");
    
    // Hook messages
    HookUserMessage(GetUserMessageId("TextMsg"), EventMessageHook, true);

    // Forward event to modules
    DebugOnCommandsCreate();
    ConfigOnCommandsCreate();
    DataBaseOnCommandsCreate();
    LogOnCommandsCreate();
    MenusOnCommandsCreate();
    ToolsOnCommandsCreate();
    HumanOnCommandsCreate();
    ZombieOnCommandsCreate();
    SkillsOnCommandsCreate();
    WeaponsOnCommandsCreate();
    ExtraItemsOnCommandsCreate();
    CostumesOnCommandsCreate();
    VersionOnCommandsCreate();
}

/**
 * Callback for command listeners. This is invoked whenever any command reaches the server, from the server console itself or a player.
 * 
 * Clients may be in the process of connecting when they are executing commands IsClientConnected(clientIndex is not guaranteed to return true. Other functions such as GetClientIP() may not work at this point either.
 * 
 * Returning Plugin_Handled or Plugin_Stop will prevent the original, baseline code from running.
 * -- TEXT BELOW IS IMPLEMENTATION, AND NOT GUARANTEED -- Even if returning Plugin_Handled or Plugin_Stop, some callbacks will still trigger. These are: * C++ command dispatch hooks from Metamod:Source plugins * Reg*Cmd() hooks that did not create new commands.
 *
 * @param entityIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action CommandsHook(int clientIndex, const char[] commandMsg, int iArguments)
{
    // Validate client
    if(IsPlayerExist(clientIndex, false))
    {
        // Switches client commands
        switch(commandMsg[0])
        {
            // Jointeam
            case 'j' :
            {
                //!! IMPORTANT BUG FIX !!//
                // Choose random team for the new clients
                if(GetClientTeam(clientIndex) <= TEAM_SPECTATOR) //! Fix, thanks to inklesspen!
                { 
                    // Switch team to random
                    ToolsSetClientTeam(clientIndex, GetRandomInt(TEAM_ZOMBIE, TEAM_HUMAN));

                    // If game round didn't start, then respawn
                    if(gServerData[Server_RoundMode] == -1)
                    {
                        // Force client to respawn
                        ToolsForceToRespawn(clientIndex);
                    }
                }
                
                // Block commands
                return Plugin_Handled;
            }

            // Suicide
            case 'k', 'e' : 
            {
                return gCvarList[CVAR_RESPAWN_SUICIDE].BoolValue ? Plugin_Continue : Plugin_Handled;
            }
        }
    }

    // Allow commands
    return Plugin_Continue;
}

/**
 * Called when a bit buffer based usermessage is hooked.
 *
 * @param iMessage          The message index.
 * @param hBuffer           Handle to the input bit buffer.
 * @param iPlayers          Array containing player indexes.
 * @param playersNum        Number of players in the array.
 * @param bReliable         True ifmessage is reliable, false otherwise.
 * @param bInit             True ifmessage is an initmsg, false otherwise.
 **/
public Action EventMessageHook(UserMsg iMessage, BfRead hBuffer, const int[] iPlayers, int playersNum, bool bReliable, bool bInit)
{
    // Initialize engine message
    static char sTxtMsg[PLATFORM_MAX_PATH]; 
    PbReadString(hBuffer, "params", sTxtMsg, sizeof(sTxtMsg), 0); 

    // Initialize block message list
    static char sBlockMsg[PLATFORM_MAX_PATH];
    gCvarList[CVAR_MESSAGES_BLOCK].GetString(sBlockMsg, sizeof(sBlockMsg)); 

    // Block messages on the matching
    return (StrContains(sBlockMsg, sTxtMsg) != PB_FIELD_NOT_REPEATED) ? Plugin_Handled : Plugin_Continue; 
}