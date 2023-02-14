/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          particles.sp
 *  Type:          Module
 *  Description:   Particles dictionary & manager.
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

/*
 * Stocks particles API.
 */ 

/**
 * @brief Create an attached particle entity.
 * 
 * @param parent            The parent index.
 * @param sAttach           The attachment name.
 * @param sEffect           The particle name.
 * @param flDurationTime    The duration of an effect.
 * @return                  The entity index.
 **/
int ParticlesCreate(int parent, char[] sAttach, char[] sEffect, float flDurationTime)
{
	if (!hasLength(sEffect) || (hasLength(sAttach) && !LookupEntityAttachment(parent, sAttach)))
	{
		return -1;
	}
	
	static float vPosition[3]; static float vAngle[3]; 
	
	if (!hasLength(sAttach))
	{ 
		ToolsGetAbsOrigin(parent, vPosition);
		ToolsGetAbsAngles(parent, vAngle);
	}

	return UTIL_CreateParticle(parent, vPosition, vAngle, sAttach, sEffect, flDurationTime);
}

/**
 * @brief Delete an attached particle from the entity.
 * 
 * @param client            The client index.
 **/
void ParticlesRemove(int client)
{
	static char sClassname[SMALL_LINE_LENGTH];

	int MaxEntities = GetMaxEntities();
	for (int i = MaxClients; i <= MaxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, sClassname, sizeof(sClassname));

			if (sClassname[0] == 'i' && sClassname[5] == 'p' && sClassname[6] == 'a') // info_particle_system
			{
				if (ToolsGetOwner(i) == client)
				{
					AcceptEntityInput(i, "Kill"); /// Destroy
				}
			}
		}
	}
}

/**
 * @brief Stops a particle effect on the entity. (client side)
 * 
 * @param client            The client index.
 * @param entity            The entity index.
 **/
void ParticlesStop(int client, int entity)
{
	static int effect = INVALID_STRING_INDEX;

	if (effect == INVALID_STRING_INDEX && (effect = GetEffectIndex("ParticleEffectStop")) == INVALID_STRING_INDEX)
	{
		return;
	}

	TE_Start("EffectDispatch");
	TE_WriteNum("entindex", entity);
	TE_WriteNum("m_iEffectName", effect);
	TE_SendToClient(client);
}