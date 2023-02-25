/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          visualambience.sp
 *  Type:          Module
 *  Description:   Fog, light style, sky, sun rendering, etc
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
 * @brief Hook ambience cvar changes.
 **/
void VAmbienceOnCvarInit()
{
	gCvarList.VEFFECTS_LIGHTSTYLE_VALUE = FindConVar("zp_veffects_lightstyle_value");
	gCvarList.VEFFECTS_LIGHTSTYLE       = FindConVar("zp_veffects_lightstyle");       
	gCvarList.VEFFECTS_SKY_PATH         = FindConVar("zp_veffects_sky_path");
	gCvarList.VEFFECTS_SKY              = FindConVar("zp_veffects_sky");              
	gCvarList.VEFFECTS_SKYNAME          = FindConVar("sv_skyname");
	gCvarList.VEFFECTS_SUN_DISABLE      = FindConVar("zp_veffects_sun_disable");      
	gCvarList.VEFFECTS_FOG_COLOR        = FindConVar("zp_veffects_fog_color");
	gCvarList.VEFFECTS_FOG_DENSITY      = FindConVar("zp_veffects_fog_density");
	gCvarList.VEFFECTS_FOG_STARTDIST    = FindConVar("zp_veffects_fog_startdist");
	gCvarList.VEFFECTS_FOG_ENDDIST      = FindConVar("zp_veffects_fog_enddist");
	gCvarList.VEFFECTS_FOG_FARZ         = FindConVar("zp_veffects_fog_farz");
	gCvarList.VEFFECTS_FOG              = FindConVar("zp_veffects_fog");   
	
	HookConVarChange(gCvarList.VEFFECTS_LIGHTSTYLE,       VAmbienceOnCvarHookLightStyle);
	HookConVarChange(gCvarList.VEFFECTS_LIGHTSTYLE_VALUE, VAmbienceOnCvarHookLightStyle);
	
	HookConVarChange(gCvarList.VEFFECTS_SKY,              VAmbienceOnCvarHookSky);
	HookConVarChange(gCvarList.VEFFECTS_SKY_PATH,         VAmbienceOnCvarHookSky);
	
	HookConVarChange(gCvarList.VEFFECTS_SUN_DISABLE,      VAmbienceOnCvarHookSunDisable);
	
	HookConVarChange(gCvarList.VEFFECTS_FOG,              VAmbienceOnCvarHookFog);
	HookConVarChange(gCvarList.VEFFECTS_FOG_COLOR,        VAmbienceOnCvarHookFog);
	HookConVarChange(gCvarList.VEFFECTS_FOG_DENSITY,      VAmbienceOnCvarHookFog);
	HookConVarChange(gCvarList.VEFFECTS_FOG_STARTDIST,    VAmbienceOnCvarHookFog);
	HookConVarChange(gCvarList.VEFFECTS_FOG_ENDDIST,      VAmbienceOnCvarHookFog);
	HookConVarChange(gCvarList.VEFFECTS_FOG_FARZ,         VAmbienceOnCvarHookFog);
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
	bool bLightStyle = gCvarList.VEFFECTS_LIGHTSTYLE.BoolValue;
	
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
	bool bSky = gCvarList.VEFFECTS_SKY.BoolValue;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i, false))
		{
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
	bool bSun = gCvarList.VEFFECTS_SUN_DISABLE.BoolValue;
	
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
	bool bFog = gCvarList.VEFFECTS_FOG.BoolValue;
	
	VAmbienceApplyFog(!bFog);
}

/**
 * @brief Apply all cvar values on the server.
 **/
void VAmbienceOnLoad()
{
	bool bLightstyle = gCvarList.VEFFECTS_LIGHTSTYLE.BoolValue;
	
	VAmbienceApplyLightStyle(!bLightstyle);

	bool bFog = gCvarList.VEFFECTS_FOG.BoolValue;
	
	VAmbienceApplyFog(!bFog);
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.  
 **/
void VAmbienceOnClientInit(int client)
{
	bool bSky = gCvarList.VEFFECTS_SKY.BoolValue; 
	
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
	if (bDisable)
	{
		SetLightStyle(0, "n");
		return;
	}

	int iLight = -1;
	while ((iLight = FindEntityByClassname(iLight, "env_cascade_light")) != -1) 
	{ 
		AcceptEntityInput(iLight, "Kill");
	}

	static char sLightStyleValue[4];
	gCvarList.VEFFECTS_LIGHTSTYLE_VALUE.GetString(sLightStyleValue, sizeof(sLightStyleValue));

	if (StrContains(sLightStyleValue, "a", true) != -1)
	{
		SetLightStyle(0, "b");
		return;
	}

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
	if (IsFakeClient(client))
	{
		return;
	}
	
	static char VAmbienceDefaultSky[PLATFORM_LINE_LENGTH];

	gCvarList.VEFFECTS_SKYNAME.GetString(VAmbienceDefaultSky, sizeof(VAmbienceDefaultSky));

	if (bDisable)
	{
		if (hasLength(VAmbienceDefaultSky))
		{
			gCvarList.VEFFECTS_SKYNAME.ReplicateToClient(client, VAmbienceDefaultSky);
		}
		return;
	}

	static char sSkyPath[PLATFORM_LINE_LENGTH];
	gCvarList.VEFFECTS_SKY_PATH.GetString(sSkyPath, sizeof(sSkyPath));

	gCvarList.VEFFECTS_SKYNAME.ReplicateToClient(client, sSkyPath);
}

/**
 * @brief Apply sun on the server.
 *
 * @param bDisable          (Optional) State boolean.
 **/
void VAmbienceApplySunDisable(bool bDisable = false)
{
	int iSun = -1; 
	while ((iSun = FindEntityByClassname(iSun, "env_sun")) != -1)
	{
		if (bDisable)
		{
			AcceptEntityInput(iSun, "TurnOn");
			return;
		}
		
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
	if (bDisable)
	{
		return;
	}

	int controller = FindEntityByClassname(-1, "env_fog_controller");

	if (controller == -1)
	{
		controller = CreateEntityByName("env_fog_controller");
		if (controller != -1) DispatchSpawn(controller); else return;
	}
	
	DispatchKeyValueFloat(controller, "fogmaxdensity", gCvarList.VEFFECTS_FOG_DENSITY.FloatValue);

	SetVariantInt(gCvarList.VEFFECTS_FOG_STARTDIST.IntValue);
	AcceptEntityInput(controller, "SetStartDist");

	SetVariantInt(gCvarList.VEFFECTS_FOG_ENDDIST.IntValue);
	AcceptEntityInput(controller, "SetEndDist");

	SetVariantInt(gCvarList.VEFFECTS_FOG_FARZ.IntValue);
	AcceptEntityInput(controller, "SetFarZ");

	static char sFogColor[16];
	gCvarList.VEFFECTS_FOG_COLOR.GetString(sFogColor, sizeof(sFogColor));
	
	SetVariantString(sFogColor);
	AcceptEntityInput(controller, "SetColor");

	SetVariantString(sFogColor);
	AcceptEntityInput(controller, "SetColorSecondary");
	
	AcceptEntityInput(controller, "TurnOn");
}
