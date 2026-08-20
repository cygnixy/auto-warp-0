local leg = require("leg")
local log = require("std.log")
local state = require("std.state")
local order = require("std.order")
local open_route_menu_and_warp = require("open_route_menu_and_warp")

local M = {}

-- The mission's own account of itself, written from what the client shows.
--
-- Before this existed the log was assembled out of whatever each tactic
-- happened to mention while it worked, and so it recorded decisions rather
-- than events: seven lines saying "Jump Through Stargate" was chosen, and not
-- one saying the ship ever arrived anywhere. Undocking, jumping and docking —
-- the things an operator wants to read back — went unrecorded because no
-- single action performs them. The client does, in its own time.
--
-- So this watches instead of acting. It runs every tick, beside the tactics
-- rather than inside them, compares what the client shows now against what it
-- showed a tick ago, and reports the differences. It presses nothing, and it
-- always succeeds: a narrator that could fail would stop a mission over a
-- missing name.
--
-- Every read below is spelled out in full rather than through a helper that
-- returns a piece of the tree. The path lint follows a chain only as far as
-- the function it starts in, so a read hidden behind a helper is a read
-- nobody checks against the notation — and this file exists to be trusted.

local STARTED = "journal_started"
local PLACE = "journal_place"
local SYSTEM = "journal_system"
local JUMPS = "journal_jumps"
local ROUTE = "journal_route"
local PHASE = "journal_phase"

-- Names arrive as empty strings from a panel that is present but has nothing
-- to say, and as empty tables from one that is absent altogether.
local function text(value)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return nil
end

