/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          skillsystem.cpp
 *  Type:          Module 
 *  Description:   Provides functions for zombie skills system.
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
 * Bar max length.
 **/
#define BAR_MAX_LENGTH  50
 
/**
 * @section Properties of the skill bar.
 **/ 
#define SKILL_HUD_X     0.3
#define SKILL_HUD_Y     0.185
/**
 * @endsection
 **/

/**
 * Arrays to store the skill bar.
 **/
char SkillSystemBar[MAXPLAYERS+1][BAR_MAX_LENGTH+1];
static char SkillSystemMax[BAR_MAX_LENGTH] = "__________________________________________________";
 
/**
 * @brief Skill module init function.
 **/
void SkillSystemOnInit(/*void*/)
{
    // Creates HUD synchronization objects
    gServerData.SkillSync[0] = CreateHudSynchronizer();
    gServerData.SkillSync[1] = CreateHudSynchronizer();
} 
 
/**
 * @brief Hook skills cvar changes.
 **/
void SkillSystemOnCvarInit(/*void*/)
{    
    // Creates cvars
    gCvarList[CVAR_SKILL_BUTTON] = FindConVar("zp_skill_button");  

    // Hook cvars
    HookConVarChange(gCvarList[CVAR_SKILL_BUTTON], SkillSystemOnCvarHook);
    
    // Load cvars
    SkillSystemOnCvarLoad();
}

/**
 * @brief Load tools listeners changes.
 **/
void SkillSystemOnCvarLoad(/*void*/)
{
    // Initialize command char
    static char sCommand[SMALL_LINE_LENGTH];
    
    // Validate alias
    if(hasLength(sCommand))
    {
        // Unhook listeners
        RemoveCommandListener2(SkillSystemOnCommandListened, sCommand);
    }
    
    // Gets skill command alias
    gCvarList[CVAR_SKILL_BUTTON].GetString(sCommand, sizeof(sCommand));
    
    // Validate alias
    if(!hasLength(sCommand))
    {
        // Unhook listeners
        RemoveCommandListener2(SkillSystemOnCommandListened, sCommand);
        return;
    }
    
    // Hook listeners
    AddCommandListener(SkillSystemOnCommandListened, sCommand);
}

/**
 * Cvar hook callback (zp_skill_button)
 * @brief Skills module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void SkillSystemOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Forward event to modules
    SkillSystemOnCvarLoad();
}

/**
 * Listener command callback (any)
 * @brief Usage of the skill for human/zombie.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action SkillSystemOnCommandListened(int clientIndex, char[] commandMsg, int iArguments)
{
    // Validate access
    if(!ModesIsSkill(gServerData.RoundMode))
    {
        return Plugin_Handled;
    }
        
    // Validate client 
    if(IsPlayerExist(clientIndex))
    {
        // Do the skill
        SkillSystemOnClientStart(clientIndex);
        return Plugin_Handled;
    }
    
    // Allow command
    return Plugin_Continue;
}

/**
 * @brief Client has been changed class state.
 * 
 * @param clientIndex       The client index.
 **/
