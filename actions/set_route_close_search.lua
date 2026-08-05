local log = require("log")
local pointer = require("pointer")

local M = {}

-- Puts the search away once the route is set: first the results window, then
-- the panel that opened it.
--
-- Neither closes itself. The results window is a real window in the middle of
-- the screen, and everything the flight aims at afterwards lies under it — the
-- route markers, the overview, the stargate in space. A click meant for a
-- marker that lands on a list of Jita-named characters instead presses nothing
-- and the tick is lost; worse, the host's own click_path sees the target
-- covered and refuses it, so the flight stalls with no visible reason. The
-- panel is smaller but it is a toggle left in the "on" position, and the next
-- mission that opens the search would close it instead.
--
-- The order is not free: the results window belongs to the search, and closing
-- the panel first leaves the window standing with nothing to dismiss it from.
--
-- Done when neither is on screen, which is also true when there was nothing to
-- close — a route that was already set is reached without any search at all.
local WAIT_SECONDS = 10
local SINCE = "set_route_close_search_since"

local function done()
    cygnixy.bb_set(SINCE, 0)
    return "Success"
end

-- Gives up after the deadline, and gives up with Success.
--
-- The route is already set by the time this runs; failing the command here
-- would throw away the work over a window that refuses to shut. The operator
-- is told, the flight goes on with the window in the way.
local function waiting(what)
    local since = cygnixy.bb_get(SINCE)
    local now = os.time()
    if since == nil or since == 0 then
        cygnixy.bb_set(SINCE, now)
        return "Running"
    end
    if now - since > WAIT_SECONDS then
        cygnixy.bb_set(SINCE, 0)
        log.warn("route", what .. " would not close within " .. WAIT_SECONDS ..
            "s — flying on with it on screen")
        return "Success"
    end
    return "Running"
end

function M.main(args)
    -- A window that is not on screen arrives as an empty table, not as nil, so
    -- presence is judged by what can be addressed rather than by the table
    -- being there at all.
    local results = cygnixy.eve.search_results
    local close = results and results.close
    if close and close.x ~= nil then
        local clicked, err = pointer.click(close)
        if not clicked then
            log.repeated("close_results", "debug", "route",
                "the results window was not closed: " .. tostring(err))
        end
        return waiting("the results window")
    end

    if results and results.groups and #results.groups > 0 then
        -- Standing there with no way to dismiss it. The panel below is closed
        -- anyway: the route is set and the window blocks nothing the client
        -- itself will not redraw.
        log.warn("route", "the results window offers no way to close it")
    end

    local search = cygnixy.eve.info_panel_search
    if not (search and search.display == true) then
        return done()
    end

    local icons = cygnixy.eve.info_panel_container and cygnixy.eve.info_panel_container.icons
    if not (icons and icons.search) then
        -- The panel is open but its magnifier is out of reach; nothing here can
        -- close it, and the route does not depend on it.
        return done()
    end

    local clicked, err = pointer.click("info_panel_container.icons.search")
    if not clicked then
        log.repeated("close_panel", "debug", "route",
            "the search panel was not closed: " .. tostring(err))
    end
    return waiting("the search panel")
end

return M
