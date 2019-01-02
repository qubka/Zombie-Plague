/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          voice.cpp
 *  Type:          Module 
 *  Description:   Alter listening/speaking states of humans/zombies.
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * Updates every round with the value of the cvar.
 **/
bool g_bVoice;

/**
 * Hook voice cvar changes.
 **/
void VoiceOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_SEFFECTS_ALLTALK]            = FindConVar("sv_alltalk");
    gCvarList[CVAR_SEFFECTS_VOICE]              = FindConVar("zp_seffects_voice");
    gCvarList[CVAR_SEFFECTS_VOICE_ZOMBIES_MUTE] = FindConVar("zp_seffects_voice_zombies_mute");
}

/**
 * The round is starting.
 **/
void VoiceOnRoundStart(/*void*/)
{
    bool bVoice = gCvarList[CVAR_SEFFECTS_VOICE].BoolValue;
    
    // If the cvar has changed, then reset the voice permissions
    if(g_bVoice != bVoice)
    {
        VoiceReset();
    }
    
    // Update cvar with new value
    g_bVoice = bVoice;
}

/**
 * The round is ending.
 **/
void VoiceOnRoundEnd(/*void*/)
{
    // If voice module is disabled, then stop
    if(!g_bVoice)
    {
        return;
    }
    
    // Allow everyone to listen/speak with each other
    VoiceAllTalk();
}

/**
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 **/
void VoiceOnClientInfected(const int clientIndex)
{
    // Give client proper verbal permissions
    VoiceOnClientUpdate(clientIndex);
}

/**
 * Client has been humanized.
 * 
 * @param clientIndex       The client index.
 **/
void VoiceOnClientHumanized(const int clientIndex)
{
    // Give client proper verbal permissions
    VoiceOnClientUpdate(clientIndex);
}

/**
 * Set the receiver ability to listen to the sender.
 *
 * @note  This function is from sdktools_voice, it fails if iSender is muted.
 *
 * @param iReceiver         The listener index.
 * @param iSender           The sender index.
 * @return                  True if successful otherwise false.
 **/
stock bool VoiceSetClientListening(const int iReceiver, const int iSender, const bool bListen)
{
    // If the sender is muted, then return false
    if(VoiceIsClientMuted(iSender))
    {
        return false;
    }
    
    // Sets overide
    ListenOverride override = bListen ? Listen_Yes : Listen_No;
    return SetListenOverride(iReceiver, iSender, override);
}

/**
 * Allow all clients to listen and speak with each other.
 **/
stock void VoiceAllTalk(/*void*/)
{
    // i = receiver index
    for(int i = 1; i <= MaxClients; i++)
    {
        // If receiver isn't in-game, then stop
        if(!IsPlayerExist(i, false))
        {
            continue;
        }
        
        // x = sender index
        for(int x = 1; x <= MaxClients; x++)
        {
            // If sender isn't in-game, then stop
            if(!IsPlayerExist(x, false))
            {
                continue;
            }
            
            // No need to alter listening/speaking flags between one client
            if(i == x)
            {
                continue;
            }
            
            // Receiver (i) can now hear the sender (x), only if sender isn't muted
            VoiceSetClientListening(i, x, true);
        }
    }
}

/**
 * Set which team the client is allowed to listen/speak with.
 * 
 * @param clientIndex       The client index.
 * @param bInfected         True to permit verbal communication to zombies only, false for humans only.
 **/
stock void VoiceSetClientTeam(const int clientIndex, const bool bInfected)
{
    // If zombie mute is disabled, then skip
    bool bVoiceZombieMute = gCvarList[CVAR_SEFFECTS_VOICE_ZOMBIES_MUTE].BoolValue;
    if(bVoiceZombieMute)
    {
        // Apply new voice flags
        SetClientListeningFlags(clientIndex, bInfected ? VOICE_MUTED : VOICE_NORMAL);
    }
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // If sender isn't in-game, then stop.
        if(!IsPlayerExist(i, false))
        {
            continue;
        }
        
        // No need to alter listening/speaking flags between one client
        if(clientIndex == i)
        {
            continue;
        }
        
        // Client can only listen/speak if the sender is on their team
        bool bCanListen = (bInfected == gClientData[i][Client_Zombie]);
        
        // (Dis)allow clients to listen/speak with each other, don't touch if the sender is muted
        VoiceSetClientListening(clientIndex, i, bCanListen);
        VoiceSetClientListening(i, clientIndex, bCanListen);
    }
}

/**
 * Update a client listening/speaking status.
 * 
 * @param clientIndex       The client index.
 * @param bInfected         True to permit verbal communication to zombies only, false for humans only.
 **/
stock void VoiceOnClientUpdate(const int clientIndex)
{
    // If voice module is disabled, then stop
    if(!g_bVoice)
    {
        return;
    }
    
    // Sets client listening/speaking status to their current team
    VoiceSetClientTeam(clientIndex, gClientData[clientIndex][Client_Zombie]);
}

/**
 * This function returns if the client is muted.
 * 
 * @param clientIndex    The client index.
 * @return               True if the client is muted, false if not.
 **/
stock bool VoiceIsClientMuted(const int clientIndex)
{
    // Return true if the mute flag isn't on the client
    return view_as<bool>(GetClientListeningFlags(clientIndex) & VOICE_MUTED);
}

/**
 * Reset voice listening/speaking permissions back to normal according to sv_alltalk.
 **/
stock void VoiceReset(/*void*/)
{
    // Is alltalk enabled?
    bool bAllTalk = gCvarList[CVAR_SEFFECTS_ALLTALK].BoolValue;
    
    // Determine new voice flags based off of alltalk
    int iVoiceFlags = bAllTalk ? VOICE_SPEAKALL | VOICE_LISTENALL : VOICE_TEAM | VOICE_LISTENTEAM;
    
    // x = Client index.
    for(int i = 1; i <= MaxClients; i++)
    {
        // If client isn't in-game, then stop
        if(!IsPlayerExist(i, false))
        {
            continue;
        }
        
        // Apply new voice flags
        SetClientListeningFlags(i, iVoiceFlags);
    }
}