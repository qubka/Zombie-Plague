/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          playereffects.sp
 *  Type:          Module 
 *  Description:   Player visual effects.
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
 * @brief Hook player effects cvar changes.
 **/
void PlayerVEffectsOnCvarInit()
{
	gCvarList.VEFFECTS_INFECT                 = FindConVar("zp_veffects_infect"); 
	gCvarList.VEFFECTS_INFECT_FADE            = FindConVar("zp_veffects_infect_fade"); 
	gCvarList.VEFFECTS_INFECT_FADE_TIME       = FindConVar("zp_veffects_infect_fade_time"); 
	gCvarList.VEFFECTS_INFECT_FADE_DURATION   = FindConVar("zp_veffects_infect_fade_duration"); 
	gCvarList.VEFFECTS_INFECT_FADE_R          = FindConVar("zp_veffects_infect_fade_R");
	gCvarList.VEFFECTS_INFECT_FADE_G          = FindConVar("zp_veffects_infect_fade_G");
	gCvarList.VEFFECTS_INFECT_FADE_B          = FindConVar("zp_veffects_infect_fade_B");
	gCvarList.VEFFECTS_INFECT_FADE_A          = FindConVar("zp_veffects_infect_fade_A");
	gCvarList.VEFFECTS_INFECT_SHAKE           = FindConVar("zp_veffects_infect_shake"); 
	gCvarList.VEFFECTS_INFECT_SHAKE_AMP       = FindConVar("zp_veffects_infect_shake_amp");
	gCvarList.VEFFECTS_INFECT_SHAKE_FREQUENCY = FindConVar("zp_veffects_infect_shake_frequency");
	gCvarList.VEFFECTS_INFECT_SHAKE_DURATION  = FindConVar("zp_veffects_infect_shake_duration"); 
	gCvarList.VEFFECTS_HUMANIZE               = FindConVar("zp_veffects_humanize"); 
	gCvarList.VEFFECTS_HUMANIZE_FADE          = FindConVar("zp_veffects_humanize_fade"); 
	gCvarList.VEFFECTS_HUMANIZE_FADE_TIME     = FindConVar("zp_veffects_humanize_fade_time"); 
	gCvarList.VEFFECTS_HUMANIZE_FADE_DURATION = FindConVar("zp_veffects_humanize_fade_duration"); 
	gCvarList.VEFFECTS_HUMANIZE_FADE_R        = FindConVar("zp_veffects_humanize_fade_R");
	gCvarList.VEFFECTS_HUMANIZE_FADE_G        = FindConVar("zp_veffects_humanize_fade_G");
	gCvarList.VEFFECTS_HUMANIZE_FADE_B        = FindConVar("zp_veffects_humanize_fade_B");
	gCvarList.VEFFECTS_HUMANIZE_FADE_A        = FindConVar("zp_veffects_humanize_fade_A");
	gCvarList.VEFFECTS_RESPAWN                = FindConVar("zp_veffects_respawn"); 
	gCvarList.VEFFECTS_RESPAWN_NAME           = FindConVar("zp_veffects_respawn_name");
	gCvarList.VEFFECTS_RESPAWN_ATTACH         = FindConVar("zp_veffects_respawn_attachment"); 
	gCvarList.VEFFECTS_RESPAWN_DURATION       = FindConVar("zp_veffects_respawn_duration");
	gCvarList.VEFFECTS_HEAL                   = FindConVar("zp_veffects_heal"); 
	gCvarList.VEFFECTS_HEAL_NAME              = FindConVar("zp_veffects_heal_name");
	gCvarList.VEFFECTS_HEAL_ATTACH            = FindConVar("zp_veffects_heal_attachment"); 
	gCvarList.VEFFECTS_HEAL_DURATION          = FindConVar("zp_veffects_heal_duration");
	gCvarList.VEFFECTS_HEAL_FADE              = FindConVar("zp_veffects_heal_fade"); 
	gCvarList.VEFFECTS_HEAL_FADE_TIME         = FindConVar("zp_veffects_heal_fade_time"); 
	gCvarList.VEFFECTS_HEAL_FADE_DURATION     = FindConVar("zp_veffects_heal_fade_duration"); 
	gCvarList.VEFFECTS_HEAL_FADE_R            = FindConVar("zp_veffects_heal_fade_R");
	gCvarList.VEFFECTS_HEAL_FADE_G            = FindConVar("zp_veffects_heal_fade_G");
	gCvarList.VEFFECTS_HEAL_FADE_B            = FindConVar("zp_veffects_heal_fade_B");
	gCvarList.VEFFECTS_HEAL_FADE_A            = FindConVar("zp_veffects_heal_fade_A");
	gCvarList.VEFFECTS_LEAP                   = FindConVar("zp_veffects_leap"); 
	gCvarList.VEFFECTS_LEAP_NAME              = FindConVar("zp_veffects_leap_name");
	gCvarList.VEFFECTS_LEAP_ATTACH            = FindConVar("zp_veffects_leap_attachment"); 
	gCvarList.VEFFECTS_LEAP_DURATION          = FindConVar("zp_veffects_leap_duration");
	gCvarList.VEFFECTS_LEAP_SHAKE             = FindConVar("zp_veffects_leap_shake"); 
	gCvarList.VEFFECTS_LEAP_SHAKE_AMP         = FindConVar("zp_veffects_leap_shake_amp");
	gCvarList.VEFFECTS_LEAP_SHAKE_FREQUENCY   = FindConVar("zp_veffects_leap_shake_frequency");
	gCvarList.VEFFECTS_LEAP_SHAKE_DURATION    = FindConVar("zp_veffects_leap_shake_duration"); 
}

