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
--
-- «Следующая остановка — система, в которой мы стоим» обычно значит, что
-- панель ещё не пересчиталась после прыжка. Но в системе назначения это её
-- правда и навсегда: остаток маршрута — станция, и она здесь. 6 августа в
-- 14:50 бот из-за этого не пробовал панель в последней системе ни разу и ждал
-- конца смены сессии — одиннадцать секунд вместо шести.
--
-- Отличает их число меток: до цели их столько же, сколько прыжков (три метки
-- на три прыжка), а в системе назначения остаётся одна — сама станция.
--
-- Есть один случай, где это ошибётся: маршрут в один прыжок, и панель ещё не
-- пересчиталась сразу после него. Метка одна, и правило скажет «свежая». Цена
-- ошибки мала: пробовать всё равно нечего раньше, чем клиент откроет обратный
-- отсчёт до четырёх секунд, а к этому времени панель пересчитывается всегда —
-- на всех снятых дампах она была готова уже на семи.
function M.panel_fresh(timeout_ms)
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local location = panel and panel.info_panel_location_info
    local next_stop = route and route.next_system
    local here = location and location.current_solar_system_name
    local markers = route and route.route_element_marker
    local arrived = markers ~= nil and #markers == 1
    if type(next_stop) ~= "string" or next_stop == "" then
        cygnixy.bb_set("panel_fresh", -1)
        return false
    end
    if next_stop == here and not arrived then
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

-- How many seconds the client says are left before the cluster shuts down,
-- or nil if no shutdown is announced.
--
-- The announcement lives in quick_message: "Cluster Shutdown in 3 minutes
-- and 40 seconds", "... in 2 minutes", "... in 40 seconds", "... in Less
-- than one second". A wording this parser does not know still counts as an
-- announcement: zero is returned rather than nil, because acting on a dying
-- server is worse than stopping a minute early.
function M.downtime_seconds_left()
    local message = cygnixy.eve.quick_message
    local text = message and message.text
    if type(text) ~= "string" or not string.find(text, "Cluster Shutdown", 1, true) then
        return nil
    end
    local minutes = tonumber(string.match(text, "(%d+)%s+minutes?")) or 0
    local seconds = tonumber(string.match(text, "(%d+)%s+seconds?")) or 0
    if minutes == 0 and seconds == 0 then
        return 0
    end
    return minutes * 60 + seconds
end

return M
