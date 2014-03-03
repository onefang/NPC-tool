// Onefang's general purpose NPC tool version 1.0.
// Requires onefang's utilities script.

// Copyright (C) 2013 David Seikel (onefang rejected).
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

// This is bad listening for commands on channel 0.
integer commandChannel = 0;

list attention = [];    // npc key or script number, listen handle, list of attentive NPCs
integer ATTENT_KEY      = 0;
integer ATTENT_HANDLE   = 1;
integer ATTENT_NPCS     = 2;
integer ATTENT_STRIDE   = 3;

list chatters = [];   // npc key, chat type, listen handle.  In channel order.
integer CHAT_KEY    = 0;
integer CHAT_TYPE   = 1;
integer CHAT_HANDLE = 2;
integer CHAT_STRIDE = 3;

list followers = [];   // npc key, stalkee key, distance vector
integer FOLLOW_KEY      = 0;
integer FOLLOW_STALK    = 1;
integer FOLLOW_DIST     = 2;
integer FOLLOW_STRIDE   = 3;

list movers = [];   // npc key, destination position, least distance, timestamp
integer MOVE_KEY    = 0;
integer MOVE_DEST   = 1;
integer MOVE_LEAST  = 2;
integer MOVE_TIME   = 3;
integer MOVE_STRIDE = 4;

float scriptTick = 0.5;
float lastTick = -1.0;
list scripts = [];   // user key, script card name, flags, command list LIST_SEP separated
integer SCRIPTS_KEY      = 0;
integer SCRIPTS_NAME     = 1;
integer SCRIPTS_FLAGS    = 2;
integer SCRIPTS_COMMANDS = 3;
integer SCRIPTS_STRIDE   = 4;

// Script flags.
integer SCRIPT_READING      = 1;
integer SCRIPT_ATTENTION    = 2;

list  sensorRequests = [];  // name to search for, type of search, command, user key, npc key
integer sensorInFlight = FALSE;

integer recording = FALSE;
list record = [];   // recorded commands

float restartTimer = -1.0;

// NPC commands.
string NPC_ANIMATE  = "animate";    // NPC name, animation name
string NPC_ATTENTION= "attention";  // NPC name.
string NPC_CHANGE   = "change";     // NPC name, NPC (notecard) name.
string NPC_CLONE    = "clone";      // Avatar's name.
string NPC_COME     = "come";       // NPC name.
string NPC_COMPLETE = "complete";   // NPC name.
string NPC_CREATE   = "create";     // NPC (notecard) name, (optional) position vector.
string NPC_DELETE   = "delete";     // NPC name.
string NPC_DISMISSED= "dismissed";  // NPC name.
string NPC_FOLLOW   = "follow";     // NPC name, (optional) distance (float or vector).
string NPC_FLY      = "fly";        // NPC name, position vector or object/agent name/key.
string NPC_GO       = "go";         // NPC name, position vector or object/agent name/key.
string NPC_LAND     = "land";       // NPC name, position vector or object/agent name/key.
string NPC_LINK     = "link";       // Link number, number, string, (optional) key
string NPC_LISTEN   = "listen";     // new command channel
string NPC_LOCATE   = "locate";     // NPC name
string NPC_NUKE     = "nuke";       // No arguments.
string NPC_ROTATE   = "rotate";     // NPC name, Z rotation in degrees.
string NPC_SAY      = "say";        // NPC name, thing to say, or relay channel.
string NPC_SCRIPT   = "script";     // Script notecard name.
string NPC_SHOUT    = "shout";      // NPC name, thing to shout, or relay channel.
string NPC_SIT      = "sit";        // NPC name, object to sit on.
string NPC_SLEEP    = "sleep";      // Seconds.
string NPC_STALK    = "stalk";      // NPC name, avatar name, (optional) distance (float or vector).
string NPC_STAND    = "stand";      // NPC name.
string NPC_STOP     = "stop";       // NPC name.
string NPC_STOPANIM = "stopanim";   // NPC name, animation name
string NPC_TOUCH    = "touch";      // NPC name, object to touch.
string NPC_WHISPER  = "whisper";    // NPC name, thing to whisper, or relay channel.

string NPC_MAIN     = "Main";
string NPC_PICK     = "Pick";
string NPC_NPC      = "NPC";
string NPC_RELAY    = "Relay";

// LSL allows setting variables at this level to the values of previously declared variables.
// But the OpenSim script engine developer had other ideas.
// Otherwise we would not need this duplication.
list OUR_COMMANDS = ["0", "", "", ""
    + "animate|LA|"
    + "attention|L|"
    + "change|LC.avatar|"
    + "clone|L|"
    + "come|L|"
//    "complete|L|" a script only command handled outside the usual system.
    + "create|Nv|"  // Yes first argument should be C, but we want an NPC name anyway.
    + "delete|L|"
    + "dismissed|L|"
    + "follow|Ls|"  // Just ask for a string second argument, sort them out when they get here.
    + "fly|Ls|"     // Just ask for a string second argument, sort them out when they get here.
    + "go|Ls|"      // Just ask for a string second argument, sort them out when they get here.
    + "land|Ls|"    // Just ask for a string second argument, sort them out when they get here.
    + "link|IISk|"  // TODO - the system can't handle that k on the end yet.
    + "listen|I|"
    + "locate|L|"
    + "nuke||"
    + "rotate|LF|"
    + "say|Ls|"     // Just ask for a string second argument, sort them out when they get here.
    + "script|X.npc|"
    + "shout|Ls|"   // Just ask for a string second argument, sort them out when they get here.
    + "sit|Ls|"
    + "sleep|F|"
    + "stalk|LLs|"  // Just ask for a string second argument, sort them out when they get here.
    + "stand|L|"
    + "stop|L|"
    + "stopanim|LA|"
    + "touch|LS|"
    + "whisper|Ls|" // Just ask for a string second argument, sort them out when they get here.
    ];

// When sending multiple commands, some don't need to be expanded.
list OUR_COMMANDS_NONAMES = ["attention", "create", "link", "listen", "nuke", "script", "sleep"];

integer IS_NPC;
integer IS_BOTH;
integer OBJECT;

vector STALK_DISTANCE = <-3.0, 0.0, 0.0>;
integer SIM_CHANNEL = -65767365;

string NPC_NPC_EXT = ".avatar";
string NPC_SCRIPT_EXT = ".npc";
string NPC_BACKUP_CARD = "Restore";
string NPC_RECORD_CARD = "Recorded";
string NPC_TEMP_CARD = "Temporary";

