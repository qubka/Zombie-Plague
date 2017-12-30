/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          death.cpp
 *  Type:          Game 
 *  Description:   Death event.
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
 * Event callback (player_death)
 * The player is about to die.
 * 
 * @param victimIndex		The victim index.
 * @param attackerIndex		The attacker index.
 **/
void DeathOnClientDeath(int victimIndex, int attackerIndex)
{
	// Get real player index from event key
	CBasePlayer* cBaseVictim  = CBasePlayer(victimIndex);
	CBasePlayer* cBaseAttacker = CBasePlayer(attackerIndex);

	//*********************************************************************
	//*           			EMIT ZOMBIE DEATH SOUNDS           			  *
	//*********************************************************************
	
	// Is zombie died ?
	if(cBaseVictim->m_bZombie)
	{
		// Emit zombie death sound
		cBaseVictim->InputEmitAISound(SNDCHAN_STATIC, SNDLEVEL_NORMAL, cBaseVictim->m_bNemesis ? "ZOMBIE_NEMESIS_DEATH_SOUNDS" : (ZombieIsFemale(cBaseVictim->m_nZombieClass) ? "ZOMBIE_FEMALE_DEATH_SOUNDS" : "ZOMBIE_DEATH_SOUNDS"));
	}
	else
	{
		// Emit human death sound
		cBaseVictim->InputEmitAISound(SNDCHAN_STATIC, SNDLEVEL_NORMAL, cBaseVictim->m_bSurvivor ? "HUMAN_SURVIVOR_DEATH_SOUNDS" : (HumanIsFemale(cBaseVictim->m_nHumanClass) ? "HUMAN_FEMALE_DEATH_SOUNDS" : "HUMAN_DEATH_SOUNDS"));
	}
	
	//*********************************************************************
	//*                  UPDATE VARIABLES OF THE PLAYER           		  *
	//*********************************************************************
	
	// Reset all timers
	ToolsResetTimers(cBaseVictim);
	
	// Reset some variables
	cBaseVictim->m_bNightVisionOn = 0;
	cBaseVictim->m_bSetGlow(false);

	// Validate round
	if(!RoundEndOnValidate())
	{
		// Player was killed by other ?
		if(cBaseVictim != cBaseAttacker) 
		{
			// If respawn amount more, than limit, stop
			if(cBaseVictim->m_nRespawnTimes > GetConVarInt(gCvarList[CVAR_RESPAWN_AMOUNT]))
			{
				return;
			}
			
			// Verify that the attacker is exist
			if(IsPlayerExist(cBaseAttacker->Index))
			{
				// Increment exp and bonuses
				if(cBaseVictim->m_bZombie)
				{
					cBaseAttacker->m_nAmmoPacks += cBaseVictim->m_bNemesis ? GetConVarInt(gCvarList[CVAR_BONUS_KILL_NEMESIS]) : GetConVarInt(gCvarList[CVAR_BONUS_KILL_ZOMBIE]);
					if(GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM])) cBaseAttacker->m_iExp += cBaseVictim->m_bNemesis ? GetConVarInt(gCvarList[CVAR_LEVEL_KILL_NEMESIS]) : GetConVarInt(gCvarList[CVAR_LEVEL_KILL_ZOMBIE]);
				}
				else
				{
					cBaseAttacker->m_nAmmoPacks += cBaseVictim->m_bSurvivor ? GetConVarInt(gCvarList[CVAR_BONUS_KILL_SURVIVOR]) : GetConVarInt(gCvarList[CVAR_BONUS_KILL_HUMAN]);
					if(GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM])) cBaseAttacker->m_iExp += cBaseVictim->m_bNemesis ? GetConVarInt(gCvarList[CVAR_LEVEL_KILL_NEMESIS]) : GetConVarInt(gCvarList[CVAR_LEVEL_KILL_HUMAN]);
				}
			}
		}
		// If player was killed by world, respawn on suicide?
		else if(!GetConVarBool(gCvarList[CVAR_RESPAWN_WORLD]))
		{
			return;
		}

		// Respawn ifhuman/zombie/nemesis/survivor?
		if((cBaseVictim->m_bZombie && !cBaseVictim->m_bNemesis && !GetConVarBool(gCvarList[CVAR_RESPAWN_ZOMBIE])) || (!cBaseVictim->m_bZombie && !cBaseVictim->m_bSurvivor && !GetConVarBool(gCvarList[CVAR_RESPAWN_HUMAN])) || (cBaseVictim->m_bNemesis && !GetConVarBool(gCvarList[CVAR_RESPAWN_NEMESIS])) || (cBaseVictim->m_bSurvivor && !GetConVarBool(gCvarList[CVAR_RESPAWN_SURVIVOR])))
		{
			return;
		}
		
		// Increment count
		cBaseVictim->m_nRespawnTimes++;
		
		// Set timer for respawn player
		delete cBaseVictim->m_hZombieRespawnTimer;
		cBaseVictim->m_hZombieRespawnTimer = CreateTimer(GetConVarFloat(gCvarList[CVAR_RESPAWN_TIME]), DeathOnRespawnZombie, cBaseVictim, TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * The player is about to respawn.
 *
 * @param hTimer     	 The timer handle.
 * @param cBaseVictim	 The victim index.
 **/
public Action DeathOnRespawnZombie(Handle hTimer, CBasePlayer* cBaseVictim)
{
	// Clear timer
	cBaseVictim->m_hZombieRespawnTimer = NULL;	
	
	// If mode doesn't started yet, then stop
	if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
	{
		return ACTION_STOP;
	}
		
	// Validate client
	if(!IsPlayerExist(cBaseVictim->Index, false))
	{
		return ACTION_STOP;
	}
	
	// Verify that the client is dead
	if(IsPlayerAlive(cBaseVictim->Index))
	{
		return ACTION_STOP;
	}
	
	// Respawn player automatically ifallowed on current round
	if((gServerData[Server_RoundMode] != GameModes_Survivor || GetConVarBool(gCvarList[CVAR_RESPAWN_ALLOW_SURVIVOR])) && (gServerData[Server_RoundMode] != GameModes_Swarm || GetConVarBool(gCvarList[CVAR_RESPAWN_ALLOW_SWARM])) && (gServerData[Server_RoundMode] != GameModes_Nemesis || GetConVarBool(gCvarList[CVAR_RESPAWN_ALLOW_NEMESIS])))
	{
		// Infection rounds = none of the above
		if(!GetConVarBool(gCvarList[CVAR_RESPAWN_INFETION]) && gServerData[Server_RoundMode] != GameModes_Survivor && gServerData[Server_RoundMode] != GameModes_Swarm && gServerData[Server_RoundMode] != GameModes_Nemesis && gServerData[Server_RoundMode] != GameModes_Armageddon)
		{
			return ACTION_STOP;
		}
		
		// Respawn ifonly the last human is left? (ignore this setting on survivor rounds)
		if(gServerData[Server_RoundMode] != GameModes_Survivor && !GetConVarBool(gCvarList[CVAR_RESPAWN_LAST]) && fnGetHumans() <= 1)
		{
			return ACTION_STOP;
		}

		// Respawn a player
		ToolsForceToRespawn(cBaseVictim);
	}
	
	// Destroy timer
	return ACTION_STOP;
}