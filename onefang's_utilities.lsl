// onefang's utilites version 3.0
// Read a complete settings notecard and send settings to other scripts.
// Also other useful functions.

// Copyright (C) 2007 David Seikel (onefang rejected).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies of the Software and its Copyright notices.  In addition publicly
// documented acknowledgment must be given that this software has been used if no
// source code of this software is made available publicly.  This includes
// acknowledgments in either Copyright notices, Manuals, Publicity and Marketing
// documents or any documentation provided with any product containing this
// software.  This License does not apply to any software that links to the
// libraries provided by this software (statically or dynamically), but only to
// the software provided.
//
// Please see the COPYING-PLAIN for a plain-english explanation of this notice
// and it's intent.
//
// The software is provided "as is", without warranty of any kind, express or
// implied, including but not limited to the warranties of merchantability,
// fitness for a particular purpose and noninfringement.  In no event shall
// the authors be liable for any claim, damages or other liability, whether
// in an action of contract, tort or otherwise, arising from, out of or in
// connection with the software or the use or other dealings in the software.
//
// As a special exception to the above conditions, the Second Life user known
// as Winter Ventura may ignore all permissions and conditions and provide her
// own.

// See the notecard "onefang's utilities manual".


float MENU_TIMEOUT = 45.0;

list channelHandles = [];    // channel            | listener
list chatChannels = [];      // channel            | script list
list chatOwners = [];        // owner+channel      | script list
list chatPrefixes = [];      // channel+" "+prefix | script list  (PREFIXES WITH SPACE)
list chatPrefixes2 = [];     // channel+" "+prefix | script list  (PREFIXES WITH NO SPACE)
list chatCommands = [];      // script+channel     | command list { command | argument defining stuff }
// TODO might be better to do - script+channel+" "+prefix | command list { command | argument defining stuff }
//    and do away with the chatPrefix lists.  Makes no space prefix checks harder I think.
//    or add a prefix field to the list.

// SettingsReaderAndUtilities constants for copying into other code.
string  LIST_SEP = "$!#";           // Used to seperate lists when sending them as strings.
integer UTILITIES_RESET            = -1;
integer UTILITIES_RESET_DONE        = -2;
integer UTILITIES_READ            = -3;
integer UTILITIES_READ_DONE        = -4;
integer UTILITIES_SUBSTITUTE        = -5;
integer UTILITIES_SUBSTITUTE_DONE    = -6;
integer UTILITIES_NEXT_WORD        = -7;
integer UTILITIES_NEXT_WORD_DONE        = -8;
integer UTILITIES_PAYMENT_MADE        = -9;    // Not used by this script
integer UTILITIES_PAYMENT_MADE_DONE    = -10;    // Not used by this script
integer UTILITIES_MENU            = -11;
integer UTILITIES_MENU_DONE        = -12;
integer UTILITIES_WARP            = -13;
integer UTILITIES_WARP_DONE        = -14;
integer UTILITIES_AVATAR_KEY        = -15;      // Redundant in OpenSim.
integer UTILITIES_AVATAR_KEY_DONE    = -16;     // Redundant in OpenSim.
integer UTILITIES_CHAT            = -17;
integer UTILITIES_CHAT_DONE        = -18;
integer UTILITIES_CHAT_FAKE        = -19;
integer UTILITIES_CHAT_FAKE_DONE        = -20;    // Never used anywhere.
// TODO reuse -20 for CHAT_PURGE - which removes this scriptKey from all chat lists, usually before replacing them.
//      Which was done some other way if I remember.

// internal constant and variable declarations.
integer KEYS_SCRIPT    = 0;
integer KEYS_TYPE    = 1;
integer KEYS_NAME    = 2;
integer KEYS_EXTRA    = 3;
integer KEYS_ID        = 4;
integer KEYS_STRIDE    = 5;

string  REQUEST_KEY    = "1";
string  REQUEST_IM    = "2";
string  REQUEST_ONLINE    = "3";
string  REQUEST_AVATAR    = "4";

integer MENU_USER       = 0;    // Key of user the big menu is for.
integer MENU_CHANNEL    = 1;    // Listen channel for big menu dialogs.
integer MENU_SCRIPT     = 2;    // ScriptKey of the script calling the menu.
integer MENU_HANDLE     = 3;    // Listen ID for big menu dialogs.
integer MENU_TYPE       = 4;    // Type of menu.
integer MENU_MESSAGE    = 5;    // Message for the top of big menu dialog.
integer MENU_MENU       = 6;    // The big menu itself.               LIST_SEP separated when they come in.
integer MENU_FILTER     = 7;    // Regex filter for inventory menus.  | separated when they come in.
integer MENU_POS        = 8;    // Current position within big menu.
integer MENU_MAXPOS     = 9;    // Maximum position within big menu.
integer MENU_NAMES      = 10;   // Long names to get around stupid SL menu limitations.
integer MENU_TIME       = 11;   // Otherwise this list is ever growing.  Damn Ignore button.  sigh
integer MENU_STRIDE     = 12;

list    settingsCards = [];           // Queue of cards to read.
string  settingsName = ".settings";   // Name of a notecard in the object's inventory.
key     settingsKey = NULL_KEY;       // ScriptKey of the script reading the card.
integer settingsLine = 0;             // Current line number.
key     settingsQueryID = NULL_KEY;   // ID used to identify dataserver queries.

list    menus = [];                   // The menus.
list    registeredMenus = [];         // Any scripts that have registered as needing a touch menu.
list    keyRequests = [];             // A list of avatar key requests.

