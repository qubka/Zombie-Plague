/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          toolsfunctions.sp
 *  Type:          Module 
 *  Description:   API for offsets/signatures exposed in tools.sp
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
 * Handles for storing messages id.
 **/
UserMsg hTextMsg; UserMsg hHintText; char sEmpty[FILE_LINE_LENGTH] = "";

/**
 * @brief Creates commands for tools module.
 **/
void ToolsOnCommandInit()
{
	hTextMsg = GetUserMessageId("TextMsg");
	hHintText = GetUserMessageId("HintText");
	
	if (!hasLength(sEmpty))
	{
		for (int i = 0; i < sizeof(sEmpty) - 1; i++) 
		{
			sEmpty[i] = ' ';
		}
	}

	HookUserMessage(hTextMsg, ToolsOnMessageHook, true);
	HookUserMessage(hTextMsg, ToolsOnHintHook, true);
	HookUserMessage(hHintText, ToolsOnHintHook, true);
}

/**
 * @brief Hook tools cvar changes.
 **/
void ToolsOnCvarInit()
{
	gCvarList.LIGHT_BUTTON                 = FindConVar("zp_light_button");  
	gCvarList.LIGHT_BUTTON_BLOCK           = FindConVar("zp_light_button_block");  
	gCvarList.MESSAGES_OBJECTIVE           = FindConVar("zp_messages_objective");
	gCvarList.MESSAGES_COUNTER             = FindConVar("zp_messages_counter");
	gCvarList.MESSAGES_BLAST               = FindConVar("zp_messages_blast");
	gCvarList.MESSAGES_DAMAGE              = FindConVar("zp_messages_damage");
	gCvarList.MESSAGES_DONATE              = FindConVar("zp_messages_donate");
	gCvarList.MESSAGES_CLASS_INFO          = FindConVar("zp_messages_class_info");
	gCvarList.MESSAGES_CLASS_CHOOSE        = FindConVar("zp_messages_class_choose");
	gCvarList.MESSAGES_CLASS_DUMP          = FindConVar("zp_messages_class_dump");
	gCvarList.MESSAGES_ITEM_INFO           = FindConVar("zp_messages_item_info");
	gCvarList.MESSAGES_ITEM_ALL            = FindConVar("zp_messages_item_all");
	gCvarList.MESSAGES_WEAPON_INFO         = FindConVar("zp_messages_weapon_info");
	gCvarList.MESSAGES_WEAPON_DROP         = FindConVar("zp_messages_weapon_drop");
	gCvarList.MESSAGES_WELCOME_HUD_TIME    = FindConVar("zp_messages_welcome_hud_time");
	gCvarList.MESSAGES_WELCOME_HUD_FADEIN  = FindConVar("zp_messages_welcome_hud_fadein");
	gCvarList.MESSAGES_WELCOME_HUD_FADEOUT = FindConVar("zp_messages_welcome_hud_fadeout");
	gCvarList.MESSAGES_WELCOME_HUD_R       = FindConVar("zp_messages_welcome_hud_R");
	gCvarList.MESSAGES_WELCOME_HUD_G       = FindConVar("zp_messages_welcome_hud_G");
	gCvarList.MESSAGES_WELCOME_HUD_B       = FindConVar("zp_messages_welcome_hud_B");
	gCvarList.MESSAGES_WELCOME_HUD_A       = FindConVar("zp_messages_welcome_hud_A");
	gCvarList.MESSAGES_WELCOME_HUD_X       = FindConVar("zp_messages_welcome_hud_X");
	gCvarList.MESSAGES_WELCOME_HUD_Y       = FindConVar("zp_messages_welcome_hud_Y");
	gCvarList.MESSAGES_BLOCK               = FindConVar("zp_messages_block");
	gCvarList.SEND_TABLES                  = FindConVar("sv_sendtables");
	
	gCvarList.SEND_TABLES.IntValue = 1;
	
	HookConVarChange(gCvarList.LIGHT_BUTTON, ToolsFOnCvarHook);
	HookConVarChange(gCvarList.SEND_TABLES,  CvarsUnlockOnCvarHook);
	
	ToolsOnCommandLoad();
}

