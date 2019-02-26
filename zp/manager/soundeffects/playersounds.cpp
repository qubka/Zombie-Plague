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
 * @section Struct of sounds used by the plugin.
 **/
enum struct SoundData
{
    int Flashlight;
    int Ammunition;
    int Level;
    int Nvgs;
    int Start;
    int Count;
    int Blast;
};
/**
 * @endsection
 **/
 
/**
 * Array to store sound data in.
 **/
SoundData gSoundData;

/**
 * @brief Prepare all player sounds data.
 **/
void PlayerSoundsOnOnLoad(/*void*/)
{
    // Initialize buffer char
    static char sBuffer[SMALL_LINE_LENGTH];
    
    // Load player flashlight sounds
    gCvarList[CVAR_SEFFECTS_PLAYER_FLASHLIGHT].GetString(sBuffer, sizeof(sBuffer));
    gSoundData.Flashlight = SoundsKeyToIndex(sBuffer);

    // Load player nightvision sounds
    gCvarList[CVAR_SEFFECTS_PLAYER_NVGS].GetString(sBuffer, sizeof(sBuffer));
    gSoundData.Nvgs = SoundsKeyToIndex(sBuffer);
    
    // Load player ammunition sounds
    gCvarList[CVAR_SEFFECTS_PLAYER_AMMUNITION].GetString(sBuffer, sizeof(sBuffer));
    gSoundData.Ammunition = SoundsKeyToIndex(sBuffer);

    // Load player level sounds
    gCvarList[CVAR_SEFFECTS_PLAYER_LEVEL].GetString(sBuffer, sizeof(sBuffer));
    gSoundData.Level = SoundsKeyToIndex(sBuffer);

    // Load round start sounds
    gCvarList[CVAR_SEFFECTS_ROUND_START].GetString(sBuffer, sizeof(sBuffer));
    gSoundData.Start = SoundsKeyToIndex(sBuffer);

    // Load round count sounds
    gCvarList[CVAR_SEFFECTS_ROUND_COUNT].GetString(sBuffer, sizeof(sBuffer));
    gSoundData.Count = SoundsKeyToIndex(sBuffer);
    
    // Load round blast sounds
    gCvarList[CVAR_SEFFECTS_ROUND_BLAST].GetString(sBuffer, sizeof(sBuffer));
    gSoundData.Blast = SoundsKeyToIndex(sBuffer);
}

/**
 * @brief Hook player sounds cvar changes.
 **/
void PlayerSoundsOnCvarInit(/*void*/)
{
    // Creates cvars
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
    gCvarList[CVAR_SEFFECTS_ROUND_BLAST]       = FindConVar("zp_seffects_round_blast");
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_SEFFECTS_PLAYER_FLASHLIGHT], PlayerSoundsOnCvarHook);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_PLAYER_NVGS],       PlayerSoundsOnCvarHook);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_PLAYER_AMMUNITION], PlayerSoundsOnCvarHook);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_PLAYER_LEVEL],      PlayerSoundsOnCvarHook);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_ROUND_START],       PlayerSoundsOnCvarHook);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_ROUND_COUNT],       PlayerSoundsOnCvarHook);
    HookConVarChange(gCvarList[CVAR_SEFFECTS_ROUND_BLAST],       PlayerSoundsOnCvarHook);
}

/**
 * @brief The counter is begin.
 **/
