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
public Plugin ZombieClassNormalM10 =
{
    name            = "[ZP] Zombie Class: NormalM10",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "NormalM10" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "NormalM10Info" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/normal_m_10/normal_m_10.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/normal_m_10/hand_v2/hand_zombie_normal_m_10.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/normal_m_10/grenade/grenade_normal_m_10.mdl"    
#define ZOMBIE_CLASS_HEALTH             5500
#define ZOMBIE_CLASS_SPEED              1.0
#define ZOMBIE_CLASS_GRAVITY            0.9
#define ZOMBIE_CLASS_KNOCKBACK          1.0
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_VIP                NO
#define ZOMBIE_CLASS_DURATION           2.0    
#define ZOMBIE_CLASS_COUNTDOWN          30.0
#define ZOMBIE_CLASS_REGEN_HEALTH       300
#define ZOMBIE_CLASS_REGEN_INTERVAL     6.0
#define ZOMBIE_CLASS_SKILL_SPEED        2000.0
#define ZOMBIE_CLASS_SKILL_GRAVITY      0.01
#define ZOMBIE_CLASS_SKILL_SIZE         0.3
#define ZOMBIE_CLASS_SKILL_ELASTICITY   10.0
#define ZOMBIE_CLASS_SKILL_DISSOLVE     40  // Amount of energy which ball lose to dissolve
#define ZOMBIE_CLASS_SKILL_DURATION     3.0 
#define ZOMBIE_CLASS_SKILL_EXP_RADIUS   22500.0 //[squared]
#define ZOMBIE_CLASS_SKILL_EXP_DAMAGE   50.0
#define ZOMBIE_CLASS_SKILL_EXP_SURVIVOR false  // Can survivor blasted [false-no // true-yes]
#define ZOMBIE_CLASS_SKILL_EXP_TIME     2.0
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_REGEN_SOUNDS"
#define ZOMBIE_CLASS_EFFECT_COLOR_F         {186, 85, 211, 75}
#define ZOMBIE_CLASS_EFFECT_DURATION_F      2.3
#define ZOMBIE_CLASS_EFFECT_TIME_F          3.0      
#define ZOMBIE_CLASS_EFFECT_SHAKE_FREQUENCY 1.0           
#define ZOMBIE_CLASS_EFFECT_SHAKE_DURATION  3.0           
#define ZOMBIE_CLASS_EFFECT_SHAKE_AMP       2.0   
/**
 * @endsection
 **/

// Initialize variables
Handle Task_HumanBlasted[MAXPLAYERS+1] = INVALID_HANDLE;
 
// ConVar for sound level
ConVar hSoundLevel;
 
// Initialize zombie class index
int gZombieNormalM10;
#pragma unused gZombieNormalM10

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary) // Paralizing blast
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initilizate zombie class
        gZombieNormalM10 = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
        ZOMBIE_CLASS_INFO,
        ZOMBIE_CLASS_MODEL, 
        ZOMBIE_CLASS_CLAW,  
        ZOMBIE_CLASS_GRENADE,
        ZOMBIE_CLASS_HEALTH, 
        ZOMBIE_CLASS_SPEED, 
        ZOMBIE_CLASS_GRAVITY, 
        ZOMBIE_CLASS_KNOCKBACK, 
        ZOMBIE_CLASS_LEVEL,
        ZOMBIE_CLASS_VIP, 
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
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

