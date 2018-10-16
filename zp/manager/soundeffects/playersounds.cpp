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
 * Server sound types.
 **/
enum ServerSounds
{
    Survivor_Infect,    /** When a survivor is infect */
    Survivor_Hurt,      /** When a survivor is hurt */
    Survivor_Death,     /** When a survivor is killed */

    Nemesis_Idle,       /** Nemesis moan periodically */
    Nemesis_Hurt,       /** When a nemesis is hurt */
    Nemesis_Death,      /** When a nemesis is killed */
    Nemesis_Burn,       /** When a nemesis is on fire */
    Nemesis_Footstep,   /** When a nemesis is walk */
    Nemesis_Respawn,    /** When a nemesis is respawn */
    Nemesis_Attack,     /** When a nemesis is attack */

    Player_Flashlight,  /** When a player is switch the flashlight */
    Player_Ammunition,  /** When a player is buy the ammunition */
    Player_Level,       /** When a player is level up */       

    Round_Start,        /** When a round is started */
    Round_Count,        /** When a round is counting */
    Round_Zombie,       /** When a zombie is won */
    Round_Human,        /** When a human is won */
    Round_Draw          /** When a nobody is won */
}

/**
 * Sound default keys.
 **/
int gServerKey[ServerSounds];

/**
 * Prepare all player sounds data.
 **/
void PlayerSoundsOnLoad(/*void*/)
{
    // Initialize variable
    static char sBuffer[PARAM_NAME_MAXLEN];
    
    // Load survivor infect sounds
    gCvarList[CVAR_SEFFECTS_SURVIVOR_INFECT].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Survivor_Infect] = SoundsKeyToIndex(sBuffer);

    // Load survivor hurt sounds
    gCvarList[CVAR_SEFFECTS_SURVIVOR_HURT].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Survivor_Hurt] = SoundsKeyToIndex(sBuffer);

    // Load survivor death sounds
    gCvarList[CVAR_SEFFECTS_SURVIVOR_DEATH].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Survivor_Death] = SoundsKeyToIndex(sBuffer);

    // Load nemesis idle sounds
    gCvarList[CVAR_SEFFECTS_NEMESIS_IDLE].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Nemesis_Idle] = SoundsKeyToIndex(sBuffer);

    // Load nemesis hurt sounds
    gCvarList[CVAR_SEFFECTS_NEMESIS_HURT].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Nemesis_Hurt] = SoundsKeyToIndex(sBuffer);

    // Load nemesis death sounds
    gCvarList[CVAR_SEFFECTS_NEMESIS_DEATH].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Nemesis_Death] = SoundsKeyToIndex(sBuffer);

    // Load nemesis burn sounds
    gCvarList[CVAR_SEFFECTS_NEMESIS_BURN].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Nemesis_Burn] = SoundsKeyToIndex(sBuffer);

    // Load nemesis footstep sounds
    gCvarList[CVAR_SEFFECTS_NEMESIS_FOOTSTEP].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Nemesis_Footstep] = SoundsKeyToIndex(sBuffer);

    // Load nemesis respawn sounds
    gCvarList[CVAR_SEFFECTS_NEMESIS_RESPAWN].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Nemesis_Respawn] = SoundsKeyToIndex(sBuffer);

    // Load nemesis attack sounds
    gCvarList[CVAR_SEFFECTS_NEMESIS_ATTACK].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Nemesis_Attack] = SoundsKeyToIndex(sBuffer);

    // Load player flashlight sounds
    gCvarList[CVAR_SEFFECTS_PLAYER_FLASHLIGHT].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Player_Flashlight] = SoundsKeyToIndex(sBuffer);

    // Load player ammunition sounds
    gCvarList[CVAR_SEFFECTS_PLAYER_AMMUNITION].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Player_Ammunition] = SoundsKeyToIndex(sBuffer);

    // Load player level sounds
    gCvarList[CVAR_SEFFECTS_PLAYER_LEVEL].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Player_Level] = SoundsKeyToIndex(sBuffer);

    // Load round start sounds
    gCvarList[CVAR_SEFFECTS_ROUND_START].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Round_Start] = SoundsKeyToIndex(sBuffer);

    // Load round count sounds
    gCvarList[CVAR_SEFFECTS_ROUND_COUNT].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Round_Count] = SoundsKeyToIndex(sBuffer);

    // Load round zombie win sounds
    gCvarList[CVAR_SEFFECTS_ROUND_ZOMBIE].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Round_Zombie] = SoundsKeyToIndex(sBuffer);

    // Load round human win sounds
    gCvarList[CVAR_SEFFECTS_ROUND_HUMAN].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Round_Human] = SoundsKeyToIndex(sBuffer);

    // Load round draw sounds
    gCvarList[CVAR_SEFFECTS_ROUND_DRAW].GetString(sBuffer, sizeof(sBuffer));
    gServerKey[Round_Draw] = SoundsKeyToIndex(sBuffer);
}

