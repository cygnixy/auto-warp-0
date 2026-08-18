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
-- @param args table args[1] = destination, args[2] = return_destination
-- @return string "Success" or "Failure"
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
