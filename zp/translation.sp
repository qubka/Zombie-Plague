/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          translation.sp
 *  Type:          Core 
 *  Description:   Translation parsing functions.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
 * Prefix on all messages printed from the plugin.
 **/
#define TRANSLATION_PHRASE_PREFIX          "[ZP]"

/**
 * @section Text color chars.
 **/
#define TRANSLATION_TEXT_COLOR_DEFAULT     "\x01"
#define TRANSLATION_TEXT_COLOR_RED         "\x02"
#define TRANSLATION_TEXT_COLOR_LGREEN      "\x03"
#define TRANSLATION_TEXT_COLOR_GREEN       "\x04"
/**
 * @endsection
 **/
 
/**
 * @brief Load translations file here.
 **/
void TranslationOnInit()
{
	LoadTranslations("zombieplague.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	static char sPath[PLATFORM_LINE_LENGTH];
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations");
	
	DirectoryListing hDirectory = OpenDirectory(sPath);
	
	if (hDirectory == null)
	{
		LogEvent(false, _, _, _, "Config Validation", "Error opening folder: \"%s\"", sPath);
		return;
	}
	
	FileType hType; int iFormat;
	
	while (hDirectory.GetNext(sPath, sizeof(sPath), hType)) 
	{
		if (hType == FileType_File) 
		{
			if (!strncmp(sPath, "zombieplague_", 13, false))
			{
				iFormat = FindCharInString(sPath, '.');

				if (iFormat != -1) 
				{
					if (!strcmp(sPath[iFormat], ".phrases.txt", false))
					{
						LoadTranslations(sPath);
					}
				}
			}
		}
	}
	
	delete hDirectory;
}

/*
 * Stocks translation API.
 */

/**
 * @brief Format the string to the plugin style.
 * 
 * @param sText             Text to format.
 * @param iMaxlen           Maximum length of the formatted text.
 **/
stock void TranslationPluginFormatString(char[] sText, int iMaxlen, bool bColor = true)
{
	if (bColor)
	{
		Format(sText, iMaxlen, " @green%s @default%s", TRANSLATION_PHRASE_PREFIX, sText);

		ReplaceString(sText, iMaxlen, "@default", TRANSLATION_TEXT_COLOR_DEFAULT);
		ReplaceString(sText, iMaxlen, "@red", TRANSLATION_TEXT_COLOR_RED);
		ReplaceString(sText, iMaxlen, "@lgreen", TRANSLATION_TEXT_COLOR_LGREEN);
		ReplaceString(sText, iMaxlen, "@green", TRANSLATION_TEXT_COLOR_GREEN);
	}
	else
	{
		Format(sText, iMaxlen, "%s %s", TRANSLATION_PHRASE_PREFIX, sText);
	}
}

/**
 * @brief Print console text to the client. (with style)
 * 
 * @param client            The client index.
 * @param ...               Translation formatting parameters.  
 **/
stock void TranslationPrintToConsole(int client, any ...)
{
	if (!IsFakeClient(client))
	{
		SetGlobalTransTarget(client);
		
		static char sTranslation[CONSOLE_LINE_LENGTH];
		VFormat(sTranslation, sizeof(sTranslation), "%t", 2);
		
		TranslationPluginFormatString(sTranslation, sizeof(sTranslation), false);
		
		PrintToConsole(client, sTranslation);
	}
}

/**
 * @brief Print console text to all players or server. (with style)
 * 
 * @param bServer           True to also print text to server console, false just to the clients.
 * @param ...               Translation formatting parameters.
 **/
stock void TranslationPrintToConsoleAll(bool bServer, any ...)
{
	static char sTranslation[CONSOLE_LINE_LENGTH];

	if (bServer)
	{
		SetGlobalTransTarget(LANG_SERVER);

		VFormat(sTranslation, sizeof(sTranslation), "%t", 3);

		TranslationPluginFormatString(sTranslation, sizeof(sTranslation), false);

		PrintToServer(sTranslation);
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientValid(i, false, false))
		{
			continue;
		}

		SetGlobalTransTarget(i);

		VFormat(sTranslation, sizeof(sTranslation), "%t", 3);

		TranslationPluginFormatString(sTranslation, sizeof(sTranslation), false);

		PrintToConsole(i, sTranslation);
	}
}

/**
 * @brief Print hint center text to the client.
 * 
 * @param client            The client index.
 * @param ...               Formatting parameters.
 **/
stock void TranslationPrintHintText(int client, any ...)
{
	if (!IsFakeClient(client))
	{
		SetGlobalTransTarget(client);

		static char sTranslation[CHAT_LINE_LENGTH];
		VFormat(sTranslation, CHAT_LINE_LENGTH, "%t", 2);

		UTIL_CreateClientHint(client, sTranslation);
		
		EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
	}
}

/**
 * @brief Print hint center text to all clients.
 *
 * @param ...               Formatting parameters.
 **/
stock void TranslationPrintHintTextAll(any ...)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientValid(i, false, false))
		{
			continue;
		}

		SetGlobalTransTarget(i);
		
		static char sTranslation[CHAT_LINE_LENGTH];
		VFormat(sTranslation, CHAT_LINE_LENGTH, "%t", 1);
		
		UTIL_CreateClientHint(i, sTranslation);
	}
	
	EmitSoundToAll(SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
}

