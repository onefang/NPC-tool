// Onefang's NPC menu version 1.0.
// Requires NPC tool, and onefang's utilities scripts.

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

list chatters = [];   // npc key, relay channel.
integer CHAT_KEY     = 0;
integer CHAT_CHANNEL = 1;
integer CHAT_STRIDE  = 2;

list  sensorRequests = [];  // name to search for, type of search, range, command, user key, npc key, title for menu, agents flag, every flag
integer sensorInFlight = FALSE;

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

string NPC_MAIN     = "Main";   // TODO - does not really matter what this is I think, so use it as the registered menu button.
string NPC_PICK     = "Pick";
string NPC_NPC      = "NPC";
string NPC_RELAY    = "Relay";

string NPC_NPC_EXT = ".avatar";
string NPC_SCRIPT_EXT = ".npc";
string NPC_BACKUP_CARD = "Restore";
string NPC_RECORD_CARD = "Recorded";

integer NPC_RECORD      = -100;
integer NPC_RECORD_STOP = -101;
integer NPC_NEW_NPC     = -102;
integer NPC_ADD_CHATTER = -103;
integer NPC_DEL_CHATTER = -104;


// Stuff for onefangs common utilities.
key NPCscriptKey;
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


showMenu(key id, string type, string title, list buttons, string extra)
{
    llMessageLinked(LINK_SET, UTILITIES_MENU, llDumpList2String([id, type, title] + buttons, LIST_SEP), (key) scriptKey + "|" + extra);
}

NPCmenu(key id, key npc)
{
    string name = llKey2Name(npc);

    if ((0 == osIsUUID(npc)) || (npc == NULL_KEY) || ("" == name))
    {
        showMenu(id, (string) INVENTORY_NONE, "Main NPC menu.", 
            [
            "clone avatar..", "create NPC..", "run script..",
            "nearby NPCs..", "local NPCs..", "NPCs in sim..",
            "backup NPCs", "nuke NPCs", "restore NPCs",
            "start recording", "stop recording"
            ], NPC_MAIN);
    }
    else
    {
        integer found = llListFindList(chatters, [npc]);
        string chat = "";

        if (0 <= found)
            chat = "\nUse /" + llList2String(chatters, found + CHAT_CHANNEL) + " to relay chat to " + llKey2Name(npc);
        showMenu(id, (string) INVENTORY_NONE, "Play with " + llKey2Name(npc) + " :" + chat,
            [
            "change..", "chat relay..", "come here",
            "go to..", "fly to..", "land at..",
            "follow me", "stalk them..", "stop moving",
            "sit..", NPC_STAND,
            NPC_LOCATE, "take controls", "touch..",
            "start animation..", "stop animation..",
            NPC_DELETE
            ], NPC_NPC + "|" + npc);
    }
}

startSensor(key user, key npc, string name, integer type, float range, 
    string command, string title, integer agents, integer everything)
{
    if ((AGENT == type) && (range > 9999.9999))   // Assumes we are only looking for NPCs.
    {
        integer i;
        list menu = [];
        list avatars = osGetAvatarList();   // Strided list, UUID, position, name.
        integer length = llGetListLength(avatars);

        for (i = 0; i < length; i++)
        {
            key this = (key) llList2String(avatars, i * 3);

            if (osIsNpc(this))
                menu += [llKey2Name(this) + "|" + (string) this];
        }
        if (llGetListLength(menu) > 0)
            showMenu(user, (string) INVENTORY_NONE, "Choose NPC :", menu, NPC_PICK);
    }
    else
    {
        sensorRequests += [name, type, range, command, user, npc, title, agents, everything];
        nextSensor();
    }
}

nextSensor()
{
    if (sensorInFlight)
        return;
    if (0 < llGetListLength(sensorRequests))
    {
        string  name    = llList2String(sensorRequests, 0);
        integer type    = llList2Integer(sensorRequests, 1);
        float   range   = llList2Float(sensorRequests, 2);
        string  command = llList2String(sensorRequests, 3);
        key     user    = llList2String(sensorRequests, 4);
        key     npc     = llList2String(sensorRequests, 5);
        string  title   = llList2String(sensorRequests, 6);
        integer agents  = llList2Integer(sensorRequests, 7);
        integer every   = llList2Integer(sensorRequests, 8);

        sensorInFlight = TRUE;
        llSensor(name, "", type, range, TWO_PI);
    }
}

