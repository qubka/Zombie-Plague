/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          runcmd.cpp
 *  Type:          Game
 *  Description:   Hook buttons, and initiliaze commands and menus.
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
 * Called when a clients movement buttons are being processed.
 *  
 * @param clientIndex		The client index.
 * @param bitFlags			Copyback buffer containing the current commands (as bitflags - see entity_prop_stocks.inc).
 * @param clientAlive		If true, then will be apply for the alive client.
 **/ 
Action RunCmdOnPlayerRunCmd(int clientIndex, int &bitFlags, bool clientAlive)
{
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Update client money HUD
	cBasePlayer->m_iAccount(cBasePlayer->m_nAmmoPacks);
	
	// Button menu hooks
	if(bitFlags & (1 << GetConVarInt(gCvarList[CVAR_GAME_CUSTOM_MENU])))
	{
		// Open the main menu
		if(cBasePlayer->m_bMenuEmpty()) MenuMain(cBasePlayer);
	}
	
	// If player is alive ?
	if(clientAlive)
	{
		//!! IMPORTANT BUG FIX !!//
		// Ladder can reset gravity, so update it each frame
		cBasePlayer->m_flGravity = cBasePlayer->m_bNemesis ? GetConVarFloat(gCvarList[CVAR_NEMESIS_GRAVITY]) : (cBasePlayer->m_bZombie ? ZombieGetGravity(cBasePlayer->m_nZombieClass) : HumanGetGravity(cBasePlayer->m_nHumanClass));

		// Update client position on the radar
		cBasePlayer->m_bSpotted(!cBasePlayer->m_bZombie);
		
		// Button leap hooks
		if((bitFlags & IN_JUMP) && (bitFlags & IN_DUCK))
		{	
			// Do jump
			JumpBoostOnClientLeapJump(cBasePlayer);
		}
		else
		{
			// Do restore health
			SkillsOnHealthRegen(cBasePlayer);
		}
	}
	else 
	{
		//!! IMPORTANT BUG FIX !!//
		// Choose random team for the new clients
		if(cBasePlayer->m_iTeamNum == TEAM_NONE || cBasePlayer->m_iTeamNum == TEAM_SPECTATOR)
		{
			// Swith team to random
			cBasePlayer->m_iTeamNum = GetRandomInt(TEAM_ZOMBIE, TEAM_HUMAN);
		}
		
		// Block hooks of the bot control button
		bitFlags &= (~IN_USE);
		return ACTION_CHANGED;
	}
	
	// Allow hooks
	return ACTION_CONTINUE;
}