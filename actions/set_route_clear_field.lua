local log = require("log")
local pointer = require("pointer")
local press = require("press")

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

    -- The text is the truth, now that it is read from the field itself and
    -- not from a label the client may not draw. The cross is not a sign of
    -- anything: this client keeps that icon inside the edit box whether or
    -- not there is text to clear, and reading it as "something is in there"
    -- had the bot clearing an empty field for ever on 2026-08-05 at 21:08.
    local text = search.text
    if type(text) ~= "string" or text == "" then
        press.done("clear_field")
        return "Success"
    end

    local cross = search.clear
    if not (cross and cross.x ~= nil) then
        log.error("route", "the search field holds \"" .. text ..
            "\" and offers no cross to clear it: a new name would be typed onto the old one")
        return "Failure"
    end

    -- One press, then the client's answer: the cross clears the field; pressing it again while the client redraws hits whatever replaces it.
    if press.pending("clear_field") then
        return "Running"
    end
    local cleared, err = pointer.click(cross)
    press.made("clear_field")
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
