/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          tools_functions.cpp
 *  Type:          Module 
 *  Description:   API for offsets/signatures exposed in tools.cpp
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
 * @brief Creates commands for tools module.
 **/
void ToolsOnCommandInit(/*void*/)
{
    // Hook messages
    HookUserMessage(GetUserMessageId("TextMsg"), ToolsOnMessageHook, true);
}

/**
 * @brief Hook tools cvar changes.
 **/
void ToolsOnCvarInit(/*void*/)
{
    // Creates cvars
    gCvarList[CVAR_LIGHT_BUTTON]          = FindConVar("zp_light_button");  
    gCvarList[CVAR_MESSAGES_OBJECTIVE]    = FindConVar("zp_messages_objective");
    gCvarList[CVAR_MESSAGES_COUNTER]      = FindConVar("zp_messages_counter");
    gCvarList[CVAR_MESSAGES_BLAST]        = FindConVar("zp_messages_blast");
    gCvarList[CVAR_MESSAGES_DAMAGE]       = FindConVar("zp_messages_damage");
    gCvarList[CVAR_MESSAGES_DONATE]       = FindConVar("zp_messages_donate");
    gCvarList[CVAR_MESSAGES_CLASS_INFO]   = FindConVar("zp_messages_class_info");
    gCvarList[CVAR_MESSAGES_CLASS_CHOOSE] = FindConVar("zp_messages_class_choose");
    gCvarList[CVAR_MESSAGES_ITEM_INFO]    = FindConVar("zp_messages_item_info");
    gCvarList[CVAR_MESSAGES_ITEM_ALL]     = FindConVar("zp_messages_item_all");
    gCvarList[CVAR_MESSAGES_WEAPON_INFO]  = FindConVar("zp_messages_weapon_info");
    gCvarList[CVAR_MESSAGES_WEAPON_ALL]   = FindConVar("zp_messages_weapon_all");
    gCvarList[CVAR_MESSAGES_BLOCK]        = FindConVar("zp_messages_block");
    gCvarList[CVAR_SEND_TABLES]           = FindConVar("sv_sendtables");
    
    // Sets locked cvars to their locked value
    gCvarList[CVAR_SEND_TABLES].IntValue = 1;
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_LIGHT_BUTTON], ToolsFOnCvarHook);
    HookConVarChange(gCvarList[CVAR_SEND_TABLES],  CvarsUnlockOnCvarHook);
    
    // Load cvars
    ToolsOnCommandLoad();
}

/**
 * @brief Load tools listeners changes.
 **/
void ToolsOnCommandLoad(/*void*/)
{
    // Initialize command char
    static char sCommand[SMALL_LINE_LENGTH];
    
    // Validate alias
    if(hasLength(sCommand))
    {
        // Unhook listeners
        RemoveCommandListener2(ToolsOnCommandListened, sCommand);
    }
    
    // Gets flashlight command alias
    gCvarList[CVAR_LIGHT_BUTTON].GetString(sCommand, sizeof(sCommand));
    
    // Validate alias
    if(!hasLength(sCommand))
    {
        // Unhook listeners
        RemoveCommandListener2(ToolsOnCommandListened, sCommand);
        return;
        }
    
    // Hook listeners
    AddCommandListener(ToolsOnCommandListened, sCommand);
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
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Forward event to modules
    ToolsOnCommandLoad();
}

/**
 * Listener command callback (any)
 * @brief Usage of the on/off flashlight/nvgs.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action ToolsOnCommandListened(int clientIndex, char[] commandMsg, int iArguments)
{
    // Validate client 
    if(IsPlayerExist(clientIndex))
    {
        // Gets class overlay
        static char sOverlay[PLATFORM_LINE_LENGTH];
        ClassGetOverlay(gClientData[clientIndex].Class, sOverlay, sizeof(sOverlay));

        // Validate nvgs
        if(ClassIsNvgs(gClientData[clientIndex].Class) || hasLength(sOverlay)) 
        {
            // If mode doesn't ended yet, then stop
            if(gServerData.RoundEnd) /// Avoid reset round end overlays
            {
                // Block command
                return Plugin_Handled;
            }
            
            // Update nvgs in the database
            gClientData[clientIndex].Vision = !gClientData[clientIndex].Vision;
            DataBaseOnClientUpdate(clientIndex, ColumnType_Vision);
            
            // Switch on/off nightvision  
            VOverlayOnClientNvgs(clientIndex);
            
            // Forward event to modules
            SoundsOnClientNvgs(clientIndex);
        }
        else
        {
            // Switch on/off flashlight
            ToolsSetFlashLight(clientIndex, true);
            
            // Forward event to modules
            SoundsOnClientFlashLight(clientIndex);
        }
        
        // Block command
        return Plugin_Handled;
    }
    
    // Allow command
    return Plugin_Continue;
}

/**
 * @brief Hook client messages.
 *
 * @param iMessage          The message index.
 * @param hBuffer           Handle to the input bit buffer.
 * @param iPlayers          Array containing player indexes.
 * @param playersNum        Number of players in the array.
 * @param bReliable         True if message is reliable, false otherwise.
 * @param bInit             True if message is an initmsg, false otherwise.
 **/
