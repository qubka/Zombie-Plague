/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          translation.cpp
 *  Type:          Core 
 *  Description:   Translation parsing functions.
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
 * @section Max length of different message formats.
 **/
#define TRANSLATION_MAX_LENGTH_CHAT 192
#define TRANSLATION_MAX_LENGTH_CONSOLE 1024
/**
 * @endsection
 **/

/**
 * Prefix on all messages printed from the plugin.
 **/
#define TRANSLATION_PHRASE_PREFIX 		"[ZP]"

/**
 * @section Text color chars.
 **/
#define TRANSLATION_TEXT_COLOR_DEFAULT 	"\x01"
#define TRANSLATION_TEXT_COLOR_RED 		"\x02"
#define TRANSLATION_TEXT_COLOR_LGREEN 	"\x03"
#define TRANSLATION_TEXT_COLOR_GREEN 	"\x04"
/**
 * @endsection
 **/

/**
 * Load translations file here.
 **/
void TranslationInit()
{
	// Load translations phrases used by plugin
	LoadTranslations("zombieplague.phrases");
}

/**
 * Format the string to the plugin's style.
 * 
 * @param sText      		Text to format.
 * @param iMaxlen    		Maximum length of the formatted text.
 **/
stock void TranslationPluginFormatString(char[] sText, int iMaxlen, bool bColor = true)
{
	if(bColor)
	{
		// Format prefix onto the string
		Format(sText, iMaxlen, " @green%s @default%s", TRANSLATION_PHRASE_PREFIX, sText);

		// Replace color tokens with CS:GO color chars
		ReplaceString(sText, iMaxlen, "@default", TRANSLATION_TEXT_COLOR_DEFAULT);
		ReplaceString(sText, iMaxlen, "@red", TRANSLATION_TEXT_COLOR_RED);
		ReplaceString(sText, iMaxlen, "@lgreen", TRANSLATION_TEXT_COLOR_LGREEN);
		ReplaceString(sText, iMaxlen, "@green", TRANSLATION_TEXT_COLOR_GREEN);
	}
	else
	{
		// Format prefix onto the string
		Format(sText, iMaxlen, "%s %s", TRANSLATION_PHRASE_PREFIX, sText);
	}
}

/**
 * Print console text to client. (with style)
 * 
 * @param clientIndex    The client index.
 * @param ...       	 Translation formatting parameters.  
 */
stock void TranslationPrintToConsole(int clientIndex, any ...)
{
    // Set translation target
    SetGlobalTransTarget(clientIndex);
    
    // Translate phrase
    static char sTranslation[TRANSLATION_MAX_LENGTH_CONSOLE];
    VFormat(sTranslation, sizeof(sTranslation), "%t", 2);
    
    // Format string to create plugin style
    TranslationPluginFormatString(sTranslation, sizeof(sTranslation), false);
    
    // Print translated phrase to client's console
    PrintToConsole(clientIndex, sTranslation);
}

/**
 * Print console text to all admins or server. (with style)
 * 
 * @param bServer    True to also print text to server console, false just to clients.
 * @param bAdmin	 True to just administators, false just to clients.
 * @param ...        Translation formatting parameters.
 */
stock void TranslationPrintToConsoleAll(bool bServer, bool bAdmin, any ...)
{
	static char sTranslation[TRANSLATION_MAX_LENGTH_CONSOLE];

	if(bServer)
	{
		// Set translation target
		SetGlobalTransTarget(LANG_SERVER);

		// Translate phrase
		VFormat(sTranslation, sizeof(sTranslation), "%t", 3);

		// Format string to create plugin style
		TranslationPluginFormatString(sTranslation, sizeof(sTranslation), false);

		// Print translated phrase to server's console
		PrintToServer(sTranslation);
	}

	// x = client index.
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if(!IsPlayerExist(i, false))
		{
			continue;
		}

		// If client isn't an admin, and we're only printing to admins, then stop
		if(bAdmin && !IsPlayerHasFlag(i))
		{
			continue;
		}

		// Set translation target
		SetGlobalTransTarget(LANG_SERVER);

		// Translate phrase.
		VFormat(sTranslation, sizeof(sTranslation), "%t", 3);

		// Format string to create plugin style
		TranslationPluginFormatString(sTranslation, sizeof(sTranslation), false);

		// Print translated phrase to client's console
		PrintToConsole(i, sTranslation);
	}
}

/**
 * Print hint center text to client.
 * 
 * @param clientIndex    	The client index.
 * @param ...            	Formatting parameters.
 **/
stock void TranslationPrintHintText(int clientIndex, any ...)
{
	// Set translation target
	SetGlobalTransTarget(clientIndex);

	// Translate phrase
	static char sTranslation[TRANSLATION_MAX_LENGTH_CHAT];
	VFormat(sTranslation, TRANSLATION_MAX_LENGTH_CHAT, "%t", 2);

	// Print translated phrase to client's screen
	PrintHintText(clientIndex, sTranslation);
}

/**
 * Print hint center text to all clients.
 *
 * @param ...      			Formatting parameters.
 **/
stock void TranslationPrintHintTextAll(any ...)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if(!IsPlayerExist(i, false))
		{
			continue;
		}
		
		// Set translation target
		SetGlobalTransTarget(i);
		
		// Translate phrase
		static char sTranslation[TRANSLATION_MAX_LENGTH_CHAT];
		VFormat(sTranslation, TRANSLATION_MAX_LENGTH_CHAT, "%t", 1);
		
		// Print translated phrase to client's screen
		PrintHintText(i, sTranslation);
	}
}

