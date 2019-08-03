/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          healthsprite.cpp
 *  Type:          Module
 *  Description:   Show a health bar above a player.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
void HealthOnLoad(/*void*/)
{
    // If health sprite disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_HEALTH].BoolValue)
    {
        return;
    }
    
    // Load health sprite material
    static char sSprite[PLATFORM_LINE_LENGTH];
    gCvarList[CVAR_VEFFECTS_HEALTH_SPRITE].GetString(sSprite, sizeof(sSprite));
    if(hasLength(sSprite))
    {
        // Precache material
        Format(sSprite, sizeof(sSprite), "materials/%s", sSprite);
        DecryptPrecacheTextures(sSprite);
        PrecacheGeneric(sSprite, true);
    }
} 

/**
 * @brief Hook health cvar changes.
 **/
void HealthOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_VEFFECTS_HEALTH]          = FindConVar("zp_veffects_health");
    gCvarList[CVAR_VEFFECTS_HEALTH_SPRITE]   = FindConVar("zp_veffects_health_sprite");
    gCvarList[CVAR_VEFFECTS_HEALTH_SCALE]    = FindConVar("zp_veffects_health_scale");
    gCvarList[CVAR_VEFFECTS_HEALTH_VAR]      = FindConVar("zp_veffects_health_var");
    gCvarList[CVAR_VEFFECTS_HEALTH_FRAMES]   = FindConVar("zp_veffects_health_frames");
    gCvarList[CVAR_VEFFECTS_HEALTH_DURATION] = FindConVar("zp_veffects_health_duration");
    gCvarList[CVAR_VEFFECTS_HEALTH_HEIGHT]   = FindConVar("zp_veffects_health_height");
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_HEALTH],        HealthOnCvarHook);    
    HookConVarChange(gCvarList[CVAR_VEFFECTS_HEALTH_SPRITE], HealthOnCvarHook);  
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
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Forward event to modules
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
    // Allow particle to be transmittable
    if(GetEdictFlags(entity) & FL_EDICT_ALWAYS)
    {
        SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
    }

    // Gets parent of the entity
    int parent = ToolsGetParent(entity);

    // Validate observer mode
    if(parent == client || (ToolsGetObserverMode(client) == SPECMODE_FIRSTPERSON && parent == ToolsGetObserverTarget(client)))
    {
        // Block transmitting
        return Plugin_Handled;
    }

    // Allow transmitting
    return Plugin_Continue;
}

/**
 * @brief Client has been changed class state.
 *
 * @param client            The client index.
 **/
