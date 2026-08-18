local log = require("std.log")
local pointer = require("std.pointer")
local press = require("std.press")

local M = {}

-- Acknowledges standard informational modals (OK/Close/Accept).
-- Consenting buttons (Yes/No) are guarded by user flags.
local ACKNOWLEDGE = { OK = true, Close = true, Accept = true }

function M.main(args)
    local boxes = cygnixy.eve.message_boxes
    local modal_active = cygnixy.eve.stacking and cygnixy.eve.stacking.modal_active

    if not (boxes and #boxes > 0 and boxes[1].buttons and #boxes[1].buttons > 0) then
        if modal_active then
            if press.pending("modal_escape", 1500) then
                return "Running"
            end
            local pressed, err = pointer.press_key("escape")
            press.made("modal_escape")
            if pressed then
                log.info("client", "a modal overlay is blocking the client — pressed Escape to close it")
            else
                log.repeated("modal_escape_press", "warn", "client",
                    "failed to press Escape: " .. tostring(err))
            end
            return "Running"
        end

        press.done("modal_escape")
        press.done("message_box")
        return "Success"
    end

    for _, button in ipairs(boxes[1].buttons) do
        local node, label = button[1], button[2]
        if ACKNOWLEDGE[label] and node and node.region then
            if press.pending("message_box") then
                return "Running"
            end
            local pressed, err = pointer.click(node.region)
            press.made("message_box")
            if not pressed then
                log.repeated("message_box", "debug", "client",
                    "the message box was not dismissed: " .. tostring(err))
                return "Running"
            end
            log.info("client", "dismissed a message box with \"" .. label .. "\"")
            return "Running"
        end
    end

    -- A modal offering nothing but consent. Not this action's business, and
    -- not something to press blindly: the flight's own push_message_boxes
    -- handles those when the operator has allowed it.
    return "Success"
end

return M
