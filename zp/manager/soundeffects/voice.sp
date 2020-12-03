/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          voice.sp
 *  Type:          Module 
 *  Description:   Alter listening/speaking states of humans/zombies.
 *
 *  Copyright (C) 2015-2020  Greyscale, Richard Helgeby
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
 * @brief Hook voice cvar changes.
 **/
void VoiceOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.SEFFECTS_ALLTALK            = FindConVar("sv_alltalk");
	gCvarList.SEFFECTS_VOICE              = FindConVar("zp_seffects_voice");
	gCvarList.SEFFECTS_VOICE_ZOMBIES_MUTE = FindConVar("zp_seffects_voice_zombies_mute");
	
	// Hook cvars
	//HookConVarChange(gCvarList.SEFFECTS_ALLTALK],            VoiceOnCvarHook);
	HookConVarChange(gCvarList.SEFFECTS_VOICE,              VoiceOnCvarHook);
	HookConVarChange(gCvarList.SEFFECTS_VOICE_ZOMBIES_MUTE, VoiceMuteOnCvarHook);
}

/**
 * @brief The round is starting.
 **/
void VoiceOnRoundStart(/*void*/)
{
	// Allow everyone to listen/speak with each other
	gCvarList.SEFFECTS_ALLTALK.IntValue = 1;
}

/**
 * @brief The round is ending.
 **/
void VoiceOnRoundEnd(/*void*/)
{
	// Allow everyone to listen/speak with each other
	gCvarList.SEFFECTS_ALLTALK.IntValue = 1;
}

/**
 * @brief The gamemode is starting.
 **/
void VoiceOnGameModeStart(/*void*/)
{
	// Change the voice permissions based on custom cvar
	gCvarList.SEFFECTS_ALLTALK.IntValue = gCvarList.SEFFECTS_VOICE.BoolValue;
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void VoiceOnClientUpdate(int client)
{
	// If zombie mute is disabled, then skip
	bool bVoiceMute = gCvarList.SEFFECTS_VOICE_ZOMBIES_MUTE.BoolValue;
	if (bVoiceMute)
	{
		// Apply new voice flags
		SetClientListeningFlags(client, gClientData[client].Zombie ? VOICE_MUTED : VOICE_NORMAL);
	}
}

/**
 * Cvar hook callback (zp_seffects_voice)
 * @brief Reload the voice variable on zombie/human.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void VoiceOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (oldValue[0] == newValue[0])
	{
		return;
	}
	
	// Validate loaded map
	if (gServerData.MapLoaded)
	{
		// Reload only if round is started
		if (gServerData.RoundStart)
		{
			// Change the voice permissions based on custom cvar
			gCvarList.SEFFECTS_ALLTALK.IntValue = StringToInt(newValue);
		}
	}
}

/**
 * Cvar hook callback (zp_seffects_voice_zombies_mute)
 * @brief Resets the mute variable on zombie.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void VoiceMuteOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (oldValue[0] == newValue[0])
	{
		return;
	}
	
	// Validate loaded map
	if (gServerData.MapLoaded)
	{
		// If zombie mute is disabled, then reset flags
		bool bVoiceMute = view_as<bool>(StringToInt(newValue));
	
		// i = client index
		for (int i = 1; i <= MaxClients; i++)
		{
			// Validate zombie
			if (IsPlayerExist(i, false) && gClientData[i].Zombie)
			{
				// Update variables
				SetClientListeningFlags(i, bVoiceMute ? VOICE_MUTED : VOICE_NORMAL);
			}
		}
	}
}