/**
 * @brief Client has been infected.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
void PlayerVEffectsOnClientInfected(int client, int attacker)
{
	if (!gCvarList.VEFFECTS_INFECT_SHAKE.BoolValue) 
	{
		VEffectsShakeClientScreen(client, gCvarList.VEFFECTS_INFECT_SHAKE_AMP, gCvarList.VEFFECTS_INFECT_SHAKE_FREQUENCY, gCvarList.VEFFECTS_INFECT_SHAKE_DURATION);
	}
	
	if (!gCvarList.VEFFECTS_INFECT_FADE.BoolValue) 
	{
		VEffectsFadeClientScreen(client, gCvarList.VEFFECTS_INFECT_FADE_DURATION, gCvarList.VEFFECTS_INFECT_FADE_TIME, gCvarList.VEFFECTS_INFECT_FADE_R, gCvarList.VEFFECTS_INFECT_FADE_G, gCvarList.VEFFECTS_INFECT_FADE_B, gCvarList.VEFFECTS_INFECT_FADE_A);
	}
	
	static char sParticle[SMALL_LINE_LENGTH];
	static char sAttachment[SMALL_LINE_LENGTH];

	static float flDuration;

	if (gServerData.RoundStart && attacker < 1)
	{
		if (!gCvarList.VEFFECTS_RESPAWN.BoolValue) 
		{
			return;
		}
		
		flDuration = gCvarList.VEFFECTS_RESPAWN_DURATION.FloatValue;
		if (!flDuration)
		{
			return;
		}

		gCvarList.VEFFECTS_RESPAWN_NAME.GetString(sParticle, sizeof(sParticle));
		gCvarList.VEFFECTS_RESPAWN_ATTACH.GetString(sAttachment, sizeof(sAttachment));
	}
	else
	{
		if (!gCvarList.VEFFECTS_INFECT.BoolValue) 
		{
			return;
		}
		
		flDuration = ClassGetEffectTime(gClientData[client].Class);
		if (!flDuration)
		{
			return;
		}

		ClassGetEffectName(gClientData[client].Class, sParticle, sizeof(sParticle)); 
		ClassGetEffectAttach(gClientData[client].Class, sAttachment, sizeof(sAttachment));
	}

	ParticlesCreate(client, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been humanized.
 * 
 * @param client            The client index.
 **/