list    ANIMATIONS =
[
    "aim_L_bow", "aim_R_bazooka", "aim_R_handgun", "aim_R_rifle", "angry_fingerwag",
     "angry_tantrum", "away", "backflip", "blowkiss", "bow", "brush", "clap",
     "courtbow", "cross_arms", "crouch", "crouchwalk", "curtsy",
     "dance1", "dance2", "dance3", "dance4", "dance5", "dance6", "dance7", "dance8",
     "dead", "drink", "express_afraid", "express_anger", "express_bored",
     "express_cry", "express_embarrased", "express_laugh", "express_repulsed",
     "express_sad", "express_shrug", "express_surprise", "express_wink",
     "express_worry", "falldown", "female_walk", "fist_pump", "fly", "flyslow",
     "hello", "hold_R_bow", "hold_R_bazooka", "hold_R_handgun", "hold_R_rifle",
     "hold_throw_R", "hover", "hover_down", "hover_up", "impatient",
     "jump", "jumpforjoy", "kick_roundhouse_R", "kissmybutt", "kneel_left",
     "kneel_right", "land", "laugh_short", "motorcycle_sit", "musclebeach", "no_head",
     "no_unhappy", "nyanya", "peace", "point_me", "point_you",
     "prejump", "punch_L", "punch_onetwo", "punch_R",
     "RPS_countdown", "RPS_paper", "RPS_rock", "RPS_scissors",
     "run", "salute", "shoot_L_bow", "shout", "sit", "sit_female", "sit_ground",
     "sit_to_stand", "sleep", "slowwalk", "smoke_idle", "smoke_inhale",
     "smoke_throw_down", "snapshot", "soft_land", "stand", "standup", "stand_1",
     "stand_2", "stand_3", "stand_4", "stretch", "stride", "surf", "sword_strike_R",
     "talk", "throw_R", "tryon_shirt", "turnback_180", "turnleft", "turnright",
     "turn_180", "type", "uphillwalk", "walk", "whisper", "whistle", "wink_hollywood",
     "yell", "yes_happy", "yes_head", "yoga_float"
];


list addChatScripts(list thisList, string name, string value, integer stride)
{
    integer found = llListFindList(thisList, [name]);

    if (0 <= found)
    {
        list values = llParseString2List(llList2String(thisList, found + 1), ["|"], []);

        if (1 == stride)
        {
            integer subFound = llListFindList(values, [value]);

            if (0 > subFound)
                values += [value];
        }
        else
        {
            integer length = llGetListLength(values);
            integer i;

            for (i = 0; i < length; i += stride)
            {
                list sub = llList2List(values, i, i + stride - 1);
                integer subFound = llListFindList(values, [llList2String(sub, 0)]);

                if (0 > subFound)
                    values += sub;
            }
        }
        thisList = llListReplaceList(thisList, [name, llDumpList2String(values, "|")], found, found + 1);
    }
    else
        thisList += [name, value];
    return thisList;
}

list delChatScripts(list thisList, string name, string value, integer stride)
{
    integer found = llListFindList(thisList, [name]);

    if (0 <= found)
    {
        list values = llParseString2List(llList2String(thisList, found + 1), ["|"], []);

        if (1 == stride)
        {
            integer subFound = llListFindList(values, [value]);

            if (0 <= subFound)
                values = llDeleteSubList(values, subFound, subFound);
        }
        else
        {
            integer length = llGetListLength(values);
            integer i;

            for (i = 0; i < length; i += stride)
            {
                list sub = llList2List(values, i, i + stride - 1);
                integer subFound = llListFindList(values, [llList2String(sub, 0)]);

                if (0 <= subFound)
                    values = llDeleteSubList(values, subFound, subFound + stride - 1);
            }
        }
        if (llGetListLength(values))
            thisList = llListReplaceList(thisList, [name, llDumpList2String(values, "|")], found, found + 1);
        else
            thisList = llDeleteSubList(thisList, found, found + 1);
    }
    return thisList;
}

resetPrimShit()
{
    llParticleSystem([]);
// Comment this out for now.  Causes problems with updates, and is probably not needed.
//    llSetRemoteScriptAccessPin(0);
    llSetText("", <1, 1, 1 >, 1.0);
    llSetTextureAnim(FALSE | SMOOTH | LOOP, ALL_SIDES, 1, 1, 0, 0, 0.0);
    llTargetOmega(<0, 0, 0 >, 0, 0);
}

// Get the next word.
// The last parameter is the last word returned from the previous call.
// The list results are -
// 0 = The rest of the text.
// 1 = The next word.
list nextWord(string separator, string message, string last)
{
    list    result = [];
    integer index;

    index = llSubStringIndex(message, separator);
    if (0 <= index)
    {
        if (0 != index)               // Check for a corner case.
            last += llGetSubString(message, 0, index - 1);
        if ((index + 1) < llStringLength(message))
            message = llGetSubString(message, index + 1, -1);
        else
            message = "";
        result += message;
        result += last;
    }
    else
    {
        result += "";
        result += last + message;
    }

    return (result);
}

// Substitute params from a list.
string substitute(list values, string separator)
{
    string  result = "";
    string  original = llList2String(values, 0);
    integer length = llGetListLength(values);

//    integer length = (values != []);  // Speed hack.
    integer index = 1;

    while ((0 <= index) && ("" != original))
    {
        index = llSubStringIndex(original, separator);
        if (0 <= index)
        {
            string  last = separator;
            integer i;

            if (0 != index)           // Check for a corner case.
                result += llGetSubString(original, 0, index - 1);
            if ((index + 2) < llStringLength(original))
            {
                last = llGetSubString(original, index + 1, index + 1);
                original = llGetSubString(original, index + 2, -1);
            }
            else
                original = "";

            for (i = 1; i < length; ++i)
            {
                string  pattern = llList2String(values, i);

                if (llGetSubString(pattern, 0, 0) == last)
                {
                    last = llGetSubString(pattern, 1, -1);
                    i = length;           // A break statement would be nice.
                }
            }
            result += last;
        }
    }

    return result + original;
}

