local leg = require("leg")
local log = require("std.log")
local patience = require("std.patience")

local M = {}

-- How long a flight with nothing to fly and nothing to explain it is given
-- before that is called the end of it.
--
-- Milliseconds, not ticks, for the reason std.press spells out at the top of
-- press.lua. A minute, and it is generous on purpose: this is not a wait for the
-- client to answer a press but a watch on the mission's own input, and the route
-- panel it reads blanks for whole seconds across a session change. A minute of a
-- mission spent standing is already visible from the outside; less than that
-- risks calling a slow undock an empty mission.
local PATIENCE_MS = 60000

local WAIT = "somewhere_to_fly"

-- The word the client writes on the mission entry's button when the ship is in
-- the mission's own system and the thing wanted next is a warp, not a route.
-- The same word cygnixy/mission-combat presses in the step after this one, and
-- the same one cygnixy/agent-missions reads before deciding not to lay a route.
local WARP_OFFERED = "Warp to Location"

-- WHETHER THIS FLIGHT IS OVER BEFORE IT BEGAN — Success — or has something to
-- do — Failure, and the tree flies it.
--
-- IT IS A CONDITION AND NOT A WATCHDOG, and that difference is what the run of
-- 16:51 was spent teaching. As a watchdog it said "nothing to fly" and let the
-- tick through to the flight below, which then tried to set a route it could
-- not set, failed, and was run again by the repeat around it — for as long as
-- anybody left it. Everything upstream had worked: the mission was recognised
-- as being in hand, the route was correctly not laid, the reason was correctly
-- named. And then the step simply never ended, which from the outside looks
-- exactly like a bot at work.
--
-- A STEP THAT CAN NEITHER MOVE NOR FINISH IS NOT ALLOWED TO EXIST. A refusal is
-- read; a silent stand is not. So this answers the tree's question — is there
-- anything here to fly — and the tree does the ending.
--
-- The four ways there is something to fly, and every one of them is a Failure:
--
-- 1. THE MISSION NAMED A PLACE. Nothing else matters then; the route is set
--    from the name.
-- 2. A ROUTE IS ALREADY DRAWN. Markers as well as jumps, for the reason
--    is_route_set gives at length: a collapsed route panel draws no markers
--    while its header still counts the jumps, and an expanded one has been seen
--    carrying markers with no jump count at all.
-- 3. SOMETHING HAS ALREADY BEEN ORDERED. _state is written by
--    warp_choice.after_chosen and by nothing else, so it means "this flight has
--    sent the ship somewhere". THIS BRANCH IS WHY THE QUESTION MAY BE ASKED ON
--    EVERY TICK: at the end of an ordinary flight the route empties itself and
--    the mission entry begins offering a warp, which is branch 4's picture
--    exactly — and ending the step there would abandon a leg that ordered a
--    Dock before the ship was in the station. Once anything has been ordered,
--    the flight below owns its own ending.
-- 4. Nothing explains the emptiness, and the budget above has not run out. The
--    flight below is tried exactly as it would have been.
--
-- And the two ways it is over:
--
-- 5. THE MISSION IS IN THIS SYSTEM. The entry's button offers a warp: the
--    client is saying there is nowhere to route to and the next thing wanted is
--    a warp, which the fight step makes. Nothing has been ordered and nothing
--    will be. The step is done, on the first tick, with no clock at all.
-- 6. A minute of nothing, with nothing to explain it. The step is done too, and
--    the line says so at error level: whoever was to lay the route did not. It
--    ends rather than fails because the cause is upstream and the steps after
--    this one report on their own; what may not happen is this step going on
--    standing there without a word.
function M.main(args)
    local destination = leg.pick(args and args[1], args and args[2])
    if type(destination) == "string" and destination ~= "" then
        patience.forget(WAIT)
        return "Failure"
    end

    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local jumps = route and route.jumps
    local markers = route and route.route_element_marker
    if (type(jumps) == "number" and jumps > 0)
        or (type(markers) == "table" and #markers > 0) then
        patience.forget(WAIT)
        return "Failure"
    end

    local ordered = cygnixy.bb_get("_state")
    if type(ordered) == "string" and ordered ~= "" then
        patience.forget(WAIT)
        return "Failure"
    end

    -- The mission entry's button, read whole in one function so the path lint
    -- can follow the chain.
    local missions = panel and panel.info_panel_agent_missions
    local entries = missions and missions.entries
    local entry = entries and entries[1]
    local button = entry and entry.action_button
    local label = button and button.label
    if label == WARP_OFFERED then
        patience.forget(WAIT)
        log.steady("somewhere_to_fly", "info", "flight",
            "no route, and none wanted: the mission is in this system and its entry " ..
            "offers a warp to the place — this flight is over before it began")
        return "Success"
    end

    if patience.gave_up(WAIT, PATIENCE_MS) then
        patience.forget(WAIT)
        log.repeated("route", "error", "flight",
            "this flight was given no destination and there is no route to follow, " ..
            PATIENCE_MS .. "ms on — whoever was to lay the route did not, or there was " ..
            "none to lay; ending the step rather than standing here")
        return "Success"
    end

    log.steady("somewhere_to_fly", "info", "flight",
        "no destination and no route yet — waiting for one to appear")
    return "Failure"
end

return M
