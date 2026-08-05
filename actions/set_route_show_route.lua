local log = require("log")
local pointer = require("pointer")

local M = {}

-- Opens the route block of the info panel, if it is not shown already.
--
-- Everything downstream reads the route from that block: is_route_set, the
-- markers the ship is steered by, the exit condition of the whole flight. When
-- the block is collapsed the parse has no InfoPanelRoute at all, so a route
-- that exists looks exactly like a route that does not — on 2026-08-05 the bot
-- laid a route, could not see it, and stopped in the station believing there
-- was nothing to fly.
--
-- The icon is a toggle, like the magnifier: it is pressed only while the block
-- is absent, and the next tick reads the tree again to see the result.
function M.main(args)
    local panel = cygnixy.eve.info_panel_container
    if panel and panel.info_panel_route and panel.info_panel_route.route_element_marker then
        return "Success"
    end

    local icons = panel and panel.icons
    if not (icons and icons.route) then
        log.error("route", "the route block cannot be opened: its icon is not on screen")
        return "Failure"
    end

    local clicked, err = pointer.click("info_panel_container.icons.route")
    if not clicked then
        if pointer.transient(err) then
            log.repeated("show_route", "debug", "route",
                "waiting for the foreground before opening the route block")
            return "Running"
        end
        log.error("route", "opening the route block failed: " .. tostring(err))
        return "Failure"
    end
    return "Running"
end

return M
