/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          visualambience.cpp
 *  Type:          Module
 *  Description:   Fog, light style, sky, sun rendering, etc
 *
 *  Copyright (C) 2015-2018  Greyscale, Richard Helgeby
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
 * Hook zp_veffects_* cvar changes.
 * 
 **/
void VAmbienceCvarsHook(/*void*/)
{
    // Hook lightstyle cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_LIGHTSTYLE],         VAmbienceCvarsHookLightStyle);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_LIGHTSTYLE_VALUE], VAmbienceCvarsHookLightStyle);
    
    // Hook sky cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_SKY],                 VAmbienceCvarsHookSky);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_SKY_PATH],         VAmbienceCvarsHookSky);
    
    // Hook sun cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_SUN_DISABLE],         VAmbienceCvarsHookSunDisable);
    
    // Hook fog cvars
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG],                 VAmbienceCvarsHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_COLOR],         VAmbienceCvarsHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_DENSITY],         VAmbienceCvarsHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_STARTDIST],     VAmbienceCvarsHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_ENDDIST],         VAmbienceCvarsHookFog);
    HookConVarChange(gCvarList[CVAR_VEFFECTS_FOG_FARZ],         VAmbienceCvarsHookFog);
}

/**
 * Cvar hook callback (zp_veffects_lightstyle, zp_veffects_lightstyle_value)
 * Updated server to cvar values.
 * 
 * @param convar            The cvar handle.
 * @param oldvalue          The value before change.
 * @param newvalue          The new value.
 **/
public void VAmbienceCvarsHookLightStyle(ConVar iConVar, const char[] oldValue, const char[] newValue)
{
    // If lightstyle is disabled, then disable
    bool bLightStyle = gCvarList[CVAR_VEFFECTS_LIGHTSTYLE].BoolValue;
    
    // Apply light style.
    VAmbienceApplyLightStyle(!bLightStyle);
}

/**
 * Cvar hook callback (zp_veffects_sky, zp_veffects_sky_path)
 * Updated server to cvar values.
 * 
 * @param convar            The cvar handle.
 * @param oldvalue          The value before change.
 * @param newvalue          The new value.
 **/
public void VAmbienceCvarsHookSky(ConVar iConVar, const char[] oldValue, const char[] newValue)
{
    // If sky is disabled, then disable
    bool bSky = gCvarList[CVAR_VEFFECTS_SKY].BoolValue;
    
    // Apply new sky
    VAmbienceApplySky(!bSky);
}

/**
 * Cvar hook callback (zp_veffects_sun_disable)
 * Updated server to cvar values.
 * 
 * @param convar            The cvar handle.
 * @param oldvalue          The value before change.
 * @param newvalue          The new value.
 **/
public void VAmbienceCvarsHookSunDisable(ConVar iConVar, const char[] oldValue, const char[] newValue)
{
    // If fog is disabled, then disable
    bool bSun = gCvarList[CVAR_VEFFECTS_SUN_DISABLE].BoolValue;
    
    // Apply sun
    VAmbienceApplySunDisable(!bSun);
}

/**
 * Cvar hook callback (zp_veffects_fog_*)
 * Updated server to cvar values.
 * 
 * @param convar            The cvar handle.
 * @param oldvalue          The value before change.
 * @param newvalue          The new value.
 **/
public void VAmbienceCvarsHookFog(ConVar iConVar, const char[] oldValue, const char[] newValue)
{
    // Apply fog
    VAmbienceApplyFog();
}

/**
 * Apply all cvar values on server.
 **/
void VAmbienceLoad(/*void*/)
{
    // If lightstyle is disabled, then disable
    bool bLightstyle = gCvarList[CVAR_VEFFECTS_LIGHTSTYLE].BoolValue;
    
    // Apply light style
    VAmbienceApplyLightStyle(!bLightstyle);
    
    // If sky is disabled, then disable
    bool bSky = gCvarList[CVAR_VEFFECTS_SKY].BoolValue;
    
    // Apply new sky
    VAmbienceApplySky(!bSky);
    
    // Apply fog
    VAmbienceApplyFog();
}

/**
 * Apply light style on server.
 **/
