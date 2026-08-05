local log = require("log")
local pointer = require("pointer")

local M = {}

-- Empties the search field before a new name is typed.
--
-- Typing over a previous query glues two names into one that matches nothing,
-- and the field keeps what was typed until it is cleared. The cross inside the
-- field appears together with the text, so its absence means the field is
-- already empty.
function M.main(args)
    local search = cygnixy.eve.info_panel_search
    if not (search and search.display == true) then
        return "Failure"
    end

    local text = search.text
    if type(text) ~= "string" or text == "" then
        return "Success"
    end

    if search.clear == nil or search.clear.x == nil then
        log.error("route", "the search field holds \"" .. text ..
            "\" and offers no way to clear it: a new name would be typed onto the old one")
        return "Failure"
    end

    local cleared, err = pointer.click(search.clear)
    if not cleared then
        if pointer.transient(err) then
            log.repeated("clear_field", "debug", "route",
                "waiting for the foreground before clearing the search field")
            return "Running"
        end
        log.error("route", "clearing the search field failed: " .. tostring(err))
        return "Failure"
    end
    return "Running"
end

return M
