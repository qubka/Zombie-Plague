/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          playersounds.cpp
 *  Type:          Module 
 *  Description:   Player sound effects.
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
 * @section List of sounds used by the plugin.
 **/
enum SoundList
{
    Player_Flashlight,  /** When a player is switch the flashlight */
    Player_Ammunition,  /** When a player is buy the ammunition */
    Player_Level,       /** When a player is level up */    
    Player_Nvgs,        /** When a player is switch the nvgs */   

    Round_Start,        /** When a round is started */
    Round_Count         /** When a round is counting */
}
/**
 * @endsection
 **/
 
/**
 * Array to store sound data in.
 **/
int gServerKey[SoundList];

/**
 * Prepare all player sounds data.
 **/
void PlayerSoundsOnLoad(/*void*/)
{
    // Initialize buffer char
    static char sBuffer[PARAM_NAME_MAXLEN];
    
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
}

/**
 * Hook player sounds cvar changes.
 **/
void PlayerSoundsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_SEFFECTS_INFECT]            = FindConVar("zp_seffects_infect");
    gCvarList[CVAR_SEFFECTS_MOAN]              = FindConVar("zp_seffects_moan");
    gCvarList[CVAR_SEFFECTS_GROAN]             = FindConVar("zp_seffects_groan");
    gCvarList[CVAR_SEFFECTS_BURN]              = FindConVar("zp_seffects_burn");
    gCvarList[CVAR_SEFFECTS_DEATH]             = FindConVar("zp_seffects_death");
    gCvarList[CVAR_SEFFECTS_FOOTSTEPS]         = FindConVar("zp_seffects_footsteps");
    gCvarList[CVAR_SEFFECTS_CLAWS]             = FindConVar("zp_seffects_claws");
    gCvarList[CVAR_SEFFECTS_PLAYER_FLASHLIGHT] = FindConVar("zp_seffects_player_flashlight");  
    gCvarList[CVAR_SEFFECTS_PLAYER_NVGS]       = FindConVar("zp_seffects_player_nvgs");  
    gCvarList[CVAR_SEFFECTS_PLAYER_AMMUNITION] = FindConVar("zp_seffects_player_ammunition");
    gCvarList[CVAR_SEFFECTS_PLAYER_LEVEL]      = FindConVar("zp_seffects_player_level");
    gCvarList[CVAR_SEFFECTS_ROUND_START]       = FindConVar("zp_seffects_round_start");   
    gCvarList[CVAR_SEFFECTS_ROUND_COUNT]       = FindConVar("zp_seffects_round_count");   
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_SEFFECTS_PLAYER_FLASHLIGHT], PlayerSoundsCvarsHookChange);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_PLAYER_NVGS],       PlayerSoundsCvarsHookChange);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_PLAYER_AMMUNITION], PlayerSoundsCvarsHookChange);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_PLAYER_LEVEL],      PlayerSoundsCvarsHookChange);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_ROUND_START],       PlayerSoundsCvarsHookChange);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_ROUND_COUNT],       PlayerSoundsCvarsHookChange);
}

/**
 * The counter is begin.
 **/
