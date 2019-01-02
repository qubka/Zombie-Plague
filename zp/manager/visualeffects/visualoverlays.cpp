/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          visualoverlays.cpp
 *  Type:          Module
 *  Description:   Handles overlays on clients, as a part of class attributes.
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
 * Client has been changed class state.
 *
 * @param clientIndex       The client index.
 * @param layIndex          The overlay type.
 **/
void VOverlayOnClientUpdate(const int clientIndex, OverlayType layIndex)
{
    // Initilize overlay char
    static char sOverlay[PLATFORM_MAX_PATH];

    // Switch overlays
    switch(layIndex)
    {
        // Remove 'Any' overlay
        case Overlay_Reset : 
        { 
            sOverlay[0] = '\0'; 
            ToolsSetClientNightVision(clientIndex, false); /// Disable ngv 
            ToolsSetClientNightVision(clientIndex, false, true); /// Remove ngv ownership
        }
  
        // Show 'Human Win' overlay
        case Overlay_HumanWin : 
        { 
            
            if(!strlen(sOverlay)) return; // Stop here if the path empty
        }    

        // Show 'Zombie Win' overlay
        case Overlay_ZombieWin : 
        { 
            
            if(!strlen(sOverlay)) return; // Stop here if the path empty
        }
        
        // Show 'Draw' overlay
        case Overlay_Draw : 
        { 
             
            if(!strlen(sOverlay)) return; // Stop here if the path empty
        }  
        
        // Show 'Vision' overlay
        case Overlay_Vision : 
        {
            ToolsSetClientNightVision(clientIndex, true, true); /// Create ngv ownership
            ToolsSetClientNightVision(clientIndex, ClassIsNvgs(gClientData[clientIndex][Client_Class])); /// Enable ngv
            ClassGetOverlay(gClientData[clientIndex][Client_Class], sOverlay, sizeof(sOverlay)); 
            if(!strlen(sOverlay)) return; // Stop here if the path empty
        }                        
    }

    // Format the full path
    Format(sOverlay, sizeof(sOverlay), "r_screenoverlay \"%s\"", sOverlay);
    
    // Display overlay to the client
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") &~ FCVAR_CHEAT); 
    ClientCommand(clientIndex, sOverlay);
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
}