/**
 * Print hud text to client.
 * 
 * @param clientIndex    	The client index.
 * @param x 				x coordinate, from 0 to 1. -1.0 is the center.
 * @param y 				y coordinate, from 0 to 1. -1.0 is the center.
 * @param holdTime 			Number of seconds to hold the text.
 * @param r 				Red color value.
 * @param g 				Green color value.
 * @param b 				Blue color value.
 * @param a 				Alpha transparency value.
 * @param effect 			0/1 causes the text to fade in and fade out. 2 causes the text to flash[?].
 * @param fxTime 			Duration of chosen effect (may not apply to all effects).
 * @param fadeIn 			Number of seconds to spend fading in.
 * @param fadeOut 			Number of seconds to spend fading out.
 * @param ...            	Formatting parameters.
 **/
stock void TranslationPrintHudText(int clientIndex, float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut, any ...)
{
	// Set translation target
	SetGlobalTransTarget(clientIndex);

	// Translate phrase
	static char sTranslation[TRANSLATION_MAX_LENGTH_CHAT];
	VFormat(sTranslation, TRANSLATION_MAX_LENGTH_CHAT, "%t", 13);

	// Sets the HUD parameters for drawing text
	SetHudTextParams(x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut);
	
	// Print translated phrase to client's screen
	ShowHudText(clientIndex, -1, sTranslation);
}

/**
 * Print hud text to all clients.
 *
 * @param x 				x coordinate, from 0 to 1. -1.0 is the center.
 * @param y 				y coordinate, from 0 to 1. -1.0 is the center.
 * @param holdTime 			Number of seconds to hold the text.
 * @param r 				Red color value.
 * @param g 				Green color value.
 * @param b 				Blue color value.
 * @param a 				Alpha transparency value.
 * @param effect 			0/1 causes the text to fade in and fade out. 2 causes the text to flash[?].
 * @param fxTime 			Duration of chosen effect (may not apply to all effects).
 * @param fadeIn 			Number of seconds to spend fading in.
 * @param fadeOut 			Number of seconds to spend fading out.
 * @param ...            	Formatting parameters.
 **/
stock void TranslationPrintHudTextAll(float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut, any ...)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if(!IsPlayerExist(i, false))
		{
			continue;
		}
		
		// Set translation target
		SetGlobalTransTarget(i);
		
		// Translate phrase
		static char sTranslation[TRANSLATION_MAX_LENGTH_CHAT];
		VFormat(sTranslation, TRANSLATION_MAX_LENGTH_CHAT, "%t", 12);
		
		// Sets the HUD parameters for drawing text
		SetHudTextParams(x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut);

		// Print translated phrase to client's screen
		ShowHudText(i, -1, sTranslation);
	}
}

/**
 * Print chat text to client.
 * 
 * @param clientIndex    	The client index.
 * @param ...            	Formatting parameters. 
 **/
stock void TranslationPrintToChat(int clientIndex, any ...)
{
	// Set translation target
	SetGlobalTransTarget(clientIndex);
	
    // Translate phrase
	static char sTranslation[TRANSLATION_MAX_LENGTH_CHAT];
	VFormat(sTranslation, TRANSLATION_MAX_LENGTH_CHAT, "%t", 2);
	
	// Format string to create plugin style
	TranslationPluginFormatString(sTranslation, TRANSLATION_MAX_LENGTH_CHAT);
	
	// Print translated phrase to client's chat
	PrintToChat(clientIndex, sTranslation);
}

/**
 * Print center text to all clients.
 *
 * @param ...      			Formatting parameters.
 **/
stock void TranslationPrintToChatAll(any ...)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if(!IsPlayerExist(i, false))
		{
			continue;
		}

		// Set translation target
		SetGlobalTransTarget(i);
		
		// Translate phrase
		static char sTranslation[TRANSLATION_MAX_LENGTH_CHAT];
		VFormat(sTranslation, TRANSLATION_MAX_LENGTH_CHAT, "%t", 1);
		
		// Format string to create plugin style
		TranslationPluginFormatString(sTranslation, TRANSLATION_MAX_LENGTH_CHAT);
		
		// Print translated phrase to client's chat
		PrintToChat(i, sTranslation);
	}
}

/**
 * Print text to server. (with style)
 * 
 * @param ...       Translation formatting parameters.  
 */
stock void TranslationPrintToServer(any:...)
{
	// Set translation target
	SetGlobalTransTarget(LANG_SERVER);

	// Translate phrase
	static char sTranslation[TRANSLATION_MAX_LENGTH_CONSOLE];
	VFormat(sTranslation, sizeof(sTranslation), "%t", 1);

	// Format string to create plugin style
	TranslationPluginFormatString(sTranslation, sizeof(sTranslation), false);

	// Print translated phrase to server's console
	PrintToServer(sTranslation);
}

/**
 * Print into console for client. (with style)
 * 
 * @param clientIndex    	The client index.
 * @param ...            	Formatting parameters. 
 **/
stock void TranslationReplyToCommand(int clientIndex, any ...)
{
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		return;
	}
	
	// Set translation target
	SetGlobalTransTarget(clientIndex);
	
	// Translate phrase
	static char sTranslation[TRANSLATION_MAX_LENGTH_CONSOLE];
	VFormat(sTranslation, TRANSLATION_MAX_LENGTH_CONSOLE, "%t", 2);

	// Format string to create plugin style
	TranslationPluginFormatString(sTranslation, TRANSLATION_MAX_LENGTH_CONSOLE, false);

	// Print translated phrase to client's console
	ReplyToCommand(clientIndex, sTranslation);
}