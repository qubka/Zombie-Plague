/**
 * ============================================================================
 *
 *  Zombie Plague
 *
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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Zombie Class: Stamper",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_SHAKE_AMP         2.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY   1.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_DURATION    3.0
#define ZOMBIE_CLASS_SKILL_DISTANCE          60.0
#define ZOMBIE_CLASS_SKILL_HEALTH            200
#define ZOMBIE_CLASS_SKILL_RADIUS            400.0
#define ZOMBIE_CLASS_SKILL_KNOCKBACK         1000.0  
#define ZOMBIE_CLASS_SKILL_EXP_TIME          2.0
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define METAL_GIBS_AMOUNT                   5.0
#define METAL_GIBS_DELAY                    0.05
#define METAL_GIBS_SPEED                    500.0
#define METAL_GIBS_VARIENCE                 1.0  
#define METAL_GIBS_LIFE                     1.0  
#define METAL_GIBS_DURATION                 2.0
/**
 * @endsection
 **/

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Zombie index
int gZombie;
#pragma unused gZombie

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gZombie = ZP_GetClassNameID("stamper");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"stamper\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("COFFIN_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"COFFIN_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Models
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_GetClientClass(clientIndex) == gZombie)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3];

        // Gets weapon position
        ZP_GetPlayerGunPosition(clientIndex, ZOMBIE_CLASS_SKILL_DISTANCE, _, _, vPosition);
        GetClientEyeAngles(clientIndex, vAngle); vAngle[0] = vAngle[2] = 0.0; /// Only pitch
        
        // Initialize the hull intersection
        static const float vMins[3] = { -3.077446, -9.829969, -37.660713 }; 
        static const float vMaxs[3] = { 11.564661, 20.737569, 38.451633  }; 
        
        // Create the hull trace
        vPosition[2] += vMaxs[2] / 2; /// Move center of hull upward
        TR_TraceHull(vPosition, vPosition, vMins, vMaxs, MASK_SOLID);
        
        // Validate no collisions
        if(!TR_DidHit())
        {
            // Create a physics entity
            int entityIndex = UTIL_CreatePhysics("coffin", vPosition, vAngle, "models/player/custom_player/zombie/zombiepile/zombiepile.mdl", PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);

            // Validate entity
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Sets physics
                SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
                SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                
                // Sets owner to the entity
                SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex);

                #if ZOMBIE_CLASS_SKILL_HEALTH > 0
                // Sets health
                SetEntProp(entityIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
                SetEntProp(entityIndex, Prop_Data, "m_iHealth", ZOMBIE_CLASS_SKILL_HEALTH);
                SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", ZOMBIE_CLASS_SKILL_HEALTH);

                // Create damage hook
                SDKHook(entityIndex, SDKHook_OnTakeDamage, CoffinDamageHook);
                #endif
                
                // Play sound
                ZP_EmitSoundToAll(gSound, 1, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                
                // Create remove timer
                CreateTimer(ZP_GetClassSkillDuration(gZombie), CoffinExploadHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Coffin damage hook.
 *
 * @param entityIndex       The entity index.    
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action CoffinDamageHook(int entityIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &iBits)
{
    // Calculate the damage
    int iHealth = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

    // Destroy entity
    if(!iHealth)
    {
        // Destroy damage hook
        SDKUnhook(entityIndex, SDKHook_OnTakeDamage, CoffinDamageHook);

        // Expload it
        CoffinExpload(entityIndex);
    }
    else
    {
        // Play sound
        ZP_EmitSoundToAll(gSound, GetRandomInt(2, 3), entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
        // Apply damage
        SetEntProp(entityIndex, Prop_Data, "m_iHealth", iHealth);
    }

    // Return on success
    return Plugin_Handled;
}

/**
 * @brief Main timer for exploade coffin.
 * 
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.                    
 **/
public Action CoffinExploadHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Expload it
        CoffinExpload(entityIndex);
    }
}

/**
 * @brief Exploade coffin.
 * 
 * @param entityIndex       The entity index.                    
 **/
void CoffinExpload(int entityIndex)
{
    // Initialize vectors
    static float vEntPosition[3]; static float vVictimPosition[3]; static float vGibAngle[3]; float vShootAngle[3];

    // Gets entity position
    GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vEntPosition);

    // Find any players in the radius
    int i; int it = 1; /// iterator
    while((i = ZP_FindPlayerInSphere(it, vEntPosition, ZOMBIE_CLASS_SKILL_RADIUS)) != INVALID_ENT_REFERENCE)
    {
        // Gets victim origin
        GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vVictimPosition);

        // Create a knockback
        UTIL_CreatePhysForce(i, vEntPosition, vVictimPosition, GetVectorDistance(vEntPosition, vVictimPosition), ZOMBIE_CLASS_SKILL_KNOCKBACK, ZOMBIE_CLASS_SKILL_RADIUS);
        
        // Create a shake
        UTIL_CreateShakeScreen(i, ZOMBIE_CLASS_SKILL_SHAKE_AMP, ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY, ZOMBIE_CLASS_SKILL_SHAKE_DURATION);
    }
    
    // Create an explosion effect
    UTIL_CreateParticle(entityIndex, vEntPosition, _, _, "explosion_hegrenade_dirt", ZOMBIE_CLASS_SKILL_EXP_TIME);

    // Play sound
    ZP_EmitSoundToAll(gSound, 4, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    
    // Create a breaked metal effect
    static char sBuffer[NORMAL_LINE_LENGTH];
    for(int x = 0; x <= 4; x++)
    {
        // Find gib positions
        vShootAngle[1] += 72.0; vGibAngle[0] = GetRandomFloat(0.0, 360.0); vGibAngle[1] = GetRandomFloat(-15.0, 15.0); vGibAngle[2] = GetRandomFloat(-15.0, 15.0); switch(x)
        {
            case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib1.mdl");
            case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib2.mdl");
            case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib3.mdl");
            case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib4.mdl");
            case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib5.mdl");
        }
    
        // Create gibs
        UTIL_CreateShooter(entityIndex, "1", _, MAT_METAL, sBuffer, vShootAngle, vGibAngle, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
    }

    // Kill after some duration
    UTIL_RemoveEntity(entityIndex, 0.1);
}