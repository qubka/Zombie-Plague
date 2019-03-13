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
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Zombie Class: MutationHeavy",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_REWARD       10 // For each human
/**
 * @endsection
 **/

// Timer index
Handle Task_HumanTrapped[MAXPLAYERS+1] = null;  bool bStandOnTrap[MAXPLAYERS+1];

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Zombie index
int gZombie;
#pragma unused gZombie

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Load translations phrases used by plugin
        LoadTranslations("zombieplague.phrases");
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gZombie = ZP_GetClassNameID("mutationheavy");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"mutationheavy\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("TRAP_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"TRAP_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timer
        Task_HumanTrapped[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Delete timer
    delete Task_HumanTrapped[clientIndex];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientDeath(int clientIndex, int attackerIndex)
{
    // Delete timer
    delete Task_HumanTrapped[clientIndex];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientUpdated(int clientIndex, int attackerIndex)
{
    // Reset move
    SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    
    // Delete timer
    delete Task_HumanTrapped[clientIndex];
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
        // Validate place
        if(bStandOnTrap[clientIndex])
        {
            bStandOnTrap[clientIndex] = false; /// To avoid placing trap on the trap
            return Plugin_Handled;
        }
        
        // Show message
        SetGlobalTransTarget(clientIndex);
        PrintHintText(clientIndex, "%t", "mutationheavy set");
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientSkillOver(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_GetClientClass(clientIndex) == gZombie)
    {
        // Initialize vectors
        static float vPosition[3];
        
        // Gets client position
        GetClientAbsOrigin(clientIndex, vPosition);
        
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a trap entity
        int entityIndex = CreateEntityByName("prop_physics_multiplayer"); 

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValue(entityIndex, "model", "models/player/custom_player/zombie/ice/ice.mdl");
            DispatchKeyValue(entityIndex, "spawnflags", "8834"); /// Don't take physics damage | Not affected by rotor wash | Prevent pickup | Force server-side
            
            // Spawn the entity
            DispatchSpawn(entityIndex);
            
            // Teleport the trap
            TeleportEntity(entityIndex, vPosition, NULL_VECTOR, NULL_VECTOR);
            
            // Sets physics
            SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
            SetEntProp(entityIndex, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER); 
            SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
            SetEntityMoveType(entityIndex, MOVETYPE_NONE);

            // Create a prop_dynamic entity
            int trapIndex = CreateEntityByName("prop_dynamic");

            // Validate entity
            if(trapIndex != INVALID_ENT_REFERENCE)
            {
                // Dispatch main values of the entity
                DispatchKeyValue(trapIndex, "model", "models/player/custom_player/zombie/zombie_trap/trap.mdl");
                DispatchKeyValue(trapIndex, "DefaultAnim", "idle");
                DispatchKeyValue(trapIndex, "spawnflags", "256"); /// Start with collision disabled
                DispatchKeyValue(trapIndex, "solid", "0");
                
                // Spawn the entity
                DispatchSpawn(trapIndex);

                // Create transmit hook
                SDKHook(trapIndex, SDKHook_SetTransmit, TrapOnTransmit);

                // Spawn the fake trap
                TeleportEntity(trapIndex, vPosition, NULL_VECTOR, NULL_VECTOR);
            }
            
            // Sets parent for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
            SetEntPropEnt(entityIndex, Prop_Data, "m_hMoveChild", trapIndex);

            // Sets an entity color
            SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
            SetEntityRenderColor(entityIndex, _, _, _, 0); 

            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, TrapTouchHook);
        }
        
        // Show message
        SetGlobalTransTarget(clientIndex);
        PrintHintText(clientIndex, "%t", "mutationheavy success");
    }
}

