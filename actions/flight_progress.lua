local log = require("std.log")
local patience = require("std.patience")
local state = require("std.state")

local M = {}

-- How long the ship may show no change at all before that is called a stand
-- rather than a flight.
--
-- A QUARTER OF AN HOUR, and the size is the point. This is not a budget for a
-- press to be answered — every one of those is a minute or two and lives in the
-- action that presses. It is the last line against a step that can neither move
-- nor finish, and it has to be longer than anything a flight legitimately does
-- without changing any of the five things below. The longest of those is a
-- single warp across a big system with no gates left to count: some four
-- minutes, phase "warping" throughout, the route already at zero jumps. Fifteen
-- minutes is several times that, and still short enough that a hung step is
-- found within a coffee break rather than at the end of an evening.
local PATIENCE_MS = 900000

local WAIT = "flight_progress"

-- What the last tick saw, so that "nothing changed" is a reading and not a
-- feeling.
local MARK = "_flight_mark"

-- Whether anything at all is happening, said once and pressing nothing.
--
-- THE RULE THIS EXISTS FOR: a step that can neither get anywhere nor end is
-- worse than one that fails. A failure is read; a stand looks exactly like work.
-- This bot's tree has one loop that can hold a step for ever —
-- @repeat_until_success around the route and the flight — and several ways into
-- it that no single action can foresee: a route the operator clears by hand
-- mid-run, a Dock ordered at a station the ship never reaches, a set_route step
-- that fails for a reason of its own on every pass. Each of those is somebody
-- else's bug to find; none of them may cost an evening of a bot that looks busy.
--
-- The five things it watches are the whole of what "getting somewhere" means to
-- this bot, and every one of them is a reading of the client rather than of the
-- bot's own intentions:
--
--   the phase          docked, undocking, warping, adrift, session
--   what was ordered   _state, written by warp_choice and nothing else
--   jumps left         the route's own count
--   the next system    the route's own name for it
--   the system now     where the ship actually is
--
-- A flight that is working changes one of them every few minutes: a gate taken
-- moves the system and the count, a warp begun moves the phase, an order given
-- moves _state. A flight that is standing changes none.
--
-- It never answers Running, so the warp of this tick is ordered on this tick —
-- the same rule report_ship_health follows and for the same reason. It does
-- answer Failure, once, at the end of the budget, which ends the run with a
-- line naming what has not moved.
function M.main()
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local jumps = route and route.jumps
    local next_system = route and route.next_system
    local location = panel and panel.info_panel_location_info
    local here = location and location.current_solar_system_id

    local mark = tostring(state.phase()) ..
        "/" .. tostring(cygnixy.bb_get("_state")) ..
        "/" .. (type(jumps) == "number" and string.format("%d", jumps) or "-") ..
        "/" .. (type(next_system) == "string" and next_system or "-") ..
        "/" .. (type(here) == "number" and string.format("%d", here) or "-")

    if cygnixy.bb_get(MARK) ~= mark then
        cygnixy.bb_set(MARK, mark)
        -- The clock is forgotten rather than restarted: the next tick that sees
        -- no change starts it afresh, which is a tick's worth of slack on a
        -- fifteen-minute budget and one branch less to get wrong.
        patience.forget(WAIT)
        return "Success"
    end

    if patience.gave_up(WAIT, PATIENCE_MS) then
        patience.forget(WAIT)
        log.repeated("progress", "error", "flight",
            "nothing about this flight has changed in " .. PATIENCE_MS ..
            "ms — phase, order, jumps, next system and the system the ship is in " ..
            "all still read " .. mark .. "; ending the step rather than standing here")
        return "Failure"
    end

    return "Success"
end

return M
