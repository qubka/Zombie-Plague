/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          visualeffects.cpp
 *  Type:          Module 
 *  Description:   Visual effects.
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

 /*
  * Load other visual effect modules
  */
#include "zp/visualeffects/visualambience.cpp"
#include "zp/visualeffects/visualoverlay.cpp"
#include "zp/visualeffects/ragdoll.cpp"
 
/**
 * @section Explosion flags.
 **/
#define EXP_NODAMAGE               1
#define EXP_REPEATABLE             2
#define EXP_NOFIREBALL             4
#define EXP_NOSMOKE                8
#define EXP_NODECAL               16
#define EXP_NOSPARKS              32
#define EXP_NOSOUND               64
#define EXP_RANDOMORIENTATION    128
#define EXP_NOFIREBALLSMOKE      256
#define EXP_NOPARTICLES          512
#define EXP_NODLIGHTS           1024
#define EXP_NOCLAMPMIN          2048
#define EXP_NOCLAMPMAX          4096
/**
 * @endsection
 **/

/**
 * @section Fade flags.
 **/
#define FFADE_IN            	0x0001        
#define FFADE_OUT            	0x0002        
#define FFADE_MODULATE          0x0004      
#define FFADE_STAYOUT           0x0008       
#define FFADE_PURGE            	0x0010       
/**
 * @endsection
 **/
 
/**
 * Number of valid models.
 **/
int decalSmoke;
int decalBloodDecal;

/**
 * Load visual effects data.
 */
void VEffectsLoad(/*void*/)
{
	// Precache smoke model
	decalSmoke = PrecacheModel("sprites/steam1.vmt");
	
	// Precache blood decals
	decalBloodDecal = PrecacheDecal("decals/bloodstain_001.vtf");
	
	// Forward event to sub-modules
	VAmbienceLoad();
	VOverlayLoad(); //=> better to load it in the config execute
}

/**
 * Plugin has just finished creating/hooking cvars.
 **/
void VEffectsOnCvarInit(/*void*/)
{
    // Hook zp_veffects_* cvars
    VAmbienceCvarsHook();
}
 
/**
 * Create infect effect.
 *
 * @param clientIndex		The client index.
 **/
void VEffectInfectEffect(int clientIndex)
{
	// Initialize vector variables
	static float flOrigin[3];
	
	// Get client's position
	GetClientAbsOrigin(clientIndex, flOrigin);
	flOrigin[2] += 30;

	// Create smoke explosion at client's origin
	if(GetConVarBool(gCvarList[CVAR_VEFFECTS_EXPLOSION])) 
	{
		VEffectSmokeFunction(flOrigin);
		VEffectDustFunction(flOrigin);
	}
	
	// Create energy splash effect
	if(GetConVarBool(gCvarList[CVAR_VEFFECTS_SPLASH]))
	{
		VEffectEnergySplashFunction(flOrigin);
	}
	
	// Shake client's screen
	VEffectsShakeClientScreen(clientIndex);
}

/**
 * Create spawn effect.
 *
 * @param clientIndex		The client index.
 **/
void VEffectSpawnEffect(int clientIndex)
{
	// Initialize vector variable
	static float flOrigin[3];
	
	// Get client's position
	GetClientAbsOrigin(clientIndex, flOrigin);
	
	// Create an fire entity
	int nEntity = CreateEntityByName("info_particle_system");
	
	// If entity isn't valid, then skip
	if(nEntity)
	{
		// Give name to the entity 
		DispatchKeyValue(nEntity, "effect_name", "env_fire_large");
		
		// Sets the origin of the explosion
		DispatchKeyValueVector(nEntity, "origin", flOrigin);
		
		// Spawn the entity into the world
		DispatchSpawn(nEntity);
		
		// Get and modify flags on fired
		SetVariantString("!activator");
		
		// Sets parent to the entity
		AcceptEntityInput(nEntity, "SetParent", clientIndex);
		
		// Activate the enity
		ActivateEntity(nEntity);
		AcceptEntityInput(nEntity, "Start");
		
		// Sets modified flags on entity
		SetVariantString("OnUser1 !self:kill::1.5:1");
		AcceptEntityInput(nEntity, "AddOutput");
		AcceptEntityInput(nEntity, "FireUser1");
	}
}

/**
 * Shake a client's screen with specific parameters.
 * 
 * @param clientIndex		The client index.
 **/