void PlayerSoundsOnCounterStart(/*void*/)
{
    // Emit round start sound
    SEffectsInputEmitToAll(gSoundData.Start, _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Timer callback, the round is ending. *(Post)
 *
 * @param reasonIndex       The reason index.
 **/
public Action PlayerSoundsOnRoundEndPost(Handle hTimer, CSRoundEndReason reasonIndex)
{
    // Clear timer
    gServerData.EndTimer = null;
    
    // Gets reason
    switch(reasonIndex)
    {
        // Emit sounds
        case CSRoundEnd_TerroristWin : SEffectsInputEmitToAll(ModesGetSoundEndZombieID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);   
        case CSRoundEnd_CTWin :        SEffectsInputEmitToAll(ModesGetSoundEndHumanID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
        case CSRoundEnd_Draw :         SEffectsInputEmitToAll(ModesGetSoundEndDrawID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
    }
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief The counter is working.
 *
 * @return                  True or false.
 **/
bool PlayerSoundsOnCounter(/*void*/)
{
    // Emit counter sound
    return SEffectsInputEmitToAll(gSoundData.Count, gServerData.RoundCount, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Timer callback, the blast is started. *(Post)
 **/
public Action PlayerSoundsOnBlastPost(Handle hTimer)
{
    // Clear timer
    gServerData.BlastTimer = null;
    
    // Emit blast sound
    SEffectsInputEmitToAll(gSoundData.Blast, _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);

    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief The gamemode is starting.
 **/
void PlayerSoundsOnGameModeStart(/*void*/)
{
    // Emit round start sound
    SEffectsInputEmitToAll(ModesGetSoundStartID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Client has been killed.
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

    // Emit death sound
    SEffectsInputEmitToAll(ClassGetSoundDeathID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Client has been hurt.
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
        // Validate burning
        if(bBurning)
        {
            // If burn sounds disabled, then skip
            if(gCvarList[CVAR_SEFFECTS_BURN].BoolValue) 
            {
                // Emit burn sound
                SEffectsInputEmitToAll(ClassGetSoundBurnID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_BODY, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
                return; /// Exit here
            }
        }
        
        // Emit hurt sound
        SEffectsInputEmitToAll(ClassGetSoundHurtID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_BODY, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
    }
}

/**
 * @brief Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
void PlayerSoundsOnClientInfected(int clientIndex, int attackerIndex)
{
    // If infect sound cvar is disabled, then skip
    if(gCvarList[CVAR_SEFFECTS_INFECT].BoolValue) 
    {
        // If change was done by server
        if(!attackerIndex)
        {
            // Emit respawn sound
            SEffectsInputEmitToAll(ClassGetSoundRespawnID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
        }
        else
        {
            // Emit infect sound
            SEffectsInputEmitToAll(ClassGetSoundInfectID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
        }
    }
    
    // If interval is set to 0, then stop
    float flInterval = gCvarList[CVAR_SEFFECTS_MOAN].FloatValue;
    if(!flInterval)
    {
        return;
    }

    // Start repeating timer
    delete gClientData[clientIndex].MoanTimer;
    gClientData[clientIndex].MoanTimer = CreateTimer(flInterval, PlayerSoundsOnMoanRepeat, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief Timer callback, repeats a moaning sound on zombies.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action PlayerSoundsOnMoanRepeat(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Emit moan sound
        SEffectsInputEmitToAll(ClassGetSoundIdleID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    gClientData[clientIndex].MoanTimer = null;
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientRegen(int clientIndex)
{
    // Emit regen sound
    SEffectsInputEmitToAll(ClassGetSoundRegenID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientJump(int clientIndex)
{
    // Emit jump sound
    SEffectsInputEmitToAll(ClassGetSoundJumpID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Client has been switch nightvision.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientNvgs(int clientIndex)
{
    // Emit player nightvision sound
    SEffectsInputEmitToAll(gSoundData.Nvgs, _, clientIndex, SNDCHAN_ITEM, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Client has been switch flashlight.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientFlashLight(int clientIndex)
{
    // Emit player flashlight sound
    SEffectsInputEmitToAll(gSoundData.Flashlight, _, clientIndex, SNDCHAN_ITEM, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Client has been buy ammunition.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientAmmunition(int clientIndex)
{
    // Emit player ammunition sound
    SEffectsInputEmitToAll(gSoundData.Ammunition, _, clientIndex, SNDCHAN_ITEM, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Client has been level up.
 * 
 * @param clientIndex       The client index.
 **/
void PlayerSoundsOnClientLevelUp(int clientIndex)
{
    // Emit player levelup sound
    SEffectsInputEmitToAll(gSoundData.Level, _, clientIndex, SNDCHAN_ITEM, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Client has been shoot.
 * 
 * @param clientIndex       The client index.
 * @param iD                The weapon id.
 * @return                  True or false.
 **/
bool PlayerSoundsOnClientShoot(int clientIndex, int iD)
{
    // Emit player shoot sound
    return SEffectsInputEmitToAll(WeaponsGetSoundID(iD), _, clientIndex, SNDCHAN_WEAPON, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue);
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
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
    int clientIndex = (IsValidEdict(entityIndex) && WeaponsValidateKnife(entityIndex)) ? WeaponsGetOwner(entityIndex) : entityIndex;

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
                if(SEffectsInputEmitToAll(ClassGetSoundFootID(gClientData[clientIndex].Class), _, clientIndex, SNDCHAN_STREAM, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue))
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
                if(SEffectsInputEmitToAll(ClassGetSoundAttackID(gClientData[clientIndex].Class), _, entityIndex, SNDCHAN_WEAPON, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue))
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
 * @brief Load the sound variables.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void PlayerSoundsOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{    
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if(gServerData.MapLoaded)
    {
        // Forward event to modules
        PlayerSoundsOnOnLoad();
    }
}