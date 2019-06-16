/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          visualambience.cpp
 *  Type:          Module
 *  Description:   Fog, light style, sky, sun rendering, etc
 *
 *  Copyright (C) 2015-2019  Greyscale, Richard Helgeby
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
 * @brief Hook ambience cvar changes.
 **/
void VAmbienceOnCvarInit(/*void*/)
{
    // Creates cvars
    gCvarList[CVAR_VEFFECTS_LIGHTSTYLE_VALUE] = FindConVar("zp_veffects_lightstyle_value");
    gCvarList[CVAR_VEFFECTS_LIGHTSTYLE]       = FindConVar("zp_veffects_lightstyle");       
    gCvarList[CVAR_VEFFECTS_SKY_PATH]         = FindConVar("zp_veffects_sky_path");
    gCvarList[CVAR_VEFFECTS_SKY]              = FindConVar("zp_veffects_sky");              
    gCvarList[CVAR_VEFFECTS_SKYNAME]          = FindConVar("sv_skyname");
    gCvarList[CVAR_VEFFECTS_SUN_DISABLE]      = FindConVar("zp_veffects_sun_disable");      
    gCvarList[CVAR_VEFFECTS_FOG_COLOR]        = FindConVar("zp_veffects_fog_color");
    gCvarList[CVAR_VEFFECTS_FOG_DENSITY]      = FindConVar("zp_veffects_fog_density");
    gCvarList[CVAR_VEFFECTS_FOG_STARTDIST]    = FindConVar("zp_veffects_fog_startdist");
    gCvarList[CVAR_VEFFECTS_FOG_ENDDIST]      = FindConVar("zp_veffects_fog_enddist");
    gCvarList[CVAR_VEFFECTS_FOG_FARZ]         = FindConVar("zp_veffects_fog_farz");
    gCvarList[CVAR_VEFFECTS_FOG]              = FindConVar("zp_veffects_fog");   
    
    // Hook lightstyle cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_LIGHTSTYLE],       VAmbienceOnCvarHookLightStyle);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_LIGHTSTYLE_VALUE], VAmbienceOnCvarHookLightStyle);
    
    // Hook sky cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_SKY],              VAmbienceOnCvarHookSky);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_SKY_PATH],         VAmbienceOnCvarHookSky);
    
    // Hook sun cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_SUN_DISABLE],      VAmbienceOnCvarHookSunDisable);
    
    // Hook fog cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG],              VAmbienceOnCvarHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_COLOR],        VAmbienceOnCvarHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_DENSITY],      VAmbienceOnCvarHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_STARTDIST],    VAmbienceOnCvarHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_ENDDIST],      VAmbienceOnCvarHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_FARZ],         VAmbienceOnCvarHookFog);
}

/**
 * Cvar hook callback (zp_veffects_lightstyle, zp_veffects_lightstyle_value)
 * @brief Enable or disable light feature on the server.
 * 
 * @param convar            The cvar handle.
 * @param oldvalue          The value before change.
 * @param newvalue          The new value.
 **/
public void VAmbienceOnCvarHookLightStyle(ConVar iConVar, char[] oldValue, char[] newValue)
{
    // If lightstyle is disabled, then disable
    bool bLightStyle = gCvarList[CVAR_VEFFECTS_LIGHTSTYLE].BoolValue;
    
    // Apply light style.
    VAmbienceApplyLightStyle(!bLightStyle);
}

/**
 * Cvar hook callback (zp_veffects_sky, zp_veffects_sky_path)
 * @brief Enable or disable sun feature on the server.
 * 
 * @param convar            The cvar handle.
 * @param oldvalue          The value before change.
 * @param newvalue          The new value.
 **/
public void VAmbienceOnCvarHookSky(ConVar iConVar, char[] oldValue, char[] newValue)
{
    // If sky is disabled, then stop
    bool bSky = gCvarList[CVAR_VEFFECTS_SKY].BoolValue;
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate real client
        if(IsPlayerExist(i, false))
        {
            // Apply new sky
            VAmbienceApplySky(i, !bSky);
        }
    }
}

/**
 * Cvar hook callback (zp_veffects_sun_disable)
 * @brief Enable or disable sun feature on the server.
 * 
 * @param convar            The cvar handle.
 * @param oldvalue          The value before change.
 * @param newvalue          The new value.
 **/
public void VAmbienceOnCvarHookSunDisable(ConVar iConVar, char[] oldValue, char[] newValue)
{
    // If sun is disabled, then stop
    bool bSun = gCvarList[CVAR_VEFFECTS_SUN_DISABLE].BoolValue;
    
    // Apply sun
    VAmbienceApplySunDisable(!bSun);
}

/**
 * Cvar hook callback (zp_veffects_fog_*)
 * @brief Enable or disable fog feature on the server.
 * 
 * @param convar            The cvar handle.
 * @param oldvalue          The value before change.
 * @param newvalue          The new value.
 **/
public void VAmbienceOnCvarHookFog(ConVar iConVar, char[] oldValue, char[] newValue)
{
    // If fog is disabled, then stop
    bool bFog = gCvarList[CVAR_VEFFECTS_FOG].BoolValue;
    
    // Apply fog
    VAmbienceApplyFog(!bFog);
}

/**
 * @brief Apply all cvar values on the server.
 **/
