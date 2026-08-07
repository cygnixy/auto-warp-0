local log = require("std.log")
local state = require("state")

local M = {}

-- Is the order still in flight? Then the caller waits rather than ordering
-- again.
--
-- Motion is not obedience, and reading it as obedience cost sixty-two seconds
-- of silent hanging on 2026-08-06 at 12:44. The order to jump was given during
-- a session change, the client did not take it, the phase went to adrift — and
-- from that second on every tick saw about three hundred metres per second,
-- reset the patience clock and returned Running without a word. A ship pushed
-- out of a station flies on by itself and does not stop until it is told to:
-- its speed is above any threshold always, so the patience never began to run
-- and the warning about a lost order could never be reached.
--
-- state.lua had already written this trap down — "a ship pushed out of a
-- station is moving with nobody having ordered anything" — and moved the speed
-- test down here, where it promptly repeated it, only invisibly.
--
-- Obedience shows in the manoeuvre, not in the speed. The client draws Warp,
-- Jump and Approach exactly while it is carrying an order out, and announces
-- docking itself. The adrift phase *is* "nobody is carrying anything out": the
-- patience clock is reset by evidence of work, never by a sign of movement.
--
-- Where the clock is reset: see M.observe. It cannot be reset from here,
-- and putting it here was the first fix's mistake — the only caller of this
-- function is the `move` node, which the tree reaches solely in adrift and
-- session. While the ship warps nobody asks, so the branch that was meant to
-- hold the clock at zero never ran, and the flight of 13:25 came out of every
-- forty-eight-second warp to be told that nothing had come of the order in
-- forty-eight seconds. Four false warnings and eight orders for four legs,
-- where one order per leg is the whole point.
--
-- patience_ms — how long without any evidence of work is allowed before the
-- order is taken for lost.
function M.pending(patience_ms)
    if (cygnixy.bb_get("order_pending") or 0) ~= 1 then
        return false
    end

    -- Nothing is happening. Start counting, if counting has not started.
    local since = cygnixy.bb_get("order_since") or -1
    if since < 0 then
        cygnixy.bb_set("order_since", cygnixy.now_ms())
        return true
    end

    -- Patience is out: the order is taken for lost.
    local waited = cygnixy.now_ms() - since
    if waited >= patience_ms then
        log.repeated("order_stuck", "warn", "flight",
            "nothing has come of the last order in " .. math.floor(waited / 1000) ..
            "s, ordering again")
        cygnixy.bb_set("order_pending", 0)
        cygnixy.bb_set("order_since", -1)
        return false
    end

    return true
end

-- Records that an order has just been given. The only place an order is
-- marked: it used to be marked both by warp_choice.after_chosen and by its
-- caller a line later, with two sets of keys between them.
function M.issue()
    cygnixy.bb_set("order_pending", 1)
    cygnixy.bb_set("order_since", -1)
end

-- What becomes of the order this tick, whatever the client is showing.
--
-- Called by the journal, which is the one thing that runs on every tick in
-- every phase. The guard that consults the clock does not: it is reached in
-- two phases out of nine, and a rule about "while the client works" cannot
-- live somewhere that is blind while the client works.
--
-- Patience measures a continuous absence of evidence, so a manoeuvre holds
-- the clock at zero rather than merely restarting it once. Whether an order
-- is outstanding does not matter here: with none pending the clock means
-- nothing anyway, and the guard reads it only after M.issue.
function M.observe(phase)
    if
        phase == state.WARPING
        or phase == state.JUMPING
        or phase == state.APPROACHING
        or phase == state.DOCKING
    then
        cygnixy.bb_set("order_since", -1)
    end
end

-- The client has said the order is over: it changes session, it is in a
-- hangar, it is leaving one, or it has gone quiet altogether.
--
-- Called on a change of phase, not every tick. That is deliberate: an order
-- given during a session change -- the mid-session probe -- would otherwise be
-- wiped by the very next tick and given again on the one after.
--
-- Docking is not in this list, and neither is arriving at a gate. "Jump
-- through stargate" covers the warp and the jump both, and a Dock order ends
-- when the ship is docked: clearing the mark in the middle costs an extra
-- order at every leg.
function M.ends_with_phase(phase)
    if
        phase == state.SESSION
        or phase == state.DOCKED
        or phase == state.UNDOCKING
        or phase == state.UNKNOWN
    then
        cygnixy.bb_set("order_pending", 0)
        cygnixy.bb_set("order_since", -1)
    end
end

return M
