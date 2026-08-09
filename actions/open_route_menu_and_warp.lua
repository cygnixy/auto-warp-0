local log = require("std.log")
local press = require("std.press")
local state = require("std.state")
local order = require("std.order")
local guard = require("guard")
local pointer = require("std.pointer")
local warp_choice = require("warp_choice")

local M = {}

-- Markers are addressed by path rather than by the regions read out of them:
-- along a path the click point is worked out with the windows lying over the
-- info panel taken into account, and a marker is eight pixels across — a window
-- over its corner is enough to swallow the click.
--
-- All of them are offered, in the order the panel lists them, because the first
-- is not always the gate: on the leg into a system the panel carries two, and
-- the leading one is the system just reached.
local function marker_paths(count)
    local paths = {}
    for index = 1, count do
        paths[index] = string.format(
            "info_panel_container.info_panel_route.route_element_marker[%d].region",
            index - 1
        )
    end
    return paths
end

local PATIENCE_MS = 8000
local PROBE_EVERY_MS = 2000
local PANEL_HELD_MS = 700

-- The client serves no travel command early in a session change, and says so
-- itself: its countdown reads high. Measured over the flight of 14:05, where
-- every attempt fell into one of two groups and nothing else about the client
-- differed between them:
--
--   7 seconds left -> the route marker's menu carries Show Info, Save
--                     Location, Remove Waypoint, and no way to travel   (3 of 3)
--   4 or fewer     -> the same menu carries Jump Through Stargate       (3 of 3)
--
-- Everything else was identical on both sides, and that is the point: the
-- route panel had already recomputed for the new system, the overview already
-- held its ten rows in the tree -- drawn empty, but there -- and the location
-- panel already named the new system. The one thing that told the two apart
-- was the number the client publishes about itself.
--
-- Four is where the evidence stops, not where the client's rule is: the probe
-- runs every two seconds, so five and six were never asked. Asking too late
-- costs nothing, since the order lands on the next probe either way; the whole
-- gain here is not spending a menu gesture on a client that will refuse it.
local SESSION_READY_S = 4

function M.main(args)
    -- Read once: three questions below are about the same tick, and a phase
    -- re-read between them would let them disagree.
    local phase = state.phase()

    -- An order is outstanding: wait up to 8s with the client showing no sign
    -- of carrying it out before giving it again.
    --
    -- Asked before anything about the session, and that order matters. A jump
    -- order starts a session change of its own, so with the question the other
    -- way round the bot spent the seconds after every successful order
    -- announcing that the session change was too young to order in -- three
    -- times, then nine, escalating into warnings about a client that was doing
    -- exactly what it had been told.
    if order.pending(PATIENCE_MS) then
        return "Running"
    end

    if phase == state.SESSION then
        -- The client's own countdown, when it reads. nil means it did not, and
        -- then the probe goes ahead as it did before this was known: a wait on
        -- a signal that never arrives is worse than a wasted gesture.
        --
        -- Said once per session change, at debug. This wait is normal and the
        -- client's own clock bounds it; a line per tick, or a count that grows
        -- into a warning, teaches the reader to ignore warnings.
        local left = state.session_seconds_left()
        if left ~= nil and left > SESSION_READY_S then
            if (cygnixy.bb_get("said_session_early") or 0) ~= 1 then
                cygnixy.bb_set("said_session_early", 1)
                log.debug("flight",
                    "waiting out the young session change: the client offers no way to travel yet")
            end
            return "Running"
        end

        -- Mid-session probing: wait until the route panel is fresh before trying.
        if not guard.panel_fresh(PANEL_HELD_MS) then
            return "Running"
        end
    end

    -- Take permission for mid-session probing if in session change.
    if phase == state.SESSION then
        if press.pending("session_probe", PROBE_EVERY_MS) then
            return "Running"
        end
        press.made("session_probe")
        cygnixy.bb_set("panel_fresh", -1)
        log.debug("flight", "the route panel has caught up and held; trying it mid-session")
    end

    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    if not (route and route.route_element_marker and #route.route_element_marker > 0) then
        -- Said aloud, because a wordless Running is indistinguishable in the
        -- log from a bot doing its job: the hang of 12:44 left sixty-two
        -- seconds of nothing at all. Only while the panels can be believed --
        -- the route panel blanks itself during a session change, and an empty
        -- panel then says "not yet" rather than "no route".
        if state.settled(phase) then
            log.repeated("no_markers", "debug", "flight",
                "the route panel shows no marker to order from")

            -- No marker and settled panels are not by themselves "the route
            -- is over": drifting_no_markers.json is exactly this shape with
            -- a real place still named in next_system, and staying Running
            -- for it is the whole point of that fixture. next_system is what
            -- tells the two apart -- it names nowhere once the route is
            -- actually spent, not merely slow to redraw a marker.
            --
            -- Live run, 2026-08-09: a system-kind mission arrived with
            -- next_system already null and circled here forever -- 243 lines
            -- and a warning nobody could silence by hand, because this
            -- branch answered Running whatever the route said. Failure hands
            -- the tick to whatever fly_route's own exit condition decides an
            -- empty, settled route this bare actually means: done, for a
            -- system-kind leg with nowhere further to go, or merely nothing
            -- to order this tick, for a station-kind leg still short of a
            -- dock -- in which case the debug line above keeps escalating
            -- exactly as it always did.
            --
            -- Checked by type, not by nil: the host turns a JSON null into an
            -- empty table on the way into Lua, not into nil, and
            -- route.next_system == nil would never once be true for it.
            if type(route.next_system) ~= "string" then
                return "Failure"
            end
        end
        return "Running"
    end
    log.forget("no_markers")

    local paths = marker_paths(#route.route_element_marker)
    local entry, err = pointer.open_menu_and_choose(paths, warp_choice.choices)
    if entry == nil then
        log.repeated("route_menu", "debug", "flight",
            "no order could be given from the route marker: " .. tostring(err))
        return "Running"
    end

    warp_choice.after_chosen(entry)
    return "Success"
end

return M
