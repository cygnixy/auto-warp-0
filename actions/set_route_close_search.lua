local log = require("std.log")
local pointer = require("std.pointer")
local press = require("std.press")

local M = {}

-- Puts the results window away once the route is set.
--
-- The window is a real one in the middle of the screen, and everything the
-- flight aims at afterwards lies under it: the route markers, the overview,
-- the stargate. A click meant for a marker that lands on a list of
-- Jita-named characters presses nothing, and the host refuses a path whose
-- target is covered, so the flight stalls with no visible reason.
--
-- The search panel is left alone. It is a strip inside the info panel, it
-- covers nothing the flight needs, and its magnifier is a toggle: pressing it
-- again is one more chance to reopen what was just closed for no gain at all.
-- The bot presses that icon once per mission, to open the search, and never
-- again.
--
-- Nothing here is timed. The window closes when its Close button is pressed;
-- if a press does not land the answer is to press again, not to count. The
-- ways out are the ones the client offers -- the window gone, or no button to
-- close it with.

local function done()
    log.forget("close_results")
    press.done("close_results")
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
        return "Running"
    end

    if results and results.groups and #results.groups > 0 then
        -- Standing there with no way to dismiss it. Nothing here can help, and
        -- the route is set either way.
        log.warn("route", "the results window offers no way to close it")
    end

    return done()
end

return M
