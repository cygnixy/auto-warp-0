local state = require("state")

local M = {}

-- Устойчива ли фаза (в доке, в варпе, подлетает или в дрейфе).
function M.settled(phase)
    return state.settled(phase or state.phase())
end

-- How many seconds the client says are left of the session change, or nil if
-- it is not saying.
--
-- The client keeps its own countdown and writes it in the indicator's tooltip:
-- "Session changing - Time left: 7 seconds". This is not a clock of ours —
-- it is a number the client publishes about itself, the same kind of fact as
-- a manoeuvre or a panel, and the only one that tells early in a session
-- change from late in it.
--
-- The wording has three shapes on this client — "1 second", "7 seconds" and
-- "Less than one second" — and the tooltip outlives the indicator: it still
-- reads "Less than one second" long after the change is over. So it is only
-- worth asking while the indicator is shown, which is what the session phase
-- already means.
--
-- nil is an answer: the tooltip did not read. Whoever asks should carry on as
-- though there were no countdown rather than wait for one that never comes.
function M.session_seconds_left()
    local indicator = cygnixy.eve.session_time_indicator
    local hint = indicator and indicator.hint
    if type(hint) ~= "string" or hint == "" then
        return nil
    end
    local seconds = string.match(hint, "(%d+)%s+seconds?")
    if seconds then
        return tonumber(seconds)
    end
    if string.find(hint, "than one second", 1, true) then
        return 0
    end
    return nil
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
