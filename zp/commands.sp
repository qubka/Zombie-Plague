/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          commands.sp
 *  Type:          Game 
 *  Description:   Console command initilization and hooking.
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
 * @brief Commands are created.
 **/
void CommandsOnInit()
{
	DebugOnCommandInit();
	ConfigOnCommandInit();
	MemoryOnCommandInit();
	LogOnCommandInit();
	DeathOnCommandInit();
	SpawnOnCommandInit();
	MenusOnCommandInit();
	ToolsOnCommandInit();
	ClassesOnCommandInit();
	WeaponsOnCommandInit();
	GameModesOnCommandInit();
	CostumesOnCommandInit();
	VersionOnCommandInit();
}

/**
 * @brief Wraps ProcessTargetString() and handles producing error messages for bad targets.
 *
 * @param client        The client who issued command.
 * @param sArgument     The target argument.
 * @return              The index of target client, or -1 on error.
 */
stock int FindTargetByID(int client, const char[] sArgument)
{
	int iD = strlen(sArgument);
	if (iD == 0)
	{
		return -1;
	}

	AuthIdType mType = AuthId_Engine; // account id
	
	if (!strncmp(sArgument, "STEAM_", 6) && sArgument[7] == ':')
	{
		mType = AuthId_Steam2;
	}
	else if (!strncmp(sArgument, "[U:", 3))
	{
		mType = AuthId_Steam3;
	}
	else if (iD == 17 && IsStringNumeric(sArgument))
	{
		mType = AuthId_SteamID64;
	}
	else if (iD == 9 && sArgument[0] == '@' && IsStringNumeric(sArgument[1]))
	{
		iD = StringToInt(sArgument[1]);
	}
	else
	{
		return FindTarget(client, sArgument, true, false);
	}
	
	static char sAuth[SMALL_LINE_LENGTH];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i, false, false))
		{
			if (mType == AuthId_Engine)
			{
				if (gClientData[i].AccountID == iD)
				{
					return i;
				}
			}
			else
			{
				GetClientAuthId(i, mType, sAuth, sizeof(sAuth));
				if (!strcmp(sAuth, sArgument))
				{
					return i;
				}
			}
		}
	}
	
	return -1;
}