void VEffectsShakeClientScreen(int clientIndex)
{
	// If screen shake disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_VEFFECTS_SHAKE])) 
	{
		return;
	}

	// Create message
	Handle hShake = StartMessageOne("Shake", clientIndex);

	// Validate message
	if(hShake != INVALID_HANDLE)
	{
		// Write shake information to message handle
		PbSetInt(hShake,   "command", 0);
		PbSetFloat(hShake, "local_amplitude", GetConVarFloat(gCvarList[CVAR_VEFFECTS_SHAKE_AMP]));
		PbSetFloat(hShake, "frequency", GetConVarFloat(gCvarList[CVAR_VEFFECTS_SHAKE_FREQUENCY]));
		PbSetFloat(hShake, "duration", GetConVarFloat(gCvarList[CVAR_VEFFECTS_SHAKE_DURATION]));

		// End usermsg and send to client
		EndMessage();
	}
}

/**
 * Fade a client's screen with specific parameters.
 * 
 * @param clientIndex		The client index.
 */
void VEffectsFadeClientScreen(int clientIndex)
{
	// If screen fade disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_VEFFECTS_FADE])) 
	{
		return;
	}

	// Create message
	Handle hFade = StartMessageOne("Fade", clientIndex);

	// Validate message
	if(hFade != INVALID_HANDLE)
	{
		// Write shake information to message handle
		PbSetInt(hFade, "duration", RoundToNearest(GetConVarFloat(gCvarList[CVAR_VEFFECTS_FADE_DURATION]) * 1000.0)); 
		PbSetInt(hFade, "hold_time", RoundToNearest(GetConVarFloat(gCvarList[CVAR_VEFFECTS_FADE_TIME]) * 1000.0)); 
		PbSetInt(hFade, "flags", FFADE_IN); 
		PbSetColor(hFade, "clr", {255, 0, 0, 75}); 

		// End usermsg and send to client
		EndMessage();
	}
}

/**
 * Make footsteps and bloodstains on the floor.
 *
 * @param sTimer     	 	The timer index.
 * @param cBasePlayer    	The client index.
 **/
public Action VEffectsBleeding(Handle sTimer, CBasePlayer* cBasePlayer)
{
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return ACTION_STOP;
	}
	
	// Verify that the client is zombie
	if(cBasePlayer->m_bZombie)
	{
		// If player on the ground
		if(cBasePlayer->m_iFlags & FL_ONGROUND)
		{
			// Initialize origin vectors
			static float flOrigin[3];

			// Get client's position
			cBasePlayer->m_flGetOrigin(flOrigin);
			
			// Get the foot' position
			flOrigin[1] -= 36.0;
			
			// Create bleeding particle
			VEffectBloodDecalFunction(flOrigin);
		}
		
		// Allow bleeding
		return ACTION_CONTINUE;
	}
	
	// Remove bleeding
	return ACTION_STOP;
}

/**
 * Create a light dynamic entity.
 * 
 * @param flOrigin			The vector for origin of entity.
 * @param colorLight		The string will color. (RGBA)
 * @param flDistanceLight	The distance of light.
 * @param flRadiusLight		The radius of light.
 * @param flDurationLight	The duration of light.
 * @param attachMent		If true, entity will be attach to client.
 * @param clientIndex	 	(Optional) The client index.
 **/
