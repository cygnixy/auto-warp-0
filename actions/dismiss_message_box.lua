local log = require("log")
local pointer = require("pointer")
local press = require("press")

local M = {}

-- Acknowledges a modal the client has put up, and only acknowledges it.
--
-- "OK" and "Close" say "I have read this"; "Yes" says "do it". Only the first
-- kind is pressed here, without asking anyone, because a modal blocks the
-- whole client and a bot that cannot dismiss it can do nothing at all. The
-- consenting kind stays behind the push_button_yes flag where the operator put
-- it.
--
-- On 2026-08-05 the client answered an over-long search with "Information:
-- Search String Too Long". Nothing in the bot pressed OK — push_message_boxes
-- knows only "Yes", and it runs only during the flight — so the modal stood
-- there while set_route typed into a field it could no longer read, for four
-- minutes, until the operator stopped the mission.
local ACKNOWLEDGE = { OK = true, Close = true, Accept = true }

function M.main(args)
    local boxes = cygnixy.eve.message_boxes
    if not (boxes and #boxes > 0 and boxes[1].buttons) then
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