integer NPC_RECORD      = -100;
integer NPC_RECORD_STOP = -101;
integer NPC_NEW_NPC     = -102;
integer NPC_ADD_CHATTER = -103;
integer NPC_DEL_CHATTER = -104;


// Stuff for onefangs common utilities.
key     scriptKey;

string  UTILITIES_SCRIPT_NAME       = "onefang's utilities";
string  LIST_SEP                    = "$!#";           // Used to seperate lists when sending them as strings.
integer UTILITIES_RESET             = -1;
integer UTILITIES_RESET_DONE        = -2;
integer UTILITIES_READ              = -3;
integer UTILITIES_READ_DONE         = -4;
integer UTILITIES_SUBSTITUTE        = -5;
integer UTILITIES_SUBSTITUTE_DONE   = -6;
integer UTILITIES_NEXT_WORD         = -7;
integer UTILITIES_NEXT_WORD_DONE    = -8;
integer UTILITIES_PAYMENT_MADE      = -9;
integer UTILITIES_PAYMENT_MADE_DONE = -10;
integer UTILITIES_MENU              = -11;
integer UTILITIES_MENU_DONE         = -12;
integer UTILITIES_WARP              = -13;
integer UTILITIES_WARP_DONE         = -14;
integer UTILITIES_AVATAR_KEY        = -15;
integer UTILITIES_AVATAR_KEY_DONE   = -16;
integer UTILITIES_CHAT              = -17;
integer UTILITIES_CHAT_DONE         = -18;
integer UTILITIES_CHAT_FAKE         = -19;
integer UTILITIES_CHAT_FAKE_DONE    = -20;


integer checkChat(key npc, string message, integer type, key newNpc)
{
    // Check if it's a single word.
    if (-1 == llSubStringIndex(message, " "))
    {
        integer channel = (integer) message;

        // Check if it's a sane number.
        if ((message == (string) channel) && (channel < 12))
        {
            integer old    = llListFindList(chatters, [npc]);

            if (NULL_KEY != newNpc)
                chatters = llListReplaceList(chatters, [newNpc], old, old);
            else
            {
                // We are using llList2String here, coz the above find might return -1, and only llList2String can handle that.
                key     oldNpc = (key)     llList2String(chatters, old + CHAT_KEY);
                integer oldType   = (integer) llList2String(chatters, old + CHAT_TYPE);
                integer handle = (integer) llList2String(chatters, old + CHAT_HANDLE);

                // No matter what, remove the old one for this NPC.
                if (-1 != old)
                {
                    llListenRemove(handle);
                    chatters = llListReplaceList(chatters, ["", 0, 0], old, old + CHAT_STRIDE - 1);
                }
                if (0 < channel)
                {
                    handle = (integer) llList2String(chatters, (channel * CHAT_STRIDE) + CHAT_HANDLE);
                    if (handle)
                        llListenRemove(handle);
                    handle = llListen(channel, "", NULL_KEY, "");
                    chatters = llListReplaceList(chatters, [npc, type, handle], channel * CHAT_STRIDE, (channel * CHAT_STRIDE) + CHAT_STRIDE - 1);
                    llMessageLinked(LINK_SET, NPC_ADD_CHATTER, npc + "|" + (string) channel, scriptKey);
                }
                else
                    llMessageLinked(LINK_SET, NPC_DEL_CHATTER, npc, scriptKey);
            }
            return TRUE;
        }
    }

    if (NULL_KEY != npc)
    {
        string command = "#";

        if (0 == type)          {command = "whisper";   osNpcWhisper(npc, 0, message);}
        else if (1 == type)     {command = "say";       osNpcSay(npc, message);}
        else if (2 == type)     {command = "shout";     osNpcShout(npc, 0, message);}
        if (recording)
            recordIt(command, [llKey2Name(npc), message]);
    }
    return FALSE;
}

startSensor(key user, key npc, string name, integer type, string command)
{
    sensorRequests += [name, type, command, user, npc];
    nextSensor();
}

nextSensor()
{
    if (sensorInFlight)
        return;
    if (0 < llGetListLength(sensorRequests))
    {
        string  name    = llList2String(sensorRequests, 0);
        integer type    = llList2Integer(sensorRequests, 1);
        string  command = llList2String(sensorRequests, 2);
        key     user    = llList2String(sensorRequests, 3);
        key     npc     = llList2String(sensorRequests, 4);

        sensorInFlight = TRUE;
        llSensor(name, "", type, 1024.0, TWO_PI);
    }
}

integer newScript(key user, string name)
{
    integer i;
    integer length = llGetListLength(scripts);

    if (NULL_KEY == llGetInventoryKey(name))
    {
        llSay(0, "No such script notecard - " + name);
        return -1;
    }
    // Scan one past the end, so that if there's no free ones, we stick it at the end.
    for (i = 0; i <= length; i += SCRIPTS_STRIDE)
    {
        if ("" == llList2String(scripts, i + SCRIPTS_KEY))
        {
            scripts = llListReplaceList(scripts, [user, name, SCRIPT_READING, ""], i, i + SCRIPTS_STRIDE - 1);
            llMessageLinked(LINK_SET, UTILITIES_READ, name, scriptKey + "|" + (string) i);
            // A break command is a wonderful thing LL.
            return i;
        }
    }
    // Should never get here, but just in case, try to trigger an error later on.
    return -1;
}

recordIt(string command, list arguments)
{
    integer length = llGetListLength(arguments);
    integer i;
    float now = llGetTime(); 

    // Record pauses between commands, but not if it's less than the script tick time, no point.
    if ((0.0 < lastTick) && ((now - lastTick) > scriptTick))
        record += ["sleep " + (string) (now - lastTick)];
    lastTick = now;
    for (i = 0; i < length; ++i)
    {
        string arg = llList2String(arguments, i);

        if (osIsUUID(arg))
            arg = llKey2Name(arg);
        command += " " + arg;
    }
    record += [command];
}

