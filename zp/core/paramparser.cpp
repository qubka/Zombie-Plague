/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:           paramparser.cpp
 *  Type:           Core 
 *  Description:    Provides functions for parsing single line strings, 
 *                    and parameters in key="value" format.
 *
 *
 *                  Examle raw string:
 *                  key1 = "value1"
 *                  key2 = "value2", "value3"
 *                  key3 = "value4", "value5", "value6"
 *                  key4 = "value7"
 *
 *  Copyright (C) 2015-2019  Nikita Ushakov (Ireland, Dublin)
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
 * @section Limit settings.
 **/
#define PARAM_VALUE_MAXPARTS 32      /** Maximum sub parts of value string. */    
#define PARAM_NAME_MAXLEN    64      /** Maximum length of key name. */
#define PARAM_VALUE_MAXLEN   256     /** Maximum length of value string. */
/**
 * @endsection
 **/

/**
 * @section Parsing error codes.
 **/
#define PARAM_ERROR_NO                  -1  /** No errors. */
#define PARAM_ERROR_EMPTY               0   /** Source string is empty. */
#define PARAM_ERROR_UNEXPECTED_KEY      1   /** Unexpected key name. */
#define PARAM_ERROR_UNEXPECTED_END      2   /** Unexpected end of source string. */
#define PARAM_ERROR_MISSING_SEPARATOR   3   /** Could not find a separator sign after key name. */
#define PARAM_ERROR_MISSING_QUOTES      4   /** Could not find a quotes sign (") after key name. */
#define PARAM_ERROR_UNKNOWN             5   /** Unknown error. The parser got a invalid result from a search function it couldn't handle. */
#define PARAM_ERROR_FULL                6   /** Destination array is full. */
/**
 * @endsection
 **/
 
/**
 * Errors description for a codes.
 **/
static const char sParamError[7][PARAM_VALUE_MAXLEN] = {
    /*"No errors",*/
    "Source string is empty",
    "Unexpected key name",
    "Unexpected end of source string",
    "Could not find a separator sign after key name",
    "Could not find a quotes sign (\") after key name",
    "Unknown error. The parser got a invalid result from a search function it couldn't handle",
    "Destination array is full"
};
   
/**
 * Modes for what to do and expect when parsing. White space characters between
 * modes are ignored.
 **/
enum ParamModes
{
    ParamMode_Sep,    /** Expect a separator sign. */
    ParamMode_Key,    /** Expect a key name. */
    ParamMode_Value,  /** Expect a value string. */
    ParamMode_Finish  /** Finish parsing. */
}

/**
 * Structure for storing a key/value pair.
 **/
enum ParamParseResult
{
    String:Param_Name[PARAM_NAME_MAXLEN],   /** Key or flag name. */
    String:Param_Value[PARAM_VALUE_MAXLEN]  /** Value. Only used if a key. */
}

/**************************************
 *                                    *
 *       PARAMETER FUNCTIONS          *
 *                                    *
 **************************************/

 
/**
 * Parses a parameter string in key = "value" format and store the result in a ParamParseResult array.
 *
 * @param iBuffer           A ParamParseResult array to store results.
 * @param sParamString      The source string to parse. Error message output.
 * @param iMaxLen           Maximum number of keys that can be stored (first dimension of buffer).
 * @param cSeparator        The separator character.
 * @param iKeys             Optional output: Number of array.
 * @return                  Returns error code if parsing error.
 **/