void VAmbienceApplyLightStyle(const bool bDisable = false)
{
    // If default, then set to normal light style
    if(bDisable)
    {
        // Sets light style
        SetLightStyle(0, "n");
        return;
    }

    // Searching fog lights entities
    int iLight = INVALID_ENT_REFERENCE;
    while((iLight = FindEntityByClassname(iLight, "env_cascade_light")) != -1) 
    { 
        AcceptEntityInput(iLight, "Kill");
    }

    // Gets light value
    static char sLightStyleValue[4];
    gCvarList[CVAR_VEFFECTS_LIGHTSTYLE_VALUE].GetString(sLightStyleValue, sizeof(sLightStyleValue));

    // If light value contants 'a', render of textures will be remove
    if(StrContains(sLightStyleValue, "a") != -1)
    {
        // Sets darkest light style
        SetLightStyle(0, "b");
        return;
    }

    // Sets light style
    SetLightStyle(0, sLightStyleValue);
}

/**
 * Apply sky on server.
 **/
void VAmbienceApplySky(const bool bDisable = false)
{
    // If we can't find the sv_skyname cvar, then stop
    ConVar hSkyname = gCvarList[CVAR_VEFFECTS_SKYNAME];
    if(hSkyname == INVALID_HANDLE)
    {
        return;
    }

    // Default sky of current map
    static char VAmbienceDefaultSky[PLATFORM_MAX_PATH];

    // Store map default sky before applying new one
    hSkyname.GetString(VAmbienceDefaultSky, sizeof(VAmbienceDefaultSky));

    // If default, then set to default sky
    if(bDisable)
    {
        if(strlen(VAmbienceDefaultSky))
        {
            // Sets default sky on all clients
            hSkyname.SetString(VAmbienceDefaultSky, true);
        }
        return;
    }

    // Gets sky path
    static char sSkyPath[PLATFORM_MAX_PATH];
    gCvarList[CVAR_VEFFECTS_SKY_PATH].GetString(sSkyPath, sizeof(sSkyPath));

    // Sets new sky on all clients
    hSkyname.SetString(sSkyPath, true);
}

/**
 * Apply sun on server.
 **/
void VAmbienceApplySunDisable(const bool bDisable = false)
{
    // Find sun entity
    int iSun = FindEntityByClassname(-1, "env_sun");
    
    // If sun is invalid, then stop
    if(iSun == INVALID_ENT_REFERENCE)
    {
        return;
    }
    
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

/**
 * Apply fog on server.
 **/
void VAmbienceApplyFog(/*void*/)
{
    // If fog is disabled, then stop.
    if(!gCvarList[CVAR_VEFFECTS_FOG].BoolValue)
    {
        return;
    }

    // Searching fog controlling entity
    int iFogControllerIndex = FindEntityByClassname(-1, "env_fog_controller");

    // If fog controlling entity doens't exist, then create it
    if(iFogControllerIndex == INVALID_ENT_REFERENCE)
    {
        iFogControllerIndex = CreateEntityByName("env_fog_controller");
        if(iFogControllerIndex != INVALID_ENT_REFERENCE) DispatchSpawn(iFogControllerIndex); else return;
    }

    // Sets density of the fog
    DispatchKeyValueFloat(iFogControllerIndex, "fogmaxdensity", gCvarList[CVAR_VEFFECTS_FOG_DENSITY].FloatValue);

    // Sets start distance of the fog
    SetVariantInt(gCvarList[CVAR_VEFFECTS_FOG_STARTDIST].IntValue);
    AcceptEntityInput(iFogControllerIndex, "SetStartDist");

    // Sets end distance of the fog
    SetVariantInt(gCvarList[CVAR_VEFFECTS_FOG_ENDDIST].IntValue);
    AcceptEntityInput(iFogControllerIndex, "SetEndDist");

    // Sets plain distance of the fog
    SetVariantInt(gCvarList[CVAR_VEFFECTS_FOG_FARZ].IntValue);
    AcceptEntityInput(iFogControllerIndex, "SetFarZ");

    // Gets color
    static char sFogColor[16];
    gCvarList[CVAR_VEFFECTS_FOG_COLOR].GetString(sFogColor, sizeof(sFogColor));
    
    // Sets main color
    SetVariantString(sFogColor);
    AcceptEntityInput(iFogControllerIndex, "SetColor");

    // Sets secondary color
    SetVariantString(sFogColor);
    AcceptEntityInput(iFogControllerIndex, "SetColorSecondary");
    
    // Turn on fog rendering
    AcceptEntityInput(iFogControllerIndex, "TurnOn");
}
