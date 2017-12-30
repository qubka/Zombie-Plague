/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          zombieplague.cpp
 *  Type:          Main 
 *  Description:   General plugin functions and defines.
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
 * @section All engines versions.
 **/
#define ENGINE_UNKNOWN              "could not determine the engine version"    
#define ENGINE_ORIGINAL             "Original Source Engine"         
#define ENGINE_SOURCESDK2006        "Episode 1 Source Engine"         
#define ENGINE_SOURCESDK2007        "Orange Box Source Engine"        
#define ENGINE_LEFT4DEAD            "Left 4 Dead"   
#define ENGINE_DARKMESSIAH          "Dark Messiah Multiplayer"
#define ENGINE_LEFT4DEAD2           "Left 4 Dead 2"
#define ENGINE_ALIENSWARM           "Alien Swarm"
#define ENGINE_BLOODYGOODTIME       "Bloody Good Time"
#define ENGINE_EYE                  "E.Y.E Divine Cybermancy"
#define ENGINE_PORTAL2              "Portal 2"
#define ENGINE_CSGO                 "Counter-Strike: Global Offensive"
#define ENGINE_CSS                  "Counter-Strike: Source"
#define ENGINE_DOTA                 "Dota 2"
#define ENGINE_HL2DM                "Half-Life 2 Deathmatch"
#define ENGINE_DODS                 "Day of Defeat: Source"
#define ENGINE_TF2                  "Team Fortress 2"
#define ENGINE_NUCLEARDAWN          "Nuclear Dawn"
#define ENGINE_SDK2013              "Source SDK 2013"
#define ENGINE_BLADE                "Blade Symphony"
#define ENGINE_INSURGENCY			"Insurgency"
#define ENGINE_CONTAGION            "Contagion"
/**
 * @endsection
 **/
 
/*
 * Engine functions
 */
 
/**
 * Called once when server is started. Will log a warning ifa unsupported game is detected.
 **/
void GameEngineInit(/*void*/)
{
	// Get engine of the game
	switch(GetEngineVersion(/*void*/))
	{
		case Engine_Unknown :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague %s", ENGINE_UNKNOWN);
		}
		case Engine_Original :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_ORIGINAL);
		}
		case Engine_SourceSDK2006 :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_SOURCESDK2006);
		}
		case Engine_SourceSDK2007 :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_SOURCESDK2007);
		}
		case Engine_Left4Dead :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_LEFT4DEAD);
		}
		case Engine_DarkMessiah :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_DARKMESSIAH);
		}
		case Engine_Left4Dead2 :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_LEFT4DEAD2);
		}
		case Engine_AlienSwarm :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_ALIENSWARM);
		}
		case Engine_BloodyGoodTime :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_BLOODYGOODTIME);
		}
		case Engine_EYE :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_EYE);
		}
		case Engine_Portal2 :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_PORTAL2);
		}
		case Engine_CSGO :	
		{
			LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Engine catched: %s", ENGINE_CSGO);
		}
		case Engine_CSS :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_CSS);
		}
		case Engine_DOTA :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_DOTA);
		}
		case Engine_HL2DM :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_HL2DM);
		}
		case Engine_DODS :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_DODS);
		}
		case Engine_TF2 :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_TF2);
		}
		case Engine_NuclearDawn :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_NUCLEARDAWN);
		}
		case Engine_SDK2013 :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_SDK2013);
		}
		case Engine_Blade :	
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_BLADE);
		}
		case Engine_Insurgency :
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_INSURGENCY);
		}
		case Engine_Contagion :
		{
			LogEvent(true, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support %s", ENGINE_CONTAGION);
		}
	}
}

/*
 * Player functions
 */

/**
 * Returns true ifthe player is connected and alive, false ifnot.
 *
 * @param clientIndex		The client index.
 * @param clientAlive		(Optional) Set to true to validate that the client is alive, false to ignore.
 *
 * @return					True or false.
 **/
stock bool IsPlayerExist(int clientIndex, bool clientAlive = true)
{
	// If client isn't valid
	if(clientIndex <= 0 || clientIndex > MaxClients)
	{
		return false;
	}
	
	// If client isn't connected
	if(!IsClientConnected(clientIndex))
	{
		return false;
	}

	// If client isn't in game
	if(!IsClientInGame(clientIndex))
	{
		return false;
	}

	// If client isn't alive
	if(clientAlive && !IsPlayerAlive(clientIndex))
	{
		return false;
	}
	
	// If client exist
	return true;
}

/**
 * Returns whether a player has exact of the specified admin flag or not.
 *
 * @param clientIndex		The client index.
 *
 * @return					True or false.
 **/
stock bool IsPlayerHasFlag(int clientIndex, AdminFlag iFlag = Admin_Generic)
{
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		return false;
	}

	/*********************************
	 *                               *
	 *  FLAG SIMPLE AUTHENTICATION   *
	 *                               *
	 *********************************/

	// Retrieves a client's AdminId
	AdminId iD = GetUserAdmin(clientIndex);

	// Validate id
	if(iD == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	// Return true on the success
	return GetAdminFlag(iD, iFlag);
}

/**
 * Returns whether a player has all of the specified admin flags or not.
 *
 * @param clientIndex		The client index.
 * @param sFlags			The string with flags to validate.
 *
 * @return					True or false.
 */