/**
 * @brief Load tools listeners changes.
 **/
void ToolsOnCommandLoad()
{
	CreateCommandListener(gCvarList.LIGHT_BUTTON, ToolsOnCommandListened);
}

/**
 * Cvar hook callback (zp_light_button)
 * @brief Flashlight module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ToolsFOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	ToolsOnCommandLoad();
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void ToolsOnClientUpdate(int client)
{
	if (IsFakeClient(client) && !gClientData[client].Zombie)
	{
		ToolsSetFlashLight(client, true);
	}
}

/**
 * Listener command callback (any)
 * @brief Usage of the on/off flashlight/nvgs.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action ToolsOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	if (IsClientValid(client))
	{
		static char sOverlay[PLATFORM_LINE_LENGTH];
		ClassGetOverlay(gClientData[client].Class, sOverlay, sizeof(sOverlay));

		if (ClassIsNvgs(gClientData[client].Class) || hasLength(sOverlay)) 
		{
			if (!gServerData.RoundEnd) /// Avoid reset round end overlays
			{
				gClientData[client].Vision = !gClientData[client].Vision;
				DataBaseOnClientUpdate(client, ColumnType_Vision);
				
				VOverlayOnClientNvgs(client);

				EmitSoundToClient(client, gClientData[client].Vision ? SOUND_NVG_ON : SOUND_NVG_OFF, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
			}
		}
		else
		{
			ToolsSetFlashLight(client, true);

			EmitSoundToClient(client, SOUND_FLASHLIGHT, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
		}
		
		return gCvarList.LIGHT_BUTTON_BLOCK.BoolValue ? Plugin_Handled : Plugin_Continue;
	}
	
	return Plugin_Continue;
}

/**
 * @brief Hook client chat messages.
 *
 * @param hMessage          The message index.
 * @param hMsg              Handle to the input bit buffer.
 * @param iPlayers          Array containing player indexes.
 * @param playersNum        Number of players in the array.
 * @param bReliable         True if message is reliable, false otherwise.
 * @param bInit             True if message is an initmsg, false otherwise.
 **/
public Action ToolsOnMessageHook(UserMsg hMessage, Protobuf hMsg, const int[] iPlayers, int playersNum, bool bReliable, bool bInit)
{
	static char sBuffer[PLATFORM_LINE_LENGTH]; 
	hMsg.ReadString("params", sBuffer, sizeof(sBuffer), 0);

	static char sBlock[PLATFORM_LINE_LENGTH];
	gCvarList.MESSAGES_BLOCK.GetString(sBlock, sizeof(sBlock)); 

	return (StrContains(sBlock, sBuffer, false) != -1) ? Plugin_Handled : Plugin_Continue; 
}

/**
 * @brief Hook client hint messages.
 *
 * @param hMessage          The message index.
 * @param hMsg              Handle to the input bit buffer.
 * @param iPlayers          Array containing player indexes.
 * @param playersNum        Number of players in the array.
 * @param bReliable         True if message is reliable, false otherwise.
 * @param bInit             True if message is an initmsg, false otherwise.
 **/