void PlayerSoundsOnCounterStart(/*void*/)
{
    // Emit round start sound
    SEffectsInputEmitToAll(gServerKey[Round_Start], 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Timer callback, the round is ending. (Post)
 *
 * @param CReason           Reason the round has ended.
 **/
public Action PlayerSoundsOnRoundEndPost(Handle hTimer, const CSRoundEndReason CReason)
{
    // Switch end round reason
    switch(CReason)
    {
        // Emit sounds
        //case CSRoundEnd_TerroristWin : SEffectsInputEmitToAll(gServerKey[Round_Zombie], 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);   
        //case CSRoundEnd_CTWin :        SEffectsInputEmitToAll(gServerKey[Round_Human], 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
        //case CSRoundEnd_Draw :         SEffectsInputEmitToAll(gServerKey[Round_Draw], 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
    }
}

/**
 * The counter is working.
 *
 * @return                  True or false.
 **/
bool PlayerSoundsOnCounter(/*void*/)
{
    // Emit counter sound
    return SEffectsInputEmitToAll(gServerKey[Round_Count], gServerData[Server_RoundCount], SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * The gamemode is starting.
 **/
void PlayerSoundsOnGameModeStart(/*void*/)
{
    // Emit round start sound
    SEffectsInputEmitToAll(ModesGetSoundStartID(gServerData[Server_RoundMode]), 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
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

    // Emit death sound
    SEffectsInputEmitToAll(ClassGetSoundDeathID(gClientData[clientIndex][Client_Class]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
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
                // Emit burn sound
                SEffectsInputEmitToAll(ClassGetSoundBurnID(gClientData[clientIndex][Client_Class]), 0, clientIndex, SNDCHAN_BODY, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
                return; //! Exit here
            }
        }
        
        // Emit hurt sound
        SEffectsInputEmitToAll(ClassGetSoundHurtID(gClientData[clientIndex][Client_Class]), 0, clientIndex, SNDCHAN_BODY, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
    }
}

/**
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
void PlayerSoundsOnClientInfected(const int clientIndex, const int attackerIndex)
{
    // If infect sound cvar is disabled, then skip
    if(gCvarList[CVAR_SEFFECTS_INFECT].BoolValue) 
    {
        // If infection was done by server
        if(!attackerIndex)
        {
            // Emit respawn sound
            SEffectsInputEmitToAll(ClassGetSoundRespawnID(gClientData[clientIndex][Client_Class]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
        }
        else
        {
            // Emit infect sound
            SEffectsInputEmitToAll(ClassGetSoundInfectID(gClientData[clientIndex][Client_Class]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
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
    gClientData[clientIndex][Client_MoanTimer] = CreateTimer(flInterval, PlayerSoundsOnMoan, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer callback, repeats a moaning sound on zombies.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action PlayerSoundsOnMoan(Handle hTimer, const int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Emit moan sound
        SEffectsInputEmitToAll(ClassGetSoundIdleID(gClientData[clientIndex][Client_Class]), 0, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);

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
    // Emit regen sound
    SEffectsInputEmitToAll(ClassGetSoundRegenID(gClientData[clientIndex][Client_Class]), 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Client has been swith nightvision.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientNvgs(const int clientIndex)
{
    // Emit player nightvision sound
    SEffectsInputEmitToAll(gServerKey[Player_Nvgs], 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Client has been swith flashlight.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientFlashLight(const int clientIndex)
{
    // Emit player flashlight sound
    SEffectsInputEmitToAll(gServerKey[Player_Flashlight], 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Client has been buy ammunition.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientAmmunition(const int clientIndex)
{
    // Emit player ammunition sound
    SEffectsInputEmitToAll(gServerKey[Player_Ammunition], 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Client has been level up.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientLevelUp(const int clientIndex)
{
    // Emit player levelup sound
    SEffectsInputEmitToAll(gServerKey[Player_Level], 0, clientIndex, SNDCHAN_VOICE, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
}

/**
 * Client has been shoot.
 * 
 * @param clientIndex       The client index.
 * @param iD                The weapon id.
 * @return                  True or false.
 **/
bool PlayerSoundsOnClientShoot(const int clientIndex, const int iD)
{
    // Emit player shoot sound
    return SEffectsInputEmitToAll(WeaponsGetSoundID(iD), 0, clientIndex, SNDCHAN_WEAPON, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
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
        // If a footstep sound, then proceed
        if(StrContains(sSample, "footsteps", false) != -1)
        {
            // If footstep sounds disabled, then stop
            if(gCvarList[CVAR_SEFFECTS_FOOTSTEPS].BoolValue) 
            {
                // Emit footstep sound
                if(SEffectsInputEmitToAll(ClassGetSoundFootID(gClientData[clientIndex][Client_Class]), 0, clientIndex, SNDCHAN_ITEM, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue))
                {
                    // Block sounds
                    return Plugin_Stop; 
                }
            }
        }
        // If a knife sound, then proceed
        else if(StrContains(sSample, "knife", false) != -1)
        {
            // If attack sounds disabled, then stop
            if(gCvarList[CVAR_SEFFECTS_CLAWS].BoolValue) 
            {
                // Emit slash sound
                if(SEffectsInputEmitToAll(ClassGetSoundAttackID(gClientData[clientIndex][Client_Class]), 0, entityIndex, SNDCHAN_WEAPON, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue))
                {
                    // Block sounds
                    return Plugin_Stop; 
                }
            }
        }
    }

    // Allow sounds
    return Plugin_Continue;
}

/**
 * Cvar hook callback (zp_seffects_player_*, zp_seffects_round_*)
 * Load the sound variables.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void PlayerSoundsCvarsHookChange(ConVar hConVar, const char[] oldValue, const char[] newValue)
{    
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // Forward event to modules
        PlayerSoundsOnLoad();
    }
}