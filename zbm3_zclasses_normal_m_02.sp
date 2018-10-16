/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Zombie Class: NormalM02",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "normalm02" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "normalm02 info" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/normal_m_02/normal_m_02.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/normal_m_02/hand_v2/hand_zombie_normal_m_02.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/normal_m_02/grenade/grenade_normal_m_02.mdl"    
#define ZOMBIE_CLASS_HEALTH             5500
#define ZOMBIE_CLASS_SPEED              1.0
#define ZOMBIE_CLASS_GRAVITY            0.9
#define ZOMBIE_CLASS_KNOCKBACK          0.9
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_GROUP              ""
#define ZOMBIE_CLASS_DURATION           10.0    
#define ZOMBIE_CLASS_COUNTDOWN          15.0
#define ZOMBIE_CLASS_REGEN_HEALTH       300
#define ZOMBIE_CLASS_REGEN_INTERVAL     5.0
#define ZOMBIE_CLASS_SKILL_DISTANCE     60.0
#define ZOMBIE_CLASS_SKILL_HEALTH       200
#define ZOMBIE_CLASS_SKILL_EXP_TIME     0.1
#define ZOMBIE_CLASS_SKILL_RADIUS       400.0
#define ZOMBIE_CLASS_SKILL_POWER        1000.0         
#define ZOMBIE_CLASS_SKILL_SURVIVOR     true          
#define ZOMBIE_CLASS_SKILL_NEMESIS      true   
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_REGEN_SOUNDS" 
#define ZOMBIE_CLASS_EFFECT_SHAKE_AMP         2.0           
#define ZOMBIE_CLASS_EFFECT_SHAKE_FREQUENCY   1.0           
#define ZOMBIE_CLASS_EFFECT_SHAKE_DURATION    3.0
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
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary) // Stamper
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initialize zombie class
        gZombie = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
        ZOMBIE_CLASS_INFO,
        ZOMBIE_CLASS_MODEL, 
        ZOMBIE_CLASS_CLAW,  
        ZOMBIE_CLASS_GRENADE,
        ZOMBIE_CLASS_HEALTH, 
        ZOMBIE_CLASS_SPEED, 
        ZOMBIE_CLASS_GRAVITY, 
        ZOMBIE_CLASS_KNOCKBACK, 
        ZOMBIE_CLASS_LEVEL,
        ZOMBIE_CLASS_GROUP, 
        ZOMBIE_CLASS_DURATION, 
        ZOMBIE_CLASS_COUNTDOWN, 
        ZOMBIE_CLASS_REGEN_HEALTH, 
        ZOMBIE_CLASS_REGEN_INTERVAL,
        ZOMBIE_CLASS_SOUND_DEATH,
        ZOMBIE_CLASS_SOUND_HURT,
        ZOMBIE_CLASS_SOUND_IDLE,
        ZOMBIE_CLASS_SOUND_RESPAWN,
        ZOMBIE_CLASS_SOUND_BURN,
        ZOMBIE_CLASS_SOUND_ATTACK,
        ZOMBIE_CLASS_SOUND_FOOTSTEP,
        ZOMBIE_CLASS_SOUND_REGEN);
    }
}

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Sounds
    gSound = ZP_GetSoundKeyID("COFFIN_SKILL_SOUNDS");
    
    // Models
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

