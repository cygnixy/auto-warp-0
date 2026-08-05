local log = require("log")
local state = require("state")
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

-- How many ticks a ship may be seen moving under an order before the order is
-- given again anyway.
--
-- Not a deadline on the client: the phase changing clears the wait at once,
-- and that is what normally ends it — three seconds, two or three ticks. This
-- only stops the bot waiting forever on a ship that moves without ever
-- reaching a manoeuvre, which is how 19:25 ended: drifting out of a station,
-- never standing still, never ordered anything again.
local PATIENCE = 10

function M.main(args)
    -- The session change is being tested, and tested cheaply.
    --
    -- The tree waited it out because the client "opens no context menu while
    -- the session is changing" — written down long ago and never measured.
    -- The wait costs nine and a half seconds after every jump: twenty-eight
    -- seconds of the four-and-a-half-minute flight of 20:14, a tenth of it.
    --
    -- So one probe per session change, not one per tick. If the menu opens,
    -- the ship is on its way to the next gate eight seconds early and the log
    -- says "ordered". If it does not, the log says "no context menu opened",
    -- the gesture cost a second, and the bot waits as before. Either way the
    -- next run answers the question with evidence.
    if state.phase() == state.SESSION then
        if (cygnixy.bb_get("phase_try") or 0) == 1 then
            return "Running"
        end
        cygnixy.bb_set("phase_try", 1)
        log.debug("flight", "trying the route marker during the session change")
    end

    -- An order of ours is outstanding, and the ship is moving: it is being
    -- obeyed, and a second order would only interrupt the first. Speed alone
    -- would not do — a ship pushed out of a station moves with nothing
    -- ordered — so it is read together with the flag that says we ordered.
    if (cygnixy.bb_get("order_pending") or 0) == 1 then
        local shipui = cygnixy.eve.shipui
        local speed = shipui and shipui.speed
        -- A ship under way is plainly obeying, and the wait costs nothing to
        -- extend; only standing still counts against the patience. That is
        -- what the wait at a gate looks like: arrived, motionless, the jump
        -- four seconds away and no part of the client saying so.
        if type(speed) == "number" and speed > 1.0 then
            return "Running"
        end

        local ticks = (cygnixy.bb_get("order_ticks") or 0) + 1
        cygnixy.bb_set("order_ticks", ticks)
        if ticks <= PATIENCE then
            return "Running"
        end
        if ticks > PATIENCE then
            log.repeated("order_stuck", "warn", "flight",
                "nothing has come of the last order in " .. ticks ..
                " ticks — ordering again")
        end
        cygnixy.bb_set("order_pending", 0)
        cygnixy.bb_set("order_ticks", 0)
    end

    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    if not (route and route.route_element_marker and #route.route_element_marker > 0) then
        return "Running"
    end

    local paths = marker_paths(#route.route_element_marker)
    local entry, err = pointer.open_menu_and_choose(paths, warp_choice.choices)
    if entry == nil then
        -- Debug, because failing here is ordinary: the panel carries up to
        -- two markers and the leading one is the system just reached, whose
        -- menu offers nothing worth choosing. Only persistence is a warning,
        -- and log.repeated raises it on the third identical try.
        log.repeated("route_menu", "debug", "flight",
            "no order could be given from the route marker: " .. tostring(err))
        return "Running"
    end

    warp_choice.after_chosen(entry)
    return "Success"
end

return M