stock bool IsPlayerHasFlags(int clientIndex, const char[] sFlags)
{
	// Validate normal user
	if(!strlen(sFlags))
	{
		return true;
	}
	
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		return false;
	}

	/*********************************
	 *                               *
	 *   FLAG BASED AUTHENTICATION   *
	 *                               *
	 *********************************/
	
	#define ADMFLAG_BYTE	(1<<view_as<int>(i))
	
    // Retrieves a client's AdminId
	AdminId iD = GetUserAdmin(clientIndex);

	// Validate id
	if(iD == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	// Get number of flags
	int iCount, iFound, iFlag = ReadFlagString(sFlags);

	// Loop through access levels (flags) for admins
	for (AdminFlag i = Admin_Reservation; i <= Admin_Custom6; i++)
	{
		// Validate bitwise values definitions for admin flags
		if(iFlag & ADMFLAG_BYTE)
		{
			iCount++;

			// Validate flag
			if(GetAdminFlag(iD, i))
			{
				iFound++;
			}
		}
	}

	// Return true on the success
	return (iCount == iFound);
}  

/**
 * Returns whether a player is in a spesific group or not.
 *
 * @param clientIndex		The client index.
 * @param sGroup     		The SourceMod group name to check.
 *
 * @return              	True or false.
 **/
stock bool IsPlayerInGroup(int clientIndex, const char[] sGroup)
{
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		return false;
	}

	/*********************************
	 *                               *
	 *   FLAG GROUP AUTHENTICATION   *
	 *                               *
	 *********************************/
	
	// Retrieves a client's AdminId
    AdminId iD = GetUserAdmin(clientIndex);
    
    // Validate id
    if(iD == INVALID_ADMIN_ID)
    {
        return false;
    }
    
    // Get number of groups
    int  nGroup = GetAdminGroupCount(iD);
    static char sGroupName[NORMAL_LINE_LENGTH];
    
    // Validate number of groups
    if(nGroup)
    {
        // Loop through each group
        for (int i = 0; i < nGroup; i++)
        {
            // Get group name
            GetAdminGroup(iD, i, sGroupName, sizeof(sGroupName));
            
            // Compare names
            if(StrEqual(sGroup, sGroupName, false))
            {
                return true;
            }
        }
    }
    
    // No groups or no match
    return false;
}

/*
 * Server functions
 */

/**
 * Get amount of total humans.
 * 
 * @return	 				The amount of total humans.
 **/
stock int fnGetHumans(/*void*/)
{
	// Initialize variables
	int nHumans; CBasePlayer* cBasePlayer;
	
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Get real player index from event key
		cBasePlayer = CBasePlayer(i);
		
		// Verify that the client is exist
		if(!IsPlayerExist(cBasePlayer->Index))
		{
			continue;
		}
		
		// Verify that the client is human
		if(cBasePlayer->m_bZombie)
		{
			continue;
		}
		
		// Increment amount
		nHumans++;
	}
	
	// Return amount
	return nHumans;
}

/**
 * Get amount of total zombies.
 *
 * @return	 				The amount of total zombies.
 **/
stock int fnGetZombies(/*void*/)
{
	// Initialize variables
	int nZombies; CBasePlayer* cBasePlayer;
	
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Get real player index from event key
		cBasePlayer = CBasePlayer(i);
		
		// Verify that the client is exist
		if(!IsPlayerExist(cBasePlayer->Index))
		{
			continue;
		}
		
		// Verify that the client is zombie
		if(!cBasePlayer->m_bZombie)
		{
			continue;
		}
		
		// Increment amount	
		nZombies++;
	}
	
	// Return amount
	return nZombies;
}

/**
 * Get amount of total alive players.
 *
 * @return	 				The amount of total alive players.
 **/
stock int fnGetAlive(/*void*/)
{
	// Initialize variables
	int nAlive; CBasePlayer* cBasePlayer;

	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Get real player index from event key
		cBasePlayer = CBasePlayer(i);
		
		// Verify that the client is exist
		if(!IsPlayerExist(cBasePlayer->Index))
		{
			continue;
		}
		
		// Increment amount
		nAlive++;
	}
	
	// Return amount
	return nAlive;
}

/**
 * Get index of the random player.
 *
 * @param nRandom			The random number.
 * 
 * @return	 				The index of random player.
 **/
stock int fnGetRandomAlive(int nRandom)
{
	// Initialize variables
	int nAlive; CBasePlayer* cBasePlayer;
	
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Get real player index from event key
		cBasePlayer = CBasePlayer(i);
		
		// Verify that the client is exist
		if(!IsPlayerExist(cBasePlayer->Index))
		{
			continue;
		}
		
		// Increment amount
		nAlive++;
		
		// If random number is equal, so return index
		if(nAlive == nRandom)
		{
			return i;
		}
	}
	
	// Return error
	return -1;
}

/**
 * Get amount of total playing players.
 *
 * @return	 				The amount of total playing players.
 **/
stock int fnGetPlaying(/*void*/)
{
	// Initialize variables
	int nPlaying; CBasePlayer* cBasePlayer;

	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Get real player index from event key
		cBasePlayer = CBasePlayer(i);
		
		// Verify that the client is exist
		if(!IsPlayerExist(cBasePlayer->Index, false))
		{
			continue;
		}
		
		// Increment amount
		nPlaying++;
	}
	
	// Return amount
	return nPlaying;
}