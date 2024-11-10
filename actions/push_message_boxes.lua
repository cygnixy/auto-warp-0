local M = {}

function M.main(args)
    if eve.message_boxes and #eve.message_boxes > 0 and eve.message_boxes[1].buttons then
        for _, button in eve.message_boxes[1].buttons do
            if button.label == "Yes" and button.region ~= nil then
                local move_x = button.region.x + button.region.width // 2
                local move_y = button.region.y + button.region.height // 2
                info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
                mouse_move(move_x, move_y)
                sleep(50)
                mouse_click_left()
                info("CLICK Mouse Button Left")
                sleep(50)
                return "Success"
            end
        end
    end
    return "Failure"
end

return M
