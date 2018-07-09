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
 **/

/**
 * All possible overlay channels, in order of priority.
 **/
enum OverlayType
{
    Overlay_Reset,           /** Reset all overlay. */
    Overlay_HumanWin,        /** Human win overlay. */
    Overlay_ZombieWin,       /** Zombie win overlay. */
    Overlay_Draw,            /** Draw overlay. */
    Overlay_Vision           /** Vision overlay. */
};

/**
 * Prepare all decal data.
 **/
void VOverlayLoad(/*void*/)
{
    // Initialize chars
    static char sPath[PLATFORM_MAX_PATH];
    static char sOverlay[PLATFORM_MAX_PATH];
    
    //*********************************************************************
    //*               PRECACHE OF WIN OVERLAYS FILES                      *
    //*********************************************************************
    
    // Load zombie win overlay
    gCvarList[CVAR_VEFFECTS_HUD_ZOMBIE].GetString(sOverlay, sizeof(sOverlay));
    
    // Precache decals
    if(strlen(sOverlay))
    {
        Format(sPath, sizeof(sPath), "materials/%s.vmt", sOverlay);
        fnMultiFilePrecache(sPath);
        Format(sPath, sizeof(sPath), "materials/%s.vtf", sOverlay);
        fnMultiFilePrecache(sPath);
    }
    
    // Load human win overlay
    gCvarList[CVAR_VEFFECTS_HUD_HUMAN].GetString(sOverlay, sizeof(sOverlay));
    
    // Precache decals
    if(strlen(sOverlay))
    {
        Format(sPath, sizeof(sPath), "materials/%s.vmt", sOverlay);
        fnMultiFilePrecache(sPath);
        Format(sPath, sizeof(sPath), "materials/%s.vtf", sOverlay);
        fnMultiFilePrecache(sPath);
    }
    
    // Load draw overlay
    gCvarList[CVAR_VEFFECTS_HUD_DRAW].GetString(sOverlay, sizeof(sOverlay));
    
    // Precache decals
    if(strlen(sOverlay))
    {
        Format(sPath, sizeof(sPath), "materials/%s.vmt", sOverlay);
        fnMultiFilePrecache(sPath);
        Format(sPath, sizeof(sPath), "materials/%s.vtf", sOverlay);
        fnMultiFilePrecache(sPath);
    }
    
    // Load vision overlay
    gCvarList[CVAR_VEFFECTS_HUD_VISION].GetString(sOverlay, sizeof(sOverlay));
    
    // Precache decals
    if(strlen(sOverlay))
    {
        Format(sPath, sizeof(sPath), "materials/%s.vmt", sOverlay);
        fnMultiFilePrecache(sPath);
        Format(sPath, sizeof(sPath), "materials/%s.vtf", sOverlay);
        fnMultiFilePrecache(sPath);
    }
}

/**
 * Client has been changed overlay state.
 *
 * @param clientIndex       The client index.
 * @param layIndex          The type of the overlay.
 **/
void VOverlayOnClientUpdate(int clientIndex, OverlayType layIndex)
{
    // Initilize path
    static char sOverlay[NORMAL_LINE_LENGTH];

    // Switch overlays
    switch(layIndex)
    {
        // Clear any existing overlay from the screen
        case Overlay_Reset : 
        { 
            sOverlay[0] = '\0'; 
            ToolsSetClientNightVision(clientIndex, false); /// Disable ngv 
            ToolsSetClientNightVision(clientIndex, false, true); /// Remove ngv ownership
        }
        
        // Show human win overlay on the screen
        case Overlay_HumanWin : 
        { 
            gCvarList[CVAR_VEFFECTS_HUD_HUMAN].GetString(sOverlay, sizeof(sOverlay));
            if(!strlen(sOverlay)) return; // Stop here if the path empty
        }    

        // Show zombie win overlay on the screen
        case Overlay_ZombieWin : 
        { 
            gCvarList[CVAR_VEFFECTS_HUD_ZOMBIE].GetString(sOverlay, sizeof(sOverlay)); 
            if(!strlen(sOverlay)) return; // Stop here if the path empty
        }
        
        // Show draw overlay on the screen
        case Overlay_Draw : 
        { 
            gCvarList[CVAR_VEFFECTS_HUD_DRAW].GetString(sOverlay, sizeof(sOverlay)); 
            if(!strlen(sOverlay)) return; // Stop here if the path empty
        }  
        
        // Show vision overlay on the screen
        case Overlay_Vision : 
        { 
            gCvarList[CVAR_VEFFECTS_HUD_VISION].GetString(sOverlay, sizeof(sOverlay)); 
            ToolsSetClientNightVision(clientIndex, true, true); /// Create ngv ownership
            ToolsSetClientNightVision(clientIndex, gCvarList[CVAR_ZOMBIE_NIGHT_VISION].BoolValue); /// Enable ngv
            if(!strlen(sOverlay)) return; // Stop here if the path empty
        }                        
    }

    // Format the full path
    Format(sOverlay, sizeof(sOverlay), "r_screenoverlay \"%s\"", sOverlay);
    
    // Display overlay to the client
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") &~ FCVAR_CHEAT); 
    ClientCommand(clientIndex, sOverlay);
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") |  FCVAR_CHEAT);
}