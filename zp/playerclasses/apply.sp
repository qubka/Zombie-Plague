/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          apply.sp
 *  Type:          Module
 *  Description:   Functions for applying attributes of class on a client.
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
 * @brief Client has been spawned.
 * 
 * @param client            The victim index.
 * @param attacker          The attacker index.
 **/
void ApplyOnClientSpawn(int client)
{ 
	if (gServerData.RoundNew) 
	{
		gClientData[client].TeleTimes = 0;
		gClientData[client].RespawnTimes = 0;
		gClientData[client].Respawn = TEAM_HUMAN;
		
		ItemsRemoveLimits(client);
	}
	
	gClientData[client].SpawnTime = GetGameTime();

	switch (gClientData[client].Respawn)
	{
		case TEAM_ZOMBIE : 
		{
			ApplyOnClientUpdate(client, -1, ModesGetTypeZombie(gServerData.RoundMode));
		}
		
		case TEAM_HUMAN  : 
		{
			ApplyOnClientUpdate(client, -1, ModesGetTypeHuman(gServerData.RoundMode));
		}
	}    
}

/**
 * @brief Infects/humanize a client.
 *
 * @param client            The victim index.
 * @param attacker          (Optional) The attacker index. (0=world, -1=respawn)
 * @param iType             (Optional) The class type. (-2=zombie, -3=human)
 * @return                  True or false.
 **/
