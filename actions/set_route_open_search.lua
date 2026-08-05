local log = require("log")
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
        return "Success"
    end

    local icons = cygnixy.eve.info_panel_container and cygnixy.eve.info_panel_container.icons
    if not (icons and icons.search) then
        log.error("route", "the search cannot be opened: its icon is not on screen")
        return "Failure"
    end

    local clicked, err = pointer.click("info_panel_container.icons.search")
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
