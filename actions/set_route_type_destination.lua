local log = require("log")
local pointer = require("pointer")
local press = require("press")

local M = {}

-- Clicks into the search field and types the destination.
--
-- The click is what focuses the field: without it the characters reach the
-- game as hotkeys, and EVE has a shortcut for most letters -- the recon that
-- taught us this opened the settings window and an information panel before
-- anyone noticed. Typing goes through cygnixy.type_text, which sends Unicode
-- events: the operator's keyboard layout cannot turn "jita" into something
-- else.
--
-- Typing is a press like any other, and the rule is the same: type once, then
-- let the client answer. It is worse here than elsewhere, because typing does
-- not replace what is in the field -- it adds to it. Without the wait this
-- action typed the destination once a tick, each time onto the end of the
-- last, and the field filled with copies of a station name that could never
-- match the one being looked for. On 2026-08-05 at 20:34 it did that
-- twenty-three times running and the mission never left the hangar.
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
        press.done("type_destination")
        return "Success"
    end

    -- Pressed a moment ago and the client has not caught up. Waiting is the
    -- whole point: the next press would append, not correct.
    if press.pending("type_destination") then
        return "Running"
    end

    -- Anything else in the field is in the way, and has to go before more
    -- text arrives. Half a name from an interrupted attempt, a name typed
    -- twice, or something the operator left there -- all the same problem.
    local text = search.text
    if type(text) == "string" and text ~= "" then
        if not (search.clear and search.clear.x ~= nil) then
            log.error("route", "the search field holds \"" .. text ..
                "\" and offers no way to clear it")
            return "Failure"
        end
        local cleared, clear_error = pointer.click(search.clear)
        press.made("type_destination")
        if not cleared then
            if pointer.transient(clear_error) then
                log.repeated("clear_before_typing", "debug", "route",
                    "waiting for the foreground before clearing the search field")
                return "Running"
            end
            log.error("route", "clearing the search field failed: " .. tostring(clear_error))
            return "Failure"
        end
        return "Running"
    end

    local focused, click_error = pointer.click(search.field)
    if not focused then
        if pointer.transient(click_error) then
            log.repeated("focus_field", "debug", "route",
                "waiting for the foreground before focusing the search field")
            return "Running"
        end
        log.error("route", "focusing the search field failed: " .. tostring(click_error) ..
            " -- text typed now would go to whatever holds the cursor")
        return "Failure"
    end

    local typed, type_error = cygnixy.type_text(destination)
    if not typed then
        if pointer.transient(type_error) then
            log.repeated("type_destination", "debug", "route",
                "waiting for the foreground before typing the destination")
            return "Running"
        end
        log.error("route", "typing the destination failed: " .. tostring(type_error))
        return "Failure"
    end

    press.made("type_destination")
    cygnixy.press_key(0x0D)
    log.repeated("searching", "info", "route", "searching for \"" .. destination .. "\"")
    return "Running"
end

return M
