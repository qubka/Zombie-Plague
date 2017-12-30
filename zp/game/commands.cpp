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
	
	// Hook messages
	HookUserMessage(GetUserMessageId("TextMsg"), EventMessageHook, true);

	// Forward event to modules
	ConfigOnCommandsCreate();
	LogOnCommandsCreate();
	MenusOnCommandsCreate();
	ToolsOnCommandsCreate();
	SkillsOnCommandsCreate();
	VersionOnCommandsCreate();
}

/**
 * Hook client commands.
 *
 * @param clientIndex		The client index.
 * @param commandMsg		Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments		Argument count.
 **/
public Action CommandsHook(int clientIndex, const char[] commandMsg, int iArguments)
{
	// Swithes hooked commands
	switch(commandMsg[0])
	{
		// Jointeam
		case 'j' :
		{
			return ACTION_HANDLED;
		}
		
		// Suicide
		case 'k', 'e' : 
		{
			return GetConVarBool(gCvarList[CVAR_RESPAWN_SUICIDE]) ? ACTION_CONTINUE : ACTION_HANDLED;
		}
	}

	// Allow other commands
	return ACTION_CONTINUE;
}

/**
 * Called when a bit buffer based usermessage is hooked.
 *
 * @param iMessage			The message index.
 * @param sMessage			Handle to the input bit buffer.
 * @param iPlayers			Array containing player indexes.
 * @param playersNum		Number of players in the array.
 * @param bReliable			True ifmessage is reliable, false otherwise.
 * @param bInit				True ifmessage is an initmsg, false otherwise.
 **/
public Action EventMessageHook(UserMsg iMessage, BfRead sMessage, const int[] iPlayers, int playersNum, bool bReliable, bool bInit)
{
	// Initialize engine message
	static char sTxtMsg[NORMAL_LINE_LENGTH]; 
	PbReadString(sMessage, "params", sTxtMsg, sizeof(sTxtMsg), 0); 

	// Initialize block message list
	static char sBlockMsg[PLATFORM_MAX_PATH];
	GetConVarString(gCvarList[CVAR_MESSAGES_BLOCK], sBlockMsg, sizeof(sBlockMsg)); 

	// Block messages on the matching
	return (StrContains(sBlockMsg, sTxtMsg) != -1) ? ACTION_HANDLED : ACTION_CONTINUE; 
}