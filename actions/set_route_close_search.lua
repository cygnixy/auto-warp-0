local log = require("log")
local press = require("press")
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
-- Nothing here is timed. An earlier version gave each window ten seconds and
-- then flew on regardless, which is a clock deciding what only the client can:
-- the results window closes when its Close button is pressed, and if a press
-- does not land the answer is to press again, not to count. The ways out are
-- the ones the client offers — the window gone, or no button to close it with.

local function done()
    log.forget("close_results")
    log.forget("close_panel")
    press.done("close_results")
    press.done("close_panel")
    return "Success"
end

function M.main(args)
    -- A window that is not on screen arrives as an empty table, not as nil, so
    -- presence is judged by what can be addressed rather than by the table
    -- being there at all.
    local results = cygnixy.eve.search_results
    local close = results and results.close
    if close and close.x ~= nil then
        -- The window is still there, but the last press may not have been
        -- answered yet, and a second one would land on whatever the client
        -- puts in its place.
        if press.pending("close_results") then
            return "Running"
        end
        local clicked, err = pointer.click(close)
        press.made("close_results")
        if not clicked then
            log.repeated("close_results", "debug", "route",
                "the results window was not closed: " .. tostring(err))
        end
        -- Running either way: the window is still on screen this tick, and
        -- the next one reads whether the press took.
        return "Running"
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

    -- The magnifier is a toggle: a press while the last one is still being
    -- answered opens again what it just closed. This is the pair of presses
    -- that fought each other forty-three times on 2026-08-05.
    if press.pending("close_panel") then
        return "Running"
    end
    local clicked, err = pointer.click("info_panel_container.icons.search")
    press.made("close_panel")
    if not clicked then
        log.repeated("close_panel", "debug", "route",
            "the search panel was not closed: " .. tostring(err))
    end
    return "Running"
end

return M
