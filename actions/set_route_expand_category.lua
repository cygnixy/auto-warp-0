local leg = require("leg")
local log = require("std.log")
local pointer = require("std.pointer")
local press = require("std.press")
local search = require("std.search")

local M = {}

-- Expands the category the destination is looked for in.
--
-- args[1] is the outward kind, args[2] the return one; leg.pick chooses
-- between them. Each is "system" or "station". The headers read "Solar
-- Systems (3)" and "Stations (12)" — name and count — so they are matched by
-- prefix, not equality: the count changes with every search.
function M.main(args)
    local kind = leg.pick(args and args[1], args and args[2])
    local wanted = search.category_of(kind)
    if wanted == nil then
        log.error("route", "unknown destination kind \"" .. tostring(kind) ..
            "\": it must be \"system\" or \"station\"")
        return "Failure"
    end

    local results = cygnixy.eve.search_results
    if not (results and results.groups and #results.groups > 0) then
        return "Running"
    end

    -- Something is expanded already: this action ran, the operator did it, or
    -- the search itself opened the only category it matched.
    if results.entries ~= nil and #results.entries > 0 then
        press.done("expand")
        return "Success"
    end

    local header = search.find_group(results.groups, wanted)
    if header == nil then
        log.error("route", "the search found no " .. wanted .. "; it offered " ..
            search.list_groups(results.groups))
        return "Failure"
    end

    -- One press, then the client's answer: a category header is a toggle: pressing it again collapses what it just opened.
    if press.pending("expand") then
        return "Running"
    end
    local clicked, err = pointer.click(header.region)
    press.made("expand")
    if not clicked then
        if pointer.transient(err) then
            log.repeated("expand", "debug", "route",
                "waiting for the foreground before expanding the category")
            return "Running"
        end
        log.error("route", "expanding the category failed: " .. tostring(err))
        return "Failure"
    end
    return "Running"
end

return M