function M.main(args)
    local destination = leg.trimmed(args and args[1])
    local kind = args and args[2]
    local return_destination = leg.trimmed(args and args[3])

    if (cygnixy.bb_get(STARTED) or 0) == 0 then
        cygnixy.bb_set(STARTED, 1)
        cygnixy.bb_set(JUMPS, 0)
        -- Every mission starts on the outward leg. Only if the blackboard
        -- has not already said otherwise, though: a mission that begins
        -- already turned -- which happens in these very tests, seeding _leg
        -- ahead of the first tick to check the second dock without replaying
        -- the first -- is not a mission this journal gets to correct.
        if cygnixy.bb_get("_leg") == nil then
            cygnixy.bb_set("_leg", "out")
        end
        -- Log version banner for flight delimiter tracking.
        log.info(
            "mission",
            "auto-warp-0 " .. tostring(cygnixy.bot_version) ..
                " on cygnixy " .. tostring(cygnixy.version)
        )

        if text(destination) then
            log.info(
                "mission",
                "bound for " .. destination .. ", looked up among the " .. tostring(kind) .. "s"
            )
            if text(return_destination) then
                log.info("mission", "and back to " .. return_destination)
            end
        else
            log.info("mission", "no destination given — flying the route already set")
        end
    end

    -- Phase observation and change logging.
    local phase = state.phase()

    order.observe(phase)

    local was_phase = cygnixy.bb_get(PHASE)
    if phase ~= was_phase then
        log.debug("phase", tostring(was_phase == nil and "-" or was_phase) .. " -> " .. phase)
        cygnixy.bb_set(PHASE, phase)

        log.forget("chose")
        log.forget("route_menu")

        -- Both marks belong to open_route_menu_and_warp; it owns the reset
        -- because it owns the names.
        open_route_menu_and_warp.forget_session_probe()

        order.ends_with_phase(phase)
    end

    if phase == state.UNKNOWN then
        log.steady("phase_unknown", "debug", "flight",
            "the client is saying nothing about where the ship is")
    else
        log.forget("phase_unknown")
    end

    -- Silence is not space. During a session change and in the unknown the
    -- client says nothing about where the ship is, and taking that for space
    -- would have the log announce an undocking every time the screen went
    -- black between systems.
    local now_place = state.place(phase) or cygnixy.bb_get(PLACE)

    local panel = cygnixy.eve.info_panel_container
    local location = panel and panel.info_panel_location_info
    local now_system = location and text(location.current_solar_system_name)

    -- A jump is seen, not performed: the name in the location panel changes
    -- when the client finishes the session change, whoever ordered it and
    -- however many attempts it took.
    local was_system = cygnixy.bb_get(SYSTEM)
    if now_system and text(was_system) and now_system ~= was_system then
        local jumps = (cygnixy.bb_get(JUMPS) or 0) + 1
        cygnixy.bb_set(JUMPS, jumps)
        log.info(
            "flight",
            "jumped into " .. now_system .. " — " .. tostring(log.jumps(jumps)) .. " so far"
        )
    end
    if now_system then
        cygnixy.bb_set(SYSTEM, now_system)
    end

    local was_place = cygnixy.bb_get(PLACE)
    if text(was_place) and now_place ~= nil and now_place ~= was_place then
        if now_place == "space" then
            log.info("flight", "undocked into " .. (now_system or "space"))
        else
            local expanded = location and location.expanded_content
            local station = expanded and text(expanded.current_station_name)
            local where = station or now_system or "a station"
            local jumps = log.jumps(cygnixy.bb_get(JUMPS) or 0)
            if jumps then
                log.info("flight", "docked at " .. where .. " after " .. jumps)
            else
                log.info("flight", "docked at " .. where)
            end
            -- The persistent half of "where is home". The operator's slot
            -- variables died with a reselect on 2026-08-20 13:35 and the
            -- rescue step ran with its destination empty; what survives every
            -- restart and reselect is the store, and in the mission loop the
            -- station this bot last docked at IS home — the loop docks there
            -- at the end of every iteration. Written only off a station name
            -- the client actually gave; a dock recorded as a system name is
            -- no address to fly to. rawget, for std/modules.lua's reason: the
            -- cygnixy table answers missing fields with an error, not nil.
            if station ~= nil and rawget(cygnixy, "store_set") ~= nil then
                cygnixy.store_set("last_docked_station", station)
            end
        end
    end
    if now_place ~= nil then
        cygnixy.bb_set(PLACE, now_place)
    end



    local route = panel and panel.info_panel_route
    local markers = (route and route.route_element_marker) and #route.route_element_marker or 0
    local before = cygnixy.bb_get(ROUTE) or 0

    -- Suppress false route-cleared events during session changes.
    if markers == 0 and not state.settled(phase) then
        markers = before
    end
    if markers > 0 and before == 0 then
        local next_stop = route and text(route.next_system)
        if next_stop then
            log.info("route", "the client is showing the route; next waypoint " .. next_stop)
        else
            log.info("route", "the client is showing the route")
        end
    elseif markers == 0 and before > 0 and now_place == "station" then
        -- Docked with the route gone is what the end of a leg looks like from
        -- the outside; the tree reads the same two facts to stop. Whether it
        -- is the end of the mission or only the end of the outward leg
        -- depends on whether a return destination was given and which leg
        -- was flying — the same question legs_done asks, asked here again so
        -- the log narrates the turn instead of staying silent about it.
        -- (return_destination is the same local read at the top of main.)
        local going_home = leg.current() == "out"
            and type(return_destination) == "string" and return_destination ~= ""
        if going_home then
            -- Leg's end, not the mission's: legs_done turns the ship around
            -- on this same tick, and the route panel will fill again.
            log.info("route", "the way out has been flown; turning home")
        elseif text(destination) then
            -- The destination is named again here so that the last line
            -- stands on its own. The line above can only say the system: the
            -- station's name lives in the location panel's expanded content,
            -- and a docked client with that panel collapsed does not carry
            -- it. leg.pick names whichever leg just ended: the outward
            -- destination on a one-way mission, the return one on a closed
            -- mission's second dock.
            local flown = leg.pick(destination, return_destination)
            log.info("mission", "the route to " .. flown .. " has been flown to its end")
        else
            log.info("mission", "the route has been flown to its end")
        end
    end
    cygnixy.bb_set(ROUTE, markers)

    return "Success"
end

return M
