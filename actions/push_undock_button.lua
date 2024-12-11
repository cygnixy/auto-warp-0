local M = {}

function M.main(args)
    if cygnixy.eve.station_window and cygnixy.eve.station_window.buttons then
        local undock_button = cygnixy.eve.station_window.buttons["Undock"]
        if undock_button ~= nil then
            local move_x = undock_button.x + undock_button.width // 2
            local move_y = undock_button.y + undock_button.height // 2
            cygnixy.info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
            cygnixy.mouse_move(move_x, move_y)
            cygnixy.sleep(50)
            cygnixy.mouse_click_left()
            cygnixy.info("CLICK Mouse Button Left")
            local now = os.time()
            cygnixy.bb_set("undock_timestamp", now)
            cygnixy.bb_set("_state", "undock")
            return "Success"
        end
    end
    return "Running"
end

return M
