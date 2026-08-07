local log = require("std.log")
local pointer = require("std.pointer")
local press = require("std.press")

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
    local route = panel and panel.info_panel_route
    local markers = route and route.route_element_marker
    local jumps = route and route.jumps

    if markers ~= nil and #markers > 0 then
        press.done("show_route")
        press.done("expand_route")
        return "Success"
    end

    -- The block is there and the header counts jumps, but no markers are drawn:
    -- the panel is collapsed, and collapsed it shows nothing to aim at. The
    -- flight steers by those markers, so the panel is expanded before anything
    -- else happens. This is the state the bot hung in on 2026-08-05 at 21:13 --
    -- route laid, panel shut, nothing visible to click.
    if route and type(jumps) == "number" and jumps > 0 then
        local expand = route.expand
        if not (expand and expand.x ~= nil) then
            log.error("route", "the route block is collapsed and offers no way to expand it")
            return "Failure"
        end
        if press.pending("expand_route") then
            return "Running"
        end
        local opened, expand_error = pointer.click(expand)
        press.made("expand_route")
        if not opened then
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
    if press.pending("show_route") then
        return "Running"
    end
    local clicked, err = pointer.click("info_panel_container.icons.route")
    press.made("show_route")
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
