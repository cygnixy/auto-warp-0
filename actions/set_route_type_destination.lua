local leg = require("leg")
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
    -- args[1] is the outward destination, args[2] the return one; leg.pick
    -- chooses between them by what leg.lua reads off the blackboard.
    local destination = leg.pick(args and args[1], args and args[2])
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

    -- Anything at all in the field is in the way, and the cross is how that is
    -- known: it appears with the first character and goes with the last. The
    -- text is not always readable -- under a modal it reads as nothing -- and
    -- typing on the strength of an empty read is what put the destination into
    -- the field twice on 2026-08-05, until the client refused the search as
    -- too long and blocked itself with the refusal.
    -- Anything in the field is in the way: typing adds to it rather than
    -- replacing it. The text is what says so -- the cross is always there on
    -- this client, empty field or not, and judging by it left the bot
    -- clearing nothing for ever.
    local text = search.text
    if type(text) == "string" and text ~= "" then
        local cross = search.clear
        if not (cross and cross.x ~= nil) then
            log.error("route", "the search field holds \"" .. text ..
                "\" and offers no cross to clear it")
            return "Failure"
        end
        local cleared, clear_error = pointer.click(cross)
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