/**
 * Called when a client use a skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_IsPlayerZombie(clientIndex) && ZP_GetClientZombieClass(clientIndex) == gZombie)
    {
        // Initialize vectors
        static float vFromPosition[3];

        // Gets the weapon position
        ZP_GetPlayerGunPosition(clientIndex, ZOMBIE_CLASS_SKILL_DISTANCE, _, _, vFromPosition);

        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a trap entity
        int entityIndex = CreateEntityByName("prop_physics_multiplayer"); 

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValue(entityIndex, "model", "models/player/custom_player/zombie/zombiepile/zombiepile.mdl");
            DispatchKeyValue(entityIndex, "spawnflags", "8832"); /// Not affected by rotor wash | Prevent pickup | Force server-side

            // Spawn the entity
            DispatchSpawn(entityIndex);

            // Teleport the coffin
            TeleportEntity(entityIndex, vFromPosition, NULL_VECTOR, NULL_VECTOR);

            // Sets the physics
            SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
            SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
            
            // Sets owner to the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex);

            // Sets the health
            SetEntProp(entityIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
            SetEntProp(entityIndex, Prop_Data, "m_iHealth", ZOMBIE_CLASS_SKILL_HEALTH);
            SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", ZOMBIE_CLASS_SKILL_HEALTH);

            // Create damage/touch hook
            SDKHook(entityIndex, SDKHook_Touch, CoffinTouchHook);
            SDKHook(entityIndex, SDKHook_OnTakeDamage, CoffinDamageHook);
            
            // Create remove timer
            CreateTimer(ZOMBIE_CLASS_DURATION, CoffinExploadHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * Coffin touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action CoffinTouchHook(int entityIndex, int targetIndex)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Validate target
        if(IsPlayerExist(targetIndex))
        {
            // Expload with other player coliding
            if(GetEntPropEnt(entityIndex, Prop_Data, "m_pParent") != targetIndex)
            {
                // Destroy touch hook
                SDKUnhook(entityIndex, SDKHook_Touch, CoffinTouchHook);
        
                // Expload it
                CoffinExpload(entityIndex);
            }
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * Coffin damage hook.
 *
 * @param entityIndex       The entity index.    
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damageAmount      The damage amount.
 * @param damageType        The damage type.
 **/
public Action CoffinDamageHook(const int entityIndex, int &attackerIndex, int &inflictorIndex, float &damageAmount, int &damageType)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Calculate the damage
        int healthAmount = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToCeil(damageAmount); healthAmount = (healthAmount > 0) ? healthAmount : 0;

        // Destroy entity
        if(!healthAmount)
        {
            // Destroy damage hook
            SDKUnhook(entityIndex, SDKHook_OnTakeDamage, CoffinDamageHook);
    
            // Expload it
            CoffinExpload(entityIndex);
        }
        else
        {
            // Emit sound
            static char sSound[PLATFORM_MAX_PATH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), GetRandomInt(2, 3));
            EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            
            // Apply damage
            SetEntProp(entityIndex, Prop_Data, "m_iHealth", healthAmount);
        }
    }

    // Return on success
    return Plugin_Handled;
}

/**
 * Main timer for exploade coffin.
 * 
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.                    
 **/
public Action CoffinExploadHook(Handle hTimer, const int referenceIndex)
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
 * Exploade coffin.
 * 
 * @param entityIndex       The entity index.                    
 **/