/**
 * The round is ending. (Post)
 *
 * @param CReason           Reason the round has ended.
 **/
public Action PlayerSoundsOnRoundEnd(Handle hTimer, const int CReason)
{
    // Switch end round reason
    switch(CReason)
    {
        // Emit sounds
        case ROUNDEND_TERRORISTS_WIN : SoundsInputEmitToAll(gServerKey[Round_Zombie], 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);   
        case ROUNDEND_CTS_WIN :        SoundsInputEmitToAll(gServerKey[Round_Human], 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
        case ROUNDEND_ROUND_DRAW :     SoundsInputEmitToAll(gServerKey[Round_Draw], 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
    }
}

/**
 * Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientDeath(const int clientIndex)
{
    // If death sound cvar is disabled, then stop
    bool bDeath = gCvarList[CVAR_SEFFECTS_DEATH].BoolValue;
    if(!bDeath)
    {
        return;
    }

    // Is zombie died ?
    if(gClientData[clientIndex][Client_Zombie])
    {
        // Emit zombie death sound
        SoundsInputEmitToAll(gClientData[clientIndex][Client_Nemesis] ? gServerKey[Nemesis_Death] : ZombieGetSoundDeathID(gClientData[clientIndex][Client_ZombieClass]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
    }
    else
    {
        // Emit human death sound
        SoundsInputEmitToAll(gClientData[clientIndex][Client_Survivor] ? gServerKey[Survivor_Death] : HumanGetSoundDeathID(gClientData[clientIndex][Client_HumanClass]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
    }
}

/**
 * Client has been hurt.
 * 
 * @param clientIndex       The client index.
 * @param bBurning          The burning type of damage. 
 **/
void PlayerSoundsOnClientHurt(const int clientIndex, const bool bBurning)
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
        // Validate burning
        if(bBurning)
        {
            // If burn sounds disabled, then skip
            if(gCvarList[CVAR_SEFFECTS_BURN].BoolValue) 
            {
                // Emit zombie burn sound
                SoundsInputEmitToAll(gClientData[clientIndex][Client_Nemesis] ? gServerKey[Nemesis_Burn] : ZombieGetSoundBurnID(gClientData[clientIndex][Client_ZombieClass]), 0, clientIndex, SNDCHAN_BODY, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
                return; //! Exit here
            }
        }
        
        // Is zombie hurt ?
        if(gClientData[clientIndex][Client_Zombie])
        {
            // Emit zombie hurt sound
            SoundsInputEmitToAll(gClientData[clientIndex][Client_Nemesis] ? gServerKey[Nemesis_Hurt] : ZombieGetSoundHurtID(gClientData[clientIndex][Client_ZombieClass]), 0, clientIndex, SNDCHAN_BODY, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
        }
        else
        {
            // Emit human hurt sound
            SoundsInputEmitToAll(gClientData[clientIndex][Client_Survivor] ? gServerKey[Survivor_Hurt] : HumanGetSoundHurtID(gClientData[clientIndex][Client_HumanClass]), 0, clientIndex, SNDCHAN_BODY, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
        }
    }
}

/**
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param respawnMode       (Optional) Indicates that infection was on spawn.
 **/
void PlayerSoundsOnClientInfected(const int clientIndex, const bool respawnMode)
{
    // If infect sound cvar is disabled, then skip
    if(gCvarList[CVAR_SEFFECTS_INFECT].BoolValue) 
    {
        // Validate respawn mode
        if(respawnMode)
        {
            // Emit zombie respawn sound
            SoundsInputEmitToAll(gClientData[clientIndex][Client_Nemesis] ? gServerKey[Nemesis_Respawn] : ZombieGetSoundRespawnID(gClientData[clientIndex][Client_ZombieClass]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
            
        }
        else
        {
            // Emit human infect sound
            SoundsInputEmitToAll(gClientData[clientIndex][Client_Survivor] ? gServerKey[Survivor_Infect] : HumanGetSoundInfectID(gClientData[clientIndex][Client_HumanClass]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
        }
    }
    
    // If interval is set to 0, then stop
    float flInterval = gCvarList[CVAR_SEFFECTS_MOAN].FloatValue;
    if(!flInterval)
    {
        return;
    }

    // Start repeating timer
    delete gClientData[clientIndex][Client_MoanTimer];
    gClientData[clientIndex][Client_MoanTimer] = CreateTimer(flInterval, PlayerSoundsMoanTimer, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer callback, repeats a moaning sound on zombies.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action PlayerSoundsMoanTimer(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Emit zombie moan sound
        SoundsInputEmitToAll(gClientData[clientIndex][Client_Nemesis] ? gServerKey[Nemesis_Idle] : ZombieGetSoundIdleID(gClientData[clientIndex][Client_ZombieClass]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    gClientData[clientIndex][Client_MoanTimer] = INVALID_HANDLE;
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientRegen(const int clientIndex)
{
    // Emit zombie regen sound
    SoundsInputEmitToAll(ZombieGetSoundRegenID(gClientData[clientIndex][Client_ZombieClass]), 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Client has been swith flashlight.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientFlashLight(const int clientIndex)
{
    // Emit player flashlight sound
    SoundsInputEmitToAll(gServerKey[Player_Flashlight], 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Client has been buy ammunition.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientAmmunition(const int clientIndex)
{
    // Emit player ammunition sound
    SoundsInputEmitToAll(gServerKey[Player_Ammunition], 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Client has been level up.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientLevelUp(const int clientIndex)
{
    // Emit player levelup sound
    SoundsInputEmitToAll(gServerKey[Player_Level], 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
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
    int clientIndex = (IsValidEdict(entityIndex) && WeaponsValidateKnife(entityIndex)) ? GetEntDataEnt2(entityIndex, g_iOffset_WeaponOwner) : entityIndex;

    // Validate client
    if(IsPlayerExist(clientIndex))
    {
        // Verify that the client is zombie
        if(gClientData[clientIndex][Client_Zombie])
        {
            // If a footstep sound, then proceed
            if(StrContains(sSample, "footsteps") != -1)
            {
                // If footstep sounds disabled, then stop
                if(gCvarList[CVAR_SEFFECTS_FOOTSTEPS].BoolValue) 
                {
                    // Emit zombie footstep sound
                    SoundsInputEmitToAll(gClientData[clientIndex][Client_Nemesis] ? gServerKey[Nemesis_Footstep] : ZombieGetSoundFootID(gClientData[clientIndex][Client_ZombieClass]), 0, clientIndex, SNDCHAN_STREAM, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
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
                    // Emit zombie slash sound
                    SoundsInputEmitToAll(gClientData[clientIndex][Client_Nemesis] ? gServerKey[Nemesis_Attack] : ZombieGetSoundAttackID(gClientData[clientIndex][Client_ZombieClass]), 0, entityIndex, SNDCHAN_WEAPON, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
                }
                
                // Block sounds
                return Plugin_Stop; 
            }
        }
    }

    // Allow sounds
    return Plugin_Continue;
}
