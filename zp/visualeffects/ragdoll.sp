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
void RagdollOnCvarInit()
{
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
	bool bRagDollRemove = gCvarList.VEFFECTS_RAGDOLL_REMOVE.BoolValue;

	if (!bRagDollRemove)
	{
		return;
	}

	int ragdoll = RagdollGetIndex(client);

	if (ragdoll == -1)
	{
		return;
	}

	float flDissolveDelay = gCvarList.VEFFECTS_RAGDOLL_DELAY.FloatValue;
	if (!flDissolveDelay)
	{
		RagdollOnEntityRemove(null, EntIndexToEntRef(ragdoll));
		return;
	}

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
	int ragdoll = EntRefToEntIndex(refID);

	if (ragdoll != -1)
	{
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(ragdoll, sClassname, sizeof(sClassname));

		if (!strcmp(sClassname, "cs_ragdoll", false))
		{
			int iEffect = gCvarList.VEFFECTS_RAGDOLL_DISSOLVE.IntValue;

			if (iEffect == VEFFECTS_RAGDOLL_DISSOLVE_EFFECTLESS)
			{
				AcceptEntityInput(ragdoll, "Kill");
				return Plugin_Stop;
			}

			if (iEffect == VEFFECTS_RAGDOLL_DISSOLVE_RANDOM)
			{
				iEffect = GetRandomInt(VEFFECTS_RAGDOLL_DISSOLVE_ENERGY, VEFFECTS_RAGDOLL_DISSOLVE_CORE);
			}

			static char sDissolve[SMALL_LINE_LENGTH];
			FormatEx(sDissolve, sizeof(sDissolve), "dissolve%d", ragdoll);
			DispatchKeyValue(ragdoll, "targetname", sDissolve);

			int iDissolver = CreateEntityByName("env_entity_dissolver");
			
			if (iDissolver != -1)
			{
				DispatchKeyValue(iDissolver, "target", sDissolve);

				FormatEx(sDissolve, sizeof(sDissolve), "%d", iEffect);
				DispatchKeyValue(iDissolver, "dissolvetype", sDissolve);

				AcceptEntityInput(iDissolver, "Dissolve");

				AcceptEntityInput(iDissolver, "Kill");
			}
		}
	}
	
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