/**
 * @brief Print hud text to the client.
 * 
 * @param hSync             New HUD synchronization object.
 * @param client            The client index.
 * @param x                 x coordinate, from 0 to 1. -1.0 is the center.
 * @param y                 y coordinate, from 0 to 1. -1.0 is the center.
 * @param holdTime          Number of seconds to hold the text.
 * @param r                 Red color value.
 * @param g                 Green color value.
 * @param b                 Blue color value.
 * @param a                 Alpha transparency value.
 * @param effect            0/1 causes the text to fade in and fade out. 2 causes the text to flash[?].
 * @param fxTime            Duration of chosen effect (may not apply to all effects).
 * @param fadeIn            Number of seconds to spend fading in.
 * @param fadeOut           Number of seconds to spend fading out.
 * @param ...               Formatting parameters.
 **/
stock void TranslationPrintHudText(Handle hSync, int client, float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut, any ...)
{
	if (!IsFakeClient(client))
	{
		SetGlobalTransTarget(client);

		static char sTranslation[CHAT_LINE_LENGTH];
		VFormat(sTranslation, CHAT_LINE_LENGTH, "%t", 14);

		UTIL_CreateClientHud(hSync, client, x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut, sTranslation);
	}
}

/**
 * @brief Print hud text to all clients.
 *
 * @param hSync             New HUD synchronization object.
 * @param x                 x coordinate, from 0 to 1. -1.0 is the center.
 * @param y                 y coordinate, from 0 to 1. -1.0 is the center.
 * @param holdTime          Number of seconds to hold the text.
 * @param r                 Red color value.
 * @param g                 Green color value.
 * @param b                 Blue color value.
 * @param a                 Alpha transparency value.
 * @param effect            0/1 causes the text to fade in and fade out. 2 causes the text to flash[?].
 * @param fxTime            Duration of chosen effect (may not apply to all effects).
 * @param fadeIn            Number of seconds to spend fading in.
 * @param fadeOut           Number of seconds to spend fading out.
 * @param ...               Formatting parameters.
 **/
stock void TranslationPrintHudTextAll(Handle hSync, float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut, any ...)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientValid(i, false, false))
		{
			continue;
		}

		SetGlobalTransTarget(i);
		
		static char sTranslation[CHAT_LINE_LENGTH];
		VFormat(sTranslation, CHAT_LINE_LENGTH, "%t", 13);

		UTIL_CreateClientHud(hSync, i, x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut, sTranslation);
	}
}

/**
 * @brief Print chat text to the client.
 * 
 * @param client            The client index.
 * @param ...               Formatting parameters. 
 **/
stock void TranslationPrintToChat(int client, any ...)
{
	if (!IsFakeClient(client))
	{
		SetGlobalTransTarget(client);

		static char sTranslation[CHAT_LINE_LENGTH];
		VFormat(sTranslation, CHAT_LINE_LENGTH, "%t", 2);

		TranslationPluginFormatString(sTranslation, CHAT_LINE_LENGTH);

		PrintToChat(client, sTranslation);
	}
}

/**
 * @brief Print center text to all clients.
 *
 * @param ...                  Formatting parameters.
 **/
stock void TranslationPrintToChatAll(any ...)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientValid(i, false, false))
		{
			continue;
		}

		SetGlobalTransTarget(i);
		
		static char sTranslation[CHAT_LINE_LENGTH];
		VFormat(sTranslation, CHAT_LINE_LENGTH, "%t", 1);
		
		TranslationPluginFormatString(sTranslation, CHAT_LINE_LENGTH);
		
		PrintToChat(i, sTranslation);
	}
}

/**
 * @brief Print text to server. (with style)
 * 
 * @param ...               Translation formatting parameters.  
 **/
stock void TranslationPrintToServer(any:...)
{
	SetGlobalTransTarget(LANG_SERVER);

	static char sTranslation[CONSOLE_LINE_LENGTH];
	VFormat(sTranslation, sizeof(sTranslation), "%t", 1);

	TranslationPluginFormatString(sTranslation, sizeof(sTranslation), false);

	PrintToServer(sTranslation);
}

/**
 * @brief Print into console for client. (with style)
 * 
 * @param client            The client index.
 * @param ...               Formatting parameters. 
 **/
stock void TranslationReplyToCommand(int client, any ...)
{
	if (!IsClientValid(client, false))
	{
		return;
	}
	
	SetGlobalTransTarget(client);
	
	static char sTranslation[CONSOLE_LINE_LENGTH];
	VFormat(sTranslation, CONSOLE_LINE_LENGTH, "%t", 2);

	TranslationPluginFormatString(sTranslation, CONSOLE_LINE_LENGTH, false);

	ReplyToCommand(client, sTranslation);
}


/**
 * @brief Determines if the specified phrase exists within the plugin's translation cache.
 * 
 * @param sPhrase           The phrase to look.
 * @return                  True or false.
 **/
bool TranslationIsPhraseExists(char[] sPhrase)
{
	StringToLower(sPhrase); 
	
	return TranslationPhraseExists(sPhrase);
}