void HealthOnClientUpdate(int client)
{
    // If health sprite disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_HEALTH].BoolValue)
    {
        return;
    }

    // Create a sprite
    if(!HealthCreateSprite(client))
    {
        // If it exists, then hide sprite
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
    // If health sprite disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_HEALTH].BoolValue)
    {
        return;
    }
    
    // If it exists, then hide sprite 
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
    // If health sprite disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_HEALTH].BoolValue || !ClassIsHealthSprite(gClientData[client].Class))
    {
        return;
    }

    // Gets current sprite from the client reference
    int entity = EntRefToEntIndex(gClientData[attacker].AttachmentHealth);
    
    // Validate sprite
    if(entity != -1) 
    {
        // If if a new victim, then re-parent
        if(GetClientOfUserId(gClientData[attacker].LastAttacker) != client)
        {
            // Remove parent of the entity
            AcceptEntityInput(entity, "ClearParent");

            // Gets client top position
            static float vPosition[3];
            ToolsGetAbsOrigin(client, vPosition); 
            vPosition[2] += gCvarList[CVAR_VEFFECTS_HEALTH_HEIGHT].FloatValue; // Add height
            
            // Teleport the entity
            TeleportEntity(entity, vPosition, NULL_VECTOR, NULL_VECTOR);
            
            // Sets parent to the entity
            SetVariantString("!activator");
            AcceptEntityInput(entity, "SetParent", client, entity);
            ToolsSetParent(entity, client);
            
            // Store the client cache
            gClientData[attacker].LastAttacker = GetClientUserId(client);
        }

        // Validate death/invisibility
        if(iHealth <= 0 || UTIL_GetRenderColor(client, Color_Alpha) <= 0) 
        { 
            HealthHideAllSprites(client);
            return; 
        }
        
        // Make it visible
        AcceptEntityInput(entity, "ShowSprite");
        
        // Calculate frame and update sprite
        HealthShowSprite(attacker, HealthGetFrame(client));
        
        // Sets timer for updating sprite
        gClientData[attacker].HealthDuration = gCvarList[CVAR_VEFFECTS_HEALTH_DURATION].FloatValue;
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
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID);

    // Validate client
    if(client)
    {
        // Gets current sprite from the client reference
        int entity = EntRefToEntIndex(gClientData[client].AttachmentHealth);
        
        // Validate sprite
        if(entity != -1) 
        {
            // If duration is over, then stop
            if(gClientData[client].HealthDuration <= 0.0)
            {
                // Make it invisible
                AcceptEntityInput(entity, "HideSprite");  
        
                // Clear timer
                gClientData[client].SpriteTimer = null;
                
                // Destroy timer
                return Plugin_Stop;
            }
            
            // Substitute counter
            gClientData[client].HealthDuration -= 0.1;
            
            // Gets victim index
            userID = GetClientOfUserId(gClientData[client].LastAttacker);
            if(userID)
            {
                // Validate invisibility
                if(UTIL_GetRenderColor(userID, Color_Alpha) <= 0)
                {
                    // Make it invisible
                    AcceptEntityInput(entity, "HideSprite");  
            
                    // Clear timer
                    gClientData[client].SpriteTimer = null;
                    
                    // Destroy timer
                    return Plugin_Stop;
                }
        
                // Calculate frame and update sprite
                HealthShowSprite(client, HealthGetFrame(userID));

                // Allow timer
                return Plugin_Continue;
            }
        }
    }

    // Clear timer
    gClientData[client].SpriteTimer = null;
    
    // Destroy timer
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
    // Validate entities
    if(EntRefToEntIndex(gClientData[client].AttachmentHealth) != -1 ||
       EntRefToEntIndex(gClientData[client].AttachmentController) != -1) 
    {
        return false;
    }
    
    // Initialize sprite char
    static char sSprite[PLATFORM_LINE_LENGTH];
    static char sScale[SMALL_LINE_LENGTH];
    
    // Gets health sprite
    gCvarList[CVAR_VEFFECTS_HEALTH_SPRITE].GetString(sSprite, sizeof(sSprite));
    
    // Gets sprite scale
    gCvarList[CVAR_VEFFECTS_HEALTH_SCALE].GetString(sScale, sizeof(sScale));
    
    // Create an attach sprite
    int entity = UTIL_CreateSprite(client, _, _, _, sSprite, sScale, "7");
    
    // Validate entity
    if(entity != -1)
    {
        // Hide it
        AcceptEntityInput(entity, "HideSprite");

        // Hook entity callbacks
        SDKHook(entity, SDKHook_SetTransmit, HealthOnTransmit);

        // Store the client cache
        gClientData[client].AttachmentHealth = EntIndexToEntRef(entity);
    }

    // Gets sprite var
    gCvarList[CVAR_VEFFECTS_HEALTH_VAR].GetString(sScale, sizeof(sScale));
    
    // Create a shader controller sprite
    int controller = UTIL_CreateSpriteController(entity, sSprite, sScale); 
    
    // Validate entity
    if(controller != -1)
    {
        // Store the client cache
        gClientData[client].AttachmentController = EntIndexToEntRef(controller);
    }   

    // Validate success
    return true;
}

/**
 * @brief Hide the health sprite to all attackers.
 *
 * @param client            The client index.
 **/ 
void HealthHideAllSprites(int client)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(GetClientOfUserId(gClientData[i].LastAttacker) == client)
        {
            // Hide it!
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
    // Gets current sprite from the client reference
    int entity = EntRefToEntIndex(gClientData[client].AttachmentHealth);
    if(entity != -1) AcceptEntityInput(entity, "HideSprite");
}

/**
 * @brief Show the health sprite to the client.
 *
 * @param client            The client index.
 * @param iFrame            The frame index.
 **/ 
void HealthShowSprite(int client, int iFrame)
{
    // Gets current controller from the client reference
    int entity = EntRefToEntIndex(gClientData[client].AttachmentController);

    // Validate controller
    if(entity != -1) 
    {
        // Initialize frame char
        static char sFrame[SMALL_LINE_LENGTH];
        FormatEx(sFrame, sizeof(sFrame), "%i -1 0 0", iFrame);
        
        // Sets modified flags on the entity
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
    // Calculate the frames
    float flMaxFrames = gCvarList[CVAR_VEFFECTS_HEALTH_FRAMES].FloatValue - 1.0;
    float flFrame = float(ToolsGetHealth(client)) / float(ClassGetHealth(gClientData[client].Class)) * flMaxFrames;

    // Return the frame position
    return (flFrame > flMaxFrames) ? RoundToNearest(flMaxFrames) : RoundToNearest(flFrame);
}