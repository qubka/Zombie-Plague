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
 * @section: Global forward handles.
 **/
Handle forwardOnClientInfected 		= NULL;
Handle forwardOnClientHeroed 		= NULL;
Handle forwardOnClientDamaged 		= NULL;
Handle forwardOnClientBuyExtraItem 	= NULL;
Handle forwardOnClientSkillUsed		= NULL;
Handle forwardOnClientSkillOver		= NULL;
Handle forwardOnZombieModStarted 	= NULL;
/**
 * @endsection
 **/

/**
 * Initializes all natives and forwards related to infection.
 **/
void APIForwardsInit(/*void*/)
{
	forwardOnClientInfected 	= CreateGlobalForward("ZP_OnClientInfected", 		ET_Ignore, Param_Cell, Param_Cell);
	forwardOnClientHeroed		= CreateGlobalForward("ZP_OnClientHeroed", 			ET_Ignore, Param_Cell);
	forwardOnClientDamaged		= CreateGlobalForward("ZP_OnClientDamaged", 		ET_Ignore, Param_Cell, Param_Cell, Param_FloatByRef);
	forwardOnClientBuyExtraItem	= CreateGlobalForward("ZP_OnClientBuyExtraItem", 	ET_Hook,   Param_Cell, Param_Cell);
	forwardOnClientSkillUsed	= CreateGlobalForward("ZP_OnClientSkillUsed", 		ET_Hook,   Param_Cell);
	forwardOnClientSkillOver	= CreateGlobalForward("ZP_OnClientSkillOver", 		ET_Ignore, Param_Cell);
	forwardOnZombieModStarted 	= CreateGlobalForward("ZP_OnZombieModStarted",  	ET_Ignore, Param_Cell);
}

/**
 * Called when a client became a zombie.
 * 
 * @param victimIndex	 	The client index.
 * @param attackerIndex	 	The attacker index.
 **/
void API_OnClientInfected(int victimIndex, int attackerIndex)
{
    // Start forward call
	Call_StartForward(forwardOnClientInfected);

	// Push the parameters
	Call_PushCell(victimIndex);
	Call_PushCell(attackerIndex);
	
	// Finish the call
	Call_Finish();
}

/**
 * Called when a client became a survivor.
 * 
 * @param clientIndex		The client index.
 **/
void API_OnClientHeroed(int clientIndex)
{
	// Start forward call
	Call_StartForward(forwardOnClientHeroed);

	// Push the parameters
	Call_PushCell(clientIndex);

	// Finish the call
	Call_Finish();
}

/**
 * Called when a client take a fake damage.
 * 
 * @param victimIndex	 	The client index.
 * @param attackerIndex	 	The attacker index.
 * @param damageAmount		The amount of damage inflicted.
 **/
void API_OnClientDamaged(int victimIndex, int attackerIndex, float &damageAmount)
{
	// Start forward call
	Call_StartForward(forwardOnClientDamaged);

	// Push the parameters
	Call_PushCell(victimIndex);
	Call_PushCell(attackerIndex);
	Call_PushFloatRef(damageAmount);

	// Finish the call
	Call_Finish();
}

/**
 * Called after select an extraitem in equipment menu.
 * 
 * @param clientIndex		The client index.
 * @param itemIndex			The index of extra item from ZP_RegisterExtraItem() native.
 *
 * @return					Plugin_Handled or Plugin_Stop to block purhase. Anything else
 *                         	(like Plugin_Continue) to allow purhase and taking ammopacks.
 **/
Action API_OnClientBuyExtraItem(int clientIndex, int itemIndex)
{
	// Initialize future result
	Action resultHandle;
	
	// Start forward call
	Call_StartForward(forwardOnClientBuyExtraItem);
	
	// Push the parameters
	Call_PushCell(clientIndex);
	Call_PushCell(itemIndex);
	
	// Finish the call
	Call_Finish(resultHandle);
	
	// Return result
	return resultHandle;
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex		The client index.
 *
 * @return					Plugin_Handled or Plugin_Stop to block using skill. Anything else
 *								(like Plugin_Continue) to allow use.
 **/
Action API_OnClientSkillUsed(int clientIndex)
{
	// Initialize future result
	Action resultHandle;

	// Start forward call
	Call_StartForward(forwardOnClientSkillUsed);

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
 * @param clientIndex		The client index.
 **/
void API_OnClientSkillOver(int clientIndex)
{
	// Start forward call
	Call_StartForward(forwardOnClientSkillOver);

	// Push the parameters
	Call_PushCell(clientIndex);
	
	// Finish the call
	Call_Finish();
}

/**
 * Called after a zombie round is started.
 * 
 * @param modeIndex			The type of round mode. See enum ZPModeType.
 **/
void API_OnZombieModStarted(int modeIndex)
{
	// Start forward call
	Call_StartForward(forwardOnZombieModStarted);

	// Push the parameters
	Call_PushCell(modeIndex);

	// Finish the call
	Call_Finish();
}