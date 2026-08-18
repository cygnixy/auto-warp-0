local leg = require("leg")
local log = require("std.log")
local pointer = require("std.pointer")
local press = require("std.press")

local M = {}

-- Maximum retry attempts for clearing and typing destination into search field.
local MAX_ATTEMPTS = 3

-- Focuses the search input field and types the destination text via Unicode events.
--
-- @param args table args[1] = destination, args[2] = return_destination
-- @return string "Success", "Running", or "Failure"
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
        cygnixy.bb_set("type_destination_attempts", 0)
        return "Success"
    end

    -- Pressed a moment ago and the client has not caught up. Waiting is the
    -- whole point: the next press would append, not correct.
    if press.pending("type_destination") then
        return "Running"
    end

    -- Checks if input field already contains stale text that requires clearing.
    local text = search.text
    if type(text) == "string" and text ~= "" then
        local cross = search.clear
        if not (cross and cross.x ~= nil) then
            log.error("route", "the search field holds \"" .. text ..
                "\" and offers no cross to clear it")
            return "Failure"
        end

        local attempts = cygnixy.bb_get("type_destination_attempts") or 0
        if attempts >= MAX_ATTEMPTS then
            log.error("route", "the search field cannot be made to hold \"" .. destination ..
                "\": it holds \"" .. text .. "\"")
            return "Failure"
        end

        log.repeated("retype", "warn", "route",
            "the search field holds \"" .. text .. "\" instead of \"" .. destination ..
                "\"; clearing it to type again")
        local cleared, clear_error = pointer.click("info_panel_search.clear")

        -- The operator holding the foreground is not the field's fault: a
        -- tick later they may have handed it back, and spending an attempt
        -- on a click that never happened would fail the mission over
        -- something that was never wrong with the search.
        if not cleared and pointer.transient(clear_error) then
            log.repeated("clear_before_typing", "debug", "route",
                "waiting for the foreground before clearing the search field")
            return "Running"
        end

        -- Counted here and nowhere else: a cross hidden under another window
        -- is refused by click_path without raising an error a human would
        -- see, so this is the one branch every failure to clear -- seen or
        -- silent -- passes through, and the one place the budget of retries
        -- is spent. Typing afterwards does not spend it again, or a single
        -- clear-then-retype cycle would cost two of the three attempts the
        -- comment above promises instead of one.
        press.made("type_destination")
        cygnixy.bb_set("type_destination_attempts", attempts + 1)
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
