/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          ragdoll.sp
 *  Type:          Module
 *  Description:   Remove ragdolls with optional effects.
 *
 *  Copyright (C) 2015-2023 Greyscale, Richard Helgeby
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
 * @brief Hook ragdoll cvar changes.
 **/
void RagdollOnCvarInit(/*void*/)
{
	// Create cvars
	gCvarList.VEFFECTS_RAGDOLL_REMOVE   = FindConVar("zp_veffects_ragdoll_remove");
	gCvarList.VEFFECTS_RAGDOLL_DISSOLVE = FindConVar("zp_veffects_ragdoll_dissolve");
	gCvarList.VEFFECTS_RAGDOLL_DELAY    = FindConVar("zp_veffects_ragdoll_delay");
}
 
/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void RagdollOnClientDeath(int client)
{
	// If true, the stop
	bool bRagDollRemove = gCvarList.VEFFECTS_RAGDOLL_REMOVE.BoolValue;

	// If ragdoll removal is disabled, then stop
	if (!bRagDollRemove)
	{
		return;
	}

	// Gets ragdoll index
	int ragdoll = RagdollGetIndex(client);

	// If the ragdoll is invalid, then stop
	if (ragdoll == -1)
	{
		return;
	}

	// If the delay is zero, then remove right now
	float flDissolveDelay = gCvarList.VEFFECTS_RAGDOLL_DELAY.FloatValue;
	if (!flDissolveDelay)
	{
		RagdollOnEntityRemove(null, EntIndexToEntRef(ragdoll));
		return;
	}

	// Create a timer to remove/dissolve ragdoll
	CreateTimer(flDissolveDelay, RagdollOnEntityRemove, EntIndexToEntRef(ragdoll), TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief Timer callback, removed a client ragdoll.
 * 
 * @param hTimer            The timer handle. 
 * @param refID             The reference index.
 **/
public Action RagdollOnEntityRemove(Handle hTimer, int refID)
{
	// Gets ragdoll index from the reference
	int ragdoll = EntRefToEntIndex(refID);

	// If the ragdoll is already gone, then stop
	if (ragdoll != -1)
	{
		// Make sure this edict is still a ragdoll and not become a new valid entity
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(ragdoll, sClassname, sizeof(sClassname));

		// Validate classname
		if (!strcmp(sClassname, "cs_ragdoll", false))
		{
			// Gets dissolve type
			int iEffect = gCvarList.VEFFECTS_RAGDOLL_DISSOLVE.IntValue;

			// Check the dissolve type
			if (iEffect == VEFFECTS_RAGDOLL_DISSOLVE_EFFECTLESS)
			{
				// Remove entity from world
				AcceptEntityInput(ragdoll, "Kill");
				return Plugin_Stop;
			}

			// If random, set value to any between "energy" effect and "core" effect
			if (iEffect == VEFFECTS_RAGDOLL_DISSOLVE_RANDOM)
			{
				iEffect = GetRandomInt(VEFFECTS_RAGDOLL_DISSOLVE_ENERGY, VEFFECTS_RAGDOLL_DISSOLVE_CORE);
			}

			// Prep the ragdoll for dissolving
			static char sTarget[SMALL_LINE_LENGTH];
			FormatEx(sTarget, sizeof(sTarget), "dissolve%d", ragdoll);
			DispatchKeyValue(ragdoll, "targetname", sTarget);

			// Prep the dissolve entity
			int iDissolver = CreateEntityByName("env_entity_dissolver");
			
			// If dissolve entity isn't valid, then stop
			if (iDissolver != -1)
			{
				// Sets target to the ragdoll
				DispatchKeyValue(iDissolver, "target", sTarget);

				// Sets dissolve type
				static char sDissolveType[SMALL_LINE_LENGTH];
				FormatEx(sDissolveType, sizeof(sDissolveType), "%d", iEffect);
				DispatchKeyValue(iDissolver, "dissolvetype", sDissolveType);

				// Tell the entity to dissolve the ragdoll
				AcceptEntityInput(iDissolver, "Dissolve");

				// Remove the dissolver
				AcceptEntityInput(iDissolver, "Kill");
			}
		}
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Gets the ragdoll index on a client.
 *
 * @param client            The client index.
 * @return                  The ragdoll index.
 **/
int RagdollGetIndex(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
}
