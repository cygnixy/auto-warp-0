local M = {}

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

return M
