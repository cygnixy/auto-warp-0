local M = {}

function M.main(args)
    if cygnixy.eve.message_boxes and #cygnixy.eve.message_boxes > 0 and cygnixy.eve.message_boxes[1].buttons then
        for _, button in cygnixy.eve.message_boxes[1].buttons do
            if button.label == "Yes" and button.region ~= nil then
                local move_x = button.region.x + button.region.width // 2
                local move_y = button.region.y + button.region.height // 2
                cygnixy.info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
                cygnixy.mouse_move(move_x, move_y)
                cygnixy.sleep(50)
                cygnixy.mouse_click_left()
                cygnixy.info("CLICK Mouse Button Left")
                cygnixy.sleep(50)
                return "Success"
            end
        end
    end
    return "Failure"
end

return M
