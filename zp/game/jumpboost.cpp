/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          jumpboost.cpp
 *  Type:          Game 
 *  Description:   Modified jump vector magnitudes.
 *
 *  Copyright (C) 2015-2016 Nikita Ushakov (Ireland, Dublin)
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
 * Client is jumping.
 * 
 * @param clientIndex		The client index.
 **/
void JumpBoostOnClientJump(int clientIndex)
{ 
	// If jump boost disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_JUMPBOOST_ENABLE]))
	{
		return;
	}
	
	// Get real player index from event key
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Creates a single use next frame hook
	RequestFrame(view_as<RequestFrameCallback>(JumpBoostOnClientJumpPost), cBasePlayer);
}  

/**
 * Client is jumping. *(Post)
 *
 * @param cBasePlayer		The client index.
 **/
public void JumpBoostOnClientJumpPost(CBasePlayer* cBasePlayer)
{
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return;
	}

	// Initialize velocity vector
	float vVelocity[3];
	
	// Get the client's velocity
	cBasePlayer->m_flVelocity(vVelocity);
	
	// Only apply horizontal multiplier ifit's not a bhop
	if(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0)) < GetConVarFloat(gCvarList[CVAR_JUMPBOOST_MAX]))
	{
		// Apply horizontal multipliers to jump vector
		vVelocity[0] *= GetConVarFloat(gCvarList[CVAR_JUMPBOOST_MULTIPLIER]);
		vVelocity[1] *= GetConVarFloat(gCvarList[CVAR_JUMPBOOST_MULTIPLIER]);
	}

	// Apply height multiplier to jump vector
	vVelocity[2] *= GetConVarFloat(gCvarList[CVAR_JUMPBOOST_MULTIPLIER]);

	// Push the player
	cBasePlayer->m_iTeleportPlayer(NULL_VECTOR, NULL_VECTOR, vVelocity);
}

/**
 * Called when player want do the leap jump.
 *
 * @param cBasePlayer		The client index.
 **/
void JumpBoostOnClientLeapJump(CBasePlayer* cBasePlayer)
{
	// If not on the ground, then stop
	if(!(cBasePlayer->m_iFlags & FL_ONGROUND))
	{
		return;
	}

	//*********************************************************************
	//*            		INITIALIZE LEAP JUMP PROPERTIES        	  		  *
	//*********************************************************************
	
	// Initialize variable
	float flCountDown;
	
	// Verify that the client is zombie
	if(cBasePlayer->m_bZombie)
	{
		// Verify that the client is nemesis
		if(cBasePlayer->m_bNemesis)
		{
			// If nemesis leap disabled, then stop
			if(!GetConVarBool(gCvarList[CVAR_LEAP_NEMESIS])) 
			{
				return;
			}
			
			// Get countdown time
			flCountDown = GetConVarFloat(gCvarList[CVAR_LEAP_NEMESIS_COUNTDOWN]);
		}
		
		// If not
		else
		{
			// Switch type of leap jump
			switch(GetConVarInt(gCvarList[CVAR_LEAP_ZOMBIE]))
			{
				// If zombie leap disabled, then stop
				case 0 :
				{
					return;
				}
				// If zombie leap just for single zombie
				case 2 :
				{
					if(fnGetZombies() > 1) 
					{
						return;
					}
				}
			}
			
			// Get countdown time
			flCountDown = GetConVarFloat(gCvarList[CVAR_LEAP_ZOMBIE_COUNTDOWN]);
		}
	}
	
	// If not
	else
	{
		// Verify that the client is survivor
		if(cBasePlayer->m_bSurvivor)
		{
			// If survivor leap disabled, then stop
			if(!GetConVarBool(gCvarList[CVAR_LEAP_SURVIVOR]))
			{
				return;
			}
			
			// Get countdown time
			flCountDown = GetConVarFloat(gCvarList[CVAR_LEAP_SURVIVOR_COUNTDOWN]);
		}
		
		// If player is human, stop
		else return;
	}
	
	//*********************************************************************
	//*            		 CHECK DELAY OF THE LEAP JUMP           	  	  *
	//*********************************************************************
	
	// Initialize variable
	static float flDelay[MAXPLAYERS+1];
	
	// Returns the game time based on the game tick
	float flCurrentTime = GetEngineTime();
	
	// Cooldown don't over yet, then stop
	if(flCurrentTime - flDelay[cBasePlayer->Index] < flCountDown)
	{
		return;
	}
	
	// Update the leap jump delay
	flDelay[cBasePlayer->Index] = flCurrentTime;
	
	//*********************************************************************
	//*            				DO THE LEAP JUMP           	  			  *
	//*********************************************************************
	
	// Initialize some floats
	static float vAngle[3]; static float vOrigin[3]; static float vVelocity[3];
	
	// Get client's location and view direction
	cBasePlayer->m_flGetOrigin(vOrigin);
	cBasePlayer->m_flGetEyeAngles(vAngle);
	
	// Store zero's angle
	float flAngleZero = vAngle[0];	
	
	// Get location's angles
	vAngle[0] = -30.0;
	GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
	
	// Scale vector for the boost
	ScaleVector(vVelocity, cBasePlayer->m_bSurvivor ? GetConVarFloat(gCvarList[CVAR_LEAP_SURVIVOR_FORCE]) : (cBasePlayer->m_bNemesis ? GetConVarFloat(gCvarList[CVAR_LEAP_NEMESIS_FORCE]) : GetConVarFloat(gCvarList[CVAR_LEAP_ZOMBIE_FORCE])));
	
	// Restore eye angle
	vAngle[0] = flAngleZero;
	
	// Push the player
	cBasePlayer->m_iTeleportPlayer(vOrigin, vAngle, vVelocity);
}