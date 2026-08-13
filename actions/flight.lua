local leg = require("leg")
local state = require("std.state")

local M = {}

-- What this flight has to fly, read off the client in one place.
--
-- Two actions ask it and each does something different with the answer, which
-- is the whole reason the reading lives in a module rather than in either of
-- them:
--
--   flight_is_over  Success only on WARP — the step is done, and the tree ends
--                   on it
--   somewhere_to_fly  Failure only on NOTHING outlasting its budget — the run
--                     ends, loudly, because nobody knows why there is nothing
--                     to fly
--
-- The difference between those two is the difference this project has spent the
-- day defending: an emptiness the client explains is an answer, and an emptiness
-- nobody explains is a fault. Success means "the ship is where it was to be
-- taken", and saying that when it is not true sends the fight step warping at a
-- place that may not exist — which it would then report, one step late and for
-- somebody else's mistake.
--
-- Every chain into cygnixy.eve is spelled out whole inside this one function:
-- the path lint follows a chain only within the function it starts in.

-- A place was named in the mission's variables. Nothing else matters then.
M.DESTINATION = "destination"
-- A route is drawn. Markers as well as jumps, for the reason is_route_set gives
-- at length: a collapsed route panel draws no markers while its header still
-- counts the jumps, and an expanded one has been seen carrying markers with no
-- jump count at all.
M.ROUTE = "route"
-- Something has already been sent for. _state is written by
-- warp_choice.after_chosen and by nothing else, so it means "this flight has
-- ordered the ship somewhere" — and from then on the flight owns its own
-- ending. Without this, the end of an ordinary flight (route emptied, mission
-- entry offering a warp again) would read as WARP below, and a leg that ordered
-- a Dock would be called finished before the ship was ever in the station.
M.ORDERED = "ordered"
-- The mission's place is in this very system: the entry's button offers a warp
-- rather than a route, which is the client saying there is nowhere to route to.
-- The same word cygnixy/mission-combat presses in the step after this one.
M.WARP = "warp"
-- The ship is in a station, with no route to fly out on and no place named to
-- fly to. A bot whose whole job is to lay a route and fly it has nothing to do
-- with a ship in a hangar and nothing to fly it along: that is not an emptiness
-- needing an explanation, it is a ship that has arrived.
--
-- It is the state the return leg of a mission in the agent's own system leaves
-- behind: cygnixy/agent-missions presses the Dock the mission itself offers, the
-- ship goes inside, and the flight step after it has nothing left to do. Without
-- this reading that step would spend a minute deciding the emptiness was
-- nobody's fault and then fail the run over it.
M.DOCKED = "docked"

-- Nothing to fly, and nothing on the screen explains it.
M.NOTHING = "nothing"

local WARP_OFFERED = "Warp to Location"

function M.reading(out_destination, home_destination)
    local destination = leg.pick(out_destination, home_destination)
    if type(destination) == "string" and destination ~= "" then
        return M.DESTINATION
    end

    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local jumps = route and route.jumps
    local markers = route and route.route_element_marker
    if (type(jumps) == "number" and jumps > 0)
        or (type(markers) == "table" and #markers > 0) then
        return M.ROUTE
    end

    local ordered = cygnixy.bb_get("_state")
    if type(ordered) == "string" and ordered ~= "" then
        return M.ORDERED
    end

    local missions = panel and panel.info_panel_agent_missions
    local entries = missions and missions.entries
    local entry = entries and entries[1]
    local button = entry and entry.action_button
    local label = button and button.label
    if label == WARP_OFFERED then
        return M.WARP
    end

    -- Asked last of all, and after the mission entry: a ship in a station with a
    -- route still to fly is a ship about to undock, and the route above has
    -- already answered for it.
    if state.phase() == state.DOCKED then
        return M.DOCKED
    end

    return M.NOTHING
end

return M
