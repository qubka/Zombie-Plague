/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          skillsystem.cpp
 *  Type:          Game 
 *  Description:   Provides functions for zombie skills system.
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
 * Creates commands for skills module. Called when commands are created.
 **/
void SkillsOnCommandsCreate(/*void*/)
{
	// Hook commands
	AddCommandListener(SkillsHook, "drop");
}

/**
 * Called when player restore health.
 *
 * @param cBasePlayer		The client index.
 **/
void SkillsOnHealthRegen(CBasePlayer* cBasePlayer)
{
	// If health restoring disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_ZOMBIE_RESTORE]))
	{
		return;
	}
	
	// Verify that the client is zombie
	if(!cBasePlayer->m_bZombie || cBasePlayer->m_bNemesis)
	{
		return;
	}
	
	// If health restoring disabled, then stop
	if(ZombieGetRegenInterval(cBasePlayer->m_nZombieClass) == 0.0 || ZombieGetRegenHealth(cBasePlayer->m_nZombieClass) == 0)
	{
		return;
	}
	
	//*********************************************************************
	//*            		 CHECK DELAY OF THE REGENERATION           	  	  *
	//*********************************************************************
	
	// Initialize variable
	static float flDelay[MAXPLAYERS+1];
	
	// Returns the game time based on the game tick
	float flCurrentTime = GetEngineTime();
	
	// Cooldown don't over yet, then stop
	if(flCurrentTime - flDelay[cBasePlayer->Index] < ZombieGetRegenInterval(cBasePlayer->m_nZombieClass))
	{
		return;
	}
	
	// Update the health interval delay
	flDelay[cBasePlayer->Index] = flCurrentTime;
	
	//*********************************************************************
	//*            		    DO THE REGENERATION           	  			  *
	//*********************************************************************
	
	// Initialize float
	static float vVelocity[3];
	
	// Get the client's velocity
	cBasePlayer->m_flVelocity(vVelocity);
	
	// If the zombie don't move, then check health
	if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
	{
		// If restoring is available, then do it
		if(cBasePlayer->m_iHealth < ZombieGetHealth(cBasePlayer->m_nZombieClass))
		{
			// Initialize a new health amount
			int healthAmount = cBasePlayer->m_iHealth + ZombieGetRegenHealth(cBasePlayer->m_nZombieClass);
			
			// If new health more, than set default class health
			if(healthAmount > ZombieGetHealth(cBasePlayer->m_nZombieClass))
			{
				healthAmount = ZombieGetHealth(cBasePlayer->m_nZombieClass);
			}
			
			// Update health
			cBasePlayer->m_iHealth = healthAmount;

			// Create regeneration effect
			VEffectsFadeClientScreen(cBasePlayer->Index);
			
			// Emit heal sound
			cBasePlayer->InputEmitAISound(SNDCHAN_VOICE, SNDLEVEL_CONVO, ZombieIsFemale(cBasePlayer->m_nZombieClass) ? "ZOMBIE_FEMALE_REGEN_SOUNDS" : "ZOMBIE_REGEN_SOUNDS");
		}
	}
}

/**
 * Hook client command.
 *
 * @param clientIndex		The client index.
 * @param commandMsg		Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments		Argument count.
 **/
public Action SkillsHook(int clientIndex, const char[] commandMsg, int iArguments)
{
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);
	
	// Validate client 
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return ACTION_HANDLED;
	}
	
	// If the client is survivor, than stop
	if(cBasePlayer->m_bSurvivor)
	{
		return ACTION_HANDLED;
	}
	
	// If the client isn't zombie, than allow drop
	return (cBasePlayer->m_bZombie && !cBasePlayer->m_bNemesis) ? SkillsOnStart(cBasePlayer) : ACTION_CONTINUE;
}

/**
 * Called when player press drop button.
 *
 * @param cBasePlayer		The client index.
 **/
Action SkillsOnStart(CBasePlayer* cBasePlayer)
{
	// If zombie class don't have a skill, then stop
	if(!ZombieGetSkillDuration(cBasePlayer->m_nZombieClass) && !ZombieGetSkillCountDown(cBasePlayer->m_nZombieClass))
	{
		return ACTION_HANDLED;
	}
	
	// Verify that the skills are avalible
	if(!cBasePlayer->m_bSkill && !cBasePlayer->m_nSkillCountDown)
	{
		// Call forward
		Action resultHandle = API_OnClientSkillUsed(cBasePlayer->Index);
		
		// Block skill usage
		if(resultHandle == ACTION_HANDLED || resultHandle == ACTION_STOP)
		{
			return ACTION_HANDLED;
		}

		// Set skill usage
		cBasePlayer->m_bSkill = true;
		
		// Set timer for removing skill usage
		delete cBasePlayer->m_hZombieSkillTimer;
		cBasePlayer->m_hZombieSkillTimer = CreateTimer(float(ZombieGetSkillDuration(cBasePlayer->m_nZombieClass)), SkillsOnEnd, cBasePlayer, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Allow skill
	return ACTION_HANDLED;
}

/**
 * Timer for remove a skill usage.
 *
 * @param hTimer			The timer handle.
 * @param cBasePlayer		The client index.
 **/
public Action SkillsOnEnd(Handle hTimer, CBasePlayer* cBasePlayer)
{
	// Clear timer
	cBasePlayer->m_hZombieSkillTimer = NULL;
	
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return ACTION_STOP;
	}

	// Remove skill usage and set countdown time
	cBasePlayer->m_bSkill = false;
	cBasePlayer->m_nSkillCountDown = ZombieGetSkillCountDown(cBasePlayer->m_nZombieClass);
	
	// Create counter
	CreateTimer(1.0, SkillsOnCountDown, cBasePlayer, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	// Call forward
	API_OnClientSkillOver(cBasePlayer->Index);
	
	// Destroy timer
	return ACTION_STOP;
}

/**
 * Timer for the skill countdown.
 *
 * @param hTimer			The timer handle.
 * @param cBasePlayer		The client index.
 **/
public Action SkillsOnCountDown(Handle hTimer, CBasePlayer* cBasePlayer)
{
	// Validate client
	if(IsPlayerExist(cBasePlayer->Index) && cBasePlayer->m_bZombie && !cBasePlayer->m_bNemesis)
	{
		// Substitute counter
		cBasePlayer->m_nSkillCountDown--;
		
		// If counter is over, then stop
		if(!cBasePlayer->m_nSkillCountDown)
		{
			// Show message
			TranslationPrintHintText(cBasePlayer->Index, "Skill ready");

			// Destroy timer
			return ACTION_STOP;
		}

		// Show counter
		TranslationPrintHintText(cBasePlayer->Index, "Countdown", cBasePlayer->m_nSkillCountDown);
		
		// Allow counter
		return ACTION_CONTINUE;
	}
	
	// Destroy timer
	return ACTION_STOP;
}