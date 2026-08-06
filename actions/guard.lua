local state = require("state")

local M = {}

-- Устойчива ли фаза (в доке, в варпе, подлетает или в дрейфе).
function M.settled(phase)
    return state.settled(phase or state.phase())
end

-- Проверяет, обновилась ли панель маршрута после прыжка и продержалась ли timeout_ms мс.
function M.panel_fresh(timeout_ms)
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local location = panel and panel.info_panel_location_info
    local next_stop = route and route.next_system
    local here = location and location.current_solar_system_name
    if type(next_stop) ~= "string" or next_stop == "" or next_stop == here then
        cygnixy.bb_set("panel_fresh", -1)
        return false
    end

    local fresh_since = cygnixy.bb_get("panel_fresh") or -1
    if fresh_since < 0 then
        cygnixy.bb_set("panel_fresh", cygnixy.now_ms())
        return false
    end
    if cygnixy.now_ms() - fresh_since < timeout_ms then
        return false
    end
    return true
end

return M
