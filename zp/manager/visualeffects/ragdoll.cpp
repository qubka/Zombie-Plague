/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          ragdoll.cpp
 *  Type:          Module
 *  Description:   Remove ragdolls with optional effects.
 *
 *  Copyright (C) 2015-2018  Greyscale, Richard Helgeby
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
 * @section Different dissolve types.
 **/
#define VEFFECTS_RAGDOLL_DISSOLVE_EFFECTLESS    -2
#define VEFFECTS_RAGDOLL_DISSOLVE_RANDOM        -1
#define VEFFECTS_RAGDOLL_DISSOLVE_ENERGY        0
#define VEFFECTS_RAGDOLL_DISSOLVE_ELECTRICALH   1
#define VEFFECTS_RAGDOLL_DISSOLVE_ELECTRICALL   2
#define VEFFECTS_RAGDOLL_DISSOLVE_CORE          3
/**
 * @endsection
 **/

/**
 * Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void RagdollOnClientDeath(int clientIndex)
{
    // If true, the stop
    bool iRagDollRemove = gCvarList[CVAR_VEFFECTS_RAGDOLL_REMOVE].BoolValue;

    // If ragdoll removal is disabled, then stop
    if(!iRagDollRemove)
    {
        return;
    }

    // Gets the ragdoll index
    int iRagdoll = GetEntDataEnt2(clientIndex, g_iOffset_PlayerRagdool);

    // If the ragdoll is invalid, then stop
    if(iRagdoll == INVALID_ENT_REFERENCE)
    {
        return;
    }

    // If the delay is zero, then remove right now
    float flDissolveDelay = gCvarList[CVAR_VEFFECTS_RAGDOLL_DELAY].FloatValue;
    if(!flDissolveDelay)
    {
        RagdollTimer(INVALID_HANDLE, iRagdoll);
        return;
    }

    // Create a timer to remove/dissolve ragdoll
    CreateTimer(flDissolveDelay, RagdollTimer, EntIndexToEntRef(iRagdoll), TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Removed a ragdoll from the game following plugin settings.
 * 
 * @param iRagdoll          The ragdoll index.
 **/
void RagdollRemove(int iRagdoll)
{
    // Gets the dissolve type
    int iRagDollType = gCvarList[CVAR_VEFFECTS_RAGDOLL_DISSOLVE].IntValue;

    // Check the dissolve type
    if(iRagDollType == VEFFECTS_RAGDOLL_DISSOLVE_EFFECTLESS)
    {
        // Remove entity from world
        AcceptEntityInput(iRagdoll, "Kill");
        return;
    }

    // If random, set value to any between "energy" effect and "core" effect
    if(iRagDollType == VEFFECTS_RAGDOLL_DISSOLVE_RANDOM)
    {
        iRagDollType = GetRandomInt(VEFFECTS_RAGDOLL_DISSOLVE_ENERGY, VEFFECTS_RAGDOLL_DISSOLVE_CORE);
    }

    // Prep the ragdoll for dissolving
    static char sTarget[SMALL_LINE_LENGTH];
    Format(sTarget, sizeof(sTarget), "zp_dissolve_%d", iRagdoll);
    DispatchKeyValue(iRagdoll, "targetname", sTarget);

    // Prep the dissolve entity
    int iDissolver = CreateEntityByName("env_entity_dissolver");
    
    // If dissolve entity isn't valid, then stop
    if(iDissolver != INVALID_ENT_REFERENCE)
    {
        // Sets the target to the ragdoll
        DispatchKeyValue(iDissolver, "target", sTarget);

        // Sets the dissolve type
        static char sDissolveType[SMALL_LINE_LENGTH];
        Format(sDissolveType, sizeof(sDissolveType), "%d", iRagDollType);
        DispatchKeyValue(iDissolver, "dissolvetype", sDissolveType);

        // Tell the entity to dissolve the ragdoll
        AcceptEntityInput(iDissolver, "Dissolve");

        // Remove the dissolver
        AcceptEntityInput(iDissolver, "Kill");
    }
}

/**
 * Timer callback.  Removed a client's ragdoll.
 * 
 * @param hTimer            The timer handle. 
 * @param referenceIndex    The reference index.
 **/
public Action RagdollTimer(Handle hTimer, int referenceIndex)
{
    // If ragdoll removal is disabled, then stop
    if(!gCvarList[CVAR_VEFFECTS_RAGDOLL_REMOVE].BoolValue)
    {
        return;
    }

    // Get the ragdoll index from the reference
    int iRagdoll = EntRefToEntIndex(referenceIndex);

    // If the ragdoll is already gone, then stop
    if(iRagdoll == INVALID_ENT_REFERENCE)
    {
        return;
    }

    // Make sure this edict is still a ragdoll and not become a new valid entity
    static char sClassname[SMALL_LINE_LENGTH];
    GetEdictClassname(iRagdoll, sClassname, sizeof(sClassname));

    // Validate classname
    if(!strcmp(sClassname, "cs_ragdoll", false))
    {
        // Remove the ragdoll
        RagdollRemove(iRagdoll);
    }
}