bool ApplyOnClientUpdate(int client, int attacker = 0, int iType = -2)
{
	if (!IsPlayerExist(client))
	{
		return false;
	}
	
	if (iType == -2) iType = gServerData.Zombie;
	else if (iType == -3) iType = gServerData.Human;
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	if (iType == gServerData.Human)
	{
		gClientData[client].Class = gClientData[client].HumanClassNext; HumanValidateClass(client);
		gClientData[client].Zombie = false;
		gClientData[client].Custom = false;
		
		if (gServerData.RoundNew)
		{
			if (gCvarList.HUMAN_MENU.BoolValue)
			{
				ClassMenu(client, "choose humanclass", gServerData.Human, gClientData[client].HumanClassNext, true);
			}
		}
	}
	else if (iType == gServerData.Zombie)
	{
		gClientData[client].Class = gClientData[client].ZombieClassNext; ZombieValidateClass(client);
		gClientData[client].Zombie = true;
		gClientData[client].Custom = false;
		
		if (gCvarList.ZOMBIE_MENU.BoolValue)
		{
			ClassMenu(client, "choose zombieclass", gServerData.Zombie, gClientData[client].ZombieClassNext, true);
		}
	}
	else
	{
		int iD = ClassTypeToRandomClassIndex(iType);
		if (iD == -1)
		{
			static char sType[SMALL_LINE_LENGTH];
			gServerData.Types.GetString(iD, sType, sizeof(sType));
			
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache class type: \"%s\"", sType);
			return false;
		}

		gClientData[client].Class = iD;
		gClientData[client].Zombie = ClassIsZombie(gClientData[client].Class);
		gClientData[client].Custom = true;
	}
	
	gClientData[client].ResetTimers();
	
	ToolsSetFlashLight(client, false);
	ToolsSetDetecting(client, false);
	ToolsResetProgressBarTime(client);
	ToolsSetLMV(client, 1.0);

	if (WeaponsRemoveAll(client, attacker > 0)) /// Give default
	{
		static int iWeapon[SMALL_LINE_LENGTH];
		ClassGetWeapon(gClientData[client].Class, iWeapon, sizeof(iWeapon));

		for (int i = 0; i < sizeof(iWeapon); i++)
		{
			WeaponsGive(client, iWeapon[i], false);
		}
	}
	
	ToolsSetHealth(client, ClassGetHealth(gClientData[client].Class) + (gCvarList.LEVEL_SYSTEM.BoolValue ? RoundToNearest(gCvarList.LEVEL_HEALTH_RATIO.FloatValue * float(gClientData[client].Level)) : 0), true);
	ToolsSetGravity(client, ClassGetGravity(gClientData[client].Class) + (gCvarList.LEVEL_SYSTEM.BoolValue ? (gCvarList.LEVEL_GRAVITY_RATIO.FloatValue * float(gClientData[client].Level)) : 0.0));
	ToolsSetArmor(client, (ToolsGetArmor(client) < ClassGetArmor(gClientData[client].Class)) ? ClassGetArmor(gClientData[client].Class) : ToolsGetArmor(client));
	ToolsSetHud(client, ClassIsCross(gClientData[client].Class));
	ToolsSetSpot(client, ClassIsSpot(gClientData[client].Class));
	ToolsSetFov(client, ClassGetFov(gClientData[client].Class));

	static char sModel[PLATFORM_LINE_LENGTH];
	
	ClassGetModel(gClientData[client].Class, sModel, sizeof(sModel));
	if (hasLength(sModel)) SetEntityModel(client, sModel);
	
	ClassGetArmModel(gClientData[client].Class, sModel, sizeof(sModel)); 
	if (hasLength(sModel)) ToolsSetArm(client, sModel);
	
	if (gCvarList.MESSAGES_CLASS_INFO.BoolValue)
	{
		ClassGetInfo(gClientData[client].Class, sModel, sizeof(sModel));
		
		if (hasLength(sModel)) TranslationPrintHintText(client, sModel);
	}

	/*_________________________________________________________________________________________________________________________________________*/
	
	if (IsPlayerExist(attacker, false)) 
	{
		static char sIcon[SMALL_LINE_LENGTH];
		gCvarList.ICON_INFECT.GetString(sIcon, sizeof(sIcon));
		DeathCreateIcon(GetClientUserId(client), GetClientUserId(attacker), sIcon, gCvarList.ICON_HEAD.BoolValue);
		
		ToolsSetScore(attacker, true, ToolsGetScore(attacker, true) + 1);
		ToolsSetScore(client, false, ToolsGetScore(client, false) + 1);

		LevelSystemOnSetExp(attacker, gClientData[attacker].Exp + ClassGetExp(gClientData[attacker].Class, BonusType_Infect));
		AccountSetClientCash(attacker, gClientData[attacker].Money + ClassGetMoney(gClientData[attacker].Class, BonusType_Infect));
		
		if (IsPlayerAlive(attacker)) 
		{
			ToolsSetHealth(attacker, ToolsGetHealth(attacker) + ClassGetLifeSteal(gClientData[attacker].Class));
		}
	}
	else if (!attacker) /// Not respawn on spawn
	{
		if (ModesIsEscape(gServerData.RoundMode))
		{
			SpawnTeleportToRespawn(client);
		}
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	if (gClientData[client].Zombie)
	{
		SoundsOnClientInfected(client, attacker);
		VEffectsOnClientInfected(client, attacker);
	}
	else
	{
		VEffectsOnClientHumanized(client);
	}
	
	ToolsOnClientUpdate(client);
	SoundsOnClientUpdate(client);
	SkillSystemOnClientUpdate(client);
	LevelSystemOnClientUpdate(client);
	HitGroupsOnClientUpdate(client);
	VEffectsOnClientUpdate(client);
	bool bOpen = ArsenalOnClientUpdate(client);
	MarketOnClientUpdate(client, !bOpen); /// prevent opening two menus at once
	VOverlayOnClientUpdate(client, Overlay_Reset);
	if (gClientData[client].Vision) VOverlayOnClientUpdate(client, Overlay_Vision);
	_call.AccountOnClientUpdate(client);
	_call.WeaponsOnClientUpdate(client);

	if (!gServerData.RoundNew)
	{
		if (gClientData[client].Zombie)
		{
			ToolsSetTeam(client, TEAM_ZOMBIE);
		}
		else
		{
			ToolsSetTeam(client, TEAM_HUMAN);
			
			ToolsSetDetecting(client, ModesIsXRay(gServerData.RoundMode));
		}
		
		ModesValidateRound();
	}
	
	if (IsFakeClient(client))
	{
		delete gClientData[client].ThinkTimer;
		gClientData[client].ThinkTimer = CreateTimer(GetRandomFloat(10.0, 30.0), ApplyOnBotClientThink, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		gClientData[client].Money += GetRandomInt(5000, 20000);
	}

	gForwardData._OnClientUpdated(client, attacker);
	return true;
}

/**
 * @brief Sets a client team index. (Alive only)
 *
 * @param client            The client index.
 * @param iTeam             The team index.
 **/
void ApplyOnClientTeam(int client, int iTeam)
{
	bool bState = ToolsHasDefuser(client);
	ToolsSetTeam(client, iTeam);
	ToolsSetDefuser(client, bState); 

	ToolsSetDetecting(client, ModesIsXRay(gServerData.RoundMode));
}

/**
 * @brief Timer callback, bot think.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ApplyOnBotClientThink(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);

	gClientData[client].ThinkTimer = null;

	if (client)
	{
		SkillSystemOnFakeClientThink(client);
		MarketOnFakeClientThink(client);
		WeaponsOnFakeClientThink(client);
		CostumesOnFakeClientThink(client);

		gClientData[client].ThinkTimer = CreateTimer(GetRandomFloat(10.0, 30.0), ApplyOnBotClientThink, userID, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}