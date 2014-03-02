// Onefang's locator beacon script version 1.0.

// A lot of this is just my tweaked up warpPos(), the rest is mostly trivial.
// So I'll put this into the public domain.

integer SIM_CHANNEL = -65767365;
float offset = 128.0;
integer jumpSize = 512;

goThere(vector destPos)
{
    float distance = llVecDist(llGetPos(), destPos);

    if (distance > 0.001)
    {
        integer jumps = 0;
        integer time = llGetUnixTime();
        float oldDistance = 0;
        //llSetPos(destPos);  // This is not any faster, and only has a range of 10 meters.
        //destPos += <0.0, 0.0, 2.0>;  // Try to work around that damned Havok 4 bug.

        // We call the central routine several times to free the massive amount of memory used.
        do
        {
            jumps += warpPos(distance, destPos);
            distance = llVecDist(llGetPos(), destPos);
        }
        while (distance > 1.0 && ((llGetUnixTime() - time) < 2));  // Long jump, no limit.

        // OK, this is just being paranoid, but has been known to be needed in the past.
        while ((distance > 0.001) && (0.001 < (distance - oldDistance))  // Failsafe.
            && ((--jumps) > 0) && ((llGetUnixTime() - time) < 5)) // Time out.
        {
            llOwnerSay("Short hop from " + (string) llGetPos() + " of " + (string) distance + ".  Jumps " + (string) jumps);
            llSetPos(destPos);
            oldDistance = distance;
            distance = llVecDist(llGetPos(), destPos);
            llSleep(0.5);
        }
        if (distance > 0.001)
        {
            llShout(0, "Failed to get to " + (string) destPos + ", I am @ " + (string) llGetPos());
            llInstantMessage(llGetOwner(), "Failed to get to " + (string) destPos + ", I am @ " + (string) llGetPos());
        }
    }
}

integer warpPos(float distance, vector destPos)
{   // R&D by Keknehv Psaltery, 05/25/2006
    // with a little pokeing by Strife, and a bit more
    // some more munging by Talarus Luan
    // Final cleanup by Keknehv Psaltery
    // Extended distance by onefang Rejected.
    // More optimizations by 1fang Fang.

    // Compute the number of jumps necessary.
    integer jumps = (integer) (distance / 10.0) + 1;
    list rules = [PRIM_POSITION, destPos];  // The start for the rules list.
    integer count = 1;

    // Try and avoid stack/heap collisions.
    if (jumps > jumpSize)
    {
        jumps = jumpSize;
        llOwnerSay("Extra warp needed");
    }
    while ((count = count << 1 ) < jumps)
        rules += rules;

    //Changed by Eddy Ofarrel to tighten memory use some more
    llSetPrimitiveParams(rules + llList2List(rules, (count - jumps) << 1, count));
//llOwnerSay("Jumps " + (string) jumps + "   free " + (string) llGetFreeMemory());
    return jumps;
}

init()
{
    vector scale = llGetScale();

    offset = scale.z / 2;
    llListen(SIM_CHANNEL, "", NULL_KEY, "");
}

default
{
    state_entry()
    {
        init();
    }

    on_rez(integer param)
    {
        SIM_CHANNEL = param;
        init();
    }

    attach(key attached)
    {
        init();
    }

    listen(integer channel, string name, key id, string message)
    {
        if ("beacon " == llGetSubString(message, 0, 6))
        {
            vector pos = (vector) llGetSubString(message, 7, -1);

            if (ZERO_VECTOR != pos)
            {
                pos.z += offset;
                // OpenSim bug, first one doesn't quite get there, second one needed.
                // Happens with llSetPos() as well, llSetPrimitiveParams() at least does them both at once.
                // Need warpPos anyway, which hides this bug.
                goThere(pos);
                llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 1.0]);
                llSetAlpha(1.0, ALL_SIDES);
            }
        }
        else if ("nobeacon" == message)
            llDie();
    }

    touch_start(integer num_detected)
    {
        vector pos = llGetPos();

        pos.z -= offset;
        llMapDestination(llGetRegionName(), pos, pos);
    }
}