public Action ToolsOnHintHook(UserMsg hMessage, Protobuf hMsg, const int[] iPlayers, int playersNum, bool bReliable, bool bInit)
{
	static char sBuffer[FILE_LINE_LENGTH];
	
	if (hMessage == hHintText)
	{
		hMsg.ReadString("text", sBuffer, sizeof(sBuffer));
	}
	else if (hMsg.ReadInt("msg_dst") == 4)
	{
		hMsg.ReadString("params", sBuffer, sizeof(sBuffer), 0);
	}
	else
	{
		return Plugin_Continue;
	}
	
	if (StrContains(sBuffer, "</font>") != -1 || StrContains(sBuffer, "</span>") != -1)
	{
		DataPack hPack = new DataPack();
		hPack.WriteCell(playersNum);
		for (int i = 0; i < playersNum; i++)
		{
			hPack.WriteCell(iPlayers[i]);
		}
		hPack.WriteString(sBuffer);
		hPack.Reset();
		
		RequestFrame(ToolsOnMessageFix, hPack);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/**
 * @brief Called after a default hint message is created.
 *
 * @param hPack             The pack handle.
 **/
public void ToolsOnMessageFix(DataPack hPack)
{
	int iCount = 0; int iCountAll = hPack.ReadCell();
	static int clients[MAXPLAYERS+1];
	
	for (int i = 0, client; i < iCountAll; i++)
	{
		client = hPack.ReadCell();
		
		if (IsClientValid(client, false))
		{
			clients[iCount++] = client;
		}
	}
	
	if (iCount != 0)
	{
		static char sBuffer[FILE_LINE_LENGTH];
		hPack.ReadString(sBuffer, sizeof(sBuffer));

		Protobuf hMessage = view_as<Protobuf>(StartMessageEx(hTextMsg, clients, iCount, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
		
		if (hMessage != null)
		{
			hMessage.SetInt("msg_dst", 4);
			hMessage.AddString("params", "#SFUI_ContractKillStart");
			Format(sBuffer, sizeof(sBuffer), "</font>%s%s", sBuffer, sEmpty);
			hMessage.AddString("params", sBuffer);
			hMessage.AddString("params", NULL_STRING);
			hMessage.AddString("params", NULL_STRING);
			hMessage.AddString("params", NULL_STRING);
			hMessage.AddString("params", NULL_STRING);
			
			EndMessage();
		}
	}
	
	delete hPack;
}

/*
 * Stocks tools API.
 */

/**
 * @brief Respawn a player.
 *
 * @param client            The client index.
 * @return                  True on success, false otherwise. 
 **/
bool ToolsForceToRespawn(int client)
{
	if (!IsClientValid(client, false))
	{
		return false;
	}
	
	if (IsPlayerAlive(client))
	{
		return false;
	}
	
	int iDeathMatch = ModesGetMatch(gServerData.RoundMode);
	if (iDeathMatch == 1 || (iDeathMatch == 2 && GetRandomInt(0, 1)) || (iDeathMatch == 3 && fnGetHumans() < fnGetAlive() / 2))
	{
		gClientData[client].Respawn = TEAM_HUMAN;
	}
	else
	{
		gClientData[client].Respawn = TEAM_ZOMBIE;
	}

	CS_RespawnPlayer(client);
	
	return true;
}

/**
 * @brief Gets or sets the velocity of a entity.
 *
 * @param entity            The entity index.
 * @param vVelocity         The velocity output, or velocity to set on entity.
 * @param bApply            True to get entity velocity, false to set it.
 * @param bStack            If modifying velocity, then true will stack new velocity onto the entity.
 *                          current velocity, false will reset it.
 **/
void ToolsSetVelocity(int entity, float vVelocity[3], bool bApply = true, bool bStack = true)
{
	if (!bApply)
	{
		ToolsGetVelocity(entity, vVelocity);
		
		return;
	}
	
	if (bStack)
	{
		static float vVelocity2[3];
		ToolsGetVelocity(entity, vVelocity2);
		
		AddVectors(vVelocity2, vVelocity, vVelocity);
	}
	
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

/**
 * @brief Gets the velocity of a entity.
 *
 * @param entity            The entity index.
 * @param vVelocity         The velocity output.
 **/
void ToolsGetVelocity(int entity, float vVelocity[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecVelocity", vVelocity);
}

/**
 * @brief Gets the abs origin of a entity.
 *
 * @param entity            The entity index.
 * @param vPosition         The origin output.
 **/
void ToolsGetAbsOrigin(int entity, float vPosition[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
}

/**
 * @brief Gets the abs angle of a entity.
 *
 * @param entity            The entity index.
 * @param vAngle            The angle output.
 **/
void ToolsGetAbsAngles(int entity, float vAngle[3])
{
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);
}

/**
 * @brief Gets the max weapons of a entity.
 *
 * @param entity            The entity index.
 * @return                  The max weapon amount.
 **/
int ToolsGetMyWeapons(int entity)
{
	return GetEntPropArraySize(entity, Prop_Data, "m_hMyWeapons");
}

/**
 * @brief Gets weapon on the position of a entity.
 *
 * @param entity            The entity index.
 * @param iPosition         The weapon position.
 * @return                  The weapon index.
 **/
int ToolsGetWeapon(int entity, int iPosition)
{
	return GetEntPropEnt(entity, Prop_Data, "m_hMyWeapons", iPosition);
}

/**
 * @brief Gets the health of a entity.
 *
 * @param entity            The entity index.
 * @param bMax              True to get maximum value, false to get health.  
 * @return                  The health value.
 **/
int ToolsGetHealth(int entity, bool bMax = false)
{
	return GetEntProp(entity, Prop_Data, bMax ? "m_iMaxHealth" : "m_iHealth");
}

/**
 * @brief Sets the health of a entity.
 *
 * @param entity            The entity index.
 * @param iHealth           The health value.
 * @param bSet              True to set maximum value, false to modify health.  
 **/
void ToolsSetHealth(int entity, int iHealth, bool bSet = false)
{
	SetEntProp(entity, Prop_Send, "m_iHealth", iHealth);
	
	if (bSet) 
	{
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHealth);
	}
}

/**
 * @brief Gets the speed of a entity.
 *
 * @param entity            The entity index.
 * @return                  The LMV value.
 **/
float ToolsGetLMV(int entity)
{
	return GetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue");
}

/**
 * @brief Sets the speed of a entity.
 *
 * @param entity            The entity index.
 * @param flLMV             The LMV value.
 **/
void ToolsSetLMV(int entity, float flLMV)
{
	SetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue", flLMV);
}

/**
 * @brief Gets the armor of a entity.
 *
 * @param entity            The entity index.
 * @return                  The armor value.
 **/
int ToolsGetArmor(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_ArmorValue");
}

/**
 * @brief Sets the armor of a entity.
 *
 * @param entity            The entity index.
 * @param iArmor            The armor value.
 **/
void ToolsSetArmor(int entity, int iArmor)
{
	SetEntProp(entity, Prop_Send, "m_ArmorValue", iArmor);
}

/**
 * @brief Gets the team of an entity.
 * 
 * @param entity            The entity index.
 * @return                  The team index.
 **/
int ToolsGetTeam(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iTeamNum");
}

/**
 * @brief Sets the team of a entity.
 *
 * @param entity            The entity index.
 * @param iTeam             The team index.
 **/
void ToolsSetTeam(int entity, int iTeam)
{
	if (ToolsGetTeam(entity) <= TEAM_SPECTATOR) /// Fix, thanks to inklesspen!
	{
		ChangeClientTeam(entity, iTeam);
	}
	else
	{
		CS_SwitchTeam(entity, iTeam); 
	}
}

/**
 * @brief Gets nightvision values on a entity.
 *
 * @param entity            The entity index.
 * @param ownership         If true, function will return the value of the entity ownership of nightvision.
 *                          If false, function will return the value of the entity on/off state of the nightvision.
 * @return                  True if aspect of nightvision is enabled on the entity, false if not.
 **/
bool ToolsHasNightVision(int entity, bool bOwnership = false)
{
	return view_as<bool>(GetEntProp(entity, Prop_Send, bOwnership ? "m_bHasNightVision" : "m_bNightVisionOn"));
}

/**
 * @brief Controls nightvision values on a entity.
 *
 * @param entity            The entity index.
 * @param bEnable           Enable or disable an aspect of nightvision. (see ownership parameter)
 * @param bOwnership        If true, enable will toggle the entity ownership of nightvision.
 *                          If false, enable will toggle the entity on/off state of the nightvision.
 **/
void ToolsSetNightVision(int entity, bool bEnable, bool bOwnership = false)
{
	SetEntProp(entity, Prop_Send, bOwnership ? "m_bHasNightVision" : "m_bNightVisionOn", bEnable);
}

/**
 * @brief Gets defuser value on a entity.
 *
 * @param entity            The entity index.
 * @return                  The aspect of the entity defuser.
 **/
bool ToolsHasDefuser(int entity)
{
	return view_as<bool>(GetEntProp(entity, Prop_Send, "m_bHasDefuser"));
}

/**
 * @brief Controls defuser value on a entity.
 *
 * @param entity            The entity index.
 * @param bEnable           Enable or disable an aspect of defuser.
 **/
void ToolsSetDefuser(int entity, bool bEnable)
{
	SetEntProp(entity, Prop_Send, "m_bHasDefuser", bEnable);
}

/**
 * @brief Gets helmet value on a entity.
 *
 * @param entity            The entity index.
 * @return                  The aspect of the entity helmet.
 **/
bool ToolsHasHelmet(int entity)
{
	return view_as<bool>(GetEntProp(entity, Prop_Send, "m_bHasHelmet"));
}

/**
 * @brief Controls helmet value on a entity.
 *
 * @param entity            The entity index.
 * @param bEnable           Enable or disable an aspect of helmet.
 **/
void ToolsSetHelmet(int entity, bool bEnable)
{
	SetEntProp(entity, Prop_Send, "m_bHasHelmet", bEnable);
}

/**
 * @brief Gets suit value on a entity.
 *
 * @param entity            The entity index.
 * @return                  The aspect of the entity suit.
 **/
bool ToolsHasHeavySuit(int entity)
{
	return view_as<bool>(GetEntProp(entity, Prop_Send, "m_bHasHeavyArmor"));
}

/**
 * @brief Controls suit value on a entity.
 *
 * @param entity            The entity index.
 * @param bEnable           Enable or disable an aspect of suit.
 **/
void ToolsSetHeavySuit(int entity, bool bEnable)
{
	SetEntProp(entity, Prop_Send, "m_bHasHeavyArmor", bEnable);
}

/**
 * @brief Gets the active weapon index of a entity.
 *
 * @param entity            The entity index.
 * @return                  The weapon index.
 **/
int ToolsGetActiveWeapon(int entity)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");
}

/**
 * @brief Sets the active weapon index of a entity.
 *
 * @param entity            The entity index.
 * @param weapon            The weapon index.
 **/
/*void ToolsSetActiveWeapon(int entity, int weapon)
{
	SetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon", weapon);
}*/

/**
 * @brief Gets the addon bits of a entity.
 *
 * @param entity            The entity index.
 * @return                  The addon bits.
 **/
int ToolsGetAddonBits(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iAddonBits");
}

/**
 * @brief Sets the addon bits index of a entity.
 *
 * @param entity            The entity index.
 * @param iBits             The addon bits.
 **/
void ToolsSetAddonBits(int entity, int iBits)
{
	SetEntProp(entity, Prop_Send, "m_iAddonBits", iBits);
}

/**
 * @brief Gets the observer mode of a entity.
 *
 * @param entity            The entity index.
 * @return                  The mode index.
 **/
int ToolsGetObserverMode(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iObserverMode");
}

/**
 * @brief Gets the observer target of a entity.
 *
 * @param entity            The entity index.
 * @return                  The target index.
 **/
int ToolsGetObserverTarget(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_hObserverTarget");
}

/**
 * @brief Gets hitgroup value on a entity.
 *
 * @param entity            The entity index.
 * @return                  The hitgroup index.
 **/
int ToolsGetHitGroup(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_LastHitGroup");
}

/**
 * @brief Gets or sets a entity score or deaths.
 * 
 * @param entity            The entity index.
 * @param bScore            True to look at score, false to look at deaths.  
 * @return                  The score or death count of the entity.
 **/
int ToolsGetScore(int entity, bool bScore = true)
{
	return GetEntProp(entity, Prop_Data, bScore ? "m_iFrags" : "m_iDeaths");
}

/**
 * @brief Sets a entity score or deaths.
 * 
 * @param entity            The entity index.
 * @param bScore            True to look at score, false to look at deaths.  
 * @param iValue            The score/death amount.
 **/
void ToolsSetScore(int entity, bool bScore = true, int iValue = 0)
{
	SetEntProp(entity, Prop_Data, bScore ? "m_iFrags" : "m_iDeaths", iValue);
}

/**
 * @brief Sets the gravity of a entity.
 * 
 * @param entity            The entity index.
 * @param flValue           The gravity amount.
 **/
void ToolsSetGravity(int entity, float flValue)
{
	SetEntPropFloat(entity, Prop_Data, "m_flGravity", flValue);
}

/**
 * @brief Sets the spotting of a entity.
 * 
 * @param entity            The entity index.
 * @param bEnable           Enable or disable an aspect of spotting.
 **/
void ToolsSetSpot(int entity, bool bEnable)
{
	if (!bEnable)
	{
		SetEntData(entity, Player_bSpotted, false, 1, true);
		SetEntData(entity, Player_bSpottedByMask, false, _, true);
		SetEntData(entity, Player_bSpottedByMask + 4, false, _, true); /// That is table
		SetEntData(entity, Player_bSpotted - 4, 0, _, true);
	}
	else
	{
		SetEntData(entity, Player_bSpotted - 4, 9, _, true);
	}
}

/**
 * @brief Sets the detecting of a entity.
 * 
 * @param entity            The entity index.
 * @param bEnable           Enable or disable an aspect of detection.
 **/
void ToolsSetDetecting(int entity, bool bEnable)
{
	SetEntPropFloat(entity, Prop_Send, "m_flDetectedByEnemySensorTime", bEnable ? (GetGameTime() + 9999.0) : 0.0);
}

/**
 * @brief Sets the hud of a entity.
 * 
 * @param entity            The entity index.
 * @param bEnable           Enable or disable an aspect of hud.
 **/
void ToolsSetHud(int entity, bool bEnable)
{   
	SetEntProp(entity, Prop_Send, "m_iHideHUD", bEnable ? (GetEntProp(entity, Prop_Send, "m_iHideHUD") & ~HIDEHUD_CROSSHAIR) : (GetEntProp(entity, Prop_Send, "m_iHideHUD") | HIDEHUD_CROSSHAIR));
}

/**
 * @brief Sets the arms of a entity.
 * 
 * @param entity            The entity index.
 * @param sModel            The model path.
 **/
void ToolsSetArm(int entity, const char[] sModel)
{
	SetEntPropString(entity, Prop_Send, "m_szArmsModel", sModel);
}

/**
 * @brief Sets the attack delay of a entity.
 * 
 * @param entity            The entity index.
 * @param flTime            The time value.
 **/
void ToolsSetAttack(int entity, float flTime)
{
	SetEntPropFloat(entity, Prop_Send, "m_flNextAttack", flTime);
}

/**
 * @brief Sets the flashlight of a entity.
 * 
 * @param entity            The entity index.
 * @param bEnable           Enable or disable an aspect of flashlight.
 **/
void ToolsSetFlashLight(int entity, bool bEnable)
{
	ToolsSetEffect(entity, bEnable ? (ToolsGetEffect(entity) ^ EF_DIMLIGHT) : 0);
}

/**
 * @brief Sets the fov of a entity.
 * 
 * @param entity            The entity index.
 * @param iFOV              (Optional) The fov amount.
 **/
void ToolsSetFov(int entity, int iFOV = 90)
{
	SetEntProp(entity, Prop_Send, "m_iFOV", iFOV);
	SetEntProp(entity, Prop_Send, "m_iDefaultFOV", iFOV);
}

/**
 * @brief Sets body/skin for the entity.
 *
 * @param entity            The entity index.
 * @param iBody             (Optional) The body index.
 * @param iSkin             (Optional) The skin index.
 **/
void ToolsSetTextures(int entity, int iBody = -1, int iSkin = -1)
{
	if (iBody != -1) SetEntProp(entity, Prop_Send, "m_nBody", iBody);
	if (iSkin != -1) SetEntProp(entity, Prop_Send, "m_nSkin", iSkin);
}

/**
 * @brief Gets the effect of an entity.
 * 
 * @param entity            The entity index.
 * @return                  The effect value.
 **/
int ToolsGetEffect(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_fEffects");
}

/**
 * @brief Sets the effect of an entity.
 * 
 * @param entity            The entity index.
 * @param iFlags            The effect value.
 **/
void ToolsSetEffect(int entity, int iFlags)
{
	SetEntProp(entity, Prop_Send, "m_fEffects", iFlags);
}

/**
 * @brief Gets the model of an entity.
 * 
 * @param entity            The entity index.
 * @return                  The model index.
 **/
/*int ToolsGetModelIndex(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_nModelIndex");
}*/

/**
 * @brief Sets the model of an entity.
 * 
 * @param entity            The entity index.
 * @param iModel            The model index.
 **/
void ToolsSetModelIndex(int entity, int iModel)
{
	SetEntProp(entity, Prop_Send, "m_nModelIndex", iModel);
}
 
/**
 * @brief Gets the hammer ID.
 *
 * @param weapon            The entity index.
 * @return                  The hammer id.    
 **/
int ToolsGetHammerID(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

/**
 * @brief Sets the hammer ID.
 *
 * @param entity            The entity index.
 * @param iD                The hammer id.
 **/
void ToolsSetHammerID(int entity, int iD)
{
	SetEntProp(entity, Prop_Data, "m_iHammerID", iD);
}

/**
 * @brief Gets the owner of an entity.
 * 
 * @param entity            The entity index.
 * @return                  The owner index.
 **/
int ToolsGetOwner(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
}

/**
 * @brief Sets the owner of an entity.
 * 
 * @param entity            The entity index.
 * @param owner             The owner index.
 **/
void ToolsSetOwner(int entity, int owner)
{
	SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", owner);
}

/**
 * @brief Gets the parent of an entity.
 * 
 * @param entity            The entity index.
 * @return                  The parent index.
 **/
int ToolsGetParent(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_pParent");
}

/**
 * @brief Sets the parent of an entity.
 * 
 * @param entity            The entity index.
 * @param parent            The parent index.
 **/
void ToolsSetParent(int entity, int parent)
{
	SetEntPropEnt(entity, Prop_Data, "m_pParent", parent);
}

/**
 * @brief Gets the activator of an entity.
 *
 * @param entity            The entity index.
 * @return                  The activator index.
 **/
int ToolsGetActivator(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_pActivator");
}

/*_____________________________________________________________________________________________________*/


/**
 * @brief Gets the total sequence amount.
 *
 * @note The game has two methods for getting the sequence count:
 * 
 * 1. Local sequence count if the model has sequences built in the model itself.
 * 2. Virtual model sequence count if the model inherits the sequences from a different model, also known as an include model.
 *
 * @param entity            The entity index.
 * @return                  The sequence count.
 **/
int ToolsGetSequenceCount(int entity)
{
	Address pStudioHdrClass = ToolsGetStudioHdrClass(entity);
	if (pStudioHdrClass == Address_Null)
	{
		return -1;
	}
	
	Address pStudioHdrStruct = view_as<Address>(LoadFromAddress(pStudioHdrClass + view_as<Address>(StudioHdrClass_StudioHdrStruct), NumberType_Int32));
	if (pStudioHdrStruct != Address_Null)
	{
		int localSequenceCount = LoadFromAddress(pStudioHdrStruct + view_as<Address>(StudioHdrStruct_SequenceCount), NumberType_Int32);
		if (localSequenceCount)
		{
			return localSequenceCount;
		}
	}
	
	Address pVirtualModelStruct = view_as<Address>(LoadFromAddress(pStudioHdrClass + view_as<Address>(StudioHdrClass_VirualModelStruct), NumberType_Int32));
	if (pVirtualModelStruct != Address_Null)
	{
		return LoadFromAddress(pVirtualModelStruct + view_as<Address>(VirtualModelStruct_SequenceVector_Size), NumberType_Int32);
	}
	
	return -1;
}

/**
 * @brief Gets the hdr class address.
 * 
 * @param entity            The entity index.
 * @return                  The address of the hdr.    
 **/
Address ToolsGetStudioHdrClass(int entity)
{
	return view_as<Address>(GetEntData(entity, Animating_StudioHdr));
}

/**
 * @brief Gets the activity of a sequence.
 *
 * @param entity            The entity index.
 * @param iSequence         The sequence index.
 * @return                  The activity index.
 **/
int ToolsGetSequenceActivity(int entity, int iSequence)
{
	if (hSDKCallGetSequenceActivity)
	{
		return SDKCall(hSDKCallGetSequenceActivity, entity, iSequence);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "SDKCall Validation", "Failed to execute SDK call \"CBaseAnimating::GetSequenceActivity\". Update signature in \"%s\"", PLUGIN_CONFIG);
		return -1;
	}
}

/**
 * @brief Checks that the entity is a brush.
 * 
 * @param entity            The entity index.
 **/
bool ToolsIsBSPModel(int entity)
{
	if (hSDKCallIsBSPModel)
	{
		return SDKCall(hSDKCallIsBSPModel, entity);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "SDKCall Validation", "Failed to execute SDK call \"CBaseEntity::IsBSPModel\". Update signature in \"%s\"", PLUGIN_CONFIG);
		return false;
	}
}

/**
 * @brief Emulate bullet_shot on the server and does the damage calculations.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param iMode             The mode index.
 * @param iSeed             The randomizing seed.
 * @param flInaccuracy      The inaccuracy variable.
 * @param flSpread          The spread variable.
 * @param flFishTail        The fishtail variable.
 * @param iSoundType        The sound type.
 * @param flRecoilIndex     The recoil variable.
 **/
void ToolsFireBullets(int client, int weapon, const float vPosition[3], const float vAngle[3], int iMode, int iSeed, float flInaccuracy, float flSpread, float flFishTail, int iSoundType, float flRecoilIndex)
{
	TE_Start("Shotgun Shot");
	TE_WriteVector("m_vecOrigin", vPosition);
	TE_WriteFloat("m_vecAngles[0]", vAngle[0]);
	TE_WriteFloat("m_vecAngles[1]", vAngle[1]);
	TE_WriteNum("m_weapon", GetEntProp(weapon, Prop_Send, "m_Item"));
	TE_WriteNum("m_iMode", iMode);
	TE_WriteNum("m_iSeed", iSeed);
	TE_WriteNum("m_iPlayer", client - 1);
	TE_WriteFloat("m_fInaccuracy", flInaccuracy);
	TE_WriteFloat("m_fSpread", flSpread);
	TE_WriteNum("m_iSoundType", 12); /// silenced
	TE_WriteFloat("m_flRecoilIndex", flRecoilIndex);
	TE_WriteNum("m_nItemDefIndex", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
	TE_SendToAll();

	bool bCompensation = view_as<bool>(GetEntProp(client, Prop_Data, "m_bLagCompensation"));
	if (bCompensation) SetEntProp(client, Prop_Data, "m_bLagCompensation", false);
	
	if (hSDKCallFireBullets)
	{
		if (gServerData.Platform == OS_Windows)
		{
			memcpy(pFireBullets, ASMTRAMPOLINE, sizeof(ASMTRAMPOLINE));
		}
		
		SDKCall(hSDKCallFireBullets, client, weapon, 0/*CEconItemView*/, vPosition, vAngle, iMode, iSeed, flInaccuracy, flSpread, flFishTail, 0.0, iSoundType, flRecoilIndex);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Tools, "SDKCall Validation", "Failed to execute SDK call \"FX_FireBullets\". Update signature in \"%s\"", PLUGIN_CONFIG);
	}
	
	SetEntProp(client, Prop_Data, "m_bLagCompensation", bCompensation);
	
	/*Event hEvent = CreateEvent("weapon_fire");
	if (hEvent != null)
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.SetString("weapon", WeaponsGetCustomID(weapon));
		hEvent.SetBool("silenced", false);

		hEvent.Fire(false);
	}*/
}

/**
 * @brief Sets the player progress bar.
 *
 * @param client            The client index.
 * @param iDuration         The duration in the seconds.
 **/
void ToolsSetProgressBarTime(int client, int iDuration)
{
	float flGameTime = GetGameTime();
	
	SetEntData(client, Player_iProgressBarDuration, iDuration, 4, true);
	SetEntDataFloat(client, Player_flProgressBarStartTime, flGameTime, true);
	SetEntDataFloat(client, Entity_flSimulationTime, flGameTime + float(iDuration), true);
	
	SetEntData(client, Player_iBlockingUseActionInProgress, 0, 4, true);
}

/**
 * @brief Sets the player progress bar.
 *
 * @param client            The client index.
 * @param iDuration         The duration in the seconds.
 **/
void ToolsResetProgressBarTime(int client)
{
	SetEntDataFloat(client, Player_flProgressBarStartTime, 0.0, true);
	SetEntData(client, Player_iProgressBarDuration, 0, 1, true);
}