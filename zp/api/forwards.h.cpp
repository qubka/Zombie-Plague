/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          natives.h.cpp
 *  Type:          API 
 *  Description:   Forwards handlers for the ZP API.
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
 * List of forwards used by the plugin.
 **/
enum ForwardsList
{
    Handle:OnClientInfected,
    Handle:OnClientHumanized,
    Handle:OnClientDamaged,
    Handle:OnClientValidateItem,
    Handle:OnClientBuyItem,
    Handle:OnClientValidateMenu,
    Handle:OnClientValidateZombie,
    Handle:OnClientValidateHuman,
    Handle:OnClientSkillUsed,
    Handle:OnClientSkillOver,
    Handle:OnZombieModStarted
}

/**
 * Array to store forward data in.
 **/
ConVar gForwardsList[ForwardsList];

/**
 * Initializes all natives and forwards related to infection.
 **/
void APIForwardsInit(/*void*/)
{
    gForwardsList[OnClientInfected]       = CreateGlobalForward("ZP_OnClientInfected", ET_Ignore, Param_Cell, Param_Cell);
    gForwardsList[OnClientHumanized]      = CreateGlobalForward("ZP_OnClientHumanized", ET_Ignore, Param_Cell);
    gForwardsList[OnClientDamaged]        = CreateGlobalForward("ZP_OnClientDamaged", ET_Ignore, Param_Cell, Param_Cell, Param_FloatByRef, Param_Cell);
    gForwardsList[OnClientValidateItem]   = CreateGlobalForward("ZP_OnClientValidateExtraItem", ET_Hook, Param_Cell, Param_Cell);
    gForwardsList[OnClientBuyItem]        = CreateGlobalForward("ZP_OnClientBuyExtraItem", ET_Ignore, Param_Cell, Param_Cell);
    gForwardsList[OnClientValidateMenu]   = CreateGlobalForward("ZP_OnClientValidateMainMenu", ET_Hook, Param_Cell);
    gForwardsList[OnClientValidateZombie] = CreateGlobalForward("ZP_OnClientValidateZombieClass", ET_Hook, Param_Cell, Param_Cell);
    gForwardsList[OnClientValidateHuman]  = CreateGlobalForward("ZP_OnClientValidateHumanClass", ET_Hook, Param_Cell, Param_Cell);
    gForwardsList[OnClientSkillUsed]      = CreateGlobalForward("ZP_OnClientSkillUsed", ET_Hook, Param_Cell);
    gForwardsList[OnClientSkillOver]      = CreateGlobalForward("ZP_OnClientSkillOver", ET_Ignore, Param_Cell);
    gForwardsList[OnZombieModStarted]     = CreateGlobalForward("ZP_OnZombieModStarted", ET_Ignore);
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param victimIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
void API_OnClientInfected(int victimIndex, int attackerIndex)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientInfected]);

    // Push the parameters
    Call_PushCell(victimIndex);
    Call_PushCell(attackerIndex);
    
    // Finish the call
    Call_Finish();
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 **/
void API_OnClientHumanized(int clientIndex)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientHumanized]);

    // Push the parameters
    Call_PushCell(clientIndex);

    // Finish the call
    Call_Finish();
}

/**
 * Called when a client take a fake damage.
 * 
 * @param victimIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageType        The ditfield of damage types
 **/
void API_OnClientDamaged(int victimIndex, int attackerIndex, float &damageAmount, int damageType)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientDamaged]);

    // Push the parameters
    Call_PushCell(victimIndex);
    Call_PushCell(attackerIndex);
    Call_PushFloatRef(damageAmount);
    Call_PushCell(damageType);

    // Finish the call
    Call_Finish();
}

/**
 * Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param itemID            The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
Action API_OnClientValidateExtraItem(int clientIndex, int itemIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateItem]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(itemIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called after select an extraitem in equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param itemIndex         The index of extra item from ZP_RegisterExtraItem() native.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block purhase. Anything else
 *                                 (like Plugin_Continue) to allow purhase and withdraw ammopacks.
 **/
void API_OnClientBuyExtraItem(int clientIndex, int itemIndex)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientBuyItem]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(itemIndex);
    
    // Finish the call
    Call_Finish();
}

/**
 * Called before show a main menu.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block showing. Anything else
 *                              (like Plugin_Continue) to allow showing.
 **/
Action API_OnClientValidateMainMenu(int clientIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateMenu]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * @brief Called before show a zombie class in the zombie class menu.
 * 
 * @param clientIndex       The client index.
 * @param classIndex        The index of class from ZP_RegisterZombieClass() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
Action API_OnClientValidateZombieClass(int clientIndex, int classIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateZombie]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(classIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * @brief Called before show a human class in the human class menu.
 * 
 * @param clientIndex       The client index.
 * @param classIndex        The index of class from ZP_RegisterHumanClass() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
Action API_OnClientValidateHumanClass(int clientIndex, int classIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateHuman]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(classIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block using skill. Anything else
 *                                (like Plugin_Continue) to allow use.
 **/
Action API_OnClientSkillUsed(int clientIndex)
{
    // Initialize future result
    Action resultHandle;

    // Start forward call
    Call_StartForward(gForwardsList[OnClientSkillUsed]);

    // Push the parameters
    Call_PushCell(clientIndex);

    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called when a zombie skill duration is over.
 * 
 * @param clientIndex       The client index.
 **/
void API_OnClientSkillOver(int clientIndex)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientSkillOver]);

    // Push the parameters
    Call_PushCell(clientIndex);
    
    // Finish the call
    Call_Finish();
}

/**
 * Called after a zombie round is started.
 **/
void API_OnZombieModStarted(/*void*/)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnZombieModStarted]);

    // Finish the call
    Call_Finish();
}
