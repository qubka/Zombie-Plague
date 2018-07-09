/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          playersounds.cpp
 *  Type:          Module 
 *  Description:   Player sound effects.
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
 * Sound types
 **/
enum PlayerSounds
{
    Infect,       /** When player is infect */
    Moan,         /** Zombie's moan periodically */
    Groan,        /** When zombie is hurt */
    Death,        /** When a zombie is killed */
    Burn,         /** When a zombie is on fire */
    FootStep      /** When a zombie is walk */
}

/**
 * Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientDeath(int clientIndex)
{
    // If death sound cvar is disabled, then stop
    bool bDeath = gCvarList[CVAR_SEFFECTS_DEATH].BoolValue;
    if(!bDeath)
    {
        return;
    }
    
    // Initialize sound char
    static char sSound[SMALL_LINE_LENGTH];
    
    // Is zombie died ?
    if(gClientData[clientIndex][Client_Zombie])
    {
        // Gets zombie's sound
        ZombieGetSoundDeath(gClientData[clientIndex][Client_ZombieClass], sSound, sizeof(sSound));
        
        // Emit zombie death sound
        SoundsInputEmitToClient(clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Nemesis] ? "NEMESIS_DEATH_SOUNDS" : sSound);
    }
    else
    {
        // Gets human's sound
        HumanGetSoundDeath(gClientData[clientIndex][Client_HumanClass], sSound, sizeof(sSound));
        
        // Emit human death sound
        SoundsInputEmitToClient(clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Survivor] ? "SURVIVOR_DEATH_SOUNDS" : sSound);
    }
}

/**
 * Client has been hurt.
 * 
 * @param clientIndex       The client index.
 * @param bBurning          The burning type of damage. 
 **/
void PlayerSoundsOnClientHurt(int clientIndex, bool bBurning)
{
    // Gets groan factor, if 0, then stop
    int iGroan = gCvarList[CVAR_SEFFECTS_GROAN].IntValue;
    if(!iGroan)
    {
        return;
    }

    // 1 in 'groan' chance of groaning
    if(GetRandomInt(1, iGroan) == 1)
    {
        // Initialize sound char
        static char sSound[SMALL_LINE_LENGTH];
        
        // Validate burning
        if(bBurning)
        {
            // If burn sounds disabled, then skip
            if(gCvarList[CVAR_SEFFECTS_BURN].BoolValue) 
            {
                // Gets zombie's sound
                ZombieGetSoundBurn(gClientData[clientIndex][Client_ZombieClass], sSound, sizeof(sSound));
                
                // Emit zombie burn sound
                SoundsInputEmitToClient(clientIndex, SNDCHAN_BODY, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Nemesis] ? "NEMESIS_BURN_SOUNDS" : sSound);
                return; //! Exit here
            }
        }
        
        // Is zombie hurt ?
        if(gClientData[clientIndex][Client_Zombie])
        {
            // Gets zombie's sound
            ZombieGetSoundHurt(gClientData[clientIndex][Client_ZombieClass], sSound, sizeof(sSound));
            
            // Emit zombie hurt sound
            SoundsInputEmitToClient(clientIndex, SNDCHAN_BODY, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Nemesis] ? "NEMESIS_HURT_SOUNDS" : sSound);
        }
        else
        {
            // Gets human's sound
            HumanGetSoundHurt(gClientData[clientIndex][Client_HumanClass], sSound, sizeof(sSound));
            
            // Emit human hurt sound
            SoundsInputEmitToClient(clientIndex, SNDCHAN_BODY, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Survivor] ? "SURVIVOR_HURT_SOUNDS" : sSound);
        }
    }
}

/**
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param respawnMode       (Optional) Indicates that infection was on spawn.
 **/