/**
 * @brief Trap touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action TrapTouchHook(int entityIndex, int targetIndex)
{
    // Validate target
    if(IsPlayerExist(targetIndex))
    {
        // Validate human
        if(ZP_IsPlayerHuman(targetIndex) && GetEntityMoveType(targetIndex) != MOVETYPE_NONE)
        {
            // Initialize vectors
            static float vPosition[3];

            // Gets victim origin
            GetClientAbsOrigin(targetIndex, vPosition);
            
            // Trap the client
            SetEntityMoveType(targetIndex, MOVETYPE_NONE);

            // Create timer for removing freezing
            delete Task_HumanTrapped[targetIndex];
            Task_HumanTrapped[targetIndex] = CreateTimer(ZP_GetClassSkillDuration(gZombie), ClientRemoveTrapEffect, GetClientUserId(targetIndex), TIMER_FLAG_NO_MAPCHANGE);

            // Emit sound
            static char sSound[PLATFORM_LINE_LENGTH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
            EmitSoundToAll(sSound, targetIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);

            // Remove entity from world
            AcceptEntityInput(entityIndex, "Kill");

            // Show message
            SetGlobalTransTarget(targetIndex);
            PrintHintText(targetIndex, "%t", "mutationheavy catch");
            
            // Gets owner index
            int ownerIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent");

            // Validate owner
            if(IsPlayerExist(ownerIndex))
            {
                // Gets target name
                static char sName[NORMAL_LINE_LENGTH];
                GetClientName(targetIndex, sName, sizeof(sName));
        
                // Show message
                SetGlobalTransTarget(ownerIndex);
                PrintHintText(ownerIndex, "%t", "mutationheavy catched", sName);
                
                // Give reward
                ZP_SetClientMoney(ownerIndex, ZP_GetClientMoney(ownerIndex) + ZOMBIE_CLASS_SKILL_REWARD);
            }

            // Create a prop_dynamic entity
            int trapIndex = CreateEntityByName("prop_dynamic");

            // Validate entity
            if(trapIndex != INVALID_ENT_REFERENCE)
            {
                // Dispatch main values of the entity
                DispatchKeyValue(trapIndex, "model", "models/player/custom_player/zombie/zombie_trap/trap.mdl");
                DispatchKeyValue(trapIndex, "DefaultAnim", "trap");
                DispatchKeyValue(trapIndex, "spawnflags", "256"); /// Start with collision disabled
                DispatchKeyValue(trapIndex, "solid", "0");

                // Spawn the entity
                DispatchSpawn(trapIndex);
                TeleportEntity(trapIndex, vPosition, NULL_VECTOR, NULL_VECTOR);

                // Initialize time char
                static char sTime[SMALL_LINE_LENGTH];
                FormatEx(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", ZP_GetClassSkillDuration(gZombie));

                // Sets modified flags on entity
                SetVariantString(sTime);
                AcceptEntityInput(trapIndex, "AddOutput");
                AcceptEntityInput(trapIndex, "FireUser1");
            }
        }
        //Validate zombie
        else if(ZP_IsPlayerZombie(targetIndex)) bStandOnTrap[targetIndex] = true; // Reset installing here!
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public Action TrapOnTransmit(int entityIndex, int clientIndex)
{
    // Validate human
    if(ZP_IsPlayerHuman(clientIndex))
    {
        // Block transmitting
        return Plugin_Handled;
    }

    // Allow transmitting
    return Plugin_Continue;
}

/**
 * @brief Timer for remove trap effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveTrapEffect(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Clear timer 
    Task_HumanTrapped[clientIndex] = null;

    // Validate client
    if(clientIndex)
    {    
        // Untrap the client
        SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    }

    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param clientIndex       The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID)
{
    // Validate the zombie class index
    if(ZP_GetClientClass(clientIndex) == gZombie && ZP_GetClientSkillUsage(clientIndex))
    {
        // Initialize vector
        static float vVelocity[3];
        
        // Gets client velocity
        GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

        // If the zombie move, then reset skill
        if((SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
        {
            // Reset skill
            ZP_ResetClientSkill(clientIndex);
            
            // Show message
            SetGlobalTransTarget(clientIndex);
            PrintHintText(clientIndex, "%t", "mutationheavy cancel");
        }
    }
    
    // Allow button
    return Plugin_Continue;
}