void VAmbienceOnLoad(/*void*/)
{
    // If lightstyle is disabled, then stop
    bool bLightstyle = gCvarList[CVAR_VEFFECTS_LIGHTSTYLE].BoolValue;
    
    // Apply light style
    VAmbienceApplyLightStyle(!bLightstyle);

    // If fog is disabled, then disable
    bool bFog = gCvarList[CVAR_VEFFECTS_FOG].BoolValue;
    
    // Apply fog
    VAmbienceApplyFog(!bFog);
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void VAmbienceOnClientInit(int client)
{
    // If sky is disabled, then stop
    bool bSky = gCvarList[CVAR_VEFFECTS_SKY].BoolValue; 
    
    // Apply new sky
    VAmbienceApplySky(client, !bSky);
}

/*
 * Stocks ambient API.
 */

/**
 * @brief Apply light style on the server.
 *
 * @param bDisable          (Optional) State boolean.
 **/
void VAmbienceApplyLightStyle(bool bDisable = false)
{
    // If default, then set to normal light style
    if(bDisable)
    {
        // Sets light style
        SetLightStyle(0, "n");
        return;
    }

    // Searching fog lights entities
    int iLight = -1;
    while((iLight = FindEntityByClassname(iLight, "env_cascade_light")) != -1) 
    { 
        AcceptEntityInput(iLight, "Kill");
    }

    // Gets light value
    static char sLightStyleValue[4];
    gCvarList[CVAR_VEFFECTS_LIGHTSTYLE_VALUE].GetString(sLightStyleValue, sizeof(sLightStyleValue));

    // If light value contants 'a', render of textures will be remove
    if(StrContains(sLightStyleValue, "a", true) != -1)
    {
        // Sets darkest light style
        SetLightStyle(0, "b");
        return;
    }

    // Sets light style
    SetLightStyle(0, sLightStyleValue);
}

/**
 * @brief Apply sky on the client.
 *
 * @param client            The client index.
 * @param bDisable          (Optional) State boolean. 
 **/
void VAmbienceApplySky(int client, bool bDisable = false)
{
    // Validate real client
    if(IsFakeClient(client))
    {
        return;
    }
    
    // Default sky of current map
    static char VAmbienceDefaultSky[PLATFORM_LINE_LENGTH];

    // Store map default sky before applying new one
    gCvarList[CVAR_VEFFECTS_SKYNAME].GetString(VAmbienceDefaultSky, sizeof(VAmbienceDefaultSky));

    // If default, then set to default sky
    if(bDisable)
    {
        // Is it non empty ?
        if(hasLength(VAmbienceDefaultSky))
        {
            // Sets default sky to the client
            gCvarList[CVAR_VEFFECTS_SKYNAME].ReplicateToClient(client, VAmbienceDefaultSky);
        }
        return;
    }

    // Gets sky path
    static char sSkyPath[PLATFORM_LINE_LENGTH];
    gCvarList[CVAR_VEFFECTS_SKY_PATH].GetString(sSkyPath, sizeof(sSkyPath));

    // Sets new sky to the client
    gCvarList[CVAR_VEFFECTS_SKYNAME].ReplicateToClient(client, sSkyPath);
}

/**
 * @brief Apply sun on the server.
 *
 * @param bDisable          (Optional) State boolean.
 **/
void VAmbienceApplySunDisable(bool bDisable = false)
{
    // Find sun entity
    int iSun = -1; 
    while((iSun = FindEntityByClassname(iSun, "env_sun")) != -1)
    {
        // If default, then re-enable sun rendering
        if(bDisable)
        {
            // Turn on sun rendering
            AcceptEntityInput(iSun, "TurnOn");
            return;
        }
        
        // Turn off sun rendering
        AcceptEntityInput(iSun, "TurnOff");
    }
}

/**
 * @brief Apply fog on the server.
 *
 * @param bDisable          (Optional) State boolean.
 **/
void VAmbienceApplyFog(bool bDisable = false)
{
    // If fog is disabled, then stop
    if(bDisable)
    {
        return;
    }

    // Searching fog controlling entity
    int controller = FindEntityByClassname(-1, "env_fog_controller");

    // If fog controlling entity doens't exist, then create it
    if(controller == -1)
    {
        controller = CreateEntityByName("env_fog_controller");
        if(controller != -1) DispatchSpawn(controller); else return;
    }
    
    // Sets density of the fog
    DispatchKeyValueFloat(controller, "fogmaxdensity", gCvarList[CVAR_VEFFECTS_FOG_DENSITY].FloatValue);

    // Sets start distance of the fog
    SetVariantInt(gCvarList[CVAR_VEFFECTS_FOG_STARTDIST].IntValue);
    AcceptEntityInput(controller, "SetStartDist");

    // Sets end distance of the fog
    SetVariantInt(gCvarList[CVAR_VEFFECTS_FOG_ENDDIST].IntValue);
    AcceptEntityInput(controller, "SetEndDist");

    // Sets plain distance of the fog
    SetVariantInt(gCvarList[CVAR_VEFFECTS_FOG_FARZ].IntValue);
    AcceptEntityInput(controller, "SetFarZ");

    // Gets color
    static char sFogColor[16];
    gCvarList[CVAR_VEFFECTS_FOG_COLOR].GetString(sFogColor, sizeof(sFogColor));
    
    // Sets main color
    SetVariantString(sFogColor);
    AcceptEntityInput(controller, "SetColor");

    // Sets secondary color
    SetVariantString(sFogColor);
    AcceptEntityInput(controller, "SetColorSecondary");
    
    // Turn on fog rendering
    AcceptEntityInput(controller, "TurnOn");
}
