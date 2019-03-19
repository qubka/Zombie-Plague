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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @section Number of valid colors.
 **/
enum ColorType
{ 
    ColorType_Invalid = -1,       /** Used as return value when a color offset doens't exist. */
    
    ColorType_Red,                /** Red offset */
    ColorType_Green,              /** Green offset */
    ColorType_Blue,               /** Blue offset */
    ColorType_Alpha               /** Alpha offset */
};
/**
 * @endsection
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
        PrecacheModel(sSprite, true);
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
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public Action HealthOnTransmit(int entityIndex, int clientIndex)
{
    // Allow particle to be transmittable
    if(GetEdictFlags(entityIndex) & FL_EDICT_ALWAYS)
    {
        SetEdictFlags(entityIndex, (GetEdictFlags(entityIndex) ^ FL_EDICT_ALWAYS));
    }
    
    // Validate owner
    if(ToolsGetEntityOwner(entityIndex) != clientIndex) 
    {
        // Stop transmitting
        return Plugin_Stop;
    }

    // Allow transmitting
    return Plugin_Continue;
}

/**
 * @brief Client has been changed class state.
 *
 * @param clientIndex       The client index.
 **/
void HealthOnClientUpdate(int clientIndex)
{
    // If health sprite disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_HEALTH].BoolValue)
    {
        return;
    }

    // Create a sprite
    if(!HealthCreateSprite(clientIndex))
    {
        // If it exists, then hide sprite
        HealthHideSprite(clientIndex);
    }
}

/**
 * @brief Client has been hurt.
 *
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param iHealth           The health amount.
 **/ 
void HealthOnClientHurt(int clientIndex, int attackerIndex, int iHealth)
{
    // If health sprite disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_HEALTH].BoolValue || !ClassIsHealthSprite(gClientData[clientIndex].Class))
    {
        return;
    }

    // Gets current sprite from the client reference
    int entityIndex = EntRefToEntIndex(gClientData[attackerIndex].AttachmentHealth);
    
    // Validate sprite
    if(entityIndex != INVALID_ENT_REFERENCE) 
    {
        // If if a new victim, then re-parent
        if(GetClientOfUserId(gClientData[attackerIndex].LastAttacker) != clientIndex)
        {
            // Remove parent of the entity
            AcceptEntityInput(entityIndex, "ClearParent");
            
            // Initialize vector variables
            static float vPosition[3];
            
            // Gets client origin
            ToolsGetClientAbsOrigin(clientIndex, vPosition); 
            vPosition[2] += gCvarList[CVAR_VEFFECTS_HEALTH_HEIGHT].FloatValue; // Add height
            
            // Teleport the entity
            TeleportEntity(entityIndex, vPosition, NULL_VECTOR, NULL_VECTOR);
            
            // Sets parent to the entity
            SetVariantString("!activator");
            AcceptEntityInput(entityIndex, "SetParent", clientIndex, entityIndex);
            
            // Store the client cache
            gClientData[attackerIndex].LastAttacker = GetClientUserId(clientIndex);
        }

        // Validate death/invisibility
        if(iHealth <= 0 || ToolsGetClientRenderColor(clientIndex, ColorType_Alpha) <= 0) 
        { 
            HealthHideAllSprites(clientIndex);
            return; 
        }
        
        // Make it visible
        AcceptEntityInput(entityIndex, "ShowSprite");
        
        // Calculate frame and update sprite
        HealthShowSprite(attackerIndex, HealthGetFrame(clientIndex));
        
        // Sets timer for updating sprite
        gClientData[attackerIndex].HealthDuration = gCvarList[CVAR_VEFFECTS_HEALTH_DURATION].FloatValue;
        delete gClientData[attackerIndex].SpriteTimer;
        gClientData[attackerIndex].SpriteTimer = CreateTimer(0.1, HealthOnClientSprite, GetClientUserId(attackerIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Gets current sprite from the client reference
        int entityIndex = EntRefToEntIndex(gClientData[clientIndex].AttachmentHealth);
        
        // Validate sprite
        if(entityIndex != INVALID_ENT_REFERENCE) 
        {
            // If duration is over, then stop
            if(gClientData[clientIndex].HealthDuration <= 0.0)
            {
                // Make it invisible
                AcceptEntityInput(entityIndex, "HideSprite");  
        
                // Clear timer
                gClientData[clientIndex].SpriteTimer = null;
                
                // Destroy timer
                return Plugin_Stop;
            }
            
            // Substitute counter
            gClientData[clientIndex].HealthDuration -= 0.1;
            
            // Gets the victim index
            userID = GetClientOfUserId(gClientData[clientIndex].LastAttacker);
            if(userID)
            {
                // Validate invisibility
                if(ToolsGetClientRenderColor(userID, ColorType_Alpha) <= 0)
                {
                    // Make it invisible
                    AcceptEntityInput(entityIndex, "HideSprite");  
            
                    // Clear timer
                    gClientData[clientIndex].SpriteTimer = null;
                    
                    // Destroy timer
                    return Plugin_Stop;
                }
        
                // Calculate frame and update sprite
                HealthShowSprite(clientIndex, HealthGetFrame(userID));

                // Allow timer
                return Plugin_Continue;
            }
        }
    }

    // Clear timer
    gClientData[clientIndex].SpriteTimer = null;
    
    // Destroy timer
    return Plugin_Stop;
}
 
/*
 * Stocks health API.
 */ 

/**
 * @brief Create an attachment health sprite for the client.
 *
 * @param clientIndex       The client index.
 * @return                  True on the creation, false otherwise.
 **/ 
bool HealthCreateSprite(int clientIndex)
{
    // Validate entities
    if(EntRefToEntIndex(gClientData[clientIndex].AttachmentHealth) != INVALID_ENT_REFERENCE ||
       EntRefToEntIndex(gClientData[clientIndex].AttachmentController) != INVALID_ENT_REFERENCE) 
    {
        return false;
    }
    
    // Initialize sprite char
    static char sSprite[PLATFORM_LINE_LENGTH];
    static char sClassname[SMALL_LINE_LENGTH];
    static char sBuffer[SMALL_LINE_LENGTH];
    
    // Gets health sprite
    gCvarList[CVAR_VEFFECTS_HEALTH_SPRITE].GetString(sSprite, sizeof(sSprite));
    
    // Gets sprite scale
    gCvarList[CVAR_VEFFECTS_HEALTH_SCALE].GetString(sBuffer, sizeof(sBuffer));
    
    // Create an attach sprite entity
    int entityIndex = CreateEntityByName("env_sprite");
    
    // If entity isn't valid, then skip
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        FormatEx(sClassname, sizeof(sClassname), "sprite%d", clientIndex);
        DispatchKeyValue(entityIndex, "targetname", sClassname);
        DispatchKeyValue(entityIndex, "model", sSprite);
        DispatchKeyValue(entityIndex, "scale", sBuffer);
        DispatchKeyValue(entityIndex, "rendermode", "7");
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Activate the entity
        ActivateEntity(entityIndex);
        AcceptEntityInput(entityIndex, "HideSprite");

        // Sets parent to the entity
        ToolsSetEntityOwner(entityIndex, clientIndex);
        
        // Hook entity callbacks
        SDKHook(entityIndex, SDKHook_SetTransmit, HealthOnTransmit);

        // Store the client cache
        gClientData[clientIndex].AttachmentHealth = EntIndexToEntRef(entityIndex);
    }

    // Gets sprite var
    gCvarList[CVAR_VEFFECTS_HEALTH_VAR].GetString(sBuffer, sizeof(sBuffer));
    
    // Create a material controller entity
    entityIndex = CreateEntityByName("material_modify_control");
    
    // If entity isn't valid, then skip
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        DispatchKeyValue(entityIndex, "materialName", sSprite);
        DispatchKeyValue(entityIndex, "materialVar", sBuffer);
        
        // Spawn the entity 
        DispatchSpawn(entityIndex);

        // Sets parent to the entity
        SetVariantString(sClassname);
        AcceptEntityInput(entityIndex, "SetParent", entityIndex, entityIndex);
        
        // Store the client cache
        gClientData[clientIndex].AttachmentController = EntIndexToEntRef(entityIndex);
    }
    
    // Validate success
    return true;
}