startMenu(key id, list input)
{
    key     menuUser = NULL_KEY;  
    integer menuChannel = -1;
    key     menuScript = NULL_KEY;
    integer menuHandle = 0;
    integer menuType = INVENTORY_NONE;
    string  menuMessage = "";
    list    menu = [];
    list    menuFilter = [];
    integer menuPos = 0;
    integer menuMaxPos = 1;
//            list    menuNames = [];
    integer menuIndex = llGetListLength(menus);

    menuPos = 0;
    menuScript = id;
    menuUser = llList2Key(input, 0);
    menuFilter = llParseStringKeepNulls(llList2String(input, 1), ["|"], []);
    menuType = llList2Integer(menuFilter, 0);
    if (llGetListLength(menuFilter) > 1)
        menuFilter = llList2List(menuFilter, 1, -1);
    else
        menuFilter = [];
    menuMessage = llList2String(input, 2);
    menu = llList2List(input, 3, -1);
    if (NULL_KEY == menuUser)
    {
        // Only add it if it's not there.
        if (-1 == llListFindList(registeredMenus, [menuMessage + "|" + menuScript]))
            registeredMenus += [menuMessage + "|" + menuScript];
        registeredMenus = llListSort(registeredMenus, 1, TRUE);
        return;
    }
    else if (INVENTORY_NONE == menuType)
        menuMaxPos = llGetListLength(menu);
    else if (INVENTORY_ALL == menuType)                     // TODO - NONE and ALL are both -1.  lol
        menuMaxPos = llGetListLength(ANIMATIONS);
    else
    {
        integer i;
        integer j;
        integer number = llGetInventoryNumber(menuType);    // NOTE this may change while we are in the menus.
        integer length = llGetListLength(menuFilter);

        menuMaxPos = 0;
        menu= [];
        for (i = 0; i < number; ++i)
        {
            string name = llGetInventoryName(menuType, i);

            if (length)
            {
                for (j = 0; j < length; ++j)
                {
                    if (osRegexIsMatch(name, llList2String(menuFilter, j)))
                    {
                        ++menuMaxPos;
                        menu += name;
                    }
                }
            }
            else
            {
                ++menuMaxPos;
                menu += name;
            }
        }
    }
    menuChannel = (integer) (llFrand(10000) + 1000);
    menuHandle = llListen(menuChannel, "", menuUser, "");
    menuMaxPos /= 9;
    menuMaxPos *= 9;
    ++menuMaxPos;
    menus += [menuUser, menuChannel, menuScript, menuHandle, menuType, menuMessage, 
                llDumpList2String(menu, LIST_SEP), llDumpList2String(menuFilter, "|"), 
                menuPos, menuMaxPos, "", llGetTime()];
    showMenu(menuIndex);
}

showMenu(integer menuIndex)
{
    key     menuUser    = llList2String (menus, menuIndex + MENU_USER);  
    integer menuChannel = llList2Integer(menus, menuIndex + MENU_CHANNEL);
    key     menuScript  = llList2String (menus, menuIndex + MENU_SCRIPT);
    integer menuHandle  = llList2Integer(menus, menuIndex + MENU_HANDLE);
    integer menuType    = llList2Integer(menus, menuIndex + MENU_TYPE);
    string  menuMessage = llList2String (menus, menuIndex + MENU_MESSAGE);
    list    menu        = llParseString2List(llList2String (menus, menuIndex + MENU_MENU), [LIST_SEP], []);
    list    menuFilter  = llParseString2List(llList2String (menus, menuIndex + MENU_FILTER), ["|"], []);
    integer menuPos     = llList2Integer(menus, menuIndex + MENU_POS);
    integer menuMaxPos  = llList2Integer(menus, menuIndex + MENU_MAXPOS);
    list    menuNames   = [];

    list    thisMenu = [];
    integer length;
    integer i;

    for (i = 0; i < 12; ++i)
    {
        string  name;
        integer index;

        if (INVENTORY_NONE == menuType)
            name = llList2String(menu, menuPos + i);
        else if (INVENTORY_ALL == menuType)
            name = llList2String(ANIMATIONS, menuPos + i);
        else
            name = llList2String(menu, menuPos + i);
//            name = llGetInventoryName(menuType, menuPos + i);

        index = llSubStringIndex(name, "|");
        if (index != -1)
        {
            list parts = llParseStringKeepNulls(name, ["|"], []);
            name = llGetSubString(llList2String(parts, 0) + "                        ", 0, 15)
                    + "|" + llList2String(parts, 1)+ "|" + llList2String(parts, 2);
        }
        if (llStringLength(name) > 24)
        {
            menuNames += [name];
            name = llGetSubString(name, 0, 23);
        }
        // TODO - Only allow blank ones for arbitrary menus, but screws with the showMenu() code.
//        if ((INVENTORY_NONE == menuType) && ("" == name))
//            name = ".";
        if ("" != name)
            thisMenu += [name];
    }

    length = llGetListLength(thisMenu);
    if ((12 > length) && (0 == menuPos))
    {
        integer j = length % 3;
        if (0 == j)
            thisMenu += [".", "Exit", "."];
        else if (1 == j)
        {
            string last = llList2String(thisMenu, -1);
            thisMenu = llDeleteSubList(thisMenu, -1, -1) + [last, "Exit", "."];
        }
        else if (2 == j)
        {
            string penultimate = llList2String(thisMenu, -2);
            string last = llList2String(thisMenu, -1);
            thisMenu = llDeleteSubList(thisMenu, -2, -1) + [penultimate, "Exit", last];
        }
    }
    else if (9 >= length)
        thisMenu += ["<<", "Exit", ">>"];
    else
        thisMenu = llList2List(thisMenu, 0, 8) + ["<<", "Exit", ">>"];

    // Re order them to make LSL happy.
    for (i = 0; i < length; i += 3)
        thisMenu = llListInsertList(llDeleteSubList(thisMenu, -3, -1), llList2List(thisMenu, -3, -1), i);
    llDialog(menuUser, menuMessage, thisMenu, menuChannel);
    menus = llListReplaceList(menus,
                [
                    menuUser, menuChannel, menuScript, menuHandle, menuType, menuMessage, 
                    llDumpList2String(menu, LIST_SEP), llDumpList2String(menuFilter, "|"), 
                    menuPos, menuMaxPos, llDumpList2String(menuNames, LIST_SEP), llGetTime()
                ], menuIndex, menuIndex + MENU_STRIDE - 1);
}

