/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          healthsprite.sp
 *  Type:          Module
 *  Description:   Show a health bar above a player.
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
 * @brief Health module load function.
 **/         
void HealthOnLoad()
{
	if (!gCvarList.VEFFECTS_HEALTH.BoolValue)
	{
		return;
	}
	
	static char sSprite[PLATFORM_LINE_LENGTH];
	gCvarList.VEFFECTS_HEALTH_SPRITE.GetString(sSprite, sizeof(sSprite));
	if (hasLength(sSprite))
	{
		Format(sSprite, sizeof(sSprite), "materials/%s", sSprite);
		DecryptPrecacheTextures("self", sSprite);
		PrecacheGeneric(sSprite, true);
	}
} 

/**
 * @brief Hook health cvar changes.
 **/
void HealthOnCvarInit()
{
	gCvarList.VEFFECTS_HEALTH          = FindConVar("zp_veffects_health");
	gCvarList.VEFFECTS_HEALTH_SPRITE   = FindConVar("zp_veffects_health_sprite");
	gCvarList.VEFFECTS_HEALTH_SCALE    = FindConVar("zp_veffects_health_scale");
	gCvarList.VEFFECTS_HEALTH_VAR      = FindConVar("zp_veffects_health_var");
	gCvarList.VEFFECTS_HEALTH_FRAMES   = FindConVar("zp_veffects_health_frames");
	gCvarList.VEFFECTS_HEALTH_DURATION = FindConVar("zp_veffects_health_duration");
	gCvarList.VEFFECTS_HEALTH_HEIGHT   = FindConVar("zp_veffects_health_height");
	
	HookConVarChange(gCvarList.VEFFECTS_HEALTH,        HealthOnCvarHook);    
	HookConVarChange(gCvarList.VEFFECTS_HEALTH_SPRITE, HealthOnCvarHook);  
}

/**
 * Cvar hook callback (zp_veffects_health, zp_veffects_health_sprite)
 * @brief Health sprite module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void HealthOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	HealthOnLoad();
}

/**
 * Hook: SetTransmit
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entity            The entity index.
 * @param client            The client index.
 **/