void VEffectLightDynamic(float flOrigin[3] = 0.0, char[] colorLight, float flDistanceLight, float flRadiusLight, float flDurationLight, bool attachMent = false, int clientIndex = 0)
{
	// Create an light_dynamic entity
	int iLight = CreateEntityByName("light_dynamic");

	// If entity isn't valid, then skip
	if(iLight)
	{
		// Sets the inner (bright) angle
		DispatchKeyValue(iLight, "inner_cone", "0");
		
		// Sets the outer (fading) angle
		DispatchKeyValue(iLight, "cone", "80");
		
		// Sets the light brightness
		DispatchKeyValue(iLight, "brightness", "1");
		
		// Used instead of Pitch Yaw Roll's value for reasons unknown
		DispatchKeyValue(iLight, "pitch", "90");
		
		// Change the lightstyle (see Appearance field for possible values)
		DispatchKeyValue(iLight, "style", "1");
		
		// Sets the light's render color (R G B)
		DispatchKeyValue(iLight, "_light", colorLight);
		
		// Sets the maximum light distance
		DispatchKeyValueFloat(iLight, "distance", flDistanceLight);
		
		// Sets the radius of the spotlight at the end point
		DispatchKeyValueFloat(iLight, "spotlight_radius", flRadiusLight);

		// Spawn the entity
		DispatchSpawn(iLight);

		// Activate the enity
		AcceptEntityInput(iLight, "TurnOn");
		
		// Update vectors of player
		if(attachMent)
		{
			// Get client's position
			GetClientAbsOrigin(clientIndex, flOrigin);
		}

		// Teleport the entity
		TeleportEntity(iLight, flOrigin, NULL_VECTOR, NULL_VECTOR);
		
		// Attach light to the player
		if(attachMent)
		{
			// Sets the parent
			SetVariantString("!activator"); 
			AcceptEntityInput(iLight, "SetParent", clientIndex, iLight); 
			SetEntPropEnt(iLight, Prop_Data, "m_pParent", clientIndex);
		}
		else
		{
			// Emit the sound
			EmitSoundToAll("items/nvg_on.wav", iLight, SNDCHAN_STATIC);
		}
		
		// Initialize char
		static char sTime[SMALL_LINE_LENGTH];
		Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", flDurationLight);
		
		// Sets modified flags on the entity
		SetVariantString(sTime);
		AcceptEntityInput(iLight, "AddOutput");
		AcceptEntityInput(iLight, "FireUser1");
	}
}

/**
 * Delete a light dynamic entity from the client.
 * 
 * @param clientIndex		The client index.
 **/
void VEffectRemoveLightDynamic(int clientIndex)
{
	// Initialize char
	static char sClassname[NORMAL_LINE_LENGTH];
	
	// Get max amount of entities
	int nGetMaxEnt = GetMaxEntities();
	
	// nEntity = entity index
	for (int nEntity = 0; nEntity <= nGetMaxEnt; nEntity++)
	{
		// If entity isn't valid, then stop
		if(!IsValidEdict(nEntity))
		{
			continue;	
		}
		
		// Get valid edict's classname
		GetEdictClassname(nEntity, sClassname, sizeof(sClassname));
		
		// If entity is light dymanic
		if(StrEqual(sClassname, "light_dynamic"))
		{
			if(GetEntPropEnt(nEntity, Prop_Data, "m_pParent") == clientIndex)
			{
				AcceptEntityInput(nEntity, "Kill");
			}
		}
	}
}

/**
 * Ignites the client on fire.
 * 
 * @param clientIndex		The client index.
 **/
void VEffectIgniteEntity(int clientIndex, float flDurationFire)
{
	// Put fire on it
	IgniteEntity(clientIndex, flDurationFire);
}

/**
 * Extinguishes the client that is on fire.
 * 
 * @param clientIndex		The client index.
 **/
void VEffectExtinguishEntity(int clientIndex)
{
	// This instead of 'ExtinguishEntity' function
	int fireIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hEffectEntity");
	if(IsValidEdict(fireIndex))
	{
		// Make sure the entity is a flame, so we can extinguish it
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(fireIndex, sClassname, sizeof(sClassname));
		if(StrEqual(sClassname, "entityflame", false))
		{
			SetEntPropFloat(fireIndex, Prop_Data, "m_flLifetime", 0.0);
		}
	}
}

/**
 * Create blood decal.
 *
 * @param flOrigin			The position of the effect.
 **/
void VEffectBloodDecalFunction(float flOrigin[3])
{
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", flOrigin);
	TE_WriteNum("m_nIndex", decalBloodDecal);
	TE_SendToAll();
}

/**
 * Create smoke explosion effect.
 *
 * @param flOrigin			The position of the effect.
 **/
void VEffectSmokeFunction(float flOrigin[3])
{
	TE_SetupSmoke(flOrigin, decalSmoke, 130.0, 10);
	TE_SendToAll();
}

/**
 * Create dust effect.
 *
 * @param flOrigin			The position of the effect.
 **/
void VEffectDustFunction(float flOrigin[3])
{
	TE_SetupDust(flOrigin, NULL_VECTOR, 10.0, 1.0);
	TE_SendToAll();
}

/**
 * Create energy splash effect.
 *
 * @param flOrigin			The position of the effect.
 **/
void VEffectEnergySplashFunction(float flOrigin[3])
{
	TE_SetupEnergySplash(flOrigin, NULL_VECTOR, true);
	TE_SendToAll();
}