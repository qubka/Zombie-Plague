/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          commands.cpp
 *  Type:          Game 
 *  Description:   Console command initilization and hooking.
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
 * Commands are created.
 **/
void CommandsInit(/*void*/)
{
    // Forward event to sub-modules
    DebugOnCommandsCreate();
    ConfigOnCommandsCreate();
    LogOnCommandsCreate();
    MenusOnCommandsCreate();
    ToolsOnCommandsCreate();
    HumanOnCommandsCreate();
    ZombieOnCommandsCreate();
    WeaponsOnCommandsCreate();
    ExtraItemsOnCommandsCreate();
    CostumesOnCommandsCreate();
    VersionOnCommandsCreate();
}