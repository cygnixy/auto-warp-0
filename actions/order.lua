local log = require("log")

local M = {}

-- Возвращает true, если приказ ещё в полёте и действию следует ждать.
-- patience_ms — сколько мс бездвижности допустимо перед повтором приказа.
-- speed_threshold — скорость, выше которой корабль считается «движущимся».
function M.pending(patience_ms, speed_threshold)
    if (cygnixy.bb_get("order_pending") or 0) ~= 1 then
        return false
    end

    -- Корабль движется — приказ выполняется, таймер обнуляется.
    local shipui = cygnixy.eve.shipui
    local speed = shipui and shipui.speed
    if speed_threshold and type(speed) == "number" and speed > speed_threshold then
        cygnixy.bb_set("order_since", -1)
        return true
    end

    -- Корабль стоит. Начинаем отсчёт, если ещё не начали.
    local since = cygnixy.bb_get("order_since") or -1
    if since < 0 then
        cygnixy.bb_set("order_since", cygnixy.now_ms())
        return true
    end

    -- Терпение истекло — приказ считается потерянным.
    local waited = cygnixy.now_ms() - since
    if waited >= patience_ms then
        log.repeated("order_stuck", "warn", "flight",
            "nothing has come of the last order in " .. math.floor(waited / 1000) ..
            "s, ordering again")
        cygnixy.bb_set("order_pending", 0)
        cygnixy.bb_set("order_since", -1)
        return false
    end

    return true
end

-- Записывает, что приказ только что отдан.
function M.issue()
    cygnixy.bb_set("order_pending", 1)
    cygnixy.bb_set("order_since", -1)
end

return M
