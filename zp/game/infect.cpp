/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          infect.cpp
 *  Type:          Game 
 *  Description:   Provides functions for managing classes.
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
 * Infects a client.
 *
 * @param cBaseVictim		The victim index.
 * @param cBaseAttacker		(Optional) The attacker index.
 * @param nemesisMode		(Optional) Indicates that victim will be a nemesis.
 * @param respawnMode		(Optional) Indicates that infection was on spawn.
 **/
void InfectHumanToZombie(CBasePlayer* cBaseVictim, CBasePlayer* cBaseAttacker = view_as<CBasePlayer>(0), bool nemesisMode = false, bool respawnMode = false)
{
	// Validate client 
	if(!IsPlayerExist(cBaseVictim->Index))
	{
		return;
	}

	//*********************************************************************
	//*             BUGFIX WITH THE SURVIVOR DYNAMIC LIGHT           	  *
	//*********************************************************************
	
	// Delete light
	if(cBaseVictim->m_bSurvivor)
	{
		if(GetConVarBool(gCvarList[CVAR_SURVIVOR_GLOW])) VEffectRemoveLightDynamic(cBaseVictim->Index);
	}
	
	//*********************************************************************
	//*                  UPDATE VARIABLES OF THE PLAYER           		  *
	//*********************************************************************
	
	// Reset all timers
	ToolsResetTimers(cBaseVictim);
	
	// Reset some variables
	cBaseVictim->m_bZombie 					= true;
	cBaseVictim->m_bSurvivor 				= false;
	cBaseVictim->m_bSkill 			 		= false;
	cBaseVictim->m_nSkillCountDown 	 		= 0;
	cBaseVictim->m_bNightVisionOn			= GetConVarInt(gCvarList[CVAR_ZOMBIE_NIGHT_VISION]);
	cBaseVictim->m_iMoveType 				= MOVETYPE_WALK;
	cBaseVictim->m_iFOV(GetConVarInt(gCvarList[CVAR_ZOMBIE_FOV]));
	cBaseVictim->m_bSetGlow(false);
	cBaseVictim->m_bFlashLightOn(false); 
	cBaseVictim->m_bHideHUD(false);
	cBaseVictim->m_iRender(255, 255, 255);
	
	//*********************************************************************
	//* 		   UPDATE MODELS AND SET ZOMBIE CLASS PROPERTIES          *
	//*********************************************************************
	
	// Initialize model char
	static char sModel[PLATFORM_MAX_PATH];
	
	// Set nemesis properties
	if(nemesisMode)
	{
		// Set nemesis variable
		cBaseVictim->m_bNemesis 			 = true;
		
		// Update zombie class
		cBaseVictim->m_nZombieClass 		 = 0;
		
		// Create dymanic light 
		if(GetConVarBool(gCvarList[CVAR_NEMESIS_GLOW]) && gServerData[Server_RoundMode] == GameModes_Nemesis) 
		{
			// Get glowing color
			static char sColor[SMALL_LINE_LENGTH];
			GetConVarString(gCvarList[CVAR_NEMESIS_GLOW_COLOR], sColor, sizeof(sColor)); 
			
			// Create dymanic light
			VEffectLightDynamic(_, sColor, 1000.0, 150.0, 999.9, true, cBaseVictim->Index);
		}
		
		// Set health, speed and gravity and armor
		cBaseVictim->m_iHealth 	   			 = (fnGetAlive() * GetConVarInt(gCvarList[CVAR_NEMESIS_HEALTH]));
		cBaseVictim->m_flLaggedMovementValue = GetConVarFloat(gCvarList[CVAR_NEMESIS_SPEED]); 
		cBaseVictim->m_flGravity 			 = GetConVarFloat(gCvarList[CVAR_NEMESIS_GRAVITY]);
		cBaseVictim->m_iArmorValue 			 = 0;
		
		// Get nemesis's model
		GetConVarString(gCvarList[CVAR_NEMESIS_PLAYER_MODEL], sModel, sizeof(sModel)); 
	}
	
	// Set zombie properties
	else
	{
		// Update zombie class
		cBaseVictim->m_nZombieClass = cBaseVictim->m_nZombieNext; ZombieOnValidate(cBaseVictim);

		// Set health, speed and gravity and armor
		cBaseVictim->m_iHealth 				 = ZombieGetHealth(cBaseVictim->m_nZombieClass) + ((fnGetZombies() <= 1) ? GetConVarInt(gCvarList[CVAR_ZOMBIE_FISRT_HEALTH]) : (GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]) ? RoundToFloor((GetConVarFloat(gCvarList[CVAR_LEVEL_HEALTH_RATIO]) * float(cBaseVictim->m_iLevel))) : 0));
		cBaseVictim->m_flLaggedMovementValue = ZombieGetSpeed(cBaseVictim->m_nZombieClass) + (GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]) ? (GetConVarFloat(gCvarList[CVAR_LEVEL_SPEED_RATIO]) * float(cBaseVictim->m_iLevel)) : 0.0);
		cBaseVictim->m_flGravity 			 = ZombieGetGravity(cBaseVictim->m_nZombieClass) + (GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]) ? (GetConVarFloat(gCvarList[CVAR_LEVEL_GRAVITY_RATIO]) * float(cBaseVictim->m_iLevel)) : 0.0);
		cBaseVictim->m_iArmorValue 			 = 0;
		
		// Get zombie's model
		ZombieGetModel(cBaseVictim->m_nZombieClass, sModel, sizeof(sModel));
	}
	
	// Apply model
	cBaseVictim->m_ModelName(sModel);
	
	//*********************************************************************
	//*           REWARDS AND BONUSES FOR INFECTOR OF THE HUMAN           *
	//*********************************************************************
	
	// Verify that the infector is exist
	if(IsPlayerExist(cBaseAttacker->Index)) 
	{
		// Create and send custom death icon
		Event sEvent = CreateEvent("player_death");
		if(sEvent != NULL)
		{
			SetEventInt(sEvent, "userid", GetClientUserId(cBaseVictim->Index));
			SetEventInt(sEvent, "attacker", GetClientUserId(cBaseAttacker->Index));
			SetEventString(sEvent, "weapon", "weapon_claws");
			SetEventBool(sEvent, "headshot", true);
			FireEvent(sEvent, false);
		}
		
		// Increment kills and frags
		cBaseVictim->m_iDeaths++;
		cBaseAttacker->m_iFrags++;
		
		// Increment exp and bonuses
		cBaseAttacker->m_iHealth += GetConVarInt(gCvarList[CVAR_BONUS_INFECT_HEALTH]);
		cBaseAttacker->m_nAmmoPacks += GetConVarInt(gCvarList[CVAR_BONUS_INFECT]);
		if(GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM])) cBaseAttacker->m_iExp += GetConVarInt(gCvarList[CVAR_LEVEL_INFECT]);
	}
	// If infection was done by server
	else
	{
		// Return ammopacks, which was spent before server infection
		cBaseVictim->m_nAmmoPacks += cBaseVictim->m_nLastBoughtAmount;
		cBaseVictim->m_nLastBoughtAmount = 0;
	}
	
	// Remove player's weapons
	cBaseVictim->CItemRemoveAll("weapon_knife_t"); //! Give default
	
	//*********************************************************************
	//*          EMIT SOUNDS AND CREATE EFFECTS OF THE INFECTION          *
	//*********************************************************************
	
	// Is zombie respawned ?
	if(respawnMode) 
	{
		// Create spawn effect
		VEffectSpawnEffect(cBaseVictim->Index);
		
		// Emit respawn sound
		cBaseVictim->InputEmitAISound(SNDCHAN_STATIC, SNDLEVEL_NORMAL, ZombieIsFemale(cBaseVictim->m_nZombieClass) ? "ZOMBIE_FEMALE_RESPAWN_SOUNDS" : "ZOMBIE_RESPAWN_SOUNDS");
	}
	else 
	{
		// Create infect effect
		VEffectInfectEffect(cBaseVictim->Index);
		
		// Emit infect sound
		cBaseVictim->InputEmitAISound(SNDCHAN_STATIC, SNDLEVEL_NORMAL, ZombieIsFemale(cBaseVictim->m_nZombieClass) ? "HUMAN_FEMALE_INFECTION_SOUNDS" : "HUMAN_INFECTION_SOUNDS");
	}

	// Create bleeding footsteps ?
	if(GetConVarBool(gCvarList[CVAR_ZOMBIE_BLEEDING]))
	{
		CreateTimer(4.0, VEffectsBleeding, cBaseVictim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	//*********************************************************************
	//*          		 CHANGE TEAM ON THE NEXT FRAME           		  *
	//*     _MAKED FOR CORRECT SHOWING TEAM IN THE FAKE DEATH EVENT_      *
	//*********************************************************************
	
	// Change team index on the next frame
	RequestFrame(view_as<RequestFrameCallback>(InfectFrameCallback), cBaseVictim);

	// Call forward
	API_OnClientInfected(cBaseVictim->Index, cBaseAttacker->Index);
}

/**
 * Make a human.
 * 
 * @param cBasePlayer		The client index.
 **/
void MakeZombieToHuman(CBasePlayer* cBasePlayer)
{
	// Validate client 
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return;
	}
	
	// Verify that the client is zombie
	if(!cBasePlayer->m_bZombie)
	{
		return;
	}
	
	//*********************************************************************
	//*             BUGFIX WITH THE NEMESIS DYNAMIC LIGHT           	  *
	//*********************************************************************
	
	// Delete light
	if(cBasePlayer->m_bNemesis)
	{
		if(GetConVarBool(gCvarList[CVAR_NEMESIS_GLOW])) VEffectRemoveLightDynamic(cBasePlayer->Index);
	}
	
	//*********************************************************************
	//*               MAKE A HUMAN AND RESPAWN THE PLAYER           	  *
	//*********************************************************************
	
	// Initialize vector variables
	static float vOrigin[3];
	static float vEyeAngle[3];

	// Client location and view direction
	cBasePlayer->m_flGetOrigin(vOrigin);
	cBasePlayer->m_flGetEyeAngles(vEyeAngle);
	
	// Respawn a player like a human
	cBasePlayer->m_bRespawn = TEAM_HUMAN;
	cBasePlayer->m_iRespawnPlayer();
	
	// Antidot won't sent client to spawn ?
	if(!GetConVarBool(gCvarList[CVAR_HUMAN_ANTIDOT]))
	{
		// Teleport to the previus position
		cBasePlayer->m_iTeleportPlayer(vOrigin, vEyeAngle);
	}

	// Set glowing for the zombie vision
	cBasePlayer->m_bSetGlow(GetConVarBool(gCvarList[CVAR_ZOMBIE_XRAY]) ? true : false);
}