key string2key(string name, integer type)
{
    if (osIsUUID(name))
        return (key) name;
    else if (AGENT == type)
    {
        list names = llParseString2List(name, [" "], []);
        key uuid = osAvatarName2Key(llList2String(names, 0), llList2String(names, 1));

        return uuid;
    }
    else if ((IS_BOTH == type) || (IS_NPC == type))    // osAvatarName2Key() does not work on NPCs, so we gotta scan the entire sim.
    {
        // osGetAvatarList() skips the owner, so we need to add it..
        list avatars = [llGetOwner(), ZERO_VECTOR, llKey2Name(llGetOwner())] + osGetAvatarList();   // Strided list, UUID, position, name.
        integer length = llGetListLength(avatars);
        integer i;

        for (i = 0; i < length; i +=3)
        {
            key this = (key) llList2String(avatars, i);
            string thisName = llList2String(avatars, i + 2);

            if ((thisName == name) && (osIsNpc(this) || (IS_BOTH == type)))
                return this;
        }
    }
    else if (llGetObjectName() == name)
        return llGetKey();

    return NULL_KEY;
}

vector string2pos(string name)
{
    key uuid = NULL_KEY;

    if (("<" == llGetSubString(name, 0, 0)) && (">" == llGetSubString(name, -1, -1)))
    {
        // Looks like a vector, cast it.
        return (vector) name;
    }

    uuid = string2key(name, IS_BOTH);
    if (NULL_KEY != uuid)
        return (vector) llList2String(llGetObjectDetails(uuid, [OBJECT_POS]), 0);

    return ZERO_VECTOR;
}

integer goThere(key user, string name, string dest, string type)
{
    key npc = string2key(name, IS_NPC);
    integer executed = FALSE;

    if (NULL_KEY != npc)
    {
        vector pos = string2pos(dest);

        if (ZERO_VECTOR == pos)
            startSensor(user, npc, dest, ACTIVE | PASSIVE, type);
        else
        {
            integer found = llListFindList(movers, [npc]);
            integer method = OS_NPC_FLY | OS_NPC_LAND_AT_TARGET;
            list    this = [npc, pos, llVecMag((vector) llList2String(llGetObjectDetails(npc, [OBJECT_POS]), 0) - pos), llGetTime()];

            if ((0 <= found) && ((found % MOVE_STRIDE) == 0))
                llListReplaceList(movers, this, found, found + MOVE_STRIDE - 1);
            else
                movers += this;

            if (NPC_GO == type)
                method = OS_NPC_NO_FLY;
            else if (NPC_FLY == type)
                method = OS_NPC_FLY;
            else if (NPC_LAND == type)
                method = OS_NPC_FLY | OS_NPC_LAND_AT_TARGET;
            // Telling a sitting NPC to move results in an error, so tell them to stand up, just in case.
            osNpcStand(npc);
            osNpcMoveToTarget(npc, pos, method);
            executed = TRUE;
        }
    }
    return executed;
}

killNPC(key npc, key newNpc)
{
    integer found = llListFindList(followers, [npc]);
    integer length = llGetListLength(attention);

    osNpcRemove(npc);
    // Stop this attention whore from chatting, moving, and stalking.
    checkChat(npc, "0", 0, newNpc);
    
    while (0 <= found)
    {
        if ((found % FOLLOW_STRIDE) == FOLLOW_KEY)          // Change of stalker.
        {
            if (NULL_KEY != newNpc)
                followers = llListReplaceList(followers, [newNpc], found, found);
            else
                followers = llDeleteSubList(followers, found, found + FOLLOW_STRIDE - 1);
        }
        else if ((found % FOLLOW_STRIDE) == FOLLOW_STALK)   // Change of stalkee.
        {
            if (NULL_KEY != newNpc)
                followers = llListReplaceList(followers, [newNpc], found, found);
            else
                followers = llDeleteSubList(followers, found - FOLLOW_STALK, found - FOLLOW_STALK + FOLLOW_STRIDE - 1);
        }
        found = llListFindList(followers, [npc]);
    }
    found = llListFindList(movers, [npc]);
    if ((0 <= found) && ((found % MOVE_STRIDE) == 0))
    {
        // The only user of newNpc wants even the new one gone from the movers list.
        // But we do this anyway, coz it will get confused, and might need it later.
        if (NULL_KEY != newNpc)
            movers = llListReplaceList(movers, [newNpc], found, found);
        else
            movers = llDeleteSubList(movers, found, found + MOVE_STRIDE - 1);
    }
    // Search the attention lists to and remove/replace them from that.
    for (found = 0; found < length; found += ATTENT_STRIDE)
        delAttention(llList2String(attention, found + ATTENT_KEY), npc, newNpc);
}

addAttention(key user, key npc)
{
    list    npcs = [];
    integer handle = 0;
    integer isUser = FALSE;
    integer found = llListFindList(attention, [(string) user]);

    // TODO - This should not be happening, I think, but it does.
    if (NULL_KEY == npc)
        return;

    if (osIsUUID(user))
        isUser = TRUE;

    if (0 != (found % ATTENT_STRIDE))
        found = -1;

    if (-1 == found)
    {
        if (isUser)
            handle = llListen(commandChannel, llKey2Name(user), user, "");
    }
    else
    {
        handle = llList2Integer(attention, found + ATTENT_HANDLE);
        npcs = llParseString2List(llList2String(attention, found + ATTENT_NPCS), ["|"], []);
        attention = llDeleteSubList(attention, found, found + ATTENT_STRIDE - 1);
        found = llListFindList(npcs, [(string) npc]);
        if (-1 != found)
            npcs = llDeleteSubList(npcs, found, found);
    }
    attention += [user, handle, llDumpList2String(npcs + [npc], "|")];
    if (isUser)
        llSay(0, llKey2Name(npc) + " pays attention to " + llKey2Name(user));
}

// Replaces instead of deletes if newNpc is not NULL.
// Deletes them all if npc is NULL.
delAttention(key user, key npc, key newNpc)
{
    list    npcs = [];
    integer handle;
    integer isUser = FALSE;
    integer found = llListFindList(attention, [(string) user]);

    if (osIsUUID(user))
        isUser = TRUE;
    if (0 != (found % ATTENT_STRIDE))
        found = -1;

    if (-1 != found)
    {
        handle = llList2Integer(attention, found + ATTENT_HANDLE);
        npcs = llParseString2List(llList2String(attention, found + ATTENT_NPCS), ["|"], []);
        attention = llDeleteSubList(attention, found, found + ATTENT_STRIDE - 1);
        if (NULL_KEY == npc)
            npcs = [];
        else
        {
            found = llListFindList(npcs, [(string) npc]);
            if (-1 != found)
            {
                if (NULL_KEY != newNpc)
                    npcs = llListReplaceList(npcs, [newNpc], found, found);
                else
                    npcs = llDeleteSubList(npcs, found, found);
            }
        }
        if (0 == llGetListLength(npcs))
            llListenRemove(handle);
        else
            attention += [user, handle, llDumpList2String(npcs, "|")];
        if (isUser && (NULL_KEY == newNpc))
            llSay(0, llKey2Name(npc) + " ignores " + llKey2Name(user));
    }
}