void SkillSystemOnClientUpdate(int clientIndex)
{
    // If health restoring disabled, then stop
    if(!ModesIsRegen(gServerData.RoundMode))
    {
        return;
    }

    // Validate class regen interval/amount
    float flInterval = ClassGetRegenInterval(gClientData[clientIndex].Class);
    if(!flInterval || !ClassGetRegenHealth(gClientData[clientIndex].Class))
    {
        return;
    }
    
    // Sets timer for restoring health
    delete gClientData[clientIndex].HealTimer;
    gClientData[clientIndex].HealTimer = CreateTimer(flInterval, SkillSystemOnClientRegen, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief Called when player press drop button.
 *
 * @param clientIndex       The client index.
 **/
void SkillSystemOnClientStart(int clientIndex)
{
    // Validate class skill duration/countdown
    float flInterval = ClassGetSkillDuration(gClientData[clientIndex].Class);
    if(!flInterval && (!ClassGetSkillCountdown(gClientData[clientIndex].Class)))
    {
        return;
    }
    
    // Verify that the skills are avalible
    if(!gClientData[clientIndex].Skill && gClientData[clientIndex].SkillCounter <= 0.0)
    {
        // Call forward
        Action resultHandle; 
        gForwardData._OnClientSkillUsed(clientIndex, resultHandle);
        
        // Block skill usage
        if(resultHandle == Plugin_Handled || resultHandle == Plugin_Stop)
        {
            return;
        }

        // Sets skill usage
        gClientData[clientIndex].Skill = true;
        
        // Validate skill bar
        if(ClassIsSkillBar(gClientData[clientIndex].Class) && !IsFakeClient(clientIndex))
        {
            // Resets bar string 
            strcopy(SkillSystemBar[clientIndex], sizeof(SkillSystemBar[]), SkillSystemMax);
            gClientData[clientIndex].SkillCounter = flInterval; /// Update skill time usage
        
            // Sets timer for showing bar
            delete gClientData[clientIndex].BarTimer;
            gClientData[clientIndex].BarTimer = CreateTimer(0.1, SkillSystemOnClientHUD, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
        
        // Sets timer for removing skill usage
        delete gClientData[clientIndex].SkillTimer;
        gClientData[clientIndex].SkillTimer = CreateTimer(flInterval, SkillSystemOnClientEnd, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Timer callback, show HUD bar within information about skill duration.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillSystemOnClientHUD(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID); 

    // Validate client
    if(clientIndex)
    {
        // If skill is over, then stop
        if(!gClientData[clientIndex].Skill)
        {
            // Clear timer
            gClientData[clientIndex].BarTimer = null;
            
            // Destroy timer
            return Plugin_Stop;
        }
        
        // Update duration bar
        gClientData[clientIndex].SkillCounter -= 0.1;
        SkillSystemBar[clientIndex][RoundToNearest((gClientData[clientIndex].SkillCounter * BAR_MAX_LENGTH) / ClassGetSkillDuration(gClientData[clientIndex].Class))] = '\0';

        // Show health bar
        VEffectsHudClientScreen(gServerData.SkillSync[0], clientIndex, SKILL_HUD_X, SKILL_HUD_Y, 0.11, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0, SkillSystemMax);
        VEffectsHudClientScreen(gServerData.SkillSync[1], clientIndex, SKILL_HUD_X, SKILL_HUD_Y, 0.11, 255, 255, 0, 255, 0, 0.0, 0.0, 0.0, SkillSystemBar[clientIndex]);

        // Allow timer
        return Plugin_Continue;
    }
    
    // Clear timer
    gClientData[clientIndex].BarTimer = null;
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Timer callback, remove a skill usage.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillSystemOnClientEnd(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Clear timer
    gClientData[clientIndex].SkillTimer = null;
    
    // Validate client
    if(clientIndex)
    {
        // Remove skill usage and set countdown time
        gClientData[clientIndex].Skill = false;
        gClientData[clientIndex].SkillCounter = ClassGetSkillCountdown(gClientData[clientIndex].Class);
        
        // Sets timer for countdown
        delete gClientData[clientIndex].CounterTimer;
        gClientData[clientIndex].CounterTimer = CreateTimer(1.0, SkillSystemOnClientCount, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        
        // Call forward
        gForwardData._OnClientSkillOver(clientIndex);
    }

    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Timer callback, the skill countdown.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillSystemOnClientCount(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Substitute counter
        gClientData[clientIndex].SkillCounter--;
        
        // If counter is over, then stop
        if(gClientData[clientIndex].SkillCounter <= 0.0)
        {
            // Show message
            TranslationPrintHintText(clientIndex, "skill ready");

            // Clear timer
            gClientData[clientIndex].CounterTimer = null;
            
            // Destroy timer
            return Plugin_Stop;
        }

        // Show counter
        TranslationPrintHintText(clientIndex, "countdown", RoundToNearest(gClientData[clientIndex].SkillCounter));
        
        // Allow timer
        return Plugin_Continue;
    }
    
    // Clear timer
    gClientData[clientIndex].CounterTimer = null;
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Timer callback, restore a player health.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillSystemOnClientRegen(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Initialize vector
        static float vVelocity[3];
        
        // Gets client velocity
        ToolsGetClientVelocity(clientIndex, vVelocity);
        
        // If the client don't move, then check health
        if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
        {
            // If restoring is available, then do it
            int iHealth = GetClientHealth(clientIndex); // Store for next usage
            if(iHealth < ClassGetHealth(gClientData[clientIndex].Class))
            {
                // Initialize a new health amount
                int iRegen = iHealth + ClassGetRegenHealth(gClientData[clientIndex].Class);
                
                // If new health more, than set default class health
                if(iRegen > ClassGetHealth(gClientData[clientIndex].Class))
                {
                    iRegen = ClassGetHealth(gClientData[clientIndex].Class);
                }
                
                // Update health
                ToolsSetClientHealth(clientIndex, iRegen);

                // Forward event to modules
                SoundsOnClientRegen(clientIndex);
                VEffectsOnClientRegen(clientIndex);
            }
        }

        // Allow counter
        return Plugin_Continue;
    }

    // Clear timer
    gClientData[clientIndex].HealTimer = null;
    
    // Destroy timer
    return Plugin_Stop;
}

/*
 * Skill system natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void SkillSystemOnNativeInit(/*void*/)
{
    CreateNative("ZP_GetClientSkillUsage",     API_GetClientSkillUsage);
    CreateNative("ZP_GetClientSkillCountdown", API_GetClientSkillCountdown);
    CreateNative("ZP_ResetClientSkill",        API_ResetClientSkill);
}

/**
 * @brief Gets the player skill state.
 *
 * @note native bool ZP_GetClientSkillUsage(clientIndex);
 **/
public int API_GetClientSkillUsage(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return gClientData[clientIndex].Skill;
}

/**
 * @brief Gets the player skill countdown.
 *
 * @note native float ZP_GetClientSkillCountdown(clientIndex);
 **/
public int API_GetClientSkillCountdown(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value (Float fix)
    return view_as<int>(gClientData[clientIndex].SkillCounter);
}

/**
 * @brief Stop the player skill or countdown. 
 *
 * @note native void ZP_ResetClientSkill(clientIndex);
 **/
public int API_ResetClientSkill(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);
    
    // Reset the values
    delete gClientData[clientIndex].SkillTimer;
    delete gClientData[clientIndex].BarTimer;
    delete gClientData[clientIndex].CounterTimer;
    gClientData[clientIndex].Skill = false;
    gClientData[clientIndex].SkillCounter = 0.0;
}