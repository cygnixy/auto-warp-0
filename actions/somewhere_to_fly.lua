local leg = require("leg")
local log = require("std.log")
local patience = require("std.patience")

local M = {}

-- How long a flight is given to acquire something to fly before its emptiness
-- is believed.
--
-- Milliseconds, not ticks, for the reason std.press spells out at the top of
-- press.lua. A minute, and it is generous on purpose: this is not a wait for
-- the client to answer a press but a watch on the mission's own input, and the
-- route panel it reads blanks for whole seconds across a session change. A
-- minute of a mission spent standing is already visible from the outside; less
-- than that risks calling a slow undock an empty mission.
local PATIENCE_MS = 60000

local WAIT = "somewhere_to_fly"

-- Whether this flight has anywhere to go, said once and pressing nothing.
--
-- THE HOLE THIS FILLS IS A SILENT ONE. An empty destination means "the route is
-- already set, just fly it" — the way another bot's step lays a route and this
-- one flies it. With no route set either, set_route's fallback finds neither a
-- route to keep nor a name to search for, fails, and @repeat_until_success in
-- main.btree runs the whole thing again, and again: the mission stands still,
-- for as long as anyone leaves it, and says nothing at all. An operator watched
-- exactly that shape of loop once before and stopped it by hand.
--
-- It reaches a mission most easily where the place to fly to IS the place the
-- ship is: cygnixy/agent-missions lays the route home with the mission's own
-- button, and a mission taken in the agent's own system has no jumps to lay.
-- That step now refuses on its own side; this is the other side of the same
-- hole, and it covers every other way of arriving at it — a mission file with a
-- destination left empty by mistake, a route cleared by hand mid-run, a return
-- leg whose destination was never filled in.
--
-- IT NEVER ANSWERS RUNNING, so the flight of this tick costs nothing: while the
-- budget lasts it answers Success and the tree goes on to try exactly what it
-- would have tried anyway. When the budget is spent it answers Failure, which
-- fails main and ends the run with a sentence — the one thing the loop above
-- could not do for itself.
--
-- Markers as well as jumps, and for the reason is_route_set gives at length: a
-- collapsed route panel draws no markers while its header still counts the
-- jumps, and an expanded one has been seen carrying markers with no jump count
-- at all. Either one is a route.
--
-- AND ONE STATE WITH NOTHING TO FLY IS PERFECTLY HEALTHY, which is what the run
-- of 14:14 on 13 August taught: an agent gives a mission in the system he
-- himself lives in, and there is no route because there is nowhere to go. A
-- watchdog barking at that would end a good mission a minute in. It is told
-- apart by the client's own word — the mission entry's button reads "Warp to
-- Location", which is the client saying the ship is in the mission's system and
-- a warp is what is wanted next. The same word, on the same button, that
-- cygnixy/mission-combat presses in the step after this one.
--
-- Read off the mission entry rather than off the two systems, which is what the
-- step that lays the route compares: this bot does not know the mission's system
-- and has no business learning it. It knows what the panel says, and the panel
-- says it outright.
local WARP_OFFERED = "Warp to Location"

-- The label on the mission entry's button, or nil if there is no mission, no
-- button, or no label drawn. Spelled out in one function so the path lint can
-- follow the chain.
local function mission_button_label()
    local panel = cygnixy.eve.info_panel_container
    local missions = panel and panel.info_panel_agent_missions
    local entries = missions and missions.entries
    local entry = entries and entries[1]
    local button = entry and entry.action_button
    local label = button and button.label
    if type(label) ~= "string" then
        return nil
    end
    return label
end

function M.main(args)
    local destination = leg.pick(args and args[1], args and args[2])
    if type(destination) == "string" and destination ~= "" then
        patience.forget(WAIT)
        return "Success"
    end

    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local jumps = route and route.jumps
    local markers = route and route.route_element_marker
    if (type(jumps) == "number" and jumps > 0)
        or (type(markers) == "table" and #markers > 0) then
        patience.forget(WAIT)
        return "Success"
    end

    -- Nothing to fly, and the client says why: the mission is in this system.
    -- Done, at once and without a clock — there is nothing here for a budget to
    -- run out of.
    if mission_button_label() == WARP_OFFERED then
        patience.forget(WAIT)
        log.steady("somewhere_to_fly", "info", "flight",
            "no route, and none wanted: the mission is in this system and its entry " ..
            "offers a warp to the place")
        return "Success"
    end

    if patience.gave_up(WAIT, PATIENCE_MS) then
        patience.forget(WAIT)
        log.repeated("route", "error", "flight",
            "this flight was given no destination and there is no route to follow, " ..
            PATIENCE_MS .. "ms on — whoever was to lay the route did not, or there was " ..
            "none to lay")
        return "Failure"
    end

    log.steady("somewhere_to_fly", "info", "flight",
        "no destination and no route yet — waiting for one to appear")
    return "Success"
end

return M