stock int ParamParseString(iBuffer[][ParamParseResult], char[] sParamString, const int iMaxLen, char cSeparator, int &iKeys = 0)
{
    /*
     *  VALIDATION OF INPUT AND BUFFERS
     */

    // Cut out comments at the end of a line
    if(StrContains(sParamString, "//") != -1)
    {
        SplitString(sParamString, "//", sParamString, iMaxLen);
    } 
     
    // Trim string
    TrimString(sParamString);

    // Gets string length
    int iLen = strlen(sParamString);
    
    // Check if string is empty
    if(!iLen)
    {
        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_EMPTY]);
        return PARAM_ERROR_EMPTY;
    }

    // Check if there space left in the destination buffer
    if(iMaxLen > PARAM_VALUE_MAXLEN || iLen > PARAM_VALUE_MAXLEN)
    {
        // Exit loop. No more parameters can be parsed
        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_FULL]);
        return PARAM_ERROR_FULL;
    }
    
    /*
     *  PARSE LOOP
     */

    // Initialize. Expect a separator sign
    ParamModes iMode = ParamMode_Sep;

    // Buffers for temp values
    int iStartPos; int iEndPos; int iSeparatorPos;
    static char sValue[PARAM_VALUE_MAXLEN];

    // Loop through all string
    while(iMode != ParamMode_Finish)
    {
        /*
         *  MODE CHECK
         */

        // Check mode for deciding what to do
        switch(iMode)
        {
            case ParamMode_Sep :
            {
                // Position of separator character
                iSeparatorPos = FindCharInString(sParamString, cSeparator, false);

                // Parse error
                if(iSeparatorPos == -1)
                {
                    strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_MISSING_SEPARATOR]);
                    return PARAM_ERROR_MISSING_SEPARATOR;
                }

                // Update end position of key character. Substract by one to include 
                // the current character in next mode
                iEndPos = iSeparatorPos;
                    
                // Expect a key name
                iMode = ParamMode_Key;
            }

            case ParamMode_Key :
            {
                // Extract key name
                StrExtract(sValue, sParamString, iStartPos, iEndPos);

                // Trim string
                TrimString(sValue);
                
                // Check if string is empty, then stop
                if(!hasLength(sValue))
                {
                    strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_UNEXPECTED_KEY]);
                    return PARAM_ERROR_UNEXPECTED_KEY;
                }

                // Copy key name to destination buffer
                strcopy(iBuffer[iKeys][Param_Name], PARAM_NAME_MAXLEN, sValue);

                // Change mode to expect a value at next position.
                iMode = ParamMode_Value;
            }

            case ParamMode_Value :
            {
                // Find start position of first non white space character
                iStartPos = iSeparatorPos + 1;

                // Extract value string
                StrExtract(sParamString, sParamString, iStartPos, iLen);

                // Trim string
                TrimString(sParamString);
                
                // Check if string is empty, then stop
                if(!hasLength(sParamString))
                {
                    strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_UNEXPECTED_END]);
                    return PARAM_ERROR_UNEXPECTED_END;
                }
                else
                {
                    // Gets quotes at the beginning and at the end
                    int iQuote1 = FindCharInString(sParamString, '"', true);
                    int iQuote2 = FindCharInString(sParamString, '"', false);
                    
                    // Check if string without quote, then stop
                    if(iQuote1 == -1 || iQuote2 == -1 || iQuote1 == iQuote2)
                    {
                        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_MISSING_QUOTES]);
                        return PARAM_ERROR_MISSING_QUOTES;
                    }
                }

                // Copy value string to destination buffer
                strcopy(iBuffer[iKeys][Param_Value], PARAM_VALUE_MAXLEN, sParamString);

                // Successful parsing
                iMode = ParamMode_Finish;
            }
        }
    }

    // Return on success
    return PARAM_ERROR_NO;
}

/**
 * Finds the first key index in a parameter array matching the specified key.
 *
 * @param iParams            A ParamParseResult array to search through.
 * @param iMaxKeys           Max amount of keys on the 2D array.
 * @param sKey               Key to find.
 * @param caseSensitive      Specifies whether the search is case sensitive or not (default).
 * @return                   Index of the key iff ound, -1 otherwise.
 **/
stock int ParamFindKey(const iBuffer[][ParamParseResult], const int iMaxKeys, const char[] sKey, const bool caseSensitive = false)
{
    // Loop through all parameters
    for(int iIndex = 0; iIndex < iMaxKeys; iIndex++)
    {
        // Match key name
        if(!strcmp(iBuffer[iIndex][Param_Name], sKey, caseSensitive))
        {
            // Key found, return the key index
            return iIndex;
        }
    }
    
    // Return on unsuccess
    return -1;
}

/**************************************
 *                                    *
 *         HELPER FUNCTIONS           *
 *                                    *
 **************************************/
 
/**
 * Extracts a area in a string between two positions.
 *
 * @param sBuffer           Destination string buffer.
 * @param sSource           Source string to extract from.
 * @param startPos          Start position of string to extract.
 * @param endPos            End position of string to extract.
 * @return                  The number of cells written.
 **/
stock int StrExtract(char[] sBuffer, const char[] sSource, const int startPos, const int endPos)
{
    // Calculate string length. Also add space for null terminator
    int iMaxLen = endPos - startPos + 1;
    
    // Validate length
    if(iMaxLen < 0)
    {
        return 0;
    }
    
    // Extract string and store it in the buffer
    return strcopy(sBuffer, iMaxLen, sSource[startPos]);
}