/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          natives.h.cpp
 *  Type:          API 
 *  Description:   Natives handlers for the ZP API.
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
 * Initializes all natives.
 **/
void APINativesInit(/*void*/)
{
    // Create main natives
    CreateNative("ZP_IsPlayerInGroup",      API_IsPlayerInGroup);
    CreateNative("ZP_IsPlayerZombie",       API_IsPlayerZombie);
    CreateNative("ZP_IsPlayerHuman",        API_IsPlayerHuman);
    CreateNative("ZP_IsPlayerUseSkill",     API_IsPlayerUseSkill);
    CreateNative("ZP_RespawnClient",        API_RespawnClient);
    CreateNative("ZP_ChangeClient",         API_ChangeClient); 
    CreateNative("ZP_GetClientMoney",       API_GetClientMoney);
    CreateNative("ZP_SetClientMoney",       API_SetClientMoney);
    CreateNative("ZP_GetClientLastBought",  API_GetClientLastBought);
    CreateNative("ZP_SetClientLastBought",  API_SetClientLastBought);
    CreateNative("ZP_GetClientLevel",       API_GetClientLevel);
    CreateNative("ZP_SetClientLevel",       API_SetClientLevel);
    CreateNative("ZP_GetClientExp",         API_GetClientExp);
    CreateNative("ZP_SetClientExp",         API_SetClientExp);
    CreateNative("ZP_GetClientTime",        API_GetClientTime);
    CreateNative("ZP_IsNewRound",           API_IsNewRound);
    CreateNative("ZP_IsEndRound",           API_IsEndRound);
    CreateNative("ZP_IsStartedRound",       API_IsStartedRound);
    CreateNative("ZP_GetNumberRound",       API_GetNumberRound);
    CreateNative("ZP_GetHumanAmount",       API_GetHumanAmount);
    CreateNative("ZP_GetZombieAmount",      API_GetZombieAmount);
    CreateNative("ZP_GetAliveAmount",       API_GetAliveAmount);
    CreateNative("ZP_GetPlayingAmount",     API_GetPlayingAmount);
    CreateNative("ZP_GetRandomHuman",       API_GetRandomHuman);
    CreateNative("ZP_GetRandomZombie",      API_GetRandomZombie);  

    // Forward event to sub-modules
    ToolsAPI();
    ClassesAPI();
    ExtraItemsAPI();
    WeaponsAPI();
    SoundsAPI();
    HitGroupsAPI();
    MenusAPI();
    GameModesAPI();
    CostumesAPI();
}

/**
 * Returns whether a player is in group or not.
 *
 * native bool ZP_IsPlayerInGroup(clientIndex, group);
 **/
public int API_IsPlayerInGroup(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    GetNativeString(2, sGroup, sizeof(sGroup));
    
    // Return the value
    return IsPlayerInGroup(clientIndex, sGroup);
}

/**
 * Returns true if the player is a zombie, false if not. 
 *
 * native bool ZP_IsPlayerZombie(clientIndex);
 **/
public int API_IsPlayerZombie(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return gClientData[clientIndex][Client_Zombie];
}

/**
 * Returns true if the player is a human, false if not.
 *
 * native bool ZP_IsPlayerHuman(clientIndex);
 **/
public int API_IsPlayerHuman(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return !gClientData[clientIndex][Client_Zombie];
}

/**
 * Returns true if the player use a skill, false if not. 
 *
 * native bool ZP_IsPlayerUseSkill(clientIndex);
 **/
public int API_IsPlayerUseSkill(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return gClientData[clientIndex][Client_Skill];
}

/**
 * Respawn a player.
 *
 * native void ZP_RespawnClient(clientIndex, iD);
 **/
public int API_RespawnClient(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Force client to respawn
    ToolsForceToRespawn(clientIndex);
}

/**
 * Infect/humanize a player.
 *
 * native void ZP_ChangeClient(clientIndex, attackerIndex, class);
 **/
