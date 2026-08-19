local log = require("std.log")
local act = require("std.act")
local press = require("std.press")

local M = {}

-- Ensures the route panel is visible and expanded to expose waypoint markers.
-- The route icon behaves as a toggle control.
function M.main(args)
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local markers = route and route.route_element_marker
    local jumps = route and route.jumps

    if markers ~= nil and #markers > 0 then
        press.done("show_route")
        press.done("expand_route")
        return "Success"
    end

    -- Expands collapsed route block when jumps > 0 but waypoint markers are hidden.
    if route and type(jumps) == "number" and jumps > 0 then
        local expand = route.expand
        if not (expand and expand.x ~= nil) then
            log.error("route", "the route block is collapsed and offers no way to expand it")
            return "Failure"
        end
        local outcome, expand_error = act.click("expand_route", expand)
        if outcome == act.WAITING or outcome == act.REFUSED then
            log.repeated("expand_route", "debug", "route",
                "the route block was not expanded: " .. tostring(expand_error))
        end
        return "Running"
    end

    -- No route at all: nothing to show, and nothing downstream needs the block
    -- until there is.
    if route and jumps == 0 then
        press.done("show_route")
        return "Success"
    end

    local icons = panel and panel.icons
    if not (icons and icons.route) then
        log.error("route", "the route block cannot be opened: its icon is not on screen")
        return "Failure"
    end

    -- One press, then the client's answer: the route block icon is a toggle: pressing it again hides what it just showed.
    return act.click_or_fail("show_route", "info_panel_container.icons.route", {
        subject = "route",
        waiting = "waiting for the foreground before opening the route block",
        failed = "opening the route block failed: ",
    })
end

return M
