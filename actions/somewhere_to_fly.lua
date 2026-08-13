local flight = require("flight")
local log = require("std.log")
local patience = require("std.patience")

local M = {}

-- How long a flight with nothing to fly and nothing to explain it is given
-- before that is called a fault.
--
-- Milliseconds, not ticks, for the reason std.press spells out at the top of
-- press.lua. A minute, and it is generous on purpose: this is not a wait for the
-- client to answer a press but a watch on the mission's own input, and the route
-- panel it reads blanks for whole seconds across a session change. A minute of a
-- mission spent standing is already visible from the outside; less than that
-- risks calling a slow undock an empty mission.
local PATIENCE_MS = 60000

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
