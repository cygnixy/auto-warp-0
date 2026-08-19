local log = require("std.log")
local act = require("std.act")
local press = require("std.press")

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

    -- Directly checks text content rather than clear button presence.
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
    return act.click_or_fail("clear_field", "info_panel_search.clear", {
        subject = "route",
        waiting = "waiting for the foreground before clearing the search field",
        failed = "clearing the search field failed: ",
    })
end

return M