void PlayerVEffectsOnClientHumanized(int client)
{
	if (!gCvarList.VEFFECTS_HUMANIZE_FADE.BoolValue) 
	{
		VEffectsFadeClientScreen(client, gCvarList.VEFFECTS_HUMANIZE_FADE_DURATION, gCvarList.VEFFECTS_HUMANIZE_FADE_TIME, gCvarList.VEFFECTS_HUMANIZE_FADE_R, gCvarList.VEFFECTS_HUMANIZE_FADE_G, gCvarList.VEFFECTS_HUMANIZE_FADE_B, gCvarList.VEFFECTS_HUMANIZE_FADE_A);
	}
	
	static char sParticle[SMALL_LINE_LENGTH];
	static char sAttachment[SMALL_LINE_LENGTH];
	
	static float flDuration;
	
	if (gServerData.RoundNew)
	{
		if (!gCvarList.VEFFECTS_RESPAWN.BoolValue) 
		{
			return;
		}
		
		flDuration = gCvarList.VEFFECTS_RESPAWN_DURATION.FloatValue;
		if (!flDuration)
		{
			return;
		}

		gCvarList.VEFFECTS_RESPAWN_NAME.GetString(sParticle, sizeof(sParticle));
		gCvarList.VEFFECTS_RESPAWN_ATTACH.GetString(sAttachment, sizeof(sAttachment));
	}
	else
	{
		if (!gCvarList.VEFFECTS_HUMANIZE.BoolValue) 
		{
			return;
		}
		
		flDuration = ClassGetEffectTime(gClientData[client].Class);
		if (!flDuration)
		{
			return;
		}

		ClassGetEffectName(gClientData[client].Class, sParticle, sizeof(sParticle)); 
		ClassGetEffectAttach(gClientData[client].Class, sAttachment, sizeof(sAttachment));
	}
	
	ParticlesCreate(client, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been regenerating.
 * 
 * @param client            The client index.
 **/
void PlayerVEffectsOnClientRegen(int client)
{
	if (!gCvarList.VEFFECTS_HEAL_FADE.BoolValue) 
	{
		VEffectsFadeClientScreen(client, gCvarList.VEFFECTS_HEAL_FADE_DURATION, gCvarList.VEFFECTS_HEAL_FADE_TIME, gCvarList.VEFFECTS_HEAL_FADE_R, gCvarList.VEFFECTS_HEAL_FADE_G, gCvarList.VEFFECTS_HEAL_FADE_B, gCvarList.VEFFECTS_HEAL_FADE_A);
	}
	
	if (!gCvarList.VEFFECTS_HEAL.BoolValue) 
	{
		return;
	}
	
	float flDuration = gCvarList.VEFFECTS_HEAL_DURATION.FloatValue;
	if (!flDuration)
	{
		return;
	}
	
	static char sParticle[SMALL_LINE_LENGTH];
	static char sAttachment[SMALL_LINE_LENGTH];
	
	gCvarList.VEFFECTS_HEAL_NAME.GetString(sParticle, sizeof(sParticle));
	gCvarList.VEFFECTS_HEAL_ATTACH.GetString(sAttachment, sizeof(sAttachment));
	
	ParticlesCreate(client, sAttachment, sParticle, flDuration);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param client            The client index.
 **/
void PlayerVEffectsOnClientJump(int client)
{
	if (!gCvarList.VEFFECTS_LEAP_SHAKE.BoolValue) 
	{
		VEffectsShakeClientScreen(client, gCvarList.VEFFECTS_LEAP_SHAKE_AMP, gCvarList.VEFFECTS_LEAP_SHAKE_FREQUENCY, gCvarList.VEFFECTS_LEAP_SHAKE_DURATION);
	}
	
	if (!gCvarList.VEFFECTS_LEAP.BoolValue) 
	{
		return;
	}
	
	float flDuration = gCvarList.VEFFECTS_LEAP_DURATION.FloatValue;
	if (!flDuration)
	{
		return;
	}
	
	static char sParticle[SMALL_LINE_LENGTH];
	static char sAttachment[SMALL_LINE_LENGTH];
	
	gCvarList.VEFFECTS_LEAP_NAME.GetString(sParticle, sizeof(sParticle)); 
	gCvarList.VEFFECTS_LEAP_ATTACH.GetString(sAttachment, sizeof(sAttachment));
	
	ParticlesCreate(client, sAttachment, sParticle, flDuration);
}
