local leg = require("leg")
local log = require("std.log")
local pointer = require("std.pointer")
local search = require("search")
local press = require("std.press")

local M = {}

-- Collapses every category in the results window.
--
-- "Jita" returns 498 results, 459 of them characters, and the wanted category
-- sits below all of them. Collapsed, the whole window is a short list of
-- category headers and the right one is a click away — no scrolling, no
-- guessing where the characters end.
--
-- Done when no group is expanded, which shows as the entries list being empty
-- -- or when the row being looked for is already in front of us, which is the
-- ordinary case for a name specific enough to match one thing.
--
-- args[1] is the outward destination, args[2] the return one; leg.pick
-- chooses between them. Without it this action collapsed whatever the
-- search had opened and the next step opened it again: a search for a full
-- station name returns that station alone, expanded, and the bot spent two
-- gestures putting it back the way it found it.
function M.main(args)
    local destination = leg.pick(args and args[1], args and args[2])

    local results = cygnixy.eve.search_results
    if not (results and results.groups and #results.groups > 0) then
        -- The window has not opened yet; the search is still running.
        return "Running"
    end

    local entries = results.entries
    if entries == nil or #entries == 0 then
        press.done("collapse")
        return "Success"
    end

    -- The row is here already. Collapsing now would hide the very thing the
    -- search was for.
    if type(destination) == "string" and destination ~= "" then
        local row = search.find_entry(entries, destination)
        if row ~= nil then
            press.done("collapse")
            return "Success"
        end
    end

    if results.collapse_all == nil or results.collapse_all.x == nil then
        log.error("route", "the results window offers no way to collapse its groups: " ..
            "the wanted category is buried under hundreds of rows")
        return "Failure"
    end

    -- One press, then the client's answer: collapsing again mid-redraw lands on a list that has moved under the cursor.
    if press.pending("collapse") then
        return "Running"
    end
    local clicked, err = pointer.click(results.collapse_all)
    press.made("collapse")
    if not clicked then
        if pointer.transient(err) then
            log.repeated("collapse", "debug", "route",
                "waiting for the foreground before collapsing the groups")
            return "Running"
        end
        log.error("route", "collapsing the groups failed: " .. tostring(err))
        return "Failure"
    end
    return "Running"
end

return M
