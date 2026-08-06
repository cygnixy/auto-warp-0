local log = require("log")
local press = require("press")
local pointer = require("pointer")

local M = {}

-- Opens the search panel of the info panel, if it is not open already.
--
-- The magnifier is a toggle, not a button: clicking it while the panel is open
-- closes it. And the panel keeps its region in the parsed tree even when
-- closed, so a bot that aims by remembered coordinates without asking the flag
-- clicks whatever lies underneath — a constellation link, in one memorable
-- case. The flag decides; the coordinates only follow.
function M.main(args)
    local search = cygnixy.eve.info_panel_search
    if search and search.display == true then
        -- Already open -- whether this action opened it, an earlier mission
        -- did, or the operator did. The icon is a toggle: pressing it now
        -- would close the very panel that is wanted.
        press.done("open_search")
        cygnixy.bb_set("search_field_x", -1)
        return "Success"
    end

    local icons = cygnixy.eve.info_panel_container and cygnixy.eve.info_panel_container.icons
    if not (icons and icons.search) then
        log.error("route", "the search cannot be opened: its icon is not on screen")
        return "Failure"
    end

    -- A panel on its way open is a panel answering. It slides in, and its
    -- field slides with it: on 2026-08-06 the field stood at x=98 for one
    -- press and x=103 for the next, two seconds later, with display false
    -- throughout -- the flag turns true only once the panel has arrived. The
    -- first press had worked, and the second landed on something moving. The
    -- same lesson as the ship's speed: motion is the client obeying.
    local field_x = search and search.field and search.field.x
    local seen = cygnixy.bb_get("search_field_x")
    if type(field_x) == "number" then
        cygnixy.bb_set("search_field_x", field_x)
        if type(seen) == "number" and seen ~= field_x then
            log.debug("route", "the search panel is sliding open; waiting rather than pressing")
            return "Running"
        end
    end

    -- The panel is not open and the icon is a toggle: press it once and let
    -- the client answer. Pressing every tick would open and close it in turn,
    -- which is how the closing half of this pair spent twenty-two seconds on
    -- 2026-08-05.
    if press.pending("open_search") then
        return "Running"
    end
    -- What the panel says about itself at the moment of the press, because on
    -- 2026-08-06 the search opened on the fourth press and seven seconds after
    -- the mission began, and nothing in the log said why the first three did
    -- nothing. Guessing has cost enough today; the next flight will say.
    local icon = icons.search
    log.debug("route", "pressing the magnifier: display=" .. tostring(search and search.display) ..
        ", icon=" .. tostring(icon and icon.x) .. "," .. tostring(icon and icon.y) ..
        ", field=" .. tostring(search and search.field and search.field.x))

    local clicked, err = pointer.click("info_panel_container.icons.search")
    press.made("open_search")
    if not clicked then
        if pointer.transient(err) then
            log.repeated("open_search", "debug", "route",
                "waiting for the foreground before opening the search")
            return "Running"
        end
        log.error("route", "opening the search failed: " .. tostring(err))
        return "Failure"
    end

    -- The panel opens a frame later; the tree is re-read on the next tick and
    -- the first condition above will see it.
    return "Running"
end

return M
