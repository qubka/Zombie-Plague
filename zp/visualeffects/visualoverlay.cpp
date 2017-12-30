/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          visualoverlay.cpp
 *  Type:          Module
 *  Description:   Show overlays with optional effects.
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
 */

/**
 * All possible overlay channels, in order of priority.
 **/
enum OverlayType
{
	Overlay_Reset,			/** Reset all overlay. */
	Overlay_HumanWin,		/** Human win overlay. */
	Overlay_ZombieWin,		/** Zombie win overlay. */
};

/**
 * Prepare all decal data.
 **/
void VOverlayLoad()
{
	// Initialize chars
	static char sPath[PLATFORM_MAX_PATH];
	static char sCvar[BIG_LINE_LENGTH];
	
	//*********************************************************************
	//*               PRECACHE OF WIN OVERLAYS FILES            		  *
	//*********************************************************************
	
	// Load zombie win overlay
	GetConVarString(gCvarList[CVAR_HUD_ZOMBIE_WIN], sCvar, sizeof(sCvar));
	
	// Precache decals
	Format(sPath, sizeof(sPath), "materials/%s.vmt", sCvar);
	AddFileToDownloadsTable(sPath);
	Format(sPath, sizeof(sPath), "materials/%s.vtf", sCvar);
	AddFileToDownloadsTable(sPath);
	PrecacheDecal(sPath);

	// Load human win overlay
	GetConVarString(gCvarList[CVAR_HUD_HUMAN_WIN], sCvar, sizeof(sCvar));
	
	// Precache decals
	Format(sPath, sizeof(sPath), "materials/%s.vmt", sCvar);
	AddFileToDownloadsTable(sPath);
	Format(sPath, sizeof(sPath), "materials/%s.vtf", sCvar);
	AddFileToDownloadsTable(sPath);
	PrecacheDecal(sPath);
}

/**
 * Update overlay on a client.
 *
 * @param clientIndex		The client index.
 * @param CType				The type of the overlay.
 **/
void VOverlayOnClientUpdate(int clientIndex, OverlayType CType)
{
	// Initilize path
	static char sOverlay[NORMAL_LINE_LENGTH];

	// Switch overlay type
	switch(CType)
	{
		// Clear any existing overlay from the screen
		case Overlay_Reset : 		strcopy(sOverlay, sizeof(sOverlay), "");

		// Show human win overlay on the screen
		case Overlay_HumanWin :		GetConVarString(gCvarList[CVAR_HUD_HUMAN_WIN],  sOverlay, sizeof(sOverlay)); 	

		// Show zombie win overlay on the screen
		case Overlay_ZombieWin :	GetConVarString(gCvarList[CVAR_HUD_ZOMBIE_WIN], sOverlay, sizeof(sOverlay)); 
	}
		
	// Display overlay to the client
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") &~ FCVAR_CHEAT); 
	ClientCommand(clientIndex, "r_screenoverlay \"%s\"", sOverlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") |  FCVAR_CHEAT);
}