local log = require("std.log")
local press = require("std.press")
local act = require("std.act")

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

    -- Detects search panel slide animation and waits for coordinates to settle.
    local field_x = search and search.field and search.field.x
    local seen = cygnixy.bb_get("search_field_x")
    if type(field_x) == "number" then
        cygnixy.bb_set("search_field_x", field_x)
        if type(seen) == "number" and seen ~= field_x then
            log.debug("route", "the search panel is sliding open; waiting rather than pressing")
            return "Running"
        end
    end

    -- Pacing cooldown to prevent rapid toggling of search button.
    if press.pending("open_search") then
        return "Running"
    end
    local icon = icons.search
    log.debug("route", "pressing the magnifier: display=" .. tostring(search and search.display) ..
        ", icon=" .. tostring(icon and icon.x) .. "," .. tostring(icon and icon.y) ..
        ", field=" .. tostring(search and search.field and search.field.x))

    -- The panel opens a frame later; the tree is re-read on the next tick and
    -- the first condition above will see it.
    return act.click_or_fail("open_search", "info_panel_container.icons.search", {
        subject = "route",
        waiting = "waiting for the foreground before opening the search",
        failed = "opening the search failed: ",
    })
end

return M