/**
 * @brief Hide the health sprite to all attackers.
 *
 * @param clientIndex       The client index.
 **/ 
void HealthHideAllSprites(int clientIndex)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(GetClientOfUserId(gClientData[i].LastAttacker) == clientIndex)
        {
            // Hide it!
            HealthHideSprite(i);
        }
    }
}

/**
 * @brief Hide the health sprite to the client.
 *
 * @param clientIndex       The client index.
 **/ 
void HealthHideSprite(int clientIndex)
{
    // Gets current sprite from the client reference
    int entityIndex = EntRefToEntIndex(gClientData[clientIndex].AttachmentHealth);
    if(entityIndex != INVALID_ENT_REFERENCE) AcceptEntityInput(entityIndex, "HideSprite");
}

/**
 * @brief Show the health sprite to the client.
 *
 * @param clientIndex       The client index.
 * @param iFrame            The frame index.
 **/ 
void HealthShowSprite(int clientIndex, int iFrame)
{
    // Gets current controller from the client reference
    int entityIndex = EntRefToEntIndex(gClientData[clientIndex].AttachmentController);

    // Validate controller
    if(entityIndex != INVALID_ENT_REFERENCE) 
    {
        // Initialize frame char
        static char sFrame[SMALL_LINE_LENGTH];
        FormatEx(sFrame, sizeof(sFrame), "%i -1 0 0", iFrame);
        
        // Sets modified flags on the entity
        SetVariantString(sFrame);
        AcceptEntityInput(entityIndex, "StartAnimSequence");
    }
}

/**
 * @brief Gets the frame index.
 *
 * @param clientIndex       The client index.
 **/ 
int HealthGetFrame(int clientIndex)
{
    // Calculate the frames
    float flMaxFrames = gCvarList[CVAR_VEFFECTS_HEALTH_FRAMES].FloatValue - 1.0;
    float flFrame = float(ToolsGetClientHealth(clientIndex)) / float(ClassGetHealth(gClientData[clientIndex].Class)) * flMaxFrames;

    // Return the frame position
    return (flFrame > flMaxFrames) ? RoundToNearest(flMaxFrames) : RoundToNearest(flFrame);
}