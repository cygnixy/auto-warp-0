local M = {}

function M.main(args)
    if eve.station_window and eve.station_window.buttons then
        local undock_button = eve.station_window.buttons["Undock"]
        if undock_button ~= nil then
            window_focus()
            local move_x = undock_button.x + undock_button.width // 2
            local move_y = undock_button.y + undock_button.height // 2
            info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
            mouse_move(move_x, move_y)
            sleep(50)
            mouse_click_left()
            info("CLICK Mouse Button Left")
            local now = os.time()
            bb_set("undock", now)
            bb_set("state", "undock")
            return "Success"
        end
    end
    return "Running"
end

return M
