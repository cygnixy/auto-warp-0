local flight = require("flight")
local log = require("std.log")
local patience = require("std.patience")

local M = {}

-- How long a flight with nothing to fly and nothing to explain it is given
-- before that is called a fault.
--
-- Milliseconds, not ticks, for the reason std.press spells out at the top of
-- press.lua.
--
-- HALF A MINUTE, AND THE MINUTE IT REPLACES WAS TOO LONG TO BE OF ANY USE. The
-- run of 2026-08-15 20:26 stood in exactly this emptiness — a fly-home step
-- handed an empty destination by a step that laid no route — and the operator
-- stopped it by hand after sixty seconds of one unchanging line. The blackboard
-- of the last tick before the stop reads wait_somewhere_to_fly 6173 against a
-- clock at 66000: the budget had 55 milliseconds left to run and one more tick
-- would have spent it. A budget nobody outlasts is a budget nobody ever sees,
-- and a run that has to be stopped by hand has no diagnosis in the log.
--
-- Thirty seconds is generous for what is actually being waited on. This is not a
-- wait for the client to answer a press: the route is laid by the step BEFORE
-- this one, so by the time this flight begins it either exists or it never will,
-- and the only real wait is the client drawing a panel it was told about — a
-- tick or two, on the live client of that same evening. The rest of the thirty
-- seconds is slack for a session change, which blanks the route panel for whole
-- seconds at a time.
local PATIENCE_MS = 30000

local WAIT = "somewhere_to_fly"

-- Whether there is anything to fly — and, when there is not, whether anybody
-- knows why.
--
-- IT FAILS ONLY THE EMPTINESS NOBODY EXPLAINS, and that line is the whole
-- point of it. An emptiness the client accounts for is an answer:
-- flight_is_over reads it off the same reading and ends the step with Success,
-- because the ship really is where it was to be taken. An emptiness nothing
-- accounts for is a fault, and Success there would be a lie with consequences —
-- it says "the ship is where it was sent", and the fight step would then warp at
-- a place that may not exist and report the trouble one step late, for somebody
-- else's mistake. The cause of the emptiness is indeed upstream; the claim that
-- the flight is done is this bot's own, and it must not make it.
--
-- WHERE IT STANDS IS PART OF WHAT IT DOES. In the plain sequence of main, its
-- Failure ends the run — a fallback child's Failure would only send the tick on
-- to the flight below, which is exactly the loop that cannot end. And it stands
-- as early as the tree allows, beside flight_progress: a dozen actions in this
-- bot can answer Running with no clock of their own, and a budget standing
-- behind them would never be spent at all.
--
-- It never answers Running, so the warp of this tick is ordered on this tick.
function M.main(args)
    local reading = flight.reading(args and args[1], args and args[2])
    if reading ~= flight.NOTHING then
        patience.forget(WAIT)
        return "Success"
    end

    if patience.gave_up(WAIT, PATIENCE_MS) then
        patience.forget(WAIT)
        log.repeated("route", "error", "flight",
            "this flight was given no destination and there is no route to follow, " ..
            PATIENCE_MS .. "ms on — whoever was to lay the route did not, or there was " ..
            "none to lay; the ship is not where it was to be taken, and this step will " ..
            "not say that it is")
        return "Failure"
    end

    log.steady("somewhere_to_fly", "info", "flight",
        "no destination and no route yet — waiting for one to appear")
    return "Success"
end

return M
