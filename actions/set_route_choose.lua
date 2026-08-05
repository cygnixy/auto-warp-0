local log = require("log")
local pointer = require("pointer")
local search = require("search")

local M = {}

-- Right-clicks the row named by the destination and chooses Set Destination.
--
-- args[1] is the destination name. The row must match it exactly: a search for
-- "Jita" also returns four hundred characters with Jita in their names, and a
-- route to the wrong one is a long way home.
local CHOICES = {
    { text = "Set Destination", partial_match = false },
}

function M.main(args)
    local destination = args and args[1]
    if type(destination) ~= "string" or destination == "" then
        return "Failure"
    end

    local results = cygnixy.eve.search_results
    if not (results and results.entries and #results.entries > 0) then
        return "Running"
    end

    local row, why = search.find_entry(results.entries, destination)
    if row == nil then
        log.error("route", tostring(why))
        return "Failure"
    end

    local entry, menu_error = pointer.open_menu_and_choose(row.region, CHOICES)
    if entry == nil then
        log.repeated("choose_menu", "debug", "route",
            "the row \"" .. row.text .. "\" gave no menu: " .. tostring(menu_error))
        return "Running"
    end

    log.info("route", "destination set to \"" .. row.text .. "\"")
    return "Success"
end

return M
