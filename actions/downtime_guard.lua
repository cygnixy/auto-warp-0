local log = require("log")
local guard = require("guard")

local M = {}

-- Fails the whole tree before any order is given, when the server is about
-- to go away or already has.
--
-- Two facts end a mission here. A message box whose only button is "Quit"
-- is the client saying the connection is gone: nothing can be ordered any
-- more, and pressing Quit is the operator's call, not ours. The cluster
-- shutdown countdown at or under the threshold means an order given now
-- races the server's own clock; stopping cleanly beats hanging mid-jump.
--
-- args[1] is the threshold in seconds (downtime_guard_seconds). 0 reacts
-- to Connection Lost only.
function M.main(args)
    local boxes = cygnixy.eve.message_boxes
    if boxes then
        for _, box in ipairs(boxes) do
            local buttons = box.buttons
            if buttons and #buttons == 1 and buttons[1][2] == "Quit" then
                log.error("downtime", "connection lost: the client offers only Quit")
                return "Failure"
            end
        end
    end

    local left = guard.downtime_seconds_left()
    local threshold = tonumber(args and args[1]) or 300
    if left ~= nil and left <= threshold then
        log.warn("downtime",
            "cluster shutdown in " .. tostring(left) .. "s, stopping before disconnect")
        return "Failure"
    end
    return "Success"
end

return M