void PlayerSoundsOnClientInfected(int clientIndex, bool respawnMode)
{
    // If infect sound cvar is disabled, then skip
    if(gCvarList[CVAR_SEFFECTS_INFECT].BoolValue) 
    {
        // Initialize sound char
        static char sSound[SMALL_LINE_LENGTH];
        
        // Validate respawn mode
        if(respawnMode)
        {
            // Gets zombie's sound
            ZombieGetSoundRespawn(gClientData[clientIndex][Client_ZombieClass], sSound, sizeof(sSound));
            
            // Emit zombie respawn sound
            SoundsInputEmitToClient(clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Nemesis] ? "NEMESIS_RESPAWN_SOUNDS" : sSound);
            
        }
        else
        {
            // Gets human's sound
            HumanGetSoundInfect(gClientData[clientIndex][Client_HumanClass], sSound, sizeof(sSound));
            
            // Emit human infect sound
            SoundsInputEmitToClient(clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Survivor] ? "SURVIVOR_INFECTION_SOUNDS" : sSound);
        }
    }
    
    // If interval is set to 0, then stop
    float flInterval = gCvarList[CVAR_SEFFECTS_MOAN].FloatValue;
    if(!flInterval)
    {
        return;
    }

    // Start repeating timer
    delete gClientData[clientIndex][Client_ZombieMoanTimer];
    gClientData[clientIndex][Client_ZombieMoanTimer] = CreateTimer(flInterval, PlayerSoundsMoanTimer, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer callback, repeats a moaning sound on zombies.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action PlayerSoundsMoanTimer(Handle hTimer, int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Initialize sound char
        static char sSound[SMALL_LINE_LENGTH];
        
        // Gets zombie's sound
        ZombieGetSoundIdle(gClientData[clientIndex][Client_ZombieClass], sSound, sizeof(sSound));
        
        // Emit zombie moan sound
        SoundsInputEmitToClient(clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Nemesis] ? "NEMESIS_IDLE_SOUNDS" : sSound);

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    gClientData[clientIndex][Client_ZombieMoanTimer] = INVALID_HANDLE;
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientRegen(int clientIndex)
{
    // Initialize sound char
    static char sSound[SMALL_LINE_LENGTH];
    
    // Gets zombie's sound
    ZombieGetSoundRegen(gClientData[clientIndex][Client_ZombieClass], sSound, sizeof(sSound));
    
    // Emit zombie regen sound
    SoundsInputEmitToClient(clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, sSound);
}

/**
 * Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client's indexes.
 * @param numClients        Number of clients in the array (modify this value ifyou add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entityIndex       Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFrags            The sound flags.
 **/ 
public Action PlayerSoundsNormalHook(int clients[MAXPLAYERS-1], int &numClients, char[] sSample, int &entityIndex, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFrags)
{
    // Gets real player index from event key 
    int clientIndex = WeaponsValidateKnife(entityIndex) ? GetEntDataEnt2(entityIndex, g_iOffset_WeaponOwner) : entityIndex;

    // Validate client
    if(IsPlayerExist(clientIndex))
    {
        // Verify that the client is zombie
        if(gClientData[clientIndex][Client_Zombie])
        {
            // Initialize sound char
            static char sSound[SMALL_LINE_LENGTH];
            
            // If a footstep sound, then proceed
            if(StrContains(sSample, "footsteps") != -1)
            {
                // If footstep sounds disabled, then stop
                if(gCvarList[CVAR_SEFFECTS_FOOTSTEPS].BoolValue) 
                {
                    // Gets zombie's sound
                    ZombieGetSoundFoot(gClientData[clientIndex][Client_ZombieClass], sSound, sizeof(sSound));
                    
                    // Emit zombie footstep sound
                    SoundsInputEmitToClient(clientIndex, SNDCHAN_STREAM, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Nemesis] ? "NEMESIS_FOOTSTEP_SOUNDS" : sSound);
                }
                
                // Block sounds
                return Plugin_Stop; 
            }
            // If a knife sound, then proceed
            else if(StrContains(sSample, "knife") != -1)
            {
                // If attack sounds disabled, then stop
                if(gCvarList[CVAR_SEFFECTS_CLAWS].BoolValue) 
                {
                    // Gets zombie's sound
                    ZombieGetSoundAttack(gClientData[clientIndex][Client_ZombieClass], sSound, sizeof(sSound));
                    
                    // Emit zombie slash sound using the knife entity
                    SoundsInputEmitToClient(clientIndex, SNDCHAN_WEAPON, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, gClientData[clientIndex][Client_Nemesis] ? "NEMESIS_ATTACK_SOUNDS" : sSound, entityIndex);
                }
                
                // Block sounds
                return Plugin_Stop; 
            }
        }
    }

    // Allow sounds
    return Plugin_Continue;
}
