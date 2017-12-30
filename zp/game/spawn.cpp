/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          spawn.cpp
 *  Type:          Game 
 *  Description:   Spawn event.
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
 * The player is spawning.
 *
 * @param clientIndex		The client index.
 **/
void SpawnOnClientSpawn(int clientIndex)
{
	// Get real player index from event key
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex); 

	//*********************************************************************
	//*         BUGFIX WITH UPDATE MODELS AND LIGHT OF THE PLAYER         *
	//*********************************************************************
	
	// Initialize boolean
	bool weaponUpdate = (cBasePlayer->m_bSurvivor || cBasePlayer->m_bZombie) ? true : false;
	
	//*********************************************************************
	//*                  UPDATE VARIABLES OF THE PLAYER           		  *
	//*********************************************************************
	
	// Reset all timers
	ToolsResetTimers(cBasePlayer);
	
	// Reset some variables
	cBasePlayer->m_bZombie 			 = false;
	cBasePlayer->m_bSurvivor 		 = false;
	cBasePlayer->m_bNemesis 		 = false;
	cBasePlayer->m_bSkill 			 = false;
	cBasePlayer->m_nSkillCountDown 	 = 0;
	cBasePlayer->m_bNightVisionOn 	 = 0;
	cBasePlayer->m_nLastBoughtAmount = 0;
	cBasePlayer->m_bDrawViewmodel    = true;
	cBasePlayer->m_flModelScale      = 1.0;
	cBasePlayer->m_iMoveType 		 = MOVETYPE_WALK;
	cBasePlayer->m_iFOV(90);
	cBasePlayer->m_bSetGlow(false);
	cBasePlayer->m_bFlashLightOn(false);
	cBasePlayer->m_bHideHUD(true);
	cBasePlayer->m_iRender(255, 255, 255);

	// Update or clean screen overlay
	VOverlayOnClientUpdate(cBasePlayer->Index, Overlay_Reset);
	
	//*********************************************************************
	//*               CHOOSING HUMAN TEAM OR INFECT HIM           		  *
	//*********************************************************************
	
	// If gamemode started ?
	if(gServerData[Server_RoundStart])
	{
		// Respawn as zombie?
		if(cBasePlayer->m_bRespawn == TEAM_ZOMBIE)
		{
			// Make a zombie
			InfectHumanToZombie(cBasePlayer, _, _, true);
			return;
		}
		
		// Respawn as human ?
		else
		{
			// Switch to CT
			cBasePlayer->m_iTeamNum = TEAM_HUMAN;
		}
	}
	
	// If did not, then clear some variables
	else
	{
		// Reset respawn count
		cBasePlayer->m_nRespawnTimes = 0;
		
		// Reset limit of extra items
		ItemsRemoveLimits(cBasePlayer->Index);
	}
	
	//*********************************************************************
	//* 			UPDATE MODELS AND SET HUMAN CLASS PROPERTIES          *
	//*********************************************************************
	
	// If player spawn like a zombie or survivor, then update all weapons for bugfix with custom models
	// and also remove possible light entities for dealthmatch modes
	if(weaponUpdate)
	{
		// Remove player's weapons
		cBasePlayer->CItemRemoveAll();
		
		// Give default weapon
		cBasePlayer->CItemMaterialize(IsFakeClient(cBasePlayer->Index) ? GetRandomInt(0,1) ? "weapon_negev" : "weapon_ak47" : GetRandomInt(0,1) ? "weapon_glock" : "weapon_usp_silencer");
		
		// Delete light
		if(GetConVarBool(gCvarList[CVAR_NEMESIS_GLOW]) || GetConVarBool(gCvarList[CVAR_SURVIVOR_GLOW])) VEffectRemoveLightDynamic(cBasePlayer->Index);
	}

	// Update human class
	cBasePlayer->m_nHumanClass = cBasePlayer->m_nHumanNext; HumanOnValidate(cBasePlayer);

	// Set health, speed, gravity and armor
	cBasePlayer->m_iHealth 				 = HumanGetHealth(cBasePlayer->m_nHumanClass) + (GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]) ? RoundToFloor((GetConVarFloat(gCvarList[CVAR_LEVEL_HEALTH_RATIO]) * float(cBasePlayer->m_iLevel))) : 0);
	cBasePlayer->m_flLaggedMovementValue = HumanGetSpeed(cBasePlayer->m_nHumanClass) + (GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]) ? (GetConVarFloat(gCvarList[CVAR_LEVEL_SPEED_RATIO]) * float(cBasePlayer->m_iLevel)) : 0.0);
	cBasePlayer->m_flGravity 			 = HumanGetGravity(cBasePlayer->m_nHumanClass) + (GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]) ? (GetConVarFloat(gCvarList[CVAR_LEVEL_GRAVITY_RATIO]) * float(cBasePlayer->m_iLevel)) : 0.0);
	cBasePlayer->m_iArmorValue 		 	 = (cBasePlayer->m_iArmorValue < HumanGetArmor(cBasePlayer->m_nHumanClass)) ? HumanGetArmor(cBasePlayer->m_nHumanClass) : cBasePlayer->m_iArmorValue;
	
	// Initialize model chars
	static char sArm[PLATFORM_MAX_PATH];
	static char sModel[PLATFORM_MAX_PATH]; 
	
	// Get human's models
	HumanGetArmModel(cBasePlayer->m_nHumanClass, sArm, sizeof(sArm));
	HumanGetModel(cBasePlayer->m_nHumanClass, sModel, sizeof(sModel));
	
	// Apply models
	cBasePlayer->m_ModelName(sModel, sArm);
}