myListen(integer channel, string name, key id, string message)
{
    // check if this message came from an object or avatar, 
    // use the objects owner if it came from an object.
    // Avatars own themselves. B-)
    key realId = llGetOwnerKey(id);
    integer menuIndex = llListFindList(menus, [realId, channel]);

    if (0 <= menuIndex)  // Menu response
    {
        key     menuUser    = llList2String (menus, menuIndex + MENU_USER);  
        integer menuChannel = llList2Integer(menus, menuIndex + MENU_CHANNEL);
        key     menuScript  = llList2String (menus, menuIndex + MENU_SCRIPT);
        integer menuHandle  = llList2Integer(menus, menuIndex + MENU_HANDLE);
        integer menuType    = llList2Integer(menus, menuIndex + MENU_TYPE);
        string  menuMessage = llList2String (menus, menuIndex + MENU_MESSAGE);
        list    menu        = llParseString2List(llList2String (menus, menuIndex + MENU_MENU), [LIST_SEP], []);
        list    menuFilter  = llParseString2List(llList2String (menus, menuIndex + MENU_FILTER), ["|"], []);
        integer menuPos     = llList2Integer(menus, menuIndex + MENU_POS);
        integer menuMaxPos  = llList2Integer(menus, menuIndex + MENU_MAXPOS);
        list    menuNames   = llParseString2List(llList2String (menus, menuIndex + MENU_NAMES), [LIST_SEP], []);
        integer delete      = FALSE;

        if ("<<" == message)
        {
            menuPos -= 9;
            if (menuPos < 0)
                menuPos = menuMaxPos - 1;
        }
        else if (">>" == message)
        {
            menuPos += 9;
            if (menuPos > (menuMaxPos - 1))
                menuPos = 0;
        }
        else if ("." == message)
            delete = TRUE;
        else
        {
            delete = TRUE;
            if (menuHandle)
                llListenRemove(menuHandle);
            if (llStringLength(message) == 24)
            {
                integer i;
                integer length = llGetListLength(menuNames);

                for (i = 0; i < length; ++i)
                {
                    string  lName = llList2String(menuNames, i);

                    if (message == llGetSubString(lName, 0, 23))
                        message = lName;
                }
            }

            if (NULL_KEY == menuScript)
            {
                menuScript = (key) llList2String(llParseStringKeepNulls(message, ["|"], []), 2);
                message = "";
            }
            llMessageLinked(LINK_SET, UTILITIES_MENU_DONE, llDumpList2String([menuUser, message], LIST_SEP), menuScript);
        }
        if (delete)
            menus = llDeleteSubList(menus, menuIndex, menuIndex + MENU_STRIDE - 1);
        else
        {
            menus = llListReplaceList(menus,
                        [
                            menuUser, menuChannel, menuScript, menuHandle, menuType, menuMessage, 
                            llDumpList2String(menu, LIST_SEP), llDumpList2String(menuFilter, "|"), 
                            menuPos, menuMaxPos, llDumpList2String(menuNames, LIST_SEP), llGetTime()
                        ], menuIndex, menuIndex + MENU_STRIDE - 1);
            showMenu(menuIndex);
        }
    }
    else  // Chat command.
    {
        list    scripts = [];
        list    words = [];
        string  prefix = "";
        string  command = "";
        string  idChannel = (string) realId + (string) channel;
        integer thisOwner = llListFindList(chatOwners, [idChannel]);

//llOwnerSay("->>" + (string) channel + " " + message);

//llOwnerSay("owners    " + llDumpList2String(chatOwners, "^"));
//llOwnerSay("channels  " + llDumpList2String(chatChannels, "^"));
//llOwnerSay("prefixes  " + llDumpList2String(chatPrefixes, "^"));
//llOwnerSay("prefixes2 " + llDumpList2String(chatPrefixes2, "^"));
//llOwnerSay("commands  " + llDumpList2String(chatCommands, "^"));
        if (0 <= thisOwner)
            scripts = llParseString2List(llList2String(chatOwners, thisOwner + 1), ["|"], []);
        else
        {
            integer thisChannel = llListFindList(chatChannels, [(string) channel]);

            if (0 <= thisChannel)
                scripts = llParseString2List(llList2String(chatChannels, thisChannel + 1), ["|"], []);
        }
//llOwnerSay(llDumpList2String(scripts, "|"));
        if ([] != scripts)
        {
            integer thisPrefix;
            string candidate;

            words = llParseString2List(message, [" "], []);
            candidate = llList2String(words, 0);
            thisPrefix = llListFindList(chatPrefixes, [(string) channel + " " + candidate]);
//llOwnerSay(llDumpList2String(words, "~"));
//llSay(0, candidate);
//llSay(0, (string) thisPrefix);
            if (0 <= thisPrefix)
            {
                prefix = candidate;
                scripts = llParseString2List(llList2String(chatPrefixes, thisPrefix + 1), ["|"], []);
                words = llList2List(words, 1, -1);
            }
            else
            {
                integer length = llGetListLength(chatPrefixes2);
                integer i;

                for (i = 0; i < length; i += 2)
                {
                    string pName = llList2String(chatPrefixes2, i);
                    integer pLength = llStringLength(pName);

                    if (pName == ((string) channel + " " + llGetSubString(candidate, 0, pLength)))
                    {
//                        prefix = pName;
                        prefix = candidate;
                        scripts = llParseString2List(llList2String(chatPrefixes2, i + 1), ["|"], []);
//                        words = [llGetSubString(candidate, pLength + 1, -1)] + llList2List(words, 1, -1);
                        words = llList2List(words, 1, -1);
                        i = length;
                    }
                }
            }
        }
//llOwnerSay(llDumpList2String(scripts, "|"));
//llSay(0, prefix);

        // Finally found it, process it.
        if ([] != scripts)
        {
            integer length = llGetListLength(scripts);
            integer wordLength = llGetListLength(words);
            integer i;

            // Wont put up with laggy scripts.  Use a prefix if you insist on using local chat.
//            if ((0 == channel) && ("" == prefix))
//            return;

            // The problem with this loop is that if a bunch of scripts are wanting the same commands, 
            // then it's not efficient.  In the expected use cases, that should not me much of a problem.
            for (i = 0; i < length; ++i)
            {
                string  script = llList2String(scripts, i);
                integer theseCommands = llListFindList(chatCommands, [script + (string) channel]);

                if (0 <= theseCommands)
                {
                    list commands = llParseStringKeepNulls(llList2String(chatCommands, theseCommands + 1), ["|"], []);
                    integer thisCommand = llListFindList(commands, [llList2String(words, 0)]);
//llOwnerSay(llDumpList2String(words, "~"));
//llOwnerSay(llDumpList2String(commands, "~"));
//llSay(0, (string) thisCommand);

                    if (0 != (thisCommand % 2))
                        thisCommand = -1;
                    if (0 <= thisCommand)
                    {
                        list result = [channel, name, realId, message, prefix, llList2String(commands, thisCommand)];
                        string argsTypes  = llList2String(commands, thisCommand + 1);
                        integer argsLength = llStringLength(argsTypes);
                        integer required = 0;
                        integer optional = 0;
                        integer multiple = -1;
//                        integer oldStyle = FALSE;

                        if (0 < argsLength)    // Arguments expected.
                        {
                            required = (integer) llGetSubString(argsTypes, 0, 0);
                            optional = (integer) llGetSubString(argsTypes, 1, 1);

                            {
                                list arguments = [];    // type, required, extra
                                integer a;
                                integer argsCount = 0;
                                integer w = 1;

                                for (a = 0; a < argsLength; a++)
                                {
                                    string type = llGetSubString(argsTypes, a, a);
                                    string TYPE = llToUpper(type);
                                    integer isNeeded = (TYPE == type);
                                    string extra = "";
                                    
                                    if (isNeeded)
                                        ++required;
                                    else
                                        ++optional;
                                    // Sort out the extra string for those that support it.
                                    if (("C" == TYPE) || ("X" == TYPE))
                                    {
                                        string subbie = llGetSubString(argsTypes, a + 1, -1);
                                        integer comma = llSubStringIndex(subbie, ",");

                                        if (-1 == comma)
                                        {
                                            extra = llGetSubString(argsTypes, a + 1, -1);
                                            a = argsLength;
                                        }
                                        else
                                        {
                                            extra = llGetSubString(argsTypes, a + 1, a + 1 + comma - 1);
                                            a += comma + 1;
                                        }
                                    }
                                    arguments += [TYPE, isNeeded, extra];
                                    ++argsCount;
                                }
                                for (a = 0; a < argsCount; ++a)
                                {
                                    string TYPE         = llList2String (arguments, (a * 3) + 0);
                                    integer isNeeded    = llList2Integer(arguments, (a * 3) + 1);
                                    string extra        = llList2String (arguments, (a * 3) + 2);
                                    string value        = "";

    // a animation, b bodypart, clothing, g gesture, m landmark, o object, sound, t texture.
    // c notecard, x script, Extension is what follows up to the next comma, or end of line.
    // f float, i integer, k key, r rotation, s rest of string, v vector.
    // n name of avatar or NPC.  Full two word variety, no other checking done.
    // l local name, could be just first or last name, but they need to be in the sim.
                                    if ("F" == TYPE)
                                        value = (string) llList2Float(words, w);
                                    else if ("I" == TYPE)
                                        value = (string) llList2Integer(words, w);
                                    else if ("K" == TYPE)
                                        value = (key) llList2String(words, w);
                                    else if (("R" == TYPE) || ("V" == TYPE))
                                    {
                                        string next = llList2String(words, w);

                                        if ("<" == llGetSubString(next, 0, 0))
                                        {
                                            integer l;

                                            for (l = 0; (w + l) < wordLength; ++l)
                                            {
                                                value += next;
                                                if (">" == llGetSubString(value, -1, -1))
                                                {
                                                    w += l;
                                                    l = wordLength;     // BREAK!
                                                }
                                                if (("V" == TYPE) && (3 <= l))
                                                    l = wordLength;     // BREAK!
                                                else if (("R" == TYPE) && (4 <= l))
                                                    l = wordLength;     // BREAK!
                                                next = llList2String(words, w + 1 + l);
                                            }
                                            if (">" != llGetSubString(value, -1, -1))   // Seems OpenSim at least can cast partial vectors.
                                                value = "";
                                            if ("V" == TYPE)
                                            {
                                                vector v = (vector) value;
                                                value = (string) v;
                                            }
                                            else if ("R" == TYPE)
                                            {
                                                rotation r = (rotation) value;
                                                value = (string) r;
                                            }
                                        }
                                    }
                                    else if ("L" == TYPE)
                                    {
                                        string first = llList2String(words, w);
                                        string last = llList2String(words, w + 1);

                                        if (osIsUUID(first))
                                            value = first;
                                        else if ("" != last)
                                        {
                                            list avatars = [llGetOwner(), ZERO_VECTOR, llKey2Name(llGetOwner())] + osGetAvatarList();   // Strided list, UUID, position, name.
                                            integer avaLength = llGetListLength(avatars);
                                            string aName = llToLower(first + " " + last);
                                            integer n;

                                            for (n = 0; n < avaLength; n +=3)
                                            {
                                                if (llToLower(llList2String(avatars, n + 2)) == aName)
                                                {
                                                    value = llKey2Name(llList2String(avatars, n));
                                                    ++w;
                                                    n = avaLength;      // BREAK!
                                                }
                                            }
                                        }
                                        if (("" == value) && ("" != first))   // Try scanning the sim for a matching first or last name.
                                        {
                                            list candidates = [];
                                            list avatars = [llGetOwner(), ZERO_VECTOR, llKey2Name(llGetOwner())] + osGetAvatarList();   // Strided list, UUID, position, name.
                                            integer avaLength = llGetListLength(avatars);
                                            integer n = llSubStringIndex(first, "'");

                                            // Check if we are searching for multiples.
                                            // There can be only one multiple, and it should be the first, 
                                            // so skip multiples checking if multiple is set already.
                                            if ((-1 != n) && (-1 == multiple))
                                            {
                                                multiple = a;
                                                first = llGetSubString(first, 0, n - 1);
                                            }
                                            last = llToLower(first);
                                            for (n = 0; n < avaLength; n +=3)
                                            {
                                                list names = llParseString2List(llToLower(llList2String(avatars, n + 2)), [" "], []);

                                                if ((llList2String(names, 0) == last) || (llList2String(names, 1) == last))
                                                    candidates += [llList2String(avatars, n)];
                                            }
                                            avaLength = llGetListLength(candidates);
                                            if (0 == avaLength)
                                                llSay(0, "No one matching the name " + first + " here.");
                                            else if ((1 < avaLength) && (-1 == multiple))
                                                llSay(0, "More than one matching the name " + first + " here.");
                                            else if  (-1 != multiple)
                                                value = llDumpList2String(candidates, "|");
                                            else
                                                value = llKey2Name(llList2String(candidates, 0));
                                        }
                                    }
                                    else if ("N" == TYPE)
                                    {
                                        string first = llList2String(words, w);
                                        string last = llList2String(words, w + 1);

                                        if (osIsUUID(first))
                                            value = first;
                                        else if ("" != last)
                                        {
                                            value = first + " " + last;
                                            ++w;
                                        }
                                    }
                                    else  // The rest are "rest of string".
                                    {
                                        if (w < wordLength)
                                            result += [llDumpList2String(llList2List(words, w, -1), " ")];
                                        w = wordLength;
                                    }
                                    result += [value];
                                    ++w;
                                    if (w > wordLength)
                                        a = argsCount;     // BREAK!
                                }

                                // Put the rest of the words back together as "rest of message".
                                if (w < wordLength)
                                    result += [llDumpList2String(llList2List(words, w, -1), " ")];
//llSay(0, "ARGUMENTS for " + llList2String(words, 0) + " = " + llDumpList2String(arguments, "|"));
//llSay(0, "RESULTS " + llDumpList2String(result, "~"));
                            }
                        }

                        if ((1 + required) > wordLength)
                        {
                            // bitch
                            if (id != realId)
                                llInstantMessage(realId, "Not enough required arguments in a command from your object " + llKey2Name(id) + "  The command was - " + message);
                            else
                                llInstantMessage(realId, "Not enough required arguments in your command.  The command was - " + message);
                        }
                        else
                        {
                            // RETURNS incoming channel | incoming name | incoming key | incoming message | prefix | command | list of arguments | rest of message
                            if  (-1 != multiple)
                            {
                                list candidates = llParseString2List(llList2String(result, 6 + multiple), ["|"], []);
                                integer candiLength = llGetListLength(candidates);
                                integer c;

                                for (c = 0; c < candiLength; ++c)
                                {
                                    result = llListReplaceList(result, [llList2String(candidates, c)], 6 + multiple, 6 + multiple);
                                    llMessageLinked(LINK_SET, UTILITIES_CHAT_DONE, llDumpList2String(result, LIST_SEP), (key) script);
                                }
                            }
                            else
                                llMessageLinked(LINK_SET, UTILITIES_CHAT_DONE, llDumpList2String(result, LIST_SEP), (key) script);
                        }
                    }
                }
            }
        }
    }
}

