local log = require("log")
local pointer = require("pointer")

local M = {}

-- Collapses every category in the results window.
--
-- "Jita" returns 498 results, 459 of them characters, and the wanted category
-- sits below all of them. Collapsed, the whole window is a short list of
-- category headers and the right one is a click away — no scrolling, no
-- guessing where the characters end.
--
-- Done when no group is expanded, which shows as the entries list being empty.
function M.main(args)
    local results = cygnixy.eve.search_results
    if not (results and results.groups and #results.groups > 0) then
        -- The window has not opened yet; the search is still running.
        return "Running"
    end

    local entries = results.entries
    if entries == nil or #entries == 0 then
        return "Success"
    end

    if results.collapse_all == nil or results.collapse_all.x == nil then
        log.error("route", "the results window offers no way to collapse its groups: " ..
            "the wanted category is buried under hundreds of rows")
        return "Failure"
    end

    local clicked, err = pointer.click(results.collapse_all)
    if not clicked then
        log.error("route", "the groups were not collapsed: " .. tostring(err))
        return "Failure"
    end
    return "Running"
end

return M