public Action HealthOnTransmit(int entity, int client)
{
	if (GetEdictFlags(entity) & FL_EDICT_ALWAYS)
	{
		SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
	}

	int parent = ToolsGetParent(entity);

	if (parent == client || (ToolsGetObserverMode(client) == SPECMODE_FIRSTPERSON && parent == ToolsGetObserverTarget(client)))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/**
 * @brief Client has been changed class state.
 *
 * @param client            The client index.
 **/
void HealthOnClientUpdate(int client)
{
	if (!gCvarList.VEFFECTS_HEALTH.BoolValue)
	{
		return;
	}

	if (!HealthCreateSprite(client))
	{
		HealthHideSprite(client);
	}
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void HealthOnClientDeath(int client)
{
	if (!gCvarList.VEFFECTS_HEALTH.BoolValue)
	{
		return;
	}
	
	HealthHideSprite(client);
}

/**
 * @brief Client has been hurt.
 *
 * @param client            The client index.
 * @param attacker          The attacker index.
 * @param iHealth           The health amount.
 **/ 
void HealthOnClientHurt(int client, int attacker, int iHealth)
{
	if (!gCvarList.VEFFECTS_HEALTH.BoolValue || !ClassIsHealthSprite(gClientData[client].Class))
	{
		return;
	}

	int entity = EntRefToEntIndex(gClientData[attacker].AttachmentHealth);
	
	if (entity != -1) 
	{
		if (GetClientOfUserId(gClientData[attacker].LastAttacker) != client)
		{
			AcceptEntityInput(entity, "ClearParent");

			static float vPosition[3];
			ToolsGetAbsOrigin(client, vPosition); 
			vPosition[2] += gCvarList.VEFFECTS_HEALTH_HEIGHT.FloatValue; // Add height
			
			TeleportEntity(entity, vPosition, NULL_VECTOR, NULL_VECTOR);
			
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client, entity);
			ToolsSetParent(entity, client);
			
			gClientData[attacker].LastAttacker = GetClientUserId(client);
		}

		if (iHealth <= 0 || UTIL_GetRenderColor(client, Color_Alpha) <= 0) 
		{ 
			HealthHideAllSprites(client);
			return; 
		}
		
		AcceptEntityInput(entity, "ShowSprite");
		
		HealthShowSprite(attacker, HealthGetFrame(client));
		
		gClientData[attacker].HealthDuration = gCvarList.VEFFECTS_HEALTH_DURATION.FloatValue;
		
		delete gClientData[attacker].SpriteTimer;
		gClientData[attacker].SpriteTimer = CreateTimer(0.1, HealthOnClientSprite, GetClientUserId(attacker), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * @brief Timer callback, update a player sprite with health.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action HealthOnClientSprite(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);

	if (client)
	{
		int entity = EntRefToEntIndex(gClientData[client].AttachmentHealth);
		
		if (entity != -1) 
		{
			if (gClientData[client].HealthDuration <= 0.0)
			{
				AcceptEntityInput(entity, "HideSprite");  
		
				gClientData[client].SpriteTimer = null;
				
				return Plugin_Stop;
			}
			
			gClientData[client].HealthDuration -= 0.1;
			
			userID = GetClientOfUserId(gClientData[client].LastAttacker);
			if (userID)
			{
				if (UTIL_GetRenderColor(userID, Color_Alpha) <= 0)
				{
					AcceptEntityInput(entity, "HideSprite");  
			
					gClientData[client].SpriteTimer = null;
					
					return Plugin_Stop;
				}
		
				HealthShowSprite(client, HealthGetFrame(userID));

				return Plugin_Continue;
			}
		}
	}

	gClientData[client].SpriteTimer = null;
	
	return Plugin_Stop;
}
 
/*
 * Stocks health API.
 */ 

/**
 * @brief Create an attachment health sprite for the client.
 *
 * @param client            The client index.
 * @return                  True on the creation, false otherwise.
 **/ 
bool HealthCreateSprite(int client)
{
	if (EntRefToEntIndex(gClientData[client].AttachmentHealth) != -1 ||
	   EntRefToEntIndex(gClientData[client].AttachmentController) != -1) 
	{
		return false;
	}
	
	static char sSprite[PLATFORM_LINE_LENGTH];
	static char sScale[SMALL_LINE_LENGTH];
	
	gCvarList.VEFFECTS_HEALTH_SPRITE.GetString(sSprite, sizeof(sSprite));
	gCvarList.VEFFECTS_HEALTH_SCALE.GetString(sScale, sizeof(sScale));
	
	int entity = UTIL_CreateSprite(client, _, _, _, sSprite, sScale, "7");
	
	if (entity != -1)
	{
		AcceptEntityInput(entity, "HideSprite");

		SDKHook(entity, SDKHook_SetTransmit, HealthOnTransmit);

		gClientData[client].AttachmentHealth = EntIndexToEntRef(entity);
	}

	gCvarList.VEFFECTS_HEALTH_VAR.GetString(sScale, sizeof(sScale));
	
	int controller = UTIL_CreateSpriteController(entity, sSprite, sScale); 
	
	if (controller != -1)
	{
		gClientData[client].AttachmentController = EntIndexToEntRef(controller);
	}   

	return true;
}

/**
 * @brief Hide the health sprite to all attackers.
 *
 * @param client            The client index.
 **/ 
void HealthHideAllSprites(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (GetClientOfUserId(gClientData[i].LastAttacker) == client)
		{
			HealthHideSprite(i);
		}
	}
}

/**
 * @brief Hide the health sprite to the client.
 *
 * @param client            The client index.
 **/ 
void HealthHideSprite(int client)
{
	int entity = EntRefToEntIndex(gClientData[client].AttachmentHealth);
	if (entity != -1) AcceptEntityInput(entity, "HideSprite");
}

/**
 * @brief Show the health sprite to the client.
 *
 * @param client            The client index.
 * @param iFrame            The frame index.
 **/ 
void HealthShowSprite(int client, int iFrame)
{
	int entity = EntRefToEntIndex(gClientData[client].AttachmentController);

	if (entity != -1) 
	{
		static char sFrame[SMALL_LINE_LENGTH];
		FormatEx(sFrame, sizeof(sFrame), "%d -1 0 0", iFrame);
		
		SetVariantString(sFrame);
		AcceptEntityInput(entity, "StartAnimSequence");
	}
}

/**
 * @brief Gets the frame index.
 *
 * @param client            The client index.
 **/ 
int HealthGetFrame(int client)
{
	float flMaxFrames = gCvarList.VEFFECTS_HEALTH_FRAMES.FloatValue - 1.0;
	float flFrame = float(ToolsGetHealth(client)) / float(ClassGetHealth(gClientData[client].Class)) * flMaxFrames;

	return (flFrame > flMaxFrames) ? RoundToNearest(flMaxFrames) : RoundToNearest(flFrame);
}