startNextRead()
{
    if (0 < llGetListLength(settingsCards))
    {
        settingsName = llList2String(settingsCards, 0);
        settingsKey  = llList2Key(settingsCards, 1);
        settingsLine = 0;
        settingsQueryID = llGetNotecardLine(settingsName, settingsLine);    // request first line
        settingsCards = llDeleteSubList(settingsCards, 0, 1);
    }
    else
    {
        settingsName = ".settings";
        settingsKey = NULL_KEY;
        settingsQueryID = NULL_KEY;
    }
}

list readThisLine(string data)
{
    list result = [];

    data = llStringTrim(data, STRING_TRIM);
    if ((0 < llStringLength(data)) && ("#" != llGetSubString(data, 0, 0)))
    {
        list    commands    = llParseStringKeepNulls(data, [";"], []);
        list    new        = [];
        string  newCommand    = "";
        integer length    = llGetListLength(commands);
        integer i;

        for (i = 0; i < length; ++i)
        {
            string  command = llList2String(commands, i);

            // Check for line continuation.  I think.  lol
            if ("\\" == llGetSubString(command, -1, -1))
                newCommand += llGetSubString(command, 0, -2) + ";";
            else
            {
                command = llStringTrim(newCommand + command, STRING_TRIM);
                if (0 < llStringLength(command))
                    new += [command];
                newCommand = "";
            }
//llOwnerSay("|" + newCommand + "|" + command + "|");
        }

        length = llGetListLength(new);
        for (i = 0; i < length; ++i)
        {
            string  name;
            string  value = llList2String(new, i);
            integer equals = llSubStringIndex(value, "=");

            name = "";
            if (0 <= equals)
            {
                name = llStringTrim(llGetSubString(value, 0, equals - 1), STRING_TRIM_TAIL);
                if ((equals + 1) < llStringLength(value))
                    value = llStringTrim(llGetSubString(value, equals + 1, -1), STRING_TRIM_HEAD);
                else
                    value = "";
            }
            else
            {
                name = value;
                value = "";
            }
            result += [name, value];
        }
    }
    ++settingsLine;
    return result;
}

