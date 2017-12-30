/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          global.h.cpp
 *  Type:          Main 
 *  Description:   General plugin header.
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
 * @section: Similarly as with plain data structures, 
 *			 the members of an object can be accessed directly from a pointer by using the arrow operator.
 **/
#define cBaseAttacker->					cBaseAttacker.
#define cBaseVictim->					cBaseVictim.
#define cBasePlayer->					cBasePlayer.
#define CBasePlayer*					CBasePlayer
/**
 * @endsection
 **/
 
/**
 * @section: Core static macroses.
 **/
#define ACTION_CONTINUE					Plugin_Continue
#define ACTION_CHANGED					Plugin_Changed
#define ACTION_HANDLED					Plugin_Handled
#define ACTION_STOP						Plugin_Stop

#define NULL							INVALID_HANDLE

#define SMALL_LINE_LENGTH				32
#define NORMAL_LINE_LENGTH				64
#define BIG_LINE_LENGTH					128

#define TEAM_ZOMBIE						CS_TEAM_T
#define TEAM_HUMAN						CS_TEAM_CT
#define TEAM_NONE						CS_TEAM_NONE
#define TEAM_SPECTATOR					CS_TEAM_SPECTATOR
/**
 * @endsection
 **/

/**
 * List of operation types for global array.
 **/
enum ServerData
{
	bool:Server_RoundNew,
	bool:Server_RoundEnd,
	bool:Server_RoundStart,
	Server_RoundNumber,
	Server_RoundMode,
	Server_RoundCount,
	Handle:Server_RoundTimer,
	String:Server_MapName[PLATFORM_MAX_PATH]
};

/**
 * Arrays to store the server's data.
 **/
int gServerData[ServerData];

/**
 * List of operation types for clients arrays.
 **/
enum ClientData
{
	bool:Client_Zombie,
	bool:Client_Survivor,
	bool:Client_Nemesis,
	bool:Client_Skill,
	Client_SkillCountDown,
	Client_ZombieClass,
	Client_ZombieClassNext,
	Client_HumanClass,
	Client_HumanClassNext,
	Client_Respawn,
	Client_RespawnTimes,
	Client_AmmoPacks,
	Client_LastBoughtAmount,
	Client_Level,
	Client_Exp,
	Handle:Client_ZombieSkillTimer,
	Handle:Client_ZombieRespawnTimer
};

/**
 * Arrays to store the clients' data.
 **/
int gClientData[MAXPLAYERS+1][ClientData];