/**
 * The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timer
        Task_HumanBlasted[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Delete timer
    delete Task_HumanBlasted[clientIndex];
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
    // Reset move
    SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    
    // Delete timer
    delete Task_HumanBlasted[clientIndex];
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientHumanized(int clientIndex)
{
    // Reset move
    SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    
    // Delete timer
    delete Task_HumanBlasted[clientIndex];
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex        The client index.
 *
 * @return                   Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Handled;
    }
    
    // Validate the zombie class index
    if(ZP_GetClientZombieClass(clientIndex) == gZombieNormalM10)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEntVelocity[3];
        
        // Gets the client's eye position
        GetClientEyePosition(clientIndex, vPosition);
        
        // Gets the client's eye angle
        GetClientEyeAngles(clientIndex, vAngle);

        // Gets the client's speed
        GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);
        
        // Emit sound
        EmitSoundToAll("*/zbm3/electro4.mp3", clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a blast entity
        int entityIndex = CreateEntityByName("hegrenade_projectile");
        
        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Spawn the entity
            DispatchSpawn(entityIndex);
            
            // Sets the model
            SetEntityModel(entityIndex, "models/weapons/eminem/aura_shield/aura_shield2.mdl");
            
            // Sets the blast's model scale
            SetEntPropFloat(entityIndex, Prop_Send, "m_flModelScale", ZOMBIE_CLASS_SKILL_SIZE);
            
            // Returns vectors in the direction of an angle
            GetAngleVectors(vAngle, vEntVelocity, NULL_VECTOR, NULL_VECTOR);
            
            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vEntVelocity, vEntVelocity);
            
            // Apply the magnitude by scaling the vector
            ScaleVector(vEntVelocity, ZOMBIE_CLASS_SKILL_SPEED);

            // Adds two vectors
            AddVectors(vEntVelocity, vVelocity, vEntVelocity);

            // Push the blast
            TeleportEntity(entityIndex, vPosition, vAngle, vEntVelocity);

            // Sets the parent for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);
            
            // Sets the gravity
            SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY);
            SetEntPropFloat(entityIndex, Prop_Send, "m_flElasticity", ZOMBIE_CLASS_SKILL_ELASTICITY);
            
            // Emit sound
            EmitSoundToAll("*/zbm3/gauss2.mp3", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            
            // Create an effect
            FakeCreateParticle(entityIndex, _, "gamma_blue", ZOMBIE_CLASS_DURATION);
            
            // Put fire on it
            IgniteEntity(entityIndex, ZOMBIE_CLASS_DURATION);

            // Set blue render color
            SetEntityRenderMode(entityIndex, RENDER_TRANSCOLOR);
            SetEntityRenderColor(entityIndex, 186, 85, 211, 255);

            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, BlastTouchHook);
            
            // Create remove timer
            CreateTimer(ZOMBIE_CLASS_DURATION, BlastExploadHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * Blast touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action BlastTouchHook(int entityIndex, int targetIndex)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Emit sound
        EmitSoundToAll(GetRandomInt(0, 1) ? "*/zbm3/ric_conc-1.mp3" : "*/zbm3/ric_conc-2.mp3", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * Main timer for exploade blast.
 * 
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.                    
 **/
public Action BlastExploadHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vEntPosition[3]; static float vVictimPosition[3];

        // Gets the entity's position
        GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

        // Create a info_target entity
        int infoIndex = FakeCreateEntity(vEntPosition, ZOMBIE_CLASS_SKILL_EXP_TIME);

        // Validate entity
        if(IsValidEdict(infoIndex))
        {
            // Create an explosion effect
            FakeCreateParticle(infoIndex, _, "explosion_molotov_air", ZOMBIE_CLASS_SKILL_EXP_TIME);
            
            // Emit sound
            EmitSoundToAll("*/zbm3/td_stun_exp.mp3", infoIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        }
        
        // Gets the blast's owner
        int ownerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hThrower");
        
        // Validate owner
        if(IsPlayerExist(ownerIndex))
        {
            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate client
                if(IsPlayerExist(i) && ((ZP_IsPlayerHuman(i) && !ZP_IsPlayerSurvivor(i)) || (ZP_IsPlayerSurvivor(i) && ZOMBIE_CLASS_SKILL_EXP_SURVIVOR)))
                {
                    // Gets victim's origin
                    GetClientAbsOrigin(i, vVictimPosition);

                    // Calculate the distance
                    float flDistance = GetVectorDistance(vEntPosition, vVictimPosition, true);

                    // Validate distance
                    if(flDistance <= ZOMBIE_CLASS_SKILL_EXP_RADIUS)
                    {
                        // Blaat the client
                        SetEntityMoveType(i, MOVETYPE_NONE);

                        // Create the damage for a victim
                        SDKHooks_TakeDamage(i, ownerIndex, ownerIndex, ZOMBIE_CLASS_SKILL_EXP_DAMAGE);

                        // Create an fade
                        FakeCreateFadeScreen(i, ZOMBIE_CLASS_EFFECT_DURATION_F, ZOMBIE_CLASS_EFFECT_TIME_F, 0x0001, ZOMBIE_CLASS_EFFECT_COLOR_F);
                        
                        // Create a shake
                        FakeCreateShakeScreen(i, ZOMBIE_CLASS_EFFECT_SHAKE_AMP, ZOMBIE_CLASS_EFFECT_SHAKE_FREQUENCY, ZOMBIE_CLASS_EFFECT_SHAKE_DURATION);
                        
                        // Create timer for removing freezing
                        delete Task_HumanBlasted[i];
                        Task_HumanBlasted[i] = CreateTimer(ZOMBIE_CLASS_SKILL_DURATION, ClientRemoveBlastEffect, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
                    }
                }
            }
        }

        // Remove entity from the world
        AcceptEntityInput(entityIndex, "Kill");
    }
}

/**
 * Timer for remove blast effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveBlastEffect(Handle hTimer, int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Clear timer 
    Task_HumanBlasted[clientIndex] = INVALID_HANDLE;

    // Validate client
    if(clientIndex)
    {    
        // Untrap the client
        SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    }

    // Destroy timer
    return Plugin_Stop;
}