init()
{
    llMessageLinked(LINK_SET, UTILITIES_RESET_DONE, "", llGetInventoryKey(llGetScriptName()));
    // Pointless in OpenSim, always reports 16384.  Pffft
    //llOwnerSay("Free memory " + (string) llGetFreeMemory() + " in " + llGetScriptName());
    llSetTimerEvent(MENU_TIMEOUT);
}


default
{
    state_entry()
    {
        init();
    }

    on_rez(integer param)
    {
        init();
    }

    attach(key attached)
    {
        init();
    }

    listen(integer channel, string name, key id, string message)
    {
        myListen(channel, name, id, message);
    }

    // Handle commands from other scripts.
    // Negative odd values of num are the commands, return num - 1 as the result.
    link_message(integer sender_num, integer num, string value, key id)
    {
        list    input = llParseStringKeepNulls(value, [LIST_SEP], []);

        if (UTILITIES_RESET == num)           // Request stuff to be reset
        {
            if ("reset" == value)               // Request us to be reset.
                llResetScript();
            resetPrimShit();
            llMessageLinked(LINK_SET, num - 1, value, id);
        }
        else if (UTILITIES_READ == num)     // Request a notecard to be read.
        {
            list result = [];
            integer length = osGetNumberOfNotecardLines(value);

            settingsLine = 0;
            while (settingsLine <= length)
            {
                result += readThisLine(osGetNotecardLine(value, settingsLine));
                if (0 == (settingsLine % 500))   // Don't send too many at once.
                {
                    integer percent = (integer) ((((float) settingsLine) / ((float) length)) * 100.0);

                    llSay(0, "Reading '" + value + "' " + (string) percent + "% done.");
                    // Sending a negative line to try to avoid triggering foreign scripts.
                    // Sending from -1000 downwards to avoid triggering our scripts.
                    llMessageLinked(LINK_SET, -1000 - settingsLine, llDumpList2String([value] + result, LIST_SEP), id);
                    result = [];
                }
            }
            // Send the last batch.
            if (0 != llGetListLength(result))
                llMessageLinked(LINK_SET, -1000 - settingsLine, llDumpList2String([value] + result, LIST_SEP), id);
            llMessageLinked(LINK_SET, UTILITIES_READ_DONE, value, id);
        }
        else if (UTILITIES_SUBSTITUTE == num)    // Request a param substitution.
        {
            llMessageLinked(LINK_SET, num - 1, substitute([substitute(input, "%"), "n\n", "t\t", "\\\\", "\"\""], "\\"), id);
        }
        else if (UTILITIES_NEXT_WORD == num)    // Get the next word
        {
            llMessageLinked(LINK_SET, num - 1, llDumpList2String(nextWord(llList2String(input, 0), llList2String(input, 1), llList2String(input, 2)), LIST_SEP), id);
        }
        else if (UTILITIES_MENU == num)     // Request big menu to be displayed
        {
            startMenu(id, input);
        }
        else if (UTILITIES_CHAT == num)
        {
            // channel list | owner list | prefix list | command list
            list channels = llParseString2List(llList2String(input, 0), ["|"], []);
            list owners   = llParseString2List(llList2String(input, 1), ["|"], []);
            list prefixes = llParseString2List(llList2String(input, 2), ["|"], []);
            string  commands = llList2String(input, 3);
            integer chLength = llGetListLength(channels);
            integer i;

            for (i = 0; i < chLength; ++i)
            {
                string  channel = llList2String(channels, i);
                integer j;

                if ("" != commands)
                {
//llSay(0, "ADDING " + channel + "= " + commands);
                    integer oLength = llGetListLength(owners);
                    integer pLength = llGetListLength(prefixes);
                    integer found = llListFindList(channelHandles, [channel]);

                    if ("0" == channel)
                        llOwnerSay("WARNING: Script using local chat for commands may cause lag - " + llKey2Name(id));
                    chatChannels = addChatScripts(chatChannels, channel, (string) id, 1);
                    chatCommands = addChatScripts(chatCommands, (string) id + channel, commands, 2);
                    for (j = 0; j < oLength; ++j)
                        chatOwners = addChatScripts(chatOwners, llList2String(owners, j) + channel, (string) id, 1);

                    for (j = 0; j < pLength; ++j)
                    {
                        string  prefix = llList2String(prefixes, j);

                        if (" " == llGetSubString(prefix, -1, -1))
                            chatPrefixes = addChatScripts(chatPrefixes, channel + " " + llGetSubString(prefix, 0, -2), (string) id, 1);
                        else
                            chatPrefixes2 = addChatScripts(chatPrefixes2, channel + " " + prefix, (string) id, 1);
                    }

                    // Do this last, so all the rest is setup already.
                    if (0 > found)
                    {
//llOwnerSay("LISTEN " + channel + " " + llList2String(owners, j));
// TODO - Closing and reopening that channel if details change.
                        // NOTE - only the FIRST owner is supported.
                        // TODO - this is not right anyway.  
                        //   If a channel gets more than one owner from different invocations of this command,
                        //   then it should re open the listener.
                        if (1 == oLength)
                            channelHandles += [channel, llListen((integer) channel, "", llList2Key(owners, 0), "")];
                        else
                            channelHandles += [channel, llListen((integer) channel, "", NULL_KEY, "")];
                    }
                }
                else // if ("" != commands)
                {
                   integer index = llListFindList(chatCommands, [(string) id + channel]);
                    // Yes, I know, UUIDs are a fixed length, but there's talk of using SHA1 hashes instead.
                    integer keyLength = llStringLength((string) id);
                    integer length;
                    
                    chatChannels = delChatScripts(chatChannels, channel, (string) id, 1);
                    if (0 <= index)
                        chatCommands = llDeleteSubList(chatCommands, index, index + 1);

                    length = llGetListLength(chatOwners);
                    for (j = 0; j < length; j += 2)
                    {
                        string this = llList2String(chatOwners, j);

                        if (llGetSubString(this, keyLength, -1) == channel)
                            chatOwners = delChatScripts(chatOwners, this, (string) id, 1);
                    }

// TODO - go through chatPrefixes/2 removing script from any on this channel

                    if (0 > llListFindList(chatChannels, [channel]))
                    {
                        length = llGetListLength(channelHandles);
                        for (j = 0; j < length; j += 2)
                        {
                            if (llList2String(channelHandles, j) == channel)
                            {
                                llListenRemove(llList2Integer(channelHandles, j + 1));
                                channelHandles = llDeleteSubList(channelHandles, j, j + 1);
                                length -= 2;
                                j -= 2;
                            }
                        }
                    }
//llOwnerSay("owners    " + llDumpList2String(chatOwners, "^"));
//llOwnerSay("channels  " + llDumpList2String(chatChannels, "^"));
//llOwnerSay("prefixes  " + llDumpList2String(chatPrefixes, "^"));
//llOwnerSay("prefixes2 " + llDumpList2String(chatPrefixes2, "^"));
//llOwnerSay("commands  " + llDumpList2String(chatCommands, "^"));
                } // if ("" != commands)
            } // for (i = 0; i < chLength; ++i)

        }
        else if (UTILITIES_CHAT_FAKE == num)
        {
            myListen(llList2Integer(input, 0), llList2String(input, 1), llList2Key(input, 2), llList2String(input, 3));
        }
    }

    touch_start(integer num)
    {
        integer length = llGetListLength(registeredMenus);
        integer i;

        // Scan through the list, checking if those scripts still exist in inventory.
        for (i = length - 1; i >= 0; --i)
        {
            string this = llList2String(llParseStringKeepNulls(llList2String(registeredMenus, 0), ["|"], []), 1);

            if (INVENTORY_NONE == llGetInventoryType(this))
            {
                registeredMenus = llDeleteSubList(registeredMenus, i, i);
                --length;
            }
        }
        for (i = 0; i < num; ++i)
        {
            key id = llDetectedKey(i);
            string desc = llList2String(llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(i)), [OBJECT_DESC]), 0);

            // If there's a description, then it's likely a scriptlet.
            // TODO - need a new way to do this, ANY description makes menus not work.
            if (("" != desc) && (" " != desc))
                myListen(0, llKey2Name(id), id, desc);  // TODO - the problem here is that the first argument is a channel,
                                                        // and we don't know which channel to fake.
                                                        // Maybe use the debug channel as a wildcard?
            else if (1 == length)       // Only one registered, select it directly.
            {
                llMessageLinked(LINK_SET, UTILITIES_MENU_DONE, llDumpList2String([id, ""], LIST_SEP), 
                    llList2String(llParseStringKeepNulls(llList2String(registeredMenus, 0), ["|"], []), 2));
            }
            else if (0 != length)       // More than one, put up a menu of them.
                startMenu(NULL_KEY, [id, INVENTORY_NONE, "Choose a function :"] + registeredMenus);
            // If there's zero registered menus, then do nothing.
        }
    }

    timer()
    {
        integer length = llGetListLength(menus);
        float time = llGetTime();
        integer i;

        // Run through menus, removing any that timed out.
        for (i = 0; i < length; i += MENU_STRIDE)
        {
            if (time > (llList2Float(menus, i + MENU_TIME) + MENU_TIMEOUT))
            {
                integer menuHandle  = llList2Integer(menus, i + MENU_HANDLE);

                llSay(0, "Menu for " + llKey2Name(llList2String(menus, i + MENU_USER)) + " timed out.");
                if (menuHandle)
                    llListenRemove(menuHandle);
                menus = llDeleteSubList(menus, i, i + MENU_STRIDE - 1);
                length = llGetListLength(menus);
                i -= MENU_STRIDE;
            }
        }
    }
}