sendManyCommands(key user, string command, key index)
{
    list    npcs = [];
    integer handle;
    integer found = llListFindList(attention, [(string) user]);

    if (user != index)
        found = llListFindList(attention, [(string) index]);
    if (0 != (found % ATTENT_STRIDE))
        found = -1;

    if (-1 != found)
    {
        integer length;
        integer i;
        string thisCommand;
        string rest = "";

        handle = llList2Integer(attention, found + ATTENT_HANDLE);
        npcs = llParseString2List(llList2String(attention, found + ATTENT_NPCS), ["|"], []);
        length = llGetListLength(npcs);
        // Split the command on the first space, if there is one.
        found = llSubStringIndex(command, " ");
        thisCommand = llGetSubString(command, 0, found);
        if (-1 != found)
        {
            thisCommand = llGetSubString(command, 0, found - 1);
            rest = " " + llGetSubString(command, found, -1);
        }
        else
            thisCommand = command;
// TODO - the original command will go through utilities as well,
//        if it's a chat command, and generate an error.
        // If it's on the no names list, then don't bother expanding the names.
        if (-1 != llListFindList(OUR_COMMANDS_NONAMES, [thisCommand]))
        {
            // Don't bother if it's from chat, it got done already through the usual method.
            if (0 == handle)
                sendCommand(user, command);
        }
        else
        {
            for (i = 0; i < length; ++i)
                sendCommand(user, thisCommand + " " + llList2String(npcs, i) + rest);
        }
    }
}

sendCommand(key user, string command)
{
    llMessageLinked(LINK_SET, UTILITIES_CHAT_FAKE, llDumpList2String([0, llKey2Name(user), user, command], LIST_SEP), scriptKey);
}

