local log = require("log")
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
-- phase — this tick's phase, read once by the caller.
-- patience_ms — how long without any evidence of work is allowed before the
-- order is taken for lost.
function M.pending(phase, patience_ms)
    if (cygnixy.bb_get("order_pending") or 0) ~= 1 then
        return false
    end

    -- The client is showing the order being carried out: the clock restarts.
    if
        phase == state.WARPING
        or phase == state.JUMPING
        or phase == state.APPROACHING
        or phase == state.DOCKING
    then
        cygnixy.bb_set("order_since", -1)
        return true
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

return M
