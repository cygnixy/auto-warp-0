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

    -- The cross is the sign, not the text. It appears with the first character
    -- typed and goes with the last, while the text itself is not always
    -- readable -- with a modal over the panel it reads as nothing at all, and
    -- an empty read meant "nothing to clear" here and "safe to type" next
    -- door. That pair typed the destination onto itself on 2026-08-05 until
    -- the client refused the search as too long.
    local cross = search.clear
    if not (cross and cross.x ~= nil) then
        press.done("clear_field")
        return "Success"
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
