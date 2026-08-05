local log = require("log")

local M = {}

-- Waits for the client to lay the route that was just asked for.
--
-- The client does not answer a menu click at once: it sends the request and
-- draws the route a moment later. Checking immediately — as the plain
-- is_route_set did on 2026-08-05 — reads the panel nine milliseconds after the
-- press, finds nothing and fails the whole mission over a route that appears
-- half a second later.
--
-- So absence is Running, not Failure, until the patience runs out. The
-- deadline exists because the opposite mistake is worse in the other
-- direction: a press that landed on nothing would otherwise leave the bot
-- waiting for a route nobody ordered, forever and silently.
local WAIT_SECONDS = 10
local SINCE = "set_route_confirm_since"

function M.main(args)
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local markers = route and route.route_element_marker

    if markers ~= nil and #markers > 0 then
        -- Cleared so the next mission starts its own count.
        cygnixy.bb_set(SINCE, 0)
        return "Success"
    end

    local since = cygnixy.bb_get(SINCE)
    local now = os.time()
    if since == nil or since == 0 then
        cygnixy.bb_set(SINCE, now)
        return "Running"
    end

    if now - since > WAIT_SECONDS then
        cygnixy.bb_set(SINCE, 0)
        log.error("route", "no route appeared within " .. WAIT_SECONDS ..
            "s of choosing Set Destination — the press landed on nothing")
        return "Failure"
    end

    return "Running"
end

return M