void CoffinExpload(const int entityIndex)
{
    // Initialize vectors
    static float vEntPosition[3]; static float vEntAngle[3]; static float vVictimPosition[3]; static float vVelocity[3]; static float vAngle[3];

    // Gets the entity position
    GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i) && ((ZP_IsPlayerZombie(i) && !ZP_IsPlayerNemesis(i)) || (ZP_IsPlayerNemesis(i) && ZOMBIE_CLASS_SKILL_NEMESIS) || (ZP_IsPlayerHuman(i) && !ZP_IsPlayerSurvivor(i)) || (ZP_IsPlayerSurvivor(i) && ZOMBIE_CLASS_SKILL_SURVIVOR)))
        {
            // Gets victim origin
            GetClientAbsOrigin(i, vVictimPosition);
            
            // Calculate the distance
            float flDistance = GetVectorDistance(vEntPosition, vVictimPosition);
            
            // Validate distance
            if(flDistance <= ZOMBIE_CLASS_SKILL_RADIUS)
            {                
                // Calculate the velocity vector
                SubtractVectors(vVictimPosition, vEntPosition, vVelocity);
                
                // Create a knockback
                FakeCreateKnockBack(i, vVelocity, flDistance, ZOMBIE_CLASS_SKILL_POWER, ZOMBIE_CLASS_SKILL_RADIUS);
                
                // Create a shake
                FakeCreateShakeScreen(i, ZOMBIE_CLASS_EFFECT_SHAKE_AMP, ZOMBIE_CLASS_EFFECT_SHAKE_FREQUENCY, ZOMBIE_CLASS_EFFECT_SHAKE_DURATION);
            }
        }
    }
    
    // Create an explosion effect
    FakeCreateParticle(entityIndex, vEntPosition, _, "explosion_hegrenade_dirt", ZOMBIE_CLASS_SKILL_EXP_TIME);

    // Emit sound
    static char sSound[PLATFORM_MAX_PATH];
    ZP_GetSound(gSound, sSound, sizeof(sSound), 4);
    EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    
    // Create a breaked glass effect
    static char sModel[NORMAL_LINE_LENGTH];
    for(int x = 0; x <= 4; x++)
    {
        // Find gib positions
        vAngle[1] += 72.0; vEntAngle[0] = GetRandomFloat(0.0, 360.0); vEntAngle[1] = GetRandomFloat(-15.0, 15.0); vEntAngle[2] = GetRandomFloat(-15.0, 15.0); switch(x)
        {
            case 0 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib1.mdl");
            case 1 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib2.mdl");
            case 2 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib3.mdl");
            case 3 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib4.mdl");
            case 4 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib5.mdl");
        }
    
        // Create a shooter entity
        int gibIndex = CreateEntityByName("env_shooter");

        // If entity isn't valid, then skip
        if(gibIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValueVector(gibIndex, "angles", vAngle);
            DispatchKeyValueVector(gibIndex, "gibangles", vEntAngle);
            DispatchKeyValue(gibIndex, "rendermode", "5");
            DispatchKeyValue(gibIndex, "shootsounds", "2");
            DispatchKeyValue(gibIndex, "shootmodel", sModel);
            DispatchKeyValueFloat(gibIndex, "m_iGibs", METAL_GIBS_AMOUNT);
            DispatchKeyValueFloat(gibIndex, "delay", METAL_GIBS_DELAY);
            DispatchKeyValueFloat(gibIndex, "m_flVelocity", METAL_GIBS_SPEED);
            DispatchKeyValueFloat(gibIndex, "m_flVariance", METAL_GIBS_VARIENCE);
            DispatchKeyValueFloat(gibIndex, "m_flGibLife", METAL_GIBS_LIFE);

            // Spawn the entity into the world
            DispatchSpawn(gibIndex);

            // Activate the entity
            ActivateEntity(gibIndex);  
            AcceptEntityInput(gibIndex, "Shoot");

            // Sets parent to the client
            SetVariantString("!activator"); 
            AcceptEntityInput(gibIndex, "SetParent", entityIndex, gibIndex); 

            // Sets attachment to the client
            SetVariantString("1"); /// Attachment name in the coffin model
            AcceptEntityInput(gibIndex, "SetParentAttachment", entityIndex, gibIndex);

            // Initialize variable
            static char sTime[SMALL_LINE_LENGTH];
            Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", METAL_GIBS_DURATION);

            // Sets modified flags on the entity
            SetVariantString(sTime);
            AcceptEntityInput(gibIndex, "AddOutput");
            AcceptEntityInput(gibIndex, "FireUser1");
        }
    }

    // Initialize variable
    static char sTime[SMALL_LINE_LENGTH];
    Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", ZOMBIE_CLASS_SKILL_EXP_TIME);

    // Sets modified flags on the entity
    SetVariantString(sTime);
    AcceptEntityInput(entityIndex, "AddOutput");
    AcceptEntityInput(entityIndex, "FireUser1");
}