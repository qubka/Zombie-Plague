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
 * @section All possible overlay channels, in order of priority.
 **/
enum OverlayType
{
    Overlay_Reset,                /** Reset all overlay. */
    Overlay_HumanWin,             /** Human win overlay. */
    Overlay_ZombieWin,            /** Zombie win overlay. */
    Overlay_Draw,                 /** Draw overlay. */
    Overlay_Vision                /** Vision overlay. */
};
/**
 * @endsection
 **/
 
/**
 * @brief Client has been spawn.
 *
 * @param clientIndex       The client index.
 **/
void VOverlayOnClientSpawn(int clientIndex)
{
    // Reset overlay on the team change
    VOverlayOnClientUpdate(clientIndex, Overlay_Reset);
} 

/**
 * @brief Client has been death.
 *
 * @param clientIndex       The client index.
 **/
void VOverlayOnClientDeath(int clientIndex)
{
    // Reset overlay on the death
    VOverlayOnClientUpdate(clientIndex, Overlay_Reset);
} 
 
/**
 * @brief Client has been changed class state.
 *
 * @param clientIndex       The client index.
 * @param nOverlay          The overlay type.
 **/
void VOverlayOnClientUpdate(int clientIndex, OverlayType nOverlay)
{
    // Initilize overlay char
    static char sOverlay[PLATFORM_LINE_LENGTH];

    // Gets overlay type
    switch(nOverlay)
    {
        // Remove 'Any' overlay
        case Overlay_Reset : 
        {
            // Reset overlay path
            sOverlay[0] = '\0'; 
            
            // Disable ngv and remove ngv ownership
            ToolsSetClientNightVision(clientIndex, false);
            ToolsSetClientNightVision(clientIndex, false, true);
        }
  
        // Sets 'Human Win' overlay
        case Overlay_HumanWin : 
        {
            // Gets overlay path
            ModesGetOverlayHuman(gServerData.RoundMode, sOverlay, sizeof(sOverlay)); 
            if(!hasLength(sOverlay)) return; // Stop here if the path empty
        }    

        // Sets 'Zombie Win' overlay
        case Overlay_ZombieWin : 
        {
            // Gets overlay path
            ModesGetOverlayZombie(gServerData.RoundMode, sOverlay, sizeof(sOverlay)); 
            if(!hasLength(sOverlay)) return; // Stop here if the path empty
        }
        
        // Sets 'Draw' overlay
        case Overlay_Draw : 
        {
            // Gets overlay path
            ModesGetOverlayDraw(gServerData.RoundMode, sOverlay, sizeof(sOverlay)); 
            if(!hasLength(sOverlay)) return; // Stop here if the path empty
        }  
        
        // Sets 'Vision' overlay
        case Overlay_Vision : 
        {
            // Create ngv ownership and enable ngv 
            ToolsSetClientNightVision(clientIndex, true, true);
            ToolsSetClientNightVision(clientIndex, ClassIsNvgs(gClientData[clientIndex].Class));

            // Gets overlay path
            ClassGetOverlay(gClientData[clientIndex].Class, sOverlay, sizeof(sOverlay)); 
            if(!hasLength(sOverlay)) return; // Stop here if the path empty
        }                        
    }

    // Format the full path
    Format(sOverlay, sizeof(sOverlay), "r_screenoverlay \"%s\"", sOverlay);
    
    // Display overlay to the client
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") &~ FCVAR_CHEAT); 
    ClientCommand(clientIndex, sOverlay);
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
}

/**
 * @brief Client has been switch nightvision.
 *
 * @param clientIndex       The client index.
 **/
void VOverlayOnClientNvgs(int clientIndex)
{
    // Switch on/off nightvision 
    VOverlayOnClientUpdate(clientIndex, ToolsGetClientNightVision(clientIndex, true) ? Overlay_Reset : Overlay_Vision);
}