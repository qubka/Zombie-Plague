/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          voice.sp
 *  Type:          Module 
 *  Description:   Alter listening/speaking states of humans/zombies.
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
 * @brief Hook voice cvar changes.
 **/
void VoiceOnCvarInit()
{
	gCvarList.SEFFECTS_ALLTALK            = FindConVar("sv_alltalk");
	gCvarList.SEFFECTS_VOICE              = FindConVar("zp_seffects_voice");
	gCvarList.SEFFECTS_VOICE_ZOMBIES_MUTE = FindConVar("zp_seffects_voice_zombies_mute");
	
	HookConVarChange(gCvarList.SEFFECTS_VOICE,              VoiceOnCvarHookVoice);
	HookConVarChange(gCvarList.SEFFECTS_VOICE_ZOMBIES_MUTE, VoiceOnCvarHookMute);
}

/**
 * @brief The round is starting.
 **/
void VoiceOnRoundStart()
{
	gCvarList.SEFFECTS_ALLTALK.IntValue = 1;
}

/**
 * @brief The round is ending.
 **/
void VoiceOnRoundEnd()
{
	gCvarList.SEFFECTS_ALLTALK.IntValue = 1;
}

/**
 * @brief The gamemode is starting.
 **/
void VoiceOnGameModeStart()
{
	gCvarList.SEFFECTS_ALLTALK.IntValue = gCvarList.SEFFECTS_VOICE.BoolValue;
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void VoiceOnClientUpdate(int client)
{
	bool bVoiceMute = gCvarList.SEFFECTS_VOICE_ZOMBIES_MUTE.BoolValue;
	if (bVoiceMute)
	{
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
public void VoiceOnCvarHookVoice(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	if (gServerData.MapLoaded)
	{
		if (gServerData.RoundStart)
		{
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
public void VoiceOnCvarHookMute(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	if (gServerData.MapLoaded)
	{
		bool bVoiceMute = view_as<bool>(StringToInt(newValue));
	
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientValid(i, false) && gClientData[i].Zombie)
			{
				SetClientListeningFlags(i, bVoiceMute ? VOICE_MUTED : VOICE_NORMAL);
			}
		}
	}
}
