local pointer = require("pointer")

local M = {}

-- Clicks into the search field and types the destination.
--
-- The click is what focuses the field: without it the characters reach the
-- game as hotkeys, and EVE has a shortcut for most letters — the recon that
-- taught us this opened the settings window and an information panel before
-- anyone noticed. Typing goes through cygnixy.type_text, which sends Unicode
-- events: the operator's keyboard layout cannot turn "jita" into something
-- else.
function M.main(args)
    local destination = args and args[1]
    if type(destination) ~= "string" or destination == "" then
        return "Failure"
    end

    local search = cygnixy.eve.info_panel_search
    if not (search and search.display == true and search.field) then
        return "Failure"
    end

    -- Already typed: the results are on their way, or already here.
    if search.text == destination then
        return "Success"
    end

    local focused, click_error = pointer.click(search.field)
    if not focused then
        cygnixy.info("SET ROUTE: the search field was not focused: " .. tostring(click_error))
        return "Failure"
    end

    local typed, type_error = cygnixy.type_text(destination)
    if not typed then
        cygnixy.info("SET ROUTE: " .. destination .. " was not typed: " .. tostring(type_error))
        return "Failure"
    end

    cygnixy.press_key(0x0D)
    cygnixy.info("SET ROUTE: searching for " .. destination)
    return "Running"
end

return M