public Action ToolsOnMessageHook(UserMsg iMessage, BfRead hBuffer, int[] iPlayers, int playersNum, bool bReliable, bool bInit)
{
    // Initialize engine message
    static char sTxtMsg[PLATFORM_LINE_LENGTH]; 
    PbReadString(hBuffer, "params", sTxtMsg, sizeof(sTxtMsg), 0); 

    // Initialize block message list
    static char sBlockMsg[PLATFORM_LINE_LENGTH];
    gCvarList[CVAR_MESSAGES_BLOCK].GetString(sBlockMsg, sizeof(sBlockMsg)); 

    // Block messages on the matching
    return (StrContains(sBlockMsg, sTxtMsg, false) != -1) ? Plugin_Handled : Plugin_Continue; 
}

/*
 * Stocks tools API.
 */

/**
 * @brief Respawn a player.
 *
 * @param clientIndex       The client index.
 * @return                  True on success, false otherwise. 
 **/
bool ToolsForceToRespawn(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return false;
    }
    
    // Verify that the client is dead
    if(IsPlayerAlive(clientIndex))
    {
        return false;
    }
    
    // Respawn as human ?
    int iDeathMatch = ModesGetMatch(gServerData.RoundMode);
    if(iDeathMatch == 1 || (iDeathMatch == 2 && GetRandomInt(0, 1)) || (iDeathMatch == 3 && fnGetHumans() < fnGetAlive() / 2))
    {
        gClientData[clientIndex].Respawn = TEAM_HUMAN;
    }
    // Respawn as zombie ?
    else
    {
        gClientData[clientIndex].Respawn = TEAM_ZOMBIE;
    }

    // Respawn a player
    CS_RespawnPlayer(clientIndex);
    
    // Return on success
    return true;
}

/**
 * @brief Gets or sets the velocity of a entity.
 *
 * @param entityIndex       The entity index.
 * @param vVelocity         The velocity output, or velocity to set on entity.
 * @param bApply            True to get entity velocity, false to set it.
 * @param bStack            If modifying velocity, then true will stack new velocity onto the entity.
 *                          current velocity, false will reset it.
 **/
