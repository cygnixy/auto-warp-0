local flight = require("flight")
local log = require("std.log")
local patience = require("std.patience")

local M = {}

-- Timeout waiting for route/destination to appear before aborting.
local PATIENCE_MS = 30000

local WAIT = "somewhere_to_fly"

-- Verifies that there is a valid destination or plotted route to fly.
-- Fails if no route is plotted within PATIENCE_MS.
--
-- @param args table args[1] = destination, args[2] = return_destination,
--        args[3] = destination_kind
-- @return string "Success" or "Failure"
function M.main(args)
    local reading = flight.reading(args and args[1], args and args[2])
    if reading ~= flight.NOTHING then
        patience.forget(WAIT)
        return "Success"
    end

    -- THE STORE, BEFORE THE FAILURE — and for a STATION-bound flight only.
    -- The rescue of 2026-08-20 13:35 ran with its destination empty (the
    -- operator's slot variables had died with a reselect) and no route stood,
    -- so the ship stayed in the pocket while the run stopped. What survives
    -- every restart is the store, and the station this bot last docked at is
    -- home in the loop that runs it — the loop docks there at the end of
    -- every iteration. A SYSTEM-bound flight is left to fail as before: its
    -- emptiness means the step that was to lay the route did not, and flying
    -- somewhere else instead would dress that fault up as a flight.
    if (args and args[3]) == "station"
        and cygnixy.bb_get("_recovered_destination") == nil
        and rawget(cygnixy, "store_get") ~= nil then
        local kept, why = cygnixy.store_get("last_docked_station")
        if why == nil and type(kept) == "string" and kept ~= "" then
            cygnixy.bb_set("_recovered_destination", kept)
            log.warn("flight",
                "this flight was given no destination and no route stands — the " ..
                "last station this bot docked at, " .. kept .. ", is written down " ..
                "in the store, and the flight goes there rather than nowhere")
            patience.forget(WAIT)
            return "Success"
        end
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
