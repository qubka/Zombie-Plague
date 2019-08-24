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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/
 
/**
 * @section All possible overlay channels, in order of priority.
 **/
enum OverlayType
{
    Overlay_Reset,                /** Resets all overlay. */
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
 * @param client            The client index.
 **/
void VOverlayOnClientSpawn(int client)
{
    // Resets overlay on the team change
    VOverlayOnClientUpdate(client, Overlay_Reset);
} 

/**
 * @brief Client has been death.
 *
 * @param client            The client index.
 **/
void VOverlayOnClientDeath(int client)
{
    // Resets overlay on the death
    VOverlayOnClientUpdate(client, Overlay_Reset);
} 
 
/**
 * @brief Client has been changed class state.
 *
 * @param client            The client index.
 * @param nOverlay          The overlay type.
 **/
void VOverlayOnClientUpdate(int client, OverlayType nOverlay)
{
    // Initilize overlay char
    static char sOverlay[PLATFORM_LINE_LENGTH];

    // Gets overlay type
    switch (nOverlay)
    {
        // Remove 'Any' overlay
        case Overlay_Reset : 
        {
            // Resets overlay path
            sOverlay[0] = NULL_STRING[0]; 
            
            // Disable ngv and remove ngv ownership
            ToolsSetNightVision(client, false);
            ToolsSetNightVision(client, false, true);
        }
  
        // Sets 'Human Win' overlay
        case Overlay_HumanWin : 
        {
            // Gets overlay path
            ModesGetOverlayHuman(gServerData.RoundMode, sOverlay, sizeof(sOverlay)); 
            if (!hasLength(sOverlay)) return; // Stop here if the path empty
        }    

        // Sets 'Zombie Win' overlay
        case Overlay_ZombieWin : 
        {
            // Gets overlay path
            ModesGetOverlayZombie(gServerData.RoundMode, sOverlay, sizeof(sOverlay)); 
            if (!hasLength(sOverlay)) return; // Stop here if the path empty
        }
        
        // Sets 'Draw' overlay
        case Overlay_Draw : 
        {
            // Gets overlay path
            ModesGetOverlayDraw(gServerData.RoundMode, sOverlay, sizeof(sOverlay)); 
            if (!hasLength(sOverlay)) return; // Stop here if the path empty
        }  
        
        // Sets 'Vision' overlay
        case Overlay_Vision : 
        {
            // Create ngv ownership and enable ngv 
            ToolsSetNightVision(client, true, true);
            ToolsSetNightVision(client, ClassIsNvgs(gClientData[client].Class));

            // Gets overlay path
            ClassGetOverlay(gClientData[client].Class, sOverlay, sizeof(sOverlay)); 
            if (!hasLength(sOverlay)) return; // Stop here if the path empty
        }                        
    }

    // Format the full path
    Format(sOverlay, sizeof(sOverlay), "r_screenoverlay \"%s\"", sOverlay);
    
    // Display overlay to the client
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") &~ FCVAR_CHEAT); 
    ClientCommand(client, sOverlay);
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
}

/**
 * @brief Client has been switch nightvision.
 *
 * @param client            The client index.
 **/
void VOverlayOnClientNvgs(int client)
{
    // Switch on/off nightvision 
    VOverlayOnClientUpdate(client, ToolsGetNightVision(client, true) ? Overlay_Reset : Overlay_Vision);
}