public int API_ChangeClient(Handle hPlugin, const int iNumParams)
{
    // Force client to switch player class
    switch(GetNativeCell(3))
    {
        case ClassType_Zombie   : ClassMakeZombie(GetNativeCell(1), GetNativeCell(2));       /**< Make a zombie */
        case ClassType_Nemesis  : ClassMakeZombie(GetNativeCell(1), GetNativeCell(2), true); /**< Make a nemesis */
        case ClassType_Survivor : ClassMakeHuman(GetNativeCell(1), true);                    /**< Make a survivor */
        case ClassType_Human    : ClassMakeHuman(GetNativeCell(1));                          /**< Make a human */
    }
}

/**
 * Gets the player amount of money.
 *
 * native int ZP_GetClientMoney(clientIndex);
 **/
public int API_GetClientMoney(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_Money];
}

/**
 * Sets the player amount of money.
 *
 * native void ZP_SetClientMoney(clientIndex, iD);
 **/
public int API_SetClientMoney(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets money for the client
    AccountSetClientCash(clientIndex, GetNativeCell(2));
}

/**
 * Gets the player amount of previous money spended.
 *
 * native int ZP_GetClientLastBought(clientIndex);
 **/
public int API_GetClientLastBought(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_LastBoughtAmount];
}

/**
 * Sets the player amount of money spending.
 *
 * native void ZP_SetClientLastBoughtv(clientIndex, iD);
 **/
public int API_SetClientLastBought(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets money for the client
    gClientData[clientIndex][Client_LastBoughtAmount] = GetNativeCell(2);
}

/**
 * Gets the player level.
 *
 * native int ZP_GetClientLevel(clientIndex);
 **/
public int API_GetClientLevel(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_Level];
}

/**
 * Sets the player level.
 *
 * native void ZP_SetClientLevel(clientIndex, iD);
 **/
public int API_SetClientLevel(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets level for the client
    LevelSystemOnSetLvl(clientIndex, GetNativeCell(2));
}

/**
 * Gets the player exp.
 *
 * native int ZP_GetClientExp(clientIndex);
 **/
public int API_GetClientExp(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_Exp];
}

/**
 * Sets the player exp.
 *
 * native void ZP_SetClientExp(clientIndex, iD);
 **/
public int API_SetClientExp(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets exp for the client
    LevelSystemOnSetExp(clientIndex, GetNativeCell(2));
}

/**
 * Gets the last player disconnected time.
 *
 * native int ZP_GetClientTime(clientIndex);
 **/
public int API_GetClientTime(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_Time];
}

/**
 * Gets the new round state.
 *
 * native bool ZP_IsNewRound();
 **/
public int API_IsNewRound(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundNew];
}

/**
 * Gets the end round state.
 *
 * native bool ZP_IsEndRound();
 **/
public int API_IsEndRound(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundEnd];
}

/**
 * Gets the new round state.
 *
 * native bool ZP_IsStartedRound();
 **/
public int API_IsStartedRound(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundStart];
}

/**
 * Gets the number of round.
 *
 * native int ZP_GetNumberRound();
 **/
public int API_GetNumberRound(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundNumber];
}

/**
 * Gets amount of total humans.
 *
 * native int ZP_GetHumanAmount();
 **/
public int API_GetHumanAmount(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return fnGetHumans();
}

/**
 * Gets amount of total zombies.
 *
 * native int ZP_GetZombieAmount();
 **/
public int API_GetZombieAmount(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return fnGetZombies();
}

/**
 * Gets amount of total alive players.
 *
 * native int ZP_GetAliveAmount();
 **/
public int API_GetAliveAmount(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return fnGetAlive();
}

/**
 * Gets amount of total playing players.
 *
 * native int ZP_GetPlayingAmount();
 **/
public int API_GetPlayingAmount(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return fnGetPlaying();
}

/**
 * Gets index of the random human.
 *
 * native int ZP_GetRandomHuman();
 **/
public int API_GetRandomHuman(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return fnGetRandomHuman();
}

/**
 * Gets index of the random zombie.
 *
 * native int ZP_GetRandomZombie();
 **/
public int API_GetRandomZombie(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return fnGetRandomZombie();
}