/**
 * Make a survivor.
 *
 * @param cBasePlayer		The client index.
 **/
void MakeHumanIntoSurvivor(CBasePlayer* cBasePlayer)
{
	// Validate client 
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return;
	}
	
	//*********************************************************************
	//*               			MAKE A HUMAN           	  				  *
	//*********************************************************************
	
	// If player is zombie, then humanise him
	if(cBasePlayer->m_bZombie)
	{
		MakeZombieToHuman(cBasePlayer);
	}

	//*********************************************************************
	//* 		UPDATE MODELS AND SET SURVIVOR CLASS PROPERTIES           *
	//*********************************************************************
	
	// Reset some variables
	cBasePlayer->m_bSurvivor 			= true;
	cBasePlayer->m_bSetGlow(false);
	
	// Create dymanic light
	if(GetConVarBool(gCvarList[CVAR_SURVIVOR_GLOW]) && gServerData[Server_RoundMode] == GameModes_Survivor) 
	{
		// Get glowing color
		static char sColor[SMALL_LINE_LENGTH];
		GetConVarString(gCvarList[CVAR_SURVIVOR_GLOW_COLOR], sColor, sizeof(sColor)); 
	
		// Create dymanic light
		VEffectLightDynamic(_, sColor, 1000.0, 150.0, 999.9, true, cBasePlayer->Index);
	}

	// Set survivor health, speed, gravity and armor
	cBasePlayer->m_iHealth 				 = GetConVarInt(gCvarList[CVAR_SURVIVOR_HEALTH]);
	cBasePlayer->m_flLaggedMovementValue = GetConVarFloat(gCvarList[CVAR_SURVIVOR_SPEED]); 
	cBasePlayer->m_flGravity 			 = GetConVarFloat(gCvarList[CVAR_SURVIVOR_GRAVITY]);
	cBasePlayer->m_iArmorValue 			 = 0;
	
	// Initialize model char
	static char sModel[PLATFORM_MAX_PATH];

	// Get survivor's model
	GetConVarString(gCvarList[CVAR_SURVIVOR_PLAYER_MODEL], sModel, sizeof(sModel));
	
	// Set model
	cBasePlayer->m_ModelName(sModel);
	
	// Remove player's weapons
	cBasePlayer->CItemRemoveAll("weapon_knife"); //! Give default
	
	// Initialize weapon char
	static char sWeapon[SMALL_LINE_LENGTH];
	
	// Give survivor's secondary weapon
	GetConVarString(gCvarList[CVAR_SURVIVOR_WEAPON_SECONDARY], sWeapon, sizeof(sWeapon));
	cBasePlayer->CItemMaterialize(sWeapon);
	GetConVarString(gCvarList[CVAR_SURVIVOR_WEAPON_PRIMARY], sWeapon, sizeof(sWeapon));
	cBasePlayer->CItemMaterialize(sWeapon);
	
	// Switch to CT
	cBasePlayer->m_iTeamNum = TEAM_HUMAN;

	// Call forward
	API_OnClientHeroed(cBasePlayer->Index);
}

/**
 * Changes player's team on the next frame for the right showing of the death event icon.
 *
 * @param cBasePlayer    	The client index.
 **/
public void InfectFrameCallback(CBasePlayer* cBasePlayer)
{
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return;
	}
	
	// Switch to T
	cBasePlayer->m_iTeamNum = TEAM_ZOMBIE;
	
	// Terminate the round, ifall humans was infected
	RoundEndOnValidate();
}