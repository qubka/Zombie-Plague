/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          api.cpp
 *  Type:          API 
 *  Description:   Native handlers for the ZP API.
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
 
 /*
 * Application Programming Interface (API)
 * 
 * To allow other plugins or extensions to interact directly with Zombie Plague Mod we need to implement
 * an API.  SourceMod allows us to do this by creating global "natives" or "forwards."
 * 
 * To better understand how natives and forwards are created, go here:
 * http://wiki.alliedmods.net/Creating_Natives_(SourceMod_Scripting)
 * http://wiki.alliedmods.net/Function_Calling_API_(SourceMod_Scripting) 
 */

#include "zp/api/forwards.h.cpp"
#include "zp/api/natives.h.cpp"

/**
 * Initializes all main natives and forwards.
 **/
APLRes APIInit(/*void*/)
{
	// Load natives
	APINativesInit();
	
	// Load forwards
	APIForwardsInit();
	
	// Register mod library
	RegPluginLibrary("zombieplague");
	
	// Return on success
	return APLRes_Success;
}