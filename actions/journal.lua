local log = require("log")
local state = require("state")

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
    local destination = args and args[1]
    local kind = args and args[2]

    if (cygnixy.bb_get(STARTED) or 0) == 0 then
        cygnixy.bb_set(STARTED, 1)
        cygnixy.bb_set(JUMPS, 0)
        if text(destination) then
            log.info(
                "mission",
                "bound for " .. destination .. ", looked up among the " .. tostring(kind) .. "s"
            )
        else
            log.info("mission", "no destination given — flying the route already set")
        end
    end

    -- The phase, read from the same module the tree acts on, so the log and
    -- the behaviour can never disagree about what is going on.
    local phase = state.phase()
    local was_phase = cygnixy.bb_get(PHASE)
    if phase ~= was_phase then
        -- Debug, not info: phases change several times a jump and the reader
        -- following the mission does not need them. The reader hunting a
        -- fault needs nothing else.
        log.debug("phase", tostring(was_phase == nil and "-" or was_phase) .. " -> " .. phase)
        cygnixy.bb_set(PHASE, phase)
    end

    -- Silence is not space. During a session change and in the unknown the
    -- client says nothing about where the ship is, and taking that for space
    -- would have the log announce an undocking every time the screen went
    -- black between systems.
    local now_place = state.place(phase) or cygnixy.bb_get(PLACE)

    local panel = cygnixy.eve.info_panel_container
    local location = panel and panel.info_panel_location_info
    local now_system = location and text(location.current_solar_system_name)

    -- Whether the ship got anywhere this tick. The counters that turn a
    -- repeated line into a warning mean "the same thing to no effect", and
    -- only this action can tell effect from repetition: the tactics see one
    -- gate at a time and give every one of them the same order. On 2026-08-05
    -- at 17:53 the third "Jump Through Stargate" was warned about ten seconds
    -- after the jump it had caused, because nobody had told the counter that
    -- the ship had moved.
    local moved = false

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
        moved = true
    end
    if now_system then
        cygnixy.bb_set(SYSTEM, now_system)
    end

    local was_place = cygnixy.bb_get(PLACE)
    if text(was_place) and now_place ~= nil and now_place ~= was_place then
        moved = true
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
        end
    end
    if now_place ~= nil then
        cygnixy.bb_set(PLACE, now_place)
    end

    if moved then
        -- The orders that got the ship here worked; the next complaint about
        -- them starts from one, not from where the last leg left off.
        log.forget("chose")
        log.forget("route_menu")
    end

    local route = panel and panel.info_panel_route
    local markers = (route and route.route_element_marker) and #route.route_element_marker or 0
    local before = cygnixy.bb_get(ROUTE) or 0
    if markers > 0 and before == 0 then
        local next_stop = route and text(route.next_system)
        if next_stop then
            log.info("route", "the client is showing the route; next waypoint " .. next_stop)
        else
            log.info("route", "the client is showing the route")
        end
    elseif markers == 0 and before > 0 and now_place == "station" then
        -- Docked with the route gone is what the end of a mission looks like
        -- from the outside; the tree reads the same two facts to stop.
        --
        -- The destination is named again here so that the last line stands on
        -- its own. The line above can only say the system: the station's name
        -- lives in the location panel's expanded content, and a docked client
        -- with that panel collapsed does not carry it.
        if text(destination) then
            log.info("mission", "the route to " .. destination .. " has been flown to its end")
        else
            log.info("mission", "the route has been flown to its end")
        end
    end
    cygnixy.bb_set(ROUTE, markers)

    return "Success"
end

return M
