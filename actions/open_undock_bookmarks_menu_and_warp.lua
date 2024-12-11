local M = {}

function M.main(args)
    if cygnixy.eve.standalone_bookmark_window and cygnixy.eve.standalone_bookmark_window.entries then
        for _, entry in cygnixy.eve.standalone_bookmark_window.entries do
            if entry and entry[1] and string.find(entry[1], "Undock") then
                local region = entry[2]
                local move_x = region.x + region.width // 2
                local move_y = region.y + region.height // 2
                cygnixy.info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
                cygnixy.mouse_move(move_x, move_y)
                cygnixy.sleep(50)
                cygnixy.mouse_click_right()
                cygnixy.info("CLICK Mouse Button Right")
                cygnixy.sleep(200)
                cygnixy.update_eve()
                local push_jump_or_dock_or_warp = require("push_jump_or_dock_or_warp")
                local result = push_jump_or_dock_or_warp.main()
                return result
            end
        end
    end
    return "Failure"
end

return M
