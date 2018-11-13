/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          skillsystem.cpp
 *  Type:          Game 
 *  Description:   Provides functions for zombie skills system.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 * Creates commands for skills module. Called when commands are created.
 **/
void SkillsOnCommandsCreate(/*void*/)
{
    // Hook listeners
    AddCommandListener(SkillsOnUse);
}

/**
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param nemesisMode       (Optional) Indicates that client will be a nemesis.
 **/
void SkillsOnClientInfected(const int clientIndex, const bool nemesisMode = false)
{
    // If health restoring disabled, then stop
    if(!gCvarList[CVAR_ZOMBIE_RESTORE].BoolValue || nemesisMode)
    {
        return;
    }

    // Validate zombie class regen interval/amount
    float flInterval = ZombieGetRegenInterval(gClientData[clientIndex][Client_ZombieClass]);
    if(!flInterval || !ZombieGetRegenHealth(gClientData[clientIndex][Client_ZombieClass]))
    {
        return;
    }
    
    // Sets timer for restoring health
    delete gClientData[clientIndex][Client_HealTimer];
    gClientData[clientIndex][Client_HealTimer] = CreateTimer(flInterval, SkillsOnHealthRegen, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer for restore a player health.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillsOnHealthRegen(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Initialize variable
        static float vVelocity[3];
        
        // Gets the client velocity
        ToolsGetClientVelocity(clientIndex, vVelocity);
        
        // If the zombie don't move, then check health
        if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
        {
            // If restoring is available, then do it
            int iHealth = GetClientHealth(clientIndex); // Store for next usage
            if(iHealth < ZombieGetHealth(gClientData[clientIndex][Client_ZombieClass]))
            {
                // Initialize a new health amount
                int iRegen = iHealth + ZombieGetRegenHealth(gClientData[clientIndex][Client_ZombieClass]);
                
                // If new health more, than set default class health
                if(iRegen > ZombieGetHealth(gClientData[clientIndex][Client_ZombieClass]))
                {
                    iRegen = ZombieGetHealth(gClientData[clientIndex][Client_ZombieClass]);
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
    gClientData[clientIndex][Client_HealTimer] = INVALID_HANDLE;
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Callback for command listener to use skill for human/zombie.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action SkillsOnUse(const int clientIndex, const char[] commandMsg, const int iArguments)
{
    // Validate client 
    if(IsPlayerExist(clientIndex))
    {
        // Gets command alias
        static char sCommand[SMALL_LINE_LENGTH];
        gCvarList[CVAR_GAME_CUSTOM_SKILL_BUTTON].GetString(sCommand, sizeof(sCommand));
        
        // Validate command
        if(!strcmp(sCommand, commandMsg))
        {
            // Validate human/zombie
            if(gClientData[clientIndex][Client_Nemesis] || gClientData[clientIndex][Client_Survivor])
            {
                return Plugin_Handled;
            }
            
            // Do the skill
            SkillsOnStart(clientIndex);
            return Plugin_Handled;
        }
    }
    
    // Allow command
    return Plugin_Continue;
}

/**
 * Called when player press drop button.
 *
 * @param clientIndex       The client index.
 **/
void SkillsOnStart(const int clientIndex)
{
    // Validate class skill duration/countdown
    float flInterval = gClientData[clientIndex][Client_Zombie] ? ZombieGetSkillDuration(gClientData[clientIndex][Client_ZombieClass]) : HumanGetSkillDuration(gClientData[clientIndex][Client_HumanClass]);
    if(!flInterval && (gClientData[clientIndex][Client_Zombie] ? !ZombieGetSkillCountDown(gClientData[clientIndex][Client_ZombieClass]) : !HumanGetSkillCountDown(gClientData[clientIndex][Client_HumanClass])))
    {
        return;
    }
    
    // Verify that the skills are avalible
    if(!gClientData[clientIndex][Client_Skill] && !gClientData[clientIndex][Client_SkillCountDown])
    {
        // Call forward
        Action resultHandle = API_OnClientSkillUsed(clientIndex);
        
        // Block skill usage
        if(resultHandle == Plugin_Handled || resultHandle == Plugin_Stop)
        {
            return;
        }

        // Sets skill usage
        gClientData[clientIndex][Client_Skill] = true;
        
        // Sets timer for removing skill usage
        delete gClientData[clientIndex][Client_SkillTimer];
        gClientData[clientIndex][Client_SkillTimer] = CreateTimer(flInterval, SkillsOnEnd, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * Timer for remove a skill usage.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillsOnEnd(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Clear timer
    gClientData[clientIndex][Client_SkillTimer] = INVALID_HANDLE;
    
    // Validate client
    if(clientIndex)
    {
        // Remove skill usage and set countdown time
        gClientData[clientIndex][Client_Skill] = false;
        gClientData[clientIndex][Client_SkillCountDown] = gClientData[clientIndex][Client_Zombie] ? ZombieGetSkillCountDown(gClientData[clientIndex][Client_ZombieClass]) : HumanGetSkillCountDown(gClientData[clientIndex][Client_HumanClass]);
        
        // Sets timer for countdown
        delete gClientData[clientIndex][Client_CountDownTimer];
        gClientData[clientIndex][Client_CountDownTimer] = CreateTimer(1.0, SkillsOnCountDown, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        
        // Call forward
        API_OnClientSkillOver(clientIndex);
    }

    // Destroy timer
    return Plugin_Stop;
}

/**
 * Timer for the skill countdown.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action SkillsOnCountDown(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Substitute counter
        gClientData[clientIndex][Client_SkillCountDown]--;
        
        // If counter is over, then stop
        if(!gClientData[clientIndex][Client_SkillCountDown])
        {
            // Show message
            TranslationPrintHintText(clientIndex, "skill ready");

            // Clear timer
            gClientData[clientIndex][Client_CountDownTimer] = INVALID_HANDLE;
            
            // Destroy timer
            return Plugin_Stop;
        }

        // Show counter
        TranslationPrintHintText(clientIndex, "countdown", RoundToCeil(gClientData[clientIndex][Client_SkillCountDown]));
        
        // Allow timer
        return Plugin_Continue;
    }
    
    // Clear timer
    gClientData[clientIndex][Client_CountDownTimer] = INVALID_HANDLE;
    
    // Destroy timer
    return Plugin_Stop;
}