sendCommand(key user, string command)
{
    // Work around the other script getting reset later, with a fresh key
    NPCscriptKey = llGetInventoryKey("NPC tool");
    llMessageLinked(LINK_SET, UTILITIES_CHAT_FAKE, llDumpList2String([0, llKey2Name(user), user, command], LIST_SEP), NPCscriptKey);
}

init()
{
    scriptKey = llGetInventoryKey(llGetScriptName());
    // Register our interest in touch menus.
    llMessageLinked(LINK_SET, UTILITIES_MENU, llDumpList2String([NULL_KEY, INVENTORY_NONE, "NPC tool|" + llGetScriptName()], LIST_SEP), (key) scriptKey);
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

    link_message(integer sender_num, integer num, string value, key id)
    {
        list keys = llParseStringKeepNulls((string) id, ["|"], []);
        string extra = llList2String(keys, 1);

        id = (key) llList2String(keys, 0);
        // Work around the other script getting reset later, with a fresh key
        NPCscriptKey = llGetInventoryKey("NPC tool");
//llSay(0, "id = " + (string) id + " extra = " + extra + " VALUE " + value);
        if (UTILITIES_RESET_DONE == num)
            init();
        else if ((NPC_NEW_NPC == num) && (NPCscriptKey == id))
        {
            list args = llParseString2List(value, ["|"], []);

            NPCmenu(llList2String(args, 0), llList2String(args, 1));
        }
        else if ((NPC_ADD_CHATTER == num) && (NPCscriptKey == id))
        {
            list args = llParseString2List(value, ["|"], []);
            key npc = llList2String(args, 0);
            integer channel = llList2Integer(args, 1);
            integer found = llListFindList(chatters, [npc]);

            if (0 <= found)
                chatters = llDeleteSubList(chatters, found, found + CHAT_STRIDE - 1);
            chatters += [npc, channel];
        }
        else if ((NPC_DEL_CHATTER == num) && (NPCscriptKey == id))
        {
            integer found = llListFindList(chatters, [value]);

            if (0 <= found)
                chatters = llDeleteSubList(chatters, found, found + CHAT_STRIDE - 1);
        }
        else if ((UTILITIES_CHAT_DONE == num) && (NPCscriptKey == id))
        {
            // incoming channel | incoming name | incoming key | incoming message | prefix | command | list of arguments | rest of message
            list    result        = llParseStringKeepNulls(value, [LIST_SEP], []);
            //integer inchannel    = llList2Integer(result, 0);
            //string  inName          = llList2String (result, 1);
            key     user        = llList2Key    (result, 2);
            //string  inMessage    = llList2String (result, 3);
            //string  prefix          = llList2String (result, 4);
            string  command        = llList2String (result, 5);
            list    arguments    = llList2List   (result, 6, -1);   // Includes "rest of message" as the last one.

            if (NPC_NUKE == command)
            {
                chatters = [];
                sensorRequests = [];
                sensorInFlight = FALSE;
            }
        }
        else if ((UTILITIES_MENU_DONE == num) && (scriptKey == id))    // Big menu button pushed
        {
            list    input = llParseStringKeepNulls(value, [LIST_SEP], []);
            key     user = (key) llList2String(input, 0);
            string  selection =  llList2String(input, 1);
            list    parts = llParseString2List(selection, ["|"], []);
            key     uuid = (key) llList2String(parts, 1);
            key     npc = (key) llList2String(keys, 2);
            list    details = llGetObjectDetails(uuid, [OBJECT_POS]);
            string  menu = extra;
//llSay(0, extra + " MENU " + value + "  KEYS " + llDumpList2String(keys, " "));

            // See if it was our top level menu requested via touch registration.
            if ("" == selection)
            {
                NPCmenu(user, NULL_KEY);
                return;
            }

            // Figure out what the user picked.
            if ((NPC_MAIN == extra) || (NPC_NPC == extra))
                menu = selection;
            // Make sure main menu items don't return to an NPC menu, by setting npc to null.
            if (NPC_MAIN == extra)
                npc = NULL_KEY;

            // Check if the NPC still exists.
            if (NPC_NPC == extra)
            {
                list npcDetails = llGetObjectDetails(npc, [OBJECT_POS]);

                if (llGetListLength(npcDetails) == 0)
                {
                    // Bail out if the NPC went AWOL.
                    npc = NULL_KEY;
                    selection = "Exit";
                }
            }

            if ("Exit" == selection)
            {
                if (NPC_NPC  == extra)  npc = NULL_KEY;
                if (NPC_MAIN == extra)  return;
            }
            // Commands.
            else if (NPC_ANIMATE       == menu)  sendCommand(user, NPC_ANIMATE  + " " + npc + " " + selection);
            else if (NPC_CHANGE        == menu)  sendCommand(user, NPC_CHANGE   + " " + npc + " " + selection);
            else if (NPC_CLONE         == menu)  sendCommand(user, NPC_CLONE    + " " + uuid);
            else if (NPC_FLY           == menu)  sendCommand(user, NPC_FLY      + " " + npc + " " + llList2String(details, 0));
            else if (NPC_GO            == menu)  sendCommand(user, NPC_GO       + " " + npc + " " + llList2String(details, 0));
            else if (NPC_LAND          == menu)  sendCommand(user, NPC_LAND     + " " + npc + " " + llList2String(details, 0));
            else if (NPC_LOCATE        == menu)  sendCommand(user, NPC_LOCATE   + " " + npc);
            else if (NPC_RELAY         == menu)  sendCommand(user, NPC_SAY      + " " + npc + " " + selection);
            else if (NPC_SCRIPT        == menu)  sendCommand(user, NPC_SCRIPT   + " " + selection);
            else if (NPC_SIT           == menu)  sendCommand(user, NPC_SIT      + " " + npc + " " + uuid);
            else if (NPC_STALK         == menu)  sendCommand(user, NPC_STALK    + " " + npc + " " + uuid);
            else if (NPC_STAND         == menu)  sendCommand(user, NPC_STAND    + " " + npc);
            else if (NPC_STOPANIM      == menu)  sendCommand(user, NPC_STOPANIM + " " + npc + " " + selection);
            else if (NPC_TOUCH         == menu)  sendCommand(user, NPC_TOUCH    + " " + npc + " " + uuid);
            else if ("come here"       == menu)  sendCommand(user, NPC_COME     + " " + npc);
            else if ("follow me"       == menu)  sendCommand(user, NPC_FOLLOW   + " " + npc);
            else if ("nuke NPCs"       == menu)  sendCommand(user, NPC_NUKE);
            else if ("restore NPCs"    == menu)  sendCommand(user, NPC_SCRIPT   + " " + NPC_BACKUP_CARD + NPC_SCRIPT_EXT);
            else if ("stop moving"     == menu)  sendCommand(user, NPC_STOP     + " " + npc);

            // Menus.
            else if ("change.."          == menu)  showMenu(user, ((string) INVENTORY_NOTECARD) + "|.+\\" + NPC_NPC_EXT,
                                                        "Choose an NPC to change to :",   [], NPC_CHANGE + "|" + npc);
            else if ("chat relay.."      == menu)  showMenu(user,  (string) INVENTORY_NONE,
                                                        "Choose a channel to relay chat from :", ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"], NPC_RELAY + "|" + npc);
            else if ("create NPC.."      == menu)  showMenu(user, ((string) INVENTORY_NOTECARD) + "|.+\\" + NPC_NPC_EXT,
                                                        "Choose an NPC to create :",      [], NPC_CREATE);
            else if ("run script.."      == menu)  showMenu(user, ((string) INVENTORY_NOTECARD) + "|.+\\" + NPC_SCRIPT_EXT,
                                                        "Choose a script to run :",       [], NPC_SCRIPT);
            else if ("start animation.." == menu)  showMenu(user,  (string) INVENTORY_ANIMATION,
                                                        "Choose an animation to start :", [], NPC_ANIMATE  + "|" + npc);
            else if ("stop animation.."  == menu)  showMenu(user,  (string) INVENTORY_ANIMATION,
                                                        "Choose an animation to stop :",  [], NPC_STOPANIM + "|" + npc);

            // Sensor menus.
            else if ("clone avatar.."  == menu)  startSensor(user, "",  "", AGENT,              256.0, NPC_CLONE,  "Choose person to clone :",  TRUE,  TRUE);
            else if ("fly to.."        == menu)  startSensor(user, npc, "", ACTIVE | PASSIVE,  1024.0, NPC_FLY,    "Choose thing to fly to :",  FALSE, TRUE);
            else if ("go to.."         == menu)  startSensor(user, npc, "", ACTIVE | PASSIVE,  1024.0, NPC_GO,     "Choose thing to go to :",   FALSE, TRUE);
            else if ("land at.."       == menu)  startSensor(user, npc, "", ACTIVE | PASSIVE,  1024.0, NPC_LAND,   "Choose thing to land at :", FALSE, TRUE);
            else if ("local NPCs.."    == menu)  startSensor(user, "",  "", AGENT,              256.0, NPC_PICK,   "Choose NPC :",              FALSE, FALSE);
            else if ("nearby NPCs.."   == menu)  startSensor(user, "",  "", AGENT,               20.0, NPC_PICK,   "Choose NPC :",              FALSE, FALSE);
            else if ("NPCs in sim.."   == menu)  startSensor(user, "",  "", AGENT,            16384.0, NPC_PICK,   "Choose NPC :",              FALSE, FALSE);
            else if ("sit.."           == menu)  startSensor(user, npc, "", ACTIVE | SCRIPTED, 1024.0, NPC_SIT,    "Choose thing to sit on :",  FALSE, TRUE);
            else if ("stalk them.."    == menu)  startSensor(user, npc, "", AGENT,             1024.0, NPC_STALK,  "Choose person to stalk :",  TRUE,  TRUE);
            else if ("touch.."         == menu)  startSensor(user, npc, "", ACTIVE | SCRIPTED, 1024.0, NPC_TOUCH,  "Choose thing to touch :",   FALSE, TRUE);

            // Misc.
            else if (NPC_PICK          == menu)  npc = uuid;
            else if ("start recording" == menu)  llMessageLinked(LINK_SET, NPC_RECORD,      "", NPCscriptKey);
            else if ("stop recording"  == menu)  llMessageLinked(LINK_SET, NPC_RECORD_STOP, "", NPCscriptKey);
            else if (NPC_CREATE   == menu)
            {
                sendCommand(user, NPC_CREATE   + " " + selection);
                // Avoid the NPCmenu() below.  An odd one out, coz the NPC wont exist yet, but we want their menu when they do exist.
                return;
            }
            else if (NPC_DELETE    == menu)
            {
                sendCommand(user, NPC_DELETE + " " + npc);
                // An odd one out, the NPC wont exist, so return to the main menu.
                npc = NULL_KEY;
            }
            else if ("backup NPCs"     == menu)
            {
                list avatars = osGetAvatarList();   // Strided list, UUID, position, name.
                list delete = [];
                list backup = [];
                integer length = llGetListLength(avatars);
                integer i;

                llRemoveInventory(NPC_BACKUP_CARD + NPC_SCRIPT_EXT);
                for (i = 0; i < length; i++)
                {
                    key this = (key) llList2String(avatars, i * 3);

                    if (osIsNpc(this))
                    {
                        string aName = llKey2Name(this);

                        osAgentSaveAppearance(this, aName + NPC_NPC_EXT);
                        delete += [NPC_DELETE + " " + aName];
                        backup += [NPC_CREATE + " " + aName + " " + llList2String(avatars, (i * 3) + 1)];
                    }
                }
                osMakeNotecard(NPC_BACKUP_CARD + NPC_SCRIPT_EXT,
                      ["script " + NPC_BACKUP_CARD + ".before" + NPC_SCRIPT_EXT]
                    + delete + backup
                    + ["script " + NPC_BACKUP_CARD + ".after" + NPC_SCRIPT_EXT]);
            }

            // If the menu name ends in "..", then it's expected that we are waiting on another menu, so don't show one now.
            if (0 == osRegexIsMatch(menu, ".+\\.\\.$"))
                NPCmenu(user, npc);
        }   // End of menu block.
    }

    no_sensor()
    {
        sensorInFlight = FALSE;
        if (llGetListLength(sensorRequests))
        {
            sensorRequests = llDeleteSubList(sensorRequests, 0, 8);
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
            float   range   = llList2Float(sensorRequests, 2);
            string  command = llList2String(sensorRequests, 3);
            key     user    = llList2String(sensorRequests, 4);
            key     npc     = llList2String(sensorRequests, 5);
            string  title   = llList2String(sensorRequests, 6);
            integer agents  = llList2Integer(sensorRequests, 7);
            integer every   = llList2Integer(sensorRequests, 8);

            sensorRequests = llDeleteSubList(sensorRequests, 0, 8);
            if ("" == title)
                sendCommand(user, command + " " + npc + " " + llDetectedKey(0));
            else
            {
                integer i;
                list menu = [];

                if (agents)
                    menu += ["you|" + (string) user];
                for (i = 0; i < numberDetected; i++)
                {
                    key this = llDetectedKey(i);

                    if (!(agents && (this == user)))
                        if (every || osIsNpc(this))
                            menu += [llDetectedName(i) + "|" + (string) this];
                }
                if (llGetListLength(menu) > 0)
                    showMenu(user, (string) INVENTORY_NONE, title, menu, command + "|" + npc);
            }
            nextSensor();
        }
    }

}