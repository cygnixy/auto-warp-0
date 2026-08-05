local log = require("log")
local pointer = require("pointer")
local search = require("search")

local M = {}

-- Right-clicks the row named by the destination, chooses Set Destination, and
-- is done when the client shows the route — not when the click was sent.
--
-- args[1] is the destination name. The row must match it exactly: a search for
-- "Jita" also returns four hundred characters with Jita in their names, and a
-- route to the wrong one is a long way home.
--
-- The route is the only proof the order was taken. There is no other: between
-- the press and the route the client shows nothing that says "heard you", so a
-- step that reported success on the press reported the press, not the route,
-- and the flight began with nothing to follow.
--
-- Waiting for it is done by watching, not by counting. An earlier version gave
-- the client ten seconds and failed the mission at the end of them, which is a
-- verdict passed by a clock: it called a slow client broken and a lost press
-- patient. Neither is a thing the client said. So this reads the panel each
-- tick, and while the route is not there and the row still is, it orders again
-- — setting the same destination twice costs nothing, and the loop ends the
-- moment the client draws the route, whether that is the first attempt or the
-- twentieth.
local CHOICES = {
    { text = "Set Destination", partial_match = false },
}

function M.main(args)
    local destination = args and args[1]
    if type(destination) ~= "string" or destination == "" then
        return "Failure"
    end

    -- The client has drawn the route: that is the whole job, whoever's press
    -- did it and however long it took.
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local markers = route and route.route_element_marker
    if markers ~= nil and #markers > 0 then
        log.forget("choose_menu")
        log.forget("chosen")
        return "Success"
    end

    local results = cygnixy.eve.search_results
    if not (results and results.entries and #results.entries > 0) then
        return "Running"
    end

    local row, why = search.find_entry(results.entries, destination)
    if row == nil then
        -- An answer, not an accident: the client looked and there is no such
        -- place. Trying again would ask the same question forever.
        log.error("route", tostring(why))
        return "Failure"
    end

    local entry, menu_error = pointer.open_menu_and_choose(row.region, CHOICES)
    if entry == nil then
        log.repeated("choose_menu", "debug", "route",
            "the row \"" .. row.text .. "\" gave no menu: " .. tostring(menu_error))
        return "Running"
    end

    -- Running, not Success: the order is given, the route is not yet there.
    -- The next tick reads the panel and decides.
    log.repeated("chosen", "info", "route", "destination set to \"" .. row.text .. "\"")
    return "Running"
end

return M