init()
{
    integer i;
    if (llGetAttached())
    {
        // We are attached to an avatar, so get it's key.
        key realId = llGetOwnerKey(llGetKey());
        if (osIsNpc(realId))
        {
            // TODO - Instead we should go into a "only control this NPC" mode.
            llSay(0, "Deleting onefang's NPC scripts from this NPC.");
            llRemoveInventory(UTILITIES_SCRIPT_NAME);
            llRemoveInventory(llGetScriptName());
        }
        else
        {
            // Only listen to the attachment wearer if attached.
            OUR_COMMANDS = llListReplaceList(OUR_COMMANDS, [realId], 1, 1);
        }
    }
    IS_NPC = ACTIVE;
    IS_BOTH = SCRIPTED;
    OBJECT = PASSIVE;
    for (i = 0; i < 16; ++i)
        chatters += ["", 0, 0];
    scriptKey = llGetInventoryKey(llGetScriptName());
    llMessageLinked(LINK_SET, UTILITIES_RESET, "reset", scriptKey);
    llSetTimerEvent(scriptTick);
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

    changed(integer change)
    {
        // Restore NPCs if the sim restarted, after a delay to let the sim settle.
        if (change & CHANGED_REGION_START)
            restartTimer = llGetTime() + 60.0;
    }

    link_message(integer sender_num, integer num, string value, key id)
    {
        list keys = llParseStringKeepNulls((string) id, ["|"], []);
        string extra = llList2String(keys, 1);

        id = (key) llList2String(keys, 0);
//llSay(0, "id = " + (string) id + " extra = " + extra + " VALUE " + value);
        if ((NPC_RECORD == num) && (scriptKey == id))
        {
            record = [];
            recording = TRUE;
        }
        else if ((NPC_RECORD_STOP == num) && (scriptKey == id))
        {
            recording = FALSE;
            lastTick = -1.0;
            llRemoveInventory(NPC_RECORD_CARD + NPC_SCRIPT_EXT);
            osMakeNotecard(NPC_RECORD_CARD + NPC_SCRIPT_EXT, record);
        }
        else if ((UTILITIES_RESET_DONE == num) && (llGetInventoryKey(UTILITIES_SCRIPT_NAME) == id))
        {
            // Set our commands.
            OUR_COMMANDS = llListReplaceList(OUR_COMMANDS, [commandChannel], 0, 0);
            llMessageLinked(LINK_SET, UTILITIES_CHAT, llDumpList2String(OUR_COMMANDS, LIST_SEP), scriptKey);
        }
        else if ((UTILITIES_READ_DONE == num) && (scriptKey == id))
        {
            // The script is done, remove the reading flag.
            list    command = llParseStringKeepNulls(value, [LIST_SEP], []);
            string  card = llList2String(command, 0);
            // extra was pre strided when it was sent off.
            integer i = ((integer) extra);

            if ("" != llList2String(scripts, i))
            {
                integer flags = llList2Integer(scripts, i + SCRIPTS_FLAGS);

                scripts = llListReplaceList(scripts, [flags & (~SCRIPT_READING)], i + SCRIPTS_FLAGS, i + SCRIPTS_FLAGS);
//llSay(0, "Done reading " + (string) i + " " + card + "\n" + llDumpList2String(scripts, "~"));
            }
        }
        else if (-1000 >= num)    // SettingsReader telling us to change a setting.
        {
            // num is the line number : -1000 - settingsLine
            // Not sure if llMessageLinked is a FIFO, but lets hope so.
            // Otherwise we may have to resort to OpenSim card reading, and drop SL compatibility.
            list    command = llParseStringKeepNulls(value, [LIST_SEP], []);
            list result = [];
            string  card = llList2String(command, 0);
            integer length = llGetListLength(command);
            // extra was pre strided when it was sent off.
            integer i = (integer) extra;
            integer j;
            string commands = llList2String(scripts, i + SCRIPTS_COMMANDS);

            if ("" != commands)
                result = [commands];
//llSay(0, "     reading " + (string) i + " " + card);
//if (0 == (num % 100))  {llSay(0, "read line " + (string) num);  llSleep(0.1);}
            for (j = 1; j < length; j += 2)
                result += [llList2String(command, j) + LIST_SEP + llList2String(command, j + 1)];
            scripts = llListReplaceList(scripts, [llDumpList2String(result, "|")], i + SCRIPTS_COMMANDS, i + SCRIPTS_COMMANDS);
        }
        else if ((UTILITIES_CHAT_DONE == num) && (scriptKey == id))
        {
            integer executed = FALSE;
            // incoming channel | incoming name | incoming key | incoming message | prefix | command | list of arguments | rest of message
            list    result        = llParseStringKeepNulls(value, [LIST_SEP], []);
            //integer inchannel    = llList2Integer(result, 0);
            //string  inName          = llList2String (result, 1);
            key     user        = llList2Key    (result, 2);
            //string  inMessage    = llList2String (result, 3);
            //string  prefix          = llList2String (result, 4);
            string  command        = llList2String (result, 5);
            list    arguments    = llList2List   (result, 6, -1);   // Includes "rest of message" as the last one.
//llSay(0, "COMMAND " + value);

            // WARNING - Don't return out of this "if" chain, unless you don't want the command recorded.
            // TODO - Maybe just do that instead of using the executed flag.
            if (NPC_ATTENTION == command)
                addAttention(user, string2key(llList2String(arguments, 0), IS_NPC));
            if (NPC_DISMISSED == command)
                delAttention(user, string2key(llList2String(arguments, 0), IS_NPC), NULL_KEY);
            else if (NPC_CLONE == command)
            {
                string name = llList2String(arguments, 0);
                key uuid = string2key(name, AGENT);

                if (osIsUUID(name))
                    name = llKey2Name(name);
                if (NULL_KEY != uuid)
                {
                    osAgentSaveAppearance(uuid, name + NPC_NPC_EXT);
                    executed = TRUE;
                }
            }
            else if (NPC_CREATE == command)
            {
                string name = llList2String(arguments, 0);
                list names = llParseString2List(name, [" "], []);
                string last = llList2String(names, 1);
                vector pos = llList2String(arguments, 1);
                key npc;
                integer fromMenu = FALSE;

                // Either strip off the extension, or add it.
                if (llSubStringIndex(last, NPC_NPC_EXT) != -1)
                {
                    last = llGetSubString(last, 0, -1 - llStringLength(NPC_NPC_EXT));
                    // This is an evil hack, the menu system will hand us the full name of the notecard.
                    // Other methods are likely to not do so.  But only likely.
                    // TODO - I think this idea fails with the new argument parsing.  DOH!
                    fromMenu = TRUE;
                }
                else
                    name += NPC_NPC_EXT;
                if (ZERO_VECTOR == pos)
                    pos = llGetPos() + (<1.0, 0.0, 1.5> * llGetRot());
                npc = osNpcCreate(llList2String(names, 0), last, pos, name, OS_NPC_SENSE_AS_AGENT | OS_NPC_NOT_OWNED);
                executed = TRUE;
                if (fromMenu)
                    llMessageLinked(LINK_SET, NPC_NEW_NPC, user + "|" + npc, scriptKey);
            }
            else if (NPC_CHANGE == command)
            {
                string card = llList2String(arguments, 1);

                if (llSubStringIndex(card, NPC_NPC_EXT) == -1)
                    card += NPC_NPC_EXT;
                osNpcLoadAppearance(string2key(llList2String(arguments, 0), IS_NPC), card);
                executed = TRUE;
            }
            else if (NPC_COME == command)
                executed = goThere(user, llList2String(arguments, 0), user, NPC_GO);
            else if (NPC_FOLLOW == command)
            {
                key npc = string2key(llList2String(arguments, 0), IS_NPC);

                if  (NULL_KEY != npc)
                {
                    integer found = llListFindList(followers, [npc]);
                    vector  pos = (vector) llList2String(arguments, 1);

                    if (ZERO_VECTOR == pos)
                    {
                        float distance = llList2Float(arguments, 1);

                        if (0.0 == distance)
                            pos = STALK_DISTANCE;
                        else
                            pos = <distance, 0.0, 0.0>;
                    }
                    if ((0 <= found) && ((found % FOLLOW_STRIDE) == 0))
                        llListReplaceList(followers, [npc, user, pos], found, found + FOLLOW_STRIDE - 1);
                    else
                        followers += [npc, user, pos];
                    executed = TRUE;
                }
            }
            else if (NPC_STALK == command)
            {
                key npc = string2key(llList2String(arguments, 0), IS_NPC);
                key avatar = string2key(llList2String(arguments, 1), IS_BOTH);

                // No stalking yourself, that's just creepy.
                if ((NULL_KEY != avatar) && (NULL_KEY != npc) && (avatar != npc))
                {
                    integer found = llListFindList(followers, [npc]);
                    vector  pos = (vector) llList2String(arguments, 2);

                    if (ZERO_VECTOR == pos)
                    {
                        float distance = llList2Float(arguments, 2);

                        if (0.0 == distance)
                            pos = STALK_DISTANCE;
                        else
                            pos = <distance, 0.0, 0.0>;
                    }
                    if ((0 <= found) && ((found % FOLLOW_STRIDE) == 0))
                        llListReplaceList(followers, [npc, avatar, pos], found, found + FOLLOW_STRIDE - 1);
                    else
                        followers += [npc, avatar, pos];
                    executed = TRUE;
                }
            }
            else if (NPC_GO == command)
                executed = goThere(user, llList2String(arguments, 0), llList2String(arguments, 1), NPC_GO);
            else if (NPC_FLY == command)
                executed = goThere(user, llList2String(arguments, 0), llList2String(arguments, 1), NPC_FLY);
            else if (NPC_LAND == command)
                executed = goThere(user, llList2String(arguments, 0), llList2String(arguments, 1), NPC_LAND);
            else if (NPC_LINK == command)
            {
                llMessageLinked(llList2Integer(arguments, 0), llList2Integer(arguments, 1), 
                                llList2String(arguments, 2), llList2String(arguments, 3));
                executed = TRUE;
            }
            else if (NPC_LISTEN == command)
            {
                // Remove our chat commands from whatever channel they where on before.
                llMessageLinked(LINK_SET, UTILITIES_CHAT, llDumpList2String(llList2List(OUR_COMMANDS, 0, 0) + ["", "", ""], LIST_SEP), scriptKey);
                // Set them on the new channel.
                commandChannel = llList2Integer(arguments, 0);
                OUR_COMMANDS = llListReplaceList(OUR_COMMANDS, [commandChannel], 0, 0);
                llMessageLinked(LINK_SET, UTILITIES_CHAT, llDumpList2String(OUR_COMMANDS, LIST_SEP), scriptKey);
                executed = TRUE;
            }
            else if (NPC_LOCATE == command)
            {
                key    npc = string2key(llList2String(arguments, 0), IS_NPC);
                vector pos = string2pos(llList2String(arguments, 0));
                vector size = llGetAgentSize(npc);

                // This wont work, it HAS to be in a touch event.  Silly LL and their hobbled thinking.
                //llMapDestination(llGetRegionName(), pos, pos);

                // Offset by halfish the NPCs size, so it should end up above them.
                pos.z += size.z / 1.8;
                // First destroy any existing beacons.  Simplifies things.
                llRegionSay(SIM_CHANNEL, "nobeacon");
                llRezObject("locator beacon", llGetPos(), ZERO_VECTOR, llEuler2Rot(<180.0 * DEG_TO_RAD, 0.0, 0.0>), SIM_CHANNEL);
                // Wait for it to finish starting up.  A hack I know, avoids making things more complex.
                // Avoids complications with object_rez(key uuid) events and having to track what we rezzed.
                llSleep(1.0);
                llRegionSay(SIM_CHANNEL, "beacon " + (string) pos);
            }
            else if (NPC_ANIMATE == command)
            {
                osNpcPlayAnimation(string2key(llList2String(arguments, 0), IS_NPC), llList2String(arguments, 1));
                executed = TRUE;
            }
            else if (NPC_STOPANIM == command)
            {
                osNpcStopAnimation(string2key(llList2String(arguments, 0), IS_NPC), llList2String(arguments, 1));
                executed = TRUE;
            }
            else if (NPC_ROTATE == command)
            {
                rotation rot = llEuler2Rot(<0.0, 0.0, llList2Float(arguments, 1) * DEG_TO_RAD>);

                osNpcSetRot(string2key(llList2String(arguments, 0), IS_NPC), rot);
                executed = TRUE;
            }
            else if (NPC_SCRIPT == command)
            {
                newScript(user, llList2String(arguments, 0));
                // Don't actually record this, since it's commands will be recorded.
                executed = FALSE;
            }
            else if (NPC_SAY == command)
                executed = checkChat(string2key(llList2String(arguments, 0), IS_NPC), llList2String(arguments, 1), 1, NULL_KEY);
            else if (NPC_SHOUT == command)
                executed = checkChat(string2key(llList2String(arguments, 0), IS_NPC), llList2String(arguments, 1), 2, NULL_KEY);
            else if (NPC_STOP == command)
            {
                key npc = string2key(llList2String(arguments, 0), IS_NPC);
                integer found = llListFindList(followers, [npc]);

                if ((0 <= found) && ((found % FOLLOW_STRIDE) == 0))
                    followers = llDeleteSubList(followers, found, found + FOLLOW_STRIDE - 1);
                found = llListFindList(movers, [npc]);
                if ((0 <= found) && ((found % MOVE_STRIDE) == 0))
                    movers = llDeleteSubList(movers, found, found + MOVE_STRIDE - 1);
                osNpcStopMoveToTarget(npc);
                executed = TRUE;
            }
            else if (NPC_COMPLETE == command) // Do nothing, it's a script only command handled completely in the script.
                executed = TRUE;
            else if (NPC_WHISPER == command)
                executed = checkChat(string2key(llList2String(arguments, 0), IS_NPC), llList2String(arguments, 1), 0, NULL_KEY);
            else if (NPC_SIT == command)
            {
                key npc = string2key(llList2String(arguments, 0), IS_NPC);
                string name = llList2String(arguments, 1);

                if (NULL_KEY != npc)
                {
                    key that = string2key(name, OBJECT);

                    if (NULL_KEY == that)
                        startSensor(user, npc, name, ACTIVE | SCRIPTED, NPC_SIT);
                    else
                    {
                        osNpcSit(npc, that, OS_NPC_SIT_NOW);
                        executed = TRUE;
                    }
                }
            }
            else if (NPC_TOUCH == command)
            {
                key npc = string2key(llList2String(arguments, 0), IS_NPC);
                string name = llList2String(arguments, 1);

                if (NULL_KEY != npc)
                {
                    key that = string2key(name, OBJECT);

                    if (NULL_KEY == that)
                        startSensor(user, npc, name, ACTIVE | SCRIPTED, NPC_TOUCH);
                    else
                    {
                        osNpcTouch(npc, that, LINK_ROOT);
                        executed = TRUE;
                    }
                }
            }
            else if (NPC_STAND == command)
            {
                osNpcStand(string2key(llList2String(arguments, 0), IS_NPC));
                executed = TRUE;
            }
            else if (NPC_DELETE == command)
            {
                // Since this deletes the NPC, if we are recording we wont be able to do llKey2Name below.
                string name = llKey2Name(string2key(llList2String(arguments, 0), IS_NPC));

                killNPC(string2key(llList2String(arguments, 0), IS_NPC), NULL_KEY);
                arguments = [name];
                executed = TRUE;
            }
            else if (NPC_NUKE == command)
            {
                list avatars = osGetAvatarList();   // Strided list, UUID, position, name.
                integer length = llGetListLength(avatars);
                integer i;

                for (i = 0; i < length; i++)
                {
                    key this = (key) llList2String(avatars, i * 3);

                    if (osIsNpc(this))
                        osNpcRemove(this);
                }
                attention = [];
                chatters = [];
                followers = [];
                movers = [];
                scripts = [];
                sensorRequests = [];
                sensorInFlight = FALSE;
                // Delete the beacons as well.
                llRegionSay(SIM_CHANNEL, "nobeacon");
                executed = TRUE;
            }

            // Record it, but only if it did something.
            if (recording && executed)
                recordIt(command, arguments);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        key npc        = (key) llList2String (chatters, (channel * CHAT_STRIDE) + CHAT_KEY);
        integer type   =       llList2Integer(chatters, (channel * CHAT_STRIDE) + CHAT_TYPE);
        integer handle =       llList2Integer(chatters, (channel * CHAT_STRIDE) + CHAT_HANDLE);

        // It's either in the chatters or the attention list.
        // Chatters are on their own channel.
        // Attentions are on the usual command channel (common for all users).
        // Utilities will also be listening on the command channel.  And will get a duplicate utterance, sans the name.
        // So choose between them based on channel.
        // Users that make a chatter channel the same as the command channel deserve what they get.
        if (channel == commandChannel)
            sendManyCommands(id, message, id);
        if (NULL_KEY != npc)
            checkChat(npc, message, type, NULL_KEY);
    }

    no_sensor()
    {
        sensorInFlight = FALSE;
        if (llGetListLength(sensorRequests))
        {
            sensorRequests = llDeleteSubList(sensorRequests, 0, 4);
            nextSensor();
        }
    }

    sensor(integer numberDetected)
    {
        sensorInFlight = FALSE;
        if (llGetListLength(sensorRequests))
        {
            string  name    = llList2String(sensorRequests, 0);
            integer type    = llList2Integer(sensorRequests, 1);
            string  command = llList2String(sensorRequests, 2);
            key     user    = llList2String(sensorRequests, 3);
            key     npc     = llList2String(sensorRequests, 4);

            sensorRequests = llDeleteSubList(sensorRequests, 0, 4);
            sendCommand(user, command + " " + npc + " " + llDetectedKey(0));
            nextSensor();
        }
    }

    timer()
    {
        integer i;
        integer length = llGetListLength(followers);

        // Check for sim restart.
        if ((0.0 < restartTimer) && (llGetTime() > restartTimer))
        {
            restartTimer = -1.0;
            // Start with a nuke, just to clear out all the lists.
            sendCommand(llGetOwnerKey(llGetKey()), NPC_NUKE);
            sendCommand(llGetOwnerKey(llGetKey()), NPC_SCRIPT + " " + NPC_BACKUP_CARD + NPC_SCRIPT_EXT);
            // The sim restarted, no need to take care of followers or scripts this time.
            return;
        }

        // First the followers.
        for (i = 0; i < length; i += FOLLOW_STRIDE)
        {
            key     npc         = (key)     llList2String(followers, i + FOLLOW_KEY);
            key     stalkee     = (key)     llList2String(followers, i + FOLLOW_STALK);
            vector  distance    = (vector)  llList2String(followers, i + FOLLOW_DIST);
            float   mag         = llVecMag(distance);
            list    details     =  llGetObjectDetails(stalkee, [OBJECT_POS, OBJECT_VELOCITY, OBJECT_ROT]);
            list    npcDetails  =  llGetObjectDetails(npc,     [OBJECT_POS, OBJECT_VELOCITY, OBJECT_ROT]);
            vector  pos         = (vector)  llList2String(details, 0);
            vector  speed       = (vector)  llList2String(details, 1);
            rotation    rot     = (rotation) llList2String(details, 2);
            integer npcInfo     = llGetAgentInfo(npc);
            integer info        = llGetAgentInfo(stalkee);
            integer isFlying    = info & AGENT_FLYING;
            integer isWalking   = info & AGENT_WALKING;
            integer isInAir     = info & AGENT_IN_AIR;
            integer isRunning   = info & AGENT_ALWAYS_RUN;
            integer isSitting   = info & AGENT_SITTING;
            vector  newPos      = pos + (distance * rot);
            float   newDist     = llVecMag((vector) llList2String(npcDetails, 0) - pos);

            if (newDist > mag)
            {
                if (npcInfo & AGENT_SITTING)   // Tell the lazy bum to stand up.
                    osNpcStand(npc);
                if (isRunning)
                    osNpcMoveToTarget(npc, newPos, OS_NPC_NO_FLY | OS_NPC_RUNNING);
                else if (isFlying || isInAir)
                    osNpcMoveToTarget(npc, newPos, OS_NPC_FLY);
                else if (isWalking)
                    osNpcMoveToTarget(npc, newPos, OS_NPC_NO_FLY);
                else
                    osNpcMoveToTarget(npc, newPos, OS_NPC_NO_FLY);
//                    osNpcMoveToTarget(npc, pos, OS_NPC_FLY | OS_NPC_LAND_AT_TARGET);
            }
            else
                osNpcStopMoveToTarget(npc);
        }

        // Then movers.
        length = llGetListLength(movers);
        for (i = 0; i < length; i += MOVE_STRIDE)
        {
            key     npc   = (key)     llList2String (movers, i + MOVE_KEY);
            vector  dest  = (vector)  llList2String (movers, i + MOVE_DEST);
            float   least =           llList2Float  (movers, i + MOVE_LEAST);
            float   time  =           llList2Float  (movers, i + MOVE_TIME);
            float   left  = llVecMag((vector) llList2String(llGetObjectDetails(npc, [OBJECT_POS]), 0) - dest);

            if (least > left)                     // Progress has been made.
                movers = llListReplaceList(movers, [left, llGetTime()], i + MOVE_LEAST, i + MOVE_TIME);
            else if ((llGetTime() - time) > 5.0)  // No progress, they are stuck.
            {
                key oldNpc = npc;
                string name = llKey2Name(npc);
                list names = llParseString2List(name, [" "], []);
                list anims = llGetAnimationList(npc);
                integer animLen = llGetListLength(anims);
                integer invLen = llGetInventoryNumber(INVENTORY_ANIMATION);
                integer j;

                llShout(0, name + " is stuck!");
if ("" == name)
{
    llSay(0, "stuck key " + (string) i + " " + npc + "  -  " + oldNpc + " -- " + llDumpList2String(movers, "|"));
    killNPC(oldNpc, NULL_KEY);
    return;
}
                osAgentSaveAppearance(npc, NPC_TEMP_CARD + NPC_NPC_EXT);
                length = llGetListLength(movers);
                npc = osNpcCreate(llList2String(names, 0), llList2String(names, 1), dest, NPC_TEMP_CARD + NPC_NPC_EXT, OS_NPC_SENSE_AS_AGENT | OS_NPC_NOT_OWNED);
                llRemoveInventory(NPC_TEMP_CARD + NPC_NPC_EXT);
                // We want to replace them into the Attention, chatters, and followers lists.
                // Though no point adding them back to movers.
//llSay(0, "stuck key " + npc + "  -  " + oldNpc + " -- " + llDumpList2String(movers, "|"));
                killNPC(oldNpc, npc);

                // Try to re instate the animations.
                for (j = 0;  j < animLen; ++j)
                {
                    key anim = (key) llList2String(anims, j);
                    integer k;

                    // For each of the anims that was playing on the old NPC,
                    // See if we can find a match in our inventory.
                    for (k = 0;  k < invLen;  ++k)
                    {
                        string thisName = llGetInventoryName(INVENTORY_ANIMATION, k);

                        if (llGetInventoryKey(thisName) == anim)
                        {
                            osNpcPlayAnimation(npc, thisName);
                            k = invLen;
                        }
                    }
                }
            }

            if (left < 2.5)                // They have arrived.
            {
                movers = llDeleteSubList(movers, i, i + MOVE_STRIDE - 1);
                length -= MOVE_STRIDE;
                osNpcStopMoveToTarget(npc);
            }
        }

        // Then the scripts.
        length = llGetListLength(scripts);
        for (i = 0; i < length; i += SCRIPTS_STRIDE)
        {
            string     user = llList2String(scripts, i + SCRIPTS_KEY);

            if ("" != user)
            {
                string  name = llList2String(scripts, i + SCRIPTS_NAME);
                integer flags = llList2Integer(scripts, i + SCRIPTS_FLAGS);
                list    commands = llParseStringKeepNulls(llList2String(scripts, i + SCRIPTS_COMMANDS), ["|"], []);
                list    statement = llParseStringKeepNulls(llList2String(commands, 0), [LIST_SEP], []);
                string  command = llList2String(statement, 0);
                string  value  = llList2Key(statement, 1);

                commands = llDeleteSubList(commands, 0, 0);

                if ("" == value)    // A command with no =.  Run it as a pretend chat command from the user.
                {
                    if ("sleep " == llGetSubString(command, 0, 5))
                    {
                        float time = (float) llGetSubString(command, 6, -1);

                        commands = llListInsertList(commands, ["until " + (string)(llGetTime() + time)], 0);
                    }
                    else if ("until " == llGetSubString(command, 0, 5))
                    {
                        float time = (float) llGetSubString(command, 6, -1);

                        if (llGetTime() < time)
                            commands = llListInsertList(commands, [command], 0);
                    }
                    else if ("script " == llGetSubString(command, 0, 6))
                    {
                        string new = llGetSubString(command, 7, -1);
                        integer index = newScript(user, new);

                        if (0 == llGetListLength(commands))
                            ;//llSay(0, "tail recursion detected - " + name + " -> " + new + "  " + (string) i + " -> " + (string) index);
                        else if (-1 != index)
                            commands = llListInsertList(commands, ["wait " + (string) index + " " + new], 0);
                    }
                    else if ("wait " == llGetSubString(command, 0, 4))
                    {
                        list parts = llParseStringKeepNulls(command, [" "], []);
                        integer index = llList2Integer(parts, 1);
                        string card = llList2String(parts, 2);

                        // Check if the script this user started is still in the same slot we created above.
                        // Note, still possible to get a, hopefully rare, race condition here.
                        if ((llList2String(scripts, index + SCRIPTS_KEY) == user) && (llList2String(scripts, index + SCRIPTS_NAME) == card))
                            commands = llListInsertList(commands, [command], 0);
                    }
                    else if ("complete" == llGetSubString(command, 0, 7) && (8 == llStringLength(command)))
                    {
                        // Deal with attention seekers, we have to wait for all of them to get there.
                        integer found = llListFindList(attention, [(string) i]);

                        if (0 != (found % ATTENT_STRIDE))
                            found = -1;

                        if (-1 != found)
                        {
                            list npcs = llParseString2List(llList2String(attention, found + ATTENT_NPCS), ["|"], []);
                            integer nLength = llGetListLength(npcs);
                            integer j;

                            for (j = 0;  j < nLength; ++j)
                            {
                                key npc = llList2String(npcs, j);
                                found = llListFindList(movers, [npc]);

                                // If any are still a mover, keep waiting for the move to complete.
                                if ((0 <= found) && ((found % MOVE_STRIDE) == 0))
                                {
                                    commands = llListInsertList(commands, [command], 0);
                                    j = nLength;
                                }
                            }
                        }
                    }
                    else if ("complete " == llGetSubString(command, 0, 8))
                    {
                        key npc = string2key(llGetSubString(command, 9, -1), IS_NPC);
                        integer found = llListFindList(movers, [npc]);

                        // If they are still a mover, keep waiting for the move to complete.
                        if ((0 <= found) && ((found % MOVE_STRIDE) == 0))
                            commands = llListInsertList(commands, [command], 0);
                    }
                    else if ("attention " == llGetSubString(command, 0, 9))
                    {
                        addAttention((string) i, string2key(llGetSubString(command, 10, -1), IS_NPC));
                        scripts = llListReplaceList(scripts, [flags | SCRIPT_ATTENTION], i + SCRIPTS_FLAGS, i + SCRIPTS_FLAGS);
                    }
                    else if ("dismissed " == llGetSubString(command, 0, 9))
                    {
                        scripts = llListReplaceList(scripts, [flags & (~SCRIPT_ATTENTION)], i + SCRIPTS_FLAGS, i + SCRIPTS_FLAGS);
                        delAttention((string) i, string2key(llGetSubString(command, 10, -1), IS_NPC), NULL_KEY);
                    }
                    else if ("" != command)
                    {
//llSay(0, "DOING " + (string) (flags & SCRIPT_ATTENTION) + " " + command);
                        if (flags & SCRIPT_ATTENTION)
                            sendManyCommands(user, command, (string) i);
                        else
                            sendCommand(user, command);
                    }
                }
                else                // A variable assignment.
                {
//                    if ("DEBUG" == command)
//                        DEBUG = ("TRUE" == value);
                }

                if ((flags & SCRIPT_READING) || (0 < llGetListLength(commands)))
                    scripts = llListReplaceList(scripts, [llDumpList2String(commands, "|")], i + SCRIPTS_COMMANDS, i + SCRIPTS_COMMANDS);
                else
                {
                    scripts = llListReplaceList(scripts, ["", "", 0, ""], i, i + SCRIPTS_STRIDE - 1);
                    // Remove all our attention seekers.
                    delAttention((string) i, NULL_KEY, NULL_KEY);
                    while ((llGetListLength(scripts) > 0) && ("" == llList2String(scripts, 0 - SCRIPTS_STRIDE)))
                        scripts = llDeleteSubList(scripts, 0 - SCRIPTS_STRIDE, -1);
//llSay(0, "Finished script " + (string) i + " " + llDumpList2String(commands, "^") + "\n" + llDumpList2String(scripts, "~"));
                }
            }
        }
    }

}
