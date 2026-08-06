local log = require("log")
local press = require("press")
local state = require("state")
local order = require("order")
local guard = require("guard")
local pointer = require("pointer")
local warp_choice = require("warp_choice")

local M = {}

-- Markers are addressed by path rather than by the regions read out of them:
-- along a path the click point is worked out with the windows lying over the
-- info panel taken into account, and a marker is eight pixels across — a window
-- over its corner is enough to swallow the click.
--
-- All of them are offered, in the order the panel lists them, because the first
-- is not always the gate: on the leg into a system the panel carries two, and
-- the leading one is the system just reached.
local function marker_paths(count)
    local paths = {}
    for index = 1, count do
        paths[index] = string.format(
            "info_panel_container.info_panel_route.route_element_marker[%d].region",
            index - 1
        )
    end
    return paths
end

local PATIENCE_MS = 8000
local PROBE_EVERY_MS = 2000
local PANEL_HELD_MS = 700

function M.main(args)
    -- Mid-session probing: wait until the route panel is fresh before trying.
    if state.phase() == state.SESSION then
        if not guard.panel_fresh(PANEL_HELD_MS) then
            return "Running"
        end
    end

    -- An order is outstanding: wait up to 8s without movement before ordering again.
    if order.pending(PATIENCE_MS, 1.0) then
        return "Running"
    end

    -- Take permission for mid-session probing if in session change.
    if state.phase() == state.SESSION then
        if press.pending("session_probe", PROBE_EVERY_MS) then
            return "Running"
        end
        press.made("session_probe")
        cygnixy.bb_set("panel_fresh", -1)
        log.debug("flight", "the route panel has caught up and held; trying it mid-session")
    end

    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    if not (route and route.route_element_marker and #route.route_element_marker > 0) then
        return "Running"
    end

    local paths = marker_paths(#route.route_element_marker)
    local entry, err = pointer.open_menu_and_choose(paths, warp_choice.choices)
    if entry == nil then
        log.repeated("route_menu", "debug", "flight",
            "no order could be given from the route marker: " .. tostring(err))
        return "Running"
    end

    warp_choice.after_chosen(entry)
    order.issue()
    return "Success"
end

return M