void ToolsSetVelocity(int entityIndex, float vVelocity[3], bool bApply = true, bool bStack = true)
{
    // If retrieve if true, then get entity velocity
    if(!bApply)
    {
        // Gets entity velocity
        ToolsGetVelocity(entityIndex, vVelocity);
        
        // Stop here
        return;
    }
    
    // If stack is true, then add entity velocity
    if(bStack)
    {
        // Gets entity velocity
        static float vSpeed[3];
        ToolsGetVelocity(entityIndex, vSpeed);
        
        // Add to the current
        AddVectors(vSpeed, vVelocity, vVelocity);
    }
    
    // Apply velocity on entity
    TeleportEntity(entityIndex, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

/**
 * @brief Gets the velocity of a entity.
 *
 * @param entityIndex       The entity index.
 * @param vVelocity         The velocity output.
 **/
void ToolsGetVelocity(int entityIndex, float vVelocity[3])
{
    // Find the datamap
    if(!g_iOffset_Velocity)
    {
        g_iOffset_Velocity = FindDataMapInfo(entityIndex, "m_vecVelocity");
    }
   
    // Gets origin of the entity
    GetEntDataVector(entityIndex, g_iOffset_Velocity, vVelocity);
}

/**
 * @brief Gets the abs origin of a entity.
 *
 * @param entityIndex       The entity index.
 * @param vPosition         The origin output.
 **/
void ToolsGetAbsOrigin(int entityIndex, float vPosition[3])
{
    // Find the datamap
    if(!g_iOffset_Origin)
    {
        g_iOffset_Origin = FindDataMapInfo(entityIndex, "m_vecAbsOrigin");
    }
   
    // Gets origin of the entity
    GetEntDataVector(entityIndex, g_iOffset_Origin, vPosition);
}

/**
 * @brief Gets the abs angle of a entity.
 *
 * @param entityIndex       The entity index.
 * @param vAngle            The angle output.
 **/
void ToolsGetAbsAngles(int entityIndex, float vAngle[3])
{
    // Find the datamap
    if(!g_iOffset_Angles)
    {
        g_iOffset_Angles = FindDataMapInfo(entityIndex, "m_angAbsRotation");
    }
   
    // Gets angles of the entity
    GetEntDataVector(entityIndex, g_iOffset_Angles, vAngle);
}

/**
 * @brief Gets the render of a entity.
 *
 * @param entityIndex       The entity index.
 * @param mColor            The offset index.
 * @return                  The color amount.
 **/
int ToolsGetRenderColor(int entityIndex, ColorType mColor)
{
    // Gets render of the entity
    return GetEntData(entityIndex, g_iOffset_Render + view_as<int>(mColor), 1);
}

/**
 * @brief Gets the max weapons of a entity.
 *
 * @return                  The max weapon amount.
 **/
int ToolsGetMyWeapons(/*void*/)
{
    // Intialize counter
    static int iAmount;
    
    // Calculate the my weapon table size
    if(!iAmount)
    {
        iAmount = (g_iOffset_ActiveWeapon - g_iOffset_MyWeapons) / 4;
    }
    
    // Gets weapons of the entity
    return iAmount;
}

/**
 * @brief Gets the health of a entity.
 *
 * @param entityIndex       The entity index.
 * @param bMax              True to get maximum value, false to get health.  
 * @return                  The health value.
 **/
 int ToolsGetHealth(int entityIndex, bool bMax = false)
{
    // Gets health of the entity
    return GetEntData(entityIndex, bMax ? g_iOffset_MaxHealth : g_iOffset_Health);
}

/**
 * @brief Sets the health of a entity.
 *
 * @param entityIndex       The entity index.
 * @param iValue            The health value.
 * @param bSet              True to set maximum value, false to modify health.  
 **/
void ToolsSetHealth(int entityIndex, int iValue, bool bSet = false)
{
    // Sets health of the entity
    SetEntData(entityIndex, g_iOffset_Health, iValue, _, true);
    
    // If set is true, then set max health
    if(bSet) 
    {
        // Find the datamap
        if(!g_iOffset_MaxHealth)
        {
            g_iOffset_MaxHealth = FindDataMapInfo(entityIndex, "m_iMaxHealth");
        }

        // Sets max health of the entity
        SetEntData(entityIndex, g_iOffset_MaxHealth, iValue, _, true);
    }
}

/**
 * @brief Gets the speed of a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The LMV value.
 **/
/*float ToolsGetLMV(int entityIndex)
{
    // Gets lagged movement value of the entity
    return GetEntDataFloat(entityIndex, g_iOffset_LMV);
}*/

/**
 * @brief Sets the speed of a entity.
 *
 * @param entityIndex       The entity index.
 * @param flValue           The LMV value.
 **/
void ToolsSetLMV(int entityIndex, float flValue)
{
    // Sets lagged movement value of the entity
    SetEntDataFloat(entityIndex, g_iOffset_LMV, flValue, true);
}

/**
 * @brief Gets the armor of a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The armor value.
 **/
int ToolsGetArmor(int entityIndex)
{
    // Gets armor of the entity
    return GetEntData(entityIndex, g_iOffset_Armor);
}

/**
 * @brief Sets the armor of a entity.
 *
 * @param entityIndex       The entity index.
 * @param iValue            The armor value.
 **/
void ToolsSetArmor(int entityIndex, int iValue)
{
    // Sets armor of the entity
    SetEntData(entityIndex, g_iOffset_Armor, iValue, _, true);
}

/**
 * @brief Gets the team of an entity.
 * 
 * @param entityIndex       The entity index.
 * @return                  The team index.
 **/
int ToolsGetTeam(int entityIndex)
{
    // Gets team on the entity
    return GetEntData(entityIndex, g_iOffset_Team);
}

/**
 * @brief Sets the team of a entity.
 *
 * @param entityIndex       The entity index.
 * @param iValue            The team index.
 **/
void ToolsSetTeam(int entityIndex, int iValue)
{
    // Validate team
    if(ToolsGetTeam(entityIndex) <= TEAM_SPECTATOR) /// Fix, thanks to inklesspen!
    {
        // Sets team of the entity
        ChangeClientTeam(entityIndex, iValue);
    }
    else
    {
        // Switch team of the entity
        CS_SwitchTeam(entityIndex, iValue); 
    }
}

/**
 * @brief Gets nightvision values on a entity.
 *
 * @param entityIndex       The entity index.
 * @param ownership         If true, function will return the value of the entity ownership of nightvision.
 *                          If false, function will return the value of the entity on/off state of the nightvision.
 * @return                  True if aspect of nightvision is enabled on the entity, false if not.
 **/
bool ToolsGetNightVision(int entityIndex, bool bOwnership = false)
{
    // If ownership is true, then gets the ownership of nightvision on entity
    return view_as<bool>(GetEntData(entityIndex, bOwnership ? g_iOffset_HasNightVision : g_iOffset_NightVisionOn, 1));
}

/**
 * @brief Controls nightvision values on a entity.
 *
 * @param entityIndex       The entity index.
 * @param bEnable           Enable or disable an aspect of nightvision. (see ownership parameter)
 * @param bOwnership        If true, enable will toggle the entity ownership of nightvision.
 *                          If false, enable will toggle the entity on/off state of the nightvision.
 **/
void ToolsSetNightVision(int entityIndex, bool bEnable, bool bOwnership = false)
{
    // If ownership is true, then toggle the ownership of nightvision on entity
    SetEntData(entityIndex, bOwnership ? g_iOffset_HasNightVision : g_iOffset_NightVisionOn, bEnable, 1, true);
}

/**
 * @brief Gets defuser value on a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The aspect of the entity defuser.
 **/
bool ToolsGetDefuser(int entityIndex)
{
    // Gets defuser on the entity
    return view_as<bool>(GetEntData(entityIndex, g_iOffset_HasDefuser, 1));
}

/**
 * @brief Controls defuser value on a entity.
 *
 * @param entityIndex       The entity index.
 * @param bEnable           Enable or disable an aspect of defuser.
 **/
void ToolsSetDefuser(int entityIndex, bool bEnable)
{
    // Sets defuser on the entity
    SetEntData(entityIndex, g_iOffset_HasDefuser, bEnable, 1, true);
}

/**
 * @brief Gets helmet value on a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The aspect of the entity helmet.
 **/
bool ToolsGetHelmet(int entityIndex)
{
    // Gets helmet on the entity
    return view_as<bool>(GetEntData(entityIndex, g_iOffset_HasHelmet, 1));
}

/**
 * @brief Controls helmet value on a entity.
 *
 * @param entityIndex       The entity index.
 * @param bEnable           Enable or disable an aspect of helmet.
 **/
void ToolsSetHelmet(int entityIndex, bool bEnable)
{
    // Sets helmet on the entity
    SetEntData(entityIndex, g_iOffset_HasHelmet, bEnable, 1, true);
}

/**
 * @brief Gets suit value on a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The aspect of the entity suit.
 **/
bool ToolsGetHeavySuit(int entityIndex)
{
    // Gets suit on the entity
    return view_as<bool>(GetEntData(entityIndex, g_iOffset_HasHeavyArmor, 1));
}

/**
 * @brief Controls suit value on a entity.
 *
 * @param entityIndex       The entity index.
 * @param bEnable           Enable or disable an aspect of suit.
 **/
void ToolsSetHeavySuit(int entityIndex, bool bEnable)
{
    // Sets suit on the entity
    SetEntData(entityIndex, g_iOffset_HasHeavyArmor, bEnable, 1, true);
}

/**
 * @brief Gets the active weapon index of a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The weapon index.
 **/
int ToolsGetActiveWeapon(int entityIndex)
{
    // Gets weapon on the entity    
    return GetEntDataEnt2(entityIndex, g_iOffset_ActiveWeapon);
}

/**
 * @brief Sets the active weapon index of a entity.
 *
 * @param entityIndex       The entity index.
 * @param weaponIndex       The weapon index.
 **/
void ToolsSetActiveWeapon(int entityIndex, int weaponIndex)
{
    // Sets weapon on the entity    
    SetEntDataEnt2(entityIndex, g_iOffset_ActiveWeapon, weaponIndex, true);
}

/**
 * @brief Gets the addon bits of a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The addon bits.
 **/
int ToolsGetAddonBits(int entityIndex)
{
    // Gets addon value on the entity    
    return GetEntData(entityIndex, g_iOffset_AddonBits);
}

/**
 * @brief Sets the addon bits index of a entity.
 *
 * @param entityIndex       The entity index.
 * @param iValue            The addon bits.
 **/
void ToolsSetAddonBits(int entityIndex, int iValue)
{
    // Sets addon value on the entity    
    SetEntData(entityIndex, g_iOffset_AddonBits, iValue, _, true);
}

/**
 * @brief Gets the observer mode of a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The mode index.
 **/
int ToolsGetObserverMode(int entityIndex)
{
    // Gets obs mode on the entity    
    return GetEntData(entityIndex, g_iOffset_ObserverMode);
}

/**
 * @brief Gets the observer target of a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The target index.
 **/
int ToolsGetObserverTarget(int entityIndex)
{
    // Gets obs mode on the entity    
    return GetEntDataEnt2(entityIndex, g_iOffset_ObserverTarget);
}

/**
 * @brief Gets hitgroup value on a entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The hitgroup index.
 **/
int ToolsGetHitGroup(int entityIndex)
{
    // Gets hitgroup on the entity    
    return GetEntData(entityIndex, g_iOffset_HitGroup);
}

/**
 * @brief Gets or sets a entity score or deaths.
 * 
 * @param entityIndex       The entity index.
 * @param bScore            True to look at score, false to look at deaths.  
 * @return                  The score or death count of the entity.
 **/
int ToolsGetScore(int entityIndex, bool bScore = true)
{
    // Find the datamap
    if(!g_iOffset_Frags || !g_iOffset_Death)
    {
        g_iOffset_Frags = FindDataMapInfo(entityIndex, "m_iFrags");
        g_iOffset_Death = FindDataMapInfo(entityIndex, "m_iDeaths");
    }
    
    // If score is true, then return entity score, otherwise return entity deaths
    return GetEntData(entityIndex, bScore ? g_iOffset_Frags : g_iOffset_Death);
}

/**
 * @brief Sets a entity score or deaths.
 * 
 * @param entityIndex       The entity index.
 * @param bScore            True to look at score, false to look at deaths.  
 * @param iValue            The score/death amount.
 **/
void ToolsSetScore(int entityIndex, bool bScore = true, int iValue = 0)
{
    // Find the datamap
    if(!g_iOffset_Frags || !g_iOffset_Death)
    {
        g_iOffset_Frags = FindDataMapInfo(entityIndex, "m_iFrags");
        g_iOffset_Death = FindDataMapInfo(entityIndex, "m_iDeaths");
    }
    
    // If score is true, then set entity score, otherwise set entity deaths
    SetEntData(entityIndex, bScore ? g_iOffset_Frags : g_iOffset_Death, iValue, _, true);
}


/**
 * @brief Sets the gravity of a entity.
 * 
 * @param entityIndex       The entity index.
 * @param flValue           The gravity amount.
 **/
void ToolsSetGravity(int entityIndex, float flValue)
{
    // Find the datamap
    if(!g_iOffset_Gravity)
    {
        g_iOffset_Gravity = FindDataMapInfo(entityIndex, "m_flGravity");
    }
    
    // Sets gravity on the entity
    SetEntDataFloat(entityIndex, g_iOffset_Gravity, flValue, true);
}

/**
 * @brief Sets the spotting of a entity.
 * 
 * @param entityIndex       The entity index.
 * @param bEnable           Enable or disable an aspect of spotting.
 **/
void ToolsSetSpot(int entityIndex, bool bEnable)
{
    // If retrieve if true, then reset variables
    if(!bEnable)
    {
        // Sets value on the entity
        SetEntData(entityIndex, g_iOffset_Spotted, false, 1, true);
        SetEntData(entityIndex, g_iOffset_SpottedByMask, false, _, true);
        SetEntData(entityIndex, g_iOffset_SpottedByMask + 4, false, _, true); /// That is table
        SetEntData(entityIndex, g_iOffset_CanBeSpotted, 0, _, true);
    }
    else
    {
        // Sets value on the entity
        SetEntData(entityIndex, g_iOffset_CanBeSpotted, 9, _, true);
    }
}

/**
 * @brief Sets the detecting of a entity.
 * 
 * @param entityIndex       The entity index.
 * @param bEnable           Enable or disable an aspect of detection.
 **/
void ToolsSetDetecting(int entityIndex, bool bEnable)
{
    // Sets glow on the entity
    SetEntDataFloat(entityIndex, g_iOffset_Detected, bEnable ? (GetGameTime() + 9999.0) : 0.0, true);
}

/**
 * @brief Sets the hud of a entity.
 * 
 * @param entityIndex       The entity index.
 * @param bEnable           Enable or disable an aspect of hud.
 **/
void ToolsSetHud(int entityIndex, bool bEnable)
{   
    // Sets hud type on the entity
    SetEntData(entityIndex, g_iOffset_HUD, bEnable ? (GetEntData(entityIndex, g_iOffset_HUD) & ~HIDEHUD_CROSSHAIR) : (GetEntData(entityIndex, g_iOffset_HUD) | HIDEHUD_CROSSHAIR), _, true);
}

/**
 * @brief Sets the arms of a entity.
 * 
 * @param entityIndex       The entity index.
 * @param sModel            The model path.
 * @param iMaxLen           The lenght of string. 
 **/
void ToolsSetArm(int entityIndex, char[] sModel, int iMaxLen)
{
    // Sets arm on the entity
    SetEntDataString(entityIndex, g_iOffset_Arms, sModel, iMaxLen, true);
}

/**
 * @brief Sets the attack delay of a entity.
 * 
 * @param entityIndex       The entity index.
 * @param flValue           The speed amount.
 **/
void ToolsSetAttack(int entityIndex, float flValue)
{
    // Sets next attack on the entity
    SetEntDataFloat(entityIndex, g_iOffset_Attack, flValue, true);
}

/**
 * @brief Sets the flashlight of a entity.
 * 
 * @param entityIndex       The entity index.
 * @param bEnable           Enable or disable an aspect of flashlight.
 **/
void ToolsSetFlashLight(int entityIndex, bool bEnable)
{
    // Sets flashlight on the entity
    ToolsSetEffect(entityIndex, bEnable ? (ToolsGetEffect(entityIndex) ^ EF_DIMLIGHT) : 0);
}

/**
 * @brief Sets the fov of a entity.
 * 
 * @param entityIndex       The entity index.
 * @param iValue            (Optional) The fov amount.
 **/
void ToolsSetFov(int entityIndex, int iValue = 90)
{
    // Sets fov on the entity
    SetEntData(entityIndex, g_iOffset_Fov, iValue, _, true);
    SetEntData(entityIndex, g_iOffset_DefaultFOV, iValue, _, true);
}

/**
 * @brief Sets body/skin for the entity.
 *
 * @param entityIndex       The entity index.
 * @param iBody             (Optional) The body index.
 * @param iSkin             (Optional) The skin index.
 **/
void ToolsSetTextures(int entityIndex, int iBody = -1, int iSkin = -1)
{
    if(iBody != -1) SetEntData(entityIndex, g_iOffset_Body, iBody, _, true);
    if(iSkin != -1) SetEntData(entityIndex, g_iOffset_Skin, iSkin, _, true);
}

/**
 * @brief Gets the effect of an entity.
 * 
 * @param entityIndex       The entity index.
 * @return                  The effect value.
 **/
int ToolsGetEffect(int entityIndex)
{
    // Gets effect on the entity    
    return GetEntData(entityIndex, g_iOffset_Effects);
}

/**
 * @brief Sets the effect of an entity.
 * 
 * @param entityIndex       The entity index.
 * @param iValue            The effect value.
 **/
void ToolsSetEffect(int entityIndex, int iValue)
{
    // Sets effect on the entity
    SetEntData(entityIndex, g_iOffset_Effects, iValue, _, true);
}

/**
 * @brief Gets the activator of an entity.
 *
 * @param entityIndex       The entity index.
 * @return                  The activator index.
 **/
int ToolsGetActivator(int entityIndex)
{
    // Find the datamap
    if(!g_iOffset_Activator)
    {
        g_iOffset_Activator = FindDataMapInfo(entityIndex, "m_pActivator");
    }
    
    // Gets activator on the entity
    return GetEntDataEnt2(entityIndex, g_iOffset_Activator);
}

/**
 * @brief Sets the model of an entity.
 * 
 * @param entityIndex       The entity index.
 * @param iModel            The model index.
 **/
void ToolsSetModelIndex(int entityIndex, int iModel)
{
    // Sets index on the entity
    SetEntData(entityIndex, g_iOffset_ModelIndex, iModel, _, true);
}

/**
 * @brief Gets the owner of an entity.
 * 
 * @param entityIndex       The entity index.
 * @return                  The owner index.
 **/
int ToolsGetOwner(int entityIndex)
{
    // Gets owner on the entity
    return GetEntDataEnt2(entityIndex, g_iOffset_OwnerEntity);
}

/**
 * @brief Sets the owner of an entity.
 * 
 * @param entityIndex       The entity index.
 * @param ownerIndex        The owner index.
 **/
void ToolsSetOwner(int entityIndex, int ownerIndex)
{
    // Sets owner on the entity
    SetEntDataEnt2(entityIndex, g_iOffset_OwnerEntity, ownerIndex, true);
}

/*_____________________________________________________________________________________________________*/

/**
 * @brief Validate the attachment on the entity.
 *
 * @param entityIndex       The entity index.
 * @param sAttach           The attachment name.
 * @return                  True or false.
 **/
bool ToolsLookupAttachment(int entityIndex, char[] sAttach)
{
    return (hasLength(sAttach) && SDKCall(hSDKCallLookupAttachment, entityIndex, sAttach));
}

/**
 * @brief Gets the attachment of the entity.
 *
 * @param entityIndex       The entity index.
 * @param sAttach           The attachment name.
 * @param vPosition         The origin output.
 * @param vAngle            The angle output.
 **/
void ToolsGetAttachment(int entityIndex, char[] sAttach, float vPosition[3], float vAngle[3])
{
    // Validate windows
    if(gServerData.Platform == OS_Windows)
    {
        SDKCall(hSDKCallGetAttachment, entityIndex, sAttach, vPosition, vAngle); 
    }
    else
    {
        int iAttach = SDKCall(hSDKCallLookupAttachment, entityIndex, sAttach);
        if(iAttach)
        {
            SDKCall(hSDKCallGetAttachment, entityIndex, iAttach, vPosition, vAngle); 
        }
    }
}

/**
 * @brief Gets the sequence of the entity.
 *
 * @param entityIndex       The entity index.
 * @param sAnim             The sequence name.
 * @return                  The sequence index.
 **/
int ToolsLookupSequence(int entityIndex, char[] sAnim)
{
    // Validate windows
    if(gServerData.Platform == OS_Windows)
    {
        return SDKCall(hSDKCallLookupSequence, entityIndex, sAnim); 
    }
    else
    {
        // Gets 'CStudioHdr' class
        Address pStudioHdrClass = ToolsGetStudioHdrClass(entityIndex);
        if(pStudioHdrClass == Address_Null)
        {
            return -1;
        }
        
        return SDKCall(hSDKCallLookupSequence, pStudioHdrClass, sAnim); 
    }
}

/**
 * @brief Gets the pose of the entity.
 *
 * @param entityIndex       The entity index.
 * @param sPose             The pose name.
 * @return                  The pose parameter.
 **/
int ToolsLookupPoseParameter(int entityIndex, char[] sPose)
{
    // Gets 'CStudioHdr' class
    Address pStudioHdrClass = ToolsGetStudioHdrClass(entityIndex);
    if(pStudioHdrClass == Address_Null)
    {
        return -1;
    }
    
    return SDKCall(hSDKCallLookupPoseParameter, entityIndex, pStudioHdrClass, sPose); 
}

/**
 * @brief Resets the sequence of the entity.
 *
 * @param entityIndex       The entity index.
 * @param sAnim             The sequence name.
 **/
void ToolsResetSequence(int entityIndex, char[] sAnim) 
{ 
    // Find the sequence index
    int iSequence = ToolsLookupSequence(entityIndex, sAnim); 
    if(iSequence < 0) 
    {
        return; 
    }
    
    // Tracker 17868: If the sequence number didn't actually change, but you call resetsequence info, it changes
    // the newsequenceparity bit which causes the client to call m_flCycle.Reset() which causes a very slight 
    // discontinuity in looping animations as they reset around to cycle 0.0. This was causing the parentattached
    // helmet on barney to hitch every time barney's idle cycled back around to its start.
    SDKCall(hSDKCallResetSequence, entityIndex, iSequence);
}

/**
 * @brief Gets the total sequence amount.
 *
 * @note The game has two methods for getting the sequence count:
 * 
 * 1. Local sequence count if the model has sequences built in the model itself.
 * 2. Virtual model sequence count if the model inherits the sequences from a different model, also known as an include model.
 *
 * @param entityIndex       The entity index.
 * @return                  The sequence count.
 **/
int ToolsGetSequenceCount(int entityIndex)
{
    // Gets 'CStudioHdr' class
    Address pStudioHdrClass = ToolsGetStudioHdrClass(entityIndex);
    if(pStudioHdrClass == Address_Null)
    {
        return -1;
    }
    
    // Gets 'studiohdr_t' class
    Address pStudioHdrStruct = view_as<Address>(LoadFromAddress(pStudioHdrClass + view_as<Address>(StudioHdrClass_StudioHdrStruct), NumberType_Int32));
    if(pStudioHdrStruct != Address_Null)
    {
        int localSequenceCount = LoadFromAddress(pStudioHdrStruct + view_as<Address>(StudioHdrStruct_SequenceCount), NumberType_Int32);
        if(localSequenceCount)
        {
            return localSequenceCount;
        }
    }
    
    // Gets 'virtualmodel_t' class
    Address pVirtualModelStruct = view_as<Address>(LoadFromAddress(pStudioHdrClass + view_as<Address>(StudioHdrClass_VirualModelStruct), NumberType_Int32));
    if(pVirtualModelStruct != Address_Null)
    {
        return LoadFromAddress(pVirtualModelStruct + view_as<Address>(VirtualModelStruct_SequenceVector_Size), NumberType_Int32);
    }
    
    // Return on unsuccess 
    return -1;
}

/**
 * @brief Gets the duration of a sequence.
 * 
 * @param entityIndex       The entity index.
 * @param iSequence         The sequence index.
 * @return                  The sequence duration.  
 **/
float ToolsGetSequenceDuration(int entityIndex, int iSequence)
{
    // Gets 'CStudioHdr' class
    Address pStudioHdrClass = ToolsGetStudioHdrClass(entityIndex);
    if(pStudioHdrClass == Address_Null)
    {
        return 0.0;
    }

    return SDKCall(hSDKCallGetSequenceDuration, entityIndex, pStudioHdrClass, iSequence);
}

/**
 * @brief Gets the activity of a sequence.
 *
 * @param entityIndex       The entity index.
 * @param iSequence         The sequence index.
 * @return                  The activity index.
 **/
int ToolsGetSequenceActivity(int entityIndex, int iSequence)
{
    return SDKCall(hSDKCallGetSequenceActivity, entityIndex, iSequence);
}

/**
 * @brief Gets the hdr class address.
 * 
 * @param entityIndex       The entity index.
 * @return                  The address of the hdr.    
 **/
Address ToolsGetStudioHdrClass(int entityIndex)
{
    return view_as<Address>(GetEntData(entityIndex, Animating_StudioHdr));
}

/**
 * @brief Update a entity transmit state.
 * 
 * @param entityIndex       The entity index.
 **/
void ToolsUpdateTransmitState(int entityIndex)
{
    SDKCall(hSDKCallUpdateTransmitState, entityIndex);
}

/**
 * @brief Checks that the entity is a brush.
 * 
 * @param entityIndex       The entity index.
 **/
bool ToolsIsBSPModel(int entityIndex)
{
    return SDKCall(hSDKCallIsBSPModel, entityIndex);
}

/**
 * @brief Emulate 'bullet_shot' on the server and does the damage calculations.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param iMode             The mode index.
 * @param iSeed             The randomizing seed.
 * @param flInaccuracy      The inaccuracy variable.
 * @param flSpread          The spread variable.
 * @param iSoundType        The sound type.
 *
 * @return                  True or false.
 **/
bool ToolsFireBullets(int clientIndex, int weaponIndex, float vPosition[3], float vAngle[3], int iMode, int iSeed, float flInaccuracy, float flSpread, int iSoundType)
{
    // Create a bullet decal
    TE_Start("Shotgun Shot");
    TE_WriteVector("m_vecOrigin", vPosition);
    TE_WriteFloat("m_vecAngles[0]", vAngle[0]);
    TE_WriteFloat("m_vecAngles[1]", vAngle[1]);
    TE_WriteNum("m_weapon", WeaponsGetItemDefenition(weaponIndex));
    TE_WriteNum("m_iMode", iMode);
    TE_WriteNum("m_iSeed", iSeed);
    TE_WriteNum("m_iPlayer", clientIndex - 1);
    TE_WriteFloat("m_fInaccuracy", flInaccuracy);
    TE_WriteFloat("m_fSpread", flSpread);
    TE_SendToAll();
    
    // If windows, then stop
    if(gServerData.Platform == OS_Windows)
    {
        return false;
    }
    
    // Find the datamap
    if(!g_iOffset_LagCompensation)
    {
        g_iOffset_LagCompensation = FindDataMapInfo(clientIndex, "m_bLagCompensation");
    }
    
    // Emulate shot on the server side and block lag compensation
    bool bLock = view_as<bool>(GetEntData(clientIndex, g_iOffset_LagCompensation));
    SetEntData(clientIndex, g_iOffset_LagCompensation, false, 1, true);
    SDKCall(hSDKCallFireBullets, clientIndex, weaponIndex, 0, vPosition, vAngle, iMode, iSeed, flInaccuracy, flSpread, 0.0, 0.0, iSoundType, GetEntDataFloat(weaponIndex, g_iOffset_RecoilIndex));
    SetEntData(clientIndex, g_iOffset_LagCompensation, bLock, 1, true);

    // Return on the success
    return true;
}